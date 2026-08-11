import { relationalStore } from '@kit.ArkData';
import { PageInfo } from '../core/model/NoteTypes';
import { parsePageBackground } from '../core/model/PageBackgroundModel';
import { readEffectiveNoteBackground } from './OriginalSetMetadataOperation';
import { HistoryEffect, HistoryMetadata, OpType } from '../core/model/OpTypes';
import { taskpool, util } from '@kit.ArkTS';
import { OriginalInkCreateMetadata, StrokeElementData } from '../core/model/StrokeTypes';
import { ImageElement, MathElement, ShapeElement, TextBlockElement } from '../core/model/ElementTypes';
import { cloneImageElement, imageBlockWorldBounds } from '../core/model/ImageBlockGeometry';
import { cloneShapeElement, recomputeShapeBounds } from '../core/model/ShapeGeometry';
import { cloneTextBlockElement, textBlockWorldBounds } from '../core/model/TextBlockGeometry';
import { cloneMathElement, mathBlockWorldBounds } from '../core/model/MathBlockGeometry';
import {
  legacyPageElementOrder, materializePageElements, normalizePageElementOrder, OrderedPageElement,
  PageElementKind, PageElementRef,
} from '../core/model/PageElementOrder';
import { DatabaseManager } from './DatabaseManager';
import { LatestWriteQueue } from './LatestWriteQueue';
import { editorPersistenceMutex } from './EditorPersistenceMutex';
import { foldSearchText } from './SearchText';
import { SearchItemType } from './SearchItemType';
import { handwritingSourceChanged, pageSnapshotChanged, SearchSourceElement } from './SearchIndexPolicy';
import { allocateOperationIdentity, AllocatedOperationIdentity, appendOperation } from './OpStoreImpl';
import {
  classifyPageMutation, createPageMutation, encodePageMutationOp, PageMutationOpPayload,
} from './PageMutationOpCodec';
import { validateHistoryMetadata } from './PersistentHistoryMetadata';
import { OriginalSelectionGroup } from '../core/model/OriginalGroupSelection';
import {
  decodeOperationId, encodeOperationId, OperationIdentity, OriginalSequenceIdentity,
  validateOperationIdentity,
} from './OperationIdentity';
import { compareUnsignedLongDecimal } from './UnsignedDecimal';
import { encodeOriginalLocalCreateInk } from './OriginalCreateInkPayloadEncoder';
import {
  ORIGINAL_CREATE_INK_PAYLOAD_TYPE, OriginalCreateInkOperationApplier,
} from './OriginalCreateInkOperation';
import {
  encodeOriginalEntityVisibility,
} from './OriginalDeleteEntitiesPayloadEncoder';
import {
  ORIGINAL_DELETE_ENTITIES_PAYLOAD_TYPE, OriginalDeleteEntitiesOperationApplier,
} from './OriginalDeleteEntitiesOperation';
import {
  StoredSyncedOperation, SyncedOperationApplyResult, SyncedOperationInboxState,
} from './SyncedOperationInbox';
import { decodePersistedElement, encodePersistedElement, PersistedElement } from './PersistedElementCodec';

export { decodePersistedElement, encodePersistedElement, PersistedElement };

export interface LoadedElements {
  strokes: StrokeElementData[];
  textBlocks: TextBlockElement[];
  shapes: ShapeElement[];
  images: ImageElement[];
  mathBlocks: MathElement[];
  elementOrder: PageElementRef[];
  elements: OrderedPageElement[];
  groups: OriginalSelectionGroup[];
}

interface PersistedGroupMember {
  timestamp: number;
  siteId: number;
}

export interface FirstPageThumbnailState {
  page: PageInfo;
  revision: string;
}

interface PreparedElement {
  elementId: string;
  kind: number;
  payload: Uint8Array;
  searchText: string | null;
}

interface PreparedPageSave {
  noteId: string;
  pageId: string;
  elements: PreparedElement[];
  history?: HistoryMetadata;
}

export interface HistoryPageSnapshot {
  strokes: StrokeElementData[];
  textBlocks: TextBlockElement[];
  elementOrder: PageElementRef[];
  shapes: ShapeElement[];
  images: ImageElement[];
  mathBlocks?: MathElement[];
  history?: HistoryMetadata;
}

interface SearchBackfillPage {
  noteId: string;
  pageId: string;
  revision: number;
}

interface ParsedSearchText {
  subId: string;
  foldedText: string;
}

interface OriginalOrderEntry {
  key: string;
  timestamp: number;
  siteId: number;
  zIndex: string;
}

interface OriginalEntityVisibilityMutation {
  identity: OperationIdentity;
  deleted: boolean;
}

@Concurrent
function parseSearchTextPayloads(payloads: Uint8Array[]): ParsedSearchText[] {
  const result: ParsedSearchText[] = [];
  for (const payload of payloads) {
    try {
      // @Concurrent functions may only reference imports and locals.
      const decoder = util.TextDecoder.create('utf-8');
      const parsed = JSON.parse(decoder.decodeToString(payload)) as PersistedElement;
      if (parsed.kind === 'text' || parsed.kind === 'shape') {
        const text = parsed.data as TextBlockElement | ShapeElement;
        if (typeof text.id === 'string' && typeof text.richText === 'string') {
          result.push({ subId: text.id, foldedText: text.richText.toLowerCase() });
        }
      }
    } catch (_error) {
      // A corrupt snapshot stays loadable; it simply cannot contribute searchable text.
    }
  }
  return result;
}

export class StrokePersistence {
  private store: relationalStore.RdbStore | null = null;
  private saveQueues: Map<string, LatestWriteQueue<PreparedPageSave>> = new Map();
  private searchBackfillPromise: Promise<void> | null = null;

  initialize(db: DatabaseManager): void {
    this.store = db.getStore();
  }

  isReady(): boolean {
    return this.store !== null;
  }

  async reserveOriginalInkCreate(noteId: string, pageId: string,
    wallClockTime: number = Date.now()): Promise<OriginalInkCreateMetadata | null> {
    if (this.store === null) {
      throw new Error('StrokePersistence is not initialized');
    }
    return editorPersistenceMutex.runExclusive(async (): Promise<OriginalInkCreateMetadata | null> => {
      if (this.store === null) {
        throw new Error('StrokePersistence is not initialized');
      }
      const store: relationalStore.RdbStore = this.store;
      await store.beginTransaction();
      try {
        const page: OriginalSequenceIdentity | null = await this.readEligibleOriginalInkPage(
          store, noteId, pageId);
        if (page === null) {
          await store.commit();
          return null;
        }
        const identity: AllocatedOperationIdentity = await allocateOperationIdentity(
          store, noteId, wallClockTime);
        const maximumZIndex: string | null = await this.readMaximumOriginalZIndex(store, noteId, page);
        if (maximumZIndex !== null &&
          compareUnsignedLongDecimal(maximumZIndex, identity.clientTime.toString()) > 0) {
          await store.commit();
          return null;
        }
        await store.commit();
        return {
          timestamp: identity.timestamp, siteId: identity.siteId, clientTime: identity.clientTime,
          pageTimestamp: page.timestamp, pageSiteId: page.siteId, pageIndex: page.index,
          pencilSeed: 0,
        };
      } catch (e) {
        await store.rollBack();
        throw new Error(`reserve original CREATE_INK failed: ${JSON.stringify(e)}`);
      }
    });
  }

