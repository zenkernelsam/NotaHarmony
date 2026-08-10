import { relationalStore } from '@kit.ArkData';
import { Point2D, Rect2D } from '../core/model/GeometryTypes';
import { PageElementKind } from '../core/model/PageElementOrder';
import { InkStyle, StrokeElementData, StrokePathPoint } from '../core/model/StrokeTypes';
import {
  ORIGINAL_PENCIL_FALLBACK_SEED, PencilSplatGenerator, PencilSplatLimitError,
} from '../core/algorithm/PencilSplatGenerator';
import {
  compareOperationIdentity, encodeOperationId, OperationIdentity, OriginalSequenceIdentity,
  validateOperationIdentity, validateOriginalSequenceIdentity,
} from './OperationIdentity';
import {
  decodeOriginalInkPath, decodeOriginalInkPathAppend, DecodedOriginalInkPath,
  DecodedOriginalInkPathAppend, inkPathCommandBounds, OriginalInkPathDeferredError,
  transformedInkBounds, unionOriginalInkBounds,
} from './OriginalInkPathCodec';
import {
  OriginalFlatBufferTableReader, readOriginalPayloadTable,
} from './OriginalSyncedOperationFlatBuffer';
import { SearchItemType } from './SearchItemType';
import {
  decodePersistedElement, encodePersistedElement, PersistedElement,
} from './StrokePersistence';
import {
  StoredSyncedOperation, SyncedOperationApplier, SyncedOperationApplyResult,
} from './SyncedOperationInbox';

export const ORIGINAL_ADD_PATH_ELEMENTS_PAYLOAD_TYPE: number = 16;
const MAX_ORIGINAL_INK_PATH_BYTES: number = 16 * 1024 * 1024;
const MAX_SYNCED_PENCIL_SPLATS: number = 262144;

export interface OriginalAddPathElementsPayload {
  ink: OperationIdentity;
  centerPathElements: Uint8Array | null;
  centerPathEstimatedElements: Uint8Array | null;
}

interface StoredInkTarget {
  ink: OperationIdentity;
  page: OriginalSequenceIdentity;
  pageId: string;
  table: string;
  revisionTable: string;
  revision: number;
  archived: boolean;
}

interface StoredEstimatedPath {
  bytes: Uint8Array;
  winner: OperationIdentity | null;
}

export interface OriginalInkAppendRecord extends OperationIdentity {
  bytes: Uint8Array;
}

export interface RebuiltOriginalInkGeometry {
  pathPoints: StrokePathPoint[];
  cubicSegments: StrokeElementData['cubicSegments'];
  splatPoints: StrokeElementData['splatPoints'];
  bounds: Rect2D;
  attributed: boolean;
}

export function decodeOriginalAddPathElements(bytes: Uint8Array): OriginalAddPathElementsPayload {
  return decodeOriginalAddPathElementsTable(
    readOriginalPayloadTable(bytes, ORIGINAL_ADD_PATH_ELEMENTS_PAYLOAD_TYPE));
}

export function decodeOriginalAddPathElementsTable(table: OriginalFlatBufferTableReader):
  OriginalAddPathElementsPayload {
  const rawInk: Uint8Array | null = table.readInlineBytes(0, 8);
  if (rawInk === null) {
    throw new Error('original add-path-elements is missing its target ink');
  }
  const ink: OperationIdentity = {
    siteId: readUint16(rawInk, 0), timestamp: readUint32(rawInk, 4),
  };
  validateOperationIdentity(ink);
  const centerPathElements: Uint8Array | null = table.readByteVector(
    1, false, MAX_ORIGINAL_INK_PATH_BYTES);
  const centerPathEstimatedElements: Uint8Array | null = table.readByteVector(
    2, false, MAX_ORIGINAL_INK_PATH_BYTES);
  if (centerPathElements === null && centerPathEstimatedElements === null) {
    throw new Error('original add-path-elements contains no path elements');
  }
  return {
    ink: ink,
    centerPathElements: centerPathElements,
    centerPathEstimatedElements: centerPathEstimatedElements,
  };
}

