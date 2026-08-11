import { relationalStore } from '@kit.ArkData';
import { PageElementKind } from '../core/model/PageElementOrder';
import {
  encodeOperationId, OperationIdentity, OriginalSequenceIdentity,
  validateOperationIdentity, validateOriginalSequenceIdentity,
} from './OperationIdentity';
import {
  NullableRegisterUpdate, OriginalInkPageOrigin, OriginalInkScale,
  OriginalModifyInkOperationApplier, OriginalModifyInkPayload,
} from './OriginalModifyInkOperation';
import {
  NullableBlockRegisterUpdate, OriginalBlockPageOrigin, OriginalBlockScale,
  OriginalModifyBlockOperationApplier, OriginalModifyBlockPayload,
} from './OriginalModifyBlockOperation';
import {
  OriginalModifyShapePayload, OriginalShapeGroupOperationApplier, OriginalShapeNullableUpdate,
  OriginalShapePageOrigin, OriginalShapeScale,
} from './OriginalShapeGroupOperation';
import { OriginalPageMutationBatch } from './OriginalPageMutationBatch';
import {
  OriginalFlatBufferTableReader, readOriginalInlineFloat32,
  readOriginalInlineUint64Decimal, readOriginalPayloadTable,
} from './OriginalSyncedOperationFlatBuffer';
import {
  StoredSyncedOperation, SyncedOperationApplier, SyncedOperationApplyResult,
} from './SyncedOperationInbox';
import { validateUnsignedLongDecimal } from './UnsignedDecimal';

export const ORIGINAL_MODIFY_POSITIONS_PAYLOAD_TYPE: number = 24;

const MAX_MODIFY_POSITION_COUNT: number = 10000;
const SAVEPOINT_NAME: string = 'original_modify_positions';

export interface OriginalModifyPosition {
  target: OperationIdentity;
  pageOrigin: OriginalInkPageOrigin | null;
  rotation: NullableRegisterUpdate<number>;
  scale: NullableRegisterUpdate<OriginalInkScale>;
  zIndex: string | null;
}

export interface OriginalModifyPositionsPayload {
  modifications: OriginalModifyPosition[];
}

enum PositionTargetType {
  INK = 1,
  BLOCK = 2,
  SHAPE = 3,
}

interface ClassifiedPositionModification {
  modification: OriginalModifyPosition;
  type: PositionTargetType;
}

export function decodeOriginalModifyPositions(bytes: Uint8Array): OriginalModifyPositionsPayload {
  return decodeOriginalModifyPositionsTable(
    readOriginalPayloadTable(bytes, ORIGINAL_MODIFY_POSITIONS_PAYLOAD_TYPE));
}

export function decodeOriginalModifyPositionsTable(
  table: OriginalFlatBufferTableReader): OriginalModifyPositionsPayload {
  const rows: OriginalFlatBufferTableReader[] = table.readTableVector(0, MAX_MODIFY_POSITION_COUNT);
  if (rows.length === 0) {
    throw new Error('original modify-positions has no modifications');
  }
  for (let field: number = 1; field <= 1024; field++) {
    if (table.hasField(field)) {
      throw new Error('original modify-positions has an unknown payload field');
    }
  }
  const identities: Set<string> = new Set<string>();
  const modifications: OriginalModifyPosition[] = [];
  for (const row of rows) {
    const modification: OriginalModifyPosition = decodePosition(row);
    const identity: string = encodeOperationId(modification.target);
    if (identities.has(identity)) {
      throw new Error('original modify-positions repeats a target');
    }
    identities.add(identity);
    modifications.push(modification);
  }
  return { modifications: modifications };
}

export class OriginalModifyPositionsOperationApplier implements SyncedOperationApplier {
  private ink: OriginalModifyInkOperationApplier = new OriginalModifyInkOperationApplier();
  private block: OriginalModifyBlockOperationApplier = new OriginalModifyBlockOperationApplier();
  private shape: OriginalShapeGroupOperationApplier = new OriginalShapeGroupOperationApplier();

