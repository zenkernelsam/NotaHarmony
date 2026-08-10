import { relationalStore } from '@kit.ArkData';
import { TextBlockElement } from '../core/model/ElementTypes';
import { TransformMatrix } from '../core/model/GeometryTypes';
import { PageElementKind } from '../core/model/PageElementOrder';
import { textBlockWorldBounds } from '../core/model/TextBlockGeometry';
import {
  compareOperationIdentity, encodeOperationId, OperationIdentity, OriginalSequenceIdentity,
  validateOperationIdentity, validateOriginalSequenceIdentity,
} from './OperationIdentity';
import { OriginalBlockType } from './OriginalCreateBlockOperation';
import {
  OriginalFlatBufferTableReader, readOriginalInlineFloat32, readOriginalPayloadTable,
} from './OriginalSyncedOperationFlatBuffer';
import { SearchItemType } from './SearchItemType';
import { decodePersistedElement, encodePersistedElement, PersistedElement } from './StrokePersistence';
import {
  StoredSyncedOperation, SyncedOperationApplier, SyncedOperationApplyResult,
} from './SyncedOperationInbox';
import { compareUnsignedLongDecimal, validateUnsignedLongDecimal } from './UnsignedDecimal';

export const ORIGINAL_MODIFY_BLOCK_PAYLOAD_TYPE: number = 23;
const MAX_ORIGINAL_MODIFY_BLOCK_COUNT: number = 10000;

export interface NullableBlockRegisterUpdate<T> {
  present: boolean;
  value: T | null;
}

export interface OriginalBlockScale {
  x: number;
  y: number;
}

export interface OriginalBlockPageOrigin {
  page: OriginalSequenceIdentity;
  originX: number;
  originY: number;
}

export interface OriginalModifyBlockPayload {
  blocks: OperationIdentity[];
  corner: number | null;
  pageOrigin: OriginalBlockPageOrigin | null;
  rotation: NullableBlockRegisterUpdate<number>;
  scale: NullableBlockRegisterUpdate<OriginalBlockScale>;
  width: number | null;
  height: number | null;
  textWrap: number | null;
  enableCaption: boolean | null;
  zIndex: string | null;
  positionLocked: boolean | null;
  hasTypeSpecificFields: boolean;
}

interface StoredRegister<T> {
  value: T | null;
  winner: OperationIdentity | null;
}

interface StoredBlockState {
  basePageOrigin: OriginalBlockPageOrigin;
  pageOrigin: StoredRegister<OriginalBlockPageOrigin>;
  baseRotation: number | null;
  rotation: StoredRegister<number>;
  baseScale: OriginalBlockScale | null;
  scale: StoredRegister<OriginalBlockScale>;
  baseWidth: number;
  baseHeight: number;
  size: StoredRegister<OriginalBlockScale>;
  baseCorner: number;
  corner: StoredRegister<number>;
  baseTextWrap: number;
  textWrap: StoredRegister<number>;
  baseEnableCaption: boolean;
  enableCaption: StoredRegister<boolean>;
  basePositionLocked: boolean;
  positionLocked: StoredRegister<boolean>;
  baseLeftInset: number;
  baseTopInset: number;
  baseZIndex: string;
  zIndex: StoredRegister<string>;
}

interface StoredPageTarget {
  page: OriginalSequenceIdentity;
  pageId: string;
  table: string;
  revisionTable: string;
  revision: number;
  archived: boolean;
}

interface StoredBlockTarget extends StoredPageTarget {
  block: OperationIdentity;
  zIndex: string;
}

interface StoredZIndexRow {
  elementId: string;
  kind: number;
  timestamp: number;
  siteId: number;
  zIndex: string;
}

interface PageMutation {
  target: StoredPageTarget;
  rows: StoredZIndexRow[];
}

interface PlannedBlockReplacement {
  target: StoredBlockTarget;
  destination: StoredPageTarget;
  state: StoredBlockState;
  text: TextBlockElement;
  updatedText: TextBlockElement;
  pageOriginValue: OriginalBlockPageOrigin;
  rotationValue: number | null;
  scaleValue: OriginalBlockScale | null;
  sizeValue: OriginalBlockScale;
  cornerValue: number;
  textWrapValue: number;
  enableCaptionValue: boolean;
  positionLockedValue: boolean;
  zIndexValue: string;
  replacePageOrigin: boolean;
  replaceRotation: boolean;
  replaceScale: boolean;
  replaceSize: boolean;
  replaceCorner: boolean;
  replaceTextWrap: boolean;
  replaceEnableCaption: boolean;
  replacePositionLocked: boolean;
  replaceZIndex: boolean;
}