export class OriginalAddPathElementsOperationApplier implements SyncedOperationApplier {
  supports(payloadType: number): boolean {
    return payloadType === ORIGINAL_ADD_PATH_ELEMENTS_PAYLOAD_TYPE;
  }

  async apply(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation): Promise<SyncedOperationApplyResult> {
    let payload: OriginalAddPathElementsPayload;
    try {
      payload = decodeOriginalAddPathElements(operation.rawOperation);
    } catch (_error) {
      return { deferredReason: 'MALFORMED_ADD_PATH_ELEMENTS_PAYLOAD' };
    }
    return this.applyPayload(store, operation, payload);
  }

  preflightTable(table: OriginalFlatBufferTableReader): string | null {
    let payload: OriginalAddPathElementsPayload;
    try {
      payload = decodeOriginalAddPathElementsTable(table);
    } catch (_error) {
      return 'MALFORMED_ADD_PATH_ELEMENTS_PAYLOAD';
    }
    return preflightOriginalAddPathElements(payload);
  }

  async applyTable(store: relationalStore.RdbStore, operation: StoredSyncedOperation,
    table: OriginalFlatBufferTableReader): Promise<SyncedOperationApplyResult> {
    let payload: OriginalAddPathElementsPayload;
    try {
      payload = decodeOriginalAddPathElementsTable(table);
    } catch (_error) {
      return { deferredReason: 'MALFORMED_ADD_PATH_ELEMENTS_PAYLOAD' };
    }
    return this.applyPayload(store, operation, payload);
  }

