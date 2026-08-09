import { relationalStore } from '@kit.ArkData';
import { HistoryMetadata, OpType } from '../core/model/OpTypes';
import { PageInfo } from '../core/model/NoteTypes';
import { validatePageDimensions } from '../core/model/PageCoordinateSpace';
import { PageRepository } from './RepositoryInterfaces';
import { DatabaseManager } from './DatabaseManager';
import { AsyncMutex, MutexRelease } from './AsyncMutex';
import { allocateOperationClientTime, appendOperation } from './OpStoreImpl';
import {
  classifyPageStructureMutation, createPageStructureMutation, encodePageStructureMutation,
  PageStructureMutation,
} from './PageStructureOpCodec';

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
        const predicates = new relationalStore.RdbPredicates('page_info');
        predicates.equalTo('note_id', noteId);
        predicates.equalTo('page_id', pageId);
        const deleted: number = await store.delete(predicates);
        if (deleted !== 1) {
          throw new Error(`expected to delete one page, deleted ${deleted}`);
        }
        const remaining: PageInfo[] = await this.queryPages(store, noteId);
        for (let index: number = 0; index < remaining.length; index++) {
          if (remaining[index].pageIndex !== index) {
            await this.updatePageIndex(store, noteId, remaining[index].pageId, index);
          }
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
    const clientTime: number = await allocateOperationClientTime(store, noteId);
    await appendOperation(store, {
      noteId: noteId,
      opId: `page-structure:${mutation.fromRevision}:${mutation.toRevision}`,
      opType: opType,
      payload: encodePageStructureMutation(mutation),
      clientTime: clientTime,
      history: history,
    });
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