export function decodeOriginalModifyBlock(bytes: Uint8Array): OriginalModifyBlockPayload {
  const table: OriginalFlatBufferTableReader = readOriginalPayloadTable(
    bytes, ORIGINAL_MODIFY_BLOCK_PAYLOAD_TYPE);
  const rawBlocks: number[][] = table.readInlineOperationIdentityVector(
    0, MAX_ORIGINAL_MODIFY_BLOCK_COUNT);
  if (rawBlocks.length === 0) {
    throw new Error('original modify-block contains no target blocks');
  }
  const blocks: OperationIdentity[] = [];
  const identities: Set<string> = new Set<string>();
  for (const raw of rawBlocks) {
    const block: OperationIdentity = { timestamp: raw[0], siteId: raw[1] };
    validateOperationIdentity(block);
    const key: string = encodeOperationId(block);
    if (identities.has(key)) {
      throw new Error('original modify-block repeats a target block');
    }
    identities.add(key);
    blocks.push(block);
  }
  const rawPage: number[] | null = table.readInlineSequence(2);
  const originBytes: Uint8Array | null = table.readInlineBytes(3, 8);
  if ((rawPage === null) !== (originBytes === null)) {
    throw new Error('original modify-block must pair page and origin');
  }
  let pageOrigin: OriginalBlockPageOrigin | null = null;
  if (rawPage !== null && originBytes !== null) {
    const page: OriginalSequenceIdentity = {
      timestamp: rawPage[0], siteId: rawPage[1], index: rawPage[2],
    };
    validateOriginalSequenceIdentity(page);
    pageOrigin = {
      page: page, originX: readOriginalInlineFloat32(originBytes, 0),
      originY: readOriginalInlineFloat32(originBytes, 4),
    };
  }
  const rotationSetter: OriginalFlatBufferTableReader | null = table.readTable(4);
  const scaleSetter: OriginalFlatBufferTableReader | null = table.readTable(5);
  const scaleBytes: Uint8Array | null = scaleSetter === null ? null :
    scaleSetter.readInlineBytes(0, 8);
  const sizeBytes: Uint8Array | null = table.readInlineBytes(6, 8);
  const zIndex: string | null = table.readUint64Decimal(9);
  if (zIndex !== null) {
    validateUnsignedLongDecimal(zIndex);
  }
  let hasTypeSpecificFields: boolean = false;
  for (let field: number = 10; field <= 16; field++) {
    if (table.hasField(field)) {
      hasTypeSpecificFields = true;
    }
  }
  return {
    blocks: blocks,
    corner: table.hasField(1) ? normalizeOriginalEnum(table.readUint8(1, 0), 1) : null,
    pageOrigin: pageOrigin,
    rotation: {
      present: rotationSetter !== null,
      value: rotationSetter === null || !rotationSetter.hasField(0) ? null :
        rotationSetter.readFloat32(0, 0),
    },
    scale: {
      present: scaleSetter !== null,
      value: scaleBytes === null ? null : {
        x: readOriginalInlineFloat32(scaleBytes, 0),
        y: readOriginalInlineFloat32(scaleBytes, 4),
      },
    },
    width: sizeBytes === null ? null : readOriginalInlineFloat32(sizeBytes, 0),
    height: sizeBytes === null ? null : readOriginalInlineFloat32(sizeBytes, 4),
    textWrap: table.hasField(7) ? normalizeOriginalEnum(table.readUint8(7, 0), 1) : null,
    enableCaption: table.hasField(8) ? table.readUint8(8, 0) !== 0 : null,
    zIndex: zIndex,
    positionLocked: table.hasField(17) ? table.readUint8(17, 0) !== 0 : null,
    hasTypeSpecificFields: hasTypeSpecificFields,
  };
}

export class OriginalModifyBlockOperationApplier implements SyncedOperationApplier {
  supports(payloadType: number): boolean {
    return payloadType === ORIGINAL_MODIFY_BLOCK_PAYLOAD_TYPE;
  }

