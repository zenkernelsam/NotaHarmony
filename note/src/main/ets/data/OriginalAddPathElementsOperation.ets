import { relationalStore } from '@kit.ArkData';
import { Point2D, Rect2D } from '../core/model/GeometryTypes';
import { PageElementKind } from '../core/model/PageElementOrder';
import { InkStyle, StrokeElementData, StrokePathPoint } from '../core/model/StrokeTypes';
import {
  compareOperationIdentity, encodeOperationId, OperationIdentity, OriginalSequenceIdentity,
  validateOperationIdentity, validateOriginalSequenceIdentity,
} from './OperationIdentity';
import {
  decodeOriginalInkPath, decodeOriginalInkPathAppend, DecodedOriginalInkPath,
  DecodedOriginalInkPathAppend, OriginalInkPathDeferredError, transformedExpandedBounds,
  unionOriginalInkBounds,
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

export interface OriginalInkAppendRecord extends OperationIdentity {
  bytes: Uint8Array;
}

export interface RebuiltOriginalInkGeometry {
  pathPoints: StrokePathPoint[];
  cubicSegments: StrokeElementData['cubicSegments'];
  bounds: Rect2D;
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
    if (payload.centerPathEstimatedElements !== null) {
      return { deferredReason: 'ADD_PATH_ELEMENTS_ESTIMATED_PATH_UNSUPPORTED' };
    }
    const candidateBytes: Uint8Array = payload.centerPathElements as Uint8Array;
    let candidateProbe: DecodedOriginalInkPathAppend;
    try {
      candidateProbe = decodeOriginalInkPathAppend(candidateBytes, { x: 0, y: 0 });
    } catch (_error) {
      if (_error instanceof OriginalInkPathDeferredError) {
        return { deferredReason: _error.deferredReason };
      }
      return { deferredReason: 'MALFORMED_ADD_PATH_ELEMENTS_PAYLOAD' };
    }

    const target: StoredInkTarget | null = await this.readTarget(store, operation.noteId, payload.ink);
    if (target === null) {
      return { deferredReason: 'ADD_PATH_ELEMENTS_INK_MISSING_OR_UNBOUND' };
    }
    const basePath: Uint8Array | null = await this.readBasePath(store, operation.noteId, payload.ink);
    if (basePath === null) {
      return { deferredReason: 'ADD_PATH_ELEMENTS_BASE_STATE_MISSING' };
    }
    const stroke: StrokeElementData | null = await this.readStroke(store, operation.noteId, target);
    if (stroke === null) {
      return { deferredReason: 'ADD_PATH_ELEMENTS_STROKE_DIVERGED' };
    }
    const unsupported: string | null = this.unsupportedStrokeReason(stroke, candidateProbe);
    if (unsupported !== null) {
      return { deferredReason: unsupported };
    }
    const existingAppends: OriginalInkAppendRecord[] = await this.readAppends(
      store, operation.noteId, payload.ink);
    let expected: RebuiltOriginalInkGeometry;
    try {
      expected = rebuildOriginalInkGeometry(basePath, existingAppends, stroke);
    } catch (_error) {
      return { deferredReason: 'ADD_PATH_ELEMENTS_TRACKED_STATE_INVALID' };
    }
    if (!originalInkGeometryMatches(stroke, expected)) {
      return { deferredReason: 'ADD_PATH_ELEMENTS_STROKE_DIVERGED' };
    }
    if (target.revision >= Number.MAX_SAFE_INTEGER) {
      return { deferredReason: 'ADD_PATH_ELEMENTS_PAGE_REVISION_EXHAUSTED' };
    }

    const allAppends: OriginalInkAppendRecord[] = existingAppends.slice();
    allAppends.push({
      timestamp: operation.timestamp, siteId: operation.siteId, bytes: candidateBytes,
    });
    allAppends.sort(compareStoredAppend);
    let rebuilt: RebuiltOriginalInkGeometry;
    try {
      rebuilt = rebuildOriginalInkGeometry(basePath, allAppends, stroke);
    } catch (_error) {
      return { deferredReason: 'MALFORMED_ADD_PATH_ELEMENTS_PAYLOAD' };
    }
    const updatedStroke: StrokeElementData = {
      id: stroke.id,
      pathPoints: rebuilt.pathPoints,
      cubicSegments: rebuilt.cubicSegments,
      splatPoints: stroke.splatPoints,
      renderSpec: stroke.renderSpec,
      transform: stroke.transform,
      bounds: rebuilt.bounds,
      maskPath: stroke.maskPath,
      isFinished: stroke.isFinished,
    };
    await store.insert('original_ink_path_append', {
      'note_id': operation.noteId,
      'ink_timestamp': payload.ink.timestamp,
      'ink_site_id': payload.ink.siteId,
      'append_timestamp': operation.timestamp,
      'append_site_id': operation.siteId,
      'center_path_elements': candidateBytes,
    });
    await this.updateStroke(store, operation.noteId, target, updatedStroke);
    await this.advanceRevisionAndInvalidateSearch(store, operation.noteId, target);
    return { deferredReason: null };
  }

  private unsupportedStrokeReason(stroke: StrokeElementData,
    candidate: DecodedOriginalInkPathAppend): string | null {
    if (!isSupportedOriginalStoredStroke(stroke)) {
      return 'ADD_PATH_ELEMENTS_STROKE_DIVERGED';
    }
    if (stroke.renderSpec.isPencil || stroke.splatPoints.length > 0) {
      return 'ADD_PATH_ELEMENTS_PENCIL_UNSUPPORTED';
    }
    if (stroke.renderSpec.inkStyle < InkStyle.FIXED_WIDTH ||
      stroke.renderSpec.inkStyle > InkStyle.DOTS) {
      return 'ADD_PATH_ELEMENTS_STYLE_UNSUPPORTED';
    }
    if (stroke.renderSpec.inkStyle === InkStyle.VARIABLE_WIDTH && !candidate.attributed) {
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
       WHERE element.note_id = ? AND element.element_timestamp = ? AND element.element_site_id = ?`,
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

export function rebuildOriginalInkGeometry(baseBytes: Uint8Array,
  appends: OriginalInkAppendRecord[], stroke: StrokeElementData): RebuiltOriginalInkGeometry {
  const base: DecodedOriginalInkPath = decodeOriginalInkPath(baseBytes);
  const pathPoints: StrokePathPoint[] = base.pathPoints.slice();
  const cubicSegments: StrokeElementData['cubicSegments'] = base.cubicSegments.slice();
  let localBounds: Rect2D = base.localBounds;
  let current: Point2D = pathPoints[pathPoints.length - 1].position;
  const sorted: OriginalInkAppendRecord[] = appends.slice();
  sorted.sort(compareStoredAppend);
  for (const stored of sorted) {
    const append: DecodedOriginalInkPathAppend = decodeOriginalInkPathAppend(stored.bytes, current);
    if (stroke.renderSpec.inkStyle === InkStyle.VARIABLE_WIDTH && !append.attributed) {
      throw new Error('variable-width append has no attributes');
    }
    pathPoints.push(...append.pathPoints);
    cubicSegments.push(...append.cubicSegments);
    localBounds = unionOriginalInkBounds(localBounds, append.localBounds);
    current = append.endPoint;
  }
  return {
    pathPoints: pathPoints,
    cubicSegments: cubicSegments,
    bounds: transformedExpandedBounds(localBounds, stroke.renderSpec.brushWidth, stroke.transform),
  };
}

export function originalInkGeometryMatches(stroke: StrokeElementData,
  expected: RebuiltOriginalInkGeometry): boolean {
  return JSON.stringify(stroke.pathPoints) === JSON.stringify(expected.pathPoints) &&
    JSON.stringify(stroke.cubicSegments) === JSON.stringify(expected.cubicSegments) &&
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
