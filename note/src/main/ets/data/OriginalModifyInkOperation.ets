import { relationalStore } from '@kit.ArkData';
import { TransformMatrix } from '../core/model/GeometryTypes';
import { PencilSplatLimitError } from '../core/algorithm/PencilSplatGenerator';
import { PageElementKind } from '../core/model/PageElementOrder';
import { InkPathCommand, InkStyle, InkStyleMapEntry, RenderSpec,
  StrokeElementData, TapePattern } from '../core/model/StrokeTypes';
import {
  compareOperationIdentity, encodeOperationId, OperationIdentity, OriginalSequenceIdentity,
  validateOperationIdentity, validateOriginalSequenceIdentity,
} from './OperationIdentity';
import {
  isSupportedOriginalStoredStroke, OriginalInkAppendRecord,
  originalInkGeometryMatches, rebuildOriginalInkGeometry, RebuiltOriginalInkGeometry,
} from './OriginalAddPathElementsOperation';
import {
  decodeOriginalAuxiliaryInkPath, decodeOriginalInkPathReplacement,
  DecodedOriginalAuxiliaryInkPath, originalInkTransform, OriginalInkPathDeferredError,
} from './OriginalInkPathCodec';
import { decodeOriginalCreateInk, OriginalCreateInkPayload } from './OriginalCreateInkOperation';
import {
  decodeOriginalInkStyleMap, MAX_ORIGINAL_INK_STYLE_MAP_ENTRIES,
  ORIGINAL_INK_STYLE_MAP_ENTRY_BYTES, sameInkStyleMap,
} from './OriginalInkStyleMapCodec';
import {
  OriginalFlatBufferTableReader, readOriginalInlineFloat32, readOriginalPayloadTable,
} from './OriginalSyncedOperationFlatBuffer';
import { SearchItemType } from './SearchItemType';
import { OriginalPageMutationBatch } from './OriginalPageMutationBatch';
import {
  decodePersistedElement, encodePersistedElement, PersistedElement,
} from './StrokePersistence';
import {
  StoredSyncedOperation, SyncedOperationApplier, SyncedOperationApplyResult,
} from './SyncedOperationInbox';
import { compareUnsignedLongDecimal, validateUnsignedLongDecimal } from './UnsignedDecimal';

export const ORIGINAL_MODIFY_INK_PAYLOAD_TYPE: number = 17;
const MAX_ORIGINAL_MODIFY_INK_COUNT: number = 10000;
const MAX_ORIGINAL_INK_PATH_BYTES: number = 16 * 1024 * 1024;

export interface OriginalModifyInkPayload {
  inks: OperationIdentity[];
  pageOrigin: OriginalInkPageOrigin | null;
  rotation: NullableRegisterUpdate<number>;
  scale: NullableRegisterUpdate<OriginalInkScale>;
  style: number | null;
  color: number | null;
  width: number | null;
  centerPath: Uint8Array | null;
  customPath: NullableRegisterUpdate<Uint8Array>;
  fillPath: NullableRegisterUpdate<Uint8Array>;
  fillColor: NullableRegisterUpdate<number>;
  styleMap: NullableRegisterUpdate<Uint8Array>;
  zIndex: string | null;
  nibAngle: number | null;
  nibFlatness: number | null;
  tapePattern: TapePattern | null;
  inkEffects: string | null;
  inkEffectsTinted: boolean | null;
}

export interface OriginalInkPageOrigin {
  page: OriginalSequenceIdentity;
  originX: number;
  originY: number;
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
  estimatedPath: StoredRegister<Uint8Array>;
  baseCustomPath: Uint8Array | null;
  customPath: StoredRegister<Uint8Array>;
  baseFillPath: Uint8Array | null;
  fillPath: StoredRegister<Uint8Array>;
  baseFillColor: number | null;
  fillColor: StoredRegister<number>;
  baseStyleMap: Uint8Array | null;
  styleMap: StoredRegister<Uint8Array>;
  style: StoredRegister<number>;
  color: StoredRegister<number>;
  width: StoredRegister<number>;
  baseTapePattern: TapePattern | null;
  tapePattern: StoredRegister<TapePattern>;
  baseInkEffects: string;
  inkEffects: StoredRegister<string>;
  baseInkEffectsTinted: boolean;
  inkEffectsTinted: StoredRegister<boolean>;
  baseTransform: OriginalInkBaseTransform | null;
  basePage: OriginalSequenceIdentity | null;
  pageOrigin: StoredRegister<OriginalInkPageOrigin>;
  rotation: StoredRegister<number>;
  scale: StoredRegister<OriginalInkScale>;
  baseZIndex: string | null;
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

interface StoredInkTarget extends StoredPageTarget {
  ink: OperationIdentity;
  zIndex: string;
  hidden: boolean;
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

interface PlannedReplacement {
  target: StoredInkTarget;
  state: StoredInkState;
  stroke: StrokeElementData;
  geometry: RebuiltOriginalInkGeometry;
  replaceCenterPath: boolean;
  replaceCustomPath: boolean;
  replaceFillPath: boolean;
  replaceFillColor: boolean;
  replaceStyleMap: boolean;
  replaceStyle: boolean;
  replaceColor: boolean;
  replaceWidth: boolean;
  replaceTapePattern: boolean;
  replaceInkEffects: boolean;
  replaceInkEffectsTinted: boolean;
  replaceRotation: boolean;
  replaceScale: boolean;
  replacePageOrigin: boolean;
  replaceZIndex: boolean;
  customPathBytes: Uint8Array | null;
  fillPathBytes: Uint8Array | null;
  fillColorValue: number | null;
  styleMapBytes: Uint8Array;
  styleMap: InkStyleMapEntry[];
  baseCustomPath: Uint8Array | null;
  baseFillPath: Uint8Array | null;
  baseFillColor: number | null;
  baseStyleMap: Uint8Array | null;
  style: number;
  color: number;
  width: number;
  tapePattern: TapePattern | undefined;
  inkEffects: string;
  inkEffectsTinted: boolean;
  transform: TransformMatrix;
  baseTransform: OriginalInkBaseTransform | null;
  rotationValue: number | null;
  scaleValue: OriginalInkScale | null;
  destination: StoredPageTarget;
  basePage: OriginalSequenceIdentity | null;
  pageOriginValue: OriginalInkPageOrigin | null;
  baseZIndex: string | null;
  zIndexValue: string;
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
  const rawPage: number[] | null = table.readInlineSequence(1);
  const origin: Uint8Array | null = table.readInlineBytes(2, 8);
  let pageOrigin: OriginalInkPageOrigin | null = null;
  if (rawPage !== null && origin !== null) {
    const page: OriginalSequenceIdentity = {
      timestamp: rawPage[0], siteId: rawPage[1], index: rawPage[2],
    };
    validateOriginalSequenceIdentity(page);
    pageOrigin = {
      page: page, originX: readOriginalInlineFloat32(origin, 0),
      originY: readOriginalInlineFloat32(origin, 4),
    };
  }
  const rotationSetter: OriginalFlatBufferTableReader | null = table.readTable(3);
  const scaleSetter: OriginalFlatBufferTableReader | null = table.readTable(4);
  const scaleBytes: Uint8Array | null = scaleSetter === null ? null :
    scaleSetter.readInlineBytes(0, 8);
  const colorBytes: Uint8Array | null = table.readInlineBytes(6, 4);
  const customPathBytes: Uint8Array | null = table.readByteVector(
    9, false, MAX_ORIGINAL_INK_PATH_BYTES);
  const fillPathBytes: Uint8Array | null = table.readByteVector(
    10, false, MAX_ORIGINAL_INK_PATH_BYTES);
  const fillColorSetter: OriginalFlatBufferTableReader | null = table.readTable(11);
  const fillColorBytes: Uint8Array | null = fillColorSetter === null ? null :
    fillColorSetter.readInlineBytes(0, 4);
  const styleMapBytes: Uint8Array | null = table.readInlineVectorBytes(
    12, ORIGINAL_INK_STYLE_MAP_ENTRY_BYTES, MAX_ORIGINAL_INK_STYLE_MAP_ENTRIES);
  const rawStyle: number = table.readUint8(5, 0);
  return {
    inks: inks,
    pageOrigin: pageOrigin,
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
    customPath: { present: table.hasField(9), value: customPathBytes },
    fillPath: { present: table.hasField(10), value: fillPathBytes },
    fillColor: {
      present: fillColorSetter !== null,
      value: fillColorBytes === null ? null : originalColorToArgb(fillColorBytes),
    },
    styleMap: { present: styleMapBytes !== null, value: styleMapBytes },
    zIndex: table.readUint64Decimal(13),
    nibAngle: table.hasField(14) ? table.readUint16(14) : null,
    nibFlatness: table.hasField(15) ? table.readUint16(15) : null,
    tapePattern: table.hasField(16) ?
      normalizeOriginalEnum(table.readUint8(16, 0), TapePattern.CHECKERS) as TapePattern : null,
    inkEffects: table.readUint64Decimal(17),
    inkEffectsTinted: table.hasField(18) ? table.readUint8(18, 1) !== 0 : null,
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
    return this.applyPayload(store, operation, payload);
  }