  private async applyPayload(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation,
    payload: OriginalAddPathElementsPayload): Promise<SyncedOperationApplyResult> {
    let actualProbe: DecodedOriginalInkPathAppend | null = null;
    let estimatedProbe: DecodedOriginalInkPathAppend | null = null;
    try {
      if (payload.centerPathElements !== null) {
        actualProbe = decodeOriginalInkPathAppend(
          payload.centerPathElements, { x: 0, y: 0 });
      }
      if (payload.centerPathEstimatedElements !== null) {
        estimatedProbe = decodeOriginalInkPathAppend(
          payload.centerPathEstimatedElements, { x: 0, y: 0 });
      }
    } catch (_error) {
      if (_error instanceof OriginalInkPathDeferredError) {
        return { deferredReason: _error.deferredReason };
      }
      return { deferredReason: 'MALFORMED_ADD_PATH_ELEMENTS_PAYLOAD' };
    }

    const estimatedState: StoredEstimatedPath | null = await this.readEstimatedPath(
      store, operation.noteId, payload.ink);
    if (estimatedState === null) {
      return { deferredReason: 'ADD_PATH_ELEMENTS_BASE_STATE_MISSING' };
    }
    const existingAppends: OriginalInkAppendRecord[] = await this.readAppends(
      store, operation.noteId, payload.ink);
    const existingAppend: OriginalInkAppendRecord | undefined = existingAppends.find(
      (append: OriginalInkAppendRecord): boolean =>
        compareOperationIdentity(append, operation) === 0);
    if (existingAppend !== undefined && payload.centerPathElements === null) {
      throw new Error('original add-path-elements identity conflicts with persisted actual path');
    }
    if (existingAppend !== undefined && !sameBytes(
      existingAppend.bytes, payload.centerPathElements as Uint8Array)) {
      throw new Error('original add-path-elements identity conflicts with persisted actual path');
    }
    const incomingEstimated: Uint8Array = payload.centerPathEstimatedElements === null ?
      new Uint8Array(0) : payload.centerPathEstimatedElements;
    const estimatedComparison: number | null = estimatedState.winner === null ? null :
      compareOperationIdentity(estimatedState.winner, operation);
    let operationAlreadyApplied: boolean = false;
    if (estimatedComparison === 0) {
      if (!sameBytes(estimatedState.bytes, incomingEstimated)) {
        throw new Error('original add-path-elements identity conflicts with persisted estimated path');
      }
    }
    if (existingAppend !== undefined) {
      if (estimatedComparison === null || estimatedComparison < 0) {
        throw new Error('original add-path-elements has partial persisted state');
      }
      operationAlreadyApplied = true;
    }
    if (payload.centerPathElements !== null && existingAppend === undefined &&
      estimatedComparison === 0) {
      throw new Error('original add-path-elements has partial persisted state');
    }
    if (payload.centerPathElements === null && estimatedComparison !== null &&
      estimatedComparison >= 0) {
      operationAlreadyApplied = true;
    }

    const target: StoredInkTarget | null = await this.readTarget(store, operation.noteId, payload.ink);
    if (target === null) {
      return operationAlreadyApplied ? { deferredReason: null } :
        { deferredReason: 'ADD_PATH_ELEMENTS_INK_MISSING_OR_UNBOUND' };
    }
    const basePath: Uint8Array | null = await this.readBasePath(store, operation.noteId, payload.ink);
    if (basePath === null) {
      return { deferredReason: 'ADD_PATH_ELEMENTS_BASE_STATE_MISSING' };
    }
    const stroke: StrokeElementData | null = await this.readStroke(store, operation.noteId, target);
    if (stroke === null) {
      return { deferredReason: 'ADD_PATH_ELEMENTS_STROKE_DIVERGED' };
    }
    const unsupported: string | null = this.unsupportedStrokeReason(
      stroke, actualProbe, estimatedProbe);
    if (unsupported !== null) {
      return { deferredReason: unsupported };
    }
    let expected: RebuiltOriginalInkGeometry;
    try {
      expected = rebuildOriginalInkGeometry(
        basePath, existingAppends, stroke, estimatedState.bytes);
    } catch (_error) {
      if (_error instanceof PencilSplatLimitError) {
        return { deferredReason: 'ADD_PATH_ELEMENTS_PENCIL_SPLAT_BUDGET_EXCEEDED' };
      }
      return { deferredReason: 'ADD_PATH_ELEMENTS_TRACKED_STATE_INVALID' };
    }
    if (!originalInkGeometryMatches(stroke, expected)) {
      return { deferredReason: 'ADD_PATH_ELEMENTS_STROKE_DIVERGED' };
    }
    if (operationAlreadyApplied) {
      return { deferredReason: null };
    }
    const replaceEstimated: boolean = estimatedState.winner === null ||
      compareOperationIdentity(operation, estimatedState.winner) > 0;
    if (payload.centerPathElements === null && !replaceEstimated) {
      return { deferredReason: null };
    }
    if (target.revision >= Number.MAX_SAFE_INTEGER) {
      return { deferredReason: 'ADD_PATH_ELEMENTS_PAGE_REVISION_EXHAUSTED' };
    }

    const allAppends: OriginalInkAppendRecord[] = existingAppends.slice();
    if (payload.centerPathElements !== null && existingAppend === undefined) {
      allAppends.push({
        timestamp: operation.timestamp, siteId: operation.siteId,
        bytes: payload.centerPathElements,
      });
    }
    allAppends.sort(compareStoredAppend);
    const estimatedBytes: Uint8Array = replaceEstimated ?
      (payload.centerPathEstimatedElements === null ? new Uint8Array(0) :
        payload.centerPathEstimatedElements) : estimatedState.bytes;
    let rebuilt: RebuiltOriginalInkGeometry;
    try {
      rebuilt = rebuildOriginalInkGeometry(basePath, allAppends, stroke, estimatedBytes);
    } catch (_error) {
      if (_error instanceof PencilSplatLimitError) {
        return { deferredReason: 'ADD_PATH_ELEMENTS_PENCIL_SPLAT_BUDGET_EXCEEDED' };
      }
      return { deferredReason: 'MALFORMED_ADD_PATH_ELEMENTS_PAYLOAD' };
    }
    const updatedStroke: StrokeElementData = {
      id: stroke.id,
      pathPoints: rebuilt.pathPoints,
      cubicSegments: rebuilt.cubicSegments,
      splatPoints: rebuilt.splatPoints,
      renderSpec: stroke.renderSpec,
      transform: stroke.transform,
      bounds: rebuilt.bounds,
      maskPath: stroke.maskPath,
      customPath: stroke.customPath,
      fillPath: stroke.fillPath,
      fillColor: stroke.fillColor,
      styleMap: stroke.styleMap,
      isFinished: stroke.isFinished,
    };
    if (payload.centerPathElements !== null && existingAppend === undefined) {
      await store.insert('original_ink_path_append', {
        'note_id': operation.noteId,
        'ink_timestamp': payload.ink.timestamp,
        'ink_site_id': payload.ink.siteId,
        'append_timestamp': operation.timestamp,
        'append_site_id': operation.siteId,
        'center_path_elements': payload.centerPathElements,
      });
    }
    if (replaceEstimated) {
      await this.updateEstimatedPath(store, operation.noteId, payload.ink,
        operation, estimatedBytes);
    }
    await this.updateStroke(store, operation.noteId, target, updatedStroke);
    await this.advanceRevisionAndInvalidateSearch(store, operation.noteId, target);
    return { deferredReason: null };
  }