  supports(payloadType: number): boolean {
    return payloadType === ORIGINAL_MODIFY_POSITIONS_PAYLOAD_TYPE;
  }

  async apply(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation): Promise<SyncedOperationApplyResult> {
    let table: OriginalFlatBufferTableReader;
    try {
      if (OriginalFlatBufferTableReader.fromRoot(operation.rawOperation).hasField(6)) {
        return { deferredReason: 'TRANSIENT_MODIFY_POSITIONS_UNSUPPORTED' };
      }
      table = readOriginalPayloadTable(operation.rawOperation, ORIGINAL_MODIFY_POSITIONS_PAYLOAD_TYPE);
    } catch (_error) {
      return { deferredReason: 'MALFORMED_MODIFY_POSITIONS_PAYLOAD' };
    }
    return this.applyTable(store, operation, table);
  }

  preflightTable(table: OriginalFlatBufferTableReader, transient: boolean = false): string | null {
    if (transient) {
      return 'TRANSIENT_MODIFY_POSITIONS_UNSUPPORTED';
    }
    let payload: OriginalModifyPositionsPayload;
    try {
      payload = decodeOriginalModifyPositionsTable(table);
    } catch (_error) {
      return 'MALFORMED_MODIFY_POSITIONS_PAYLOAD';
    }
    return preflightModifyPositions(payload);
  }

  async applyTable(store: relationalStore.RdbStore, operation: StoredSyncedOperation,
    table: OriginalFlatBufferTableReader): Promise<SyncedOperationApplyResult> {
    let payload: OriginalModifyPositionsPayload;
    try {
      payload = decodeOriginalModifyPositionsTable(table);
    } catch (_error) {
      return { deferredReason: 'MALFORMED_MODIFY_POSITIONS_PAYLOAD' };
    }
    const preflightReason: string | null = preflightModifyPositions(payload);
    if (preflightReason !== null) {
      return { deferredReason: preflightReason };
    }
    const classified: ClassifiedPositionModification[] | string =
      await this.classifyTargets(store, operation.noteId, payload);
    if (typeof classified === 'string') {
      return { deferredReason: classified };
    }
    return this.applyClassified(store, operation, classified);
  }

  private async applyClassified(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation,
    classified: ClassifiedPositionModification[]): Promise<SyncedOperationApplyResult> {
    let active: boolean = false;
    try {
      await store.executeSql(`SAVEPOINT ${SAVEPOINT_NAME}`);
      active = true;
      const revisionBatch: OriginalPageMutationBatch = new OriginalPageMutationBatch();
      for (const item of classified) {
        let result: SyncedOperationApplyResult;
        if (item.type === PositionTargetType.INK) {
          result = await this.ink.applyPositionPayload(store, operation,
            inkPayload(item.modification), revisionBatch);
        } else if (item.type === PositionTargetType.BLOCK) {
          result = await this.block.applyPositionPayload(store, operation,
            blockPayload(item.modification), revisionBatch);
        } else {
          result = await this.shape.applyPositionPayload(store, operation,
            shapePayload(item.modification), revisionBatch);
        }
        if (result.deferredReason !== null) {
          active = false;
          await rollbackSavepoint(store);
          return result;
        }
      }
      await revisionBatch.flush(store, operation.noteId);
      await store.executeSql(`RELEASE SAVEPOINT ${SAVEPOINT_NAME}`);
      active = false;
      return { deferredReason: null };
    } catch (error) {
      if (active) {
        try {
          await rollbackSavepoint(store);
        } catch (_rollbackError) {
          // Preserve the reducer failure; the inbox transaction remains the final rollback boundary.
        }
      }
      throw new Error(`original MODIFY_POSITIONS apply failed: ${JSON.stringify(error)}`);
    }
  }

