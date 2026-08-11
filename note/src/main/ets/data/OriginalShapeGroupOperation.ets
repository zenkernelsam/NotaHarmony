import { relationalStore } from '@kit.ArkData';
import {
  ElementType, EllipseElement, LineElement, PolygonElement, RichTextCharacterStyle,
  RichTextCharacterStyleRun, RichTextParagraphStyle, RichTextParagraphStyleRun,
  ShapeArrowHead, ShapeElement,
} from '../core/model/ElementTypes';
import { Point2D, Rect2D, TransformMatrix } from '../core/model/GeometryTypes';
import { PageElementKind } from '../core/model/PageElementOrder';
import { recomputeShapeBounds } from '../core/model/ShapeGeometry';
import {
  compareOperationIdentity, encodeOperationId, OperationIdentity, OriginalSequenceIdentity,
  validateOperationIdentity, validateOriginalSequenceIdentity,
} from './OperationIdentity';
import { readOriginalEntityVisibilityWinner } from './OriginalEntityVisibilityState';
import { OriginalPageMutationBatch, OriginalMutationPageTarget } from './OriginalPageMutationBatch';
import {
  OriginalFlatBufferTableReader, readOriginalInlineFloat32, readOriginalPayloadTable,
} from './OriginalSyncedOperationFlatBuffer';
import { decodePersistedElement, encodePersistedElement, PersistedElement } from './StrokePersistence';
import {
  StoredSyncedOperation, SyncedOperationApplier, SyncedOperationApplyResult,
} from './SyncedOperationInbox';
import { compareUnsignedLongDecimal, validateUnsignedLongDecimal } from './UnsignedDecimal';
import {
  originalGroupLayerRanks, OriginalLayeringEntity, refreshOriginalGroupLayeredOrder,
} from './OriginalGroupLayering';

export const ORIGINAL_CREATE_SHAPE_PAYLOAD_TYPE: number = 18;
export const ORIGINAL_MODIFY_SHAPE_PAYLOAD_TYPE: number = 19;
export const ORIGINAL_CREATE_GROUP_PAYLOAD_TYPE: number = 20;
export const ORIGINAL_MODIFY_GROUP_PAYLOAD_TYPE: number = 21;

const MAX_SHAPE_TARGETS: number = 10000;
const MAX_SHAPE_POINTS: number = 100000;
const MAX_GROUP_MEMBERS: number = 10000;

export enum OriginalShapeDefinitionType {
  NONE = 0,
  LINE = 1,
  POLYGON = 2,
  ELLIPSE = 3,
}

export interface OriginalShapePoint { x: number; y: number; }
export interface OriginalShapeScale { x: number; y: number; }

export interface OriginalLineDefinition {
  type: OriginalShapeDefinitionType.LINE;
  start: OriginalShapePoint;
  controlPoint1: OriginalShapePoint | null;
  controlPoint2: OriginalShapePoint | null;
  end: OriginalShapePoint;
  arrowHead: number;
}

export interface OriginalPolygonDefinition {
  type: OriginalShapeDefinitionType.POLYGON;
  points: OriginalShapePoint[];
}

export interface OriginalEllipseDefinition {
  type: OriginalShapeDefinitionType.ELLIPSE;
  width: number;
  height: number;
}

export type OriginalShapeDefinition = OriginalLineDefinition | OriginalPolygonDefinition |
  OriginalEllipseDefinition;

export interface OriginalCreateShapePayload {
  page: OriginalSequenceIdentity;
  originX: number;
  originY: number;
  rotation: number | null;
  scale: OriginalShapeScale | null;
  definition: OriginalShapeDefinition;
  tool: number;
  style: number;
  tapePattern: number | null;
  color: number;
  borderWidth: number;
  fillColor: number | null;
  zIndex: string;
  smartHighlight: boolean;
  force: number | null;
  positionLocked: boolean;
  inkEffects: string;
  inkEffectsTinted: boolean;
}

export interface OriginalShapeNullableUpdate<T> { present: boolean; value: T | null; }

export interface OriginalShapePageOrigin {
  page: OriginalSequenceIdentity;
  x: number;
  y: number;
}

export interface OriginalModifyShapePayload {
  shapes: OperationIdentity[];
  pageOrigin: OriginalShapePageOrigin | null;
  rotation: OriginalShapeNullableUpdate<number>;
  scale: OriginalShapeNullableUpdate<OriginalShapeScale>;
  definition: OriginalShapeNullableUpdate<OriginalShapeDefinition>;
  tool: number | null;
  style: number | null;
  tapePattern: number | null;
  color: number | null;
  borderWidth: number | null;
  fillColor: OriginalShapeNullableUpdate<number>;
  zIndex: string | null;
  positionLocked: boolean | null;
  inkEffects: string | null;
  inkEffectsTinted: boolean | null;
}

export interface OriginalCreateGroupPayload { members: OperationIdentity[]; }
export interface OriginalModifyGroupPayload {
  group: OperationIdentity;
  members: OperationIdentity[];
}

interface ShapeWinner extends OperationIdentity { field: string; }
interface StoredShapeState {
  create: OriginalCreateShapePayload;
  resolved: OriginalCreateShapePayload;
  winners: ShapeWinner[];
}

interface StoredShapeTarget {
  shape: OperationIdentity;
  page: OriginalSequenceIdentity;
  pageId: string;
  kind: number;
  visible: boolean;
  target: OriginalMutationPageTarget;
}

interface StoredOrderRow extends OperationIdentity {
  elementId: string;
  kind: number;
  zIndex: string;
}

export function decodeOriginalCreateShape(bytes: Uint8Array,
  defaultZIndex: string): OriginalCreateShapePayload {
  return decodeOriginalCreateShapeTable(
    readOriginalPayloadTable(bytes, ORIGINAL_CREATE_SHAPE_PAYLOAD_TYPE), defaultZIndex);
}

export function decodeOriginalCreateShapeTable(table: OriginalFlatBufferTableReader,
  defaultZIndex: string): OriginalCreateShapePayload {
  rejectFieldsFrom(table, 18, 'CreateShape payload');
  const page: number[] | null = table.readInlineSequence(0);
  const origin: Uint8Array | null = table.readInlineBytes(1, 8);
  const definitionType: number = table.readUint8(4, OriginalShapeDefinitionType.NONE);
  const definitionTable: OriginalFlatBufferTableReader | null = table.readTable(5);
  const color: Uint8Array | null = table.readInlineBytes(9, 4);
  if (page === null || origin === null || definitionTable === null || color === null) {
    throw new Error('CreateShape is missing a required field');
  }
  const pageIdentity: OriginalSequenceIdentity = sequenceIdentity(page);
  const scaleBytes: Uint8Array | null = table.readInlineBytes(3, 8);
  const fillBytes: Uint8Array | null = table.readInlineBytes(11, 4);
  const zIndex: string = table.readUint64Decimal(12, defaultZIndex) as string;
  const inkEffects: string = table.readUint64Decimal(16, '0') as string;
  validateUnsignedLongDecimal(zIndex);
  validateUnsignedLongDecimal(inkEffects);
  const payload: OriginalCreateShapePayload = {
    page: pageIdentity,
    originX: readOriginalInlineFloat32(origin, 0),
    originY: readOriginalInlineFloat32(origin, 4),
    rotation: table.hasField(2) ? table.readFloat32(2, 0) : null,
    scale: scaleBytes === null ? null : pointScale(scaleBytes),
    definition: decodeDefinition(definitionType, definitionTable),
    tool: table.readUint8(6, 0),
    style: table.readUint8(7, 1),
    tapePattern: table.hasField(8) ? table.readUint8(8, 0) : null,
    color: originalColorToArgb(color),
    borderWidth: table.readFloat32(10, 4),
    fillColor: fillBytes === null ? null : originalColorToArgb(fillBytes),
    zIndex: zIndex,
    smartHighlight: table.readUint8(13, 0) !== 0,
    force: table.hasField(14) ? table.readFloat32(14, 0) : null,
    positionLocked: table.readUint8(15, 0) !== 0,
    inkEffects: inkEffects,
    inkEffectsTinted: table.readUint8(17, 1) !== 0,
  };
  validateCreateShape(payload, fillBytes);
  return payload;
}