  preflightTable(table: OriginalFlatBufferTableReader): string | null {
    let payload: OriginalModifyInkPayload;
    try {
      payload = decodeOriginalModifyInkTable(table);
    } catch (_error) {
      return 'MALFORMED_MODIFY_INK_PAYLOAD';
    }
    return preflightOriginalModifyInk(payload);
  }

  async applyTable(store: relationalStore.RdbStore, operation: StoredSyncedOperation,
    table: OriginalFlatBufferTableReader): Promise<SyncedOperationApplyResult> {
    let payload: OriginalModifyInkPayload;
    try {
      payload = decodeOriginalModifyInkTable(table);
    } catch (_error) {
      return { deferredReason: 'MALFORMED_MODIFY_INK_PAYLOAD' };
    }
    return this.applyPayload(store, operation, payload);
  }

  async applyPositionPayload(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation, payload: OriginalModifyInkPayload,
    revisionBatch: OriginalPageMutationBatch): Promise<SyncedOperationApplyResult> {
    return this.applyPayload(store, operation, payload, revisionBatch);
  }

  private async applyPayload(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation,
    payload: OriginalModifyInkPayload,
    revisionBatch: OriginalPageMutationBatch | null = null): Promise<SyncedOperationApplyResult> {
    const preflightReason: string | null = preflightOriginalModifyInk(payload);
    if (preflightReason !== null) {
      return { deferredReason: preflightReason };
    }
    if (payload.pageOrigin === null && !payload.rotation.present && !payload.scale.present &&
      payload.style === null &&
      payload.color === null && payload.width === null && payload.centerPath === null &&
      !payload.customPath.present && !payload.fillPath.present && !payload.fillColor.present &&
      !payload.styleMap.present &&
      payload.zIndex === null && payload.inkEffects === null &&
      payload.inkEffectsTinted === null) {
      // q06 does not register or apply wd8 nib fields; a nib-only op is an applied no-op.
      return { deferredReason: null };
    }
    let decodedCustomPath: DecodedOriginalAuxiliaryInkPath | null = null;
    let decodedFillPath: DecodedOriginalAuxiliaryInkPath | null = null;
    let decodedStyleMap: InkStyleMapEntry[] = [];
    try {
      if (payload.customPath.present && payload.customPath.value !== null) {
        decodedCustomPath = decodeOriginalAuxiliaryInkPath(
          payload.customPath.value, 'MODIFY_INK_CUSTOM_PATH');
        if (decodedCustomPath.commands.length === 0) {
          payload.customPath.value = null;
          decodedCustomPath = null;
        }
      }
      if (payload.fillPath.present && payload.fillPath.value !== null) {
        decodedFillPath = decodeOriginalAuxiliaryInkPath(
          payload.fillPath.value, 'MODIFY_INK_FILL_PATH');
        if (decodedFillPath.commands.length === 0) {
          payload.fillPath.value = null;
          decodedFillPath = null;
        }
      }
      if (payload.styleMap.present) {
        decodedStyleMap = decodeOriginalInkStyleMap(payload.styleMap.value);
        if (decodedStyleMap.length > 1) {
          throw new Error('single-component original Ink has a mismatched style map');
        }
      }
    } catch (_error) {
      if (_error instanceof OriginalInkPathDeferredError) {
        return { deferredReason: _error.deferredReason };
      }
      return { deferredReason: 'MALFORMED_MODIFY_INK_PAYLOAD' };
    }

    const planned: PlannedReplacement[] = [];
    const affectedPages: Map<string, StoredPageTarget> = new Map<string, StoredPageTarget>();
    for (const ink of payload.inks) {
      const target: StoredInkTarget | null = await this.readTarget(store, operation.noteId, ink);
      if (target === null) {
        return { deferredReason: 'MODIFY_INK_TARGET_MISSING_OR_UNBOUND' };
      }
      const state: StoredInkState | null = await this.readState(store, operation.noteId, ink);
      if (state === null) {
        return { deferredReason: 'MODIFY_INK_BASE_STATE_MISSING' };
      }
      assertMatchingModifyInkWinners(payload, state, operation);
      const replaceCenterPath: boolean = payload.centerPath !== null &&
        registerAccepts(operation, state.centerPathWinner);
      const replaceCustomPath: boolean = payload.customPath.present &&
        registerAccepts(operation, state.customPath.winner);
      const replaceFillPath: boolean = payload.fillPath.present &&
        registerAccepts(operation, state.fillPath.winner);
      const replaceFillColor: boolean = payload.fillColor.present &&
        registerAccepts(operation, state.fillColor.winner);
      const replaceStyleMap: boolean = payload.styleMap.present &&
        registerAccepts(operation, state.styleMap.winner);
      const replaceStyle: boolean = payload.style !== null &&
        registerAccepts(operation, state.style.winner);
      const replaceColor: boolean = payload.color !== null &&
        registerAccepts(operation, state.color.winner);
      const replaceWidth: boolean = payload.width !== null &&
        registerAccepts(operation, state.width.winner);
      const replaceTapePattern: boolean = payload.tapePattern !== null &&
        registerAccepts(operation, state.tapePattern.winner);
      const replaceInkEffects: boolean = payload.inkEffects !== null &&
        registerAccepts(operation, state.inkEffects.winner);
      const replaceInkEffectsTinted: boolean = payload.inkEffectsTinted !== null &&
        registerAccepts(operation, state.inkEffectsTinted.winner);
      const replaceRotation: boolean = payload.rotation.present &&
        registerAccepts(operation, state.rotation.winner);
      const replaceScale: boolean = payload.scale.present &&
        registerAccepts(operation, state.scale.winner);
      const replacePageOrigin: boolean = payload.pageOrigin !== null &&
        registerAccepts(operation, state.pageOrigin.winner);
      const replaceZIndex: boolean = payload.zIndex !== null &&
        registerAccepts(operation, state.zIndex.winner);
      if (!replaceCenterPath && !replaceCustomPath && !replaceFillPath && !replaceFillColor &&
        !replaceStyleMap &&
        !replaceStyle && !replaceColor && !replaceWidth && !replaceTapePattern &&
        !replaceInkEffects && !replaceInkEffectsTinted &&
        !replaceRotation && !replaceScale && !replacePageOrigin && !replaceZIndex) {
        continue;
      }
      const stroke: StrokeElementData | null = await this.readStroke(store, operation.noteId, target);
      if (stroke === null || !isSupportedOriginalStoredStroke(stroke)) {
        return { deferredReason: 'MODIFY_INK_STROKE_DIVERGED' };
      }
      if (!stroke.renderSpec.isPencil && stroke.splatPoints.length > 0) {
        return { deferredReason: 'MODIFY_INK_STROKE_DIVERGED' };
      }
      let initial: OriginalCreateInkPayload | null = null;
      if ((replaceStyle && state.style.value === null) ||
        (replaceColor && state.color.value === null) ||
        (replaceWidth && state.width.value === null) ||
        (replaceCustomPath && state.customPath.winner === null) ||
        (replaceFillPath && state.fillPath.winner === null) ||
        (replaceFillColor && state.fillColor.winner === null) ||
        (replaceStyleMap && state.styleMap.winner === null) ||
        ((replacePageOrigin || replaceRotation || replaceScale) &&
          (state.baseTransform === null || state.basePage === null)) ||
        (replaceZIndex && state.baseZIndex === null)) {
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
      const oldInkEffects: string = state.inkEffects.winner !== null ?
        state.inkEffects.value as string : state.baseInkEffects;
      const oldInkEffectsTinted: boolean = state.inkEffectsTinted.winner !== null ?
        state.inkEffectsTinted.value as boolean : state.baseInkEffectsTinted;
      const oldTapePattern: TapePattern | null = state.tapePattern.winner !== null ?
        state.tapePattern.value : state.baseTapePattern;
      if ((replaceStyle && stroke.renderSpec.inkStyle !== originalStyleToInkStyle(oldStyle)) ||
        (replaceColor && stroke.renderSpec.color !== oldColor) ||
        (replaceWidth && stroke.renderSpec.brushWidth !== oldWidth) ||
        (replaceTapePattern &&
          (stroke.renderSpec.tapePattern === undefined ? null : stroke.renderSpec.tapePattern) !==
            oldTapePattern) ||
        ((replaceInkEffects || replaceInkEffectsTinted) &&
          normalizedStoredInkEffects(stroke.renderSpec.inkEffects) !== oldInkEffects) ||
        ((replaceInkEffects || replaceInkEffectsTinted) &&
          normalizedStoredInkEffectsTinted(stroke.renderSpec.inkEffectsTinted) !==
            oldInkEffectsTinted)) {
        return { deferredReason: 'MODIFY_INK_RENDER_STATE_DIVERGED' };
      }
      const style: number = replaceStyle ? payload.style as number :
        inkStyleToOriginalStyle(stroke.renderSpec.inkStyle);
      const color: number = replaceColor ? payload.color as number : stroke.renderSpec.color;
      const width: number = replaceWidth ? payload.width as number : stroke.renderSpec.brushWidth;
      const tapePattern: TapePattern | undefined = replaceTapePattern ?
        payload.tapePattern as TapePattern :
        (oldTapePattern === null ? undefined : oldTapePattern);
      if (replaceTapePattern && state.baseTapePattern === null) {
        return { deferredReason: 'MODIFY_INK_TAPE_PATTERN_FOR_NON_TAPE' };
      }
      const inkEffects: string = replaceInkEffects ?
        payload.inkEffects as string : oldInkEffects;
      const inkEffectsTinted: boolean = replaceInkEffectsTinted ?
        payload.inkEffectsTinted as boolean : oldInkEffectsTinted;
      if (inkEffects !== '0' && (stroke.renderSpec.isPencil || tapePattern !== undefined)) {
        return { deferredReason: 'MODIFY_INK_EFFECT_TOOL_UNSUPPORTED' };
      }
      const baseCustomPath: Uint8Array | null = state.baseCustomPath !== null ?
        state.baseCustomPath : initial !== null ? initial.customPathBytes : null;
      const baseFillPath: Uint8Array | null = state.baseFillPath !== null ?
        state.baseFillPath : initial !== null ? initial.fillPathBytes : null;
      const baseFillColor: number | null = state.baseFillColor !== null ?
        state.baseFillColor : initial !== null ? initial.fillColor : null;
      const oldCustomPathBytes: Uint8Array | null = state.customPath.winner !== null ?
        state.customPath.value : baseCustomPath;
      const oldFillPathBytes: Uint8Array | null = state.fillPath.winner !== null ?
        state.fillPath.value : baseFillPath;
      const oldFillColor: number | null = state.fillColor.winner !== null ?
        state.fillColor.value : baseFillColor;
      const baseStyleMap: Uint8Array | null = state.baseStyleMap !== null ?
        state.baseStyleMap : initial !== null ? initial.styleMapBytes : null;
      const oldStyleMapBytes: Uint8Array | null = state.styleMap.winner !== null ?
        state.styleMap.value : baseStyleMap;
      let oldCustomPath: InkPathCommand[] | null;
      let oldFillPath: InkPathCommand[] | null;
      let oldStyleMap: InkStyleMapEntry[];
      try {
        oldCustomPath = decodeStoredAuxiliaryPath(oldCustomPathBytes, 'MODIFY_INK_CUSTOM_PATH');
        oldFillPath = decodeStoredAuxiliaryPath(oldFillPathBytes, 'MODIFY_INK_FILL_PATH');
        oldStyleMap = decodeOriginalInkStyleMap(oldStyleMapBytes);
      } catch (_error) {
        return { deferredReason: 'MODIFY_INK_TRACKED_STATE_INVALID' };
      }
      if ((replaceCustomPath && !sameOptionalValue(stroke.customPath, oldCustomPath)) ||
        (replaceFillPath && !sameOptionalValue(stroke.fillPath, oldFillPath)) ||
        (replaceFillColor && (stroke.fillColor === undefined ? null : stroke.fillColor) !==
          oldFillColor)) {
        return { deferredReason: 'MODIFY_INK_AUXILIARY_STATE_DIVERGED' };
      }
      if (replaceStyleMap && !sameInkStyleMap(stroke.styleMap, oldStyleMap)) {
        return { deferredReason: 'MODIFY_INK_STYLE_MAP_STATE_DIVERGED' };
      }
      const oldInkEffectPhase: number = oldStyleMap.length === 0 ? 0 :
        oldStyleMap[0].backingDashPhase;
      if ((replaceStyleMap || replaceInkEffects || replaceInkEffectsTinted) &&
        stroke.renderSpec.inkEffectPhase !== undefined &&
        stroke.renderSpec.inkEffectPhase !== oldInkEffectPhase) {
        return { deferredReason: 'MODIFY_INK_EFFECT_PHASE_STATE_DIVERGED' };
      }
      const customPathBytes: Uint8Array | null = replaceCustomPath ?
        payload.customPath.value : oldCustomPathBytes;
      const fillPathBytes: Uint8Array | null = replaceFillPath ?
        payload.fillPath.value : oldFillPathBytes;
      const fillColorValue: number | null = replaceFillColor ?
        payload.fillColor.value : oldFillColor;
      const styleMapBytes: Uint8Array = replaceStyleMap ?
        payload.styleMap.value as Uint8Array :
        (oldStyleMapBytes === null ? new Uint8Array(0) : oldStyleMapBytes);
      const styleMap: InkStyleMapEntry[] = replaceStyleMap ? decodedStyleMap : oldStyleMap;
      const customPath: InkPathCommand[] | null = replaceCustomPath ?
        (decodedCustomPath === null ? null : decodedCustomPath.commands) : oldCustomPath;
      const fillPath: InkPathCommand[] | null = replaceFillPath ?
        (decodedFillPath === null ? null : decodedFillPath.commands) : oldFillPath;
      let baseZIndex: string | null = state.baseZIndex;
      let zIndexValue: string = target.zIndex;
      if (replaceZIndex) {
        baseZIndex = baseZIndex !== null ? baseZIndex :
          (initial as OriginalCreateInkPayload).zIndex;
        const oldZIndex: string = state.zIndex.winner !== null ?
          state.zIndex.value as string : baseZIndex;
        if (target.zIndex !== oldZIndex) {
          return { deferredReason: 'MODIFY_INK_Z_INDEX_STATE_DIVERGED' };
        }
        zIndexValue = payload.zIndex as string;
      }
      let transform: TransformMatrix = stroke.transform;
      let baseTransform: OriginalInkBaseTransform | null = null;
      let basePage: OriginalSequenceIdentity | null = null;
      let destination: StoredPageTarget = target;
      if (replacePageOrigin || replaceRotation || replaceScale) {
        baseTransform = state.baseTransform !== null ? state.baseTransform :
          createBaseTransform(initial as OriginalCreateInkPayload);
        basePage = state.basePage !== null ? state.basePage :
          (initial as OriginalCreateInkPayload).page;
        const oldPageOrigin: OriginalInkPageOrigin = state.pageOrigin.winner !== null ?
          state.pageOrigin.value as OriginalInkPageOrigin : {
            page: basePage, originX: baseTransform.originX, originY: baseTransform.originY,
          };
        if (!samePageIdentity(target.page, oldPageOrigin.page)) {
          return { deferredReason: 'MODIFY_INK_PAGE_ORIGIN_STATE_DIVERGED' };
        }
        const oldRotation: number = state.rotation.winner !== null &&
          state.rotation.value !== null ? state.rotation.value : baseTransform.rotation;
        const oldScale: OriginalInkScale = state.scale.winner !== null &&
          state.scale.value !== null ? state.scale.value :
          { x: baseTransform.scaleX, y: baseTransform.scaleY };
        const expectedTransform: TransformMatrix = originalInkTransform(
          oldPageOrigin.originX, oldPageOrigin.originY, oldRotation, oldScale.x, oldScale.y);
        if (!transformMatricesEqual(stroke.transform, expectedTransform)) {
          return { deferredReason: 'MODIFY_INK_TRANSFORM_STATE_DIVERGED' };
        }
        const nextRotation: number = replaceRotation ?
          (payload.rotation.value === null ? baseTransform.rotation : payload.rotation.value) :
          oldRotation;
        const nextScale: OriginalInkScale = replaceScale ?
          (payload.scale.value === null ? { x: baseTransform.scaleX, y: baseTransform.scaleY } :
            payload.scale.value) : oldScale;
        const nextPageOrigin: OriginalInkPageOrigin = replacePageOrigin ?
          payload.pageOrigin as OriginalInkPageOrigin : oldPageOrigin;
        if (replacePageOrigin) {
          const resolved: StoredPageTarget | null = await this.readPageTarget(
            store, operation.noteId, nextPageOrigin.page);
          if (resolved === null) {
            return { deferredReason: 'MODIFY_INK_DESTINATION_PAGE_MISSING_OR_UNBOUND' };
          }
          destination = samePageIdentity(target.page, resolved.page) ? target : resolved;
        }
        transform = originalInkTransform(nextPageOrigin.originX, nextPageOrigin.originY,
          nextRotation, nextScale.x, nextScale.y);
      }
      const renderSpec: RenderSpec = {
        color: color, brushWidth: width, inkStyle: originalStyleToInkStyle(style),
        isHighlighter: stroke.renderSpec.isHighlighter, isPencil: stroke.renderSpec.isPencil,
        inkEffects: inkEffects, inkEffectsTinted: inkEffectsTinted,
        inkEffectPhase: styleMap.length === 0 ? 0 : styleMap[0].backingDashPhase,
        tapePattern: tapePattern,
      };
      const candidateStroke: StrokeElementData = copyStroke(stroke, renderSpec, transform,
        customPath, fillPath, fillColorValue, styleMap);
      const appends: OriginalInkAppendRecord[] = await this.readAppends(
        store, operation.noteId, ink);
      let expected: RebuiltOriginalInkGeometry;
      let replacement: RebuiltOriginalInkGeometry;
      try {
        expected = rebuildOriginalInkGeometry(
          state.basePath, appends, stroke, state.estimatedPath.value);
        replacement = rebuildOriginalInkGeometry(
          replaceCenterPath ? payload.centerPath as Uint8Array : state.basePath,
          appends, candidateStroke, state.estimatedPath.value);
      } catch (_error) {
        if (_error instanceof PencilSplatLimitError) {
          return { deferredReason: 'MODIFY_INK_PENCIL_SPLAT_BUDGET_EXCEEDED' };
        }
        return { deferredReason: 'MODIFY_INK_TRACKED_STATE_INVALID' };
      }
      if (!originalInkGeometryMatches(stroke, expected)) {
        return { deferredReason: 'MODIFY_INK_STROKE_DIVERGED' };
      }
      if (!stroke.renderSpec.isPencil && style === 0 && !replacement.attributed) {
        return { deferredReason: 'MODIFY_INK_VARIABLE_PATH_ATTRIBUTES_MISSING' };
      }
      if (!target.hidden && (target.revision >= Number.MAX_SAFE_INTEGER ||
        destination.revision >= Number.MAX_SAFE_INTEGER)) {
        return { deferredReason: 'MODIFY_INK_PAGE_REVISION_EXHAUSTED' };
      }
      planned.push({
        target: target, state: state, stroke: stroke, geometry: replacement,
        replaceCenterPath: replaceCenterPath, replaceCustomPath: replaceCustomPath,
        replaceFillPath: replaceFillPath, replaceFillColor: replaceFillColor,
        replaceStyleMap: replaceStyleMap,
        replaceStyle: replaceStyle,
        replaceColor: replaceColor, replaceWidth: replaceWidth,
        replaceTapePattern: replaceTapePattern,
        replaceInkEffects: replaceInkEffects,
        replaceInkEffectsTinted: replaceInkEffectsTinted,
        replaceRotation: replaceRotation, replaceScale: replaceScale,
        replacePageOrigin: replacePageOrigin, replaceZIndex: replaceZIndex,
        customPathBytes: customPathBytes, fillPathBytes: fillPathBytes,
        fillColorValue: fillColorValue, styleMapBytes: styleMapBytes, styleMap: styleMap,
        baseCustomPath: baseCustomPath, baseFillPath: baseFillPath,
        baseFillColor: baseFillColor, baseStyleMap: baseStyleMap,
        style: style, color: color, width: width, tapePattern: tapePattern,
        inkEffects: inkEffects, inkEffectsTinted: inkEffectsTinted, transform: transform,
        baseTransform: state.baseTransform === null ? baseTransform : null,
        rotationValue: replaceRotation ? payload.rotation.value : state.rotation.value,
        scaleValue: replaceScale ? payload.scale.value : state.scale.value,
        destination: destination,
        basePage: state.basePage === null ? basePage : null,
        pageOriginValue: replacePageOrigin ? payload.pageOrigin : state.pageOrigin.value,
        baseZIndex: state.baseZIndex === null ? baseZIndex : null,
        zIndexValue: zIndexValue,
      });
      if (!target.hidden) {
        affectedPages.set(pageKey(target), target);
        affectedPages.set(pageKey(destination), destination);
      }
    }

    const pageMutations: Map<string, PageMutation> | null = await this.preparePageMutations(
      store, operation.noteId, planned);
    if (pageMutations === null) {
      return { deferredReason: 'MODIFY_INK_ELEMENT_ORDER_DIVERGED' };
    }
    for (const replacement of planned) {
      await this.updateState(store, operation.noteId, replacement.target.ink,
        replacement, operation, payload.centerPath);
      if (replacement.target.hidden) {
        await this.updateHiddenStroke(store, operation.noteId, replacement);
      } else if (samePageIdentity(replacement.target.page, replacement.destination.page)) {
        if (replacement.replaceZIndex) {
          await this.updateTrackedZIndex(store, operation.noteId, replacement);
        }
        await this.updateStroke(store, operation.noteId, replacement);
      } else {
        await this.moveStroke(store, operation.noteId, replacement, pageMutations);
      }
    }
    for (const mutation of pageMutations.values()) {
      await this.materializeOrder(store, operation.noteId, mutation);
    }
    for (const target of affectedPages.values()) {
      if (revisionBatch === null) {
        await this.advanceRevisionAndInvalidateSearch(store, operation.noteId, target);
      } else {
        revisionBatch.recordInk(target);
      }
    }
    return { deferredReason: null };
  }

  private async readTarget(store: relationalStore.RdbStore, noteId: string,
    ink: OperationIdentity): Promise<StoredInkTarget | null> {
    const rows = await store.querySql(
      `SELECT element.kind, element.page_timestamp, element.page_site_id, element.page_index,
              identity.page_id, identity.visible, element.z_index,
              element.visible AS element_visible
       FROM original_element_z_index element
       JOIN original_page_identity identity ON identity.note_id = element.note_id
        AND identity.seq_timestamp = element.page_timestamp
        AND identity.seq_site_id = element.page_site_id AND identity.seq_index = element.page_index
       WHERE element.note_id = ? AND element.element_timestamp = ? AND element.element_site_id = ?`,
      [noteId, ink.timestamp, ink.siteId]);
    let page: OriginalSequenceIdentity;
    let pageId: string;
    let zIndex: string;
    let hidden: boolean;
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
      zIndex = rows.getString(rows.getColumnIndex('z_index'));
      hidden = rows.getLong(rows.getColumnIndex('element_visible')) === 0;
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
      ink: ink, page: page, pageId: pageId, table: 'page_element_snapshot', zIndex: zIndex,
      revisionTable: 'page_info', revision: liveRevision, archived: false, hidden: hidden,
    } : {
      ink: ink, page: page, pageId: pageId, table: 'original_deleted_page_element',
      zIndex: zIndex, revisionTable: 'original_deleted_page',
      revision: archivedRevision as number, archived: true, hidden: hidden,
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
    if (pageId === null || pageId.length === 0) {
      return null;
    }
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
      page: page, pageId: pageId, table: 'page_element_snapshot',
      revisionTable: 'page_info', revision: liveRevision, archived: false,
    } : {
      page: page, pageId: pageId, table: 'original_deleted_page_element',
      revisionTable: 'original_deleted_page', revision: archivedRevision as number, archived: true,
    };
  }

