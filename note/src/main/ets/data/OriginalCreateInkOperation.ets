import { relationalStore } from '@kit.ArkData';
import { InkStyle, StrokeElementData } from '../core/model/StrokeTypes';
import { PageElementKind } from '../core/model/PageElementOrder';
import { encodeOperationId, OriginalSequenceIdentity,
  validateOriginalSequenceIdentity } from './OperationIdentity';
import { encodePersistedElement, PersistedElement } from './StrokePersistence';
import { SearchItemType } from './SearchItemType';
import {
  OriginalFlatBufferTableReader, readOriginalInlineFloat32, readOriginalPayloadTable,
} from './OriginalSyncedOperationFlatBuffer';
import { StoredSyncedOperation, SyncedOperationApplier,
  SyncedOperationApplyResult } from './SyncedOperationInbox';
import { compareUnsignedLongDecimal, validateUnsignedLongDecimal } from './UnsignedDecimal';
import {
  decodeOriginalInkPath, DecodedOriginalInkPath, originalInkTransform,
  OriginalInkPathDeferredError, transformedExpandedBounds,
} from './OriginalInkPathCodec';

export const ORIGINAL_CREATE_INK_PAYLOAD_TYPE: number = 15;
const MAX_ORIGINAL_INK_PATH_BYTES: number = 16 * 1024 * 1024;

export interface OriginalCreateInkPayload {
  page: OriginalSequenceIdentity;
  originX: number;
  originY: number;
  rotation: number;
  scaleX: number;
  scaleY: number;
  tool: number;
  style: number;
  color: number;
  width: number;
  centerPathBytes: Uint8Array | null;
  path: DecodedOriginalInkPath | null;
  zIndex: string;
  hasTapePattern: boolean;
  hasCustomPath: boolean;
  hasFillPath: boolean;
  hasFillColor: boolean;
  styleMapCount: number;
  hasAudioDuration: boolean;
  hasNibAngle: boolean;
  hasNibFlatness: boolean;
  inkEffects: string;
  inkEffectsTinted: boolean;
}

interface StoredTargetPage {
  pageId: string;
  table: string;
  revisionTable: string;
  revision: number;
  archived: boolean;
}

interface StoredZIndexRow {
  elementId: string;
  kind: number;
  timestamp: number;
  siteId: number;
  zIndex: string;
}

export function decodeOriginalCreateInk(bytes: Uint8Array,
  defaultZIndex: string): OriginalCreateInkPayload {
  return decodeOriginalCreateInkTable(
    readOriginalPayloadTable(bytes, ORIGINAL_CREATE_INK_PAYLOAD_TYPE), defaultZIndex);
}