export function decodeOriginalModifyShape(bytes: Uint8Array): OriginalModifyShapePayload {
  return decodeOriginalModifyShapeTable(
    readOriginalPayloadTable(bytes, ORIGINAL_MODIFY_SHAPE_PAYLOAD_TYPE));
}

export function decodeOriginalModifyShapeTable(
  table: OriginalFlatBufferTableReader): OriginalModifyShapePayload {
  rejectFieldsFrom(table, 17, 'ModifyShape payload');
  const shapes: OperationIdentity[] = identities(
    table.readInlineOperationIdentityVector(0, MAX_SHAPE_TARGETS), 'ModifyShape');
  if (shapes.length === 0) {
    throw new Error('ModifyShape has no targets');
  }
  const rawPage: number[] | null = table.readInlineSequence(1);
  const rawOrigin: Uint8Array | null = table.readInlineBytes(2, 8);
  if ((rawPage === null) !== (rawOrigin === null)) {
    throw new Error('ModifyShape must specify page and origin together');
  }
  const rotationTable: OriginalFlatBufferTableReader | null = table.readTable(3);
  const scaleTable: OriginalFlatBufferTableReader | null = table.readTable(4);
  const definitionTypePresent: boolean = table.hasField(5);
  const definitionType: number = table.readUint8(5, OriginalShapeDefinitionType.NONE);
  const definitionTable: OriginalFlatBufferTableReader | null = table.readTable(6);
  if (!definitionTypePresent && definitionTable !== null) {
    throw new Error('ModifyShape definition has no discriminator');
  }
  const colorBytes: Uint8Array | null = table.readInlineBytes(10, 4);
  const fillSetter: OriginalFlatBufferTableReader | null = table.readTable(12);
  const fillBytes: Uint8Array | null = fillSetter === null ? null : fillSetter.readInlineBytes(0, 4);
  const inkEffects: string | null = table.readUint64Decimal(15, null);
  const zIndex: string | null = table.readUint64Decimal(13, null);
  if (inkEffects !== null) {
    validateUnsignedLongDecimal(inkEffects);
  }
  if (zIndex !== null) {
    validateUnsignedLongDecimal(zIndex);
  }
  const scaleBytes: Uint8Array | null = scaleTable === null ? null :
    scaleTable.readInlineBytes(0, 8);
  const payload: OriginalModifyShapePayload = {
    shapes: shapes,
    pageOrigin: rawPage === null || rawOrigin === null ? null : {
      page: sequenceIdentity(rawPage), x: readOriginalInlineFloat32(rawOrigin, 0),
      y: readOriginalInlineFloat32(rawOrigin, 4),
    },
    rotation: { present: rotationTable !== null,
      value: rotationTable === null || !rotationTable.hasField(0) ? null :
        rotationTable.readFloat32(0, 0) },
    scale: { present: scaleTable !== null,
      value: scaleBytes === null ? null : pointScale(scaleBytes) },
    definition: { present: definitionTypePresent,
      value: !definitionTypePresent || definitionType === OriginalShapeDefinitionType.NONE ? null :
        decodeRequiredDefinition(definitionType, definitionTable) },
    tool: table.hasField(7) ? table.readUint8(7, 0) : null,
    style: table.hasField(8) ? table.readUint8(8, 0) : null,
    tapePattern: table.hasField(9) ? table.readUint8(9, 0) : null,
    color: colorBytes === null ? null : originalColorToArgb(colorBytes),
    borderWidth: table.hasField(11) ? table.readFloat32(11, 0) : null,
    fillColor: { present: fillSetter !== null,
      value: fillBytes === null ? null : originalColorToArgb(fillBytes) },
    zIndex: zIndex,
    positionLocked: table.hasField(14) ? table.readUint8(14, 0) !== 0 : null,
    inkEffects: inkEffects,
    inkEffectsTinted: table.hasField(16) ? table.readUint8(16, 0) !== 0 : null,
  };
  validateModifyShape(payload, fillBytes);
  return payload;
}

export function decodeOriginalCreateGroup(bytes: Uint8Array): OriginalCreateGroupPayload {
  return decodeOriginalCreateGroupTable(
    readOriginalPayloadTable(bytes, ORIGINAL_CREATE_GROUP_PAYLOAD_TYPE));
}

export function decodeOriginalCreateGroupTable(
  table: OriginalFlatBufferTableReader): OriginalCreateGroupPayload {
  rejectFieldsFrom(table, 1, 'CreateGroup payload');
  const members: OperationIdentity[] = identities(
    table.readInlineOperationIdentityVector(0, MAX_GROUP_MEMBERS), 'CreateGroup', false);
  if (members.length === 0) {
    throw new Error('CreateGroup has no members');
  }
  return { members: members };
}

export function decodeOriginalModifyGroup(bytes: Uint8Array): OriginalModifyGroupPayload {
  return decodeOriginalModifyGroupTable(
    readOriginalPayloadTable(bytes, ORIGINAL_MODIFY_GROUP_PAYLOAD_TYPE));
}

export function decodeOriginalModifyGroupTable(
  table: OriginalFlatBufferTableReader): OriginalModifyGroupPayload {
  rejectFieldsFrom(table, 2, 'ModifyGroup payload');
  const rawGroup: Uint8Array | null = table.readInlineBytes(0, 8);
  if (rawGroup === null) {
    throw new Error('ModifyGroup target is missing');
  }
  const members: OperationIdentity[] = identities(
    table.readInlineOperationIdentityVector(1, MAX_GROUP_MEMBERS), 'ModifyGroup', false);
  if (members.length === 0) {
    throw new Error('ModifyGroup has no members');
  }
  return { group: identityFromBytes(rawGroup), members: members };
}

export class OriginalShapeGroupOperationApplier implements SyncedOperationApplier {
  supports(payloadType: number): boolean {
    return payloadType >= ORIGINAL_CREATE_SHAPE_PAYLOAD_TYPE &&
      payloadType <= ORIGINAL_MODIFY_GROUP_PAYLOAD_TYPE;
  }

  async apply(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation): Promise<SyncedOperationApplyResult> {
    let table: OriginalFlatBufferTableReader;
    try {
      table = readOriginalPayloadTable(operation.rawOperation, operation.payloadType);
    } catch (_error) {
      return { deferredReason: 'MALFORMED_SHAPE_GROUP_PAYLOAD' };
    }
    return this.applyTable(store, operation, table);
  }

  preflightTable(table: OriginalFlatBufferTableReader, payloadType: number,
    defaultZIndex: string): string | null {
    try {
      this.decodeTable(table, payloadType, defaultZIndex);
      return null;
    } catch (_error) {
      return 'MALFORMED_SHAPE_GROUP_PAYLOAD';
    }
  }

  async applyTable(store: relationalStore.RdbStore, operation: StoredSyncedOperation,
    table: OriginalFlatBufferTableReader): Promise<SyncedOperationApplyResult> {
    try {
      validateOperationIdentity(operation);
    } catch (_error) {
      return { deferredReason: 'MALFORMED_SHAPE_GROUP_PAYLOAD' };
    }
    let payload: Object;
    try {
      payload = this.decodeTable(table, operation.payloadType, operation.clientTime);
    } catch (_error) {
      return { deferredReason: 'MALFORMED_SHAPE_GROUP_PAYLOAD' };
    }
    try {
      if (operation.payloadType === ORIGINAL_CREATE_SHAPE_PAYLOAD_TYPE) {
        return this.applyCreateShape(store, operation, payload as OriginalCreateShapePayload);
      }
      if (operation.payloadType === ORIGINAL_MODIFY_SHAPE_PAYLOAD_TYPE) {
        return this.applyModifyShape(store, operation, payload as OriginalModifyShapePayload);
      }
      if (operation.payloadType === ORIGINAL_CREATE_GROUP_PAYLOAD_TYPE) {
        return this.applyCreateGroup(store, operation, payload as OriginalCreateGroupPayload);
      }
      if (operation.payloadType === ORIGINAL_MODIFY_GROUP_PAYLOAD_TYPE) {
        return this.applyModifyGroup(store, operation, payload as OriginalModifyGroupPayload);
      }
      return { deferredReason: 'SHAPE_GROUP_PAYLOAD_TYPE_UNSUPPORTED' };
    } catch (error) {
      if (error instanceof ShapeGroupDeferredError) {
        return { deferredReason: error.reason };
      }
      throw new Error(`original Shape/Group apply failed: ${JSON.stringify(error)}`);
    }
  }

