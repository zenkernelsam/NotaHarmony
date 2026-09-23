import { relationalStore } from '@kit.ArkData';
import { HistoryEffect, HistoryMetadata, OpType } from '../core/model/OpTypes';
import { NoteBackgroundSettings, PageBackground, PageInfo } from '../core/model/NoteTypes';
import { PageElementKind } from '../core/model/PageElementOrder';
import { validatePageDimensions } from '../core/model/PageCoordinateSpace';
import {
  cloneNoteBackgroundSettings, clonePageBackground, clonePageInfo, duplicatedOriginalPageBackground,
  noteBackgroundSettingsFromPage,
  originalDefaultNoteBackgroundSettings, originalPaperOrientation, parsePageBackground,
  samePageBackground, serializePageBackground,
} from '../core/model/PageBackgroundModel';
import {
  OriginalNoteBackgroundState, readEffectiveNoteBackground, readOriginalNoteBackgroundState,
} from './OriginalSetMetadataOperation';
import { PageRepository } from './RepositoryInterfaces';
import { DatabaseManager } from './DatabaseManager';
import { MutexRelease } from './AsyncMutex';
import { editorPersistenceMutex } from './EditorPersistenceMutex';
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
import { decodeStoredPageElement } from './StrokePersistence';
import {
  hasAlignedOriginalPageState, originalPageIdentityExists, PersistedOriginalPageMutation,
  persistOriginalCreatePage, persistOriginalDuplicatePage, persistOriginalPageBackground,
  persistOriginalPageBookmark, persistOriginalPageReorder, persistOriginalPageVisibility,
} from './OriginalPagePersistence';
import {
  DuplicatePageMutation, encodeDuplicatePageMutation,
} from './DuplicatePageOpCodec';
import {
  DeletePageCompensationMutation, encodeDeletePageCompensationMutation,
} from './DeletePageCompensationOpCodec';
import {
  persistOriginalNoteBackground, PersistedOriginalNoteBackground,
} from './OriginalNoteBackgroundPersistence';
import { assertLivePageElementIdsAvailable } from './PageElementIdentity';

interface CheckpointSearchRow {
  type: number;
  subId: string;
  foldedText: string;
  rects: Uint8Array | null;
}

export class PageRepositoryImpl implements PageRepository {
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

  async getNoteBackground(noteId: string): Promise<NoteBackgroundSettings> {
    if (noteId.length === 0) {
      throw new Error('getNoteBackground failed: note ID is required');
    }
    try {
      const store: relationalStore.RdbStore = this.db.getStore();
      if (await this.noteHasOriginalPages(store, noteId)) {
        const state: OriginalNoteBackgroundState = await readOriginalNoteBackgroundState(store, noteId);
        const decoded = state.effective;
        return cloneNoteBackgroundSettings({
          background: decoded.background,
          registerBackground: state.registerValue === null ? null : state.registerValue.background,
          template: decoded.template,
          size: decoded.size,
          orientation: originalPaperOrientation(decoded.background),
          widthMm: decoded.widthMm,
          heightMm: decoded.heightMm,
        });
      }
      const pages: PageInfo[] = await this.queryPages(store, noteId);
      return pages.length === 0 ? originalDefaultNoteBackgroundSettings() :
        noteBackgroundSettingsFromPage(pages[0]);
    } catch (e) {
      throw new Error(`getNoteBackground failed: ${JSON.stringify(e)}`);
    }
  }

  async updateNoteBackground(noteId: string, requested: NoteBackgroundSettings,
    selectedPageId: string, history?: HistoryMetadata): Promise<NoteBackgroundSettings> {
    const release: MutexRelease = await editorPersistenceMutex.lock();
    const store: relationalStore.RdbStore = this.db.getStore();
    try {
      await store.beginTransaction();
      try {
        const persisted: PersistedOriginalNoteBackground = await persistOriginalNoteBackground(
          store, noteId, requested, selectedPageId, history);
        await store.commit();
        return cloneNoteBackgroundSettings(persisted.after);
      } catch (e) {
        await store.rollBack();
        throw new Error(`updateNoteBackground failed: ${JSON.stringify(e)}`);
      }
    } finally {
      release();
    }
  }

  async addPage(noteId: string, page: PageInfo, history?: HistoryMetadata,
    afterPageId?: string): Promise<PageInfo> {
    return this.addPageInternal(noteId, page, history, true, afterPageId);
  }

  async addImportedPage(noteId: string, page: PageInfo): Promise<PageInfo> {
    return this.addPageInternal(noteId, page, undefined, false, undefined);
  }

