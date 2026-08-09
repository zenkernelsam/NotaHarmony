import { relationalStore } from '@kit.ArkData';
import { HistoryEffect, HistoryMetadata, OpType } from '../core/model/OpTypes';
import { PageInfo } from '../core/model/NoteTypes';
import { PageElementKind } from '../core/model/PageElementOrder';
import { validatePageDimensions } from '../core/model/PageCoordinateSpace';
import { PageRepository } from './RepositoryInterfaces';
import { DatabaseManager } from './DatabaseManager';
import { AsyncMutex, MutexRelease } from './AsyncMutex';
import { allocateOperationIdentity, AllocatedOperationIdentity, appendOperation } from './OpStoreImpl';
import {
  classifyPageStructureMutation, createPageStructureMutation, encodePageStructureMutation,
  PageStructureMutation,
} from './PageStructureOpCodec';
import { validateHistoryMetadata } from './PersistentHistoryMetadata';
import {
  PageDeleteCheckpoint, PageDeleteCheckpointElement,
} from './PageDeleteCheckpoint';
import { SearchItemType } from './SearchItemType';
import { decodePersistedElement, PersistedElement } from './StrokePersistence';

interface CheckpointSearchRow {
  type: number;
  subId: string;
  foldedText: string;
  rects: Uint8Array | null;
}

export class PageRepositoryImpl implements PageRepository {
  private static mutationMutex: AsyncMutex = new AsyncMutex();
  private db: DatabaseManager;

  constructor(db: DatabaseManager) {
    this.db = db;
  }

  async getPages(noteId: string): Promise<PageInfo[]> {
    try {
      return await this.queryPages(this.db.getStore(), noteId);
    } catch (e) {
      throw new Error(`getPages failed: ${JSON.stringify(e)}`);
    }
  }

  async addPage(noteId: string, page: PageInfo, history?: HistoryMetadata): Promise<PageInfo> {
    if (noteId.length === 0 || page.pageId.length === 0) {
      throw new Error('addPage failed: note ID and page ID are required');
    }
    validatePageDimensions(page);
    const release: MutexRelease = await PageRepositoryImpl.mutationMutex.lock();
    const store: relationalStore.RdbStore = this.db.getStore();
    try {
      await store.beginTransaction();
      try {
        const revision: number = await this.queryStructureRevision(store, noteId);
        const before: PageInfo[] = await this.queryPages(store, noteId);
        const assignedPage: PageInfo = this.clonePage(page);
        assignedPage.pageIndex = before.length;
        const bucket: relationalStore.ValuesBucket = {
          'page_id': assignedPage.pageId,
          'note_id': noteId,
          'page_index': assignedPage.pageIndex,
          'size': assignedPage.size,
          'template': assignedPage.template,
          'orientation': assignedPage.orientation,
          'width_mm': assignedPage.widthMm,
          'height_mm': assignedPage.heightMm,
        };
        await store.insert('page_info', bucket);
        const after: PageInfo[] = await this.queryPages(store, noteId);
        await this.appendStructureMutation(store, noteId, revision, before, after, OpType.CREATE_PAGE, history);
        await store.commit();
        return assignedPage;
      } catch (e) {
        await store.rollBack();
        throw new Error(`addPage failed: ${JSON.stringify(e)}`);
      }
    } finally {
      release();
    }
  }

  async deletePage(noteId: string, pageId: string, history?: HistoryMetadata): Promise<void> {
    await this.deletePageInternal(noteId, pageId, history, false);
  }

  async deletePageWithCheckpoint(noteId: string, pageId: string,
    history: HistoryMetadata): Promise<void> {
    validateHistoryMetadata(history);
    if (history.effect !== HistoryEffect.PUSH && history.effect !== HistoryEffect.REDO) {
      throw new Error('deletePageWithCheckpoint requires PUSH or REDO history');
    }
    await this.deletePageInternal(noteId, pageId, history, true);
  }