  private decodeTable(table: OriginalFlatBufferTableReader, payloadType: number,
    defaultZIndex: string): Object {
    if (payloadType === ORIGINAL_CREATE_SHAPE_PAYLOAD_TYPE) {
      return decodeOriginalCreateShapeTable(table, defaultZIndex);
    }
    if (payloadType === ORIGINAL_MODIFY_SHAPE_PAYLOAD_TYPE) {
      return decodeOriginalModifyShapeTable(table);
    }
    if (payloadType === ORIGINAL_CREATE_GROUP_PAYLOAD_TYPE) {
      return decodeOriginalCreateGroupTable(table);
    }
    if (payloadType === ORIGINAL_MODIFY_GROUP_PAYLOAD_TYPE) {
      return decodeOriginalModifyGroupTable(table);
    }
    throw new Error('unsupported Shape/Group payload type');
  }

  private async applyCreateShape(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation,
    payload: OriginalCreateShapePayload): Promise<SyncedOperationApplyResult> {
    const signature: string = JSON.stringify(payload);
    const existing: string | null = await scalarString(store,
      `SELECT create_signature FROM original_shape_state WHERE note_id = ?
       AND shape_timestamp = ? AND shape_site_id = ?`,
      [operation.noteId, operation.timestamp, operation.siteId]);
    if (existing !== null) {
      if (existing !== signature) {
        throw new Error('original CreateShape identity conflicts with persisted state');
      }
      return { deferredReason: null };
    }
    const target: OriginalMutationPageTarget | null = await readPageTarget(
      store, operation.noteId, payload.page);
    if (target === null) {
      return { deferredReason: 'CREATE_SHAPE_PAGE_MISSING_OR_UNBOUND' };
    }
    if (!await pageCoverageIsComplete(store, operation.noteId, target)) {
      return { deferredReason: 'CREATE_SHAPE_ELEMENT_ORDER_DIVERGED' };
    }
    const visibility = await readOriginalEntityVisibilityWinner(store, operation.noteId, operation);
    const hidden: boolean = visibility !== null && visibility.deleted;
    if (!hidden && target.revision >= Number.MAX_SAFE_INTEGER) {
      return { deferredReason: 'CREATE_SHAPE_PAGE_REVISION_EXHAUSTED' };
    }
    const shape: ShapeElement = materializeShape(operation, payload);
    let rows: StoredOrderRow[];
    try {
      rows = await readOriginalOrder(store, operation.noteId, payload.page);
    } catch (_error) {
      return { deferredReason: 'CREATE_SHAPE_GROUP_LAYERING_DIVERGED' };
    }
    rows.push({ timestamp: operation.timestamp, siteId: operation.siteId,
      elementId: shape.id, kind: PageElementKind.SHAPE, zIndex: payload.zIndex });
    if (!await sortOrderRows(store, operation.noteId, rows)) {
      return { deferredReason: 'CREATE_SHAPE_GROUP_LAYERING_DIVERGED' };
    }
    await store.insert('original_element_z_index', {
      'note_id': operation.noteId, 'element_timestamp': operation.timestamp,
      'element_site_id': operation.siteId, 'page_timestamp': payload.page.timestamp,
      'page_site_id': payload.page.siteId, 'page_index': payload.page.index,
      'kind': PageElementKind.SHAPE, 'visible': hidden ? 0 : 1, 'z_index': payload.zIndex,
    });
    await store.insert('original_shape_state', {
      'note_id': operation.noteId, 'shape_timestamp': operation.timestamp,
      'shape_site_id': operation.siteId, 'create_payload': signature,
      'resolved_payload': signature, 'register_winners': '[]', 'create_signature': signature,
    });
    const persisted: PersistedElement = { kind: 'shape', data: shape };
    if (hidden) {
      await store.insert('original_deleted_entity', {
        'note_id': operation.noteId, 'entity_timestamp': operation.timestamp,
        'entity_site_id': operation.siteId, 'page_timestamp': payload.page.timestamp,
        'page_site_id': payload.page.siteId, 'page_index': payload.page.index,
        'element_id': shape.id, 'kind': PageElementKind.SHAPE,
        'payload': encodePersistedElement(persisted), 'revision': target.revision,
        'element_order': orderIndex(rows, shape.id, PageElementKind.SHAPE),
      });
      return { deferredReason: null };
    }
    await insertPageElement(store, operation.noteId, target, shape.id,
      encodePersistedElement(persisted), target.revision + 1);
    await assignPageOrder(store, operation.noteId, target);
    const batch: OriginalPageMutationBatch = new OriginalPageMutationBatch();
    batch.recordBlock(target, false);
    await batch.flush(store, operation.noteId);
    return { deferredReason: null };
  }

  private async applyModifyShape(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation,
    payload: OriginalModifyShapePayload,
    revisionBatch: OriginalPageMutationBatch | null = null,
    journal: boolean = true): Promise<SyncedOperationApplyResult> {
    const signature: string = JSON.stringify(payload);
    const previous: string | null = journal ? await scalarString(store,
      `SELECT payload_signature FROM original_shape_modification WHERE note_id = ?
       AND operation_timestamp = ? AND operation_site_id = ?`,
      [operation.noteId, operation.timestamp, operation.siteId]) : null;
    if (previous !== null) {
      if (previous !== signature) {
        throw new Error('original ModifyShape identity conflicts with persisted state');
      }
      return { deferredReason: null };
    }
    const states: StoredShapeState[] = [];
    const targets: StoredShapeTarget[] = [];
    const snapshots: ShapeElement[] = [];
    const pageTargets: Map<string, OriginalMutationPageTarget> =
      new Map<string, OriginalMutationPageTarget>();
    for (const shape of payload.shapes) {
      const state: StoredShapeState | null = await readShapeState(store, operation.noteId, shape);
      const target: StoredShapeTarget | null = await readShapeTarget(store, operation.noteId, shape);
      if (state === null || target === null) {
        return { deferredReason: 'MODIFY_SHAPE_TARGET_MISSING_OR_UNBOUND' };
      }
      const snapshot: ShapeElement | null = await readMaterializedShape(
        store, operation.noteId, target);
      if (snapshot === null) {
        return { deferredReason: 'MODIFY_SHAPE_SNAPSHOT_DIVERGED' };
      }
      states.push(state);
      targets.push(target);
      snapshots.push(snapshot);
      if (target.visible) {
        pageTargets.set(pageKey(target.page), target.target);
      }
      if (payload.pageOrigin !== null) {
        const destination: OriginalMutationPageTarget | null = await readPageTarget(
          store, operation.noteId, payload.pageOrigin.page);
        if (destination === null) {
          return { deferredReason: 'MODIFY_SHAPE_PAGE_MISSING_OR_UNBOUND' };
        }
        if (target.visible) {
          pageTargets.set(pageKey(payload.pageOrigin.page), destination);
        }
      }
    }
    for (const target of pageTargets.values()) {
      if (target.revision >= Number.MAX_SAFE_INTEGER) {
        return { deferredReason: 'MODIFY_SHAPE_PAGE_REVISION_EXHAUSTED' };
      }
      if (!await pageCoverageIsComplete(store, operation.noteId, target)) {
        return { deferredReason: 'MODIFY_SHAPE_ELEMENT_ORDER_DIVERGED' };
      }
    }
    if (journal) {
      await store.insert('original_shape_modification', {
        'note_id': operation.noteId, 'operation_timestamp': operation.timestamp,
        'operation_site_id': operation.siteId, 'payload_signature': signature,
      });
    }
    const changedPages: Map<string, OriginalMutationPageTarget> =
      new Map<string, OriginalMutationPageTarget>();
    for (let index: number = 0; index < payload.shapes.length; index++) {
      const shape: OperationIdentity = payload.shapes[index];
      const state: StoredShapeState = states[index];
      const target: StoredShapeTarget = targets[index];
      const changed: boolean = applyShapeRegisters(state, payload, operation);
      if (!changed) {
        continue;
      }
      const oldPage: OriginalSequenceIdentity = target.page;
      const newPage: OriginalSequenceIdentity = state.resolved.page;
      const shapeElement: ShapeElement = materializeShape(shape, state.resolved);
      copyShapeRichText(shapeElement, snapshots[index]);
      const persisted: PersistedElement = { kind: 'shape', data: shapeElement };
      await updateShapeState(store, operation.noteId, shape, state);
      await updateShapeOrderState(store, operation.noteId, shape, target,
        newPage, state.resolved.zIndex);
      if (!target.visible) {
        await updateHiddenShape(store, operation.noteId, shape, newPage,
          encodePersistedElement(persisted));
        continue;
      }
      const destination: OriginalMutationPageTarget | undefined = pageTargets.get(pageKey(newPage));
      if (destination === undefined) {
        throw new Error('visible original Shape destination disappeared after preflight');
      }
      await removeActiveShape(store, operation.noteId, target);
      await insertPageElement(store, operation.noteId, destination, shapeElement.id,
        encodePersistedElement(persisted), destination.revision + 1);
      changedPages.set(pageKey(oldPage), pageTargets.get(pageKey(oldPage)) as OriginalMutationPageTarget);
      changedPages.set(pageKey(newPage), destination);
    }
    const batch: OriginalPageMutationBatch = revisionBatch === null ?
      new OriginalPageMutationBatch() : revisionBatch;
    for (const target of changedPages.values()) {
      await assignPageOrder(store, operation.noteId, target);
      batch.recordBlock(target, false);
    }
    if (revisionBatch === null) {
      await batch.flush(store, operation.noteId);
    }
    return { deferredReason: null };
  }

