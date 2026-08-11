import { relationalStore } from '@kit.ArkData';
import { PageInfo } from '../core/model/NoteTypes';
import { parsePageBackground } from '../core/model/PageBackgroundModel';
import { readEffectiveNoteBackground } from './OriginalSetMetadataOperation';
import { HistoryEffect, HistoryMetadata, OpType } from '../core/model/OpTypes';
import { taskpool, util } from '@kit.ArkTS';
import { InkStyle, OriginalInkCreateMetadata, StrokeElementData } from '../core/model/StrokeTypes';
import { ImageElement, MathElement, ShapeElement, TextBlockElement } from '../core/model/ElementTypes';
import { Rect2D, TransformMatrix } from '../core/model/GeometryTypes';
import {
  cloneImageElement, imageBlockWorldBounds, reflectImageCropRect,
} from '../core/model/ImageBlockGeometry';
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
  originalGroupLayerUnits, OriginalLayeringEntity, OriginalLayeringUnit,
} from './OriginalGroupLayering';
import {
  decodeOperationId, encodeOperationId, OperationIdentity, OriginalSequenceIdentity,
  validateOperationIdentity,
} from './OperationIdentity';
import {
  compareUnsignedLongDecimal, MAX_UNSIGNED_LONG_DECIMAL, validateUnsignedLongDecimal,
} from './UnsignedDecimal';
import { encodeOriginalLocalCreateInk } from './OriginalCreateInkPayloadEncoder';
import {
  ORIGINAL_CREATE_INK_PAYLOAD_TYPE, OriginalCreateInkOperationApplier,
} from './OriginalCreateInkOperation';
import {
  rebuildOriginalPencilWidth, RebuiltOriginalPencilWidth,
} from '../core/adaptation/OriginalPencilWidthGeometry';
import {
  encodeOriginalEntityVisibility,
} from './OriginalDeleteEntitiesPayloadEncoder';
import {
  MAX_ORIGINAL_DELETE_ENTITY_COUNT, ORIGINAL_DELETE_ENTITIES_PAYLOAD_TYPE,
  OriginalDeleteEntitiesOperationApplier,
} from './OriginalDeleteEntitiesOperation';
import {
  encodeOriginalInkRenderRegisters, OriginalInkRenderRegisterUpdate,
} from './OriginalModifyInkPayloadEncoder';
import { encodeOriginalOperationEnvelope } from './OriginalOperationEnvelopeEncoder';
import {
  decodeOriginalModifyInk, ORIGINAL_MODIFY_INK_PAYLOAD_TYPE, OriginalModifyInkOperationApplier,
  OriginalModifyInkPayload,
} from './OriginalModifyInkOperation';
import { encodeOriginalImageCrop, encodeOriginalImageFlip } from './OriginalModifyBlockPayloadEncoder';
import {
  decodeOriginalModifyBlock, ORIGINAL_MODIFY_BLOCK_PAYLOAD_TYPE,
  OriginalModifyBlockOperationApplier, OriginalModifyBlockPayload,
} from './OriginalModifyBlockOperation';
import { OriginalBlockRect } from './OriginalCreateBlockOperation';
import { OriginalPageMutationBatch } from './OriginalPageMutationBatch';
import { encodeOriginalModifyPositions } from './OriginalModifyPositionsPayloadEncoder';
import {
  ORIGINAL_MODIFY_POSITIONS_PAYLOAD_TYPE, OriginalModifyPosition,
  OriginalModifyPositionsOperationApplier, OriginalModifyPositionsPayload,
} from './OriginalModifyPositionsOperation';
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
  originalZOrderHint?: OriginalZOrderHint;
}

export enum OriginalZOrderCommand {
  SEND_BACK = 0,
  BRING_FRONT = 1,
  SEND_BACKWARD = 2,
  BRING_FORWARD = 3,
}

export interface OriginalZOrderHint {
  command: OriginalZOrderCommand;
  selectedElementIds: string[];
  selectedGroupIds?: string[];
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
  unitId: string;
  unitTimestamp: number;
  unitSiteId: number;
  unitZIndex: string;
  unitGroup: boolean;
}

interface OriginalOrderUnit {
  id: string;
  timestamp: number;
  siteId: number;
  zIndex: string;
  group: boolean;
  entries: OriginalOrderEntry[];
}

interface OriginalZOrderValue {
  target: OperationIdentity;
  zIndex: string;
}

interface OriginalZOrderHistory {
  before: OriginalZOrderValue[];
  after: OriginalZOrderValue[];
}

interface OriginalModifyPositionsMutation {
  payload: OriginalModifyPositionsPayload;
  zOrderHistory: OriginalZOrderHistory | null;
}

interface OriginalEntityVisibilityMutation {
  identities: OperationIdentity[];
  deleted: boolean;
}

interface OriginalInkRenderMutationBatch extends OriginalInkRenderRegisterUpdate {
  identities: OperationIdentity[];
}

interface OriginalInkRenderMutation {
  batches: OriginalInkRenderMutationBatch[];
}

export interface OriginalImageFlipUpdate {
  identity: OperationIdentity;
  horizontal: boolean | null;
  vertical: boolean | null;
  cropRect: OriginalBlockRect | null;
}

export interface OriginalImageFlipMutation {
  updates: OriginalImageFlipUpdate[];
}

export interface OriginalImageCropUpdate {
  identity: OperationIdentity;
  originX: number;
  originY: number;
  scaleX: number;
  scaleY: number;
  width: number;
  height: number;
  cropRect: OriginalBlockRect | null;
}

export interface OriginalImageCropMutation {
  updates: OriginalImageCropUpdate[];
}

export function classifyOriginalImageFlipMutation(current: SearchSourceElement[],
  next: SearchSourceElement[]): OriginalImageFlipMutation | null {
  if (current.length !== next.length) {
    return null;
  }
  const updates: OriginalImageFlipUpdate[] = [];
  let axis: number = -1;
  for (let index: number = 0; index < current.length; index++) {
    if (current[index].elementId !== next[index].elementId ||
      current[index].kind !== next[index].kind) {
      return null;
    }
    if (sameByteArrays(current[index].payload, next[index].payload)) {
      continue;
    }
    if (current[index].kind !== PageElementKind.IMAGE) {
      return null;
    }
    try {
      const beforePersisted: PersistedElement = decodePersistedElement(current[index].payload);
      const afterPersisted: PersistedElement = decodePersistedElement(next[index].payload);
      if (beforePersisted.kind !== 'image' || afterPersisted.kind !== 'image') {
        return null;
      }
      const before: ImageElement = beforePersisted.data as ImageElement;
      const after: ImageElement = afterPersisted.data as ImageElement;
      const identity: OperationIdentity | null = decodeOperationId(before.id);
      const horizontalChanged: boolean =
        before.imageFlippedHorizontally !== after.imageFlippedHorizontally;
      const verticalChanged: boolean =
        before.imageFlippedVertically !== after.imageFlippedVertically;
      if (identity === null || before.id !== current[index].elementId ||
        after.id !== next[index].elementId || before.id !== after.id ||
        horizontalChanged === verticalChanged) {
        return null;
      }
      const updateAxis: number = horizontalChanged ? 0 : 1;
      if (axis >= 0 && axis !== updateAxis) {
        return null;
      }
      axis = updateAxis;
      const candidate: ImageElement = cloneImageElement(before);
      if (horizontalChanged) {
        candidate.imageFlippedHorizontally = after.imageFlippedHorizontally;
      } else {
        candidate.imageFlippedVertically = after.imageFlippedVertically;
      }
      if (candidate.cropRect !== null) {
        candidate.cropRect = reflectImageCropRect(candidate.cropRect,
          candidate.intrinsicWidth, candidate.intrinsicHeight, horizontalChanged);
      }
      if (!sameByteArrays(encodePersistedElement({ kind: 'image', data: candidate }),
        next[index].payload)) {
        return null;
      }
      updates.push({
        identity: identity,
        horizontal: horizontalChanged ? after.imageFlippedHorizontally : null,
        vertical: verticalChanged ? after.imageFlippedVertically : null,
        cropRect: candidate.cropRect === null ? null : {
          x: candidate.cropRect.left, y: candidate.cropRect.top,
          width: candidate.cropRect.right - candidate.cropRect.left,
          height: candidate.cropRect.bottom - candidate.cropRect.top,
        },
      });
    } catch (_error) {
      return null;
    }
  }
  return updates.length === 0 ? null : { updates: updates };
}