  private async deletePageInternal(noteId: string, pageId: string, history: HistoryMetadata | undefined,
    useCheckpoint: boolean): Promise<void> {
    if (noteId.length === 0 || pageId.length === 0) {
      throw new Error('deletePage failed: note ID and page ID are required');
    }
    const release: MutexRelease = await PageRepositoryImpl.mutationMutex.lock();
    const store: relationalStore.RdbStore = this.db.getStore();
    try {
      await store.beginTransaction();
      try {
        const revision: number = await this.queryStructureRevision(store, noteId);
        const before: PageInfo[] = await this.queryPages(store, noteId);
        if (before.length <= 1) {
          throw new Error('a note must retain at least one page');
        }
        if (this.findPageIndex(before, pageId) < 0) {
          throw new Error('page does not belong to note');
        }
        if (useCheckpoint) {
          if (history === undefined) {
            throw new Error('checkpointed page deletion requires history metadata');
          }
          if (history.effect === HistoryEffect.PUSH) {
            await this.createDeleteCheckpoint(store, noteId, pageId, before, history);
          } else {
            await this.verifyDeleteCheckpointState(store, noteId, pageId, history.actionId);
          }
        }
        const predicates = new relationalStore.RdbPredicates('page_info');
        predicates.equalTo('note_id', noteId);
        predicates.equalTo('page_id', pageId);
        const deleted: number = await store.delete(predicates);
        if (deleted !== 1) {
          throw new Error(`expected to delete one page, deleted ${deleted}`);
        }
        let targetIndex: number = 0;
        for (const page of before) {
          if (page.pageId === pageId) {
            continue;
          }
          if (page.pageIndex !== targetIndex) {
            await this.updatePageIndex(store, noteId, page.pageId, targetIndex);
          }
          targetIndex++;
        }
        const after: PageInfo[] = await this.queryPages(store, noteId);
        await this.appendStructureMutation(store, noteId, revision, before, after, OpType.DELETE_PAGE, history);
        await store.commit();
      } catch (e) {
        await store.rollBack();
        throw new Error(`deletePage failed: ${JSON.stringify(e)}`);
      }
    } finally {
      release();
    }
  }

  async restoreDeletedPage(noteId: string, actionId: string, history: HistoryMetadata): Promise<void> {
    validateHistoryMetadata(history);
    if (noteId.length === 0 || actionId.length === 0 || history.actionId !== actionId ||
      history.effect !== HistoryEffect.UNDO) {
      throw new Error('restoreDeletedPage requires matching UNDO history');
    }
    const release: MutexRelease = await PageRepositoryImpl.mutationMutex.lock();
    const store: relationalStore.RdbStore = this.db.getStore();
    try {
      await store.beginTransaction();
      try {
        const checkpoint: PageDeleteCheckpoint = await this.loadDeleteCheckpoint(store, noteId, actionId);
        const searches: CheckpointSearchRow[] = await this.loadCheckpointSearch(store, noteId, actionId);
        this.validateCheckpointSearch(searches);
        const revision: number = await this.queryStructureRevision(store, noteId);
        const before: PageInfo[] = await this.queryPages(store, noteId);
        if (checkpoint.page.pageIndex < 0 || checkpoint.page.pageIndex > before.length ||
          this.findPageIndex(before, checkpoint.page.pageId) >= 0) {
          throw new Error('deleted-page checkpoint no longer matches page membership');
        }
        for (let index: number = 0; index < before.length; index++) {
          await this.updatePageIndex(store, noteId, before[index].pageId, -(index + 1));
        }
        await this.insertCheckpointPage(store, checkpoint);
        let existingIndex: number = 0;
        for (let targetIndex: number = 0; targetIndex <= before.length; targetIndex++) {
          if (targetIndex === checkpoint.page.pageIndex) {
            continue;
          }
          await this.updatePageIndex(store, noteId, before[existingIndex].pageId, targetIndex);
          existingIndex++;
        }
        await this.restoreCheckpointElements(store, checkpoint);
        await this.restoreCheckpointSearch(store, checkpoint, searches);
        const after: PageInfo[] = await this.queryPages(store, noteId);
        await this.appendStructureMutation(store, noteId, revision, before, after, OpType.CREATE_PAGE, history);
        await store.commit();
      } catch (e) {
        await store.rollBack();
        throw new Error(`restoreDeletedPage failed: ${JSON.stringify(e)}`);
      }
    } finally {
      release();
    }
  }

  async getDeleteCheckpoints(noteId: string): Promise<PageDeleteCheckpoint[]> {
    if (noteId.length === 0) {
      throw new Error('getDeleteCheckpoints requires a note ID');
    }
    const store: relationalStore.RdbStore = this.db.getStore();
    const resultSet = await store.querySql(
      `SELECT action_id FROM page_delete_checkpoint WHERE note_id = ?
       ORDER BY created_time, action_id`, [noteId]);
    const actionIds: string[] = [];
    try {
      while (resultSet.goToNextRow()) {
        actionIds.push(resultSet.getString(resultSet.getColumnIndex('action_id')));
      }
    } finally {
      resultSet.close();
    }
    const result: PageDeleteCheckpoint[] = [];
    for (const actionId of actionIds) {
      result.push(await this.loadDeleteCheckpoint(store, noteId, actionId));
    }
    return result;
  }