  async applyPositionPayload(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation, payload: OriginalModifyShapePayload,
    revisionBatch: OriginalPageMutationBatch): Promise<SyncedOperationApplyResult> {
    return this.applyModifyShape(store, operation, payload, revisionBatch, false);
  }

  private async applyCreateGroup(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation,
    payload: OriginalCreateGroupPayload): Promise<SyncedOperationApplyResult> {
    const signature: string = JSON.stringify(payload.members);
    const existing = await store.querySql(
      `SELECT create_signature, z_index FROM original_group_state WHERE note_id = ?
       AND group_timestamp = ? AND group_site_id = ?`,
      [operation.noteId, operation.timestamp, operation.siteId]);
    try {
      if (existing.goToFirstRow()) {
        if (existing.getString(existing.getColumnIndex('create_signature')) !== signature) {
          throw new Error('original CreateGroup identity conflicts with persisted state');
        }
        if (existing.isColumnNull(existing.getColumnIndex('z_index'))) {
          const predicates = new relationalStore.RdbPredicates('original_group_state');
          predicates.equalTo('note_id', operation.noteId);
          predicates.equalTo('group_timestamp', operation.timestamp);
          predicates.equalTo('group_site_id', operation.siteId);
          if (await store.update({ 'z_index': operation.clientTime }, predicates) !== 1) {
            throw new Error('original CreateGroup legacy z-index backfill changed concurrently');
          }
        } else if (existing.getString(existing.getColumnIndex('z_index')) !== operation.clientTime) {
          throw new Error('original CreateGroup z-index conflicts with persisted state');
        }
        if (!await refreshOriginalGroupLayeredOrder(store, operation.noteId)) {
          throw new Error('original CreateGroup layering diverged');
        }
        return { deferredReason: null };
      }
    } finally {
      existing.close();
    }
    try {
      validateUnsignedLongDecimal(operation.clientTime);
    } catch (_error) {
      return { deferredReason: 'MALFORMED_CREATE_GROUP_CLIENT_TIME' };
    }
    await store.insert('original_group_state', {
      'note_id': operation.noteId, 'group_timestamp': operation.timestamp,
      'group_site_id': operation.siteId, 'create_members': signature,
      'members_value': signature, 'members_winner_timestamp': 0,
      'members_winner_site_id': 0, 'members_winner_present': 0,
      'z_index': operation.clientTime, 'create_signature': signature,
    });
    if (!await refreshOriginalGroupLayeredOrder(store, operation.noteId)) {
      throw new Error('original CreateGroup layering diverged');
    }
    return { deferredReason: null };
  }

  private async applyModifyGroup(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation,
    payload: OriginalModifyGroupPayload): Promise<SyncedOperationApplyResult> {
    const signature: string = JSON.stringify(payload);
    const previous: string | null = await scalarString(store,
      `SELECT payload_signature FROM original_group_modification WHERE note_id = ?
       AND operation_timestamp = ? AND operation_site_id = ?`,
      [operation.noteId, operation.timestamp, operation.siteId]);
    if (previous !== null) {
      if (previous !== signature) {
        throw new Error('original ModifyGroup identity conflicts with persisted state');
      }
      return { deferredReason: null };
    }
    const rows = await store.querySql(
      `SELECT members_winner_timestamp, members_winner_site_id, members_winner_present
       FROM original_group_state WHERE note_id = ? AND group_timestamp = ? AND group_site_id = ?`,
      [operation.noteId, payload.group.timestamp, payload.group.siteId]);
    let applies: boolean;
    try {
      if (!rows.goToFirstRow()) {
        return { deferredReason: 'MODIFY_GROUP_TARGET_MISSING' };
      }
      applies = rows.getLong(rows.getColumnIndex('members_winner_present')) === 0 ||
        compareOperationIdentity(operation, {
          timestamp: rows.getLong(rows.getColumnIndex('members_winner_timestamp')),
          siteId: rows.getLong(rows.getColumnIndex('members_winner_site_id')),
        }) > 0;
    } finally {
      rows.close();
    }
    await store.insert('original_group_modification', {
      'note_id': operation.noteId, 'operation_timestamp': operation.timestamp,
      'operation_site_id': operation.siteId, 'group_timestamp': payload.group.timestamp,
      'group_site_id': payload.group.siteId, 'payload_signature': signature,
    });
    if (applies) {
      const predicates = new relationalStore.RdbPredicates('original_group_state');
      predicates.equalTo('note_id', operation.noteId);
      predicates.equalTo('group_timestamp', payload.group.timestamp);
      predicates.equalTo('group_site_id', payload.group.siteId);
      if (await store.update({
        'members_value': JSON.stringify(payload.members),
        'members_winner_timestamp': operation.timestamp,
        'members_winner_site_id': operation.siteId, 'members_winner_present': 1,
      }, predicates) !== 1) {
        throw new Error('original group members changed concurrently');
      }
      if (!await refreshOriginalGroupLayeredOrder(store, operation.noteId)) {
        throw new Error('original ModifyGroup layering diverged');
      }
    }
    return { deferredReason: null };
  }
}