  async apply(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation): Promise<SyncedOperationApplyResult> {
    let payload: OriginalModifyBlockPayload;
    try {
      payload = decodeOriginalModifyBlock(operation.rawOperation);
    } catch (_error) {
      return { deferredReason: 'MALFORMED_MODIFY_BLOCK_PAYLOAD' };
    }
    if (payload.hasTypeSpecificFields) {
      return { deferredReason: 'MODIFY_BLOCK_TYPE_SPECIFIC_FIELDS_UNSUPPORTED' };
    }
    if (payload.corner !== null || payload.textWrap !== null || payload.enableCaption !== null ||
      payload.positionLocked !== null) {
      return { deferredReason: 'MODIFY_BLOCK_COMMON_BEHAVIOR_UNSUPPORTED' };
    }
    if ((payload.pageOrigin !== null && (!Number.isFinite(payload.pageOrigin.originX) ||
      !Number.isFinite(payload.pageOrigin.originY))) ||
      (payload.rotation.value !== null && !Number.isFinite(payload.rotation.value)) ||
      (payload.scale.value !== null && (!Number.isFinite(payload.scale.value.x) ||
        !Number.isFinite(payload.scale.value.y))) ||
      (payload.width !== null && (!Number.isFinite(payload.width) || payload.width < 0)) ||
      (payload.height !== null && (!Number.isFinite(payload.height) || payload.height < 0))) {
      return { deferredReason: 'MODIFY_BLOCK_GEOMETRY_UNSUPPORTED' };
    }
    if (payload.pageOrigin === null && !payload.rotation.present && !payload.scale.present &&
      payload.width === null && payload.corner === null && payload.textWrap === null &&
      payload.enableCaption === null && payload.positionLocked === null && payload.zIndex === null) {
      return { deferredReason: null };
    }

    const planned: PlannedBlockReplacement[] = [];
    for (const block of payload.blocks) {
      const target: StoredBlockTarget | null = await this.readTarget(store, operation.noteId, block);
      if (target === null) {
        return { deferredReason: 'MODIFY_BLOCK_TARGET_MISSING_OR_UNBOUND' };
      }
      const state: StoredBlockState | null = await this.readState(store, operation.noteId, block);
      const text: TextBlockElement | null = await this.readText(store, operation.noteId, target);
      if (state === null || text === null || !this.currentStateMatches(target, state, text)) {
        return { deferredReason: 'MODIFY_BLOCK_STATE_DIVERGED' };
      }
      const replacePageOrigin: boolean = payload.pageOrigin !== null &&
        registerAccepts(operation, state.pageOrigin.winner);
      const replaceRotation: boolean = payload.rotation.present &&
        registerAccepts(operation, state.rotation.winner);
      const replaceScale: boolean = payload.scale.present &&
        registerAccepts(operation, state.scale.winner);
      const replaceSize: boolean = payload.width !== null &&
        registerAccepts(operation, state.size.winner);
      const replaceCorner: boolean = payload.corner !== null &&
        registerAccepts(operation, state.corner.winner);
      const replaceTextWrap: boolean = payload.textWrap !== null &&
        registerAccepts(operation, state.textWrap.winner);
      const replaceEnableCaption: boolean = payload.enableCaption !== null &&
        registerAccepts(operation, state.enableCaption.winner);
      const replacePositionLocked: boolean = payload.positionLocked !== null &&
        registerAccepts(operation, state.positionLocked.winner);
      const replaceZIndex: boolean = payload.zIndex !== null &&
        registerAccepts(operation, state.zIndex.winner);
      if (!replacePageOrigin && !replaceRotation && !replaceScale && !replaceSize &&
        !replaceCorner && !replaceTextWrap && !replaceEnableCaption &&
        !replacePositionLocked && !replaceZIndex) {
        continue;
      }
      const currentPageOrigin: OriginalBlockPageOrigin = effectivePageOrigin(state);
      const pageOriginValue: OriginalBlockPageOrigin = replacePageOrigin ?
        payload.pageOrigin as OriginalBlockPageOrigin : currentPageOrigin;
      const rotationValue: number | null = replaceRotation ? payload.rotation.value :
        effectiveNullable(state.baseRotation, state.rotation);
      const scaleValue: OriginalBlockScale | null = replaceScale ? payload.scale.value :
        effectiveNullable(state.baseScale, state.scale);
      const sizeValue: OriginalBlockScale = replaceSize ? {
        x: payload.width as number, y: payload.height as number,
      } : effectiveSize(state);
      const zIndexValue: string = replaceZIndex ? payload.zIndex as string : effectiveZIndex(state);
      const destination: StoredPageTarget | null = samePageIdentity(target.page, pageOriginValue.page) ?
        target : await this.readPageTarget(store, operation.noteId, pageOriginValue.page);
      if (destination === null || target.revision >= Number.MAX_SAFE_INTEGER ||
        destination.revision >= Number.MAX_SAFE_INTEGER) {
        return { deferredReason: 'MODIFY_BLOCK_DESTINATION_MISSING_OR_EXHAUSTED' };
      }
      const updatedText: TextBlockElement = cloneText(text);
      const scale: OriginalBlockScale = scaleValue === null ? { x: 1, y: 1 } : scaleValue;
      updatedText.transform = blockTransform(pageOriginValue.originX, pageOriginValue.originY,
        rotationValue === null ? 0 : rotationValue, scale.x, scale.y);
      updatedText.rotationRadians = rotationValue === null ? 0 : rotationValue;
      updatedText.blockWidth = sizeValue.x;
      updatedText.blockHeight = sizeValue.y;
      updatedText.bounds = textBlockWorldBounds(updatedText);
      planned.push({
        target: target, destination: destination, state: state, text: text, updatedText: updatedText,
        pageOriginValue: pageOriginValue, rotationValue: rotationValue, scaleValue: scaleValue,
        sizeValue: sizeValue,
        cornerValue: replaceCorner ? payload.corner as number : effectiveNumber(state.baseCorner, state.corner),
        textWrapValue: replaceTextWrap ? payload.textWrap as number :
          effectiveNumber(state.baseTextWrap, state.textWrap),
        enableCaptionValue: replaceEnableCaption ? payload.enableCaption as boolean :
          effectiveBoolean(state.baseEnableCaption, state.enableCaption),
        positionLockedValue: replacePositionLocked ? payload.positionLocked as boolean :
          effectiveBoolean(state.basePositionLocked, state.positionLocked),
        zIndexValue: zIndexValue,
        replacePageOrigin: replacePageOrigin, replaceRotation: replaceRotation,
        replaceScale: replaceScale, replaceSize: replaceSize, replaceCorner: replaceCorner,
        replaceTextWrap: replaceTextWrap, replaceEnableCaption: replaceEnableCaption,
        replacePositionLocked: replacePositionLocked, replaceZIndex: replaceZIndex,
      });
    }
    if (planned.length === 0) {
      return { deferredReason: null };
    }
    const mutations: Map<string, PageMutation> | null = await this.preparePageMutations(
      store, operation.noteId, planned);
    if (mutations === null) {
      return { deferredReason: 'MODIFY_BLOCK_ELEMENT_ORDER_DIVERGED' };
    }
    const affected: Map<string, StoredPageTarget> = new Map<string, StoredPageTarget>();
    for (const replacement of planned) {
      affected.set(pageKey(replacement.target), replacement.target);
      affected.set(pageKey(replacement.destination), replacement.destination);
      await this.updateState(store, operation.noteId, replacement, operation);
      if (samePageIdentity(replacement.target.page, replacement.destination.page)) {
        if (replacement.replaceZIndex) {
          await this.updateTrackedElement(store, operation.noteId, replacement, false);
        }
        await this.updateText(store, operation.noteId, replacement);
      } else {
        await this.moveText(store, operation.noteId, replacement, mutations);
      }
    }
    for (const mutation of mutations.values()) {
      await this.materializeOrder(store, operation.noteId, mutation);
    }
    for (const target of affected.values()) {
      await this.advanceRevisionAndInvalidateSearch(store, operation.noteId, target);
    }
    return { deferredReason: null };
  }

  private async readTarget(store: relationalStore.RdbStore, noteId: string,
    block: OperationIdentity): Promise<StoredBlockTarget | null> {
    const rows = await store.querySql(
      `SELECT element.kind, element.page_timestamp, element.page_site_id, element.page_index,
              identity.page_id, identity.visible, element.z_index, state.block_type
       FROM original_element_z_index element
       JOIN original_page_identity identity ON identity.note_id = element.note_id
        AND identity.seq_timestamp = element.page_timestamp
        AND identity.seq_site_id = element.page_site_id AND identity.seq_index = element.page_index
       JOIN original_block_state state ON state.note_id = element.note_id
        AND state.block_timestamp = element.element_timestamp
        AND state.block_site_id = element.element_site_id
       WHERE element.note_id = ? AND element.element_timestamp = ? AND element.element_site_id = ?`,
      [noteId, block.timestamp, block.siteId]);
    let page: OriginalSequenceIdentity;
    let pageId: string;
    let zIndex: string;
    try {
      if (!rows.goToFirstRow() || rows.getLong(rows.getColumnIndex('kind')) !== PageElementKind.TEXT ||
        rows.getLong(rows.getColumnIndex('block_type')) !== OriginalBlockType.TEXT ||
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
      zIndex = rows.getString(rows.getColumnIndex('z_index'));
    } finally {
      rows.close();
    }
    validateOriginalSequenceIdentity(page);
    validateUnsignedLongDecimal(zIndex);
    const target: StoredPageTarget | null = await this.resolveStoredPage(
      store, noteId, page, pageId);
    return target === null ? null : {
      block: block, page: target.page, pageId: target.pageId, table: target.table,
      revisionTable: target.revisionTable, revision: target.revision,
      archived: target.archived, zIndex: zIndex,
    };
  }

  private async readPageTarget(store: relationalStore.RdbStore, noteId: string,
    page: OriginalSequenceIdentity): Promise<StoredPageTarget | null> {
    const rows = await store.querySql(
      `SELECT page_id, visible FROM original_page_identity WHERE note_id = ?
       AND seq_timestamp = ? AND seq_site_id = ? AND seq_index = ?`,
      [noteId, page.timestamp, page.siteId, page.index]);
    let pageId: string | null = null;
    try {
      if (!rows.goToFirstRow() || rows.getLong(rows.getColumnIndex('visible')) !== 1 ||
        rows.isColumnNull(rows.getColumnIndex('page_id'))) {
        return null;
      }
      pageId = rows.getString(rows.getColumnIndex('page_id'));
    } finally {
      rows.close();
    }
    return pageId === null ? null : this.resolveStoredPage(store, noteId, page, pageId);
  }

  private async resolveStoredPage(store: relationalStore.RdbStore, noteId: string,
    page: OriginalSequenceIdentity, pageId: string): Promise<StoredPageTarget | null> {
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
      page: page, pageId: pageId, table: 'page_element_snapshot', revisionTable: 'page_info',
      revision: liveRevision, archived: false,
    } : {
      page: page, pageId: pageId, table: 'original_deleted_page_element',
      revisionTable: 'original_deleted_page', revision: archivedRevision as number, archived: true,
    };
  }