export function decodeOriginalCreateInkTable(table: OriginalFlatBufferTableReader,
  defaultZIndex: string): OriginalCreateInkPayload {
  validateUnsignedLongDecimal(defaultZIndex);
  const rawPage: number[] | null = table.readInlineSequence(0);
  const origin: Uint8Array | null = table.readInlineBytes(1, 8);
  const color: Uint8Array | null = table.readInlineBytes(7, 4);
  if (rawPage === null || origin === null || color === null) {
    throw new Error('original create-ink is missing a required inline field');
  }
  const page: OriginalSequenceIdentity = {
    timestamp: rawPage[0], siteId: rawPage[1], index: rawPage[2],
  };
  validateOriginalSequenceIdentity(page);
  const scale: Uint8Array | null = table.readInlineBytes(3, 8);
  const centerPath: Uint8Array | null = table.readByteVector(
    9, false, MAX_ORIGINAL_INK_PATH_BYTES);
  const customPath: Uint8Array | null = table.readByteVector(
    10, false, MAX_ORIGINAL_INK_PATH_BYTES);
  const fillPath: Uint8Array | null = table.readByteVector(
    11, false, MAX_ORIGINAL_INK_PATH_BYTES);
  const zIndex: string = table.readUint64Decimal(14, defaultZIndex) as string;
  validateUnsignedLongDecimal(zIndex);
  return {
    page: page,
    originX: readOriginalInlineFloat32(origin, 0),
    originY: readOriginalInlineFloat32(origin, 4),
    rotation: table.readFloat32(2, 0),
    scaleX: scale === null ? 1 : readOriginalInlineFloat32(scale, 0),
    scaleY: scale === null ? 1 : readOriginalInlineFloat32(scale, 4),
    tool: normalizeOriginalEnum(table.readUint8(4, 0), 7),
    style: normalizeOriginalEnum(table.readUint8(5, 0), 3),
    hasTapePattern: table.hasField(6),
    color: ((color[3] << 24) | (color[0] << 16) | (color[1] << 8) | color[2]),
    width: table.readFloat32(8, 0),
    centerPathBytes: centerPath,
    path: centerPath === null ? null : decodeOriginalInkPath(centerPath),
    zIndex: zIndex,
    hasCustomPath: customPath !== null,
    hasFillPath: fillPath !== null,
    hasFillColor: table.hasField(12),
    styleMapCount: table.readInlineVectorCount(13, 20, 65535),
    hasAudioDuration: table.hasField(15),
    hasNibAngle: table.hasField(16),
    hasNibFlatness: table.hasField(17),
    inkEffects: table.readUint64Decimal(18, '0') as string,
    inkEffectsTinted: table.readUint8(19, 1) !== 0,
  };
}

export class OriginalCreateInkOperationApplier implements SyncedOperationApplier {
  supports(payloadType: number): boolean {
    return payloadType === ORIGINAL_CREATE_INK_PAYLOAD_TYPE;
  }

  async apply(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation): Promise<SyncedOperationApplyResult> {
    let payload: OriginalCreateInkPayload;
    try {
      payload = decodeOriginalCreateInk(operation.rawOperation, operation.clientTime);
    } catch (_error) {
      if (_error instanceof OriginalInkPathDeferredError) {
        return { deferredReason: _error.deferredReason };
      }
      return { deferredReason: 'MALFORMED_CREATE_INK_PAYLOAD' };
    }
    const unsupported: string | null = this.unsupportedReason(payload);
    if (unsupported !== null) {
      return { deferredReason: unsupported };
    }
    const target: StoredTargetPage | null = await this.readTargetPage(store, operation, payload.page);
    if (target === null) {
      return { deferredReason: 'CREATE_INK_PAGE_MISSING_OR_UNBOUND' };
    }
    if (await this.originalElementExists(store, operation)) {
      throw new Error('original create-ink operation was applied twice');
    }
    const existingRows: StoredZIndexRow[] | null = await this.readCompleteOriginalOrder(
      store, operation.noteId, payload.page, target);
    if (existingRows === null) {
      return { deferredReason: 'CREATE_INK_ELEMENT_ORDER_DIVERGED' };
    }
    if (target.revision >= Number.MAX_SAFE_INTEGER) {
      return { deferredReason: 'CREATE_INK_PAGE_REVISION_EXHAUSTED' };
    }

    const stroke: StrokeElementData = this.buildStroke(operation, payload);
    await store.insert('original_element_z_index', {
      'note_id': operation.noteId,
      'element_timestamp': operation.timestamp,
      'element_site_id': operation.siteId,
      'page_timestamp': payload.page.timestamp,
      'page_site_id': payload.page.siteId,
      'page_index': payload.page.index,
      'kind': PageElementKind.STROKE,
      'z_index': payload.zIndex,
    });
    await store.insert('original_ink_state', {
      'note_id': operation.noteId,
      'ink_timestamp': operation.timestamp,
      'ink_site_id': operation.siteId,
      'base_center_path': payload.centerPathBytes as Uint8Array,
      'center_path_winner_timestamp': operation.timestamp,
      'center_path_winner_site_id': operation.siteId,
      'style_value': payload.style,
      'style_winner_timestamp': operation.timestamp,
      'style_winner_site_id': operation.siteId,
      'color_value': payload.color,
      'color_winner_timestamp': operation.timestamp,
      'color_winner_site_id': operation.siteId,
      'width_value': payload.width,
      'width_winner_timestamp': operation.timestamp,
      'width_winner_site_id': operation.siteId,
    });
    existingRows.push({
      elementId: stroke.id, kind: PageElementKind.STROKE,
      timestamp: operation.timestamp, siteId: operation.siteId, zIndex: payload.zIndex,
    });
    existingRows.sort(compareStoredZIndexRows);
    await this.materializeOrder(store, operation.noteId, payload.page, target,
      existingRows, stroke, target.revision + 1);
    return { deferredReason: null };
  }