  private async classifyTargets(store: relationalStore.RdbStore, noteId: string,
    payload: OriginalModifyPositionsPayload): Promise<ClassifiedPositionModification[] | string> {
    const result: ClassifiedPositionModification[] = [];
    for (const modification of payload.modifications) {
      const rows = await store.querySql(
        `SELECT element.kind,
          EXISTS(SELECT 1 FROM original_ink_state ink WHERE ink.note_id = element.note_id
            AND ink.ink_timestamp = element.element_timestamp
            AND ink.ink_site_id = element.element_site_id) AS has_ink,
          EXISTS(SELECT 1 FROM original_block_state block WHERE block.note_id = element.note_id
            AND block.block_timestamp = element.element_timestamp
            AND block.block_site_id = element.element_site_id) AS has_block,
          EXISTS(SELECT 1 FROM original_shape_state shape WHERE shape.note_id = element.note_id
            AND shape.shape_timestamp = element.element_timestamp
            AND shape.shape_site_id = element.element_site_id) AS has_shape
         FROM original_element_z_index element WHERE element.note_id = ?
           AND element.element_timestamp = ? AND element.element_site_id = ?`,
        [noteId, modification.target.timestamp, modification.target.siteId]);
      try {
        if (!rows.goToFirstRow()) {
          return 'MODIFY_POSITIONS_TARGET_MISSING';
        }
        const kind: number = rows.getLong(rows.getColumnIndex('kind'));
        const hasInk: boolean = rows.getLong(rows.getColumnIndex('has_ink')) === 1;
        const hasBlock: boolean = rows.getLong(rows.getColumnIndex('has_block')) === 1;
        const hasShape: boolean = rows.getLong(rows.getColumnIndex('has_shape')) === 1;
        if (kind === PageElementKind.STROKE && hasInk && !hasBlock && !hasShape) {
          result.push({ modification: modification, type: PositionTargetType.INK });
        } else if ((kind === PageElementKind.TEXT || kind === PageElementKind.IMAGE ||
          kind === PageElementKind.MATH) && hasBlock && !hasInk && !hasShape) {
          result.push({ modification: modification, type: PositionTargetType.BLOCK });
        } else if (kind === PageElementKind.SHAPE && hasShape && !hasInk && !hasBlock) {
          result.push({ modification: modification, type: PositionTargetType.SHAPE });
        } else {
          return 'MODIFY_POSITIONS_TARGET_STATE_DIVERGED';
        }
      } finally {
        rows.close();
      }
    }
    return result;
  }
}

function decodePosition(table: OriginalFlatBufferTableReader): OriginalModifyPosition {
  for (let field: number = 6; field <= 1024; field++) {
    if (table.hasField(field)) {
      throw new Error('original modify-position has an unknown field');
    }
  }
  const targetBytes: Uint8Array | null = table.readInlineBytes(0, 8);
  if (targetBytes === null) {
    throw new Error('original modify-position has no target');
  }
  const target: OperationIdentity = {
    siteId: targetBytes[0] + targetBytes[1] * 0x100,
    timestamp: readUint32(targetBytes, 4),
  };
  validateOperationIdentity(target);
  const rawPage: number[] | null = table.readInlineSequence(1);
  const originBytes: Uint8Array | null = table.readInlineBytes(2, 8);
  if ((rawPage === null) !== (originBytes === null)) {
    throw new Error('original modify-position must pair page and origin');
  }
  let pageOrigin: OriginalInkPageOrigin | null = null;
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
  const rotationSetter: OriginalFlatBufferTableReader | null = table.readTable(3);
  const scaleSetter: OriginalFlatBufferTableReader | null = table.readTable(4);
  const scaleBytes: Uint8Array | null = scaleSetter === null ? null :
    scaleSetter.readInlineBytes(0, 8);
  const zIndexBytes: Uint8Array | null = table.readInlineBytes(5, 8);
  const zIndex: string | null = zIndexBytes === null ? null :
    readOriginalInlineUint64Decimal(zIndexBytes, 0);
  if (zIndex !== null) {
    validateUnsignedLongDecimal(zIndex);
  }
  return {
    target: target,
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
    zIndex: zIndex,
  };
}