  private async readState(store: relationalStore.RdbStore, noteId: string,
    block: OperationIdentity): Promise<StoredBlockState | null> {
    const rows = await store.querySql(
      `SELECT * FROM original_block_state WHERE note_id = ?
       AND block_timestamp = ? AND block_site_id = ?`,
      [noteId, block.timestamp, block.siteId]);
    try {
      if (!rows.goToFirstRow()) {
        return null;
      }
      const basePage: OriginalSequenceIdentity = {
        timestamp: rows.getLong(rows.getColumnIndex('create_page_timestamp')),
        siteId: rows.getLong(rows.getColumnIndex('create_page_site_id')),
        index: rows.getLong(rows.getColumnIndex('create_page_index')),
      };
      validateOriginalSequenceIdentity(basePage);
      const pageWinner: OperationIdentity | null = readOptionalWinner(rows, 'page_origin');
      const storedPage: OriginalSequenceIdentity | null = readNullableSequence(rows,
        'page_origin_page_timestamp', 'page_origin_page_site_id', 'page_origin_page_index');
      const pageOrigin: OriginalBlockPageOrigin | null = pageWinner === null ? null : {
        page: requireValue(storedPage, 'page-origin page'),
        originX: requireValue(readNullableDouble(rows, 'page_origin_x'), 'page-origin x'),
        originY: requireValue(readNullableDouble(rows, 'page_origin_y'), 'page-origin y'),
      };
      const baseScale: OriginalBlockScale | null = readNullableScale(
        rows, 'create_scale_x', 'create_scale_y');
      const scaleWinner: OperationIdentity | null = readOptionalWinner(rows, 'scale');
      const scaleValue: OriginalBlockScale | null = scaleWinner === null ? null :
        readNullableScale(rows, 'scale_x_value', 'scale_y_value');
      const baseRotation: number | null = readNullableDouble(rows, 'create_rotation');
      const rotationWinner: OperationIdentity | null = readOptionalWinner(rows, 'rotation');
      const rotationValue: number | null = rotationWinner === null ? null :
        readNullableDouble(rows, 'rotation_value');
      const sizeWinner: OperationIdentity | null = readOptionalWinner(rows, 'size');
      const sizeValue: OriginalBlockScale | null = sizeWinner === null ? null : {
        x: requireValue(readNullableDouble(rows, 'size_width_value'), 'size width'),
        y: requireValue(readNullableDouble(rows, 'size_height_value'), 'size height'),
      };
      const baseZIndex: string = rows.getString(rows.getColumnIndex('create_z_index'));
      validateUnsignedLongDecimal(baseZIndex);
      const zWinner: OperationIdentity | null = readOptionalWinner(rows, 'z_index');
      const zValue: string | null = zWinner === null ? null :
        requireValue(readNullableString(rows, 'z_index_value'), 'z-index');
      if (zValue !== null) {
        validateUnsignedLongDecimal(zValue);
      }
      const baseOriginX: number = rows.getDouble(rows.getColumnIndex('create_origin_x'));
      const baseOriginY: number = rows.getDouble(rows.getColumnIndex('create_origin_y'));
      const baseWidth: number = rows.getDouble(rows.getColumnIndex('create_width'));
      const baseHeight: number = rows.getDouble(rows.getColumnIndex('create_height'));
      const baseCorner: number = rows.getLong(rows.getColumnIndex('create_corner'));
      const baseTextWrap: number = rows.getLong(rows.getColumnIndex('create_text_wrap'));
      const baseEnableCaption: number = rows.getLong(rows.getColumnIndex('create_enable_caption'));
      const basePositionLocked: number = rows.getLong(rows.getColumnIndex('create_position_locked'));
      const baseLeftInset: number = rows.getDouble(rows.getColumnIndex('create_margin_left'));
      const baseTopInset: number = rows.getDouble(rows.getColumnIndex('create_margin_top'));
      if (![baseOriginX, baseOriginY, baseWidth, baseHeight, baseLeftInset, baseTopInset]
        .every((value: number) => Number.isFinite(value)) || baseWidth < 0 || baseHeight < 0 ||
        baseLeftInset < 0 || baseTopInset < 0 || baseCorner < 0 || baseCorner > 1 ||
        baseTextWrap < 0 || baseTextWrap > 1 ||
        (baseEnableCaption !== 0 && baseEnableCaption !== 1) ||
        (basePositionLocked !== 0 && basePositionLocked !== 1) ||
        !isFiniteNullableNumber(baseRotation) || !isFiniteNullableNumber(rotationValue) ||
        !isFiniteNullableScale(baseScale) || !isFiniteNullableScale(scaleValue) ||
        !isFiniteNullableScale(sizeValue) ||
        (sizeValue !== null && (sizeValue.x < 0 || sizeValue.y < 0)) ||
        (pageOrigin !== null && (!Number.isFinite(pageOrigin.originX) ||
          !Number.isFinite(pageOrigin.originY)))) {
        return null;
      }
      const corner: StoredRegister<number> = readNumberRegister(rows, 'corner');
      const textWrap: StoredRegister<number> = readNumberRegister(rows, 'text_wrap');
      if ((corner.value !== null && (corner.value < 0 || corner.value > 1)) ||
        (textWrap.value !== null && (textWrap.value < 0 || textWrap.value > 1))) {
        return null;
      }
      return {
        basePageOrigin: {
          page: basePage,
          originX: baseOriginX, originY: baseOriginY,
        },
        pageOrigin: { value: pageOrigin, winner: pageWinner },
        baseRotation: baseRotation,
        rotation: { value: rotationValue, winner: rotationWinner },
        baseScale: baseScale, scale: { value: scaleValue, winner: scaleWinner },
        baseWidth: baseWidth, baseHeight: baseHeight,
        size: { value: sizeValue, winner: sizeWinner },
        baseCorner: baseCorner, corner: corner,
        baseTextWrap: baseTextWrap, textWrap: textWrap,
        baseEnableCaption: baseEnableCaption !== 0,
        enableCaption: readBooleanRegister(rows, 'enable_caption'),
        basePositionLocked: basePositionLocked !== 0,
        positionLocked: readBooleanRegister(rows, 'position_locked'),
        baseLeftInset: baseLeftInset, baseTopInset: baseTopInset,
        baseZIndex: baseZIndex, zIndex: { value: zValue, winner: zWinner },
      };
    } catch (_error) {
      return null;
    } finally {
      rows.close();
    }
  }