  private unsupportedStrokeReason(stroke: StrokeElementData,
    actual: DecodedOriginalInkPathAppend | null,
    estimated: DecodedOriginalInkPathAppend | null): string | null {
    if (!isSupportedOriginalStoredStroke(stroke)) {
      return 'ADD_PATH_ELEMENTS_STROKE_DIVERGED';
    }
    if (!stroke.renderSpec.isPencil && stroke.splatPoints.length > 0) {
      return 'ADD_PATH_ELEMENTS_STROKE_DIVERGED';
    }
    if (stroke.renderSpec.inkStyle < InkStyle.FIXED_WIDTH ||
      stroke.renderSpec.inkStyle > InkStyle.DOTS) {
      return 'ADD_PATH_ELEMENTS_STYLE_UNSUPPORTED';
    }
    if (!stroke.renderSpec.isPencil && stroke.renderSpec.inkStyle === InkStyle.VARIABLE_WIDTH &&
      ((actual !== null && !actual.attributed) ||
        (estimated !== null && !estimated.attributed))) {
      return 'ADD_PATH_ELEMENTS_VARIABLE_PATH_ATTRIBUTES_MISSING';
    }
    return null;
  }

  private async readTarget(store: relationalStore.RdbStore, noteId: string,
    ink: OperationIdentity): Promise<StoredInkTarget | null> {
    const rows = await store.querySql(
      `SELECT element.kind, element.page_timestamp, element.page_site_id, element.page_index,
              identity.page_id, identity.visible
       FROM original_element_z_index element
       JOIN original_page_identity identity ON identity.note_id = element.note_id
        AND identity.seq_timestamp = element.page_timestamp
        AND identity.seq_site_id = element.page_site_id AND identity.seq_index = element.page_index
       WHERE element.note_id = ? AND element.element_timestamp = ? AND element.element_site_id = ?
        AND element.visible = 1`,
      [noteId, ink.timestamp, ink.siteId]);
    let page: OriginalSequenceIdentity;
    let pageId: string;
    try {
      if (!rows.goToFirstRow() || rows.getLong(rows.getColumnIndex('kind')) !== PageElementKind.STROKE ||
        rows.getLong(rows.getColumnIndex('visible')) !== 1 ||
        rows.isColumnNull(rows.getColumnIndex('page_id'))) {
        return null;
      }
      page = {
        timestamp: rows.getLong(rows.getColumnIndex('page_timestamp')),
        siteId: rows.getLong(rows.getColumnIndex('page_site_id')),
        index: rows.getLong(rows.getColumnIndex('page_index')),
      };
      pageId = rows.getString(rows.getColumnIndex('page_id'));
    } finally {
      rows.close();
    }
    validateOriginalSequenceIdentity(page);
    const liveRevision: number | null = await readSingleRevision(store,
      'SELECT content_revision FROM page_info WHERE note_id = ? AND page_id = ?', [noteId, pageId]);
    const archivedRevision: number | null = await readSingleRevision(store,
      `SELECT content_revision FROM original_deleted_page WHERE note_id = ?
       AND page_timestamp = ? AND page_site_id = ? AND page_index = ?`,
      [noteId, page.timestamp, page.siteId, page.index]);
    if ((liveRevision === null) === (archivedRevision === null)) {
      return null;
    }
    return liveRevision !== null ? {
      ink: ink, page: page, pageId: pageId, table: 'page_element_snapshot',
      revisionTable: 'page_info', revision: liveRevision, archived: false,
    } : {
      ink: ink, page: page, pageId: pageId, table: 'original_deleted_page_element',
      revisionTable: 'original_deleted_page', revision: archivedRevision as number, archived: true,
    };
  }