  queueSaveElements(noteId: string, pageId: string, strokes: StrokeElementData[],
    textBlocks: TextBlockElement[], elementOrder: PageElementRef[] = [], shapes: ShapeElement[] = [],
    preserveActionBoundary: boolean = false, history?: HistoryMetadata,
    images: ImageElement[] = [], mathBlocks: MathElement[] = []): number {
    if (this.store === null) {
      throw new Error('StrokePersistence is not initialized');
    }
    const snapshot: PreparedPageSave = this.prepareSave(
      noteId, pageId, strokes, textBlocks, elementOrder, shapes, images, mathBlocks, history);
    return this.getSaveQueue(noteId, pageId).enqueue(snapshot, preserveActionBoundary);
  }

  async flush(noteId: string, pageId: string): Promise<void> {
    const queue: LatestWriteQueue<PreparedPageSave> | undefined =
      this.saveQueues.get(this.saveKey(noteId, pageId));
    if (queue !== undefined) {
      await queue.flush();
    }
  }

  hasDirtySave(noteId: string, pageId: string): boolean {
    const queue: LatestWriteQueue<PreparedPageSave> | undefined =
      this.saveQueues.get(this.saveKey(noteId, pageId));
    return queue !== undefined && queue.isDirty();
  }

  async saveElements(noteId: string, pageId: string, strokes: StrokeElementData[],
    textBlocks: TextBlockElement[], elementOrder: PageElementRef[] = [], shapes: ShapeElement[] = [],
    images: ImageElement[] = [], mathBlocks: MathElement[] = []): Promise<void> {
    this.queueSaveElements(noteId, pageId, strokes, textBlocks, elementOrder, shapes,
      false, undefined, images, mathBlocks);
    await this.flush(noteId, pageId);
  }

  async saveHistoryGroup(noteId: string, pageId: string, initial: HistoryPageSnapshot,
    steps: HistoryPageSnapshot[]): Promise<void> {
    if (this.store === null || steps.length === 0) {
      throw new Error('history group cannot be saved');
    }
    const preparedInitial: PreparedPageSave = this.prepareSave(
      noteId, pageId, initial.strokes, initial.textBlocks, initial.elementOrder,
      initial.shapes, initial.images, initial.mathBlocks ?? []);
    const preparedSteps: PreparedPageSave[] = [];
    const actionIds: Set<string> = new Set<string>();
    let effect: HistoryEffect | null = null;
    for (const step of steps) {
      if (step.history === undefined) {
        throw new Error('history group metadata is invalid');
      }
      validateHistoryMetadata(step.history);
      if (step.history.effect === HistoryEffect.PUSH || actionIds.has(step.history.actionId) ||
        (effect !== null && effect !== step.history.effect)) {
        throw new Error('history group metadata is invalid');
      }
      actionIds.add(step.history.actionId);
      effect = step.history.effect;
      preparedSteps.push(this.prepareSave(
        noteId, pageId, step.strokes, step.textBlocks, step.elementOrder,
        step.shapes, step.images, step.mathBlocks ?? [], step.history));
    }
    await this.flush(noteId, pageId);
    await editorPersistenceMutex.runExclusive(async (): Promise<void> => {
      await this.writeHistoryGroupLocked(preparedInitial, preparedSteps);
    });
  }