function preflightModifyPositions(payload: OriginalModifyPositionsPayload): string | null {
  for (const modification of payload.modifications) {
    if ((modification.pageOrigin !== null &&
      (!Number.isFinite(modification.pageOrigin.originX) ||
        !Number.isFinite(modification.pageOrigin.originY))) ||
      (modification.rotation.value !== null && !Number.isFinite(modification.rotation.value)) ||
      (modification.scale.value !== null &&
        (!Number.isFinite(modification.scale.value.x) ||
          !Number.isFinite(modification.scale.value.y)))) {
      return 'MODIFY_POSITIONS_GEOMETRY_UNSUPPORTED';
    }
  }
  return null;
}

function inkPayload(modification: OriginalModifyPosition): OriginalModifyInkPayload {
  return {
    inks: [modification.target], pageOrigin: modification.pageOrigin,
    rotation: modification.rotation, scale: modification.scale,
    style: null, color: null, width: null, centerPath: null,
    customPath: { present: false, value: null },
    fillPath: { present: false, value: null },
    fillColor: { present: false, value: null },
    styleMap: { present: false, value: null },
    zIndex: modification.zIndex, nibAngle: null, nibFlatness: null,
    tapePattern: null, inkEffects: null, inkEffectsTinted: null,
  };
}

function blockPayload(modification: OriginalModifyPosition): OriginalModifyBlockPayload {
  const pageOrigin: OriginalBlockPageOrigin | null = modification.pageOrigin === null ? null : {
    page: modification.pageOrigin.page,
    originX: modification.pageOrigin.originX,
    originY: modification.pageOrigin.originY,
  };
  const rotation: NullableBlockRegisterUpdate<number> = {
    present: modification.rotation.present,
    value: modification.rotation.value,
  };
  const scale: NullableBlockRegisterUpdate<OriginalBlockScale> = {
    present: modification.scale.present,
    value: modification.scale.value === null ? null : {
      x: modification.scale.value.x,
      y: modification.scale.value.y,
    },
  };
  return {
    blocks: [modification.target], corner: null, pageOrigin: pageOrigin,
    rotation: rotation, scale: scale, width: null, height: null,
    textWrap: null, enableCaption: null,
    paper: { present: false, value: null }, resizesWidthToFitText: null,
    cropRect: { present: false, value: null },
    imageFlippedHorizontally: null, imageFlippedVertically: null,
    zIndex: modification.zIndex, positionLocked: null,
    mathLatex: { present: false, value: null },
    mathColor: { present: false, value: null },
  };
}

function shapePayload(modification: OriginalModifyPosition): OriginalModifyShapePayload {
  const pageOrigin: OriginalShapePageOrigin | null = modification.pageOrigin === null ? null : {
    page: modification.pageOrigin.page,
    x: modification.pageOrigin.originX,
    y: modification.pageOrigin.originY,
  };
  const rotation: OriginalShapeNullableUpdate<number> = {
    present: modification.rotation.present,
    value: modification.rotation.value,
  };
  const scale: OriginalShapeNullableUpdate<OriginalShapeScale> = {
    present: modification.scale.present,
    value: modification.scale.value === null ? null : {
      x: modification.scale.value.x,
      y: modification.scale.value.y,
    },
  };
  return {
    shapes: [modification.target],
    pageOrigin: pageOrigin,
    rotation: rotation, scale: scale,
    definition: { present: false, value: null }, tool: null, style: null,
    tapePattern: null, color: null, borderWidth: null,
    fillColor: { present: false, value: null }, zIndex: modification.zIndex,
    positionLocked: null, inkEffects: null, inkEffectsTinted: null,
  };
}

async function rollbackSavepoint(store: relationalStore.RdbStore): Promise<void> {
  await store.executeSql(`ROLLBACK TO SAVEPOINT ${SAVEPOINT_NAME}`);
  await store.executeSql(`RELEASE SAVEPOINT ${SAVEPOINT_NAME}`);
}

function readUint32(bytes: Uint8Array, offset: number): number {
  return bytes[offset] + bytes[offset + 1] * 0x100 + bytes[offset + 2] * 0x10000 +
    bytes[offset + 3] * 0x1000000;
}