  private unsupportedReason(payload: OriginalCreateInkPayload): string | null {
    if (payload.tool === 1) {
      return 'CREATE_INK_PENCIL_SPLATS_UNSUPPORTED';
    }
    if (payload.tool !== 0 && payload.tool !== 2) {
      return payload.tool === 3 ? 'CREATE_INK_TAPE_UNSUPPORTED' : 'CREATE_INK_TOOL_UNSUPPORTED';
    }
    if (payload.hasTapePattern) {
      return 'CREATE_INK_TAPE_PATTERN_UNSUPPORTED';
    }
    if (payload.style < 0 || payload.style > 3) {
      return 'CREATE_INK_STYLE_UNSUPPORTED';
    }
    if (!Number.isFinite(payload.originX) || !Number.isFinite(payload.originY) ||
      !Number.isFinite(payload.rotation) || !Number.isFinite(payload.scaleX) ||
      !Number.isFinite(payload.scaleY)) {
      return 'CREATE_INK_TRANSFORM_UNSUPPORTED';
    }
    if (!Number.isFinite(payload.width) || payload.width < 0) {
      return 'CREATE_INK_WIDTH_UNSUPPORTED';
    }
    if (payload.path === null) {
      return 'CREATE_INK_CENTER_PATH_MISSING';
    }
    if (payload.style === 0 && !payload.path.attributed) {
      return 'CREATE_INK_VARIABLE_PATH_ATTRIBUTES_MISSING';
    }
    if (payload.hasCustomPath || payload.hasFillPath || payload.hasFillColor ||
      payload.styleMapCount > 0) {
      return 'CREATE_INK_AUXILIARY_PATH_UNSUPPORTED';
    }
    if (payload.hasAudioDuration) {
      return 'CREATE_INK_AUDIO_DURATION_UNSUPPORTED';
    }
    if (payload.hasNibAngle || payload.hasNibFlatness) {
      return 'CREATE_INK_NIB_ATTRIBUTES_UNSUPPORTED';
    }
    if (payload.inkEffects !== '0') {
      return 'CREATE_INK_EFFECTS_UNSUPPORTED';
    }
    if (!payload.inkEffectsTinted) {
      return 'CREATE_INK_INVALID_EFFECT_TINT';
    }
    return null;
  }

  private buildStroke(operation: StoredSyncedOperation,
    payload: OriginalCreateInkPayload): StrokeElementData {
    const path: DecodedOriginalInkPath = payload.path as DecodedOriginalInkPath;
    const transform = originalInkTransform(payload.originX, payload.originY,
      payload.rotation, payload.scaleX, payload.scaleY);
    const style: InkStyle = payload.style === 0 ? InkStyle.VARIABLE_WIDTH :
      payload.style === 1 ? InkStyle.FIXED_WIDTH :
        payload.style === 2 ? InkStyle.DASH : InkStyle.DOTS;
    return {
      id: encodeOperationId(operation),
      pathPoints: path.pathPoints,
      cubicSegments: path.cubicSegments,
      splatPoints: [],
      renderSpec: {
        color: payload.color, brushWidth: payload.width, inkStyle: style,
        isHighlighter: payload.tool === 2, isPencil: false,
      },
      transform: transform,
      bounds: transformedExpandedBounds(path.localBounds, payload.width, transform),
      maskPath: [],
      isFinished: true,
    };
  }