  async updatePage(page: PageInfo, history?: HistoryMetadata): Promise<void> {
    if (page.pageId.length === 0) {
      throw new Error('updatePage failed: page ID is required');
    }
    validatePageDimensions(page);
    const release: MutexRelease = await PageRepositoryImpl.mutationMutex.lock();
    const store: relationalStore.RdbStore = this.db.getStore();
    try {
      await store.beginTransaction();
      try {
        const noteId: string = await this.queryPageNoteId(store, page.pageId);
        const revision: number = await this.queryStructureRevision(store, noteId);
        const before: PageInfo[] = await this.queryPages(store, noteId);
        const pageIndex: number = this.findPageIndex(before, page.pageId);
        if (pageIndex < 0 || page.pageIndex !== before[pageIndex].pageIndex) {
          throw new Error('page settings cannot change page order');
        }
        if (this.samePage(before[pageIndex], page)) {
          await store.commit();
          return;
        }
        const bucket: relationalStore.ValuesBucket = {
          'size': page.size,
          'template': page.template,
          'orientation': page.orientation,
          'width_mm': page.widthMm,
          'height_mm': page.heightMm,
        };
        const predicates = new relationalStore.RdbPredicates('page_info');
        predicates.equalTo('note_id', noteId);
        predicates.equalTo('page_id', page.pageId);
        const updated: number = await store.update(bucket, predicates);
        if (updated !== 1) {
          throw new Error(`expected to update one page, updated ${updated}`);
        }
        const after: PageInfo[] = await this.queryPages(store, noteId);
        await this.appendStructureMutation(store, noteId, revision, before, after, OpType.UPDATE_PAGE, history);
        await store.commit();
      } catch (e) {
        await store.rollBack();
        throw new Error(`updatePage failed: ${JSON.stringify(e)}`);
      }
    } finally {
      release();
    }
  }

  async reorderPages(noteId: string, pageIds: string[], history?: HistoryMetadata): Promise<void> {
    if (noteId.length === 0) {
      throw new Error('reorderPages failed: note ID is required');
    }
    const release: MutexRelease = await PageRepositoryImpl.mutationMutex.lock();
    const store: relationalStore.RdbStore = this.db.getStore();
    try {
      await store.beginTransaction();
      try {
        const revision: number = await this.queryStructureRevision(store, noteId);
        const before: PageInfo[] = await this.queryPages(store, noteId);
        this.validateRequestedOrder(before, pageIds);
        if (this.samePageOrder(before, pageIds)) {
          await store.commit();
          return;
        }
        // Move every row outside the unique non-negative range before assigning final positions.
        for (let index: number = 0; index < pageIds.length; index++) {
          await this.updatePageIndex(store, noteId, pageIds[index], -(index + 1));
        }
        for (let index: number = 0; index < pageIds.length; index++) {
          await this.updatePageIndex(store, noteId, pageIds[index], index);
        }
        const after: PageInfo[] = await this.queryPages(store, noteId);
        await this.appendStructureMutation(store, noteId, revision, before, after, OpType.REORDER_PAGES, history);
        await store.commit();
      } catch (e) {
        await store.rollBack();
        throw new Error(`reorderPages failed: ${JSON.stringify(e)}`);
      }
    } finally {
      release();
    }
  }

  private rowToPage(resultSet: relationalStore.ResultSet): PageInfo {
    const page: PageInfo = {
      pageId: resultSet.getString(resultSet.getColumnIndex('page_id')),
      pageIndex: resultSet.getLong(resultSet.getColumnIndex('page_index')),
      size: resultSet.getLong(resultSet.getColumnIndex('size')),
      template: resultSet.getLong(resultSet.getColumnIndex('template')),
      orientation: resultSet.getLong(resultSet.getColumnIndex('orientation')),
      widthMm: resultSet.getDouble(resultSet.getColumnIndex('width_mm')),
      heightMm: resultSet.getDouble(resultSet.getColumnIndex('height_mm')),
    };
    validatePageDimensions(page);
    return page;
  }