  async replaceImportedHandwritingText(noteId: string, pageId: string, text: string): Promise<void> {
    if (this.store === null) {
      throw new Error('StrokePersistence is not initialized');
    }
    await editorPersistenceMutex.runExclusive(async (): Promise<void> => {
      if (this.store === null) {
        throw new Error('StrokePersistence is not initialized');
      }
      const store: relationalStore.RdbStore = this.store;
      await store.beginTransaction();
      try {
        await this.deletePageSearchType(store, noteId, pageId, SearchItemType.INK);
        const foldedText: string = foldSearchText(text);
        if (foldedText.trim().length > 0) {
          const bucket: relationalStore.ValuesBucket = {
            'note_id': noteId,
            'type': SearchItemType.INK,
            'sub_id': pageId,
            'page_id': pageId,
            'folded_text': foldedText,
            'rects': null,
          };
          await store.insert('search_item', bucket,
            relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
        }
        await store.commit();
      } catch (e) {
        await store.rollBack();
        throw new Error(`replace imported handwriting text failed: ${JSON.stringify(e)}`);
      }
    });
  }

  async loadElements(noteId: string, pageId: string): Promise<LoadedElements> {
    return this.loadMatchingElements(noteId, pageId);
  }

  async loadAllElements(noteId: string): Promise<LoadedElements> {
    return this.loadMatchingElements(noteId, null);
  }

  async loadFirstPageElements(noteId: string): Promise<LoadedElements> {
    if (this.store === null) {
      throw new Error('StrokePersistence is not initialized');
    }
    const pageSet = await this.store.querySql(
      'SELECT page_id FROM page_info WHERE note_id = ? ORDER BY page_index LIMIT 1', [noteId]);
    let pageId: string = '';
    if (pageSet.goToFirstRow()) {
      pageId = pageSet.getString(pageSet.getColumnIndex('page_id'));
    }
    pageSet.close();
    return pageId.length > 0 ? this.loadElements(noteId, pageId) :
      { strokes: [], textBlocks: [], shapes: [], images: [], mathBlocks: [],
        elementOrder: [], elements: [], groups: [] };
  }

  async getFirstPageThumbnailState(noteId: string): Promise<FirstPageThumbnailState | null> {
    if (this.store === null) {
      throw new Error('StrokePersistence is not initialized');
    }
    const resultSet = await this.store.querySql(
      `SELECT page.page_id AS page_id, page.page_index AS page_index, page.size AS size, page.template AS template,
        page.orientation AS orientation, page.width_mm AS width_mm, page.height_mm AS height_mm,
        page.background_json AS background_json, page.original_page_in_asset AS original_page_in_asset,
        page.content_revision AS content_revision,
        EXISTS(SELECT 1 FROM original_page_identity identity
          WHERE identity.note_id = page.note_id AND identity.page_id = page.page_id) AS original_page,
        (SELECT COUNT(*) FROM page_element_snapshot snapshot
         WHERE snapshot.note_id = page.note_id AND snapshot.page_id = page.page_id) AS element_count
       FROM page_info page WHERE page.note_id = ? ORDER BY page.page_index LIMIT 1`, [noteId]);
    try {
      if (!resultSet.goToFirstRow()) {
        return null;
      }
      const page: PageInfo = {
        pageId: resultSet.getString(resultSet.getColumnIndex('page_id')),
        pageIndex: resultSet.getLong(resultSet.getColumnIndex('page_index')),
        size: resultSet.getLong(resultSet.getColumnIndex('size')),
        template: resultSet.getLong(resultSet.getColumnIndex('template')),
        orientation: resultSet.getLong(resultSet.getColumnIndex('orientation')),
        widthMm: resultSet.getDouble(resultSet.getColumnIndex('width_mm')),
        heightMm: resultSet.getDouble(resultSet.getColumnIndex('height_mm')),
        background: parsePageBackground(resultSet.isColumnNull(resultSet.getColumnIndex('background_json'))
          ? null : resultSet.getString(resultSet.getColumnIndex('background_json'))),
        originalPageInAsset: resultSet.isColumnNull(resultSet.getColumnIndex('original_page_in_asset'))
          ? undefined : resultSet.getLong(resultSet.getColumnIndex('original_page_in_asset')),
      };
      let fallbackSignature: string = '';
      if (page.background === null &&
        resultSet.getLong(resultSet.getColumnIndex('original_page')) === 1) {
        page.noteBackgroundFallback = (await readEffectiveNoteBackground(this.store, noteId)).background;
        fallbackSignature = JSON.stringify(page.noteBackgroundFallback);
      }
      const maxRevision: number = resultSet.getLong(resultSet.getColumnIndex('content_revision'));
      const elementCount: number = resultSet.getLong(resultSet.getColumnIndex('element_count'));
      return {
        page: page,
        revision: `${page.pageId}:${page.size}:${page.template}:${page.orientation}:` +
          `${page.widthMm}:${page.heightMm}:${resultSet.isColumnNull(resultSet.getColumnIndex('background_json'))
            ? '' : resultSet.getString(resultSet.getColumnIndex('background_json'))}:` +
          `${page.originalPageInAsset === undefined ? '' : page.originalPageInAsset}:` +
          `${fallbackSignature}:${maxRevision}:${elementCount}`,
      };
    } finally {
      resultSet.close();
    }
  }

  async getNoteRevisionSignature(noteId: string): Promise<string> {
    if (this.store === null) {
      throw new Error('StrokePersistence is not initialized');
    }
    const resultSet = await this.store.querySql(
      `SELECT page_id, page_index, size, template, orientation, width_mm, height_mm,
        background_json, original_page_in_asset, content_revision
       FROM page_info WHERE note_id = ? ORDER BY page_index, page_id`, [noteId]);
    try {
      const rows: string[] = [];
      while (resultSet.goToNextRow()) {
        rows.push(`${resultSet.getString(resultSet.getColumnIndex('page_id'))},` +
          `${resultSet.getLong(resultSet.getColumnIndex('page_index'))},` +
          `${resultSet.getLong(resultSet.getColumnIndex('size'))},` +
          `${resultSet.getLong(resultSet.getColumnIndex('template'))},` +
          `${resultSet.getLong(resultSet.getColumnIndex('orientation'))},` +
          `${resultSet.getDouble(resultSet.getColumnIndex('width_mm'))},` +
          `${resultSet.getDouble(resultSet.getColumnIndex('height_mm'))},` +
          `${resultSet.isColumnNull(resultSet.getColumnIndex('background_json')) ? '' :
            resultSet.getString(resultSet.getColumnIndex('background_json'))},` +
          `${resultSet.isColumnNull(resultSet.getColumnIndex('original_page_in_asset')) ? '' :
            resultSet.getLong(resultSet.getColumnIndex('original_page_in_asset'))},` +
          `${resultSet.getLong(resultSet.getColumnIndex('content_revision'))}`);
      }
      return rows.join(';');
    } finally {
      resultSet.close();
    }
  }

  async backfillSearchIndex(): Promise<void> {
    if (this.store === null) {
      throw new Error('StrokePersistence is not initialized');
    }
    if (this.searchBackfillPromise !== null) {
      return this.searchBackfillPromise;
    }
    this.searchBackfillPromise = this.runSearchBackfill();
    try {
      await this.searchBackfillPromise;
    } finally {
      this.searchBackfillPromise = null;
    }
  }

  private async runSearchBackfill(): Promise<void> {
    while (true) {
      const pages: SearchBackfillPage[] = await this.loadPendingSearchPages(8);
      if (pages.length === 0) {
        return;
      }
      for (const page of pages) {
        const payloads: Uint8Array[] = await this.loadTextPayloads(page.noteId, page.pageId);
        const parsed = await taskpool.execute(parseSearchTextPayloads, payloads) as ParsedSearchText[];
        await editorPersistenceMutex.runExclusive(async (): Promise<void> => {
          await this.commitBackfilledPage(page, parsed);
        });
      }
    }
  }

  private async writePrepared(snapshot: PreparedPageSave, revision: number): Promise<void> {
    await editorPersistenceMutex.runExclusive(async (): Promise<void> => {
      await this.writePreparedLocked(snapshot, revision);
    });
  }

  private async writePreparedLocked(snapshot: PreparedPageSave, revision: number): Promise<void> {
    if (this.store === null) {
      throw new Error('StrokePersistence is not initialized');
    }
    const store: relationalStore.RdbStore = this.store;
    await store.beginTransaction();
    try {
      const revisionSet = await store.querySql(
        `SELECT content_revision AS current_revision
         FROM page_info WHERE note_id = ? AND page_id = ?`,
        [snapshot.noteId, snapshot.pageId]);
      let currentRevision: number = 0;
      try {
        if (!revisionSet.goToFirstRow()) {
          throw new Error('snapshot page does not exist');
        }
        currentRevision = revisionSet.getLong(revisionSet.getColumnIndex('current_revision'));
      } finally {
        revisionSet.close();
      }
      const current: SearchSourceElement[] = await this.loadCurrentSnapshot(store, snapshot.noteId, snapshot.pageId);
      if (!pageSnapshotChanged(current, snapshot.elements)) {
        await store.commit();
        return;
      }
      const snapshotRevision: number = currentRevision + 1;
      const mutation: PageMutationOpPayload = createPageMutation(
        snapshot.pageId, currentRevision, snapshotRevision, current, snapshot.elements);
      const originalVisibility: OriginalEntityVisibilityMutation | null =
        this.singleOriginalEntityVisibility(current, snapshot.elements);
      if (originalVisibility !== null) {
        await this.applyOriginalEntityVisibility(store, snapshot, originalVisibility,
          snapshotRevision);
        await this.rebuildPageSearchState(store, snapshot, snapshotRevision,
          handwritingSourceChanged(current, snapshot.elements));
        await this.appendHistoryCompanion(store, snapshot, mutation);
        await store.commit();
        return;
      }
      const originalCreate: PreparedElement | null = this.singleReservedOriginalCreate(
        current, snapshot.elements);
      if (originalCreate !== null) {
        await this.writeOriginalCreateInk(store, snapshot, current, originalCreate,
          mutation, currentRevision, snapshotRevision);
        await store.commit();
        return;
      }
      await this.blockOriginalInkAuthoring(store, snapshot.noteId, snapshot.pageId);
      const pageRevision: relationalStore.ValuesBucket = { 'content_revision': snapshotRevision };
      const pagePredicates = new relationalStore.RdbPredicates('page_info');
      pagePredicates.equalTo('note_id', snapshot.noteId);
      pagePredicates.equalTo('page_id', snapshot.pageId);
      const revisedPages: number = await store.update(pageRevision, pagePredicates);
      if (revisedPages !== 1) {
        throw new Error(`expected one page revision update, got ${revisedPages}`);
      }
      const sourceChanged: boolean = handwritingSourceChanged(current, snapshot.elements);
      const del = new relationalStore.RdbPredicates('page_element_snapshot');
      del.equalTo('note_id', snapshot.noteId);
      del.equalTo('page_id', snapshot.pageId);
      await store.delete(del);
      const buckets: relationalStore.ValuesBucket[] = [];
      for (let seq: number = 0; seq < snapshot.elements.length; seq++) {
        const element: PreparedElement = snapshot.elements[seq];
        buckets.push({
          'note_id': snapshot.noteId,
          'page_id': snapshot.pageId,
          'element_id': element.elementId,
          'kind': element.kind,
          'payload': element.payload,
          'revision': snapshotRevision,
          'element_order': seq,
        });
      }
      if (buckets.length > 0) {
        await store.batchInsert('page_element_snapshot', buckets);
      }
      await this.deletePageSearchType(
        store, snapshot.noteId, snapshot.pageId, SearchItemType.TEXT_BLOCK);
      if (sourceChanged) {
        await this.deletePageSearchType(store, snapshot.noteId, snapshot.pageId, SearchItemType.INK);
      }
      const searchBuckets: relationalStore.ValuesBucket[] = [];
      for (const element of snapshot.elements) {
        if (element.searchText !== null) {
          searchBuckets.push({
            'note_id': snapshot.noteId,
            'type': SearchItemType.TEXT_BLOCK,
            'sub_id': element.elementId,
            'page_id': snapshot.pageId,
            'folded_text': element.searchText,
            'rects': null,
          });
        }
      }
      for (const searchBucket of searchBuckets) {
        await store.insert('search_item', searchBucket,
          relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
      }
      const indexState: relationalStore.ValuesBucket = {
        'note_id': snapshot.noteId,
        'page_id': snapshot.pageId,
        'indexed_revision': snapshotRevision,
      };
      await store.insert('search_page_state', indexState,
        relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
      const identity: AllocatedOperationIdentity = await allocateOperationIdentity(store, snapshot.noteId);
      await appendOperation(store, {
        opId: identity.opId,
        noteId: snapshot.noteId,
        opType: classifyPageMutation(mutation),
        payload: encodePageMutationOp(mutation),
        clientTime: identity.clientTime,
        opTimestamp: identity.timestamp,
        editorSiteId: identity.siteId,
        history: snapshot.history,
      });
      await store.commit();
    } catch (e) {
      await store.rollBack();
      throw new Error(`saveElements revision ${revision} failed: ${JSON.stringify(e)}`);
    }
  }

  private singleReservedOriginalCreate(current: SearchSourceElement[],
    next: PreparedElement[]): PreparedElement | null {
    if (next.length !== current.length + 1) {
      return null;
    }
    for (let index: number = 0; index < current.length; index++) {
      if (current[index].elementId !== next[index].elementId ||
        current[index].kind !== next[index].kind ||
        !sameByteArrays(current[index].payload, next[index].payload)) {
        return null;
      }
    }
    const added: PreparedElement = next[next.length - 1];
    if (added.kind !== PageElementKind.STROKE) {
      return null;
    }
    try {
      const persisted: PersistedElement = decodePersistedElement(added.payload);
      if (persisted.kind !== 'stroke') {
        return null;
      }
      const stroke: StrokeElementData = persisted.data as StrokeElementData;
      const original: OriginalInkCreateMetadata | undefined = stroke.originalCreate;
      const identity: OperationIdentity | null = decodeOperationId(stroke.id);
      return original !== undefined && identity !== null &&
        identity.timestamp === original.timestamp && identity.siteId === original.siteId ? added : null;
    } catch (_error) {
      return null;
    }
  }

  private async writeOriginalCreateInk(store: relationalStore.RdbStore,
    snapshot: PreparedPageSave, current: SearchSourceElement[], added: PreparedElement,
    mutation: PageMutationOpPayload, currentRevision: number, snapshotRevision: number): Promise<void> {
    const persisted: PersistedElement = decodePersistedElement(added.payload);
    const stroke: StrokeElementData = persisted.data as StrokeElementData;
    const metadata: OriginalInkCreateMetadata = stroke.originalCreate as OriginalInkCreateMetadata;
    const page: OriginalSequenceIdentity = {
      timestamp: metadata.pageTimestamp, siteId: metadata.pageSiteId, index: metadata.pageIndex,
    };
    const eligible: OriginalSequenceIdentity | null = await this.readEligibleOriginalInkPage(
      store, snapshot.noteId, snapshot.pageId);
    if (eligible === null || eligible.timestamp !== page.timestamp || eligible.siteId !== page.siteId ||
      eligible.index !== page.index) {
      throw new Error('reserved local CREATE_INK page is no longer original-aligned');
    }
    const payload: Uint8Array = encodeOriginalLocalCreateInk(page, stroke);
    const operation: StoredSyncedOperation = localStoredOperation(
      snapshot.noteId, metadata, ORIGINAL_CREATE_INK_PAYLOAD_TYPE, payload,
      stroke.audioStartTime === undefined ? null : stroke.audioStartTime);
    const result: SyncedOperationApplyResult = await new OriginalCreateInkOperationApplier().apply(
      store, operation);
    if (result.deferredReason !== null) {
      throw new Error(`local CREATE_INK was deferred: ${result.deferredReason}`);
    }
    await appendOperation(store, {
      noteId: snapshot.noteId, opId: stroke.id, opType: OpType.ORIGINAL_CREATE_INK,
      payload: payload, clientTime: metadata.clientTime, opTimestamp: metadata.timestamp,
      editorSiteId: metadata.siteId, uploadImmediately: true,
    });
    const materialized: SearchSourceElement[] = await this.loadCurrentSnapshot(
      store, snapshot.noteId, snapshot.pageId);
    if (!samePreparedIdentityOrder(materialized, snapshot.elements)) {
      throw new Error('local CREATE_INK reducer produced an unexpected element order');
    }
    for (let index: number = 0; index < snapshot.elements.length; index++) {
      const element: PreparedElement = snapshot.elements[index];
      const predicates = new relationalStore.RdbPredicates('page_element_snapshot');
      predicates.equalTo('note_id', snapshot.noteId);
      predicates.equalTo('page_id', snapshot.pageId);
      predicates.equalTo('element_id', element.elementId);
      predicates.equalTo('kind', element.kind);
      const values: relationalStore.ValuesBucket = {
        'revision': snapshotRevision, 'element_order': index,
      };
      if (element.elementId === added.elementId && element.kind === added.kind) {
        values['payload'] = added.payload;
      }
      if (await store.update(values, predicates) !== 1) {
        throw new Error('local CREATE_INK snapshot reconciliation lost an element');
      }
    }
    await this.rebuildPageSearchState(store, snapshot, snapshotRevision, true);
    await this.appendHistoryCompanion(store, snapshot, mutation);
    if (currentRevision + 1 !== snapshotRevision) {
      throw new Error('local CREATE_INK revision contract changed');
    }
  }

  private async appendHistoryCompanion(store: relationalStore.RdbStore,
    snapshot: PreparedPageSave, mutation: PageMutationOpPayload): Promise<void> {
    const companion: AllocatedOperationIdentity = await allocateOperationIdentity(store, snapshot.noteId);
    await appendOperation(store, {
      noteId: snapshot.noteId, opId: companion.opId, opType: classifyPageMutation(mutation),
      payload: encodePageMutationOp(mutation), clientTime: companion.clientTime,
      opTimestamp: companion.timestamp, editorSiteId: companion.siteId, history: snapshot.history,
    });
  }

  private async rebuildPageSearchState(store: relationalStore.RdbStore,
    snapshot: PreparedPageSave, revision: number, sourceChanged: boolean): Promise<void> {
    await this.deletePageSearchType(store, snapshot.noteId, snapshot.pageId, SearchItemType.TEXT_BLOCK);
    if (sourceChanged) {
      await this.deletePageSearchType(store, snapshot.noteId, snapshot.pageId, SearchItemType.INK);
    }
    for (const element of snapshot.elements) {
      if (element.searchText !== null) {
        await store.insert('search_item', {
          'note_id': snapshot.noteId, 'type': SearchItemType.TEXT_BLOCK,
          'sub_id': element.elementId, 'page_id': snapshot.pageId,
          'folded_text': element.searchText, 'rects': null,
        }, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
      }
    }
    await store.insert('search_page_state', {
      'note_id': snapshot.noteId, 'page_id': snapshot.pageId, 'indexed_revision': revision,
    }, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
  }

  private async writeHistoryGroupLocked(initial: PreparedPageSave, steps: PreparedPageSave[]): Promise<void> {
    if (this.store === null) {
      throw new Error('StrokePersistence is not initialized');
    }
    const store: relationalStore.RdbStore = this.store;
    await store.beginTransaction();
    try {
      const revisionSet = await store.querySql(
        `SELECT content_revision AS current_revision
         FROM page_info WHERE note_id = ? AND page_id = ?`, [initial.noteId, initial.pageId]);
      let currentRevision: number = 0;
      try {
        if (!revisionSet.goToFirstRow()) {
          throw new Error('history group page does not exist');
        }
        currentRevision = revisionSet.getLong(revisionSet.getColumnIndex('current_revision'));
      } finally {
        revisionSet.close();
      }
      let current: SearchSourceElement[] = await this.loadCurrentSnapshot(store, initial.noteId, initial.pageId);
      if (pageSnapshotChanged(current, initial.elements)) {
        throw new Error('history group database source does not match the editor');
      }
      const original: SearchSourceElement[] = current;
      let sourceChanged: boolean = false;
      for (const step of steps) {
        if (!pageSnapshotChanged(current, step.elements) || step.history === undefined) {
          throw new Error('history group contains an empty mutation');
        }
        const nextRevision: number = currentRevision + 1;
        const mutation: PageMutationOpPayload = createPageMutation(
          step.pageId, currentRevision, nextRevision, current, step.elements);
        const originalVisibility: OriginalEntityVisibilityMutation | null =
          this.singleOriginalEntityVisibility(current, step.elements);
        if (originalVisibility === null) {
          await this.materializePreparedPage(store, step, currentRevision, nextRevision);
        } else {
          await this.applyOriginalEntityVisibility(store, step, originalVisibility,
            nextRevision);
        }
        const identity: AllocatedOperationIdentity = await allocateOperationIdentity(store, step.noteId);
        await appendOperation(store, {
          opId: identity.opId,
          noteId: step.noteId,
          opType: classifyPageMutation(mutation),
          payload: encodePageMutationOp(mutation),
          clientTime: identity.clientTime,
          opTimestamp: identity.timestamp,
          editorSiteId: identity.siteId,
          history: step.history,
        });
        sourceChanged = sourceChanged || handwritingSourceChanged(current, step.elements);
        currentRevision = nextRevision;
        current = step.elements;
      }
      const final: PreparedPageSave = steps[steps.length - 1];
      await this.rebuildPageSearchState(store, final, currentRevision,
        sourceChanged || handwritingSourceChanged(original, final.elements));
      await store.commit();
    } catch (e) {
      await store.rollBack();
      throw new Error(`save history group failed: ${JSON.stringify(e)}`);
    }
  }

  private singleOriginalEntityVisibility(current: SearchSourceElement[],
    next: PreparedElement[]): OriginalEntityVisibilityMutation | null {
    const deleted: boolean = current.length === next.length + 1;
    const undeleted: boolean = next.length === current.length + 1;
    if (!deleted && !undeleted) {
      return null;
    }
    const larger: (SearchSourceElement | PreparedElement)[] = deleted ? current : next;
    const smaller: (SearchSourceElement | PreparedElement)[] = deleted ? next : current;
    let largerIndex: number = 0;
    let smallerIndex: number = 0;
    let target: SearchSourceElement | PreparedElement | null = null;
    while (largerIndex < larger.length) {
      if (smallerIndex < smaller.length &&
        sameElement(larger[largerIndex], smaller[smallerIndex])) {
        largerIndex++;
        smallerIndex++;
      } else if (target === null) {
        target = larger[largerIndex++];
      } else {
        return null;
      }
    }
    if (target === null || smallerIndex !== smaller.length || target.kind !== PageElementKind.STROKE) {
      return null;
    }
    try {
      const persisted: PersistedElement = decodePersistedElement(target.payload);
      if (persisted.kind !== 'stroke') {
        return null;
      }
      const stroke: StrokeElementData = persisted.data as StrokeElementData;
      const identity: OperationIdentity | null = decodeOperationId(stroke.id);
      return stroke.originalCreate !== undefined && identity !== null ?
        { identity: identity, deleted: deleted } : null;
    } catch (_error) {
      return null;
    }
  }

  private async applyOriginalEntityVisibility(store: relationalStore.RdbStore,
    step: PreparedPageSave, visibility: OriginalEntityVisibilityMutation,
    expectedRevision: number): Promise<void> {
    const identity: AllocatedOperationIdentity = await allocateOperationIdentity(store, step.noteId);
    const payload: Uint8Array = encodeOriginalEntityVisibility(
      visibility.deleted ? [visibility.identity] : [], visibility.deleted ? [] : [visibility.identity]);
    const metadata: OriginalInkCreateMetadata = {
      timestamp: identity.timestamp, siteId: identity.siteId, clientTime: identity.clientTime,
      pageTimestamp: 0, pageSiteId: 0, pageIndex: 0,
      pencilSeed: 0,
    };
    const operation: StoredSyncedOperation = localStoredOperation(
      step.noteId, metadata, ORIGINAL_DELETE_ENTITIES_PAYLOAD_TYPE, payload, null);
    const result: SyncedOperationApplyResult = await new OriginalDeleteEntitiesOperationApplier().apply(
      store, operation);
    if (result.deferredReason !== null) {
      throw new Error(`local Ink visibility was deferred: ${result.deferredReason}`);
    }
    await appendOperation(store, {
      noteId: step.noteId, opId: identity.opId, opType: OpType.ORIGINAL_DELETE_ENTITIES,
      payload: payload, clientTime: identity.clientTime, opTimestamp: identity.timestamp,
      editorSiteId: identity.siteId, uploadImmediately: true,
    });
    const materialized: SearchSourceElement[] = await this.loadCurrentSnapshot(
      store, step.noteId, step.pageId);
    if (!samePreparedIdentityOrder(materialized, step.elements)) {
      throw new Error('local Ink visibility reducer produced an unexpected element order');
    }
    await this.reconcilePreparedRows(store, step, expectedRevision);
  }

  private async materializePreparedPage(store: relationalStore.RdbStore,
    step: PreparedPageSave, currentRevision: number, nextRevision: number): Promise<void> {
    await this.blockOriginalInkAuthoring(store, step.noteId, step.pageId);
    const predicates = new relationalStore.RdbPredicates('page_info');
    predicates.equalTo('note_id', step.noteId);
    predicates.equalTo('page_id', step.pageId);
    predicates.equalTo('content_revision', currentRevision);
    if (await store.update({ 'content_revision': nextRevision }, predicates) !== 1) {
      throw new Error('history page revision changed concurrently');
    }
    const del = new relationalStore.RdbPredicates('page_element_snapshot');
    del.equalTo('note_id', step.noteId);
    del.equalTo('page_id', step.pageId);
    await store.delete(del);
    const buckets: relationalStore.ValuesBucket[] = [];
    for (let index: number = 0; index < step.elements.length; index++) {
      const element: PreparedElement = step.elements[index];
      buckets.push({
        'note_id': step.noteId, 'page_id': step.pageId, 'element_id': element.elementId,
        'kind': element.kind, 'payload': element.payload, 'revision': nextRevision,
        'element_order': index,
      });
    }
    if (buckets.length > 0) {
      await store.batchInsert('page_element_snapshot', buckets);
    }
  }

  private async reconcilePreparedRows(store: relationalStore.RdbStore,
    step: PreparedPageSave, revision: number): Promise<void> {
    for (let index: number = 0; index < step.elements.length; index++) {
      const element: PreparedElement = step.elements[index];
      const predicates = new relationalStore.RdbPredicates('page_element_snapshot');
      predicates.equalTo('note_id', step.noteId);
      predicates.equalTo('page_id', step.pageId);
      predicates.equalTo('element_id', element.elementId);
      predicates.equalTo('kind', element.kind);
      if (await store.update({
        'payload': element.payload, 'revision': revision, 'element_order': index,
      }, predicates) !== 1) {
        throw new Error('history original visibility reconciliation lost an element');
      }
    }
  }

  private async loadPendingSearchPages(limit: number): Promise<SearchBackfillPage[]> {
    if (this.store === null) {
      throw new Error('StrokePersistence is not initialized');
    }
    const resultSet = await this.store.querySql(
      `SELECT page.note_id AS note_id, page.page_id AS page_id,
        page.content_revision AS content_revision
       FROM page_info page
       LEFT JOIN search_page_state state
         ON state.note_id = page.note_id AND state.page_id = page.page_id
       WHERE state.indexed_revision IS NULL OR state.indexed_revision != page.content_revision
       ORDER BY page.note_id, page.page_index LIMIT ?`, [limit]);
    const pages: SearchBackfillPage[] = [];
    try {
      while (resultSet.goToNextRow()) {
        pages.push({
          noteId: resultSet.getString(resultSet.getColumnIndex('note_id')),
          pageId: resultSet.getString(resultSet.getColumnIndex('page_id')),
          revision: resultSet.getLong(resultSet.getColumnIndex('content_revision')),
        });
      }
    } finally {
      resultSet.close();
    }
    return pages;
  }

  private async loadTextPayloads(noteId: string, pageId: string): Promise<Uint8Array[]> {
    if (this.store === null) {
      throw new Error('StrokePersistence is not initialized');
    }
    const predicates = new relationalStore.RdbPredicates('page_element_snapshot');
    predicates.equalTo('note_id', noteId);
    predicates.equalTo('page_id', pageId);
    predicates.equalTo('kind', 2);
    predicates.orderByAsc('element_order');
    const resultSet = await this.store.query(predicates, ['payload']);
    const payloads: Uint8Array[] = [];
    try {
      while (resultSet.goToNextRow()) {
        payloads.push(resultSet.getBlob(resultSet.getColumnIndex('payload')));
      }
    } finally {
      resultSet.close();
    }
    return payloads;
  }

  private async commitBackfilledPage(page: SearchBackfillPage,
    texts: ParsedSearchText[]): Promise<void> {
    if (this.store === null) {
      throw new Error('StrokePersistence is not initialized');
    }
    const store: relationalStore.RdbStore = this.store;
    await store.beginTransaction();
    try {
      const revisionSet = await store.querySql(
        'SELECT content_revision FROM page_info WHERE note_id = ? AND page_id = ?',
        [page.noteId, page.pageId]);
      let currentRevision: number = -1;
      try {
        if (revisionSet.goToFirstRow()) {
          currentRevision = revisionSet.getLong(revisionSet.getColumnIndex('content_revision'));
        }
      } finally {
        revisionSet.close();
      }
      if (currentRevision !== page.revision) {
        await store.rollBack();
        return;
      }
      const oldSearch = new relationalStore.RdbPredicates('search_item');
      oldSearch.equalTo('note_id', page.noteId);
      oldSearch.equalTo('page_id', page.pageId);
      oldSearch.equalTo('type', SearchItemType.TEXT_BLOCK);
      await store.delete(oldSearch);
      for (const text of texts) {
        const bucket: relationalStore.ValuesBucket = {
          'note_id': page.noteId,
          'type': SearchItemType.TEXT_BLOCK,
          'sub_id': text.subId,
          'page_id': page.pageId,
          'folded_text': text.foldedText,
          'rects': null,
        };
        await store.insert('search_item', bucket,
          relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
      }
      const state: relationalStore.ValuesBucket = {
        'note_id': page.noteId,
        'page_id': page.pageId,
        'indexed_revision': page.revision,
      };
      await store.insert('search_page_state', state,
        relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
      await store.commit();
    } catch (e) {
      await store.rollBack();
      throw new Error(`search backfill failed: ${JSON.stringify(e)}`);
    }
  }

  private prepareSave(noteId: string, pageId: string, strokes: StrokeElementData[],
    textBlocks: TextBlockElement[], elementOrder: PageElementRef[], shapes: ShapeElement[],
    images: ImageElement[], mathBlocks: MathElement[],
    history?: HistoryMetadata): PreparedPageSave {
    const elements: PreparedElement[] = [];
    const preferredOrder: PageElementRef[] = elementOrder.length > 0
      ? elementOrder : legacyPageElementOrder(strokes, textBlocks, shapes, images, mathBlocks);
    const ordered: OrderedPageElement[] = materializePageElements(
      preferredOrder, strokes, textBlocks, shapes, images, mathBlocks);
    for (const element of ordered) {
      if (element.kind === PageElementKind.STROKE) {
        const payload: PersistedElement = { kind: 'stroke', data: element.data };
        elements.push({ elementId: element.elementId, kind: PageElementKind.STROKE,
          payload: encodePersistedElement(payload), searchText: null });
      } else if (element.kind === PageElementKind.TEXT) {
        const payload: PersistedElement = { kind: 'text', data: element.data };
        elements.push({ elementId: element.elementId, kind: PageElementKind.TEXT,
          payload: encodePersistedElement(payload), searchText: foldSearchText(element.data.richText) });
      } else if (element.kind === PageElementKind.SHAPE) {
        const payload: PersistedElement = { kind: 'shape', data: element.data };
        elements.push({ elementId: element.elementId, kind: PageElementKind.SHAPE,
          payload: encodePersistedElement(payload),
          searchText: foldSearchText(element.data.richText ?? '') });
      } else if (element.kind === PageElementKind.IMAGE) {
        const payload: PersistedElement = { kind: 'image', data: element.data };
        elements.push({ elementId: element.elementId, kind: PageElementKind.IMAGE,
          payload: encodePersistedElement(payload), searchText: null });
      } else if (element.kind === PageElementKind.MATH) {
        const payload: PersistedElement = { kind: 'math', data: element.data };
        elements.push({ elementId: element.elementId, kind: PageElementKind.MATH,
          payload: encodePersistedElement(payload), searchText: null });
      }
    }
    return { noteId: noteId, pageId: pageId, elements: elements, history: history };
  }

  private getSaveQueue(noteId: string, pageId: string): LatestWriteQueue<PreparedPageSave> {
    const key: string = this.saveKey(noteId, pageId);
    let queue: LatestWriteQueue<PreparedPageSave> | undefined = this.saveQueues.get(key);
    if (queue === undefined) {
      queue = new LatestWriteQueue<PreparedPageSave>(
        async (snapshot: PreparedPageSave, revision: number): Promise<void> =>
          this.writePrepared(snapshot, revision));
      this.saveQueues.set(key, queue);
    }
    return queue;
  }

  private saveKey(noteId: string, pageId: string): string {
    return `${noteId}\u0000${pageId}`;
  }

  private async deletePageSearchType(store: relationalStore.RdbStore, noteId: string,
    pageId: string, type: SearchItemType): Promise<void> {
    const predicates = new relationalStore.RdbPredicates('search_item');
    predicates.equalTo('note_id', noteId);
    predicates.equalTo('page_id', pageId);
    predicates.equalTo('type', type);
    await store.delete(predicates);
  }

  private async loadCurrentSnapshot(store: relationalStore.RdbStore,
    noteId: string, pageId: string): Promise<SearchSourceElement[]> {
    const predicates = new relationalStore.RdbPredicates('page_element_snapshot');
    predicates.equalTo('note_id', noteId);
    predicates.equalTo('page_id', pageId);
    predicates.orderByAsc('element_order');
    const resultSet = await store.query(predicates, ['element_id', 'kind', 'payload']);
    const current: SearchSourceElement[] = [];
    try {
      while (resultSet.goToNextRow()) {
        current.push({
          elementId: resultSet.getString(resultSet.getColumnIndex('element_id')),
          kind: resultSet.getLong(resultSet.getColumnIndex('kind')),
          payload: resultSet.getBlob(resultSet.getColumnIndex('payload')),
        });
      }
    } finally {
      resultSet.close();
    }
    return current;
  }

  private async readEligibleOriginalInkPage(store: relationalStore.RdbStore,
    noteId: string, pageId: string): Promise<OriginalSequenceIdentity | null> {
    const guard = await store.querySql(
      `SELECT blocked FROM original_local_ink_authoring_guard
       WHERE note_id = ? AND page_id = ?`, [noteId, pageId]);
    try {
      if (guard.goToFirstRow() && guard.getLong(guard.getColumnIndex('blocked')) !== 0) {
        return null;
      }
    } finally {
      guard.close();
    }
    const identityRows = await store.querySql(
      `SELECT seq_timestamp, seq_site_id, seq_index FROM original_page_identity
       WHERE note_id = ? AND page_id = ? AND visible = 1`, [noteId, pageId]);
    let page: OriginalSequenceIdentity | null = null;
    try {
      if (identityRows.goToFirstRow()) {
        page = {
          timestamp: identityRows.getLong(identityRows.getColumnIndex('seq_timestamp')),
          siteId: identityRows.getLong(identityRows.getColumnIndex('seq_site_id')),
          index: identityRows.getLong(identityRows.getColumnIndex('seq_index')),
        };
      }
    } finally {
      identityRows.close();
    }
    if (page === null) {
      return null;
    }
    const snapshot = await store.querySql(
      `SELECT element_id, kind FROM page_element_snapshot WHERE note_id = ? AND page_id = ?
       ORDER BY element_order`, [noteId, pageId]);
    const actual: string[] = [];
    try {
      while (snapshot.goToNextRow()) {
        actual.push(`${snapshot.getLong(snapshot.getColumnIndex('kind'))}:` +
          snapshot.getString(snapshot.getColumnIndex('element_id')));
      }
    } finally {
      snapshot.close();
    }
    const tracked = await store.querySql(
      `SELECT element_timestamp, element_site_id, kind, z_index FROM original_element_z_index
       WHERE note_id = ? AND page_timestamp = ? AND page_site_id = ? AND page_index = ?
       AND visible = 1`, [noteId, page.timestamp, page.siteId, page.index]);
    const original: OriginalOrderEntry[] = [];
    try {
      while (tracked.goToNextRow()) {
        const timestamp: number = tracked.getLong(tracked.getColumnIndex('element_timestamp'));
        const siteId: number = tracked.getLong(tracked.getColumnIndex('element_site_id'));
        original.push({
          key: `${tracked.getLong(tracked.getColumnIndex('kind'))}:` +
            encodeOperationId({ timestamp: timestamp, siteId: siteId }),
          timestamp: timestamp, siteId: siteId,
          zIndex: tracked.getString(tracked.getColumnIndex('z_index')),
        });
      }
    } finally {
      tracked.close();
    }
    original.sort(compareOriginalOrderEntries);
    if (actual.length !== original.length) {
      return null;
    }
    for (let index: number = 0; index < actual.length; index++) {
      if (actual[index] !== original[index].key) {
        return null;
      }
    }
    return page;
  }

  private async blockOriginalInkAuthoring(store: relationalStore.RdbStore,
    noteId: string, pageId: string): Promise<void> {
    const original = await store.querySql(
      `SELECT 1 FROM original_page_identity WHERE note_id = ? AND page_id = ? LIMIT 1`,
      [noteId, pageId]);
    let hasOriginalIdentity: boolean = false;
    try {
      hasOriginalIdentity = original.goToFirstRow();
    } finally {
      original.close();
    }
    if (hasOriginalIdentity) {
      await store.insert('original_local_ink_authoring_guard', {
        'note_id': noteId, 'page_id': pageId, 'blocked': 1,
      }, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
    }
  }

  private async readMaximumOriginalZIndex(store: relationalStore.RdbStore, noteId: string,
    page: OriginalSequenceIdentity): Promise<string | null> {
    const rows = await store.querySql(
      `SELECT z_index FROM original_element_z_index WHERE note_id = ? AND page_timestamp = ?
       AND page_site_id = ? AND page_index = ? AND visible = 1`,
      [noteId, page.timestamp, page.siteId, page.index]);
    let maximum: string | null = null;
    try {
      while (rows.goToNextRow()) {
        const value: string = rows.getString(rows.getColumnIndex('z_index'));
        if (maximum === null || compareUnsignedLongDecimal(maximum, value) < 0) {
          maximum = value;
        }
      }
    } finally {
      rows.close();
    }
    return maximum;
  }

  private async loadMatchingElements(noteId: string, pageId: string | null): Promise<LoadedElements> {
    const result: LoadedElements = {
      strokes: [], textBlocks: [], shapes: [], images: [], mathBlocks: [],
      elementOrder: [], elements: [], groups: [],
    };
    if (this.store === null) {
      throw new Error('StrokePersistence is not initialized');
    }
    const store: relationalStore.RdbStore = this.store;
    try {
      const predicates = new relationalStore.RdbPredicates('page_element_snapshot');
      predicates.equalTo('note_id', noteId);
      if (pageId !== null) {
        predicates.equalTo('page_id', pageId);
      }
      predicates.orderByAsc('element_order');
      const resultSet = await store.query(predicates);
      try {
        while (resultSet.goToNextRow()) {
          const bytes: Uint8Array = resultSet.getBlob(resultSet.getColumnIndex('payload'));
          try {
            const parsed: PersistedElement = decodePersistedElement(bytes);
            if (parsed.kind === 'stroke') {
              const stroke: StrokeElementData = parsed.data as StrokeElementData;
              result.strokes.push(stroke);
              result.elementOrder.push({ kind: PageElementKind.STROKE,
                elementId: stroke.id, zIndex: result.elementOrder.length });
            } else if (parsed.kind === 'text') {
              const text: TextBlockElement = cloneTextBlockElement(parsed.data as TextBlockElement);
              text.bounds = textBlockWorldBounds(text);
              result.textBlocks.push(text);
              result.elementOrder.push({ kind: PageElementKind.TEXT,
                elementId: text.id, zIndex: result.elementOrder.length });
            } else if (parsed.kind === 'shape') {
              const shape: ShapeElement = cloneShapeElement(parsed.data as ShapeElement);
              shape.bounds = recomputeShapeBounds(shape);
              result.shapes.push(shape);
              result.elementOrder.push({ kind: PageElementKind.SHAPE,
                elementId: shape.id, zIndex: result.elementOrder.length });
            } else if (parsed.kind === 'image') {
              const image: ImageElement = cloneImageElement(parsed.data as ImageElement);
              image.bounds = imageBlockWorldBounds(image);
              result.images.push(image);
              result.elementOrder.push({ kind: PageElementKind.IMAGE,
                elementId: image.id, zIndex: result.elementOrder.length });
            } else if (parsed.kind === 'math') {
              const math: MathElement = cloneMathElement(parsed.data as MathElement);
              math.bounds = mathBlockWorldBounds(math);
              result.mathBlocks.push(math);
              result.elementOrder.push({ kind: PageElementKind.MATH,
                elementId: math.id, zIndex: result.elementOrder.length });
            }
          } catch (e) {
            // Ignore an individual corrupt element without discarding the rest of the page.
          }
        }
      } finally {
        resultSet.close();
      }
      result.groups = await this.loadOriginalSelectionGroups(store, noteId);
    } catch (e) {
      throw new Error(`loadElements failed: ${JSON.stringify(e)}`);
    }
    result.elementOrder = normalizePageElementOrder(
      result.elementOrder, result.strokes, result.textBlocks, result.shapes, result.images,
      result.mathBlocks);
    result.elements = materializePageElements(
      result.elementOrder, result.strokes, result.textBlocks, result.shapes, result.images,
      result.mathBlocks);
    return result;
  }

  private async loadOriginalSelectionGroups(store: relationalStore.RdbStore,
    noteId: string): Promise<OriginalSelectionGroup[]> {
    const rows = await store.querySql(
      `SELECT state.group_timestamp, state.group_site_id, state.members_value
       FROM original_group_state state
       LEFT JOIN original_entity_visibility_winner visibility
        ON visibility.note_id = state.note_id
        AND visibility.entity_timestamp = state.group_timestamp
        AND visibility.entity_site_id = state.group_site_id
       WHERE state.note_id = ? AND (visibility.deleted IS NULL OR visibility.deleted = 0)
       ORDER BY state.group_timestamp, state.group_site_id`, [noteId]);
    const groups: OriginalSelectionGroup[] = [];
    try {
      while (rows.goToNextRow()) {
        try {
          const timestamp: number = rows.getLong(rows.getColumnIndex('group_timestamp'));
          const siteId: number = rows.getLong(rows.getColumnIndex('group_site_id'));
          const identity: OperationIdentity = { timestamp: timestamp, siteId: siteId };
          validateOperationIdentity(identity);
          const raw: PersistedGroupMember[] = JSON.parse(
            rows.getString(rows.getColumnIndex('members_value'))) as PersistedGroupMember[];
          if (!Array.isArray(raw) || raw.length === 0) {
            continue;
          }
          const members: string[] = [];
          const seen: Set<string> = new Set<string>();
          for (const value of raw) {
            const member: OperationIdentity = { timestamp: value.timestamp, siteId: value.siteId };
            validateOperationIdentity(member);
            const memberId: string = encodeOperationId(member);
            if (!seen.has(memberId)) {
              seen.add(memberId);
              members.push(memberId);
            }
          }
          if (members.length > 0) {
            groups.push({ id: encodeOperationId(identity), timestamp: timestamp,
              siteId: siteId, members: members });
          }
        } catch (_error) {
          // Ignore one corrupt group without making its page contents unreadable.
        }
      }
    } finally {
      rows.close();
    }
    return groups;
  }

}

function compareOriginalOrderEntries(left: OriginalOrderEntry,
  right: OriginalOrderEntry): number {
  let compared: number = compareUnsignedLongDecimal(left.zIndex, right.zIndex);
  if (compared !== 0) {
    return compared;
  }
  compared = left.timestamp === right.timestamp ? 0 : left.timestamp < right.timestamp ? -1 : 1;
  if (compared !== 0) {
    return compared;
  }
  return left.siteId === right.siteId ? 0 : left.siteId < right.siteId ? -1 : 1;
}

function sameByteArrays(left: Uint8Array, right: Uint8Array): boolean {
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

function samePreparedIdentityOrder(current: SearchSourceElement[],
  expected: PreparedElement[]): boolean {
  if (current.length !== expected.length) {
    return false;
  }
  for (let index: number = 0; index < current.length; index++) {
    if (current[index].elementId !== expected[index].elementId ||
      current[index].kind !== expected[index].kind) {
      return false;
    }
  }
  return true;
}

function sameElement(left: SearchSourceElement | PreparedElement,
  right: SearchSourceElement | PreparedElement): boolean {
  return left.elementId === right.elementId && left.kind === right.kind &&
    sameByteArrays(left.payload, right.payload);
}

function localStoredOperation(noteId: string, metadata: OriginalInkCreateMetadata,
  payloadType: number, payload: Uint8Array, audioTime: string | null): StoredSyncedOperation {
  return {
    noteId: noteId, timestamp: metadata.timestamp, siteId: metadata.siteId,
    clientTime: metadata.clientTime.toString(), serverTime: '0', audioTime: audioTime,
    schemaVersion: 1, payloadType: payloadType, rawOperation: payload,
    state: SyncedOperationInboxState.APPLIED, deferredReason: null,
    receivedAt: metadata.clientTime,
  };
}