export function classifyOriginalImageCropMutation(current: SearchSourceElement[],
  next: SearchSourceElement[]): OriginalImageCropMutation | null {
  if (!samePreparedIdentityOrder(current, next)) {
    return null;
  }
  const updates: OriginalImageCropUpdate[] = [];
  for (let index: number = 0; index < current.length; index++) {
    if (sameByteArrays(current[index].payload, next[index].payload)) {
      continue;
    }
    if (current[index].kind !== PageElementKind.IMAGE) {
      return null;
    }
    try {
      const beforePersisted: PersistedElement = decodePersistedElement(current[index].payload);
      const afterPersisted: PersistedElement = decodePersistedElement(next[index].payload);
      if (beforePersisted.kind !== 'image' || afterPersisted.kind !== 'image') {
        return null;
      }
      const before: ImageElement = beforePersisted.data as ImageElement;
      const after: ImageElement = afterPersisted.data as ImageElement;
      const identity: OperationIdentity | null = decodeOperationId(before.id);
      const beforePosition: PositionComponents | null = positionComponents(before.transform);
      const afterPosition: PositionComponents | null = positionComponents(after.transform);
      const sourceCrop: Rect2D = before.cropRect === null ? {
        left: 0, top: 0, right: before.intrinsicWidth, bottom: before.intrinsicHeight,
      } : before.cropRect;
      const targetCrop: Rect2D = after.cropRect === null ? {
        left: 0, top: 0, right: after.intrinsicWidth, bottom: after.intrinsicHeight,
      } : after.cropRect;
      if (identity === null || before.id !== current[index].elementId || before.id !== after.id ||
        after.id !== next[index].elementId || beforePosition === null || afterPosition === null ||
        !sameImageCropDomain(before, after) || !validIntrinsicCrop(sourceCrop, before) ||
        !validIntrinsicCrop(targetCrop, after) ||
        !numbersNear(before.blockWidth, sourceCrop.right - sourceCrop.left) ||
        !numbersNear(before.blockHeight, sourceCrop.bottom - sourceCrop.top) ||
        !numbersNear(after.blockWidth, targetCrop.right - targetCrop.left) ||
        !numbersNear(after.blockHeight, targetCrop.bottom - targetCrop.top) ||
        !numbersNear(beforePosition.rotation, afterPosition.rotation) ||
        !numbersNear(beforePosition.scaleX, afterPosition.scaleX) ||
        !numbersNear(beforePosition.scaleY, afterPosition.scaleY)) {
        return null;
      }
      const offsetX: number = targetCrop.left - sourceCrop.left;
      const offsetY: number = targetCrop.top - sourceCrop.top;
      const candidate: ImageElement = cloneImageElement(before);
      candidate.transform[2] = Math.fround(before.transform[0] * offsetX +
        before.transform[1] * offsetY + before.transform[2]);
      candidate.transform[5] = Math.fround(before.transform[3] * offsetX +
        before.transform[4] * offsetY + before.transform[5]);
      candidate.blockWidth = Math.fround(targetCrop.right - targetCrop.left);
      candidate.blockHeight = Math.fround(targetCrop.bottom - targetCrop.top);
      candidate.cropRect = after.cropRect === null ? null : {
        left: Math.fround(targetCrop.left), top: Math.fround(targetCrop.top),
        right: Math.fround(targetCrop.right), bottom: Math.fround(targetCrop.bottom),
      };
      candidate.bounds = imageBlockWorldBounds(candidate);
      if (!sameByteArrays(encodePersistedElement({ kind: 'image', data: candidate }),
        next[index].payload)) {
        return null;
      }
      updates.push({
        identity: identity,
        originX: Math.fround(afterPosition.originX),
        originY: Math.fround(afterPosition.originY),
        scaleX: Math.fround(afterPosition.scaleX),
        scaleY: Math.fround(afterPosition.scaleY),
        width: Math.fround(after.blockWidth),
        height: Math.fround(after.blockHeight),
        cropRect: after.cropRect === null ? null : {
          x: Math.fround(after.cropRect.left), y: Math.fround(after.cropRect.top),
          width: Math.fround(after.cropRect.right - after.cropRect.left),
          height: Math.fround(after.cropRect.bottom - after.cropRect.top),
        },
      });
    } catch (_error) {
      return null;
    }
  }
  return updates.length === 1 ? { updates: updates } : null;
}