  private async queryPages(store: relationalStore.RdbStore, noteId: string): Promise<PageInfo[]> {
    const predicates = new relationalStore.RdbPredicates('page_info');
    predicates.equalTo('note_id', noteId);
    predicates.orderByAsc('page_index');
    const resultSet = await store.query(predicates);
    const pages: PageInfo[] = [];
    try {
      while (resultSet.goToNextRow()) {
        const page: PageInfo = this.rowToPage(resultSet);
        if (page.pageIndex !== pages.length) {
          throw new Error('stored page indexes are not contiguous');
        }
        pages.push(page);
      }
    } finally {
      resultSet.close();
    }
    return pages;
  }

  private async queryStructureRevision(store: relationalStore.RdbStore, noteId: string): Promise<number> {
    const resultSet = await store.querySql(
      'SELECT structure_revision FROM note_meta WHERE id = ?', [noteId]);
    try {
      if (!resultSet.goToFirstRow()) {
        throw new Error('note does not exist');
      }
      const revision: number = resultSet.getLong(resultSet.getColumnIndex('structure_revision'));
      if (!Number.isSafeInteger(revision) || revision < 0) {
        throw new Error('stored page structure revision is invalid');
      }
      return revision;
    } finally {
      resultSet.close();
    }
  }

  private async queryPageNoteId(store: relationalStore.RdbStore, pageId: string): Promise<string> {
    const resultSet = await store.querySql('SELECT note_id FROM page_info WHERE page_id = ?', [pageId]);
    try {
      if (!resultSet.goToFirstRow()) {
        throw new Error('page does not exist');
      }
      return resultSet.getString(resultSet.getColumnIndex('note_id'));
    } finally {
      resultSet.close();
    }
  }

  private async appendStructureMutation(store: relationalStore.RdbStore, noteId: string,
    revision: number, before: PageInfo[], after: PageInfo[], expectedType: OpType,
    history?: HistoryMetadata): Promise<void> {
    const mutation: PageStructureMutation = createPageStructureMutation(
      revision, revision + 1, before, after);
    const opType: OpType = classifyPageStructureMutation(mutation);
    if (opType !== expectedType) {
      throw new Error(`page mutation type mismatch: expected ${expectedType}, got ${opType}`);
    }
    const revisionBucket: relationalStore.ValuesBucket = { 'structure_revision': mutation.toRevision };
    const revisionPredicates = new relationalStore.RdbPredicates('note_meta');
    revisionPredicates.equalTo('id', noteId);
    revisionPredicates.equalTo('structure_revision', revision);
    const updated: number = await store.update(revisionBucket, revisionPredicates);
    if (updated !== 1) {
      throw new Error('page structure revision changed concurrently');
    }
    const identity: AllocatedOperationIdentity = await allocateOperationIdentity(store, noteId);
    await appendOperation(store, {
      noteId: noteId,
      opId: identity.opId,
      opType: opType,
      payload: encodePageStructureMutation(mutation),
      clientTime: identity.clientTime,
      opTimestamp: identity.timestamp,
      editorSiteId: identity.siteId,
      history: history,
    });
  }

  private async createDeleteCheckpoint(store: relationalStore.RdbStore, noteId: string, pageId: string,
    pages: PageInfo[], history: HistoryMetadata): Promise<void> {
    const pageIndex: number = this.findPageIndex(pages, pageId);
    if (pageIndex < 0) {
      throw new Error('checkpoint page does not belong to note');
    }
    const contentRevision: number = await this.queryPageContentRevision(store, noteId, pageId);
    const indexedRevision: number | null = await this.queryIndexedRevision(store, noteId, pageId);
    if (indexedRevision !== null && indexedRevision > contentRevision) {
      throw new Error('page search revision exceeds its content revision');
    }
    const page: PageInfo = pages[pageIndex];
    const header: relationalStore.ValuesBucket = {
      'note_id': noteId,
      'action_id': history.actionId,
      'page_id': pageId,
      'page_index': page.pageIndex,
      'size': page.size,
      'template': page.template,
      'orientation': page.orientation,
      'width_mm': page.widthMm,
      'height_mm': page.heightMm,
      'content_revision': contentRevision,
      'indexed_revision': indexedRevision,
      'created_time': history.actionTime,
    };
    await store.insert('page_delete_checkpoint', header);

    const elements: PageDeleteCheckpointElement[] = await this.loadLiveElements(store, noteId, pageId);
    this.validateCheckpointElements(elements, contentRevision);
    const elementBuckets: relationalStore.ValuesBucket[] = [];
    for (const element of elements) {
      elementBuckets.push({
        'note_id': noteId,
        'action_id': history.actionId,
        'element_id': element.elementId,
        'kind': element.kind,
        'payload': element.payload,
        'revision': element.revision,
        'element_order': element.elementOrder,
      });
    }
    if (elementBuckets.length > 0) {
      await store.batchInsert('page_delete_checkpoint_element', elementBuckets);
    }
    const searches: CheckpointSearchRow[] = await this.loadLiveSearch(store, noteId, pageId);
    this.validateCheckpointSearch(searches);
    const searchBuckets: relationalStore.ValuesBucket[] = [];
    for (const search of searches) {
      searchBuckets.push({
        'note_id': noteId,
        'action_id': history.actionId,
        'type': search.type,
        'sub_id': search.subId,
        'folded_text': search.foldedText,
        'rects': search.rects,
      });
    }
    if (searchBuckets.length > 0) {
      await store.batchInsert('page_delete_checkpoint_search', searchBuckets);
    }
  }

