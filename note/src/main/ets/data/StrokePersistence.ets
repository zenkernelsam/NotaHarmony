import { relationalStore } from '@kit.ArkData';
import { PageInfo } from '../core/model/NoteTypes';
import { parsePageBackground } from '../core/model/PageBackgroundModel';
import { readEffectiveNoteBackground } from './OriginalSetMetadataOperation';
import { HistoryEffect, HistoryMetadata } from '../core/model/OpTypes';
import { taskpool, util } from '@kit.ArkTS';
import { StrokeElementData } from '../core/model/StrokeTypes';
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

export interface PersistedElement {
  kind: string;
  data: StrokeElementData | TextBlockElement | ShapeElement | ImageElement | MathElement;
}

// page_element_snapshot.payload is a SQLite BLOB containing UTF-8 JSON bytes.
// Keeping one codec for every read/write path prevents TEXT/BLOB affinity drift.
export function encodePersistedElement(element: PersistedElement): Uint8Array {
  const encoder = new util.TextEncoder();
  return encoder.encodeInto(JSON.stringify(element));
}

export function decodePersistedElement(payload: Uint8Array): PersistedElement {
  const decoder = util.TextDecoder.create('utf-8');
  return JSON.parse(decoder.decodeToString(payload)) as PersistedElement;
}

export interface LoadedElements {
  strokes: StrokeElementData[];
  textBlocks: TextBlockElement[];
  shapes: ShapeElement[];
  images: ImageElement[];
  mathBlocks: MathElement[];
  elementOrder: PageElementRef[];
  elements: OrderedPageElement[];
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
      { strokes: [], textBlocks: [], shapes: [], images: [], mathBlocks: [], elementOrder: [], elements: [] };
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
      for (const step of steps) {
        if (!pageSnapshotChanged(current, step.elements) || step.history === undefined) {
          throw new Error('history group contains an empty mutation');
        }
        const nextRevision: number = currentRevision + 1;
        const mutation: PageMutationOpPayload = createPageMutation(
          step.pageId, currentRevision, nextRevision, current, step.elements);
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
        currentRevision = nextRevision;
        current = step.elements;
      }
      const pageRevision: relationalStore.ValuesBucket = { 'content_revision': currentRevision };
      const pagePredicates = new relationalStore.RdbPredicates('page_info');
      pagePredicates.equalTo('note_id', initial.noteId);
      pagePredicates.equalTo('page_id', initial.pageId);
      const revisedPages: number = await store.update(pageRevision, pagePredicates);
      if (revisedPages !== 1) {
        throw new Error(`expected one page revision update, got ${revisedPages}`);
      }
      const del = new relationalStore.RdbPredicates('page_element_snapshot');
      del.equalTo('note_id', initial.noteId);
      del.equalTo('page_id', initial.pageId);
      await store.delete(del);
      const final: PreparedPageSave = steps[steps.length - 1];
      const buckets: relationalStore.ValuesBucket[] = [];
      for (let seq: number = 0; seq < final.elements.length; seq++) {
        const element: PreparedElement = final.elements[seq];
        buckets.push({
          'note_id': final.noteId, 'page_id': final.pageId, 'element_id': element.elementId,
          'kind': element.kind, 'payload': element.payload, 'revision': currentRevision, 'element_order': seq,
        });
      }
      if (buckets.length > 0) {
        await store.batchInsert('page_element_snapshot', buckets);
      }
      await this.deletePageSearchType(store, final.noteId, final.pageId, SearchItemType.TEXT_BLOCK);
      if (handwritingSourceChanged(original, final.elements)) {
        await this.deletePageSearchType(store, final.noteId, final.pageId, SearchItemType.INK);
      }
      for (const element of final.elements) {
        if (element.searchText !== null) {
          await store.insert('search_item', {
            'note_id': final.noteId, 'type': SearchItemType.TEXT_BLOCK, 'sub_id': element.elementId,
            'page_id': final.pageId, 'folded_text': element.searchText, 'rects': null,
          }, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
        }
      }
      await store.insert('search_page_state', {
        'note_id': final.noteId, 'page_id': final.pageId, 'indexed_revision': currentRevision,
      }, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
      await store.commit();
    } catch (e) {
      await store.rollBack();
      throw new Error(`save history group failed: ${JSON.stringify(e)}`);
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

  private async loadMatchingElements(noteId: string, pageId: string | null): Promise<LoadedElements> {
    const result: LoadedElements = {
      strokes: [], textBlocks: [], shapes: [], images: [], mathBlocks: [], elementOrder: [], elements: [],
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

}