  private async readTargetPage(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation, page: OriginalSequenceIdentity): Promise<StoredTargetPage | null> {
    const identity = await store.querySql(
      `SELECT page_id, visible FROM original_page_identity WHERE note_id = ?
       AND seq_timestamp = ? AND seq_site_id = ? AND seq_index = ?`,
      [operation.noteId, page.timestamp, page.siteId, page.index]);
    let pageId: string | null = null;
    try {
      if (!identity.goToFirstRow() || identity.getLong(identity.getColumnIndex('visible')) !== 1) {
        return null;
      }
      const pageIdColumn: number = identity.getColumnIndex('page_id');
      pageId = identity.isColumnNull(pageIdColumn) ? null : identity.getString(pageIdColumn);
    } finally {
      identity.close();
    }
    if (pageId === null) {
      return null;
    }
    const liveRevision: number | null = await readSingleRevision(store,
      'SELECT content_revision FROM page_info WHERE note_id = ? AND page_id = ?',
      [operation.noteId, pageId]);
    const archivedRevision: number | null = await readSingleRevision(store,
      `SELECT content_revision FROM original_deleted_page WHERE note_id = ?
       AND page_timestamp = ? AND page_site_id = ? AND page_index = ?`,
      [operation.noteId, page.timestamp, page.siteId, page.index]);
    if ((liveRevision === null) === (archivedRevision === null)) {
      return null;
    }
    return liveRevision !== null ? {
      pageId: pageId, table: 'page_element_snapshot', revisionTable: 'page_info',
      revision: liveRevision, archived: false,
    } : {
      pageId: pageId, table: 'original_deleted_page_element',
      revisionTable: 'original_deleted_page', revision: archivedRevision as number, archived: true,
    };
  }

  private async originalElementExists(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation): Promise<boolean> {
    const rows = await store.querySql(
      `SELECT 1 FROM original_element_z_index WHERE note_id = ?
       AND element_timestamp = ? AND element_site_id = ? LIMIT 1`,
      [operation.noteId, operation.timestamp, operation.siteId]);
    try {
      return rows.goToFirstRow();
    } finally {
      rows.close();
    }
  }

  private async readCompleteOriginalOrder(store: relationalStore.RdbStore, noteId: string,
    page: OriginalSequenceIdentity, target: StoredTargetPage): Promise<StoredZIndexRow[] | null> {
    const tracked = await store.querySql(
      `SELECT element_timestamp, element_site_id, kind, z_index
       FROM original_element_z_index WHERE note_id = ? AND page_timestamp = ?
       AND page_site_id = ? AND page_index = ?`,
      [noteId, page.timestamp, page.siteId, page.index]);
    const trackedRows: StoredZIndexRow[] = [];
    const trackedKeys: Set<string> = new Set<string>();
    try {
      while (tracked.goToNextRow()) {
        const timestamp: number = tracked.getLong(tracked.getColumnIndex('element_timestamp'));
        const siteId: number = tracked.getLong(tracked.getColumnIndex('element_site_id'));
        const kind: number = tracked.getLong(tracked.getColumnIndex('kind'));
        const elementId: string = encodeOperationId({ timestamp: timestamp, siteId: siteId });
        trackedRows.push({ elementId: elementId, kind: kind, timestamp: timestamp,
          siteId: siteId, zIndex: tracked.getString(tracked.getColumnIndex('z_index')) });
        trackedKeys.add(`${kind}:${elementId}`);
      }
    } finally {
      tracked.close();
    }
    const existing = target.archived ? await store.querySql(
      `SELECT element_id, kind FROM original_deleted_page_element WHERE note_id = ?
       AND page_timestamp = ? AND page_site_id = ? AND page_index = ?`,
      [noteId, page.timestamp, page.siteId, page.index]) : await store.querySql(
      'SELECT element_id, kind FROM page_element_snapshot WHERE note_id = ? AND page_id = ?',
      [noteId, target.pageId]);
    let count: number = 0;
    try {
      while (existing.goToNextRow()) {
        const key: string = `${existing.getLong(existing.getColumnIndex('kind'))}:` +
          existing.getString(existing.getColumnIndex('element_id'));
        if (!trackedKeys.has(key)) {
          return null;
        }
        count++;
      }
    } finally {
      existing.close();
    }
    return count === trackedRows.length ? trackedRows : null;
  }