  private async verifyDeleteCheckpointState(store: relationalStore.RdbStore, noteId: string,
    pageId: string, actionId: string): Promise<void> {
    const checkpoint: PageDeleteCheckpoint = await this.loadDeleteCheckpoint(store, noteId, actionId);
    if (checkpoint.page.pageId !== pageId) {
      throw new Error('delete checkpoint page identity mismatch');
    }
    const pages: PageInfo[] = await this.queryPages(store, noteId);
    const pageIndex: number = this.findPageIndex(pages, pageId);
    if (pageIndex < 0 || !this.samePage(pages[pageIndex], checkpoint.page) ||
      await this.queryPageContentRevision(store, noteId, pageId) !== checkpoint.contentRevision ||
      await this.queryIndexedRevision(store, noteId, pageId) !== checkpoint.indexedRevision) {
      throw new Error('redo DELETE_PAGE source page differs from its checkpoint');
    }
    const currentElements: PageDeleteCheckpointElement[] = await this.loadLiveElements(store, noteId, pageId);
    if (!this.sameCheckpointElements(currentElements, checkpoint.elements)) {
      throw new Error('redo DELETE_PAGE source elements differ from its checkpoint');
    }
    const currentSearch: CheckpointSearchRow[] = await this.loadLiveSearch(store, noteId, pageId);
    const checkpointSearch: CheckpointSearchRow[] = await this.loadCheckpointSearch(store, noteId, actionId);
    this.validateCheckpointSearch(currentSearch);
    this.validateCheckpointSearch(checkpointSearch);
    if (!this.sameCheckpointSearch(currentSearch, checkpointSearch)) {
      throw new Error('redo DELETE_PAGE source search index differs from its checkpoint');
    }
  }

  private async loadDeleteCheckpoint(store: relationalStore.RdbStore, noteId: string,
    actionId: string): Promise<PageDeleteCheckpoint> {
    const resultSet = await store.querySql(
      `SELECT page_id, page_index, size, template, orientation, width_mm, height_mm,
        content_revision, indexed_revision, created_time
       FROM page_delete_checkpoint WHERE note_id = ? AND action_id = ?`, [noteId, actionId]);
    let checkpoint: PageDeleteCheckpoint | undefined = undefined;
    try {
      if (!resultSet.goToFirstRow()) {
        throw new Error('deleted-page checkpoint does not exist');
      }
      const page: PageInfo = {
        pageId: resultSet.getString(resultSet.getColumnIndex('page_id')),
        pageIndex: resultSet.getLong(resultSet.getColumnIndex('page_index')),
        size: resultSet.getLong(resultSet.getColumnIndex('size')),
        template: resultSet.getLong(resultSet.getColumnIndex('template')),
        orientation: resultSet.getLong(resultSet.getColumnIndex('orientation')),
        widthMm: resultSet.getDouble(resultSet.getColumnIndex('width_mm')),
        heightMm: resultSet.getDouble(resultSet.getColumnIndex('height_mm')),
      };
      validatePageDimensions(page);
      const indexedColumn: number = resultSet.getColumnIndex('indexed_revision');
      checkpoint = {
        noteId: noteId,
        actionId: actionId,
        page: page,
        contentRevision: resultSet.getLong(resultSet.getColumnIndex('content_revision')),
        indexedRevision: resultSet.isColumnNull(indexedColumn) ? null : resultSet.getLong(indexedColumn),
        createdTime: resultSet.getLong(resultSet.getColumnIndex('created_time')),
        elements: [],
      };
      this.validateCheckpointHeader(checkpoint);
    } finally {
      resultSet.close();
    }
    checkpoint.elements = await this.loadCheckpointElements(store, noteId, actionId);
    this.validateCheckpointElements(checkpoint.elements, checkpoint.contentRevision);
    return checkpoint;
  }