  private async readBasePath(store: relationalStore.RdbStore, noteId: string,
    ink: OperationIdentity): Promise<Uint8Array | null> {
    const rows = await store.querySql(
      `SELECT base_center_path FROM original_ink_state WHERE note_id = ?
       AND ink_timestamp = ? AND ink_site_id = ?`, [noteId, ink.timestamp, ink.siteId]);
    try {
      return rows.goToFirstRow() ? rows.getBlob(rows.getColumnIndex('base_center_path')) : null;
    } finally {
      rows.close();
    }
  }

  private async readEstimatedPath(store: relationalStore.RdbStore, noteId: string,
    ink: OperationIdentity): Promise<StoredEstimatedPath | null> {
    const rows = await store.querySql(
      `SELECT estimated_center_path, estimated_path_winner_timestamp,
              estimated_path_winner_site_id, estimated_path_winner_present
       FROM original_ink_state WHERE note_id = ? AND ink_timestamp = ? AND ink_site_id = ?`,
      [noteId, ink.timestamp, ink.siteId]);
    try {
      if (!rows.goToFirstRow()) {
        return null;
      }
      const present: boolean = rows.getLong(
        rows.getColumnIndex('estimated_path_winner_present')) === 1;
      let winner: OperationIdentity | null = null;
      if (present) {
        winner = {
          timestamp: rows.getLong(rows.getColumnIndex('estimated_path_winner_timestamp')),
          siteId: rows.getLong(rows.getColumnIndex('estimated_path_winner_site_id')),
        };
        validateOperationIdentity(winner);
      }
      const bytes: Uint8Array = rows.getBlob(rows.getColumnIndex('estimated_center_path'));
      if (!present && bytes.length > 0) {
        return null;
      }
      return {
        bytes: bytes,
        winner: winner,
      };
    } finally {
      rows.close();
    }
  }

  private async updateEstimatedPath(store: relationalStore.RdbStore, noteId: string,
    ink: OperationIdentity, operation: StoredSyncedOperation,
    bytes: Uint8Array): Promise<void> {
    const predicates = new relationalStore.RdbPredicates('original_ink_state');
    predicates.equalTo('note_id', noteId);
    predicates.equalTo('ink_timestamp', ink.timestamp);
    predicates.equalTo('ink_site_id', ink.siteId);
    const updated: number = await store.update({
      'estimated_center_path': bytes,
      'estimated_path_winner_timestamp': operation.timestamp,
      'estimated_path_winner_site_id': operation.siteId,
      'estimated_path_winner_present': 1,
    }, predicates);
    if (updated !== 1) {
      throw new Error('original add-path-elements lost its estimated-path register');
    }
  }

