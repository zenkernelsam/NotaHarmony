import { relationalStore } from '@kit.ArkData';
import { TransformMatrix } from '../core/model/GeometryTypes';
import { PageElementKind } from '../core/model/PageElementOrder';
import { InkStyle, RenderSpec, StrokeElementData } from '../core/model/StrokeTypes';
import {
  compareOperationIdentity, encodeOperationId, OperationIdentity, OriginalSequenceIdentity,
  validateOperationIdentity, validateOriginalSequenceIdentity,
} from './OperationIdentity';
import {
  isSupportedOriginalStoredStroke, OriginalInkAppendRecord,
  originalInkGeometryMatches, rebuildOriginalInkGeometry, RebuiltOriginalInkGeometry,
} from './OriginalAddPathElementsOperation';
import {
  decodeOriginalInkPathReplacement, originalInkTransform, OriginalInkPathDeferredError,
} from './OriginalInkPathCodec';
import { decodeOriginalCreateInk, OriginalCreateInkPayload } from './OriginalCreateInkOperation';
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

export const ORIGINAL_MODIFY_INK_PAYLOAD_TYPE: number = 17;
const MAX_ORIGINAL_MODIFY_INK_COUNT: number = 10000;
const MAX_ORIGINAL_INK_PATH_BYTES: number = 16 * 1024 * 1024;

export interface OriginalModifyInkPayload {
  inks: OperationIdentity[];
  rotation: NullableRegisterUpdate<number>;
  scale: NullableRegisterUpdate<OriginalInkScale>;
  style: number | null;
  color: number | null;
  width: number | null;
  centerPath: Uint8Array | null;
  hasUnsupportedFields: boolean;
}

export interface OriginalInkScale {
  x: number;
  y: number;
}

export interface NullableRegisterUpdate<T> {
  present: boolean;
  value: T | null;
}

interface StoredRegister<T> {
  value: T | null;
  winner: OperationIdentity | null;
}

interface OriginalInkBaseTransform {
  originX: number;
  originY: number;
  rotation: number;
  scaleX: number;
  scaleY: number;
}

interface StoredInkState {
  basePath: Uint8Array;
  centerPathWinner: OperationIdentity | null;
  style: StoredRegister<number>;
  color: StoredRegister<number>;
  width: StoredRegister<number>;
  baseTransform: OriginalInkBaseTransform | null;
  rotation: StoredRegister<number>;
  scale: StoredRegister<OriginalInkScale>;
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

interface PlannedReplacement {
  target: StoredInkTarget;
  state: StoredInkState;
  stroke: StrokeElementData;
  geometry: RebuiltOriginalInkGeometry;
  replaceCenterPath: boolean;
  replaceStyle: boolean;
  replaceColor: boolean;
  replaceWidth: boolean;
  replaceRotation: boolean;
  replaceScale: boolean;
  style: number;
  color: number;
  width: number;
  transform: TransformMatrix;
  baseTransform: OriginalInkBaseTransform | null;
  rotationValue: number | null;
  scaleValue: OriginalInkScale | null;
}

export function decodeOriginalModifyInk(bytes: Uint8Array): OriginalModifyInkPayload {
  return decodeOriginalModifyInkTable(
    readOriginalPayloadTable(bytes, ORIGINAL_MODIFY_INK_PAYLOAD_TYPE));
}

export function decodeOriginalModifyInkTable(table: OriginalFlatBufferTableReader):
  OriginalModifyInkPayload {
  const rawInks: number[][] = table.readInlineOperationIdentityVector(
    0, MAX_ORIGINAL_MODIFY_INK_COUNT);
  if (rawInks.length === 0) {
    throw new Error('original modify-ink contains no target inks');
  }
  const inks: OperationIdentity[] = [];
  const identities: Set<string> = new Set<string>();
  for (const raw of rawInks) {
    const ink: OperationIdentity = { timestamp: raw[0], siteId: raw[1] };
    validateOperationIdentity(ink);
    const identity: string = encodeOperationId(ink);
    if (identities.has(identity)) {
      throw new Error('original modify-ink repeats a target ink');
    }
    identities.add(identity);
    inks.push(ink);
  }
  let hasUnsupportedFields: boolean = false;
  for (let field: number = 1; field <= 18; field++) {
    if (field !== 3 && field !== 4 && field !== 5 && field !== 6 && field !== 7 &&
      field !== 8 && table.hasField(field)) {
      hasUnsupportedFields = true;
    }
  }
  const rotationSetter: OriginalFlatBufferTableReader | null = table.readTable(3);
  const scaleSetter: OriginalFlatBufferTableReader | null = table.readTable(4);
  const scaleBytes: Uint8Array | null = scaleSetter === null ? null :
    scaleSetter.readInlineBytes(0, 8);
  const colorBytes: Uint8Array | null = table.readInlineBytes(6, 4);
  const rawStyle: number = table.readUint8(5, 0);
  return {
    inks: inks,
    rotation: {
      present: rotationSetter !== null,
      value: rotationSetter === null || !rotationSetter.hasField(0) ? null :
        rotationSetter.readFloat32(0, 0),
    },
    scale: {
      present: scaleSetter !== null,
      value: scaleBytes === null ? null : {
        x: readInlineFloat32(scaleBytes, 0), y: readInlineFloat32(scaleBytes, 4),
      },
    },
    style: table.hasField(5) ? normalizeOriginalInkStyle(rawStyle) : null,
    color: colorBytes === null ? null : originalColorToArgb(colorBytes),
    width: table.hasField(7) ? table.readFloat32(7, 0) : null,
    centerPath: table.readByteVector(8, false, MAX_ORIGINAL_INK_PATH_BYTES),
    hasUnsupportedFields: hasUnsupportedFields,
  };
}

export class OriginalModifyInkOperationApplier implements SyncedOperationApplier {
  supports(payloadType: number): boolean {
    return payloadType === ORIGINAL_MODIFY_INK_PAYLOAD_TYPE;
  }