  private async materializeOrder(store: relationalStore.RdbStore, noteId: string,
    page: OriginalSequenceIdentity, target: StoredTargetPage, rows: StoredZIndexRow[],
    stroke: StrokeElementData, revision: number): Promise<void> {
    for (let index: number = 0; index < rows.length; index++) {
      const row: StoredZIndexRow = rows[index];
      if (row.elementId === stroke.id && row.kind === PageElementKind.STROKE) {
        const persisted: PersistedElement = { kind: 'stroke', data: stroke };
        const values: relationalStore.ValuesBucket = {
          'note_id': noteId, 'element_id': stroke.id, 'kind': PageElementKind.STROKE,
          'payload': encodePersistedElement(persisted), 'revision': revision, 'element_order': index,
        };
        if (target.archived) {
          values['page_timestamp'] = page.timestamp;
          values['page_site_id'] = page.siteId;
          values['page_index'] = page.index;
        } else {
          values['page_id'] = target.pageId;
        }
        await store.insert(target.table, values);
      } else {
        const predicates = new relationalStore.RdbPredicates(target.table);
        predicates.equalTo('note_id', noteId);
        if (target.archived) {
          predicates.equalTo('page_timestamp', page.timestamp);
          predicates.equalTo('page_site_id', page.siteId);
          predicates.equalTo('page_index', page.index);
        } else {
          predicates.equalTo('page_id', target.pageId);
        }
        predicates.equalTo('element_id', row.elementId);
        predicates.equalTo('kind', row.kind);
        const updated: number = await store.update({ 'element_order': index }, predicates);
        if (updated !== 1) {
          throw new Error('original element order materialization lost an element');
        }
      }
    }
    if (target.archived) {
      const predicates = new relationalStore.RdbPredicates('original_deleted_page');
      predicates.equalTo('note_id', noteId);
      predicates.equalTo('page_timestamp', page.timestamp);
      predicates.equalTo('page_site_id', page.siteId);
      predicates.equalTo('page_index', page.index);
      predicates.equalTo('content_revision', target.revision);
      const updated: number = await store.update({ 'content_revision': revision,
        'indexed_revision': null }, predicates);
      if (updated !== 1) {
        throw new Error('original archived page revision changed concurrently');
      }
      await store.executeSql(
        `DELETE FROM original_deleted_page_search WHERE note_id = ? AND page_timestamp = ?
         AND page_site_id = ? AND page_index = ? AND type = ?`,
        [noteId, page.timestamp, page.siteId, page.index, SearchItemType.INK]);
    } else {
      const predicates = new relationalStore.RdbPredicates('page_info');
      predicates.equalTo('note_id', noteId);
      predicates.equalTo('page_id', target.pageId);
      predicates.equalTo('content_revision', target.revision);
      const updated: number = await store.update({ 'content_revision': revision }, predicates);
      if (updated !== 1) {
        throw new Error('original live page revision changed concurrently');
      }
      await store.executeSql('DELETE FROM search_page_state WHERE note_id = ? AND page_id = ?',
        [noteId, target.pageId]);
      await store.executeSql(
        'DELETE FROM search_item WHERE note_id = ? AND page_id = ? AND type = ?',
        [noteId, target.pageId, SearchItemType.INK]);
    }
  }
}

function normalizeOriginalEnum(value: number, maximum: number): number {
  // FlatBuffers' generated u16/t16 accessors return their first enum value for an unknown byte.
  return value >= 0 && value <= maximum ? value : 0;
}

function compareStoredZIndexRows(left: StoredZIndexRow, right: StoredZIndexRow): number {
  // vnd.c compares z-index as uint64, then qo5 identity as unsigned timestamp/site.
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