  private async readText(store: relationalStore.RdbStore, noteId: string,
    target: StoredBlockTarget): Promise<TextBlockElement | null> {
    const id: string = encodeOperationId(target.block);
    const rows = target.archived ? await store.querySql(
      `SELECT payload FROM original_deleted_page_element WHERE note_id = ?
       AND page_timestamp = ? AND page_site_id = ? AND page_index = ?
       AND element_id = ? AND kind = ?`,
      [noteId, target.page.timestamp, target.page.siteId, target.page.index,
        id, PageElementKind.TEXT]) : await store.querySql(
      `SELECT payload FROM page_element_snapshot WHERE note_id = ? AND page_id = ?
       AND element_id = ? AND kind = ?`, [noteId, target.pageId, id, PageElementKind.TEXT]);
    try {
      if (!rows.goToFirstRow()) {
        return null;
      }
      const persisted: PersistedElement = decodePersistedElement(
        rows.getBlob(rows.getColumnIndex('payload')));
      return persisted.kind === 'text' ? persisted.data as TextBlockElement : null;
    } catch (_error) {
      return null;
    } finally {
      rows.close();
    }
  }

  private currentStateMatches(target: StoredBlockTarget, state: StoredBlockState,
    text: TextBlockElement): boolean {
    const pageOrigin: OriginalBlockPageOrigin = effectivePageOrigin(state);
    const rotation: number | null = effectiveNullable(state.baseRotation, state.rotation);
    const scaleValue: OriginalBlockScale | null = effectiveNullable(state.baseScale, state.scale);
    const scale: OriginalBlockScale = scaleValue === null ? { x: 1, y: 1 } : scaleValue;
    const size: OriginalBlockScale = effectiveSize(state);
    const expectedTransform: TransformMatrix = blockTransform(
      pageOrigin.originX, pageOrigin.originY, rotation === null ? 0 : rotation, scale.x, scale.y);
    const expectedText: TextBlockElement = cloneText(text);
    expectedText.transform = expectedTransform;
    expectedText.blockWidth = size.x;
    expectedText.blockHeight = size.y;
    const expectedBounds = textBlockWorldBounds(expectedText);
    return samePageIdentity(target.page, pageOrigin.page) && target.zIndex === effectiveZIndex(state) &&
      JSON.stringify(text.transform) === JSON.stringify(expectedTransform) &&
      JSON.stringify(text.bounds) === JSON.stringify(expectedBounds) &&
      text.blockWidth === size.x && text.blockHeight === size.y && text.textOrigin.x === 0 &&
      text.textOrigin.y === 0 && text.rotationRadians === (rotation === null ? 0 : rotation) &&
      text.contentLeftInset === state.baseLeftInset && text.contentTopInset === state.baseTopInset &&
      text.id === encodeOperationId(target.block);
  }

  private async preparePageMutations(store: relationalStore.RdbStore, noteId: string,
    planned: PlannedBlockReplacement[]): Promise<Map<string, PageMutation> | null> {
    const mutations: Map<string, PageMutation> = new Map<string, PageMutation>();
    for (const replacement of planned) {
      const changesPage: boolean = !samePageIdentity(
        replacement.target.page, replacement.destination.page);
      if (!changesPage && !replacement.replaceZIndex) {
        continue;
      }
      const source: PageMutation | null = await this.loadPageMutation(
        store, noteId, replacement.target, mutations);
      if (source === null) {
        return null;
      }
      const id: string = replacement.text.id;
      const sourceIndex: number = source.rows.findIndex((row: StoredZIndexRow) =>
        row.elementId === id && row.kind === PageElementKind.TEXT);
      if (sourceIndex < 0) {
        return null;
      }
      const old: StoredZIndexRow = source.rows[sourceIndex];
      const moved: StoredZIndexRow = {
        elementId: old.elementId, kind: old.kind, timestamp: old.timestamp,
        siteId: old.siteId, zIndex: replacement.zIndexValue,
      };
      if (!changesPage) {
        source.rows[sourceIndex] = moved;
        source.rows.sort(compareStoredZIndexRows);
        continue;
      }
      const destination: PageMutation | null = await this.loadPageMutation(
        store, noteId, replacement.destination, mutations);
      if (destination === null || destination.rows.some((row: StoredZIndexRow) =>
        row.elementId === id && row.kind === PageElementKind.TEXT)) {
        return null;
      }
      source.rows.splice(sourceIndex, 1);
      destination.rows.push(moved);
      source.rows.sort(compareStoredZIndexRows);
      destination.rows.sort(compareStoredZIndexRows);
    }
    return mutations;
  }