  async apply(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation): Promise<SyncedOperationApplyResult> {
    let payload: OriginalModifyInkPayload;
    try {
      payload = decodeOriginalModifyInk(operation.rawOperation);
    } catch (_error) {
      return { deferredReason: 'MALFORMED_MODIFY_INK_PAYLOAD' };
    }
    if (payload.hasUnsupportedFields) {
      return { deferredReason: 'MODIFY_INK_ADDITIONAL_FIELDS_UNSUPPORTED' };
    }
    if (!payload.rotation.present && !payload.scale.present && payload.style === null &&
      payload.color === null && payload.width === null && payload.centerPath === null) {
      return { deferredReason: null };
    }
    if ((payload.rotation.value !== null && !Number.isFinite(payload.rotation.value)) ||
      (payload.scale.value !== null && (!Number.isFinite(payload.scale.value.x) ||
        !Number.isFinite(payload.scale.value.y)))) {
      return { deferredReason: 'MODIFY_INK_TRANSFORM_UNSUPPORTED' };
    }
    if (payload.width !== null && (!Number.isFinite(payload.width) || payload.width < 0)) {
      return { deferredReason: 'MODIFY_INK_WIDTH_UNSUPPORTED' };
    }
    if (payload.centerPath !== null) {
      try {
        decodeOriginalInkPathReplacement(payload.centerPath);
      } catch (_error) {
        if (_error instanceof OriginalInkPathDeferredError) {
          return { deferredReason: _error.deferredReason };
        }
        return { deferredReason: 'MALFORMED_MODIFY_INK_PAYLOAD' };
      }
    }

    const planned: PlannedReplacement[] = [];
    const affectedPages: Map<string, StoredInkTarget> = new Map<string, StoredInkTarget>();
    for (const ink of payload.inks) {
      const target: StoredInkTarget | null = await this.readTarget(store, operation.noteId, ink);
      if (target === null) {
        return { deferredReason: 'MODIFY_INK_TARGET_MISSING_OR_UNBOUND' };
      }
      const state: StoredInkState | null = await this.readState(store, operation.noteId, ink);
      if (state === null) {
        return { deferredReason: 'MODIFY_INK_BASE_STATE_MISSING' };
      }
      const replaceCenterPath: boolean = payload.centerPath !== null &&
        registerAccepts(operation, state.centerPathWinner);
      const replaceStyle: boolean = payload.style !== null &&
        registerAccepts(operation, state.style.winner);
      const replaceColor: boolean = payload.color !== null &&
        registerAccepts(operation, state.color.winner);
      const replaceWidth: boolean = payload.width !== null &&
        registerAccepts(operation, state.width.winner);
      const replaceRotation: boolean = payload.rotation.present &&
        registerAccepts(operation, state.rotation.winner);
      const replaceScale: boolean = payload.scale.present &&
        registerAccepts(operation, state.scale.winner);
      if (!replaceCenterPath && !replaceStyle && !replaceColor && !replaceWidth &&
        !replaceRotation && !replaceScale) {
        continue;
      }
      const stroke: StrokeElementData | null = await this.readStroke(store, operation.noteId, target);
      if (stroke === null || !isSupportedOriginalStoredStroke(stroke)) {
        return { deferredReason: 'MODIFY_INK_STROKE_DIVERGED' };
      }
      if (stroke.renderSpec.isPencil || stroke.splatPoints.length > 0) {
        return { deferredReason: 'MODIFY_INK_PENCIL_UNSUPPORTED' };
      }
      let initial: OriginalCreateInkPayload | null = null;
      if ((replaceStyle && state.style.value === null) ||
        (replaceColor && state.color.value === null) ||
        (replaceWidth && state.width.value === null) ||
        ((replaceRotation || replaceScale) && state.baseTransform === null)) {
        initial = await this.readInitialRenderState(store, operation.noteId, ink);
        if (initial === null) {
          return { deferredReason: 'MODIFY_INK_RENDER_STATE_MISSING' };
        }
      }
      const oldStyle: number = state.style.value !== null ? state.style.value :
        initial !== null ? initial.style : inkStyleToOriginalStyle(stroke.renderSpec.inkStyle);
      const oldColor: number = state.color.value !== null ? state.color.value :
        initial !== null ? initial.color : stroke.renderSpec.color;
      const oldWidth: number = state.width.value !== null ? state.width.value :
        initial !== null ? initial.width : stroke.renderSpec.brushWidth;
      if ((replaceStyle && stroke.renderSpec.inkStyle !== originalStyleToInkStyle(oldStyle)) ||
        (replaceColor && stroke.renderSpec.color !== oldColor) ||
        (replaceWidth && stroke.renderSpec.brushWidth !== oldWidth)) {
        return { deferredReason: 'MODIFY_INK_RENDER_STATE_DIVERGED' };
      }
      const style: number = replaceStyle ? payload.style as number :
        inkStyleToOriginalStyle(stroke.renderSpec.inkStyle);
      const color: number = replaceColor ? payload.color as number : stroke.renderSpec.color;
      const width: number = replaceWidth ? payload.width as number : stroke.renderSpec.brushWidth;
      let transform: TransformMatrix = stroke.transform;
      let baseTransform: OriginalInkBaseTransform | null = null;
      if (replaceRotation || replaceScale) {
        baseTransform = state.baseTransform !== null ? state.baseTransform :
          createBaseTransform(initial as OriginalCreateInkPayload);
        const oldRotation: number = state.rotation.winner !== null &&
          state.rotation.value !== null ? state.rotation.value : baseTransform.rotation;
        const oldScale: OriginalInkScale = state.scale.winner !== null &&
          state.scale.value !== null ? state.scale.value :
          { x: baseTransform.scaleX, y: baseTransform.scaleY };
        const expectedTransform: TransformMatrix = originalInkTransform(
          baseTransform.originX, baseTransform.originY, oldRotation, oldScale.x, oldScale.y);
        if (!transformMatricesEqual(stroke.transform, expectedTransform)) {
          return { deferredReason: 'MODIFY_INK_TRANSFORM_STATE_DIVERGED' };
        }
        const nextRotation: number = replaceRotation ?
          (payload.rotation.value === null ? baseTransform.rotation : payload.rotation.value) :
          oldRotation;
        const nextScale: OriginalInkScale = replaceScale ?
          (payload.scale.value === null ? { x: baseTransform.scaleX, y: baseTransform.scaleY } :
            payload.scale.value) : oldScale;
        transform = originalInkTransform(baseTransform.originX, baseTransform.originY,
          nextRotation, nextScale.x, nextScale.y);
      }
      const renderSpec: RenderSpec = {
        color: color, brushWidth: width, inkStyle: originalStyleToInkStyle(style),
        isHighlighter: stroke.renderSpec.isHighlighter, isPencil: stroke.renderSpec.isPencil,
      };
      const candidateStroke: StrokeElementData = copyStroke(stroke, renderSpec, transform);
      const appends: OriginalInkAppendRecord[] = await this.readAppends(
        store, operation.noteId, ink);
      let expected: RebuiltOriginalInkGeometry;
      let replacement: RebuiltOriginalInkGeometry;
      try {
        expected = rebuildOriginalInkGeometry(state.basePath, appends, stroke);
        replacement = rebuildOriginalInkGeometry(
          replaceCenterPath ? payload.centerPath as Uint8Array : state.basePath,
          appends, candidateStroke);
      } catch (_error) {
        return { deferredReason: 'MODIFY_INK_TRACKED_STATE_INVALID' };
      }
      if (!originalInkGeometryMatches(stroke, expected)) {
        return { deferredReason: 'MODIFY_INK_STROKE_DIVERGED' };
      }
      if (style === 0 && !replacement.attributed) {
        return { deferredReason: 'MODIFY_INK_VARIABLE_PATH_ATTRIBUTES_MISSING' };
      }
      if (target.revision >= Number.MAX_SAFE_INTEGER) {
        return { deferredReason: 'MODIFY_INK_PAGE_REVISION_EXHAUSTED' };
      }
      planned.push({
        target: target, state: state, stroke: stroke, geometry: replacement,
        replaceCenterPath: replaceCenterPath, replaceStyle: replaceStyle,
        replaceColor: replaceColor, replaceWidth: replaceWidth,
        replaceRotation: replaceRotation, replaceScale: replaceScale,
        style: style, color: color, width: width, transform: transform,
        baseTransform: state.baseTransform === null ? baseTransform : null,
        rotationValue: replaceRotation ? payload.rotation.value : state.rotation.value,
        scaleValue: replaceScale ? payload.scale.value : state.scale.value,
      });
      affectedPages.set(pageKey(target), target);
    }

    for (const replacement of planned) {
      await this.updateState(store, operation.noteId, replacement.target.ink,
        replacement, operation, payload.centerPath);
      await this.updateStroke(store, operation.noteId, replacement);
    }
    for (const target of affectedPages.values()) {
      await this.advanceRevisionAndInvalidateSearch(store, operation.noteId, target);
    }
    return { deferredReason: null };
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

  private async readState(store: relationalStore.RdbStore, noteId: string,
    ink: OperationIdentity): Promise<StoredInkState | null> {
    const rows = await store.querySql(
      `SELECT base_center_path, center_path_winner_timestamp, center_path_winner_site_id,
              center_path_winner_present,
              style_value, style_winner_timestamp, style_winner_site_id,
              style_winner_present,
              color_value, color_winner_timestamp, color_winner_site_id,
              color_winner_present,
              width_value, width_winner_timestamp, width_winner_site_id,
              width_winner_present,
              create_origin_x, create_origin_y, create_rotation, create_scale_x, create_scale_y,
              rotation_value, rotation_winner_timestamp, rotation_winner_site_id,
              rotation_winner_present,
              scale_x_value, scale_y_value, scale_winner_timestamp, scale_winner_site_id,
              scale_winner_present
       FROM original_ink_state WHERE note_id = ? AND ink_timestamp = ? AND ink_site_id = ?`,
      [noteId, ink.timestamp, ink.siteId]);
    try {
      if (!rows.goToFirstRow()) {
        return null;
      }
      const centerPathWinner: OperationIdentity | null = readOptionalWinner(rows, 'center_path');
      const styleWinner: OperationIdentity | null = readOptionalWinner(rows, 'style');
      const colorWinner: OperationIdentity | null = readOptionalWinner(rows, 'color');
      const widthWinner: OperationIdentity | null = readOptionalWinner(rows, 'width');
      const rotationWinner: OperationIdentity | null = readOptionalWinner(rows, 'rotation');
      const scaleWinner: OperationIdentity | null = readOptionalWinner(rows, 'scale');
      const widthColumn: number = rows.getColumnIndex('width_value');
      const width: number | null = rows.isColumnNull(widthColumn) ? null : rows.getDouble(widthColumn);
      if (width !== null && !Number.isFinite(width)) {
        throw new Error('original modify-ink has an invalid stored width');
      }
      const baseTransform: OriginalInkBaseTransform | null = readBaseTransform(rows);
      const rotation: number | null = readNullableDouble(rows, 'rotation_value');
      const scaleX: number | null = readNullableDouble(rows, 'scale_x_value');
      const scaleY: number | null = readNullableDouble(rows, 'scale_y_value');
      if ((scaleX === null) !== (scaleY === null)) {
        throw new Error('original modify-ink has a partial stored scale');
      }
      if ((rotationWinner === null && rotation !== null) ||
        (scaleWinner === null && scaleX !== null)) {
        throw new Error('original modify-ink has an override without a winner');
      }
      return {
        basePath: rows.getBlob(rows.getColumnIndex('base_center_path')),
        centerPathWinner: centerPathWinner,
        style: { value: readNullableLong(rows, 'style_value'), winner: styleWinner },
        color: { value: readNullableLong(rows, 'color_value'), winner: colorWinner },
        width: { value: width, winner: widthWinner },
        baseTransform: baseTransform,
        rotation: { value: rotation, winner: rotationWinner },
        scale: {
          value: scaleX === null ? null : { x: scaleX, y: scaleY as number },
          winner: scaleWinner,
        },
      };
    } finally {
      rows.close();
    }
  }

  private async readInitialRenderState(store: relationalStore.RdbStore, noteId: string,
    ink: OperationIdentity): Promise<OriginalCreateInkPayload | null> {
    const rows = await store.querySql(
      `SELECT raw_operation, client_time FROM synced_operation_inbox WHERE note_id = ?
       AND op_timestamp = ? AND editor_site_id = ? AND payload_type = 15`,
      [noteId, ink.timestamp, ink.siteId]);
    try {
      if (!rows.goToFirstRow()) {
        return null;
      }
      return decodeOriginalCreateInk(rows.getBlob(rows.getColumnIndex('raw_operation')),
        rows.getString(rows.getColumnIndex('client_time')));
    } catch (_error) {
      return null;
    } finally {
      rows.close();
    }
  }

  private async readAppends(store: relationalStore.RdbStore, noteId: string,
    ink: OperationIdentity): Promise<OriginalInkAppendRecord[]> {
    const rows = await store.querySql(
      `SELECT append_timestamp, append_site_id, center_path_elements
       FROM original_ink_path_append WHERE note_id = ? AND ink_timestamp = ? AND ink_site_id = ?`,
      [noteId, ink.timestamp, ink.siteId]);
    const result: OriginalInkAppendRecord[] = [];
    try {
      while (rows.goToNextRow()) {
        const append: OriginalInkAppendRecord = {
          timestamp: rows.getLong(rows.getColumnIndex('append_timestamp')),
          siteId: rows.getLong(rows.getColumnIndex('append_site_id')),
          bytes: rows.getBlob(rows.getColumnIndex('center_path_elements')),
        };
        validateOperationIdentity(append);
        result.push(append);
      }
    } finally {
      rows.close();
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

  private async updateState(store: relationalStore.RdbStore, noteId: string,
    ink: OperationIdentity, replacement: PlannedReplacement, winner: OperationIdentity,
    basePath: Uint8Array | null): Promise<void> {
    const predicates = new relationalStore.RdbPredicates('original_ink_state');
    predicates.equalTo('note_id', noteId);
    predicates.equalTo('ink_timestamp', ink.timestamp);
    predicates.equalTo('ink_site_id', ink.siteId);
    const values: relationalStore.ValuesBucket = {};
    if (replacement.replaceCenterPath) {
      addWinnerPredicates(predicates, 'center_path', replacement.state.centerPathWinner);
      values['base_center_path'] = basePath as Uint8Array;
      values['center_path_winner_timestamp'] = winner.timestamp;
      values['center_path_winner_site_id'] = winner.siteId;
      values['center_path_winner_present'] = 1;
    }
    if (replacement.replaceStyle) {
      addWinnerPredicates(predicates, 'style', replacement.state.style.winner);
      values['style_value'] = replacement.style;
      values['style_winner_timestamp'] = winner.timestamp;
      values['style_winner_site_id'] = winner.siteId;
      values['style_winner_present'] = 1;
    }
    if (replacement.replaceColor) {
      addWinnerPredicates(predicates, 'color', replacement.state.color.winner);
      values['color_value'] = replacement.color;
      values['color_winner_timestamp'] = winner.timestamp;
      values['color_winner_site_id'] = winner.siteId;
      values['color_winner_present'] = 1;
    }
    if (replacement.replaceWidth) {
      addWinnerPredicates(predicates, 'width', replacement.state.width.winner);
      values['width_value'] = replacement.width;
      values['width_winner_timestamp'] = winner.timestamp;
      values['width_winner_site_id'] = winner.siteId;
      values['width_winner_present'] = 1;
    }
    if (replacement.baseTransform !== null) {
      values['create_origin_x'] = replacement.baseTransform.originX;
      values['create_origin_y'] = replacement.baseTransform.originY;
      values['create_rotation'] = replacement.baseTransform.rotation;
      values['create_scale_x'] = replacement.baseTransform.scaleX;
      values['create_scale_y'] = replacement.baseTransform.scaleY;
    }
    if (replacement.replaceRotation) {
      addWinnerPredicates(predicates, 'rotation', replacement.state.rotation.winner);
      values['rotation_value'] = replacement.rotationValue;
      values['rotation_winner_timestamp'] = winner.timestamp;
      values['rotation_winner_site_id'] = winner.siteId;
      values['rotation_winner_present'] = 1;
    }
    if (replacement.replaceScale) {
      addWinnerPredicates(predicates, 'scale', replacement.state.scale.winner);
      values['scale_x_value'] = replacement.scaleValue === null ? null : replacement.scaleValue.x;
      values['scale_y_value'] = replacement.scaleValue === null ? null : replacement.scaleValue.y;
      values['scale_winner_timestamp'] = winner.timestamp;
      values['scale_winner_site_id'] = winner.siteId;
      values['scale_winner_present'] = 1;
    }
    const updated: number = await store.update(values, predicates);
    if (updated !== 1) {
      throw new Error('original modify-ink register winner changed concurrently');
    }
  }

  private async updateStroke(store: relationalStore.RdbStore, noteId: string,
    replacement: PlannedReplacement): Promise<void> {
    const target: StoredInkTarget = replacement.target;
    const stroke: StrokeElementData = replacement.stroke;
    const updatedStroke: StrokeElementData = {
      id: stroke.id,
      pathPoints: replacement.geometry.pathPoints,
      cubicSegments: replacement.geometry.cubicSegments,
      splatPoints: stroke.splatPoints,
      renderSpec: {
        color: replacement.color,
        brushWidth: replacement.width,
        inkStyle: originalStyleToInkStyle(replacement.style),
        isHighlighter: stroke.renderSpec.isHighlighter,
        isPencil: stroke.renderSpec.isPencil,
      },
      transform: replacement.transform,
      bounds: replacement.geometry.bounds,
      maskPath: stroke.maskPath,
      isFinished: stroke.isFinished,
    };
    const predicates = elementPredicates(noteId, target, stroke.id);
    const persisted: PersistedElement = { kind: 'stroke', data: updatedStroke };
    const updated: number = await store.update({
      'payload': encodePersistedElement(persisted), 'revision': target.revision + 1,
    }, predicates);
    if (updated !== 1) {
      throw new Error('original modify-ink lost its target stroke');
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
      throw new Error('original modify-ink page revision changed concurrently');
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

function elementPredicates(noteId: string, target: StoredInkTarget,
  elementId: string): relationalStore.RdbPredicates {
  const predicates = new relationalStore.RdbPredicates(target.table);
  predicates.equalTo('note_id', noteId);
  if (target.archived) {
    predicates.equalTo('page_timestamp', target.page.timestamp);
    predicates.equalTo('page_site_id', target.page.siteId);
    predicates.equalTo('page_index', target.page.index);
  } else {
    predicates.equalTo('page_id', target.pageId);
  }
  predicates.equalTo('element_id', elementId);
  predicates.equalTo('kind', PageElementKind.STROKE);
  return predicates;
}

function normalizeOriginalInkStyle(value: number): number {
  return value >= 0 && value <= 3 ? value : 0;
}

function originalColorToArgb(bytes: Uint8Array): number {
  return ((bytes[3] << 24) | (bytes[0] << 16) | (bytes[1] << 8) | bytes[2]);
}

function originalStyleToInkStyle(style: number): InkStyle {
  if (style === 0) {
    return InkStyle.VARIABLE_WIDTH;
  }
  if (style === 1) {
    return InkStyle.FIXED_WIDTH;
  }
  if (style === 2) {
    return InkStyle.DASH;
  }
  if (style === 3) {
    return InkStyle.DOTS;
  }
  throw new Error('original modify-ink has an invalid style');
}

function inkStyleToOriginalStyle(style: InkStyle): number {
  if (style === InkStyle.VARIABLE_WIDTH) {
    return 0;
  }
  if (style === InkStyle.FIXED_WIDTH) {
    return 1;
  }
  if (style === InkStyle.DASH) {
    return 2;
  }
  if (style === InkStyle.DOTS) {
    return 3;
  }
  throw new Error('stored Ink has an unsupported style');
}

function copyStroke(stroke: StrokeElementData, renderSpec: RenderSpec,
  transform: TransformMatrix): StrokeElementData {
  return {
    id: stroke.id, pathPoints: stroke.pathPoints, cubicSegments: stroke.cubicSegments,
    splatPoints: stroke.splatPoints, renderSpec: renderSpec, transform: transform,
    bounds: stroke.bounds, maskPath: stroke.maskPath, isFinished: stroke.isFinished,
  };
}

function readWinner(rows: relationalStore.ResultSet, timestampColumn: string,
  siteColumn: string): OperationIdentity {
  const winner: OperationIdentity = {
    timestamp: rows.getLong(rows.getColumnIndex(timestampColumn)),
    siteId: rows.getLong(rows.getColumnIndex(siteColumn)),
  };
  validateOperationIdentity(winner);
  return winner;
}

function readNullableLong(rows: relationalStore.ResultSet, columnName: string): number | null {
  const column: number = rows.getColumnIndex(columnName);
  return rows.isColumnNull(column) ? null : rows.getLong(column);
}

function readNullableDouble(rows: relationalStore.ResultSet, columnName: string): number | null {
  const column: number = rows.getColumnIndex(columnName);
  if (rows.isColumnNull(column)) {
    return null;
  }
  const value: number = rows.getDouble(column);
  if (!Number.isFinite(value)) {
    throw new Error(`original modify-ink has an invalid ${columnName}`);
  }
  return value;
}

function readOptionalWinner(rows: relationalStore.ResultSet,
  prefix: string): OperationIdentity | null {
  const present: number = rows.getLong(rows.getColumnIndex(`${prefix}_winner_present`));
  if (present === 0) {
    return null;
  }
  if (present !== 1) {
    throw new Error('original modify-ink has an invalid winner presence');
  }
  return readWinner(rows, `${prefix}_winner_timestamp`, `${prefix}_winner_site_id`);
}

function readBaseTransform(rows: relationalStore.ResultSet): OriginalInkBaseTransform | null {
  const originX: number | null = readNullableDouble(rows, 'create_origin_x');
  const originY: number | null = readNullableDouble(rows, 'create_origin_y');
  const rotation: number | null = readNullableDouble(rows, 'create_rotation');
  const scaleX: number | null = readNullableDouble(rows, 'create_scale_x');
  const scaleY: number | null = readNullableDouble(rows, 'create_scale_y');
  const presentCount: number = [originX, originY, rotation, scaleX, scaleY]
    .filter((value: number | null) => value !== null).length;
  if (presentCount === 0) {
    return null;
  }
  if (presentCount !== 5) {
    throw new Error('original modify-ink has a partial CREATE transform');
  }
  return {
    originX: originX as number, originY: originY as number, rotation: rotation as number,
    scaleX: scaleX as number, scaleY: scaleY as number,
  };
}

function createBaseTransform(payload: OriginalCreateInkPayload): OriginalInkBaseTransform {
  return {
    originX: payload.originX, originY: payload.originY, rotation: payload.rotation,
    scaleX: payload.scaleX, scaleY: payload.scaleY,
  };
}

function transformMatricesEqual(left: TransformMatrix, right: TransformMatrix): boolean {
  return JSON.stringify(left) === JSON.stringify(right);
}

function registerAccepts(operation: OperationIdentity,
  winner: OperationIdentity | null): boolean {
  return winner === null || compareOperationIdentity(operation, winner) > 0;
}

function readInlineFloat32(bytes: Uint8Array, offset: number): number {
  return new DataView(bytes.buffer, bytes.byteOffset + offset, 4).getFloat32(0, true);
}

function addWinnerPredicates(predicates: relationalStore.RdbPredicates, prefix: string,
  winner: OperationIdentity | null): void {
  predicates.equalTo(`${prefix}_winner_present`, winner === null ? 0 : 1);
  if (winner !== null) {
    predicates.equalTo(`${prefix}_winner_timestamp`, winner.timestamp);
    predicates.equalTo(`${prefix}_winner_site_id`, winner.siteId);
  }
}

function pageKey(target: StoredInkTarget): string {
  return target.archived ?
    `archive:${target.page.timestamp}:${target.page.siteId}:${target.page.index}` :
    `live:${target.pageId}`;
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