  private async readAppends(store: relationalStore.RdbStore, noteId: string,
    ink: OperationIdentity): Promise<OriginalInkAppendRecord[]> {
    const rows = await store.querySql(
      `SELECT append_timestamp, append_site_id, center_path_elements
       FROM original_ink_path_append WHERE note_id = ? AND ink_timestamp = ? AND ink_site_id = ?
       ORDER BY append_timestamp, append_site_id`, [noteId, ink.timestamp, ink.siteId]);
    const result: OriginalInkAppendRecord[] = [];
    try {
      while (rows.goToNextRow()) {
        result.push({
          timestamp: rows.getLong(rows.getColumnIndex('append_timestamp')),
          siteId: rows.getLong(rows.getColumnIndex('append_site_id')),
          bytes: rows.getBlob(rows.getColumnIndex('center_path_elements')),
        });
      }
    } finally {
      rows.close();
    }
    for (const append of result) {
      validateOperationIdentity(append);
    }
    return result;
  }

  private async readStroke(store: relationalStore.RdbStore, noteId: string,
    target: StoredInkTarget): Promise<StrokeElementData | null> {
    const elementId: string = encodeOperationId(target.ink);
    const rows = target.archived ? await store.querySql(
      `SELECT payload FROM original_deleted_page_element WHERE note_id = ?
       AND page_timestamp = ? AND page_site_id = ? AND page_index = ?
       AND element_id = ? AND kind = ?`,
      [noteId, target.page.timestamp, target.page.siteId, target.page.index,
        elementId, PageElementKind.STROKE]) : await store.querySql(
      `SELECT payload FROM page_element_snapshot WHERE note_id = ? AND page_id = ?
       AND element_id = ? AND kind = ?`,
      [noteId, target.pageId, elementId, PageElementKind.STROKE]);
    try {
      if (!rows.goToFirstRow()) {
        return null;
      }
      const persisted: PersistedElement = decodePersistedElement(
        rows.getBlob(rows.getColumnIndex('payload')));
      return persisted.kind === 'stroke' ? persisted.data as StrokeElementData : null;
    } catch (_error) {
      return null;
    } finally {
      rows.close();
    }
  }

  private async updateStroke(store: relationalStore.RdbStore, noteId: string,
    target: StoredInkTarget, stroke: StrokeElementData): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(target.table);
    predicates.equalTo('note_id', noteId);
    if (target.archived) {
      predicates.equalTo('page_timestamp', target.page.timestamp);
      predicates.equalTo('page_site_id', target.page.siteId);
      predicates.equalTo('page_index', target.page.index);
    } else {
      predicates.equalTo('page_id', target.pageId);
    }
    predicates.equalTo('element_id', stroke.id);
    predicates.equalTo('kind', PageElementKind.STROKE);
    const persisted: PersistedElement = { kind: 'stroke', data: stroke };
    const updated: number = await store.update({
      'payload': encodePersistedElement(persisted), 'revision': target.revision + 1,
    }, predicates);
    if (updated !== 1) {
      throw new Error('original add-path-elements lost its target stroke');
    }
  }

  private async advanceRevisionAndInvalidateSearch(store: relationalStore.RdbStore,
    noteId: string, target: StoredInkTarget): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(target.revisionTable);
    predicates.equalTo('note_id', noteId);
    if (target.archived) {
      predicates.equalTo('page_timestamp', target.page.timestamp);
      predicates.equalTo('page_site_id', target.page.siteId);
      predicates.equalTo('page_index', target.page.index);
    } else {
      predicates.equalTo('page_id', target.pageId);
    }
    predicates.equalTo('content_revision', target.revision);
    const values: relationalStore.ValuesBucket = { 'content_revision': target.revision + 1 };
    if (target.archived) {
      values['indexed_revision'] = null;
    }
    const updated: number = await store.update(values, predicates);
    if (updated !== 1) {
      throw new Error('original add-path-elements page revision changed concurrently');
    }
    if (target.archived) {
      await store.executeSql(
        `DELETE FROM original_deleted_page_search WHERE note_id = ? AND page_timestamp = ?
         AND page_site_id = ? AND page_index = ? AND type = ?`,
        [noteId, target.page.timestamp, target.page.siteId, target.page.index, SearchItemType.INK]);
    } else {
      await store.executeSql('DELETE FROM search_page_state WHERE note_id = ? AND page_id = ?',
        [noteId, target.pageId]);
      await store.executeSql(
        'DELETE FROM search_item WHERE note_id = ? AND page_id = ? AND type = ?',
        [noteId, target.pageId, SearchItemType.INK]);
    }
  }
}