  private async addPageInternal(noteId: string, page: PageInfo, history: HistoryMetadata | undefined,
    useOriginalOperation: boolean, afterPageId: string | undefined): Promise<PageInfo> {
    if (noteId.length === 0 || page.pageId.length === 0) {
      throw new Error('addPage failed: note ID and page ID are required');
    }
    validatePageDimensions(page);
    const release: MutexRelease = await editorPersistenceMutex.lock();
    const store: relationalStore.RdbStore = this.db.getStore();
    try {
      await store.beginTransaction();
      try {
        const revision: number = await this.queryStructureRevision(store, noteId);
        const before: PageInfo[] = await this.queryPages(store, noteId);
        if (useOriginalOperation && await hasAlignedOriginalPageState(store, noteId)) {
          const anchorIndex: number = afterPageId === undefined
            ? before.length - 1 : this.findPageIndex(before, afterPageId);
          if (afterPageId !== undefined && anchorIndex < 0) {
            throw new Error('addPage anchor does not belong to note');
          }
          const restored: boolean = history !== undefined && history.effect === HistoryEffect.REDO &&
            await originalPageIdentityExists(store, noteId, page.pageId);
          const assignedPage: PageInfo = restored
            ? (await persistOriginalPageVisibility(store, noteId, page.pageId, false)).page
            : (await persistOriginalCreatePage(store, noteId, null,
              afterPageId === undefined ? null : afterPageId)).page;
          const after: PageInfo[] = await this.queryPages(store, noteId);
          if (history !== undefined) {
            await this.appendStructureHistoryMutation(
              store, noteId, revision, before, after, OpType.CREATE_PAGE, history);
          }
          const materializedIndex: number = this.findPageIndex(after, assignedPage.pageId);
          if (materializedIndex < 0) {
            throw new Error('original CreatePage did not materialize its assigned page');
          }
          if (!restored && materializedIndex !== anchorIndex + 1) {
            throw new Error('original CreatePage did not land after its anchor');
          }
          await store.commit();
          return this.clonePage(after[materializedIndex]);
        }
        const assignedPage: PageInfo = this.clonePage(page);
        if (afterPageId !== undefined) {
          const anchorIndex: number = this.findPageIndex(before, afterPageId);
          if (anchorIndex < 0) {
            throw new Error('addPage anchor does not belong to note');
          }
          assignedPage.pageIndex = anchorIndex + 1;
        } else {
          assignedPage.pageIndex = Math.min(Math.max(assignedPage.pageIndex, 0), before.length);
        }
        for (let index: number = before.length - 1; index >= 0; index--) {
          const existing: PageInfo = before[index];
          if (existing.pageIndex >= assignedPage.pageIndex) {
            await this.updatePageIndex(store, noteId, existing.pageId, existing.pageIndex + 1);
          }
        }
        const bucket: relationalStore.ValuesBucket = {
          'page_id': assignedPage.pageId,
          'note_id': noteId,
          'page_index': assignedPage.pageIndex,
          'size': assignedPage.size,
          'template': assignedPage.template,
          'orientation': assignedPage.orientation,
          'width_mm': assignedPage.widthMm,
          'height_mm': assignedPage.heightMm,
          'background_json': serializePageBackground(assignedPage.background),
          'original_page_in_asset': assignedPage.originalPageInAsset === undefined
            ? null : assignedPage.originalPageInAsset,
          'bookmarked': assignedPage.bookmarked === true ? 1 : 0,
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
    const release: MutexRelease = await editorPersistenceMutex.lock();
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
        if (await hasAlignedOriginalPageState(store, noteId) &&
          await originalPageIdentityExists(store, noteId, pageId)) {
          await persistOriginalPageVisibility(store, noteId, pageId, true);
          const after: PageInfo[] = await this.queryPages(store, noteId);
          if (history !== undefined) {
            await this.appendStructureHistoryMutation(
              store, noteId, revision, before, after, OpType.DELETE_PAGE, history);
          }
          await store.commit();
          return;
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
    const release: MutexRelease = await editorPersistenceMutex.lock();
    const store: relationalStore.RdbStore = this.db.getStore();
    try {
      await store.beginTransaction();
      try {
        const checkpoint: PageDeleteCheckpoint = await this.loadDeleteCheckpoint(store, noteId, actionId);
        const searches: CheckpointSearchRow[] = await this.loadCheckpointSearch(store, noteId, actionId);
        this.validateCheckpointSearch(searches);
        const checkpointElementIds: string[] = [];
        for (const element of checkpoint.elements) {
          checkpointElementIds.push(element.elementId);
        }
        await assertLivePageElementIdsAvailable(
          store, noteId, checkpoint.page.pageId, checkpointElementIds);
        const revision: number = await this.queryStructureRevision(store, noteId);
        const before: PageInfo[] = await this.queryPages(store, noteId);
        if (checkpoint.page.pageIndex < 0 || checkpoint.page.pageIndex > before.length ||
          this.findPageIndex(before, checkpoint.page.pageId) >= 0) {
          throw new Error('deleted-page checkpoint no longer matches page membership');
        }
        if (await hasAlignedOriginalPageState(store, noteId) &&
          await originalPageIdentityExists(store, noteId, checkpoint.page.pageId)) {
          await persistOriginalPageVisibility(store, noteId, checkpoint.page.pageId, false);
          const after: PageInfo[] = await this.queryPages(store, noteId);
          await this.appendStructureHistoryMutation(
            store, noteId, revision, before, after, OpType.CREATE_PAGE, history);
          await store.commit();
          return;
        }
        await this.restoreCheckpointedPage(store, noteId, checkpoint, searches, before);
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

  // Original de2.i delete-compensation: when deleting pages would leave the
  // note with fewer than two, the same op stream appends
  // u5j.i(x09, list2.size() - 1, 0, 14) — a blank page lands at the victim's
  // slot so the note always retains a page. For the single-page delete flow
  // this fires exactly when before.length <= 2; the anchor is the
  // second-to-last page (index size - 1 insertion), which makes the inserted
  // page occupy the victim's visible slot in every case.
  async deletePageWithCompensation(noteId: string, pageId: string,
    history: HistoryMetadata): Promise<PageInfo> {
    validateHistoryMetadata(history);
    if (noteId.length === 0 || pageId.length === 0 ||
      history.effect !== HistoryEffect.PUSH) {
      throw new Error('deletePageWithCompensation requires PUSH history');
    }
    const release: MutexRelease = await editorPersistenceMutex.lock();
    const store: relationalStore.RdbStore = this.db.getStore();
    try {
      await store.beginTransaction();
      try {
        const revision: number = await this.queryStructureRevision(store, noteId);
        const before: PageInfo[] = await this.queryPages(store, noteId);
        if (before.length < 1 || before.length > 2) {
          throw new Error('delete compensation only applies below three pages');
        }
        const victimIndex: number = this.findPageIndex(before, pageId);
        if (victimIndex < 0) {
          throw new Error('page does not belong to note');
        }
        await this.createDeleteCheckpoint(store, noteId, pageId, before, history);
        let compensation: PageInfo;
        if (await hasAlignedOriginalPageState(store, noteId) &&
          await originalPageIdentityExists(store, noteId, pageId)) {
          await persistOriginalPageVisibility(store, noteId, pageId, true);
          const anchorPageId: string | null =
            before.length >= 2 ? before[before.length - 2].pageId : null;
          compensation = (await persistOriginalCreatePage(
            store, noteId, null, anchorPageId)).page;
        } else {
          await this.physicalDeletePage(store, noteId, before, pageId);
          compensation = this.newCompensationPage(before[victimIndex]);
          await this.insertPageInfoAt(store, noteId, compensation,
            Math.min(victimIndex, before.length - 1));
        }
        const after: PageInfo[] = await this.queryPages(store, noteId);
        const expectedIndex: number = Math.min(victimIndex, after.length - 1);
        if (after.length !== before.length || expectedIndex < 0 ||
          after[expectedIndex].pageId !== compensation.pageId ||
          this.findPageIndex(after, pageId) >= 0) {
          throw new Error('delete compensation did not land at the victim slot');
        }
        await this.appendDeletePageCompensationCompanion(store, noteId, revision,
          pageId, after[expectedIndex], before, after, history);
        await store.commit();
        return clonePageInfo(compensation);
      } catch (e) {
        await store.rollBack();
        throw new Error(`deletePageWithCompensation failed: ${JSON.stringify(e)}`);
      }
    } finally {
      release();
    }
  }

  // UNDO of a compensated delete restores the victim (unhide or checkpoint
  // restore) and removes the inserted page — the mirror of the original's
  // single op stream, journaled by one companion.
  async undoDeletePageWithCompensation(noteId: string, actionId: string,
    compensationPageId: string, history: HistoryMetadata): Promise<void> {
    validateHistoryMetadata(history);
    if (noteId.length === 0 || actionId.length === 0 || compensationPageId.length === 0 ||
      history.actionId !== actionId || history.effect !== HistoryEffect.UNDO) {
      throw new Error('undoDeletePageWithCompensation requires matching UNDO history');
    }
    const release: MutexRelease = await editorPersistenceMutex.lock();
    const store: relationalStore.RdbStore = this.db.getStore();
    try {
      await store.beginTransaction();
      try {
        const checkpoint: PageDeleteCheckpoint =
          await this.loadDeleteCheckpoint(store, noteId, actionId);
        const revision: number = await this.queryStructureRevision(store, noteId);
        const before: PageInfo[] = await this.queryPages(store, noteId);
        const victimId: string = checkpoint.page.pageId;
        const compensationIndex: number = this.findPageIndex(before, compensationPageId);
        if (compensationIndex < 0 || this.findPageIndex(before, victimId) >= 0) {
          throw new Error('compensated delete state no longer matches page membership');
        }
        if (await hasAlignedOriginalPageState(store, noteId) &&
          await originalPageIdentityExists(store, noteId, victimId)) {
          await persistOriginalPageVisibility(store, noteId, victimId, false);
          await persistOriginalPageVisibility(store, noteId, compensationPageId, true);
        } else {
          const searches: CheckpointSearchRow[] =
            await this.loadCheckpointSearch(store, noteId, actionId);
          this.validateCheckpointSearch(searches);
          const checkpointElementIds: string[] = [];
          for (const element of checkpoint.elements) {
            checkpointElementIds.push(element.elementId);
          }
          await assertLivePageElementIdsAvailable(
            store, noteId, checkpoint.page.pageId, checkpointElementIds);
          await this.restoreCheckpointedPage(store, noteId, checkpoint, searches, before);
          const restored: PageInfo[] = before.map((page: PageInfo): PageInfo => this.clonePage(page));
          restored.splice(Math.min(checkpoint.page.pageIndex, restored.length), 0,
            this.clonePage(checkpoint.page));
          for (let index: number = 0; index < restored.length; index++) {
            restored[index].pageIndex = index;
          }
          await this.physicalDeletePage(store, noteId, restored, compensationPageId);
        }
        const after: PageInfo[] = await this.queryPages(store, noteId);
        await this.appendDeletePageCompensationCompanion(store, noteId, revision,
          victimId, before[compensationIndex], before, after, history);
        await store.commit();
      } catch (e) {
        await store.rollBack();
        throw new Error(`undoDeletePageWithCompensation failed: ${JSON.stringify(e)}`);
      }
    } finally {
      release();
    }
  }

  // REDO of a compensated delete re-hides the victim and restores the
  // inserted page's visibility — symmetric with the push transaction.
  async redoDeletePageWithCompensation(noteId: string, actionId: string,
    compensationPage: PageInfo, history: HistoryMetadata): Promise<void> {
    validateHistoryMetadata(history);
    if (noteId.length === 0 || actionId.length === 0 || compensationPage.pageId.length === 0 ||
      history.actionId !== actionId || history.effect !== HistoryEffect.REDO) {
      throw new Error('redoDeletePageWithCompensation requires matching REDO history');
    }
    const release: MutexRelease = await editorPersistenceMutex.lock();
    const store: relationalStore.RdbStore = this.db.getStore();
    try {
      await store.beginTransaction();
      try {
        const checkpoint: PageDeleteCheckpoint =
          await this.loadDeleteCheckpoint(store, noteId, actionId);
        const victimId: string = checkpoint.page.pageId;
        await this.verifyDeleteCheckpointState(store, noteId, victimId, actionId);
        const revision: number = await this.queryStructureRevision(store, noteId);
        const before: PageInfo[] = await this.queryPages(store, noteId);
        if (this.findPageIndex(before, victimId) < 0 ||
          this.findPageIndex(before, compensationPage.pageId) >= 0) {
          throw new Error('compensated delete state no longer matches page membership');
        }
        if (await hasAlignedOriginalPageState(store, noteId) &&
          await originalPageIdentityExists(store, noteId, victimId)) {
          await persistOriginalPageVisibility(store, noteId, victimId, true);
          await persistOriginalPageVisibility(store, noteId, compensationPage.pageId, false);
        } else {
          await this.physicalDeletePage(store, noteId, before, victimId);
          await this.insertPageInfoAt(store, noteId, compensationPage,
            Math.min(compensationPage.pageIndex, before.length - 1));
        }
        const after: PageInfo[] = await this.queryPages(store, noteId);
        await this.appendDeletePageCompensationCompanion(store, noteId, revision,
          victimId, compensationPage, before, after, history);
        await store.commit();
      } catch (e) {
        await store.rollBack();
        throw new Error(`redoDeletePageWithCompensation failed: ${JSON.stringify(e)}`);
      }
    } finally {
      release();
    }
  }

  // Legacy (non-original) checkpoint restore: remap live indexes to negative
  // placeholders, re-insert the checkpointed page at its recorded index, then
  // restore its element and search rows.
  private async restoreCheckpointedPage(store: relationalStore.RdbStore, noteId: string,
    checkpoint: PageDeleteCheckpoint, searches: CheckpointSearchRow[],
    before: PageInfo[]): Promise<void> {
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
  }

  private async appendDeletePageCompensationCompanion(store: relationalStore.RdbStore,
    noteId: string, fromRevision: number, deletedPageId: string, insertedPage: PageInfo,
    before: PageInfo[], after: PageInfo[], history: HistoryMetadata): Promise<void> {
    const toRevision: number = await this.queryStructureRevision(store, noteId);
    if (toRevision <= fromRevision) {
      throw new Error('compensated delete did not advance the structure revision');
    }
    const mutation: DeletePageCompensationMutation = {
      fromRevision: fromRevision,
      toRevision: toRevision,
      deletedPageId: deletedPageId,
      insertedPage: clonePageInfo(insertedPage),
      pageOrderBefore: this.pageOrderIds(before),
      pageOrderAfter: this.pageOrderIds(after),
    };
    const identity: AllocatedOperationIdentity = await allocateOperationIdentity(store, noteId);
    await appendOperation(store, {
      noteId: noteId, opId: identity.opId, opType: OpType.DELETE_PAGE_COMPENSATION,
      payload: encodeDeletePageCompensationMutation(mutation),
      clientTime: identity.clientTime, opTimestamp: identity.timestamp,
      editorSiteId: identity.siteId, history: history,
    });
  }

  // Physical (non-original) page delete: remove the row and compact the
  // following page_index values — mirrors deletePageInternal's legacy tail.
  private async physicalDeletePage(store: relationalStore.RdbStore, noteId: string,
    pages: PageInfo[], pageId: string): Promise<void> {
    const predicates = new relationalStore.RdbPredicates('page_info');
    predicates.equalTo('note_id', noteId);
    predicates.equalTo('page_id', pageId);
    const deleted: number = await store.delete(predicates);
    if (deleted !== 1) {
      throw new Error(`expected to delete one page, deleted ${deleted}`);
    }
    let targetIndex: number = 0;
    for (const page of pages) {
      if (page.pageId === pageId) {
        continue;
      }
      if (page.pageIndex !== targetIndex) {
        await this.updatePageIndex(store, noteId, page.pageId, targetIndex);
      }
      targetIndex++;
    }
  }

  // Physical (non-original) page insert at an arbitrary index; the UNIQUE
  // (note_id, page_index) index requires descending shifts.
  private async insertPageInfoAt(store: relationalStore.RdbStore, noteId: string,
    page: PageInfo, targetIndex: number): Promise<void> {
    const pages: PageInfo[] = await this.queryPages(store, noteId);
    const index: number = Math.min(Math.max(targetIndex, 0), pages.length);
    for (let i: number = pages.length - 1; i >= 0; i--) {
      const existing: PageInfo = pages[i];
      if (existing.pageIndex >= index) {
        await this.updatePageIndex(store, noteId, existing.pageId, existing.pageIndex + 1);
      }
    }
    const inserted: PageInfo = this.clonePage(page);
    inserted.pageIndex = index;
    const bucket: relationalStore.ValuesBucket = {
      'page_id': inserted.pageId,
      'note_id': noteId,
      'page_index': inserted.pageIndex,
      'size': inserted.size,
      'template': inserted.template,
      'orientation': inserted.orientation,
      'width_mm': inserted.widthMm,
      'height_mm': inserted.heightMm,
      'background_json': serializePageBackground(inserted.background),
      'original_page_in_asset': inserted.originalPageInAsset === undefined
        ? null : inserted.originalPageInAsset,
      'bookmarked': inserted.bookmarked === true ? 1 : 0,
    };
    await store.insert('page_info', bucket);
  }

  // The original's compensation page is a blank page on the note default
  // background (u5j.i -> haj.a(anchor, null, 1, UNBOOKMARKED, 16)); the legacy
  // mirror borrows the victim's dimensions with a null background so the
  // note-level default resolves at read time.
  private newCompensationPage(victim: PageInfo): PageInfo {
    return {
      pageId: `comp-${Date.now().toString(36)}${Math.random().toString(36).slice(2, 8)}`,
      pageIndex: 0,
      size: victim.size,
      template: victim.template,
      orientation: victim.orientation,
      widthMm: victim.widthMm,
      heightMm: victim.heightMm,
      background: null,
      bookmarked: false,
    };
  }

  // Original n9j Duplicate action (fd2 case 5 → de2.r → ae2 default): u5j.e
  // serializes the page's effective background (wz9.u → B() + l7j.c PDF
  // single-page collapse), de2.j anchors the copy after the last selected
  // page, and the transcode path re-issues element identities. Harmony emits
  // an original CreatePage anchored at the source page identity plus the
  // compound clipboard-paste op for the elements; the DUPLICATE_PAGE
  // companion keeps durable history because a mid-note insert is not an
  // ordinary tail CREATE_PAGE.
  async duplicatePage(noteId: string, sourcePageId: string,
    history?: HistoryMetadata): Promise<PageInfo> {
    if (noteId.length === 0 || sourcePageId.length === 0) {
      throw new Error('duplicatePage failed: note ID and source page ID are required');
    }
    const release: MutexRelease = await editorPersistenceMutex.lock();
    const store: relationalStore.RdbStore = this.db.getStore();
    try {
      await store.beginTransaction();
      try {
        const revision: number = await this.queryStructureRevision(store, noteId);
        const before: PageInfo[] = await this.queryPages(store, noteId);
        const sourceIndex: number = this.findPageIndex(before, sourcePageId);
        if (sourceIndex < 0) {
          throw new Error('duplicate page source does not belong to note');
        }
        if (!await hasAlignedOriginalPageState(store, noteId) ||
          !await originalPageIdentityExists(store, noteId, sourcePageId)) {
          throw new Error('duplicatePage requires aligned original page identity coverage');
        }
        const background: PageBackground | null =
          duplicatedOriginalPageBackground(before[sourceIndex]);
        const page: PageInfo = await this.insertPageAfterAnchor(store, noteId,
          before, revision, sourceIndex, background,
          before[sourceIndex].bookmarked === true, history);
        await store.commit();
        return clonePageInfo(page);
      } catch (e) {
        await store.rollBack();
        throw new Error(`duplicatePage failed: ${JSON.stringify(e)}`);
      }
    } finally {
      release();
    }
  }

  // Original n9j Paste (mg2.b CopiedPagesData -> lg2/m1d.c0 apply): identical
  // journal shape to Duplicate — an anchored CreatePage plus the element
  // transcode — except the page metadata comes from the clipboard record
  // rather than a live source page. The DUPLICATE_PAGE companion carries the
  // anchor identity in sourcePageId so undo/redo resolve the same way.
  async insertCopiedPage(noteId: string, anchorPageId: string,
    background: PageBackground | null, bookmarked: boolean,
    history?: HistoryMetadata): Promise<PageInfo> {
    if (noteId.length === 0 || anchorPageId.length === 0) {
      throw new Error('insertCopiedPage failed: note ID and anchor page ID are required');
    }
    const release: MutexRelease = await editorPersistenceMutex.lock();
    const store: relationalStore.RdbStore = this.db.getStore();
    try {
      await store.beginTransaction();
      try {
        const revision: number = await this.queryStructureRevision(store, noteId);
        const before: PageInfo[] = await this.queryPages(store, noteId);
        const anchorIndex: number = this.findPageIndex(before, anchorPageId);
        if (anchorIndex < 0) {
          throw new Error('copied page anchor does not belong to note');
        }
        if (!await hasAlignedOriginalPageState(store, noteId) ||
          !await originalPageIdentityExists(store, noteId, anchorPageId)) {
          throw new Error('insertCopiedPage requires aligned original page identity coverage');
        }
        const page: PageInfo = await this.insertPageAfterAnchor(store, noteId,
          before, revision, anchorIndex, background, bookmarked, history);
        await store.commit();
        return clonePageInfo(page);
      } catch (e) {
        await store.rollBack();
        throw new Error(`insertCopiedPage failed: ${JSON.stringify(e)}`);
      }
    } finally {
      release();
    }
  }

  private async insertPageAfterAnchor(store: relationalStore.RdbStore,
    noteId: string, before: PageInfo[], revision: number, anchorIndex: number,
    background: PageBackground | null, bookmarked: boolean,
    history?: HistoryMetadata): Promise<PageInfo> {
    const anchorPageId: string = before[anchorIndex].pageId;
    const mutation: PersistedOriginalPageMutation =
      await persistOriginalDuplicatePage(store, noteId, anchorPageId, background,
        bookmarked);
    const after: PageInfo[] = await this.queryPages(store, noteId);
    if (after.length !== before.length + 1 ||
      after[anchorIndex + 1].pageId !== mutation.page.pageId) {
      throw new Error('inserted page was not placed after its anchor');
    }
    if (history !== undefined) {
      const currentRevision: number = await this.queryStructureRevision(store, noteId);
      if (currentRevision !== revision + 1) {
        throw new Error('page insert reducer did not advance the structure revision');
      }
      const duplicate: DuplicatePageMutation = {
        fromRevision: revision,
        toRevision: revision + 1,
        sourcePageId: anchorPageId,
        pageId: mutation.page.pageId,
        pageOrderBefore: this.pageOrderIds(before),
        pageOrderAfter: this.pageOrderIds(after),
      };
      const identity: AllocatedOperationIdentity = await allocateOperationIdentity(store, noteId);
      await appendOperation(store, {
        noteId: noteId, opId: identity.opId, opType: OpType.DUPLICATE_PAGE,
        payload: encodeDuplicatePageMutation(duplicate),
        clientTime: identity.clientTime, opTimestamp: identity.timestamp,
        editorSiteId: identity.siteId, history: history,
      });
    }
    return mutation.page;
  }

  // Redo of a DUPLICATE_PAGE action restores the hidden duplicate through the
  // original page-visibility write (the page content was never removed).
  async restoreDuplicatedPage(noteId: string, pageId: string,
    history: HistoryMetadata): Promise<void> {
    validateHistoryMetadata(history);
    if (noteId.length === 0 || pageId.length === 0 ||
      history.effect !== HistoryEffect.REDO) {
      throw new Error('restoreDuplicatedPage requires matching REDO history');
    }
    const release: MutexRelease = await editorPersistenceMutex.lock();
    const store: relationalStore.RdbStore = this.db.getStore();
    try {
      await store.beginTransaction();
      try {
        const revision: number = await this.queryStructureRevision(store, noteId);
        const before: PageInfo[] = await this.queryPages(store, noteId);
        if (this.findPageIndex(before, pageId) >= 0) {
          throw new Error('duplicated page is already live');
        }
        if (!await hasAlignedOriginalPageState(store, noteId) ||
          !await originalPageIdentityExists(store, noteId, pageId)) {
          throw new Error('duplicated page has no restorable original identity');
        }
        await persistOriginalPageVisibility(store, noteId, pageId, false);
        const after: PageInfo[] = await this.queryPages(store, noteId);
        await this.appendStructureHistoryMutation(
          store, noteId, revision, before, after, OpType.CREATE_PAGE, history);
        await store.commit();
      } catch (e) {
        await store.rollBack();
        throw new Error(`restoreDuplicatedPage failed: ${JSON.stringify(e)}`);
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
    const release: MutexRelease = await editorPersistenceMutex.lock();
    const store: relationalStore.RdbStore = this.db.getStore();
    try {
      await store.beginTransaction();
      try {
        const noteId: string = await this.queryPageNoteId(store, page.pageId);
        const revision: number = await this.queryStructureRevision(store, noteId);
        const before: PageInfo[] = await this.queryPages(store, noteId);
        if (await originalPageIdentityExists(store, noteId, page.pageId)) {
          // Original zd2/u5j.s parity: page-scoped settings (rotate) write a
          // ModifyPage field-2 m2d/nz9 register, not the local UPDATE_PAGE
          // bucket. The reducer materializes size/template/orientation/dims.
          const pageIndexOriginal: number = this.findPageIndex(before, page.pageId);
          if (pageIndexOriginal < 0 || page.pageIndex !== before[pageIndexOriginal].pageIndex) {
            throw new Error('page settings cannot change page order');
          }
          if (this.samePage(before[pageIndexOriginal], page)) {
            await store.commit();
            return;
          }
          await persistOriginalPageBackground(store, noteId, page.pageId,
            page.background === undefined ? null : page.background);
          const afterOriginal: PageInfo[] = await this.queryPages(store, noteId);
          if (history !== undefined) {
            await this.appendStructureHistoryMutation(store, noteId, revision, before,
              afterOriginal, OpType.UPDATE_PAGE, history);
          }
          await store.commit();
          return;
        }
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
          'background_json': serializePageBackground(page.background),
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

  async reorderPages(noteId: string, pageIds: string[], movedPageId?: string,
    history?: HistoryMetadata): Promise<void> {
    if (noteId.length === 0) {
      throw new Error('reorderPages failed: note ID is required');
    }
    const release: MutexRelease = await editorPersistenceMutex.lock();
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
        if (await this.noteHasOriginalPages(store, noteId)) {
          if (movedPageId === undefined || movedPageId.length === 0) {
            throw new Error('original page reorder requires the moved page identity');
          }
          await persistOriginalPageReorder(store, noteId, pageIds, movedPageId);
          const after: PageInfo[] = await this.queryPages(store, noteId);
          if (history !== undefined) {
            await this.appendStructureHistoryMutation(
              store, noteId, revision, before, after, OpType.REORDER_PAGES, history);
          }
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

  async setPageBookmarked(noteId: string, pageId: string, bookmarked: boolean): Promise<PageInfo> {
    if (noteId.length === 0 || pageId.length === 0) {
      throw new Error('setPageBookmarked failed: note ID and page ID are required');
    }
    const release: MutexRelease = await editorPersistenceMutex.lock();
    const store: relationalStore.RdbStore = this.db.getStore();
    try {
      await store.beginTransaction();
      try {
        if (await originalPageIdentityExists(store, noteId, pageId)) {
          // Original wz9.bookmarkedRegister: the ModifyPage op wins by LWW and
          // materializes page_info.bookmarked inside the reducer.
          const persisted = await persistOriginalPageBookmark(store, noteId, pageId, bookmarked);
          await store.commit();
          return persisted.page;
        }
        const bucket: relationalStore.ValuesBucket = { 'bookmarked': bookmarked ? 1 : 0 };
        const predicates = new relationalStore.RdbPredicates('page_info');
        predicates.equalTo('note_id', noteId);
        predicates.equalTo('page_id', pageId);
        const updated: number = await store.update(bucket, predicates);
        if (updated !== 1) {
          throw new Error(`expected to update one page, updated ${updated}`);
        }
        const pages: PageInfo[] = await this.queryPages(store, noteId);
        const index: number = this.findPageIndex(pages, pageId);
        if (index < 0) {
          throw new Error('bookmarked page does not belong to note');
        }
        await store.commit();
        return this.clonePage(pages[index]);
      } catch (e) {
        await store.rollBack();
        throw new Error(`setPageBookmarked failed: ${JSON.stringify(e)}`);
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
      background: this.readBackground(resultSet),
      originalPageInAsset: this.readPageInAsset(resultSet),
      bookmarked: resultSet.getLong(resultSet.getColumnIndex('bookmarked')) === 1,
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
    if (pages.some((page: PageInfo): boolean => page.background === null) &&
      await this.noteHasOriginalPages(store, noteId)) {
      const fallback: PageBackground = (await readEffectiveNoteBackground(store, noteId)).background;
      for (const page of pages) {
        if (page.background === null) {
          page.noteBackgroundFallback = clonePageBackground(fallback);
        }
      }
    }
    return pages;
  }

  private async noteHasOriginalPages(store: relationalStore.RdbStore, noteId: string): Promise<boolean> {
    const rows = await store.querySql(
      'SELECT 1 FROM original_page_identity WHERE note_id = ? LIMIT 1', [noteId]);
    try {
      return rows.goToFirstRow();
    } finally {
      rows.close();
    }
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

  private async appendStructureHistoryMutation(store: relationalStore.RdbStore, noteId: string,
    revision: number, before: PageInfo[], after: PageInfo[], expectedType: OpType,
    history: HistoryMetadata): Promise<void> {
    const mutation: PageStructureMutation = createPageStructureMutation(
      revision, revision + 1, before, after);
    const opType: OpType = classifyPageStructureMutation(mutation);
    if (opType !== expectedType) {
      throw new Error(`page history mutation type mismatch: expected ${expectedType}, got ${opType}`);
    }
    const currentRevision: number = await this.queryStructureRevision(store, noteId);
    if (currentRevision !== mutation.toRevision) {
      throw new Error('original page reducer did not advance the expected structure revision');
    }
    const identity: AllocatedOperationIdentity = await allocateOperationIdentity(store, noteId);
    await appendOperation(store, {
      noteId: noteId, opId: identity.opId, opType: opType,
      payload: encodePageStructureMutation(mutation), clientTime: identity.clientTime,
      opTimestamp: identity.timestamp, editorSiteId: identity.siteId, history: history,
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
      'background_json': serializePageBackground(page.background),
      'original_page_in_asset': page.originalPageInAsset === undefined ? null : page.originalPageInAsset,
      'bookmarked': page.bookmarked === true ? 1 : 0,
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
      `SELECT page_id, page_index, size, template, orientation, width_mm, height_mm, background_json,
        original_page_in_asset, bookmarked,
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
        background: this.readBackground(resultSet),
        originalPageInAsset: this.readPageInAsset(resultSet),
        bookmarked: resultSet.getLong(resultSet.getColumnIndex('bookmarked')) === 1,
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
    const seen: Set<string> = new Set<string>();
    for (let index: number = 0; index < elements.length; index++) {
      const element: PageDeleteCheckpointElement = elements[index];
      if (element.elementId.length === 0 || !Number.isSafeInteger(element.kind) ||
        element.kind < PageElementKind.STROKE ||
        element.kind > PageElementKind.MATH || element.revision !== contentRevision ||
        element.elementOrder !== index || seen.has(element.elementId) ||
        element.payload.length === 0) {
        throw new Error('deleted-page checkpoint contains an invalid element');
      }
      seen.add(element.elementId);
      try {
        decodeStoredPageElement(element.elementId, element.kind, element.payload);
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
      'background_json': serializePageBackground(page.background),
      'original_page_in_asset': page.originalPageInAsset === undefined ? null : page.originalPageInAsset,
      'bookmarked': page.bookmarked === true ? 1 : 0,
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

  private pageOrderIds(pages: PageInfo[]): string[] {
    const ids: string[] = [];
    for (const page of pages) {
      ids.push(page.pageId);
    }
    return ids;
  }

  private samePage(left: PageInfo, right: PageInfo): boolean {
    return left.pageId === right.pageId && left.pageIndex === right.pageIndex &&
      left.size === right.size && left.template === right.template &&
      left.orientation === right.orientation && left.widthMm === right.widthMm &&
      left.heightMm === right.heightMm && left.originalPageInAsset === right.originalPageInAsset &&
      samePageBackground(left.background, right.background);
  }

  private clonePage(page: PageInfo): PageInfo {
    return clonePageInfo(page);
  }

  private readBackground(resultSet: relationalStore.ResultSet): PageBackground | null {
    const column: number = resultSet.getColumnIndex('background_json');
    return parsePageBackground(resultSet.isColumnNull(column) ? null : resultSet.getString(column));
  }

  private readPageInAsset(resultSet: relationalStore.ResultSet): number | undefined {
    const column: number = resultSet.getColumnIndex('original_page_in_asset');
    return resultSet.isColumnNull(column) ? undefined : resultSet.getLong(column);
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