interface PositionComponents {
  originX: number;
  originY: number;
  rotation: number;
  scaleX: number;
  scaleY: number;
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
    images: ImageElement[] = [], mathBlocks: MathElement[] = [],
    originalZOrderHint?: OriginalZOrderHint): number {
    if (this.store === null) {
      throw new Error('StrokePersistence is not initialized');
    }
    const snapshot: PreparedPageSave = this.prepareSave(
      noteId, pageId, strokes, textBlocks, elementOrder, shapes, images, mathBlocks, history,
      originalZOrderHint);
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
        this.originalEntityVisibilityMutation(current, snapshot.elements);
      if (originalVisibility !== null) {
        await this.applyOriginalEntityVisibility(store, snapshot, originalVisibility,
          snapshotRevision);
        await this.rebuildPageSearchState(store, snapshot, snapshotRevision,
          handwritingSourceChanged(current, snapshot.elements));
        await this.appendHistoryCompanion(store, snapshot, mutation);
        await store.commit();
        return;
      }
      const originalStyle: OriginalInkRenderMutation | null =
        this.originalInkStyleMutation(current, snapshot.elements);
      if (originalStyle !== null) {
        await this.applyOriginalInkStyle(store, snapshot, originalStyle, snapshotRevision);
        await this.rebuildPageSearchState(store, snapshot, snapshotRevision, true);
        await this.appendHistoryCompanion(store, snapshot, mutation);
        await store.commit();
        return;
      }
      const originalImageFlip: OriginalImageFlipMutation | null =
        classifyOriginalImageFlipMutation(current, snapshot.elements);
      if (originalImageFlip !== null) {
        await this.applyOriginalImageFlip(store, snapshot, originalImageFlip, snapshotRevision);
        await this.rebuildPageSearchState(store, snapshot, snapshotRevision, false);
        await this.appendHistoryCompanion(store, snapshot, mutation);
        await store.commit();
        return;
      }
      const originalImageCrop: OriginalImageCropMutation | null =
        classifyOriginalImageCropMutation(current, snapshot.elements);
      if (originalImageCrop !== null) {
        await this.applyOriginalImageCrop(store, snapshot, originalImageCrop, snapshotRevision);
        await this.rebuildPageSearchState(store, snapshot, snapshotRevision, false);
        await this.appendHistoryCompanion(store, snapshot, mutation);
        await store.commit();
        return;
      }
      const originalPositions: OriginalModifyPositionsMutation | null =
        await this.originalModifyPositionsMutation(store, snapshot.noteId, snapshot.pageId,
          current, snapshot.elements, snapshot.history, snapshot.originalZOrderHint);
      if (originalPositions !== null) {
        await this.applyOriginalModifyPositions(
          store, snapshot, originalPositions.payload, snapshotRevision);
        await this.recordOriginalZOrderHistory(store, snapshot, originalPositions.zOrderHistory);
        await this.rebuildPageSearchState(store, snapshot, snapshotRevision, true);
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
      payload: operation.rawOperation, clientTime: metadata.clientTime, opTimestamp: metadata.timestamp,
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
          this.originalEntityVisibilityMutation(current, step.elements);
        const originalStyle: OriginalInkRenderMutation | null = originalVisibility === null ?
          this.originalInkStyleMutation(current, step.elements) : null;
        const originalImageFlip: OriginalImageFlipMutation | null =
          originalVisibility === null && originalStyle === null ?
            classifyOriginalImageFlipMutation(current, step.elements) : null;
        const originalImageCrop: OriginalImageCropMutation | null =
          originalVisibility === null && originalStyle === null && originalImageFlip === null ?
            classifyOriginalImageCropMutation(current, step.elements) : null;
        const originalPositions: OriginalModifyPositionsMutation | null =
          originalVisibility === null && originalStyle === null && originalImageFlip === null &&
            originalImageCrop === null ?
            await this.originalModifyPositionsMutation(store, step.noteId, step.pageId,
              current, step.elements, step.history, step.originalZOrderHint) : null;
        if (originalVisibility !== null) {
          await this.applyOriginalEntityVisibility(store, step, originalVisibility,
            nextRevision);
        } else if (originalStyle !== null) {
          await this.applyOriginalInkStyle(store, step, originalStyle, nextRevision);
        } else if (originalImageFlip !== null) {
          await this.applyOriginalImageFlip(store, step, originalImageFlip, nextRevision);
        } else if (originalImageCrop !== null) {
          await this.applyOriginalImageCrop(store, step, originalImageCrop, nextRevision);
        } else if (originalPositions !== null) {
          await this.applyOriginalModifyPositions(store, step, originalPositions.payload, nextRevision);
          await this.recordOriginalZOrderHistory(store, step, originalPositions.zOrderHistory);
        } else {
          await this.materializePreparedPage(store, step, currentRevision, nextRevision);
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

  private originalEntityVisibilityMutation(current: SearchSourceElement[],
    next: PreparedElement[]): OriginalEntityVisibilityMutation | null {
    const deleted: boolean = current.length > next.length;
    const undeleted: boolean = next.length > current.length;
    if (!deleted && !undeleted) {
      return null;
    }
    const targetCount: number = Math.abs(current.length - next.length);
    if (targetCount > MAX_ORIGINAL_DELETE_ENTITY_COUNT) {
      return null;
    }
    const larger: (SearchSourceElement | PreparedElement)[] = deleted ? current : next;
    const smaller: (SearchSourceElement | PreparedElement)[] = deleted ? next : current;
    let largerIndex: number = 0;
    let smallerIndex: number = 0;
    const identities: OperationIdentity[] = [];
    while (largerIndex < larger.length) {
      if (smallerIndex < smaller.length &&
        sameElement(larger[largerIndex], smaller[smallerIndex])) {
        largerIndex++;
        smallerIndex++;
      } else {
        const identity: OperationIdentity | null = this.originalStrokeIdentity(larger[largerIndex]);
        if (identity === null) {
          return null;
        }
        identities.push(identity);
        largerIndex++;
      }
    }
    if (smallerIndex !== smaller.length || identities.length !== targetCount) {
      return null;
    }
    return { identities: identities, deleted: deleted };
  }

  private originalInkStyleMutation(current: SearchSourceElement[],
    next: PreparedElement[]): OriginalInkRenderMutation | null {
    if (!samePreparedIdentityOrder(current, next)) {
      return null;
    }
    const batches: Map<string, OriginalInkRenderMutationBatch> =
      new Map<string, OriginalInkRenderMutationBatch>();
    for (let index: number = 0; index < current.length; index++) {
      if (sameByteArrays(current[index].payload, next[index].payload)) {
        continue;
      }
      if (current[index].kind !== PageElementKind.STROKE) {
        return null;
      }
      try {
        const beforePersisted: PersistedElement = decodePersistedElement(current[index].payload);
        const afterPersisted: PersistedElement = decodePersistedElement(next[index].payload);
        if (beforePersisted.kind !== 'stroke' || afterPersisted.kind !== 'stroke') {
          return null;
        }
        const before: StrokeElementData = beforePersisted.data as StrokeElementData;
        const after: StrokeElementData = afterPersisted.data as StrokeElementData;
        const identity: OperationIdentity | null = decodeOperationId(before.id);
        const styleChanged: boolean = before.renderSpec.inkStyle !== after.renderSpec.inkStyle;
        const styleMapCleared: boolean = after.styleMap !== undefined && after.styleMap.length === 0 &&
          (before.styleMap === undefined || before.styleMap.length > 0);
        const styleUpdated: boolean = styleChanged || styleMapCleared;
        const colorChanged: boolean = before.renderSpec.color !== after.renderSpec.color;
        const widthChanged: boolean = before.renderSpec.brushWidth !== after.renderSpec.brushWidth;
        if (identity === null || before.id !== after.id ||
          before.renderSpec.isPartialEraser === true ||
          (!styleUpdated && !colorChanged && !widthChanged) ||
          (styleUpdated && before.renderSpec.isPencil)) {
          return null;
        }
        let pencilWidth: RebuiltOriginalPencilWidth | null = null;
        if (widthChanged && before.renderSpec.isPencil) {
          try {
            pencilWidth = rebuildOriginalPencilWidth(before, after.renderSpec.brushWidth);
          } catch (_error) {
            return null;
          }
        }
        const candidate: StrokeElementData = {
          id: before.id, pathPoints: before.pathPoints, cubicSegments: before.cubicSegments,
          splatPoints: pencilWidth === null ? before.splatPoints : pencilWidth.splatPoints,
          renderSpec: {
            color: colorChanged ? after.renderSpec.color : before.renderSpec.color,
            brushWidth: widthChanged ? after.renderSpec.brushWidth : before.renderSpec.brushWidth,
            inkStyle: styleUpdated ? after.renderSpec.inkStyle : before.renderSpec.inkStyle,
            isHighlighter: before.renderSpec.isHighlighter,
            isPencil: before.renderSpec.isPencil,
            isPartialEraser: before.renderSpec.isPartialEraser,
            inkEffects: before.renderSpec.inkEffects,
            inkEffectsTinted: before.renderSpec.inkEffectsTinted,
            inkEffectPhase: before.renderSpec.inkEffectPhase,
            tapePattern: before.renderSpec.tapePattern,
          },
          transform: before.transform,
          bounds: pencilWidth === null ? before.bounds : pencilWidth.bounds,
          maskPath: before.maskPath,
          customPath: before.customPath, fillPath: before.fillPath, fillColor: before.fillColor,
          styleMap: styleUpdated ? [] : before.styleMap, audioStartTime: before.audioStartTime,
          audioDuration: before.audioDuration, originalCreate: before.originalCreate,
          isFinished: before.isFinished,
        };
        const encoded: Uint8Array = encodePersistedElement({ kind: 'stroke', data: candidate });
        if (!sameByteArrays(encoded, next[index].payload)) {
          return null;
        }
        const update: OriginalInkRenderRegisterUpdate = {
          style: styleUpdated ? after.renderSpec.inkStyle : null,
          color: colorChanged ? after.renderSpec.color : null,
          width: widthChanged ? after.renderSpec.brushWidth : null,
        };
        const key: string = `${update.style === null ? 'x' : update.style}|` +
          `${update.color === null ? 'x' : update.color}|` +
          `${update.width === null ? 'x' : update.width}`;
        const batch: OriginalInkRenderMutationBatch | undefined = batches.get(key);
        if (batch === undefined) {
          batches.set(key, {
            identities: [identity], style: update.style, color: update.color, width: update.width,
          });
        } else {
          batch.identities.push(identity);
        }
      } catch (_error) {
        return null;
      }
    }
    return batches.size === 0 ? null : { batches: Array.from(batches.values()) };
  }

  private async originalModifyPositionsMutation(store: relationalStore.RdbStore,
    noteId: string, pageId: string, current: SearchSourceElement[],
    next: PreparedElement[], history?: HistoryMetadata,
    zOrderHint?: OriginalZOrderHint): Promise<OriginalModifyPositionsMutation | null> {
    if (!samePreparedIdentityOrder(current, next)) {
      return this.originalZOrderMutation(
        store, noteId, pageId, current, next, history, zOrderHint);
    }
    const page: OriginalSequenceIdentity | null = await this.readEligibleOriginalInkPage(
      store, noteId, pageId);
    if (page === null) {
      return null;
    }
    const modifications: OriginalModifyPosition[] = [];
    for (let index: number = 0; index < current.length; index++) {
      if (sameByteArrays(current[index].payload, next[index].payload)) {
        continue;
      }
      let beforePersisted: PersistedElement;
      let afterPersisted: PersistedElement;
      try {
        beforePersisted = decodePersistedElement(current[index].payload);
        afterPersisted = decodePersistedElement(next[index].payload);
      } catch (_error) {
        return null;
      }
      const before = beforePersisted.data;
      const after = afterPersisted.data;
      const identity: OperationIdentity | null = decodeOperationId(before.id);
      if (identity === null || before.id !== after.id || beforePersisted.kind !== afterPersisted.kind ||
        !positionOnlyMutation(current[index].kind, beforePersisted, afterPersisted)) {
        return null;
      }
      const beforeComponents: PositionComponents | null = positionComponents(before.transform);
      const afterComponents: PositionComponents | null = positionComponents(after.transform);
      if (beforeComponents === null || afterComponents === null) {
        return null;
      }
      const pageChanged: boolean = !numbersNear(beforeComponents.originX, afterComponents.originX) ||
        !numbersNear(beforeComponents.originY, afterComponents.originY);
      const rotationChanged: boolean = !anglesNear(
        beforeComponents.rotation, afterComponents.rotation);
      const scaleChanged: boolean = !numbersNear(beforeComponents.scaleX, afterComponents.scaleX) ||
        !numbersNear(beforeComponents.scaleY, afterComponents.scaleY);
      if (!pageChanged && !rotationChanged && !scaleChanged) {
        return null;
      }
      modifications.push({
        target: identity,
        pageOrigin: pageChanged ? {
          page: page, originX: Math.fround(afterComponents.originX),
          originY: Math.fround(afterComponents.originY),
        } : null,
        rotation: { present: rotationChanged,
          value: rotationChanged ? Math.fround(afterComponents.rotation) : null },
        scale: { present: scaleChanged, value: scaleChanged ? {
          x: Math.fround(afterComponents.scaleX), y: Math.fround(afterComponents.scaleY),
        } : null },
        zIndex: null,
      });
    }
    return modifications.length === 0 ? null : {
      payload: { modifications: modifications }, zOrderHistory: null,
    };
  }

  private async originalZOrderMutation(store: relationalStore.RdbStore,
    noteId: string, pageId: string, current: SearchSourceElement[], next: PreparedElement[],
    history?: HistoryMetadata,
    hint?: OriginalZOrderHint): Promise<OriginalModifyPositionsMutation | null> {
    if (!samePreparedMembersAndPayloads(current, next) || history === undefined) {
      return null;
    }
    const page: OriginalSequenceIdentity | null = await this.readEligibleOriginalInkPage(
      store, noteId, pageId);
    if (page === null) {
      return null;
    }
    const order: OriginalOrderEntry[] | null = await this.readOriginalOrder(
      store, noteId, page, current);
    if (order === null) {
      return null;
    }
    let zHistory: OriginalZOrderHistory | null = null;
    if (history.effect === HistoryEffect.PUSH) {
      if (hint === undefined) {
        return null;
      }
      zHistory = createOriginalZOrderHistory(order, next, hint);
    } else {
      zHistory = await this.readOriginalZOrderHistory(store, noteId, history.actionId);
    }
    if (zHistory === null) {
      return null;
    }
    const expected: OriginalZOrderValue[] = history.effect === HistoryEffect.UNDO ?
      zHistory.after : zHistory.before;
    const desired: OriginalZOrderValue[] = history.effect === HistoryEffect.UNDO ?
      zHistory.before : zHistory.after;
    if (!zOrderValuesMatch(order, expected) || !zOrderValuesProduce(order, desired, next)) {
      return null;
    }
    const modifications: OriginalModifyPosition[] = desired.map(
      (value: OriginalZOrderValue): OriginalModifyPosition => ({
        target: value.target, pageOrigin: null,
        rotation: { present: false, value: null },
        scale: { present: false, value: null }, zIndex: value.zIndex,
      }));
    return { payload: { modifications: modifications },
      zOrderHistory: history.effect === HistoryEffect.PUSH ? zHistory : null };
  }

  private async readOriginalOrder(store: relationalStore.RdbStore, noteId: string,
    page: OriginalSequenceIdentity,
    current: SearchSourceElement[]): Promise<OriginalOrderEntry[] | null> {
    const rows = await store.querySql(
      `SELECT element_timestamp, element_site_id, kind, z_index FROM original_element_z_index
       WHERE note_id = ? AND page_timestamp = ? AND page_site_id = ? AND page_index = ?
       AND visible = 1`, [noteId, page.timestamp, page.siteId, page.index]);
    const result: OriginalOrderEntry[] = [];
    try {
      while (rows.goToNextRow()) {
        const timestamp: number = rows.getLong(rows.getColumnIndex('element_timestamp'));
        const siteId: number = rows.getLong(rows.getColumnIndex('element_site_id'));
        result.push({
          key: `${rows.getLong(rows.getColumnIndex('kind'))}:` +
            encodeOperationId({ timestamp: timestamp, siteId: siteId }),
          timestamp: timestamp, siteId: siteId,
          zIndex: rows.getString(rows.getColumnIndex('z_index')),
          unitId: encodeOperationId({ timestamp: timestamp, siteId: siteId }),
          unitTimestamp: timestamp, unitSiteId: siteId,
          unitZIndex: rows.getString(rows.getColumnIndex('z_index')), unitGroup: false,
        });
      }
    } finally {
      rows.close();
    }
    const layered: OriginalOrderEntry[] | null =
      await layerOriginalOrderEntries(store, noteId, result);
    if (layered === null || layered.length !== current.length) {
      return null;
    }
    for (let index: number = 0; index < layered.length; index++) {
      if (layered[index].key !== `${current[index].kind}:${current[index].elementId}`) {
        return null;
      }
    }
    return layered;
  }

  private async readOriginalZOrderHistory(store: relationalStore.RdbStore,
    noteId: string, actionId: string): Promise<OriginalZOrderHistory | null> {
    const rows = await store.querySql(
      `SELECT before_values, after_values FROM original_local_z_order_history
       WHERE note_id = ? AND action_id = ?`, [noteId, actionId]);
    try {
      if (!rows.goToFirstRow()) {
        return null;
      }
      const before: OriginalZOrderValue[] = decodeOriginalZOrderValues(
        rows.getString(rows.getColumnIndex('before_values')));
      const after: OriginalZOrderValue[] = decodeOriginalZOrderValues(
        rows.getString(rows.getColumnIndex('after_values')));
      return sameZOrderTargets(before, after) ? { before: before, after: after } : null;
    } catch (_error) {
      return null;
    } finally {
      rows.close();
    }
  }

  private async recordOriginalZOrderHistory(store: relationalStore.RdbStore,
    step: PreparedPageSave, history: OriginalZOrderHistory | null): Promise<void> {
    if (history === null || step.history === undefined ||
      step.history.effect !== HistoryEffect.PUSH) {
      return;
    }
    await store.insert('original_local_z_order_history', {
      'note_id': step.noteId, 'action_id': step.history.actionId,
      'before_values': JSON.stringify(history.before),
      'after_values': JSON.stringify(history.after), 'action_time': step.history.actionTime,
    }, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
    await store.executeSql(
      `DELETE FROM original_local_z_order_history WHERE note_id = ? AND action_id NOT IN
       (SELECT action_id FROM original_local_z_order_history WHERE note_id = ?
        ORDER BY action_time DESC, action_id DESC LIMIT 512)`, [step.noteId, step.noteId]);
  }

  private originalStrokeIdentity(target: SearchSourceElement | PreparedElement): OperationIdentity | null {
    if (target.kind !== PageElementKind.STROKE) {
      return null;
    }
    try {
      const persisted: PersistedElement = decodePersistedElement(target.payload);
      if (persisted.kind !== 'stroke') {
        return null;
      }
      const stroke: StrokeElementData = persisted.data as StrokeElementData;
      return decodeOperationId(stroke.id);
    } catch (_error) {
      return null;
    }
  }

  private async applyOriginalEntityVisibility(store: relationalStore.RdbStore,
    step: PreparedPageSave, visibility: OriginalEntityVisibilityMutation,
    expectedRevision: number): Promise<void> {
    const identity: AllocatedOperationIdentity = await allocateOperationIdentity(store, step.noteId);
    const payload: Uint8Array = encodeOriginalEntityVisibility(
      visibility.deleted ? visibility.identities : [],
      visibility.deleted ? [] : visibility.identities);
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
      payload: operation.rawOperation, clientTime: identity.clientTime, opTimestamp: identity.timestamp,
      editorSiteId: identity.siteId, uploadImmediately: true,
    });
    const materialized: SearchSourceElement[] = await this.loadCurrentSnapshot(
      store, step.noteId, step.pageId);
    if (!samePreparedIdentityOrder(materialized, step.elements)) {
      throw new Error('local Ink visibility reducer produced an unexpected element order');
    }
    await this.reconcilePreparedRows(store, step, expectedRevision);
  }

  private async applyOriginalInkStyle(store: relationalStore.RdbStore,
    step: PreparedPageSave, mutation: OriginalInkRenderMutation,
    expectedRevision: number): Promise<void> {
    if (await this.readEligibleOriginalInkPage(store, step.noteId, step.pageId) === null) {
      throw new Error('local MODIFY_INK page is no longer original-aligned');
    }
    const revisionBatch: OriginalPageMutationBatch = new OriginalPageMutationBatch();
    const applier: OriginalModifyInkOperationApplier = new OriginalModifyInkOperationApplier();
    for (const batch of mutation.batches) {
      const identity: AllocatedOperationIdentity = await allocateOperationIdentity(store, step.noteId);
      const payload: Uint8Array = encodeOriginalInkRenderRegisters(batch.identities, batch);
      const metadata: OriginalInkCreateMetadata = {
        timestamp: identity.timestamp, siteId: identity.siteId, clientTime: identity.clientTime,
        pageTimestamp: 0, pageSiteId: 0, pageIndex: 0, pencilSeed: 0,
      };
      const operation: StoredSyncedOperation = localStoredOperation(
        step.noteId, metadata, ORIGINAL_MODIFY_INK_PAYLOAD_TYPE, payload, null);
      const decoded: OriginalModifyInkPayload = decodeOriginalModifyInk(operation.rawOperation);
      const result: SyncedOperationApplyResult = await applier.applyPositionPayload(
        store, operation, decoded, revisionBatch);
      if (result.deferredReason !== null) {
        throw new Error(`local MODIFY_INK was deferred: ${result.deferredReason}`);
      }
      await appendOperation(store, {
        noteId: step.noteId, opId: identity.opId, opType: OpType.ORIGINAL_MODIFY_INK,
        payload: operation.rawOperation, clientTime: identity.clientTime,
        opTimestamp: identity.timestamp, editorSiteId: identity.siteId, uploadImmediately: true,
      });
    }
    await revisionBatch.flush(store, step.noteId);
    const materialized: SearchSourceElement[] = await this.loadCurrentSnapshot(
      store, step.noteId, step.pageId);
    if (!samePreparedIdentityOrder(materialized, step.elements)) {
      throw new Error('local MODIFY_INK reducer produced an unexpected element order');
    }
    await this.reconcilePreparedRows(store, step, expectedRevision);
  }

  private async applyOriginalModifyPositions(store: relationalStore.RdbStore,
    step: PreparedPageSave, mutation: OriginalModifyPositionsPayload,
    expectedRevision: number): Promise<void> {
    const identity: AllocatedOperationIdentity = await allocateOperationIdentity(store, step.noteId);
    const payload: Uint8Array = encodeOriginalModifyPositions(mutation.modifications);
    const metadata: OriginalInkCreateMetadata = {
      timestamp: identity.timestamp, siteId: identity.siteId, clientTime: identity.clientTime,
      pageTimestamp: 0, pageSiteId: 0, pageIndex: 0, pencilSeed: 0,
    };
    const operation: StoredSyncedOperation = localStoredOperation(
      step.noteId, metadata, ORIGINAL_MODIFY_POSITIONS_PAYLOAD_TYPE, payload, null);
    const result: SyncedOperationApplyResult = await new OriginalModifyPositionsOperationApplier().apply(
      store, operation);
    if (result.deferredReason !== null) {
      throw new Error(`local MODIFY_POSITIONS was deferred: ${result.deferredReason}`);
    }
    await appendOperation(store, {
      noteId: step.noteId, opId: identity.opId, opType: OpType.ORIGINAL_MODIFY_POSITIONS,
      payload: operation.rawOperation, clientTime: identity.clientTime, opTimestamp: identity.timestamp,
      editorSiteId: identity.siteId, uploadImmediately: true,
    });
    const materialized: SearchSourceElement[] = await this.loadCurrentSnapshot(
      store, step.noteId, step.pageId);
    if (!samePreparedIdentityOrder(materialized, step.elements)) {
      throw new Error('local MODIFY_POSITIONS reducer produced an unexpected element order');
    }
    await this.reconcilePreparedRows(store, step, expectedRevision);
  }

  private async applyOriginalImageFlip(store: relationalStore.RdbStore,
    step: PreparedPageSave, mutation: OriginalImageFlipMutation,
    expectedRevision: number): Promise<void> {
    if (await this.readEligibleOriginalInkPage(store, step.noteId, step.pageId) === null) {
      throw new Error('local MODIFY_BLOCK page is no longer original-aligned');
    }
    const revisionBatch: OriginalPageMutationBatch = new OriginalPageMutationBatch();
    const applier: OriginalModifyBlockOperationApplier = new OriginalModifyBlockOperationApplier();
    for (const update of mutation.updates) {
      const identity: AllocatedOperationIdentity = await allocateOperationIdentity(store, step.noteId);
      const payload: Uint8Array = encodeOriginalImageFlip(
        [update.identity], update.horizontal, update.vertical, update.cropRect);
      const metadata: OriginalInkCreateMetadata = {
        timestamp: identity.timestamp, siteId: identity.siteId, clientTime: identity.clientTime,
        pageTimestamp: 0, pageSiteId: 0, pageIndex: 0, pencilSeed: 0,
      };
      const operation: StoredSyncedOperation = localStoredOperation(
        step.noteId, metadata, ORIGINAL_MODIFY_BLOCK_PAYLOAD_TYPE, payload, null);
      const decoded: OriginalModifyBlockPayload = decodeOriginalModifyBlock(operation.rawOperation);
      const result: SyncedOperationApplyResult = await applier.applyBatchedPayload(
        store, operation, decoded, revisionBatch);
      if (result.deferredReason !== null) {
        throw new Error(`local MODIFY_BLOCK image flip was deferred: ${result.deferredReason}`);
      }
      await appendOperation(store, {
        noteId: step.noteId, opId: identity.opId, opType: OpType.ORIGINAL_MODIFY_BLOCK,
        payload: operation.rawOperation, clientTime: identity.clientTime,
        opTimestamp: identity.timestamp, editorSiteId: identity.siteId,
        uploadImmediately: true,
      });
    }
    await revisionBatch.flush(store, step.noteId);
    const materialized: SearchSourceElement[] = await this.loadCurrentSnapshot(
      store, step.noteId, step.pageId);
    if (!samePreparedIdentityOrder(materialized, step.elements)) {
      throw new Error('local MODIFY_BLOCK reducer produced an unexpected element order');
    }
    await this.reconcilePreparedRows(store, step, expectedRevision);
  }

  private async applyOriginalImageCrop(store: relationalStore.RdbStore,
    step: PreparedPageSave, mutation: OriginalImageCropMutation,
    expectedRevision: number): Promise<void> {
    const page: OriginalSequenceIdentity | null = await this.readEligibleOriginalInkPage(
      store, step.noteId, step.pageId);
    if (page === null) {
      throw new Error('local MODIFY_BLOCK crop page is no longer original-aligned');
    }
    const revisionBatch: OriginalPageMutationBatch = new OriginalPageMutationBatch();
    const applier: OriginalModifyBlockOperationApplier = new OriginalModifyBlockOperationApplier();
    for (const update of mutation.updates) {
      const identity: AllocatedOperationIdentity = await allocateOperationIdentity(store, step.noteId);
      const payload: Uint8Array = encodeOriginalImageCrop([update.identity], {
        page: page, originX: update.originX, originY: update.originY,
      }, { x: update.scaleX, y: update.scaleY }, update.width, update.height, update.cropRect);
      const metadata: OriginalInkCreateMetadata = {
        timestamp: identity.timestamp, siteId: identity.siteId, clientTime: identity.clientTime,
        pageTimestamp: 0, pageSiteId: 0, pageIndex: 0, pencilSeed: 0,
      };
      const operation: StoredSyncedOperation = localStoredOperation(
        step.noteId, metadata, ORIGINAL_MODIFY_BLOCK_PAYLOAD_TYPE, payload, null);
      const decoded: OriginalModifyBlockPayload = decodeOriginalModifyBlock(operation.rawOperation);
      const result: SyncedOperationApplyResult = await applier.applyBatchedPayload(
        store, operation, decoded, revisionBatch);
      if (result.deferredReason !== null) {
        throw new Error(`local MODIFY_BLOCK image crop was deferred: ${result.deferredReason}`);
      }
      await appendOperation(store, {
        noteId: step.noteId, opId: identity.opId, opType: OpType.ORIGINAL_MODIFY_BLOCK,
        payload: operation.rawOperation, clientTime: identity.clientTime,
        opTimestamp: identity.timestamp, editorSiteId: identity.siteId,
        uploadImmediately: true,
      });
    }
    await revisionBatch.flush(store, step.noteId);
    const materialized: SearchSourceElement[] = await this.loadCurrentSnapshot(
      store, step.noteId, step.pageId);
    if (!samePreparedIdentityOrder(materialized, step.elements)) {
      throw new Error('local MODIFY_BLOCK crop reducer produced an unexpected element order');
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
    history?: HistoryMetadata, originalZOrderHint?: OriginalZOrderHint): PreparedPageSave {
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
    const hint: OriginalZOrderHint | undefined = originalZOrderHint === undefined ? undefined : {
      command: originalZOrderHint.command,
      selectedElementIds: originalZOrderHint.selectedElementIds.slice(),
      selectedGroupIds: originalZOrderHint.selectedGroupIds === undefined ? [] :
        originalZOrderHint.selectedGroupIds.slice(),
    };
    return { noteId: noteId, pageId: pageId, elements: elements, history: history,
      originalZOrderHint: hint };
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
          unitId: encodeOperationId({ timestamp: timestamp, siteId: siteId }),
          unitTimestamp: timestamp, unitSiteId: siteId,
          unitZIndex: tracked.getString(tracked.getColumnIndex('z_index')), unitGroup: false,
        });
      }
    } finally {
      tracked.close();
    }
    const layered: OriginalOrderEntry[] | null =
      await layerOriginalOrderEntries(store, noteId, original);
    if (layered === null || actual.length !== layered.length) {
      return null;
    }
    for (let index: number = 0; index < actual.length; index++) {
      if (actual[index] !== layered[index].key) {
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

async function layerOriginalOrderEntries(store: relationalStore.RdbStore, noteId: string,
  entries: OriginalOrderEntry[]): Promise<OriginalOrderEntry[] | null> {
  const byId: Map<string, OriginalOrderEntry> = new Map<string, OriginalOrderEntry>();
  const entities: OriginalLayeringEntity[] = [];
  for (const entry of entries) {
    const id: string = encodeOperationId({ timestamp: entry.timestamp, siteId: entry.siteId });
    if (byId.has(id)) {
      return null;
    }
    byId.set(id, entry);
    entities.push({ id: id, timestamp: entry.timestamp, siteId: entry.siteId,
      zIndex: entry.zIndex });
  }
  const units: OriginalLayeringUnit[] | null =
    await originalGroupLayerUnits(store, noteId, entities);
  if (units === null) {
    return null;
  }
  const layered: OriginalOrderEntry[] = [];
  for (const unit of units) {
    for (const entity of unit.entities) {
      const entry: OriginalOrderEntry | undefined = byId.get(entity.id);
      if (entry === undefined) {
        return null;
      }
      layered.push({
        key: entry.key, timestamp: entry.timestamp, siteId: entry.siteId, zIndex: entry.zIndex,
        unitId: unit.id, unitTimestamp: unit.timestamp, unitSiteId: unit.siteId,
        unitZIndex: unit.zIndex, unitGroup: unit.group,
      });
    }
  }
  return layered.length === entries.length ? layered : null;
}

function compareOriginalOrderEntries(left: OriginalOrderEntry,
  right: OriginalOrderEntry): number {
  let compared: number = compareUnsignedLongDecimal(left.unitZIndex, right.unitZIndex);
  if (compared !== 0) {
    return compared;
  }
  compared = left.unitTimestamp === right.unitTimestamp ? 0 :
    left.unitTimestamp < right.unitTimestamp ? -1 : 1;
  if (compared !== 0) {
    return compared;
  }
  compared = left.unitSiteId === right.unitSiteId ? 0 :
    left.unitSiteId < right.unitSiteId ? -1 : 1;
  if (compared !== 0 || left.unitId !== right.unitId) {
    return compared !== 0 ? compared : left.unitId < right.unitId ? -1 : 1;
  }
  compared = compareUnsignedLongDecimal(left.zIndex, right.zIndex);
  if (compared !== 0) {
    return compared;
  }
  compared = left.timestamp === right.timestamp ? 0 : left.timestamp < right.timestamp ? -1 : 1;
  return compared !== 0 ? compared :
    left.siteId === right.siteId ? 0 : left.siteId < right.siteId ? -1 : 1;
}

function createOriginalZOrderHistory(order: OriginalOrderEntry[], next: PreparedElement[],
  hint: OriginalZOrderHint): OriginalZOrderHistory | null {
  if (hint.selectedElementIds.length === 0) {
    return null;
  }
  const selectedIds: Set<string> = new Set<string>();
  for (const id of hint.selectedElementIds) {
    if (selectedIds.has(id) || decodeOperationId(id) === null) {
      return null;
    }
    selectedIds.add(id);
  }
  const selected: OriginalOrderEntry[] = order.filter(
    (entry: OriginalOrderEntry): boolean => selectedIds.has(encodeOperationId({
      timestamp: entry.timestamp, siteId: entry.siteId,
    })));
  if (selected.length !== selectedIds.size ||
    selected.some((entry: OriginalOrderEntry): boolean => entry.unitGroup)) {
    return null;
  }
  const units: OriginalOrderUnit[] | null = originalOrderUnits(order);
  if (units === null || units.length === 0) {
    return null;
  }
  const selectedUnitIds: Set<string> = new Set<string>(selectedIds);
  const groupIds: string[] = hint.selectedGroupIds === undefined ? [] : hint.selectedGroupIds;
  const availableGroupIds: Set<string> = new Set<string>(units.filter(
    (unit: OriginalOrderUnit): boolean => unit.group).map(
      (unit: OriginalOrderUnit): string => unit.id));
  for (const groupId of groupIds) {
    if (selectedUnitIds.has(groupId) || !availableGroupIds.has(groupId)) {
      return null;
    }
    selectedUnitIds.add(groupId);
  }
  const before: OriginalZOrderValue[] = [];
  const after: OriginalZOrderValue[] = [];
  if (hint.command === OriginalZOrderCommand.BRING_FRONT) {
    const maximum: string = units[units.length - 1].zIndex;
    for (let index: number = 0; index < selected.length; index++) {
      const zIndex: string | null = addUnsignedSmall(maximum, index + 1);
      if (zIndex === null) {
        return null;
      }
      appendZOrderChange(before, after, selected[index], zIndex);
    }
  } else if (hint.command === OriginalZOrderCommand.SEND_BACK) {
    const first: OriginalOrderUnit = units[0];
    const minimum: string = first.zIndex;
    const start: string | null = first.group ? subtractUnsignedSmall(minimum, selected.length) :
      minimum;
    if (start === null) {
      return null;
    }
    for (let index: number = 0; index < selected.length; index++) {
      const zIndex: string | null = addUnsignedSmall(start, index);
      if (zIndex === null) {
        return null;
      }
      appendZOrderChange(before, after, selected[index], zIndex);
    }
    if (!first.group) {
      let index: number = 0;
      for (const unit of units) {
        if (selectedUnitIds.has(unit.id)) {
          continue;
        }
        const candidate: string | null = addUnsignedSmall(
          minimum, selected.length + index);
        if (candidate === null) {
          return null;
        }
        if (compareUnsignedLongDecimal(unit.zIndex, candidate) < 0 && !unit.group) {
          if (unit.entries.length !== 1) {
            return null;
          }
          appendZOrderChange(before, after, unit.entries[0], candidate);
        }
        index++;
      }
    }
  } else if (hint.command === OriginalZOrderCommand.BRING_FORWARD ||
    hint.command === OriginalZOrderCommand.SEND_BACKWARD) {
    const forward: boolean = hint.command === OriginalZOrderCommand.BRING_FORWARD;
    const offset: number = forward ? 1 : -1;
    for (let index: number = 0; index < units.length; index++) {
      const unit: OriginalOrderUnit = units[index];
      if (!selectedUnitIds.has(unit.id) || unit.group) {
        continue;
      }
      const neighborIndex: number = index + offset;
      if (neighborIndex < 0 || neighborIndex >= units.length) {
        continue;
      }
      const neighbor: OriginalOrderUnit = units[neighborIndex];
      if (selectedUnitIds.has(neighbor.id) || unit.entries.length !== 1) {
        continue;
      }
      if (neighbor.group) {
        const zIndex: string | null = forward ? addUnsignedSmall(neighbor.zIndex, 1) :
          neighbor.zIndex === '0' ? '0' : subtractUnsignedSmall(neighbor.zIndex, 1);
        if (zIndex === null) {
          return null;
        }
        appendZOrderChange(before, after, unit.entries[0], zIndex);
      } else {
        if (neighbor.entries.length !== 1) {
          return null;
        }
        appendZOrderChange(before, after, unit.entries[0], neighbor.zIndex);
        appendZOrderChange(before, after, neighbor.entries[0], unit.zIndex);
      }
    }
  } else {
    return null;
  }
  return before.length > 0 && sameZOrderTargets(before, after) &&
    zOrderValuesProduce(order, after, next) ? { before: before, after: after } : null;
}

function originalOrderUnits(order: OriginalOrderEntry[]): OriginalOrderUnit[] | null {
  const units: OriginalOrderUnit[] = [];
  const byId: Map<string, OriginalOrderUnit> = new Map<string, OriginalOrderUnit>();
  for (const entry of order) {
    let unit: OriginalOrderUnit | undefined = byId.get(entry.unitId);
    if (unit === undefined) {
      unit = { id: entry.unitId, timestamp: entry.unitTimestamp, siteId: entry.unitSiteId,
        zIndex: entry.unitZIndex, group: entry.unitGroup, entries: [] };
      byId.set(entry.unitId, unit);
      units.push(unit);
    } else if (unit.timestamp !== entry.unitTimestamp || unit.siteId !== entry.unitSiteId ||
      unit.zIndex !== entry.unitZIndex || unit.group !== entry.unitGroup) {
      return null;
    }
    unit.entries.push(entry);
  }
  return units;
}

function appendZOrderChange(before: OriginalZOrderValue[], after: OriginalZOrderValue[],
  entry: OriginalOrderEntry, zIndex: string): void {
  const target: OperationIdentity = { timestamp: entry.timestamp, siteId: entry.siteId };
  before.push({ target: target, zIndex: entry.zIndex });
  after.push({ target: target, zIndex: zIndex });
}

function zOrderValuesMatch(order: OriginalOrderEntry[], values: OriginalZOrderValue[]): boolean {
  const byId: Map<string, OriginalOrderEntry> = new Map<string, OriginalOrderEntry>();
  for (const entry of order) {
    byId.set(encodeOperationId({ timestamp: entry.timestamp, siteId: entry.siteId }), entry);
  }
  for (const value of values) {
    const entry: OriginalOrderEntry | undefined = byId.get(encodeOperationId(value.target));
    if (entry === undefined || entry.zIndex !== value.zIndex) {
      return false;
    }
  }
  return values.length > 0;
}

function zOrderValuesProduce(order: OriginalOrderEntry[], values: OriginalZOrderValue[],
  next: PreparedElement[]): boolean {
  const replacements: Map<string, string> = new Map<string, string>();
  for (const value of values) {
    const id: string = encodeOperationId(value.target);
    if (replacements.has(id)) {
      return false;
    }
    replacements.set(id, value.zIndex);
  }
  const projected: OriginalOrderEntry[] = order.map(
    (entry: OriginalOrderEntry): OriginalOrderEntry => {
      const id: string = encodeOperationId({ timestamp: entry.timestamp, siteId: entry.siteId });
      const zIndex: string | undefined = replacements.get(id);
      return { key: entry.key, timestamp: entry.timestamp, siteId: entry.siteId,
        zIndex: zIndex === undefined ? entry.zIndex : zIndex,
        unitId: entry.unitId, unitTimestamp: entry.unitTimestamp,
        unitSiteId: entry.unitSiteId,
        unitZIndex: zIndex !== undefined && !entry.unitGroup ? zIndex : entry.unitZIndex,
        unitGroup: entry.unitGroup };
    });
  projected.sort(compareOriginalOrderEntries);
  return orderEntriesMatchPrepared(projected, next);
}

function orderEntriesMatchPrepared(order: OriginalOrderEntry[], next: PreparedElement[]): boolean {
  if (order.length !== next.length) {
    return false;
  }
  for (let index: number = 0; index < order.length; index++) {
    if (order[index].key !== `${next[index].kind}:${next[index].elementId}`) {
      return false;
    }
  }
  return true;
}

function sameZOrderTargets(before: OriginalZOrderValue[], after: OriginalZOrderValue[]): boolean {
  if (before.length === 0 || before.length !== after.length) {
    return false;
  }
  const ids: Set<string> = new Set<string>();
  for (let index: number = 0; index < before.length; index++) {
    validateOperationIdentity(before[index].target);
    validateOperationIdentity(after[index].target);
    validateUnsignedLongDecimal(before[index].zIndex);
    validateUnsignedLongDecimal(after[index].zIndex);
    const beforeId: string = encodeOperationId(before[index].target);
    if (beforeId !== encodeOperationId(after[index].target) || ids.has(beforeId)) {
      return false;
    }
    ids.add(beforeId);
  }
  return true;
}

function decodeOriginalZOrderValues(encoded: string): OriginalZOrderValue[] {
  const values: OriginalZOrderValue[] = JSON.parse(encoded) as OriginalZOrderValue[];
  if (!Array.isArray(values) || values.length === 0 || values.length > 10000) {
    throw new Error('original z-order history has an invalid count');
  }
  for (const value of values) {
    validateOperationIdentity(value.target);
    validateUnsignedLongDecimal(value.zIndex);
  }
  return values;
}

function addUnsignedSmall(value: string, amount: number): string | null {
  validateUnsignedLongDecimal(value);
  if (!Number.isSafeInteger(amount) || amount < 0) {
    return null;
  }
  let result: string = value;
  let remaining: number = amount;
  while (remaining > 0) {
    let carry: number = 1;
    let next: string = '';
    for (let index: number = result.length - 1; index >= 0; index--) {
      const digit: number = result.charCodeAt(index) - 0x30 + carry;
      next = (digit % 10).toString() + next;
      carry = Math.floor(digit / 10);
    }
    result = carry === 0 ? next : '1' + next;
    if (result.length > MAX_UNSIGNED_LONG_DECIMAL.length ||
      (result.length === MAX_UNSIGNED_LONG_DECIMAL.length && result > MAX_UNSIGNED_LONG_DECIMAL)) {
      return null;
    }
    remaining--;
  }
  return result;
}

function subtractUnsignedSmall(value: string, amount: number): string | null {
  validateUnsignedLongDecimal(value);
  if (!Number.isSafeInteger(amount) || amount < 0) {
    return null;
  }
  let result: string = value;
  let remaining: number = amount;
  while (remaining > 0 && result !== '0') {
    let borrow: number = 1;
    let next: string = '';
    for (let index: number = result.length - 1; index >= 0; index--) {
      let digit: number = result.charCodeAt(index) - 0x30 - borrow;
      if (digit < 0) {
        digit += 10;
        borrow = 1;
      } else {
        borrow = 0;
      }
      next = digit.toString() + next;
    }
    let first: number = 0;
    while (first < next.length - 1 && next.charCodeAt(first) === 0x30) {
      first++;
    }
    result = next.substring(first);
    remaining--;
  }
  return result;
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
  expected: Array<PreparedElement | SearchSourceElement>): boolean {
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

function sameImageCropDomain(before: ImageElement, after: ImageElement): boolean {
  if (!numbersNear(before.intrinsicWidth, after.intrinsicWidth) ||
    !numbersNear(before.intrinsicHeight, after.intrinsicHeight) ||
    before.assetHash !== after.assetHash || before.fileName !== after.fileName ||
    before.mimeType !== after.mimeType || before.fileSize !== after.fileSize ||
    before.assetHashBits.length !== after.assetHashBits.length) {
    return false;
  }
  for (let index: number = 0; index < before.assetHashBits.length; index++) {
    if (before.assetHashBits[index] !== after.assetHashBits[index]) {
      return false;
    }
  }
  return true;
}

function validIntrinsicCrop(crop: Rect2D, image: ImageElement): boolean {
  return finiteRect(crop) && Number.isFinite(image.intrinsicWidth) &&
    Number.isFinite(image.intrinsicHeight) && image.intrinsicWidth > 0.0001 &&
    image.intrinsicHeight > 0.0001 && crop.left >= -0.0001 && crop.top >= -0.0001 &&
    crop.right <= image.intrinsicWidth + 0.0001 &&
    crop.bottom <= image.intrinsicHeight + 0.0001 &&
    crop.right - crop.left > 0.0001 && crop.bottom - crop.top > 0.0001;
}

function samePreparedMembersAndPayloads(current: SearchSourceElement[],
  expected: PreparedElement[]): boolean {
  if (current.length !== expected.length) {
    return false;
  }
  const byKey: Map<string, SearchSourceElement> = new Map<string, SearchSourceElement>();
  for (const element of current) {
    byKey.set(`${element.kind}:${element.elementId}`, element);
  }
  if (byKey.size !== current.length) {
    return false;
  }
  for (const element of expected) {
    const source: SearchSourceElement | undefined = byKey.get(`${element.kind}:${element.elementId}`);
    if (source === undefined || !sameByteArrays(source.payload, element.payload)) {
      return false;
    }
    byKey.delete(`${element.kind}:${element.elementId}`);
  }
  return byKey.size === 0;
}

function sameElement(left: SearchSourceElement | PreparedElement,
  right: SearchSourceElement | PreparedElement): boolean {
  return left.elementId === right.elementId && left.kind === right.kind &&
    sameByteArrays(left.payload, right.payload);
}

function positionOnlyMutation(kind: number, before: PersistedElement,
  after: PersistedElement): boolean {
  if (!finiteRect(after.data.bounds)) {
    return false;
  }
  let candidate: PersistedElement;
  if (kind === PageElementKind.STROKE && before.kind === 'stroke' && after.kind === 'stroke') {
    const source: StrokeElementData = before.data as StrokeElementData;
    const target: StrokeElementData = after.data as StrokeElementData;
    const stroke: StrokeElementData = {
      id: source.id, pathPoints: source.pathPoints, cubicSegments: source.cubicSegments,
      splatPoints: source.splatPoints, renderSpec: source.renderSpec,
      transform: target.transform, bounds: target.bounds, maskPath: source.maskPath,
      customPath: source.customPath, fillPath: source.fillPath, fillColor: source.fillColor,
      styleMap: source.styleMap, audioStartTime: source.audioStartTime,
      audioDuration: source.audioDuration, originalCreate: source.originalCreate,
      isFinished: source.isFinished,
    };
    candidate = { kind: 'stroke', data: stroke };
  } else if (kind === PageElementKind.TEXT && before.kind === 'text' && after.kind === 'text') {
    const text: TextBlockElement = cloneTextBlockElement(before.data as TextBlockElement);
    text.transform = after.data.transform.slice();
    text.rotationRadians = Math.atan2(text.transform[3], text.transform[0]);
    text.bounds = textBlockWorldBounds(text);
    candidate = { kind: 'text', data: text };
  } else if (kind === PageElementKind.IMAGE && before.kind === 'image' && after.kind === 'image') {
    const image: ImageElement = cloneImageElement(before.data as ImageElement);
    image.transform = after.data.transform.slice();
    image.rotationRadians = Math.atan2(image.transform[3], image.transform[0]);
    image.bounds = imageBlockWorldBounds(image);
    candidate = { kind: 'image', data: image };
  } else if (kind === PageElementKind.MATH && before.kind === 'math' && after.kind === 'math') {
    const math: MathElement = cloneMathElement(before.data as MathElement);
    math.transform = after.data.transform.slice();
    math.rotationRadians = Math.atan2(math.transform[3], math.transform[0]);
    math.bounds = mathBlockWorldBounds(math);
    candidate = { kind: 'math', data: math };
  } else if (kind === PageElementKind.SHAPE && before.kind === 'shape' && after.kind === 'shape') {
    const shape: ShapeElement = cloneShapeElement(before.data as ShapeElement);
    shape.transform = after.data.transform.slice();
    shape.bounds = recomputeShapeBounds(shape);
    candidate = { kind: 'shape', data: shape };
  } else {
    return false;
  }
  return sameByteArrays(encodePersistedElement(candidate), encodePersistedElement(after));
}

function positionComponents(matrix: TransformMatrix): PositionComponents | null {
  if (matrix.length !== 9 || !matrix.every((value: number): boolean => Number.isFinite(value)) ||
    !numbersNear(matrix[6], 0) || !numbersNear(matrix[7], 0) || !numbersNear(matrix[8], 1)) {
    return null;
  }
  const scaleX: number = Math.sqrt(matrix[0] * matrix[0] + matrix[3] * matrix[3]);
  const determinant: number = matrix[0] * matrix[4] - matrix[1] * matrix[3];
  if (scaleX <= 0.000001 || determinant <= 0.000001) {
    return null;
  }
  const scaleY: number = determinant / scaleX;
  const rotation: number = Math.atan2(matrix[3], matrix[0]);
  const cosine: number = Math.cos(rotation);
  const sine: number = Math.sin(rotation);
  const expected: TransformMatrix = [cosine * scaleX, -sine * scaleY, matrix[2],
    sine * scaleX, cosine * scaleY, matrix[5], 0, 0, 1];
  if (!matricesNear(matrix, expected)) {
    return null;
  }
  return { originX: matrix[2], originY: matrix[5], rotation: rotation,
    scaleX: scaleX, scaleY: scaleY };
}

function matricesNear(left: TransformMatrix, right: TransformMatrix): boolean {
  if (left.length !== right.length) {
    return false;
  }
  for (let index: number = 0; index < left.length; index++) {
    if (!numbersNear(left[index], right[index])) {
      return false;
    }
  }
  return true;
}

function numbersNear(left: number, right: number): boolean {
  return Math.abs(left - right) <= 0.000001 * Math.max(1, Math.abs(left), Math.abs(right));
}

function anglesNear(left: number, right: number): boolean {
  const fullTurn: number = Math.PI * 2;
  const delta: number = ((left - right + Math.PI) % fullTurn + fullTurn) % fullTurn - Math.PI;
  return Math.abs(delta) <= 0.000001;
}

function finiteRect(rect: Rect2D): boolean {
  return Number.isFinite(rect.left) && Number.isFinite(rect.top) &&
    Number.isFinite(rect.right) && Number.isFinite(rect.bottom) &&
    rect.left <= rect.right && rect.top <= rect.bottom;
}

function localStoredOperation(noteId: string, metadata: OriginalInkCreateMetadata,
  payloadType: number, payload: Uint8Array, audioTime: string | null): StoredSyncedOperation {
  const rawOperation: Uint8Array = encodeOriginalOperationEnvelope({
    identity: { timestamp: metadata.timestamp, siteId: metadata.siteId },
    clientTime: metadata.clientTime.toString(), serverTime: null, audioTime: audioTime,
    payloadType: payloadType,
  }, payload);
  return {
    noteId: noteId, timestamp: metadata.timestamp, siteId: metadata.siteId,
    clientTime: metadata.clientTime.toString(), serverTime: '0', audioTime: audioTime,
    schemaVersion: 1, payloadType: payloadType, rawOperation: rawOperation,
    state: SyncedOperationInboxState.APPLIED, deferredReason: null,
    receivedAt: metadata.clientTime,
  };
}