  private async preparePageMutations(store: relationalStore.RdbStore, noteId: string,
    planned: PlannedReplacement[]): Promise<Map<string, PageMutation> | null> {
    const mutations: Map<string, PageMutation> = new Map<string, PageMutation>();
    for (const replacement of planned) {
      if (replacement.target.hidden) {
        continue;
      }
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
      const elementId: string = replacement.stroke.id;
      const sourceIndex: number = source.rows.findIndex((row: StoredZIndexRow) =>
        row.elementId === elementId && row.kind === PageElementKind.STROKE);
      if (sourceIndex < 0) {
        return null;
      }
      const oldRow: StoredZIndexRow = source.rows[sourceIndex];
      const moved: StoredZIndexRow = {
        elementId: oldRow.elementId, kind: oldRow.kind, timestamp: oldRow.timestamp,
        siteId: oldRow.siteId, zIndex: replacement.zIndexValue,
      };
      if (!changesPage) {
        source.rows[sourceIndex] = moved;
        source.rows.sort(compareStoredZIndexRows);
        continue;
      }
      const destination: PageMutation | null = await this.loadPageMutation(
        store, noteId, replacement.destination, mutations);
      if (destination === null || destination.rows.some((row: StoredZIndexRow) =>
        row.elementId === elementId && row.kind === PageElementKind.STROKE)) {
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
    const rows: StoredZIndexRow[] | null = await this.readCompleteOriginalOrder(
      store, noteId, target);
    if (rows === null) {
      return null;
    }
    const mutation: PageMutation = { target: target, rows: rows };
    mutations.set(key, mutation);
    return mutation;
  }

  private async readCompleteOriginalOrder(store: relationalStore.RdbStore, noteId: string,
    target: StoredPageTarget): Promise<StoredZIndexRow[] | null> {
    const page: OriginalSequenceIdentity = target.page;
    const tracked = await store.querySql(
      `SELECT element_timestamp, element_site_id, kind, z_index
       FROM original_element_z_index WHERE note_id = ? AND page_timestamp = ?
       AND page_site_id = ? AND page_index = ? AND visible = 1`,
      [noteId, page.timestamp, page.siteId, page.index]);
    const result: StoredZIndexRow[] = [];
    const keys: Set<string> = new Set<string>();
    try {
      while (tracked.goToNextRow()) {
        const timestamp: number = tracked.getLong(tracked.getColumnIndex('element_timestamp'));
        const siteId: number = tracked.getLong(tracked.getColumnIndex('element_site_id'));
        const kind: number = tracked.getLong(tracked.getColumnIndex('kind'));
        const elementId: string = encodeOperationId({ timestamp: timestamp, siteId: siteId });
        result.push({ elementId: elementId, kind: kind, timestamp: timestamp, siteId: siteId,
          zIndex: tracked.getString(tracked.getColumnIndex('z_index')) });
        keys.add(`${kind}:${elementId}`);
      }
    } finally {
      tracked.close();
    }
    const stored = target.archived ? await store.querySql(
      `SELECT element_id, kind FROM original_deleted_page_element WHERE note_id = ?
       AND page_timestamp = ? AND page_site_id = ? AND page_index = ?`,
      [noteId, page.timestamp, page.siteId, page.index]) : await store.querySql(
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

  private async readState(store: relationalStore.RdbStore, noteId: string,
    ink: OperationIdentity): Promise<StoredInkState | null> {
    const rows = await store.querySql(
      `SELECT base_center_path, center_path_winner_timestamp, center_path_winner_site_id,
              center_path_winner_present,
              estimated_center_path, estimated_path_winner_timestamp,
              estimated_path_winner_site_id, estimated_path_winner_present,
              create_custom_path, custom_path_value, custom_path_winner_timestamp,
              custom_path_winner_site_id, custom_path_winner_present,
              create_fill_path, fill_path_value, fill_path_winner_timestamp,
              fill_path_winner_site_id, fill_path_winner_present,
              create_fill_color, fill_color_value, fill_color_winner_timestamp,
              fill_color_winner_site_id, fill_color_winner_present,
              create_style_map, style_map_value, style_map_winner_timestamp,
              style_map_winner_site_id, style_map_winner_present,
              style_value, style_winner_timestamp, style_winner_site_id,
              style_winner_present,
              color_value, color_winner_timestamp, color_winner_site_id,
              color_winner_present,
              width_value, width_winner_timestamp, width_winner_site_id,
              width_winner_present,
              create_tape_pattern, tape_pattern_value, tape_pattern_winner_timestamp,
              tape_pattern_winner_site_id, tape_pattern_winner_present,
              create_ink_effects, ink_effects_value, ink_effects_winner_timestamp,
              ink_effects_winner_site_id, ink_effects_winner_present,
              create_ink_effects_tinted, ink_effects_tinted_value,
              ink_effects_tinted_winner_timestamp, ink_effects_tinted_winner_site_id,
              ink_effects_tinted_winner_present,
              create_origin_x, create_origin_y, create_page_timestamp, create_page_site_id,
              create_page_index, create_rotation, create_scale_x, create_scale_y,
              rotation_value, rotation_winner_timestamp, rotation_winner_site_id,
              rotation_winner_present,
              scale_x_value, scale_y_value, scale_winner_timestamp, scale_winner_site_id,
              scale_winner_present,
               page_origin_page_timestamp, page_origin_page_site_id, page_origin_page_index,
               page_origin_x, page_origin_y, page_origin_winner_timestamp,
               page_origin_winner_site_id, page_origin_winner_present,
               create_z_index, z_index_value, z_index_winner_timestamp,
               z_index_winner_site_id, z_index_winner_present
       FROM original_ink_state WHERE note_id = ? AND ink_timestamp = ? AND ink_site_id = ?`,
      [noteId, ink.timestamp, ink.siteId]);
    try {
      if (!rows.goToFirstRow()) {
        return null;
      }
      const centerPathWinner: OperationIdentity | null = readOptionalWinner(rows, 'center_path');
      const estimatedPathWinner: OperationIdentity | null = readOptionalWinner(rows, 'estimated_path');
      const estimatedPath: Uint8Array = rows.getBlob(
        rows.getColumnIndex('estimated_center_path'));
      if (estimatedPathWinner === null && estimatedPath.length > 0) {
        throw new Error('original modify-ink has estimated path without a winner');
      }
      const customPathWinner: OperationIdentity | null = readOptionalWinner(rows, 'custom_path');
      const fillPathWinner: OperationIdentity | null = readOptionalWinner(rows, 'fill_path');
      const fillColorWinner: OperationIdentity | null = readOptionalWinner(rows, 'fill_color');
      const styleMapWinner: OperationIdentity | null = readOptionalWinner(rows, 'style_map');
      const styleWinner: OperationIdentity | null = readOptionalWinner(rows, 'style');
      const colorWinner: OperationIdentity | null = readOptionalWinner(rows, 'color');
      const widthWinner: OperationIdentity | null = readOptionalWinner(rows, 'width');
      const tapePatternWinner: OperationIdentity | null = readOptionalWinner(rows, 'tape_pattern');
      const inkEffectsWinner: OperationIdentity | null = readOptionalWinner(rows, 'ink_effects');
      const inkEffectsTintedWinner: OperationIdentity | null =
        readOptionalWinner(rows, 'ink_effects_tinted');
      const rotationWinner: OperationIdentity | null = readOptionalWinner(rows, 'rotation');
      const scaleWinner: OperationIdentity | null = readOptionalWinner(rows, 'scale');
      const pageOriginWinner: OperationIdentity | null = readOptionalWinner(rows, 'page_origin');
      const zIndexWinner: OperationIdentity | null = readOptionalWinner(rows, 'z_index');
      const widthColumn: number = rows.getColumnIndex('width_value');
      const width: number | null = rows.isColumnNull(widthColumn) ? null : rows.getDouble(widthColumn);
      if (width !== null && !Number.isFinite(width)) {
        throw new Error('original modify-ink has an invalid stored width');
      }
      const baseInkEffects: string = rows.getString(rows.getColumnIndex('create_ink_effects'));
      const inkEffectsValue: string | null = readNullableString(rows, 'ink_effects_value');
      validateUnsignedLongDecimal(baseInkEffects);
      if (inkEffectsValue !== null) {
        validateUnsignedLongDecimal(inkEffectsValue);
      }
      const baseInkEffectsTinted: boolean =
        rows.getLong(rows.getColumnIndex('create_ink_effects_tinted')) !== 0;
      const inkEffectsTintedValue: boolean | null =
        readNullableBoolean(rows, 'ink_effects_tinted_value');
      const baseTapePatternValue: number | null = readNullableLong(rows, 'create_tape_pattern');
      const tapePatternValue: number | null = readNullableLong(rows, 'tape_pattern_value');
      if ((baseTapePatternValue !== null &&
        (baseTapePatternValue < TapePattern.STRIPES ||
          baseTapePatternValue > TapePattern.CHECKERS)) ||
        (tapePatternValue !== null &&
          (tapePatternValue < TapePattern.STRIPES ||
            tapePatternValue > TapePattern.CHECKERS)) ||
        (tapePatternWinner === null) !== (tapePatternValue === null)) {
        throw new Error('original modify-ink has an invalid Tape pattern register');
      }
      if ((inkEffectsWinner === null) !== (inkEffectsValue === null) ||
        (inkEffectsTintedWinner === null) !== (inkEffectsTintedValue === null)) {
        throw new Error('original modify-ink has an invalid effect register');
      }
      if ((customPathWinner === null && readNullableBlob(rows, 'custom_path_value') !== null) ||
        (fillPathWinner === null && readNullableBlob(rows, 'fill_path_value') !== null) ||
        (fillColorWinner === null && readNullableLong(rows, 'fill_color_value') !== null) ||
        (styleMapWinner === null && readNullableBlob(rows, 'style_map_value') !== null)) {
        throw new Error('original modify-ink has an auxiliary override without a winner');
      }
      const baseTransform: OriginalInkBaseTransform | null = readBaseTransform(rows);
      const basePage: OriginalSequenceIdentity | null = readNullableSequence(
        rows, 'create_page_timestamp', 'create_page_site_id', 'create_page_index');
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
      const pageOriginPage: OriginalSequenceIdentity | null = readNullableSequence(rows,
        'page_origin_page_timestamp', 'page_origin_page_site_id', 'page_origin_page_index');
      const pageOriginX: number | null = readNullableDouble(rows, 'page_origin_x');
      const pageOriginY: number | null = readNullableDouble(rows, 'page_origin_y');
      if ((pageOriginPage === null) !== (pageOriginX === null) ||
        (pageOriginPage === null) !== (pageOriginY === null) ||
        (pageOriginWinner === null) !== (pageOriginPage === null)) {
        throw new Error('original modify-ink has an invalid page/origin register');
      }
      const baseZIndex: string | null = readNullableString(rows, 'create_z_index');
      const zIndexValue: string | null = readNullableString(rows, 'z_index_value');
      if (baseZIndex !== null) {
        validateUnsignedLongDecimal(baseZIndex);
      }
      if (zIndexValue !== null) {
        validateUnsignedLongDecimal(zIndexValue);
      }
      if ((zIndexWinner === null) !== (zIndexValue === null)) {
        throw new Error('original modify-ink has an invalid z-index register');
      }
      return {
        basePath: rows.getBlob(rows.getColumnIndex('base_center_path')),
        centerPathWinner: centerPathWinner,
        estimatedPath: {
          value: estimatedPath,
          winner: estimatedPathWinner,
        },
        baseCustomPath: readNullableBlob(rows, 'create_custom_path'),
        customPath: { value: readNullableBlob(rows, 'custom_path_value'), winner: customPathWinner },
        baseFillPath: readNullableBlob(rows, 'create_fill_path'),
        fillPath: { value: readNullableBlob(rows, 'fill_path_value'), winner: fillPathWinner },
        baseFillColor: readNullableLong(rows, 'create_fill_color'),
        fillColor: { value: readNullableLong(rows, 'fill_color_value'), winner: fillColorWinner },
        baseStyleMap: readNullableBlob(rows, 'create_style_map'),
        styleMap: { value: readNullableBlob(rows, 'style_map_value'), winner: styleMapWinner },
        style: { value: readNullableLong(rows, 'style_value'), winner: styleWinner },
        color: { value: readNullableLong(rows, 'color_value'), winner: colorWinner },
        width: { value: width, winner: widthWinner },
        baseTapePattern: baseTapePatternValue as TapePattern | null,
        tapePattern: { value: tapePatternValue as TapePattern | null,
          winner: tapePatternWinner },
        baseInkEffects: baseInkEffects,
        inkEffects: { value: inkEffectsValue, winner: inkEffectsWinner },
        baseInkEffectsTinted: baseInkEffectsTinted,
        inkEffectsTinted: {
          value: inkEffectsTintedValue, winner: inkEffectsTintedWinner,
        },
        baseTransform: baseTransform,
        basePage: basePage,
        pageOrigin: {
          value: pageOriginPage === null ? null : {
            page: pageOriginPage, originX: pageOriginX as number, originY: pageOriginY as number,
          },
          winner: pageOriginWinner,
        },
        rotation: { value: rotation, winner: rotationWinner },
        scale: {
          value: scaleX === null ? null : { x: scaleX, y: scaleY as number },
          winner: scaleWinner,
        },
        baseZIndex: baseZIndex,
        zIndex: { value: zIndexValue, winner: zIndexWinner },
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
    const rows = target.hidden ? await store.querySql(
      `SELECT payload FROM original_deleted_entity WHERE note_id = ?
       AND entity_timestamp = ? AND entity_site_id = ?
       AND page_timestamp = ? AND page_site_id = ? AND page_index = ?
       AND element_id = ? AND kind = ?`,
      [noteId, target.ink.timestamp, target.ink.siteId,
        target.page.timestamp, target.page.siteId, target.page.index,
        elementId, PageElementKind.STROKE]) : target.archived ? await store.querySql(
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

  private async updateHiddenStroke(store: relationalStore.RdbStore, noteId: string,
    replacement: PlannedReplacement): Promise<void> {
    const source: StoredInkTarget = replacement.target;
    const stroke: StrokeElementData = replacementStroke(replacement);
    const persisted: PersistedElement = { kind: 'stroke', data: stroke };
    const archive = new relationalStore.RdbPredicates('original_deleted_entity');
    archive.equalTo('note_id', noteId);
    archive.equalTo('entity_timestamp', source.ink.timestamp);
    archive.equalTo('entity_site_id', source.ink.siteId);
    archive.equalTo('page_timestamp', source.page.timestamp);
    archive.equalTo('page_site_id', source.page.siteId);
    archive.equalTo('page_index', source.page.index);
    archive.equalTo('element_id', stroke.id);
    archive.equalTo('kind', PageElementKind.STROKE);
    const updatedArchive: number = await store.update({
      'page_timestamp': replacement.destination.page.timestamp,
      'page_site_id': replacement.destination.page.siteId,
      'page_index': replacement.destination.page.index,
      'payload': encodePersistedElement(persisted),
    }, archive);
    if (updatedArchive !== 1) {
      throw new Error('original modify-ink lost its hidden stroke');
    }
    const tracked = new relationalStore.RdbPredicates('original_element_z_index');
    tracked.equalTo('note_id', noteId);
    tracked.equalTo('element_timestamp', source.ink.timestamp);
    tracked.equalTo('element_site_id', source.ink.siteId);
    tracked.equalTo('page_timestamp', source.page.timestamp);
    tracked.equalTo('page_site_id', source.page.siteId);
    tracked.equalTo('page_index', source.page.index);
    tracked.equalTo('kind', PageElementKind.STROKE);
    tracked.equalTo('visible', 0);
    tracked.equalTo('z_index', source.zIndex);
    const updatedTracked: number = await store.update({
      'page_timestamp': replacement.destination.page.timestamp,
      'page_site_id': replacement.destination.page.siteId,
      'page_index': replacement.destination.page.index,
      'z_index': replacement.zIndexValue,
    }, tracked);
    if (updatedTracked !== 1) {
      throw new Error('original modify-ink lost its hidden tracked state');
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
    if (replacement.replaceCustomPath) {
      addWinnerPredicates(predicates, 'custom_path', replacement.state.customPath.winner);
      values['custom_path_value'] = replacement.customPathBytes;
      values['custom_path_winner_timestamp'] = winner.timestamp;
      values['custom_path_winner_site_id'] = winner.siteId;
      values['custom_path_winner_present'] = 1;
      if (replacement.state.baseCustomPath === null) {
        values['create_custom_path'] = replacement.baseCustomPath;
      }
    }
    if (replacement.replaceFillPath) {
      addWinnerPredicates(predicates, 'fill_path', replacement.state.fillPath.winner);
      values['fill_path_value'] = replacement.fillPathBytes;
      values['fill_path_winner_timestamp'] = winner.timestamp;
      values['fill_path_winner_site_id'] = winner.siteId;
      values['fill_path_winner_present'] = 1;
      if (replacement.state.baseFillPath === null) {
        values['create_fill_path'] = replacement.baseFillPath;
      }
    }
    if (replacement.replaceFillColor) {
      addWinnerPredicates(predicates, 'fill_color', replacement.state.fillColor.winner);
      values['fill_color_value'] = replacement.fillColorValue;
      values['fill_color_winner_timestamp'] = winner.timestamp;
      values['fill_color_winner_site_id'] = winner.siteId;
      values['fill_color_winner_present'] = 1;
      if (replacement.state.baseFillColor === null) {
        values['create_fill_color'] = replacement.baseFillColor;
      }
    }
    if (replacement.replaceStyleMap) {
      addWinnerPredicates(predicates, 'style_map', replacement.state.styleMap.winner);
      values['style_map_value'] = replacement.styleMapBytes;
      values['style_map_winner_timestamp'] = winner.timestamp;
      values['style_map_winner_site_id'] = winner.siteId;
      values['style_map_winner_present'] = 1;
      if (replacement.state.baseStyleMap === null) {
        values['create_style_map'] = replacement.baseStyleMap;
      }
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
    if (replacement.replaceTapePattern) {
      addWinnerPredicates(predicates, 'tape_pattern', replacement.state.tapePattern.winner);
      values['tape_pattern_value'] = replacement.tapePattern as TapePattern;
      values['tape_pattern_winner_timestamp'] = winner.timestamp;
      values['tape_pattern_winner_site_id'] = winner.siteId;
      values['tape_pattern_winner_present'] = 1;
    }
    if (replacement.replaceInkEffects) {
      addWinnerPredicates(predicates, 'ink_effects', replacement.state.inkEffects.winner);
      values['ink_effects_value'] = replacement.inkEffects;
      values['ink_effects_winner_timestamp'] = winner.timestamp;
      values['ink_effects_winner_site_id'] = winner.siteId;
      values['ink_effects_winner_present'] = 1;
    }
    if (replacement.replaceInkEffectsTinted) {
      addWinnerPredicates(predicates, 'ink_effects_tinted',
        replacement.state.inkEffectsTinted.winner);
      values['ink_effects_tinted_value'] = replacement.inkEffectsTinted ? 1 : 0;
      values['ink_effects_tinted_winner_timestamp'] = winner.timestamp;
      values['ink_effects_tinted_winner_site_id'] = winner.siteId;
      values['ink_effects_tinted_winner_present'] = 1;
    }
    if (replacement.baseTransform !== null) {
      values['create_origin_x'] = replacement.baseTransform.originX;
      values['create_origin_y'] = replacement.baseTransform.originY;
      values['create_rotation'] = replacement.baseTransform.rotation;
      values['create_scale_x'] = replacement.baseTransform.scaleX;
      values['create_scale_y'] = replacement.baseTransform.scaleY;
    }
    if (replacement.basePage !== null) {
      values['create_page_timestamp'] = replacement.basePage.timestamp;
      values['create_page_site_id'] = replacement.basePage.siteId;
      values['create_page_index'] = replacement.basePage.index;
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
    if (replacement.replacePageOrigin) {
      const pageOrigin: OriginalInkPageOrigin =
        replacement.pageOriginValue as OriginalInkPageOrigin;
      addWinnerPredicates(predicates, 'page_origin', replacement.state.pageOrigin.winner);
      values['page_origin_page_timestamp'] = pageOrigin.page.timestamp;
      values['page_origin_page_site_id'] = pageOrigin.page.siteId;
      values['page_origin_page_index'] = pageOrigin.page.index;
      values['page_origin_x'] = pageOrigin.originX;
      values['page_origin_y'] = pageOrigin.originY;
      values['page_origin_winner_timestamp'] = winner.timestamp;
      values['page_origin_winner_site_id'] = winner.siteId;
      values['page_origin_winner_present'] = 1;
    }
    if (replacement.baseZIndex !== null) {
      values['create_z_index'] = replacement.baseZIndex;
    }
    if (replacement.replaceZIndex) {
      addWinnerPredicates(predicates, 'z_index', replacement.state.zIndex.winner);
      values['z_index_value'] = replacement.zIndexValue;
      values['z_index_winner_timestamp'] = winner.timestamp;
      values['z_index_winner_site_id'] = winner.siteId;
      values['z_index_winner_present'] = 1;
    }
    const updated: number = await store.update(values, predicates);
    if (updated !== 1) {
      throw new Error('original modify-ink register winner changed concurrently');
    }
  }

  private async updateStroke(store: relationalStore.RdbStore, noteId: string,
    replacement: PlannedReplacement): Promise<void> {
    const target: StoredInkTarget = replacement.target;
    const updatedStroke: StrokeElementData = replacementStroke(replacement);
    const predicates = elementPredicates(noteId, target, replacement.stroke.id);
    const persisted: PersistedElement = { kind: 'stroke', data: updatedStroke };
    const updated: number = await store.update({
      'payload': encodePersistedElement(persisted), 'revision': target.revision + 1,
    }, predicates);
    if (updated !== 1) {
      throw new Error('original modify-ink lost its target stroke');
    }
  }

  private async updateTrackedZIndex(store: relationalStore.RdbStore, noteId: string,
    replacement: PlannedReplacement): Promise<void> {
    const target: StoredInkTarget = replacement.target;
    const predicates = new relationalStore.RdbPredicates('original_element_z_index');
    predicates.equalTo('note_id', noteId);
    predicates.equalTo('element_timestamp', target.ink.timestamp);
    predicates.equalTo('element_site_id', target.ink.siteId);
    predicates.equalTo('page_timestamp', target.page.timestamp);
    predicates.equalTo('page_site_id', target.page.siteId);
    predicates.equalTo('page_index', target.page.index);
    predicates.equalTo('kind', PageElementKind.STROKE);
    predicates.equalTo('z_index', target.zIndex);
    const updated: number = await store.update({ 'z_index': replacement.zIndexValue }, predicates);
    if (updated !== 1) {
      throw new Error('original modify-ink lost its tracked z-index');
    }
  }

  private async moveStroke(store: relationalStore.RdbStore, noteId: string,
    replacement: PlannedReplacement, mutations: Map<string, PageMutation>): Promise<void> {
    const source: StoredInkTarget = replacement.target;
    const destination: StoredPageTarget = replacement.destination;
    const stroke: StrokeElementData = replacementStroke(replacement);
    const deleted: number = await store.delete(elementPredicates(noteId, source, stroke.id));
    if (deleted !== 1) {
      throw new Error('original modify-ink lost its source stroke');
    }
    const destinationMutation: PageMutation | undefined = mutations.get(pageKey(destination));
    if (destinationMutation === undefined) {
      throw new Error('original modify-ink has no destination order');
    }
    const elementOrder: number = destinationMutation.rows.findIndex((row: StoredZIndexRow) =>
      row.elementId === stroke.id && row.kind === PageElementKind.STROKE);
    if (elementOrder < 0) {
      throw new Error('original modify-ink destination order lost its stroke');
    }
    const persisted: PersistedElement = { kind: 'stroke', data: stroke };
    const values: relationalStore.ValuesBucket = {
      'note_id': noteId, 'element_id': stroke.id, 'kind': PageElementKind.STROKE,
      'payload': encodePersistedElement(persisted), 'revision': destination.revision + 1,
      'element_order': elementOrder,
    };
    if (destination.archived) {
      values['page_timestamp'] = destination.page.timestamp;
      values['page_site_id'] = destination.page.siteId;
      values['page_index'] = destination.page.index;
    } else {
      values['page_id'] = destination.pageId;
    }
    await store.insert(destination.table, values);
    const predicates = new relationalStore.RdbPredicates('original_element_z_index');
    predicates.equalTo('note_id', noteId);
    predicates.equalTo('element_timestamp', source.ink.timestamp);
    predicates.equalTo('element_site_id', source.ink.siteId);
    predicates.equalTo('page_timestamp', source.page.timestamp);
    predicates.equalTo('page_site_id', source.page.siteId);
    predicates.equalTo('page_index', source.page.index);
    predicates.equalTo('kind', PageElementKind.STROKE);
    predicates.equalTo('z_index', source.zIndex);
    const updated: number = await store.update({
      'page_timestamp': destination.page.timestamp,
      'page_site_id': destination.page.siteId,
      'page_index': destination.page.index,
      'z_index': replacement.zIndexValue,
    }, predicates);
    if (updated !== 1) {
      throw new Error('original modify-ink lost its tracked page assignment');
    }
  }

  private async materializeOrder(store: relationalStore.RdbStore, noteId: string,
    mutation: PageMutation): Promise<void> {
    for (let index: number = 0; index < mutation.rows.length; index++) {
      const row: StoredZIndexRow = mutation.rows[index];
      const predicates = pageElementPredicates(noteId, mutation.target, row.elementId, row.kind);
      const updated: number = await store.update({ 'element_order': index }, predicates);
      if (updated !== 1) {
        throw new Error('original modify-ink order materialization lost an element');
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
  return pageElementPredicates(noteId, target, elementId, PageElementKind.STROKE);
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

function preflightOriginalModifyInk(payload: OriginalModifyInkPayload): string | null {
  if ((payload.pageOrigin !== null && (!Number.isFinite(payload.pageOrigin.originX) ||
    !Number.isFinite(payload.pageOrigin.originY))) ||
    (payload.rotation.value !== null && !Number.isFinite(payload.rotation.value)) ||
    (payload.scale.value !== null && (!Number.isFinite(payload.scale.value.x) ||
      !Number.isFinite(payload.scale.value.y)))) {
    return 'MODIFY_INK_TRANSFORM_UNSUPPORTED';
  }
  if (payload.width !== null && (!Number.isFinite(payload.width) || payload.width < 0)) {
    return 'MODIFY_INK_WIDTH_UNSUPPORTED';
  }
  try {
    if (payload.centerPath !== null) {
      decodeOriginalInkPathReplacement(payload.centerPath);
    }
    if (payload.customPath.present && payload.customPath.value !== null) {
      decodeOriginalAuxiliaryInkPath(payload.customPath.value, 'MODIFY_INK_CUSTOM_PATH');
    }
    if (payload.fillPath.present && payload.fillPath.value !== null) {
      decodeOriginalAuxiliaryInkPath(payload.fillPath.value, 'MODIFY_INK_FILL_PATH');
    }
    if (payload.styleMap.present && decodeOriginalInkStyleMap(payload.styleMap.value).length > 1) {
      return 'MALFORMED_MODIFY_INK_PAYLOAD';
    }
  } catch (_error) {
    if (_error instanceof OriginalInkPathDeferredError) {
      return _error.deferredReason;
    }
    return 'MALFORMED_MODIFY_INK_PAYLOAD';
  }
  return null;
}

function normalizeOriginalInkStyle(value: number): number {
  return value >= 0 && value <= 3 ? value : 0;
}

function normalizeOriginalEnum(value: number, maximum: number): number {
  return value >= 0 && value <= maximum ? value : 0;
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
  transform: TransformMatrix, customPath: InkPathCommand[] | null,
  fillPath: InkPathCommand[] | null, fillColor: number | null,
  styleMap: InkStyleMapEntry[]): StrokeElementData {
  return {
    id: stroke.id, pathPoints: stroke.pathPoints, cubicSegments: stroke.cubicSegments,
    splatPoints: stroke.splatPoints, renderSpec: renderSpec, transform: transform,
    bounds: stroke.bounds, maskPath: stroke.maskPath,
    customPath: customPath, fillPath: fillPath, fillColor: fillColor,
    styleMap: styleMap,
    isFinished: stroke.isFinished,
  };
}

function replacementStroke(replacement: PlannedReplacement): StrokeElementData {
  const stroke: StrokeElementData = replacement.stroke;
  return {
    id: stroke.id,
    pathPoints: replacement.geometry.pathPoints,
    cubicSegments: replacement.geometry.cubicSegments,
    splatPoints: replacement.geometry.splatPoints,
    renderSpec: {
      color: replacement.color,
      brushWidth: replacement.width,
      inkStyle: originalStyleToInkStyle(replacement.style),
      isHighlighter: stroke.renderSpec.isHighlighter,
      isPencil: stroke.renderSpec.isPencil,
      inkEffects: replacement.inkEffects,
      inkEffectsTinted: replacement.inkEffectsTinted,
      inkEffectPhase: replacement.styleMap.length === 0 ? 0 :
        replacement.styleMap[0].backingDashPhase,
      tapePattern: replacement.tapePattern,
    },
    transform: replacement.transform,
    bounds: replacement.geometry.bounds,
    maskPath: stroke.maskPath,
    customPath: replacement.customPathBytes === null ? null :
      decodeStoredAuxiliaryPath(replacement.customPathBytes, 'MODIFY_INK_CUSTOM_PATH'),
    fillPath: replacement.fillPathBytes === null ? null :
      decodeStoredAuxiliaryPath(replacement.fillPathBytes, 'MODIFY_INK_FILL_PATH'),
    fillColor: replacement.fillColorValue,
    styleMap: replacement.styleMap,
    isFinished: stroke.isFinished,
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

function readNullableBlob(rows: relationalStore.ResultSet, columnName: string): Uint8Array | null {
  const column: number = rows.getColumnIndex(columnName);
  return rows.isColumnNull(column) ? null : rows.getBlob(column);
}

function decodeStoredAuxiliaryPath(bytes: Uint8Array | null,
  reasonPrefix: string): InkPathCommand[] | null {
  if (bytes === null) {
    return null;
  }
  const decoded: DecodedOriginalAuxiliaryInkPath =
    decodeOriginalAuxiliaryInkPath(bytes, reasonPrefix);
  return decoded.commands.length === 0 ? null : decoded.commands;
}

function sameOptionalValue(left: InkPathCommand[] | null | undefined,
  right: InkPathCommand[] | null): boolean {
  const normalizedLeft: InkPathCommand[] | null = left === undefined ? null : left;
  return JSON.stringify(normalizedLeft) === JSON.stringify(right);
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

function readNullableString(rows: relationalStore.ResultSet, columnName: string): string | null {
  const column: number = rows.getColumnIndex(columnName);
  return rows.isColumnNull(column) ? null : rows.getString(column);
}

function readNullableBoolean(rows: relationalStore.ResultSet,
  columnName: string): boolean | null {
  const column: number = rows.getColumnIndex(columnName);
  if (rows.isColumnNull(column)) {
    return null;
  }
  const value: number = rows.getLong(column);
  if (value !== 0 && value !== 1) {
    throw new Error(`original modify-ink has an invalid ${columnName}`);
  }
  return value !== 0;
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

function readNullableSequence(rows: relationalStore.ResultSet, timestampColumn: string,
  siteColumn: string, indexColumn: string): OriginalSequenceIdentity | null {
  const timestamp: number | null = readNullableLong(rows, timestampColumn);
  const siteId: number | null = readNullableLong(rows, siteColumn);
  const index: number | null = readNullableLong(rows, indexColumn);
  const presentCount: number = [timestamp, siteId, index]
    .filter((value: number | null) => value !== null).length;
  if (presentCount === 0) {
    return null;
  }
  if (presentCount !== 3) {
    throw new Error('original modify-ink has a partial stored sequence');
  }
  const sequence: OriginalSequenceIdentity = {
    timestamp: timestamp as number, siteId: siteId as number, index: index as number,
  };
  validateOriginalSequenceIdentity(sequence);
  return sequence;
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

function assertMatchingModifyInkWinners(payload: OriginalModifyInkPayload,
  state: StoredInkState, operation: OperationIdentity): void {
  if (payload.centerPath !== null && winnerMatches(state.centerPathWinner, operation) &&
    !sameNullableBytes(state.basePath, payload.centerPath)) {
    throw new Error('original modify-ink identity conflicts with persisted center path');
  }
  if (payload.customPath.present && winnerMatches(state.customPath.winner, operation) &&
    !sameNullableBytes(state.customPath.value, payload.customPath.value)) {
    throw new Error('original modify-ink identity conflicts with persisted custom path');
  }
  if (payload.fillPath.present && winnerMatches(state.fillPath.winner, operation) &&
    !sameNullableBytes(state.fillPath.value, payload.fillPath.value)) {
    throw new Error('original modify-ink identity conflicts with persisted fill path');
  }
  if (payload.fillColor.present && winnerMatches(state.fillColor.winner, operation) &&
    state.fillColor.value !== payload.fillColor.value) {
    throw new Error('original modify-ink identity conflicts with persisted fill color');
  }
  if (payload.styleMap.present && winnerMatches(state.styleMap.winner, operation) &&
    !sameNullableBytes(state.styleMap.value, payload.styleMap.value)) {
    throw new Error('original modify-ink identity conflicts with persisted style map');
  }
  if (payload.style !== null && winnerMatches(state.style.winner, operation) &&
    state.style.value !== payload.style) {
    throw new Error('original modify-ink identity conflicts with persisted style');
  }
  if (payload.color !== null && winnerMatches(state.color.winner, operation) &&
    state.color.value !== payload.color) {
    throw new Error('original modify-ink identity conflicts with persisted color');
  }
  if (payload.width !== null && winnerMatches(state.width.winner, operation) &&
    state.width.value !== payload.width) {
    throw new Error('original modify-ink identity conflicts with persisted width');
  }
  if (payload.tapePattern !== null && winnerMatches(state.tapePattern.winner, operation) &&
    state.tapePattern.value !== payload.tapePattern) {
    throw new Error('original modify-ink identity conflicts with persisted Tape pattern');
  }
  if (payload.inkEffects !== null && winnerMatches(state.inkEffects.winner, operation) &&
    state.inkEffects.value !== payload.inkEffects) {
    throw new Error('original modify-ink identity conflicts with persisted effects');
  }
  if (payload.inkEffectsTinted !== null &&
    winnerMatches(state.inkEffectsTinted.winner, operation) &&
    state.inkEffectsTinted.value !== payload.inkEffectsTinted) {
    throw new Error('original modify-ink identity conflicts with persisted effect tint');
  }
  if (payload.rotation.present && winnerMatches(state.rotation.winner, operation) &&
    state.rotation.value !== payload.rotation.value) {
    throw new Error('original modify-ink identity conflicts with persisted rotation');
  }
  if (payload.scale.present && winnerMatches(state.scale.winner, operation) &&
    !sameNullableScale(state.scale.value, payload.scale.value)) {
    throw new Error('original modify-ink identity conflicts with persisted scale');
  }
  if (payload.pageOrigin !== null && winnerMatches(state.pageOrigin.winner, operation) &&
    !sameNullablePageOrigin(state.pageOrigin.value, payload.pageOrigin)) {
    throw new Error('original modify-ink identity conflicts with persisted page/origin');
  }
  if (payload.zIndex !== null && winnerMatches(state.zIndex.winner, operation) &&
    state.zIndex.value !== payload.zIndex) {
    throw new Error('original modify-ink identity conflicts with persisted z-index');
  }
}

function winnerMatches(winner: OperationIdentity | null, operation: OperationIdentity): boolean {
  return winner !== null && compareOperationIdentity(winner, operation) === 0;
}

function sameNullableBytes(left: Uint8Array | null, right: Uint8Array | null): boolean {
  if (left === null || right === null) {
    return left === right;
  }
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

function normalizedStoredInkEffects(value: string | undefined): string {
  return value === undefined ? '0' : value;
}

function normalizedStoredInkEffectsTinted(value: boolean | undefined): boolean {
  return value === undefined ? true : value;
}

function sameNullableScale(left: OriginalInkScale | null, right: OriginalInkScale | null): boolean {
  if (left === null || right === null) {
    return left === right;
  }
  return left.x === right.x && left.y === right.y;
}

function sameNullablePageOrigin(left: OriginalInkPageOrigin | null,
  right: OriginalInkPageOrigin | null): boolean {
  if (left === null || right === null) {
    return left === right;
  }
  return samePageIdentity(left.page, right.page) &&
    left.originX === right.originX && left.originY === right.originY;
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
    if (!Number.isSafeInteger(revision) || revision < 0) {
      throw new Error('original target page has an invalid revision');
    }
    return revision;
  } finally {
    rows.close();
  }
}