  private validateCheckpointHeader(checkpoint: PageDeleteCheckpoint): void {
    if (checkpoint.noteId.length === 0 || checkpoint.actionId.length === 0 ||
      checkpoint.page.pageId.length === 0 || checkpoint.page.pageIndex < 0 ||
      !Number.isSafeInteger(checkpoint.contentRevision) || checkpoint.contentRevision < 0 ||
      (checkpoint.indexedRevision !== null && (!Number.isSafeInteger(checkpoint.indexedRevision) ||
        checkpoint.indexedRevision < 0 || checkpoint.indexedRevision > checkpoint.contentRevision)) ||
      !Number.isSafeInteger(checkpoint.createdTime) ||
      checkpoint.createdTime < 0) {
      throw new Error('deleted-page checkpoint header is invalid');
    }
  }

  private async loadCheckpointElements(store: relationalStore.RdbStore, noteId: string,
    actionId: string): Promise<PageDeleteCheckpointElement[]> {
    const resultSet = await store.querySql(
      `SELECT element_id, kind, payload, revision, element_order
       FROM page_delete_checkpoint_element WHERE note_id = ? AND action_id = ?
       ORDER BY element_order`, [noteId, actionId]);
    const result: PageDeleteCheckpointElement[] = [];
    try {
      while (resultSet.goToNextRow()) {
        const element: PageDeleteCheckpointElement = {
          elementId: resultSet.getString(resultSet.getColumnIndex('element_id')),
          kind: resultSet.getLong(resultSet.getColumnIndex('kind')),
          payload: resultSet.getBlob(resultSet.getColumnIndex('payload')),
          revision: resultSet.getLong(resultSet.getColumnIndex('revision')),
          elementOrder: resultSet.getLong(resultSet.getColumnIndex('element_order')),
        };
        result.push(element);
      }
    } finally {
      resultSet.close();
    }
    return result;
  }

  private validateCheckpointElements(elements: PageDeleteCheckpointElement[], contentRevision: number): void {
    for (let index: number = 0; index < elements.length; index++) {
      const element: PageDeleteCheckpointElement = elements[index];
      if (element.elementId.length === 0 || !Number.isSafeInteger(element.kind) || element.kind < 0 ||
        element.kind > PageElementKind.SHAPE || element.revision !== contentRevision ||
        element.elementOrder !== index ||
        element.payload.length === 0) {
        throw new Error('deleted-page checkpoint contains an invalid element');
      }
      let expectedKind: string = 'stroke';
      if (element.kind === PageElementKind.TEXT) {
        expectedKind = 'text';
      } else if (element.kind === PageElementKind.SHAPE) {
        expectedKind = 'shape';
      }
      try {
        const persisted: PersistedElement = decodePersistedElement(element.payload);
        if (persisted.kind !== expectedKind || persisted.data.id !== element.elementId) {
          throw new Error('identity mismatch');
        }
      } catch (_error) {
        throw new Error('deleted-page checkpoint element payload is invalid');
      }
    }
  }

  private async loadLiveElements(store: relationalStore.RdbStore, noteId: string,
    pageId: string): Promise<PageDeleteCheckpointElement[]> {
    const resultSet = await store.querySql(
      `SELECT element_id, kind, payload, revision, element_order
       FROM page_element_snapshot WHERE note_id = ? AND page_id = ? ORDER BY element_order`,
      [noteId, pageId]);
    const result: PageDeleteCheckpointElement[] = [];
    try {
      while (resultSet.goToNextRow()) {
        const order: number = resultSet.getLong(resultSet.getColumnIndex('element_order'));
        if (order !== result.length) {
          throw new Error('live page element order is not contiguous');
        }
        result.push({
          elementId: resultSet.getString(resultSet.getColumnIndex('element_id')),
          kind: resultSet.getLong(resultSet.getColumnIndex('kind')),
          payload: resultSet.getBlob(resultSet.getColumnIndex('payload')),
          revision: resultSet.getLong(resultSet.getColumnIndex('revision')),
          elementOrder: order,
        });
      }
    } finally {
      resultSet.close();
    }
    return result;
  }

  private validateCheckpointSearch(searches: CheckpointSearchRow[]): void {
    for (const search of searches) {
      if (!Number.isSafeInteger(search.type) || search.type < SearchItemType.TITLE ||
        search.type > SearchItemType.PDF || search.subId.length === 0) {
        throw new Error('deleted-page checkpoint contains an invalid search row');
      }
    }
  }