  private async loadPageMutation(store: relationalStore.RdbStore, noteId: string,
    target: StoredPageTarget, mutations: Map<string, PageMutation>): Promise<PageMutation | null> {
    const key: string = pageKey(target);
    const existing: PageMutation | undefined = mutations.get(key);
    if (existing !== undefined) {
      return existing;
    }
    const rows: StoredZIndexRow[] | null = await this.readCompleteOriginalOrder(store, noteId, target);
    if (rows === null) {
      return null;
    }
    const mutation: PageMutation = { target: target, rows: rows };
    mutations.set(key, mutation);
    return mutation;
  }

  private async readCompleteOriginalOrder(store: relationalStore.RdbStore, noteId: string,
    target: StoredPageTarget): Promise<StoredZIndexRow[] | null> {
    const tracked = await store.querySql(
      `SELECT element_timestamp, element_site_id, kind, z_index
       FROM original_element_z_index WHERE note_id = ? AND page_timestamp = ?
       AND page_site_id = ? AND page_index = ?`,
      [noteId, target.page.timestamp, target.page.siteId, target.page.index]);
    const result: StoredZIndexRow[] = [];
    const keys: Set<string> = new Set<string>();
    try {
      while (tracked.goToNextRow()) {
        const timestamp: number = tracked.getLong(tracked.getColumnIndex('element_timestamp'));
        const siteId: number = tracked.getLong(tracked.getColumnIndex('element_site_id'));
        const kind: number = tracked.getLong(tracked.getColumnIndex('kind'));
        const id: string = encodeOperationId({ timestamp: timestamp, siteId: siteId });
        result.push({ elementId: id, kind: kind, timestamp: timestamp, siteId: siteId,
          zIndex: tracked.getString(tracked.getColumnIndex('z_index')) });
        keys.add(`${kind}:${id}`);
      }
    } finally {
      tracked.close();
    }
    const stored = target.archived ? await store.querySql(
      `SELECT element_id, kind FROM original_deleted_page_element WHERE note_id = ?
       AND page_timestamp = ? AND page_site_id = ? AND page_index = ?`,
      [noteId, target.page.timestamp, target.page.siteId, target.page.index]) : await store.querySql(
      'SELECT element_id, kind FROM page_element_snapshot WHERE note_id = ? AND page_id = ?',
      [noteId, target.pageId]);
    let count: number = 0;
    try {
      while (stored.goToNextRow()) {
        const key: string = `${stored.getLong(stored.getColumnIndex('kind'))}:` +
          stored.getString(stored.getColumnIndex('element_id'));
        if (!keys.has(key)) {
          return null;
        }
        count++;
      }
    } finally {
      stored.close();
    }
    return count === result.length ? result : null;
  }

  private async updateState(store: relationalStore.RdbStore, noteId: string,
    replacement: PlannedBlockReplacement, winner: OperationIdentity): Promise<void> {
    const predicates = new relationalStore.RdbPredicates('original_block_state');
    predicates.equalTo('note_id', noteId);
    predicates.equalTo('block_timestamp', replacement.target.block.timestamp);
    predicates.equalTo('block_site_id', replacement.target.block.siteId);
    const values: relationalStore.ValuesBucket = {};
    if (replacement.replacePageOrigin) {
      addWinnerPredicates(predicates, 'page_origin', replacement.state.pageOrigin.winner);
      values['page_origin_page_timestamp'] = replacement.pageOriginValue.page.timestamp;
      values['page_origin_page_site_id'] = replacement.pageOriginValue.page.siteId;
      values['page_origin_page_index'] = replacement.pageOriginValue.page.index;
      values['page_origin_x'] = replacement.pageOriginValue.originX;
      values['page_origin_y'] = replacement.pageOriginValue.originY;
      addWinnerValues(values, 'page_origin', winner);
    }
    if (replacement.replaceRotation) {
      addWinnerPredicates(predicates, 'rotation', replacement.state.rotation.winner);
      values['rotation_value'] = replacement.rotationValue;
      addWinnerValues(values, 'rotation', winner);
    }
    if (replacement.replaceScale) {
      addWinnerPredicates(predicates, 'scale', replacement.state.scale.winner);
      values['scale_x_value'] = replacement.scaleValue === null ? null : replacement.scaleValue.x;
      values['scale_y_value'] = replacement.scaleValue === null ? null : replacement.scaleValue.y;
      addWinnerValues(values, 'scale', winner);
    }
    if (replacement.replaceSize) {
      addWinnerPredicates(predicates, 'size', replacement.state.size.winner);
      values['size_width_value'] = replacement.sizeValue.x;
      values['size_height_value'] = replacement.sizeValue.y;
      addWinnerValues(values, 'size', winner);
    }
    if (replacement.replaceCorner) {
      addWinnerPredicates(predicates, 'corner', replacement.state.corner.winner);
      values['corner_value'] = replacement.cornerValue;
      addWinnerValues(values, 'corner', winner);
    }
    if (replacement.replaceTextWrap) {
      addWinnerPredicates(predicates, 'text_wrap', replacement.state.textWrap.winner);
      values['text_wrap_value'] = replacement.textWrapValue;
      addWinnerValues(values, 'text_wrap', winner);
    }
    if (replacement.replaceEnableCaption) {
      addWinnerPredicates(predicates, 'enable_caption', replacement.state.enableCaption.winner);
      values['enable_caption_value'] = replacement.enableCaptionValue ? 1 : 0;
      addWinnerValues(values, 'enable_caption', winner);
    }
    if (replacement.replacePositionLocked) {
      addWinnerPredicates(predicates, 'position_locked', replacement.state.positionLocked.winner);
      values['position_locked_value'] = replacement.positionLockedValue ? 1 : 0;
      addWinnerValues(values, 'position_locked', winner);
    }
    if (replacement.replaceZIndex) {
      addWinnerPredicates(predicates, 'z_index', replacement.state.zIndex.winner);
      values['z_index_value'] = replacement.zIndexValue;
      addWinnerValues(values, 'z_index', winner);
    }
    const updated: number = await store.update(values, predicates);
    if (updated !== 1) {
      throw new Error('original modify-block register winner changed concurrently');
    }
  }