function applyShapeRegisters(state: StoredShapeState, payload: OriginalModifyShapePayload,
  operation: OperationIdentity): boolean {
  let changed: boolean = false;
  if (payload.pageOrigin !== null && acceptsWinner(state.winners, 'pageOrigin', operation)) {
    state.resolved.page = cloneSequence(payload.pageOrigin.page);
    state.resolved.originX = payload.pageOrigin.x;
    state.resolved.originY = payload.pageOrigin.y;
    setWinner(state.winners, 'pageOrigin', operation); changed = true;
  }
  if (payload.rotation.present && acceptsWinner(state.winners, 'rotation', operation)) {
    state.resolved.rotation = payload.rotation.value;
    setWinner(state.winners, 'rotation', operation); changed = true;
  }
  if (payload.scale.present && acceptsWinner(state.winners, 'scale', operation)) {
    state.resolved.scale = cloneScale(payload.scale.value);
    setWinner(state.winners, 'scale', operation); changed = true;
  }
  if (payload.definition.present && acceptsWinner(state.winners, 'definition', operation)) {
    if (payload.definition.value === null) {
      // The writer normally uses NONE as "no update". Retaining the current definition keeps
      // malformed explicit NONE from making a renderable Shape impossible.
    } else {
      state.resolved.definition = cloneDefinition(payload.definition.value);
    }
    setWinner(state.winners, 'definition', operation); changed = true;
  }
  changed = applyScalar(state, 'tool', payload.tool, operation) || changed;
  changed = applyScalar(state, 'style', payload.style, operation) || changed;
  changed = applyScalar(state, 'tapePattern', payload.tapePattern, operation) || changed;
  changed = applyScalar(state, 'color', payload.color, operation) || changed;
  changed = applyScalar(state, 'borderWidth', payload.borderWidth, operation) || changed;
  if (payload.fillColor.present && acceptsWinner(state.winners, 'fillColor', operation)) {
    state.resolved.fillColor = payload.fillColor.value;
    setWinner(state.winners, 'fillColor', operation); changed = true;
  }
  changed = applyScalar(state, 'zIndex', payload.zIndex, operation) || changed;
  changed = applyScalar(state, 'positionLocked', payload.positionLocked, operation) || changed;
  changed = applyScalar(state, 'inkEffects', payload.inkEffects, operation) || changed;
  changed = applyScalar(state, 'inkEffectsTinted', payload.inkEffectsTinted, operation) || changed;
  return changed;
}

function applyScalar(state: StoredShapeState, field: string,
  value: number | string | boolean | null, operation: OperationIdentity): boolean {
  if (value === null || !acceptsWinner(state.winners, field, operation)) {
    return false;
  }
  const resolved = state.resolved as Object as Record<string, number | string | boolean | null>;
  resolved[field] = value;
  setWinner(state.winners, field, operation);
  return true;
}

function acceptsWinner(winners: ShapeWinner[], field: string,
  operation: OperationIdentity): boolean {
  const winner: ShapeWinner | undefined = winners.find(
    (candidate: ShapeWinner): boolean => candidate.field === field);
  return winner === undefined || compareOperationIdentity(operation, winner) > 0;
}

function setWinner(winners: ShapeWinner[], field: string, operation: OperationIdentity): void {
  const winner: ShapeWinner | undefined = winners.find(
    (candidate: ShapeWinner): boolean => candidate.field === field);
  if (winner === undefined) {
    winners.push({ field: field, timestamp: operation.timestamp, siteId: operation.siteId });
  } else {
    winner.timestamp = operation.timestamp;
    winner.siteId = operation.siteId;
  }
}

async function readShapeState(store: relationalStore.RdbStore, noteId: string,
  shape: OperationIdentity): Promise<StoredShapeState | null> {
  const rows = await store.querySql(
    `SELECT create_payload, resolved_payload, register_winners FROM original_shape_state
     WHERE note_id = ? AND shape_timestamp = ? AND shape_site_id = ?`,
    [noteId, shape.timestamp, shape.siteId]);
  try {
    if (!rows.goToFirstRow()) {
      return null;
    }
    const create = JSON.parse(rows.getString(rows.getColumnIndex('create_payload'))) as
      OriginalCreateShapePayload;
    const resolved = JSON.parse(rows.getString(rows.getColumnIndex('resolved_payload'))) as
      OriginalCreateShapePayload;
    const winners = JSON.parse(rows.getString(rows.getColumnIndex('register_winners'))) as
      ShapeWinner[];
    validateCreateShape(create, null);
    validateCreateShape(resolved, null);
    for (const winner of winners) {
      validateOperationIdentity(winner);
      if (winner.field.length === 0) {
        throw new Error('stored Shape winner has no field');
      }
    }
    return { create: create, resolved: resolved, winners: winners };
  } finally {
    rows.close();
  }
}

async function updateShapeState(store: relationalStore.RdbStore, noteId: string,
  shape: OperationIdentity, state: StoredShapeState): Promise<void> {
  const predicates = new relationalStore.RdbPredicates('original_shape_state');
  predicates.equalTo('note_id', noteId);
  predicates.equalTo('shape_timestamp', shape.timestamp);
  predicates.equalTo('shape_site_id', shape.siteId);
  if (await store.update({ 'resolved_payload': JSON.stringify(state.resolved),
    'register_winners': JSON.stringify(state.winners) }, predicates) !== 1) {
    throw new Error('original Shape state changed concurrently');
  }
}

async function readShapeTarget(store: relationalStore.RdbStore, noteId: string,
  shape: OperationIdentity): Promise<StoredShapeTarget | null> {
  const rows = await store.querySql(
    `SELECT page_timestamp, page_site_id, page_index, kind, visible
     FROM original_element_z_index WHERE note_id = ?
      AND element_timestamp = ? AND element_site_id = ?`,
    [noteId, shape.timestamp, shape.siteId]);
  let page: OriginalSequenceIdentity;
  let kind: number;
  let visible: boolean;
  try {
    if (!rows.goToFirstRow()) {
      return null;
    }
    page = { timestamp: rows.getLong(rows.getColumnIndex('page_timestamp')),
      siteId: rows.getLong(rows.getColumnIndex('page_site_id')),
      index: rows.getLong(rows.getColumnIndex('page_index')) };
    kind = rows.getLong(rows.getColumnIndex('kind'));
    visible = rows.getLong(rows.getColumnIndex('visible')) === 1;
  } finally {
    rows.close();
  }
  if (kind !== PageElementKind.SHAPE) {
    return null;
  }
  const target: OriginalMutationPageTarget | null = await readPageTarget(store, noteId, page);
  return target === null ? null : { shape: shape, page: page, pageId: target.pageId,
    kind: kind, visible: visible, target: target };
}

async function readMaterializedShape(store: relationalStore.RdbStore, noteId: string,
  target: StoredShapeTarget): Promise<ShapeElement | null> {
  const rows = await store.querySql(target.visible ? target.target.archived ?
    `SELECT payload FROM original_deleted_page_element WHERE note_id = ?
     AND page_timestamp = ? AND page_site_id = ? AND page_index = ?
     AND element_id = ? AND kind = ?` :
    `SELECT payload FROM page_element_snapshot WHERE note_id = ? AND page_id = ?
     AND element_id = ? AND kind = ?` :
    `SELECT payload FROM original_deleted_entity WHERE note_id = ?
     AND entity_timestamp = ? AND entity_site_id = ?
     AND page_timestamp = ? AND page_site_id = ? AND page_index = ?
     AND element_id = ? AND kind = ?`, target.visible ? target.target.archived ?
    [noteId, target.page.timestamp, target.page.siteId, target.page.index,
      encodeOperationId(target.shape), PageElementKind.SHAPE] :
    [noteId, target.pageId, encodeOperationId(target.shape), PageElementKind.SHAPE] :
    [noteId, target.shape.timestamp, target.shape.siteId,
      target.page.timestamp, target.page.siteId, target.page.index,
      encodeOperationId(target.shape), PageElementKind.SHAPE]);
  try {
    if (!rows.goToFirstRow()) {
      return null;
    }
    const persisted: PersistedElement = decodePersistedElement(
      rows.getBlob(rows.getColumnIndex('payload')));
    if (persisted.kind !== 'shape') {
      return null;
    }
    const shape: ShapeElement = persisted.data as ShapeElement;
    return shape.id === encodeOperationId(target.shape) ? shape : null;
  } catch (_error) {
    return null;
  } finally {
    rows.close();
  }
}