function preflightOriginalAddPathElements(payload: OriginalAddPathElementsPayload): string | null {
  try {
    if (payload.centerPathElements !== null) {
      decodeOriginalInkPathAppend(payload.centerPathElements, { x: 0, y: 0 });
    }
    if (payload.centerPathEstimatedElements !== null) {
      decodeOriginalInkPathAppend(payload.centerPathEstimatedElements, { x: 0, y: 0 });
    }
  } catch (_error) {
    if (_error instanceof OriginalInkPathDeferredError) {
      return _error.deferredReason;
    }
    return 'MALFORMED_ADD_PATH_ELEMENTS_PAYLOAD';
  }
  return null;
}

function sameBytes(left: Uint8Array, right: Uint8Array): boolean {
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

export function rebuildOriginalInkGeometry(baseBytes: Uint8Array,
  appends: OriginalInkAppendRecord[], stroke: StrokeElementData,
  estimatedBytes?: Uint8Array | null): RebuiltOriginalInkGeometry {
  const base: DecodedOriginalInkPath = decodeOriginalInkPath(baseBytes);
  const pathPoints: StrokePathPoint[] = base.pathPoints.slice();
  const cubicSegments: StrokeElementData['cubicSegments'] = base.cubicSegments.slice();
  let localBounds: Rect2D = base.localBounds;
  let attributed: boolean = base.attributed;
  let current: Point2D = pathPoints[pathPoints.length - 1].position;
  const sorted: OriginalInkAppendRecord[] = appends.slice();
  sorted.sort(compareStoredAppend);
  for (const stored of sorted) {
    const append: DecodedOriginalInkPathAppend = decodeOriginalInkPathAppend(stored.bytes, current);
    if (!stroke.renderSpec.isPencil && stroke.renderSpec.inkStyle === InkStyle.VARIABLE_WIDTH &&
      !append.attributed) {
      throw new Error('variable-width append has no attributes');
    }
    pathPoints.push(...append.pathPoints);
    cubicSegments.push(...append.cubicSegments);
    localBounds = unionOriginalInkBounds(localBounds, append.localBounds);
    attributed = attributed && append.attributed;
    current = append.endPoint;
  }
  if (estimatedBytes !== undefined && estimatedBytes !== null && estimatedBytes.length > 0) {
    const estimated: DecodedOriginalInkPathAppend = decodeOriginalInkPathAppend(
      estimatedBytes, current);
    if (!stroke.renderSpec.isPencil && stroke.renderSpec.inkStyle === InkStyle.VARIABLE_WIDTH &&
      !estimated.attributed) {
      throw new Error('variable-width estimated path has no attributes');
    }
    pathPoints.push(...estimated.pathPoints);
    cubicSegments.push(...estimated.cubicSegments);
    localBounds = unionOriginalInkBounds(localBounds, estimated.localBounds);
    attributed = attributed && estimated.attributed;
  }
  const splatGenerator: PencilSplatGenerator = new PencilSplatGenerator({
    spacing: stroke.renderSpec.brushWidth, maximumSplatCount: MAX_SYNCED_PENCIL_SPLATS,
  });
  const styleEntry = stroke.styleMap === undefined || stroke.styleMap.length === 0 ?
    undefined : stroke.styleMap[0];
  splatGenerator.reset(styleEntry === undefined ? ORIGINAL_PENCIL_FALLBACK_SEED :
    styleEntry.backingPencilSeed);
  let referencePoint: Point2D | undefined = undefined;
  if (styleEntry !== undefined && (styleEntry.backingPencilReferencePoint.x !== 0 ||
    styleEntry.backingPencilReferencePoint.y !== 0)) {
    referencePoint = styleEntry.backingPencilReferencePoint;
  }
  const splatPoints: StrokeElementData['splatPoints'] = stroke.renderSpec.isPencil ?
    splatGenerator.generate(cubicSegments, pathPoints, undefined, referencePoint) : [];
  return {
    pathPoints: pathPoints,
    cubicSegments: cubicSegments,
    splatPoints: splatPoints,
    bounds: transformedInkBounds(localBounds,
      stroke.renderSpec.brushWidth * (stroke.renderSpec.isPencil ? 2.84 : 1), [
      inkPathCommandBounds(stroke.customPath), inkPathCommandBounds(stroke.fillPath),
    ], stroke.transform),
    attributed: attributed,
  };
}

export function originalInkGeometryMatches(stroke: StrokeElementData,
  expected: RebuiltOriginalInkGeometry): boolean {
  return JSON.stringify(stroke.pathPoints) === JSON.stringify(expected.pathPoints) &&
    JSON.stringify(stroke.cubicSegments) === JSON.stringify(expected.cubicSegments) &&
    JSON.stringify(stroke.splatPoints) === JSON.stringify(expected.splatPoints) &&
    JSON.stringify(stroke.bounds) === JSON.stringify(expected.bounds);
}

export function isSupportedOriginalStoredStroke(stroke: StrokeElementData): boolean {
  return typeof stroke.id === 'string' && stroke.id.length > 0 &&
    Array.isArray(stroke.pathPoints) && stroke.pathPoints.length >= 2 &&
    Array.isArray(stroke.cubicSegments) && Array.isArray(stroke.splatPoints) &&
    Array.isArray(stroke.transform) && hasOnlyFiniteNumbers(stroke.transform) &&
    stroke.transform.length === 9 && Array.isArray(stroke.maskPath) &&
    stroke.renderSpec !== undefined && stroke.renderSpec !== null &&
    Number.isFinite(stroke.renderSpec.brushWidth) && stroke.renderSpec.brushWidth >= 0 &&
    stroke.bounds !== undefined && stroke.bounds !== null &&
    Number.isFinite(stroke.bounds.left) && Number.isFinite(stroke.bounds.top) &&
    Number.isFinite(stroke.bounds.right) && Number.isFinite(stroke.bounds.bottom);
}

function hasOnlyFiniteNumbers(values: number[]): boolean {
  for (const value of values) {
    if (!Number.isFinite(value)) {
      return false;
    }
  }
  return true;
}

function compareStoredAppend(left: OriginalInkAppendRecord,
  right: OriginalInkAppendRecord): number {
  return compareOperationIdentity(left, right);
}

async function readSingleRevision(store: relationalStore.RdbStore, sql: string,
  args: relationalStore.ValueType[]): Promise<number | null> {
  const rows = await store.querySql(sql, args);
  try {
    if (!rows.goToFirstRow()) {
      return null;
    }
    const revision: number = rows.getLong(rows.getColumnIndex('content_revision'));
    if (!Number.isSafeInteger(revision) || revision < 0) {
      throw new Error('original target page has an invalid revision');
    }
    return revision;
  } finally {
    rows.close();
  }
}

function readUint16(bytes: Uint8Array, offset: number): number {
  return bytes[offset] + bytes[offset + 1] * 0x100;
}

function readUint32(bytes: Uint8Array, offset: number): number {
  return bytes[offset] + bytes[offset + 1] * 0x100 + bytes[offset + 2] * 0x10000 +
    bytes[offset + 3] * 0x1000000;
}