  private async loadLiveSearch(store: relationalStore.RdbStore, noteId: string,
    pageId: string): Promise<CheckpointSearchRow[]> {
    const resultSet = await store.querySql(
      `SELECT type, sub_id, folded_text, rects FROM search_item
       WHERE note_id = ? AND page_id = ? ORDER BY type, sub_id`, [noteId, pageId]);
    const result: CheckpointSearchRow[] = [];
    try {
      while (resultSet.goToNextRow()) {
        const rectsColumn: number = resultSet.getColumnIndex('rects');
        result.push({
          type: resultSet.getLong(resultSet.getColumnIndex('type')),
          subId: resultSet.getString(resultSet.getColumnIndex('sub_id')),
          foldedText: resultSet.getString(resultSet.getColumnIndex('folded_text')),
          rects: resultSet.isColumnNull(rectsColumn) ? null : resultSet.getBlob(rectsColumn),
        });
      }
    } finally {
      resultSet.close();
    }
    return result;
  }

  private async loadCheckpointSearch(store: relationalStore.RdbStore, noteId: string,
    actionId: string): Promise<CheckpointSearchRow[]> {
    const resultSet = await store.querySql(
      `SELECT type, sub_id, folded_text, rects FROM page_delete_checkpoint_search
       WHERE note_id = ? AND action_id = ? ORDER BY type, sub_id`, [noteId, actionId]);
    const result: CheckpointSearchRow[] = [];
    try {
      while (resultSet.goToNextRow()) {
        const rectsColumn: number = resultSet.getColumnIndex('rects');
        result.push({
          type: resultSet.getLong(resultSet.getColumnIndex('type')),
          subId: resultSet.getString(resultSet.getColumnIndex('sub_id')),
          foldedText: resultSet.getString(resultSet.getColumnIndex('folded_text')),
          rects: resultSet.isColumnNull(rectsColumn) ? null : resultSet.getBlob(rectsColumn),
        });
      }
    } finally {
      resultSet.close();
    }
    return result;
  }

  private async queryPageContentRevision(store: relationalStore.RdbStore, noteId: string,
    pageId: string): Promise<number> {
    const resultSet = await store.querySql(
      'SELECT content_revision FROM page_info WHERE note_id = ? AND page_id = ?', [noteId, pageId]);
    try {
      if (!resultSet.goToFirstRow()) {
        throw new Error('checkpoint page does not exist');
      }
      const revision: number = resultSet.getLong(resultSet.getColumnIndex('content_revision'));
      if (!Number.isSafeInteger(revision) || revision < 0) {
        throw new Error('page content revision is invalid');
      }
      return revision;
    } finally {
      resultSet.close();
    }
  }

  private async queryIndexedRevision(store: relationalStore.RdbStore, noteId: string,
    pageId: string): Promise<number | null> {
    const resultSet = await store.querySql(
      'SELECT indexed_revision FROM search_page_state WHERE note_id = ? AND page_id = ?', [noteId, pageId]);
    try {
      if (!resultSet.goToFirstRow()) {
        return null;
      }
      const revision: number = resultSet.getLong(resultSet.getColumnIndex('indexed_revision'));
      if (!Number.isSafeInteger(revision) || revision < 0) {
        throw new Error('page search revision is invalid');
      }
      return revision;
    } finally {
      resultSet.close();
    }
  }

  private async insertCheckpointPage(store: relationalStore.RdbStore,
    checkpoint: PageDeleteCheckpoint): Promise<void> {
    const page: PageInfo = checkpoint.page;
    await store.insert('page_info', {
      'page_id': page.pageId,
      'note_id': checkpoint.noteId,
      'page_index': page.pageIndex,
      'size': page.size,
      'template': page.template,
      'orientation': page.orientation,
      'width_mm': page.widthMm,
      'height_mm': page.heightMm,
      'content_revision': checkpoint.contentRevision,
    });
  }

  private async restoreCheckpointElements(store: relationalStore.RdbStore,
    checkpoint: PageDeleteCheckpoint): Promise<void> {
    const buckets: relationalStore.ValuesBucket[] = [];
    for (const element of checkpoint.elements) {
      buckets.push({
        'note_id': checkpoint.noteId,
        'page_id': checkpoint.page.pageId,
        'element_id': element.elementId,
        'kind': element.kind,
        'payload': element.payload,
        'revision': element.revision,
        'element_order': element.elementOrder,
      });
    }
    if (buckets.length > 0) {
      await store.batchInsert('page_element_snapshot', buckets);
    }
  }