async function readPageTarget(store: relationalStore.RdbStore, noteId: string,
  page: OriginalSequenceIdentity): Promise<OriginalMutationPageTarget | null> {
  validateOriginalSequenceIdentity(page);
  const identity = await store.querySql(
    `SELECT page_id, visible FROM original_page_identity WHERE note_id = ?
     AND seq_timestamp = ? AND seq_site_id = ? AND seq_index = ?`,
    [noteId, page.timestamp, page.siteId, page.index]);
  let pageId: string | null = null;
  try {
    if (!identity.goToFirstRow() || identity.getLong(identity.getColumnIndex('visible')) !== 1 ||
      identity.isColumnNull(identity.getColumnIndex('page_id'))) {
      return null;
    }
    pageId = identity.getString(identity.getColumnIndex('page_id'));
  } finally {
    identity.close();
  }
  const live: number | null = await scalarLong(store,
    'SELECT content_revision FROM page_info WHERE note_id = ? AND page_id = ?', [noteId, pageId]);
  const archived: number | null = await scalarLong(store,
    `SELECT content_revision FROM original_deleted_page WHERE note_id = ?
     AND page_timestamp = ? AND page_site_id = ? AND page_index = ?`,
    [noteId, page.timestamp, page.siteId, page.index]);
  if ((live === null) === (archived === null)) {
    return null;
  }
  return { page: cloneSequence(page), pageId: pageId as string,
    revisionTable: archived === null ? 'page_info' : 'original_deleted_page',
    revision: archived === null ? live as number : archived, archived: archived !== null };
}

async function updateShapeOrderState(store: relationalStore.RdbStore, noteId: string,
  shape: OperationIdentity, target: StoredShapeTarget, page: OriginalSequenceIdentity,
  zIndex: string): Promise<void> {
  const predicates = new relationalStore.RdbPredicates('original_element_z_index');
  predicates.equalTo('note_id', noteId);
  predicates.equalTo('element_timestamp', shape.timestamp);
  predicates.equalTo('element_site_id', shape.siteId);
  predicates.equalTo('page_timestamp', target.page.timestamp);
  predicates.equalTo('page_site_id', target.page.siteId);
  predicates.equalTo('page_index', target.page.index);
  if (await store.update({ 'page_timestamp': page.timestamp, 'page_site_id': page.siteId,
    'page_index': page.index, 'z_index': zIndex }, predicates) !== 1) {
    throw new Error('original Shape ordering state changed concurrently');
  }
}

async function updateHiddenShape(store: relationalStore.RdbStore, noteId: string,
  shape: OperationIdentity, page: OriginalSequenceIdentity, payload: Uint8Array): Promise<void> {
  const predicates = new relationalStore.RdbPredicates('original_deleted_entity');
  predicates.equalTo('note_id', noteId);
  predicates.equalTo('entity_timestamp', shape.timestamp);
  predicates.equalTo('entity_site_id', shape.siteId);
  if (await store.update({ 'page_timestamp': page.timestamp, 'page_site_id': page.siteId,
    'page_index': page.index, 'payload': payload }, predicates) !== 1) {
    throw new ShapeGroupDeferredError('MODIFY_SHAPE_HIDDEN_SNAPSHOT_DIVERGED');
  }
}

async function removeActiveShape(store: relationalStore.RdbStore, noteId: string,
  target: StoredShapeTarget): Promise<void> {
  const predicates = pagePredicates(noteId, target.target);
  predicates.equalTo('element_id', encodeOperationId(target.shape));
  predicates.equalTo('kind', PageElementKind.SHAPE);
  if (await store.delete(predicates) !== 1) {
    throw new ShapeGroupDeferredError('MODIFY_SHAPE_SNAPSHOT_DIVERGED');
  }
}

async function insertPageElement(store: relationalStore.RdbStore, noteId: string,
  target: OriginalMutationPageTarget, elementId: string, payload: Uint8Array,
  revision: number): Promise<void> {
  const values: relationalStore.ValuesBucket = { 'note_id': noteId, 'element_id': elementId,
    'kind': PageElementKind.SHAPE, 'payload': payload, 'revision': revision, 'element_order': 0 };
  if (target.archived) {
    values['page_timestamp'] = target.page.timestamp;
    values['page_site_id'] = target.page.siteId;
    values['page_index'] = target.page.index;
    await store.insert('original_deleted_page_element', values);
  } else {
    values['page_id'] = target.pageId;
    await store.insert('page_element_snapshot', values);
  }
}

async function pageCoverageIsComplete(store: relationalStore.RdbStore, noteId: string,
  target: OriginalMutationPageTarget): Promise<boolean> {
  const order: StoredOrderRow[] = await readOriginalOrder(store, noteId, target.page);
  const rows = await store.query(pagePredicates(noteId, target), ['element_id', 'kind']);
  const keys: Set<string> = new Set<string>();
  for (const row of order) {
    keys.add(`${row.kind}:${row.elementId}`);
  }
  let count: number = 0;
  try {
    while (rows.goToNextRow()) {
      if (!keys.has(`${rows.getLong(rows.getColumnIndex('kind'))}:` +
        rows.getString(rows.getColumnIndex('element_id')))) {
        return false;
      }
      count++;
    }
  } finally {
    rows.close();
  }
  return count === order.length;
}

async function assignPageOrder(store: relationalStore.RdbStore, noteId: string,
  target: OriginalMutationPageTarget): Promise<void> {
  const rows: StoredOrderRow[] = await readOriginalOrder(store, noteId, target.page);
  const predicates: relationalStore.RdbPredicates = pagePredicates(noteId, target);
  const existing = await store.query(predicates, ['element_id', 'kind']);
  const keys: Set<string> = new Set<string>();
  try {
    while (existing.goToNextRow()) {
      keys.add(`${existing.getLong(existing.getColumnIndex('kind'))}:` +
        existing.getString(existing.getColumnIndex('element_id')));
    }
  } finally {
    existing.close();
  }
  if (keys.size !== rows.length) {
    throw new Error('original Shape page coverage changed during apply');
  }
  const table: string = target.archived ? 'original_deleted_page_element' : 'page_element_snapshot';
  for (let index: number = 0; index < rows.length; index++) {
    if (!keys.has(`${rows[index].kind}:${rows[index].elementId}`)) {
      throw new Error('original Shape ordering lost an element');
    }
    const update: relationalStore.RdbPredicates = pagePredicates(noteId, target);
    update.equalTo('element_id', rows[index].elementId);
    update.equalTo('kind', rows[index].kind);
    if (await store.update({ 'element_order': index }, update) !== 1) {
      throw new Error(`original Shape ordering failed in ${table}`);
    }
  }
}

async function readOriginalOrder(store: relationalStore.RdbStore, noteId: string,
  page: OriginalSequenceIdentity): Promise<StoredOrderRow[]> {
  const result = await store.querySql(
    `SELECT element_timestamp, element_site_id, kind, z_index FROM original_element_z_index
     WHERE note_id = ? AND page_timestamp = ? AND page_site_id = ? AND page_index = ?
       AND visible = 1`, [noteId, page.timestamp, page.siteId, page.index]);
  const rows: StoredOrderRow[] = [];
  try {
    while (result.goToNextRow()) {
      const timestamp: number = result.getLong(result.getColumnIndex('element_timestamp'));
      const siteId: number = result.getLong(result.getColumnIndex('element_site_id'));
      rows.push({ timestamp: timestamp, siteId: siteId, elementId: encodeOperationId({
        timestamp: timestamp, siteId: siteId }), kind: result.getLong(result.getColumnIndex('kind')),
        zIndex: result.getString(result.getColumnIndex('z_index')) });
    }
  } finally {
    result.close();
  }
  if (!await sortOrderRows(store, noteId, rows)) {
    throw new Error('original Group layering state diverged');
  }
  return rows;
}

async function sortOrderRows(store: relationalStore.RdbStore, noteId: string,
  rows: StoredOrderRow[]): Promise<boolean> {
  const entities: OriginalLayeringEntity[] = rows.map(
    (row: StoredOrderRow): OriginalLayeringEntity => ({
      id: row.elementId, timestamp: row.timestamp, siteId: row.siteId, zIndex: row.zIndex,
    }));
  const ranks: Map<string, number> | null = await originalGroupLayerRanks(store, noteId, entities);
  if (ranks === null || ranks.size !== rows.length) {
    return false;
  }
  rows.sort((left: StoredOrderRow, right: StoredOrderRow): number =>
    (ranks.get(left.elementId) as number) - (ranks.get(right.elementId) as number));
  return true;
}