  private async updateTrackedElement(store: relationalStore.RdbStore, noteId: string,
    replacement: PlannedBlockReplacement, changesPage: boolean): Promise<void> {
    const target: StoredBlockTarget = replacement.target;
    const predicates = new relationalStore.RdbPredicates('original_element_z_index');
    predicates.equalTo('note_id', noteId);
    predicates.equalTo('element_timestamp', target.block.timestamp);
    predicates.equalTo('element_site_id', target.block.siteId);
    predicates.equalTo('page_timestamp', target.page.timestamp);
    predicates.equalTo('page_site_id', target.page.siteId);
    predicates.equalTo('page_index', target.page.index);
    predicates.equalTo('kind', PageElementKind.TEXT);
    predicates.equalTo('z_index', target.zIndex);
    const values: relationalStore.ValuesBucket = { 'z_index': replacement.zIndexValue };
    if (changesPage) {
      values['page_timestamp'] = replacement.destination.page.timestamp;
      values['page_site_id'] = replacement.destination.page.siteId;
      values['page_index'] = replacement.destination.page.index;
    }
    const updated: number = await store.update(values, predicates);
    if (updated !== 1) {
      throw new Error('original modify-block lost its tracked element');
    }
  }

  private async updateText(store: relationalStore.RdbStore, noteId: string,
    replacement: PlannedBlockReplacement): Promise<void> {
    const predicates = pageElementPredicates(noteId, replacement.target,
      replacement.text.id, PageElementKind.TEXT);
    const persisted: PersistedElement = { kind: 'text', data: replacement.updatedText };
    const updated: number = await store.update({
      'payload': encodePersistedElement(persisted), 'revision': replacement.target.revision + 1,
    }, predicates);
    if (updated !== 1) {
      throw new Error('original modify-block lost its target text');
    }
  }

  private async moveText(store: relationalStore.RdbStore, noteId: string,
    replacement: PlannedBlockReplacement, mutations: Map<string, PageMutation>): Promise<void> {
    const deleted: number = await store.delete(pageElementPredicates(
      noteId, replacement.target, replacement.text.id, PageElementKind.TEXT));
    if (deleted !== 1) {
      throw new Error('original modify-block lost its source text');
    }
    const mutation: PageMutation | undefined = mutations.get(pageKey(replacement.destination));
    if (mutation === undefined) {
      throw new Error('original modify-block has no destination order');
    }
    const order: number = mutation.rows.findIndex((row: StoredZIndexRow) =>
      row.elementId === replacement.text.id && row.kind === PageElementKind.TEXT);
    if (order < 0) {
      throw new Error('original modify-block destination lost its text');
    }
    const persisted: PersistedElement = { kind: 'text', data: replacement.updatedText };
    const values: relationalStore.ValuesBucket = {
      'note_id': noteId, 'element_id': replacement.text.id, 'kind': PageElementKind.TEXT,
      'payload': encodePersistedElement(persisted),
      'revision': replacement.destination.revision + 1, 'element_order': order,
    };
    if (replacement.destination.archived) {
      values['page_timestamp'] = replacement.destination.page.timestamp;
      values['page_site_id'] = replacement.destination.page.siteId;
      values['page_index'] = replacement.destination.page.index;
    } else {
      values['page_id'] = replacement.destination.pageId;
    }
    await store.insert(replacement.destination.table, values);
    await this.updateTrackedElement(store, noteId, replacement, true);
  }

  private async materializeOrder(store: relationalStore.RdbStore, noteId: string,
    mutation: PageMutation): Promise<void> {
    for (let index: number = 0; index < mutation.rows.length; index++) {
      const row: StoredZIndexRow = mutation.rows[index];
      const updated: number = await store.update({ 'element_order': index },
        pageElementPredicates(noteId, mutation.target, row.elementId, row.kind));
      if (updated !== 1) {
        throw new Error('original modify-block order materialization lost an element');
      }
    }
  }

  private async advanceRevisionAndInvalidateSearch(store: relationalStore.RdbStore,
    noteId: string, target: StoredPageTarget): Promise<void> {
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
      throw new Error('original modify-block page revision changed concurrently');
    }
    if (target.archived) {
      await store.executeSql(
        `DELETE FROM original_deleted_page_search WHERE note_id = ? AND page_timestamp = ?
         AND page_site_id = ? AND page_index = ? AND type = ?`,
        [noteId, target.page.timestamp, target.page.siteId, target.page.index,
          SearchItemType.TEXT_BLOCK]);
    } else {
      await store.executeSql('DELETE FROM search_page_state WHERE note_id = ? AND page_id = ?',
        [noteId, target.pageId]);
      await store.executeSql(
        'DELETE FROM search_item WHERE note_id = ? AND page_id = ? AND type = ?',
        [noteId, target.pageId, SearchItemType.TEXT_BLOCK]);
    }
  }
}

function pageElementPredicates(noteId: string, target: StoredPageTarget,
  elementId: string, kind: number): relationalStore.RdbPredicates {
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
  predicates.equalTo('kind', kind);
  return predicates;
}

function effectivePageOrigin(state: StoredBlockState): OriginalBlockPageOrigin {
  return state.pageOrigin.winner === null ? state.basePageOrigin :
    state.pageOrigin.value as OriginalBlockPageOrigin;
}

function effectiveNullable<T>(base: T | null, register: StoredRegister<T>): T | null {
  return register.winner === null ? base : register.value;
}

function effectiveSize(state: StoredBlockState): OriginalBlockScale {
  return state.size.winner === null ? { x: state.baseWidth, y: state.baseHeight } :
    state.size.value as OriginalBlockScale;
}

function effectiveNumber(base: number, register: StoredRegister<number>): number {
  return register.winner === null ? base : register.value as number;
}

function effectiveBoolean(base: boolean, register: StoredRegister<boolean>): boolean {
  return register.winner === null ? base : register.value as boolean;
}