  private async restoreCheckpointSearch(store: relationalStore.RdbStore,
    checkpoint: PageDeleteCheckpoint, searches: CheckpointSearchRow[]): Promise<void> {
    for (const search of searches) {
      await store.insert('search_item', {
        'note_id': checkpoint.noteId,
        'type': search.type,
        'sub_id': search.subId,
        'page_id': checkpoint.page.pageId,
        'folded_text': search.foldedText,
        'rects': search.rects,
      });
    }
    if (checkpoint.indexedRevision !== null) {
      await store.insert('search_page_state', {
        'note_id': checkpoint.noteId,
        'page_id': checkpoint.page.pageId,
        'indexed_revision': checkpoint.indexedRevision,
      });
    }
  }

  private sameCheckpointElements(left: PageDeleteCheckpointElement[],
    right: PageDeleteCheckpointElement[]): boolean {
    if (left.length !== right.length) {
      return false;
    }
    for (let index: number = 0; index < left.length; index++) {
      if (left[index].elementId !== right[index].elementId || left[index].kind !== right[index].kind ||
        left[index].revision !== right[index].revision ||
        left[index].elementOrder !== right[index].elementOrder ||
        !this.sameBytes(left[index].payload, right[index].payload)) {
        return false;
      }
    }
    return true;
  }

  private sameCheckpointSearch(left: CheckpointSearchRow[], right: CheckpointSearchRow[]): boolean {
    if (left.length !== right.length) {
      return false;
    }
    for (let index: number = 0; index < left.length; index++) {
      const leftRects: Uint8Array = left[index].rects === null ? new Uint8Array(0) : left[index].rects as Uint8Array;
      const rightRects: Uint8Array = right[index].rects === null ? new Uint8Array(0) : right[index].rects as Uint8Array;
      if (left[index].type !== right[index].type || left[index].subId !== right[index].subId ||
        left[index].foldedText !== right[index].foldedText ||
        (left[index].rects === null) !== (right[index].rects === null) || !this.sameBytes(leftRects, rightRects)) {
        return false;
      }
    }
    return true;
  }

  private sameBytes(left: Uint8Array, right: Uint8Array): boolean {
    if (left.length !== right.length) {
      return false;
    }
    for (let index: number = 0; index < left.length; index++) {
      if (left[index] !== right[index]) {
        return false;
      }
    }
    return true;
  }

  private validateRequestedOrder(pages: PageInfo[], pageIds: string[]): void {
    if (pages.length === 0 || pageIds.length !== pages.length) {
      throw new Error('page order must contain every page exactly once');
    }
    const expected: Set<string> = new Set<string>();
    for (const page of pages) {
      expected.add(page.pageId);
    }
    const actual: Set<string> = new Set<string>();
    for (const pageId of pageIds) {
      if (!expected.has(pageId) || actual.has(pageId)) {
        throw new Error('page order contains a duplicate or foreign page ID');
      }
      actual.add(pageId);
    }
  }

  private samePageOrder(pages: PageInfo[], pageIds: string[]): boolean {
    for (let index: number = 0; index < pages.length; index++) {
      if (pages[index].pageId !== pageIds[index]) {
        return false;
      }
    }
    return true;
  }

  private findPageIndex(pages: PageInfo[], pageId: string): number {
    for (let index: number = 0; index < pages.length; index++) {
      if (pages[index].pageId === pageId) {
        return index;
      }
    }
    return -1;
  }

  private samePage(left: PageInfo, right: PageInfo): boolean {
    return left.pageId === right.pageId && left.pageIndex === right.pageIndex &&
      left.size === right.size && left.template === right.template &&
      left.orientation === right.orientation && left.widthMm === right.widthMm &&
      left.heightMm === right.heightMm;
  }

  private clonePage(page: PageInfo): PageInfo {
    return {
      pageId: page.pageId,
      pageIndex: page.pageIndex,
      size: page.size,
      template: page.template,
      orientation: page.orientation,
      widthMm: page.widthMm,
      heightMm: page.heightMm,
    };
  }

  private async updatePageIndex(store: relationalStore.RdbStore, noteId: string,
    pageId: string, pageIndex: number): Promise<void> {
    const bucket: relationalStore.ValuesBucket = { 'page_index': pageIndex };
    const predicates = new relationalStore.RdbPredicates('page_info');
    predicates.equalTo('note_id', noteId);
    predicates.equalTo('page_id', pageId);
    const updated: number = await store.update(bucket, predicates);
    if (updated !== 1) {
      throw new Error(`page index update affected ${updated} rows`);
    }
  }
}