function pagePredicates(noteId: string,
  target: OriginalMutationPageTarget): relationalStore.RdbPredicates {
  const table: string = target.archived ? 'original_deleted_page_element' : 'page_element_snapshot';
  const predicates = new relationalStore.RdbPredicates(table);
  predicates.equalTo('note_id', noteId);
  if (target.archived) {
    predicates.equalTo('page_timestamp', target.page.timestamp);
    predicates.equalTo('page_site_id', target.page.siteId);
    predicates.equalTo('page_index', target.page.index);
  } else {
    predicates.equalTo('page_id', target.pageId);
  }
  return predicates;
}

function materializeShape(identity: OperationIdentity,
  payload: OriginalCreateShapePayload): ShapeElement {
  const id: string = encodeOperationId(identity);
  const transform: TransformMatrix = shapeTransform(payload);
  let shape: ShapeElement;
  if (payload.definition.type === OriginalShapeDefinitionType.LINE) {
    const definition: OriginalLineDefinition = payload.definition as OriginalLineDefinition;
    const line: LineElement = { id: id, type: ElementType.LINE, transform: transform,
      bounds: emptyBounds(), start: clonePoint(definition.start),
      controlPoint1: cloneNullablePoint(definition.controlPoint1),
      controlPoint2: cloneNullablePoint(definition.controlPoint2), end: clonePoint(definition.end),
      arrowHead: definition.arrowHead === 1 ? ShapeArrowHead.SINGLE : ShapeArrowHead.NONE,
      color: payload.color, strokeWidth: payload.borderWidth, fillColor: payload.fillColor,
      richText: '', characterStyleRuns: [], paragraphStyleRuns: [],
      positionLocked: payload.positionLocked, originalTool: payload.tool };
    shape = line;
  } else if (payload.definition.type === OriginalShapeDefinitionType.POLYGON) {
    const definition: OriginalPolygonDefinition = payload.definition as OriginalPolygonDefinition;
    const polygon: PolygonElement = { id: id, type: ElementType.POLYGON, transform: transform,
      bounds: emptyBounds(), vertices: definition.points.map(clonePoint), isClosed: true,
      color: payload.color, strokeWidth: payload.borderWidth, fillColor: payload.fillColor,
      richText: '', characterStyleRuns: [], paragraphStyleRuns: [],
      positionLocked: payload.positionLocked, originalTool: payload.tool };
    shape = polygon;
  } else {
    const definition: OriginalEllipseDefinition = payload.definition as OriginalEllipseDefinition;
    const ellipse: EllipseElement = { id: id, type: ElementType.ELLIPSE, transform: transform,
      bounds: emptyBounds(), center: { x: definition.width / 2, y: definition.height / 2 },
      radiusX: definition.width / 2, radiusY: definition.height / 2, rotationRadians: 0,
      color: payload.color, strokeWidth: payload.borderWidth, fillColor: payload.fillColor,
      richText: '', characterStyleRuns: [], paragraphStyleRuns: [],
      positionLocked: payload.positionLocked, originalTool: payload.tool };
    shape = ellipse;
  }
  shape.bounds = recomputeShapeBounds(shape);
  return shape;
}

function copyShapeRichText(target: ShapeElement, source: ShapeElement): void {
  target.richText = source.richText === undefined ? '' : source.richText;
  target.characterStyleRuns = cloneCharacterStyleRuns(source.characterStyleRuns);
  target.paragraphStyleRuns = cloneParagraphStyleRuns(source.paragraphStyleRuns);
}

function cloneCharacterStyleRuns(runs: RichTextCharacterStyleRun[] | undefined):
  RichTextCharacterStyleRun[] | undefined {
  if (runs === undefined) {
    return undefined;
  }
  return runs.map((run: RichTextCharacterStyleRun): RichTextCharacterStyleRun => {
    const style: RichTextCharacterStyle = JSON.parse(JSON.stringify(run.style)) as
      RichTextCharacterStyle;
    return { start: run.start, end: run.end, style: style };
  });
}

function cloneParagraphStyleRuns(runs: RichTextParagraphStyleRun[] | undefined):
  RichTextParagraphStyleRun[] | undefined {
  if (runs === undefined) {
    return undefined;
  }
  return runs.map((run: RichTextParagraphStyleRun): RichTextParagraphStyleRun => {
    const style: RichTextParagraphStyle = JSON.parse(JSON.stringify(run.style)) as
      RichTextParagraphStyle;
    return { start: run.start, end: run.end, style: style };
  });
}

function shapeTransform(payload: OriginalCreateShapePayload): TransformMatrix {
  const rotation: number = payload.rotation === null ? 0 : payload.rotation;
  const scaleX: number = payload.scale === null ? 1 : payload.scale.x;
  const scaleY: number = payload.scale === null ? 1 : payload.scale.y;
  const cosine: number = Math.cos(rotation);
  const sine: number = Math.sin(rotation);
  return [cosine * scaleX, -sine * scaleY, payload.originX,
    sine * scaleX, cosine * scaleY, payload.originY, 0, 0, 1];
}

function decodeRequiredDefinition(type: number,
  table: OriginalFlatBufferTableReader | null): OriginalShapeDefinition {
  if (table === null) {
    throw new Error('Shape definition payload is missing');
  }
  return decodeDefinition(type, table);
}

function decodeDefinition(type: number,
  table: OriginalFlatBufferTableReader): OriginalShapeDefinition {
  if (type === OriginalShapeDefinitionType.LINE) {
    rejectFieldsFrom(table, 5, 'Line definition');
    const start: Uint8Array | null = table.readInlineBytes(0, 8);
    const end: Uint8Array | null = table.readInlineBytes(3, 8);
    if (start === null || end === null) {
      throw new Error('Line definition is missing an endpoint');
    }
    const cp1: Uint8Array | null = table.readInlineBytes(1, 8);
    const cp2: Uint8Array | null = table.readInlineBytes(2, 8);
    const arrowHead: number = table.readUint8(4, 0);
    if (arrowHead < 0 || arrowHead > 1) {
      throw new Error('Line arrow head is invalid');
    }
    return { type: OriginalShapeDefinitionType.LINE, start: point(start),
      controlPoint1: cp1 === null ? null : point(cp1),
      controlPoint2: cp2 === null ? null : point(cp2), end: point(end), arrowHead: arrowHead };
  }
  if (type === OriginalShapeDefinitionType.POLYGON) {
    rejectFieldsFrom(table, 1, 'Polygon definition');
    const bytes: Uint8Array | null = table.readInlineVectorBytes(0, 8, MAX_SHAPE_POINTS);
    const points: OriginalShapePoint[] = [];
    if (bytes !== null) {
      for (let offset: number = 0; offset < bytes.length; offset += 8) {
        points.push(point(bytes, offset));
      }
    }
    return { type: OriginalShapeDefinitionType.POLYGON, points: points };
  }
  if (type === OriginalShapeDefinitionType.ELLIPSE) {
    rejectFieldsFrom(table, 2, 'NormalShape definition');
    if (table.readUint8(0, 0) !== 0) {
      throw new Error('NormalShape type is unsupported');
    }
    const size: Uint8Array | null = table.readInlineBytes(1, 8);
    if (size === null) {
      throw new Error('NormalShape size is missing');
    }
    const scale: OriginalShapeScale = pointScale(size);
    if (scale.x < 0 || scale.y < 0) {
      throw new Error('NormalShape size is negative');
    }
    return { type: OriginalShapeDefinitionType.ELLIPSE, width: scale.x, height: scale.y };
  }
  throw new Error('Shape definition discriminator is invalid');
}