function effectiveZIndex(state: StoredBlockState): string {
  return state.zIndex.winner === null ? state.baseZIndex : state.zIndex.value as string;
}

function readNumberRegister(rows: relationalStore.ResultSet,
  prefix: string): StoredRegister<number> {
  const winner: OperationIdentity | null = readOptionalWinner(rows, prefix);
  return { value: winner === null ? null : requireValue(
    readNullableLong(rows, `${prefix}_value`), `${prefix} value`), winner: winner };
}

function readBooleanRegister(rows: relationalStore.ResultSet,
  prefix: string): StoredRegister<boolean> {
  const register: StoredRegister<number> = readNumberRegister(rows, prefix);
  if (register.value !== null && register.value !== 0 && register.value !== 1) {
    throw new Error(`original modify-block has an invalid ${prefix} boolean`);
  }
  return { value: register.value === null ? null : register.value !== 0, winner: register.winner };
}

function readOptionalWinner(rows: relationalStore.ResultSet,
  prefix: string): OperationIdentity | null {
  const present: number = rows.getLong(rows.getColumnIndex(`${prefix}_winner_present`));
  if (present === 0) {
    return null;
  }
  if (present !== 1) {
    throw new Error('original modify-block has an invalid winner presence');
  }
  const winner: OperationIdentity = {
    timestamp: requireValue(readNullableLong(rows, `${prefix}_winner_timestamp`), 'winner timestamp'),
    siteId: requireValue(readNullableLong(rows, `${prefix}_winner_site_id`), 'winner site'),
  };
  validateOperationIdentity(winner);
  return winner;
}

function readNullableSequence(rows: relationalStore.ResultSet, timestampColumn: string,
  siteColumn: string, indexColumn: string): OriginalSequenceIdentity | null {
  const timestamp: number | null = readNullableLong(rows, timestampColumn);
  const siteId: number | null = readNullableLong(rows, siteColumn);
  const index: number | null = readNullableLong(rows, indexColumn);
  const count: number = [timestamp, siteId, index]
    .filter((value: number | null) => value !== null).length;
  if (count === 0) {
    return null;
  }
  if (count !== 3) {
    throw new Error('original modify-block has a partial sequence');
  }
  const result: OriginalSequenceIdentity = {
    timestamp: timestamp as number, siteId: siteId as number, index: index as number,
  };
  validateOriginalSequenceIdentity(result);
  return result;
}

function readNullableScale(rows: relationalStore.ResultSet,
  xColumn: string, yColumn: string): OriginalBlockScale | null {
  const x: number | null = readNullableDouble(rows, xColumn);
  const y: number | null = readNullableDouble(rows, yColumn);
  if (x === null && y === null) {
    return null;
  }
  if (x === null || y === null) {
    throw new Error('original modify-block has a partial scale');
  }
  return { x: x, y: y };
}

function isFiniteNullableNumber(value: number | null): boolean {
  return value === null || Number.isFinite(value);
}

function isFiniteNullableScale(value: OriginalBlockScale | null): boolean {
  return value === null || Number.isFinite(value.x) && Number.isFinite(value.y);
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
    throw new Error(`original modify-block has an invalid ${columnName}`);
  }
  return value;
}

function readNullableString(rows: relationalStore.ResultSet, columnName: string): string | null {
  const column: number = rows.getColumnIndex(columnName);
  return rows.isColumnNull(column) ? null : rows.getString(column);
}

function requireValue<T>(value: T | null, label: string): T {
  if (value === null) {
    throw new Error(`original modify-block is missing ${label}`);
  }
  return value;
}

function registerAccepts(operation: OperationIdentity,
  winner: OperationIdentity | null): boolean {
  return winner === null || compareOperationIdentity(operation, winner) > 0;
}

function addWinnerPredicates(predicates: relationalStore.RdbPredicates, prefix: string,
  winner: OperationIdentity | null): void {
  predicates.equalTo(`${prefix}_winner_present`, winner === null ? 0 : 1);
  if (winner !== null) {
    predicates.equalTo(`${prefix}_winner_timestamp`, winner.timestamp);
    predicates.equalTo(`${prefix}_winner_site_id`, winner.siteId);
  }
}

function addWinnerValues(values: relationalStore.ValuesBucket,
  prefix: string, winner: OperationIdentity): void {
  values[`${prefix}_winner_timestamp`] = winner.timestamp;
  values[`${prefix}_winner_site_id`] = winner.siteId;
  values[`${prefix}_winner_present`] = 1;
}

function normalizeOriginalEnum(value: number, maximum: number): number {
  return value >= 0 && value <= maximum ? value : 0;
}

function blockTransform(originX: number, originY: number, rotation: number,
  scaleX: number, scaleY: number): TransformMatrix {
  const cosine: number = Math.cos(rotation);
  const sine: number = Math.sin(rotation);
  return [cosine * scaleX, -sine * scaleY, originX,
    sine * scaleX, cosine * scaleY, originY, 0, 0, 1];
}

function cloneText(text: TextBlockElement): TextBlockElement {
  return {
    id: text.id, type: text.type, transform: text.transform.slice(),
    bounds: { left: text.bounds.left, top: text.bounds.top,
      right: text.bounds.right, bottom: text.bounds.bottom },
    richText: text.richText, textOrigin: { x: text.textOrigin.x, y: text.textOrigin.y },
    blockWidth: text.blockWidth, blockHeight: text.blockHeight,
    rotationRadians: text.rotationRadians, contentLeftInset: text.contentLeftInset,
    contentTopInset: text.contentTopInset, fontSize: text.fontSize, fontColor: text.fontColor,
  };
}

function samePageIdentity(left: OriginalSequenceIdentity,
  right: OriginalSequenceIdentity): boolean {
  return left.timestamp === right.timestamp && left.siteId === right.siteId &&
    left.index === right.index;
}

function pageKey(target: StoredPageTarget): string {
  return `${target.page.timestamp}:${target.page.siteId}:${target.page.index}`;
}

function compareStoredZIndexRows(left: StoredZIndexRow, right: StoredZIndexRow): number {
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
    return Number.isSafeInteger(revision) && revision >= 0 ? revision : null;
  } finally {
    rows.close();
  }
}