function validateCreateShape(payload: OriginalCreateShapePayload,
  fillBytes: Uint8Array | null): void {
  validateOriginalSequenceIdentity(payload.page);
  finite(payload.originX); finite(payload.originY);
  if (payload.rotation !== null) finite(payload.rotation);
  if (payload.scale !== null) { finite(payload.scale.x); finite(payload.scale.y); }
  validateDefinition(payload.definition);
  if (payload.tool < 0 || payload.tool > 7 || payload.style < 1 || payload.style > 3 ||
    (payload.tapePattern !== null && (payload.tapePattern < 0 || payload.tapePattern > 8))) {
    throw new Error('CreateShape tool configuration is invalid');
  }
  finiteNonNegative(payload.borderWidth);
  if (payload.force !== null) finite(payload.force);
  validateUnsignedLongDecimal(payload.zIndex);
  validateUnsignedLongDecimal(payload.inkEffects);
  if (fillBytes !== null && fillBytes[3] === 0) {
    throw new Error('CreateShape uses a transparent fill color');
  }
  if (!payload.inkEffectsTinted && payload.inkEffects === '0') {
    throw new Error('CreateShape tint flag has no ink effect');
  }
  if (payload.inkEffects !== '0' && payload.tool !== 0 && payload.tool !== 2) {
    throw new Error('CreateShape ink effects require pen or highlighter');
  }
}

function validateModifyShape(payload: OriginalModifyShapePayload,
  fillBytes: Uint8Array | null): void {
  if (payload.pageOrigin !== null) {
    validateOriginalSequenceIdentity(payload.pageOrigin.page);
    finite(payload.pageOrigin.x); finite(payload.pageOrigin.y);
  }
  if (payload.rotation.value !== null) finite(payload.rotation.value);
  if (payload.scale.value !== null) { finite(payload.scale.value.x); finite(payload.scale.value.y); }
  if (payload.definition.value !== null) validateDefinition(payload.definition.value);
  if ((payload.tool !== null && (payload.tool < 0 || payload.tool > 7)) ||
    payload.style === 0 || (payload.style !== null && payload.style > 3) ||
    (payload.tapePattern !== null && payload.tapePattern > 8)) {
    throw new Error('ModifyShape tool configuration is invalid');
  }
  if (payload.borderWidth !== null) finiteNonNegative(payload.borderWidth);
  if (fillBytes !== null && fillBytes[3] === 0) {
    throw new Error('ModifyShape uses a transparent fill color');
  }
  if (payload.inkEffectsTinted === false &&
    (payload.inkEffects === null || payload.inkEffects === '0')) {
    throw new Error('ModifyShape tint flag has no ink effect');
  }
}

function validateDefinition(definition: OriginalShapeDefinition): void {
  if (definition.type === OriginalShapeDefinitionType.LINE) {
    const line: OriginalLineDefinition = definition as OriginalLineDefinition;
    validPoint(line.start); validPoint(line.end);
    if (line.controlPoint1 !== null) validPoint(line.controlPoint1);
    if (line.controlPoint2 !== null) validPoint(line.controlPoint2);
    if (line.arrowHead < 0 || line.arrowHead > 1) throw new Error('Line arrow is invalid');
  } else if (definition.type === OriginalShapeDefinitionType.POLYGON) {
    const polygon: OriginalPolygonDefinition = definition as OriginalPolygonDefinition;
    if (polygon.points.length > MAX_SHAPE_POINTS) throw new Error('Polygon is too large');
    polygon.points.forEach(validPoint);
  } else if (definition.type === OriginalShapeDefinitionType.ELLIPSE) {
    const ellipse: OriginalEllipseDefinition = definition as OriginalEllipseDefinition;
    finiteNonNegative(ellipse.width); finiteNonNegative(ellipse.height);
  } else {
    throw new Error('Shape definition is invalid');
  }
}

function identities(raw: number[][], name: string,
  unique: boolean = true): OperationIdentity[] {
  const result: OperationIdentity[] = [];
  const seen: Set<string> = new Set<string>();
  for (const item of raw) {
    const identity: OperationIdentity = { timestamp: item[0], siteId: item[1] };
    validateOperationIdentity(identity);
    const key: string = encodeOperationId(identity);
    if (unique && seen.has(key)) {
      throw new Error(`${name} repeats an identity`);
    }
    seen.add(key); result.push(identity);
  }
  return result;
}

function identityFromBytes(bytes: Uint8Array): OperationIdentity {
  const identity: OperationIdentity = { timestamp: readU32(bytes, 4), siteId: readU16(bytes, 0) };
  validateOperationIdentity(identity);
  return identity;
}

function sequenceIdentity(raw: number[]): OriginalSequenceIdentity {
  const identity: OriginalSequenceIdentity = { timestamp: raw[0], siteId: raw[1], index: raw[2] };
  validateOriginalSequenceIdentity(identity);
  return identity;
}

function point(bytes: Uint8Array, offset: number = 0): OriginalShapePoint {
  const result: OriginalShapePoint = { x: readOriginalInlineFloat32(bytes, offset),
    y: readOriginalInlineFloat32(bytes, offset + 4) };
  validPoint(result);
  return result;
}

function pointScale(bytes: Uint8Array): OriginalShapeScale {
  return { x: readOriginalInlineFloat32(bytes, 0), y: readOriginalInlineFloat32(bytes, 4) };
}

function originalColorToArgb(bytes: Uint8Array): number {
  return bytes[3] << 24 | bytes[0] << 16 | bytes[1] << 8 | bytes[2];
}

function orderIndex(rows: StoredOrderRow[], elementId: string, kind: number): number {
  const index: number = rows.findIndex((row: StoredOrderRow): boolean =>
    row.elementId === elementId && row.kind === kind);
  if (index < 0) throw new Error('new original Shape is absent from its order');
  return index;
}

async function scalarString(store: relationalStore.RdbStore, sql: string,
  args: relationalStore.ValueType[]): Promise<string | null> {
  const rows = await store.querySql(sql, args);
  try { return rows.goToFirstRow() ? rows.getString(0) : null; } finally { rows.close(); }
}

async function scalarLong(store: relationalStore.RdbStore, sql: string,
  args: relationalStore.ValueType[]): Promise<number | null> {
  const rows = await store.querySql(sql, args);
  try { return rows.goToFirstRow() ? rows.getLong(0) : null; } finally { rows.close(); }
}

function rejectFieldsFrom(table: OriginalFlatBufferTableReader, first: number,
  name: string): void {
  for (let field: number = first; field <= 1024; field++) {
    if (table.hasField(field)) throw new Error(`${name} has an unknown field`);
  }
}

function finite(value: number): void {
  if (!Number.isFinite(value)) throw new Error('Shape float is not finite');
}

function finiteNonNegative(value: number): void {
  finite(value); if (value < 0) throw new Error('Shape value is negative');
}

function validPoint(value: OriginalShapePoint): void { finite(value.x); finite(value.y); }
function clonePoint(value: OriginalShapePoint): Point2D { return { x: value.x, y: value.y }; }
function cloneNullablePoint(value: OriginalShapePoint | null): Point2D | null {
  return value === null ? null : clonePoint(value);
}
function cloneScale(value: OriginalShapeScale | null): OriginalShapeScale | null {
  return value === null ? null : { x: value.x, y: value.y };
}
function cloneSequence(value: OriginalSequenceIdentity): OriginalSequenceIdentity {
  return { timestamp: value.timestamp, siteId: value.siteId, index: value.index };
}
function cloneDefinition(value: OriginalShapeDefinition): OriginalShapeDefinition {
  return JSON.parse(JSON.stringify(value)) as OriginalShapeDefinition;
}
function emptyBounds(): Rect2D {
  return { left: 0, top: 0, right: 0, bottom: 0 };
}
function pageKey(page: OriginalSequenceIdentity): string {
  return `${page.timestamp}:${page.siteId}:${page.index}`;
}
function readU16(bytes: Uint8Array, offset: number): number {
  return bytes[offset] | bytes[offset + 1] << 8;
}
function readU32(bytes: Uint8Array, offset: number): number {
  return bytes[offset] + bytes[offset + 1] * 0x100 + bytes[offset + 2] * 0x10000 +
    bytes[offset + 3] * 0x1000000;
}

class ShapeGroupDeferredError extends Error {
  readonly reason: string;
  constructor(reason: string) { super(reason); this.reason = reason; }
}
