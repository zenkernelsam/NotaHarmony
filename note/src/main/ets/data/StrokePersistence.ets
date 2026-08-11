import { relationalStore } from '@kit.ArkData';
import { PageInfo } from '../core/model/NoteTypes';
import { parsePageBackground } from '../core/model/PageBackgroundModel';
import { readEffectiveNoteBackground } from './OriginalSetMetadataOperation';
import { HistoryCoalesceTrack, HistoryEffect, HistoryMetadata, Op, OpType } from '../core/model/OpTypes';
import { taskpool, util } from '@kit.ArkTS';
import { InkStyle, OriginalInkCreateMetadata, StrokeElementData } from '../core/model/StrokeTypes';
import {
  ElementType, ImageElement, MathElement, OriginalShapeCreateMetadata, RichTextCharacterStyleRun,
  RichTextParagraphStyleRun, ShapeElement, TextBlockElement,
} from '../core/model/ElementTypes';
import { Rect2D, TransformMatrix } from '../core/model/GeometryTypes';
import {
  cloneImageElement, imageBlockWorldBounds, originalAssetHashKey, reflectImageCropRect,
} from '../core/model/ImageBlockGeometry';
import { cloneShapeElement, recomputeShapeBounds } from '../core/model/ShapeGeometry';
import { cloneTextBlockElement, textBlockWorldBounds } from '../core/model/TextBlockGeometry';
import { cloneMathElement, mathBlockWorldBounds } from '../core/model/MathBlockGeometry';
import {
  legacyPageElementOrder, materializePageElements, normalizePageElementOrder, OrderedPageElement,
  PageElementKind, PageElementRef, samePageElementOrder,
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
  replayPageMutation,
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
import { encodeOriginalLocalCreateShape } from './OriginalCreateShapePayloadEncoder';
import {
  encodeOriginalLocalCreateImageBlock, encodeOriginalLocalCreateMathBlock,
  encodeOriginalLocalCreateTextBlock,
} from './OriginalCreateBlockPayloadEncoder';
import {
  EncodedOriginalTextOperation, encodeOriginalInitialInsertString,
  encodeOriginalTextInsertion, encodeOriginalTextVisibility,
} from './OriginalInsertTextPayloadEncoder';
import {
  OriginalLocalTextMutationPlan, OriginalLocalTextMutationPreview,
  planOriginalLocalTextMutation, predictOriginalTextInsertionIdentity,
  previewOriginalLocalTextMutation,
} from './OriginalLocalTextMutation';
import {
  materializeOriginalTextStyles, readOriginalCheckboxStates,
  readOriginalTextStyleOperations, StoredOriginalCheckboxState,
  StoredOriginalTextStyleOperation,
} from './OriginalRichTextStyleState';
import { encodeOriginalCreateGroup } from './OriginalGroupPayloadEncoder';
import {
  encodeOriginalGroupMutation, OriginalGroupMutationOpPayload,
  sameOriginalSelectionGroups, validateOriginalGroupMutation,
} from './OriginalGroupMutationOpCodec';
import {
  decodeOriginalClipboardPasteMutation, encodeOriginalClipboardPasteMutation,
  OriginalClipboardPasteMutation,
  validateOriginalClipboardPasteMutation,
} from './OriginalClipboardPasteMutationCodec';
import {
  decodeOriginalCreateInk, ORIGINAL_CREATE_INK_PAYLOAD_TYPE, OriginalCreateInkOperationApplier,
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
import {
  encodeOriginalShapeRenderRegisters, OriginalShapeRenderRegisterUpdate,
} from './OriginalModifyShapePayloadEncoder';
import { encodeOriginalOperationEnvelope } from './OriginalOperationEnvelopeEncoder';
import {
  decodeOriginalModifyInk, ORIGINAL_MODIFY_INK_PAYLOAD_TYPE, OriginalModifyInkOperationApplier,
  OriginalModifyInkPayload,
} from './OriginalModifyInkOperation';
import {
  decodeOriginalCreateShape, decodeOriginalModifyShape, ORIGINAL_CREATE_SHAPE_PAYLOAD_TYPE,
  ORIGINAL_CREATE_GROUP_PAYLOAD_TYPE, ORIGINAL_MODIFY_SHAPE_PAYLOAD_TYPE,
  OriginalCreateShapePayload, OriginalModifyShapePayload, OriginalShapeGroupOperationApplier,
} from './OriginalShapeGroupOperation';
import {
  encodeOriginalBlockPositionLocked, encodeOriginalBlockSize, encodeOriginalImageCrop,
  encodeOriginalImageFlip,
} from './OriginalModifyBlockPayloadEncoder';
import {
  decodeOriginalModifyBlock, ORIGINAL_MODIFY_BLOCK_PAYLOAD_TYPE,
  OriginalModifyBlockOperationApplier, OriginalModifyBlockPayload,
} from './OriginalModifyBlockOperation';
import {
  decodeOriginalCreateBlock, ORIGINAL_CREATE_BLOCK_PAYLOAD_TYPE, OriginalBlockRect,
  OriginalBlockType, OriginalCreateBlockOperationApplier, OriginalCreateBlockPayload,
} from './OriginalCreateBlockOperation';
import {
  decodeOriginalInsertText, decodeOriginalTextVisibility,
  ORIGINAL_INSERT_STRING_PAYLOAD_TYPE, OriginalInsertTextOperationApplier,
  OriginalTextVisibilityOperationApplier, StoredCharacter,
} from './OriginalInsertTextOperation';
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

export interface OriginalGroupMutationResult {
  mutation: OriginalGroupMutationOpPayload;
  groups: OriginalSelectionGroup[];
}

export interface OriginalClipboardPastePlan {
  strokes: StrokeElementData[];
  shapes: ShapeElement[];
  textBlocks: TextBlockElement[];
  images: ImageElement[];
  mathBlocks: MathElement[];
  elementOrder: PageElementRef[];
  groups: OriginalSelectionGroup[];
  topGroupIds: string[];
}

export interface OriginalClipboardPastePersistenceResult {
  strokes: StrokeElementData[];
  shapes: ShapeElement[];
  textBlocks: TextBlockElement[];
  images: ImageElement[];
  mathBlocks: MathElement[];
  elementOrder: PageElementRef[];
  groups: OriginalSelectionGroup[];
  topGroupIds: string[];
  mutation: OriginalClipboardPasteMutation;
  operation: Op;
}

export interface OriginalClipboardPasteHistoryResult {
  elements: SearchSourceElement[];
  elementOrder: PageElementRef[];
  groups: OriginalSelectionGroup[];
}

const MAX_ORIGINAL_CLIPBOARD_PASTE_LEAVES: number = 10000;

export function validateOriginalClipboardPastePlan(plan: OriginalClipboardPastePlan): void {
  const leafCount: number = plan.strokes.length + plan.shapes.length + plan.textBlocks.length +
    plan.images.length + plan.mathBlocks.length;
  if (leafCount === 0 || leafCount > MAX_ORIGINAL_CLIPBOARD_PASTE_LEAVES ||
    plan.elementOrder.length !== leafCount || plan.groups.length === 0 ||
    plan.groups.length > MAX_ORIGINAL_CLIPBOARD_PASTE_LEAVES ||
    plan.topGroupIds.length === 0 || plan.topGroupIds.length > plan.groups.length) {
    throw new Error('original clipboard Paste plan has an invalid size');
  }
  if (leafCount + plan.groups.length > MAX_ORIGINAL_DELETE_ENTITY_COUNT) {
    throw new Error('original clipboard Paste exceeds one type-25 visibility payload');
  }
  const page: OriginalSequenceIdentity = { timestamp: 1, siteId: 1, index: 0 };
  const leafKinds: Map<string, PageElementKind> = new Map<string, PageElementKind>();
  const addLeaf = (id: string, kind: PageElementKind): void => {
    if (decodeOperationId(id) === null || leafKinds.has(id)) {
      throw new Error('original clipboard Paste repeats or has a non-original leaf');
    }
    leafKinds.set(id, kind);
  };
  for (const stroke of plan.strokes) {
    addLeaf(stroke.id, PageElementKind.STROKE);
    encodeOriginalLocalCreateInk(page, stroke);
  }
  for (const shape of plan.shapes) {
    addLeaf(shape.id, PageElementKind.SHAPE);
    if ((shape.characterStyleRuns ?? []).length !== 0 ||
      (shape.paragraphStyleRuns ?? []).length !== 0) {
      throw new Error('original clipboard Paste Shape RichText is unsupported');
    }
    encodeOriginalLocalCreateShape(page, shape, null);
  }
  for (const text of plan.textBlocks) {
    addLeaf(text.id, PageElementKind.TEXT);
    encodeOriginalLocalCreateTextBlock(page, text);
    if (text.richText.length > 0) {
      encodeOriginalInitialInsertString({ timestamp: 1, siteId: 1 }, text.richText);
    }
  }
  for (const image of plan.images) {
    addLeaf(image.id, PageElementKind.IMAGE);
    encodeOriginalLocalCreateImageBlock(page, image);
  }
  for (const math of plan.mathBlocks) {
    addLeaf(math.id, PageElementKind.MATH);
    encodeOriginalLocalCreateMathBlock(page, math);
  }
  const orderedLeaves: Set<string> = new Set<string>();
  for (let index: number = 0; index < plan.elementOrder.length; index++) {
    const ref: PageElementRef = plan.elementOrder[index];
    if (ref.zIndex !== index || leafKinds.get(ref.elementId) !== ref.kind ||
      orderedLeaves.has(ref.elementId)) {
      throw new Error('original clipboard Paste leaf order is invalid');
    }
    orderedLeaves.add(ref.elementId);
  }
  const available: Set<string> = new Set<string>();
  leafKinds.forEach((_kind: PageElementKind, id: string): void => { available.add(id); });
  const groupIds: Set<string> = new Set<string>();
  const parentByMember: Map<string, string> = new Map<string, string>();
  for (const group of plan.groups) {
    const identity: OperationIdentity | null = decodeOperationId(group.id);
    if (identity === null || identity.timestamp !== group.timestamp ||
      identity.siteId !== group.siteId || available.has(group.id) || groupIds.has(group.id) ||
      group.members.length === 0 || group.members.length > MAX_ORIGINAL_CLIPBOARD_PASTE_LEAVES) {
      throw new Error('original clipboard Paste source Group is invalid');
    }
    const members: Set<string> = new Set<string>();
    for (const member of group.members) {
      if (!available.has(member) || members.has(member) || parentByMember.has(member)) {
        throw new Error('original clipboard Paste Groups are not a bottom-up single-parent graph');
      }
      members.add(member);
      parentByMember.set(member, group.id);
    }
    groupIds.add(group.id);
    available.add(group.id);
  }
  const expectedRoots: Set<string> = new Set<string>();
  groupIds.forEach((id: string): void => {
    if (!parentByMember.has(id)) {
      expectedRoots.add(id);
    }
  });
  const actualRoots: Set<string> = new Set<string>();
  for (const id of plan.topGroupIds) {
    if (!expectedRoots.has(id) || actualRoots.has(id)) {
      throw new Error('original clipboard Paste top Group set is invalid');
    }
    actualRoots.add(id);
  }
  if (actualRoots.size !== expectedRoots.size) {
    throw new Error('original clipboard Paste omits a top Group');
  }
}

export interface OriginalTextEditPreview {
  characterStyleRuns: RichTextCharacterStyleRun[];
  paragraphStyleRuns: RichTextParagraphStyleRun[];
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

interface OriginalTextMutation {
  block: OperationIdentity;
  plan: OriginalLocalTextMutationPlan;
  width: number;
  height: number;
  sizeChanged: boolean;
}

export interface OriginalInkRenderMutationBatch extends OriginalInkRenderRegisterUpdate {
  identities: OperationIdentity[];
}

export interface OriginalShapeRenderMutationBatch extends OriginalShapeRenderRegisterUpdate {
  identities: OperationIdentity[];
  expectedTools: number[];
  expectedStyles: number[];
}

export interface OriginalRenderMutation {
  inkBatches: OriginalInkRenderMutationBatch[];
  shapeBatches: OriginalShapeRenderMutationBatch[];
}

export interface OriginalShapeStateRenderMetadata {
  tool: number;
  style: number;
  positionLocked: boolean;
}

export function decodeOriginalShapeStateRenderMetadata(
  resolvedPayload: string): OriginalShapeStateRenderMetadata | null {
  try {
    const payload: OriginalCreateShapePayload =
      JSON.parse(resolvedPayload) as OriginalCreateShapePayload;
    const positionLocked: boolean = payload.positionLocked === undefined ? false :
      payload.positionLocked;
    if (!Number.isInteger(payload.tool) || payload.tool < 0 || payload.tool > 7 ||
      !Number.isInteger(payload.style) || payload.style < 1 || payload.style > 3 ||
      typeof positionLocked !== 'boolean') {
      return null;
    }
    return { tool: payload.tool, style: payload.style,
      positionLocked: positionLocked };
  } catch (_error) {
    return null;
  }
}

export function decodeOriginalShapeStateTool(resolvedPayload: string): number | null {
  const metadata: OriginalShapeStateRenderMetadata | null =
    decodeOriginalShapeStateRenderMetadata(resolvedPayload);
  return metadata === null ? null : metadata.tool;
}

export function classifyOriginalRenderMutation(current: SearchSourceElement[],
  next: SearchSourceElement[]): OriginalRenderMutation | null {
  if (!samePreparedIdentityOrder(current, next)) {
    return null;
  }
  const inkBatches: Map<string, OriginalInkRenderMutationBatch> =
    new Map<string, OriginalInkRenderMutationBatch>();
  const shapeBatches: Map<string, OriginalShapeRenderMutationBatch> =
    new Map<string, OriginalShapeRenderMutationBatch>();
  for (let index: number = 0; index < current.length; index++) {
    if (sameByteArrays(current[index].payload, next[index].payload)) {
      continue;
    }
    try {
      const beforePersisted: PersistedElement = decodePersistedElement(current[index].payload);
      const afterPersisted: PersistedElement = decodePersistedElement(next[index].payload);
      if (current[index].kind === PageElementKind.STROKE &&
        beforePersisted.kind === 'stroke' && afterPersisted.kind === 'stroke') {
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
        if (!sameByteArrays(encodePersistedElement({ kind: 'stroke', data: candidate }),
          next[index].payload)) {
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
        const batch: OriginalInkRenderMutationBatch | undefined = inkBatches.get(key);
        if (batch === undefined) {
          inkBatches.set(key, { identities: [identity], style: update.style,
            color: update.color, width: update.width });
        } else {
          batch.identities.push(identity);
        }
        continue;
      }
      if (current[index].kind === PageElementKind.SHAPE &&
        beforePersisted.kind === 'shape' && afterPersisted.kind === 'shape') {
        const before: ShapeElement = beforePersisted.data as ShapeElement;
        const after: ShapeElement = afterPersisted.data as ShapeElement;
        const identity: OperationIdentity | null = decodeOperationId(before.id);
        const styleChanged: boolean = before.originalStyle !== after.originalStyle;
        const colorChanged: boolean = before.color !== after.color;
        const widthChanged: boolean = before.strokeWidth !== after.strokeWidth;
        const fillChanged: boolean = before.fillColor !== after.fillColor;
        if (identity === null || before.id !== after.id || after.originalTool === undefined ||
          after.originalStyle === undefined ||
          (before.originalTool !== undefined && before.originalTool !== after.originalTool) ||
          !Number.isInteger(after.originalStyle) || after.originalStyle < 1 || after.originalStyle > 3) {
          return null;
        }
        const expectedStyle: number = before.originalStyle === undefined ?
          after.originalStyle : before.originalStyle;
        const candidate: ShapeElement = cloneShapeElement(before);
        candidate.originalTool = after.originalTool;
        candidate.originalStyle = after.originalStyle;
        candidate.color = colorChanged ? after.color : before.color;
        candidate.strokeWidth = widthChanged ? after.strokeWidth : before.strokeWidth;
        candidate.fillColor = fillChanged ? after.fillColor : before.fillColor;
        if (!sameByteArrays(encodePersistedElement({ kind: 'shape', data: candidate }),
          next[index].payload)) {
          return null;
        }
        if (!styleChanged && !colorChanged && !widthChanged && !fillChanged) {
          continue;
        }
        const update: OriginalShapeRenderRegisterUpdate = {
          style: styleChanged ? after.originalStyle : null,
          color: colorChanged ? after.color : null,
          borderWidth: widthChanged ? after.strokeWidth : null,
          fillColorPresent: fillChanged,
          fillColor: fillChanged ? after.fillColor : null,
          positionLocked: null,
        };
        const key: string = `${update.style === null ? 'x' : update.style}|` +
          `${update.color === null ? 'x' : update.color}|` +
          `${update.borderWidth === null ? 'x' : update.borderWidth}|` +
          `${update.fillColorPresent ? update.fillColor === null ? 'n' : update.fillColor : 'x'}`;
        const batch: OriginalShapeRenderMutationBatch | undefined = shapeBatches.get(key);
        if (batch === undefined) {
          shapeBatches.set(key, { identities: [identity], expectedTools: [after.originalTool],
            expectedStyles: [expectedStyle], style: update.style,
            color: update.color,
            borderWidth: update.borderWidth, fillColorPresent: update.fillColorPresent,
            fillColor: update.fillColor, positionLocked: null });
        } else {
          batch.identities.push(identity);
          batch.expectedTools.push(after.originalTool);
          batch.expectedStyles.push(expectedStyle);
        }
        continue;
      }
      return null;
    } catch (_error) {
      return null;
    }
  }
  if (inkBatches.size === 0 && shapeBatches.size === 0) {
    return null;
  }
  return { inkBatches: Array.from(inkBatches.values()),
    shapeBatches: Array.from(shapeBatches.values()) };
}

export interface OriginalPositionLockMutationBatch {
  identities: OperationIdentity[];
  expectedLocked: boolean[];
  locked: boolean;
}

export interface OriginalPositionLockMutation {
  shapeBatches: OriginalPositionLockMutationBatch[];
  blockBatches: OriginalPositionLockMutationBatch[];
}

export function classifyOriginalPositionLockMutation(current: SearchSourceElement[],
  next: SearchSourceElement[]): OriginalPositionLockMutation | null {
  if (!samePreparedIdentityOrder(current, next)) {
    return null;
  }
  const shapeBatches: Map<string, OriginalPositionLockMutationBatch> =
    new Map<string, OriginalPositionLockMutationBatch>();
  const blockBatches: Map<string, OriginalPositionLockMutationBatch> =
    new Map<string, OriginalPositionLockMutationBatch>();
  for (let index: number = 0; index < current.length; index++) {
    if (sameByteArrays(current[index].payload, next[index].payload)) {
      continue;
    }
    try {
      const beforePersisted: PersistedElement = decodePersistedElement(current[index].payload);
      const afterPersisted: PersistedElement = decodePersistedElement(next[index].payload);
      let identity: OperationIdentity | null = null;
      let expectedLocked: boolean = false;
      let locked: boolean = false;
      let batches: Map<string, OriginalPositionLockMutationBatch> | null = null;
      if (current[index].kind === PageElementKind.SHAPE &&
        beforePersisted.kind === 'shape' && afterPersisted.kind === 'shape') {
        const before: ShapeElement = beforePersisted.data as ShapeElement;
        const after: ShapeElement = afterPersisted.data as ShapeElement;
        identity = decodeOperationId(before.id);
        expectedLocked = before.positionLocked === true;
        locked = after.positionLocked === true;
        const candidate: ShapeElement = cloneShapeElement(before);
        candidate.positionLocked = locked;
        if (before.id !== after.id || expectedLocked === locked ||
          !sameByteArrays(encodePersistedElement({ kind: 'shape', data: candidate }),
            next[index].payload)) {
          return null;
        }
        batches = shapeBatches;
      } else if (current[index].kind === PageElementKind.TEXT &&
        beforePersisted.kind === 'text' && afterPersisted.kind === 'text') {
        const before: TextBlockElement = beforePersisted.data as TextBlockElement;
        const after: TextBlockElement = afterPersisted.data as TextBlockElement;
        identity = decodeOperationId(before.id);
        expectedLocked = before.positionLocked === true;
        locked = after.positionLocked === true;
        const candidate: TextBlockElement = cloneTextBlockElement(before);
        candidate.positionLocked = locked;
        if (before.id !== after.id || expectedLocked === locked ||
          !sameByteArrays(encodePersistedElement({ kind: 'text', data: candidate }),
            next[index].payload)) {
          return null;
        }
        batches = blockBatches;
      } else if (current[index].kind === PageElementKind.IMAGE &&
        beforePersisted.kind === 'image' && afterPersisted.kind === 'image') {
        const before: ImageElement = beforePersisted.data as ImageElement;
        const after: ImageElement = afterPersisted.data as ImageElement;
        identity = decodeOperationId(before.id);
        expectedLocked = before.positionLocked;
        locked = after.positionLocked;
        const candidate: ImageElement = cloneImageElement(before);
        candidate.positionLocked = locked;
        if (before.id !== after.id || expectedLocked === locked ||
          !sameByteArrays(encodePersistedElement({ kind: 'image', data: candidate }),
            next[index].payload)) {
          return null;
        }
        batches = blockBatches;
      } else if (current[index].kind === PageElementKind.MATH &&
        beforePersisted.kind === 'math' && afterPersisted.kind === 'math') {
        const before: MathElement = beforePersisted.data as MathElement;
        const after: MathElement = afterPersisted.data as MathElement;
        identity = decodeOperationId(before.id);
        expectedLocked = before.positionLocked;
        locked = after.positionLocked;
        const candidate: MathElement = cloneMathElement(before);
        candidate.positionLocked = locked;
        if (before.id !== after.id || expectedLocked === locked ||
          !sameByteArrays(encodePersistedElement({ kind: 'math', data: candidate }),
            next[index].payload)) {
          return null;
        }
        batches = blockBatches;
      } else {
        return null;
      }
      if (identity === null || batches === null) {
        return null;
      }
      const key: string = locked ? '1' : '0';
      const batch: OriginalPositionLockMutationBatch | undefined = batches.get(key);
      if (batch === undefined) {
        batches.set(key, { identities: [identity], expectedLocked: [expectedLocked], locked: locked });
      } else {
        batch.identities.push(identity);
        batch.expectedLocked.push(expectedLocked);
      }
    } catch (_error) {
      return null;
    }
  }
  if (shapeBatches.size === 0 && blockBatches.size === 0) {
    return null;
  }
  return { shapeBatches: Array.from(shapeBatches.values()),
    blockBatches: Array.from(blockBatches.values()) };
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

  async previewOriginalTextEdit(noteId: string, pageId: string,
    before: TextBlockElement, afterText: string): Promise<OriginalTextEditPreview | null> {
    if (this.store === null) {
      throw new Error('StrokePersistence is not initialized');
    }
    await this.flush(noteId, pageId);
    return editorPersistenceMutex.runExclusive(async (): Promise<OriginalTextEditPreview | null> => {
      if (this.store === null) {
        throw new Error('StrokePersistence is not initialized');
      }
      const store: relationalStore.RdbStore = this.store;
      if (before.richText === afterText ||
        await this.readEligibleOriginalInkPage(store, noteId, pageId) === null) {
        return null;
      }
      const block: OperationIdentity | null = decodeOperationId(before.id);
      if (block === null || !await this.isLiveOriginalTextBlock(store, noteId, pageId, block)) {
        return null;
      }
      const current: SearchSourceElement[] = await this.loadCurrentSnapshot(store, noteId, pageId);
      const expectedPayload: Uint8Array = encodePersistedElement({ kind: 'text', data: before });
      let matched: boolean = false;
      for (const element of current) {
        if (element.elementId === before.id && element.kind === PageElementKind.TEXT) {
          if (matched || !sameByteArrays(element.payload, expectedPayload)) {
            return null;
          }
          matched = true;
        }
      }
      if (!matched) {
        return null;
      }
      const textState: OriginalInsertTextOperationApplier =
        new OriginalInsertTextOperationApplier();
      const characters: StoredCharacter[] | null = await textState.readCharacters(
        store, noteId, block);
      const styleOperations: StoredOriginalTextStyleOperation[] | null =
        await readOriginalTextStyleOperations(store, noteId, block);
      const checkboxStates: StoredOriginalCheckboxState[] | null =
        await readOriginalCheckboxStates(store, noteId, block);
      if (characters === null || styleOperations === null || checkboxStates === null) {
        return null;
      }
      const beforeStyles = materializeOriginalTextStyles(
        characters, styleOperations, checkboxStates);
      if (beforeStyles === null || !sameTextStyleRuns(before,
        beforeStyles.characterRuns, beforeStyles.paragraphRuns)) {
        return null;
      }
      const plan: OriginalLocalTextMutationPlan | null =
        planOriginalLocalTextMutation(characters, before.richText, afterText);
      if (plan === null) {
        return null;
      }
      const insertionIdentity: OperationIdentity | null = await this.predictTextInsertionIdentity(
        store, noteId, plan);
      if (plan.insertedScalars.length > 0 && insertionIdentity === null) {
        return null;
      }
      const preview: OriginalLocalTextMutationPreview | null =
        previewOriginalLocalTextMutation(characters, styleOperations, checkboxStates,
          before.richText, afterText, insertionIdentity);
      return preview === null ? null : {
        characterStyleRuns: preview.characterStyleRuns,
        paragraphStyleRuns: preview.paragraphStyleRuns,
      };
    });
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

  async commitOriginalClipboardPaste(noteId: string, pageId: string,
    plan: OriginalClipboardPastePlan, history: HistoryMetadata):
    Promise<OriginalClipboardPastePersistenceResult> {
    if (this.store === null) {
      throw new Error('StrokePersistence is not initialized');
    }
    validateHistoryMetadata(history);
    if (history.effect !== HistoryEffect.PUSH ||
      history.coalesceTrack !== HistoryCoalesceTrack.NONE) {
      throw new Error('original clipboard Paste requires non-coalesced PUSH history');
    }
    validateOriginalClipboardPastePlan(plan);
    const stablePlan: OriginalClipboardPastePlan = cloneOriginalClipboardPastePlan(plan);
    const stableHistory: HistoryMetadata = {
      actionId: history.actionId, effect: history.effect,
      coalesceTrack: history.coalesceTrack, actionTime: history.actionTime,
    };
    validateOriginalClipboardPastePlan(stablePlan);
    validateHistoryMetadata(stableHistory);
    await this.flush(noteId, pageId);
    return editorPersistenceMutex.runExclusive(
      async (): Promise<OriginalClipboardPastePersistenceResult> => {
        if (this.store === null) {
          throw new Error('StrokePersistence is not initialized');
        }
        const store: relationalStore.RdbStore = this.store;
        await store.beginTransaction();
        try {
          const page: OriginalSequenceIdentity | null = await this.readEligibleOriginalInkPage(
            store, noteId, pageId);
          if (page === null) {
            throw new Error('original clipboard Paste page is not original-aligned');
          }
          const before: SearchSourceElement[] = await this.loadCurrentSnapshot(store, noteId, pageId);
          const currentRevision: number = await this.readLivePageRevision(store, noteId, pageId);
          if (currentRevision >= Number.MAX_SAFE_INTEGER) {
            throw new Error('original clipboard Paste page revision is exhausted');
          }
          const nextRevision: number = currentRevision + 1;
          const maximumZIndex: string | null = await this.readMaximumOriginalZIndex(
            store, noteId, page);
          const strokeById: Map<string, StrokeElementData> = new Map<string, StrokeElementData>();
          const shapeById: Map<string, ShapeElement> = new Map<string, ShapeElement>();
          const textById: Map<string, TextBlockElement> = new Map<string, TextBlockElement>();
          const imageById: Map<string, ImageElement> = new Map<string, ImageElement>();
          const mathById: Map<string, MathElement> = new Map<string, MathElement>();
          stablePlan.strokes.forEach(
            (value: StrokeElementData): void => { strokeById.set(value.id, value); });
          stablePlan.shapes.forEach(
            (value: ShapeElement): void => { shapeById.set(value.id, value); });
          stablePlan.textBlocks.forEach(
            (value: TextBlockElement): void => { textById.set(value.id, value); });
          stablePlan.images.forEach(
            (value: ImageElement): void => { imageById.set(value.id, value); });
          stablePlan.mathBlocks.forEach(
            (value: MathElement): void => { mathById.set(value.id, value); });

          const mappedIds: Map<string, string> = new Map<string, string>();
          const createdStrokes: StrokeElementData[] = [];
          const createdShapes: ShapeElement[] = [];
          const createdTexts: TextBlockElement[] = [];
          const createdImages: ImageElement[] = [];
          const createdMathBlocks: MathElement[] = [];
          const createdOrder: PageElementRef[] = [];
          const revisionBatch: OriginalPageMutationBatch = new OriginalPageMutationBatch();
          let firstCreate: boolean = true;
          for (const ref of stablePlan.elementOrder) {
            const identity: AllocatedOperationIdentity = await allocateOperationIdentity(store, noteId);
            if (firstCreate && maximumZIndex !== null &&
              compareUnsignedLongDecimal(maximumZIndex, identity.clientTime.toString()) > 0) {
              throw new Error('original clipboard Paste cannot append below the current z-index clock');
            }
            firstCreate = false;
            const metadata: OriginalInkCreateMetadata = {
              timestamp: identity.timestamp, siteId: identity.siteId,
              clientTime: identity.clientTime, pageTimestamp: page.timestamp,
              pageSiteId: page.siteId, pageIndex: page.index, pencilSeed: 0,
            };
            mappedIds.set(ref.elementId, identity.opId);
            if (ref.kind === PageElementKind.STROKE) {
              const source: StrokeElementData | undefined = strokeById.get(ref.elementId);
              if (source === undefined) {
                throw new Error('original clipboard Paste Ink source disappeared');
              }
              const stroke: StrokeElementData = cloneStrokeThroughPersistence(source);
              stroke.id = identity.opId;
              stroke.originalCreate = metadata;
              const payload: Uint8Array = encodeOriginalLocalCreateInk(page, stroke);
              const operation: StoredSyncedOperation = localStoredOperation(
                noteId, metadata, ORIGINAL_CREATE_INK_PAYLOAD_TYPE, payload,
                stroke.audioStartTime === undefined ? null : stroke.audioStartTime);
              const applied: SyncedOperationApplyResult =
                await new OriginalCreateInkOperationApplier().applyBatchedPayload(
                  store, operation,
                  decodeOriginalCreateInk(operation.rawOperation, metadata.clientTime.toString()),
                  revisionBatch);
              if (applied.deferredReason !== null) {
                throw new Error(`original clipboard CREATE_INK was deferred: ${applied.deferredReason}`);
              }
              await this.appendOriginalCreateOperation(store, noteId, identity,
                OpType.ORIGINAL_CREATE_INK, operation.rawOperation);
              createdStrokes.push(stroke);
            } else if (ref.kind === PageElementKind.SHAPE) {
              const source: ShapeElement | undefined = shapeById.get(ref.elementId);
              if (source === undefined) {
                throw new Error('original clipboard Paste Shape source disappeared');
              }
              const shape: ShapeElement = cloneShapeElement(source);
              shape.id = identity.opId;
              const shapeMetadata: OriginalShapeCreateMetadata = {
                timestamp: identity.timestamp, siteId: identity.siteId,
                clientTime: identity.clientTime, pageTimestamp: page.timestamp,
                pageSiteId: page.siteId, pageIndex: page.index, pencilSeed: 0, averageForce: null,
              };
              shape.originalCreate = shapeMetadata;
              const payload: Uint8Array = encodeOriginalLocalCreateShape(page, shape, null);
              const operation: StoredSyncedOperation = localStoredOperation(
                noteId, shapeMetadata, ORIGINAL_CREATE_SHAPE_PAYLOAD_TYPE, payload, null);
              const applied: SyncedOperationApplyResult =
                await new OriginalShapeGroupOperationApplier().applyCreateShapeBatchedPayload(
                  store, operation,
                  decodeOriginalCreateShape(operation.rawOperation, metadata.clientTime.toString()),
                  revisionBatch);
              if (applied.deferredReason !== null) {
                throw new Error(`original clipboard CREATE_SHAPE was deferred: ${applied.deferredReason}`);
              }
              await this.appendOriginalCreateOperation(store, noteId, identity,
                OpType.ORIGINAL_CREATE_SHAPE, operation.rawOperation);
              createdShapes.push(shape);
            } else if (ref.kind === PageElementKind.TEXT) {
              const source: TextBlockElement | undefined = textById.get(ref.elementId);
              if (source === undefined) {
                throw new Error('original clipboard Paste Text source disappeared');
              }
              const text: TextBlockElement = cloneTextBlockElement(source);
              text.id = identity.opId;
              text.originalCreate = metadata;
              const createPayload: Uint8Array = encodeOriginalLocalCreateTextBlock(page, text);
              const createOperation: StoredSyncedOperation = localStoredOperation(
                noteId, metadata, ORIGINAL_CREATE_BLOCK_PAYLOAD_TYPE, createPayload, null);
              const createDecoded: OriginalCreateBlockPayload = decodeOriginalCreateBlock(
                createOperation.rawOperation, metadata.clientTime.toString());
              const createApplied: SyncedOperationApplyResult =
                await new OriginalCreateBlockOperationApplier().applyBatchedPayload(
                  store, createOperation, createDecoded, revisionBatch);
              if (createApplied.deferredReason !== null) {
                throw new Error(`original clipboard CREATE_BLOCK was deferred: ${createApplied.deferredReason}`);
              }
              await this.appendOriginalCreateOperation(store, noteId, identity,
                OpType.ORIGINAL_CREATE_BLOCK, createOperation.rawOperation);
              if (text.richText.length > 0) {
                const insertIdentity: AllocatedOperationIdentity =
                  await allocateOperationIdentity(store, noteId);
                const insertMetadata: OriginalInkCreateMetadata =
                  allocatedOriginalMetadata(insertIdentity);
                const insertPayload: Uint8Array = encodeOriginalInitialInsertString(
                  { timestamp: identity.timestamp, siteId: identity.siteId }, text.richText);
                const insertOperation: StoredSyncedOperation = localStoredOperation(
                  noteId, insertMetadata, ORIGINAL_INSERT_STRING_PAYLOAD_TYPE,
                  insertPayload, null);
                const insertApplied: SyncedOperationApplyResult =
                  await new OriginalInsertTextOperationApplier().applyBatchedPayload(
                    store, insertOperation,
                    decodeOriginalInsertText(insertOperation.rawOperation,
                      ORIGINAL_INSERT_STRING_PAYLOAD_TYPE), revisionBatch);
                if (insertApplied.deferredReason !== null) {
                  throw new Error(`original clipboard INSERT_STRING was deferred: ${insertApplied.deferredReason}`);
                }
                await this.appendOriginalCreateOperation(store, noteId, insertIdentity,
                  OpType.ORIGINAL_INSERT_TEXT, insertOperation.rawOperation);
              }
              createdTexts.push(materializeOriginalTextCreate(
                identity.opId, createDecoded, text.richText, metadata));
            } else if (ref.kind === PageElementKind.IMAGE) {
              const source: ImageElement | undefined = imageById.get(ref.elementId);
              if (source === undefined) {
                throw new Error('original clipboard Paste Image source disappeared');
              }
              const image: ImageElement = cloneImageElement(source);
              image.id = identity.opId;
              const payload: Uint8Array = encodeOriginalLocalCreateImageBlock(page, image);
              const operation: StoredSyncedOperation = localStoredOperation(
                noteId, metadata, ORIGINAL_CREATE_BLOCK_PAYLOAD_TYPE, payload, null);
              const decoded: OriginalCreateBlockPayload = decodeOriginalCreateBlock(
                operation.rawOperation, metadata.clientTime.toString());
              const applied: SyncedOperationApplyResult =
                await new OriginalCreateBlockOperationApplier().applyBatchedPayload(
                  store, operation, decoded, revisionBatch);
              if (applied.deferredReason !== null) {
                throw new Error(`original clipboard Image CREATE_BLOCK was deferred: ${applied.deferredReason}`);
              }
              await this.appendOriginalCreateOperation(store, noteId, identity,
                OpType.ORIGINAL_CREATE_BLOCK, operation.rawOperation);
              createdImages.push(materializeOriginalImageCreate(identity.opId, decoded));
            } else if (ref.kind === PageElementKind.MATH) {
              const source: MathElement | undefined = mathById.get(ref.elementId);
              if (source === undefined) {
                throw new Error('original clipboard Paste Math source disappeared');
              }
              const math: MathElement = cloneMathElement(source);
              math.id = identity.opId;
              const payload: Uint8Array = encodeOriginalLocalCreateMathBlock(page, math);
              const operation: StoredSyncedOperation = localStoredOperation(
                noteId, metadata, ORIGINAL_CREATE_BLOCK_PAYLOAD_TYPE, payload, null);
              const decoded: OriginalCreateBlockPayload = decodeOriginalCreateBlock(
                operation.rawOperation, metadata.clientTime.toString());
              const applied: SyncedOperationApplyResult =
                await new OriginalCreateBlockOperationApplier().applyBatchedPayload(
                  store, operation, decoded, revisionBatch);
              if (applied.deferredReason !== null) {
                throw new Error(`original clipboard Math CREATE_BLOCK was deferred: ${applied.deferredReason}`);
              }
              await this.appendOriginalCreateOperation(store, noteId, identity,
                OpType.ORIGINAL_CREATE_BLOCK, operation.rawOperation);
              createdMathBlocks.push(materializeOriginalMathCreate(identity.opId, decoded));
            } else {
              throw new Error('original clipboard Paste leaf kind is unsupported');
            }
            createdOrder.push({ kind: ref.kind, elementId: identity.opId,
              zIndex: createdOrder.length });
          }
          await revisionBatch.flush(store, noteId);

          const createdGroups: OriginalSelectionGroup[] = [];
          const groupApplier: OriginalShapeGroupOperationApplier =
            new OriginalShapeGroupOperationApplier();
          for (const sourceGroup of stablePlan.groups) {
            const members: OperationIdentity[] = [];
            const memberIds: string[] = [];
            for (const sourceMember of sourceGroup.members) {
              const mapped: string | undefined = mappedIds.get(sourceMember);
              const member: OperationIdentity | null = mapped === undefined ? null : decodeOperationId(mapped);
              if (mapped === undefined || member === null) {
                throw new Error('original clipboard Paste Group member mapping disappeared');
              }
              memberIds.push(mapped);
              members.push(member);
            }
            const identity: AllocatedOperationIdentity = await allocateOperationIdentity(store, noteId);
            const group: OriginalSelectionGroup = {
              id: identity.opId, timestamp: identity.timestamp, siteId: identity.siteId,
              members: memberIds,
            };
            const payload: Uint8Array = encodeOriginalCreateGroup(members);
            const operation: StoredSyncedOperation = localStoredOperation(
              noteId, this.groupOperationMetadata(identity),
              ORIGINAL_CREATE_GROUP_PAYLOAD_TYPE, payload, null);
            const applied: SyncedOperationApplyResult = await groupApplier.apply(store, operation);
            if (applied.deferredReason !== null) {
              throw new Error(`original clipboard CREATE_GROUP was deferred: ${applied.deferredReason}`);
            }
            await this.appendOriginalCreateOperation(store, noteId, identity,
              OpType.ORIGINAL_CREATE_GROUP, operation.rawOperation);
            mappedIds.set(sourceGroup.id, identity.opId);
            createdGroups.push(group);
          }

          const materialized: SearchSourceElement[] =
            await this.loadCurrentSnapshot(store, noteId, pageId);
          const createdPrepared: PreparedPageSave = this.prepareSave(
            noteId, pageId, createdStrokes, createdTexts, createdOrder, createdShapes,
            createdImages, createdMathBlocks);
          const finalSnapshot: PreparedPageSave = this.reconcileOriginalClipboardPasteSnapshot(
            noteId, pageId, before, materialized, createdPrepared.elements, stableHistory);
          await this.reconcilePreparedRows(store, finalSnapshot, nextRevision);
          await this.rebuildPageSearchState(
            store, finalSnapshot, nextRevision, createdStrokes.length > 0);
          const after: SearchSourceElement[] = finalSnapshot.elements.map(
            (element: PreparedElement): SearchSourceElement => ({
              elementId: element.elementId, kind: element.kind, payload: element.payload,
            }));
          const pageMutation: PageMutationOpPayload = createPageMutation(
            pageId, currentRevision, nextRevision, before, after);
          const topGroupIds: string[] = stablePlan.topGroupIds.map((sourceId: string): string => {
            const mapped: string | undefined = mappedIds.get(sourceId);
            if (mapped === undefined) {
              throw new Error('original clipboard Paste top Group mapping disappeared');
            }
            return mapped;
          });
          const mutation: OriginalClipboardPasteMutation = {
            pageMutation: pageMutation, groups: createdGroups, topGroupIds: topGroupIds,
          };
          validateOriginalClipboardPasteMutation(mutation);
          const activeGroups: OriginalSelectionGroup[] =
            await this.loadOriginalSelectionGroups(store, noteId);
          for (const group of createdGroups) {
            if (!this.containsExactGroup(activeGroups, group)) {
              throw new Error('original clipboard Paste reducer lost a created Group');
            }
          }
          const historyOperation: Op = await this.appendOriginalClipboardPasteHistory(
            store, noteId, mutation, stableHistory);
          await store.commit();
          return {
            strokes: createdStrokes, shapes: createdShapes, textBlocks: createdTexts,
            images: createdImages, mathBlocks: createdMathBlocks,
            elementOrder: finalSnapshot.elements.map(
              (element: PreparedElement, index: number): PageElementRef => ({
                kind: element.kind, elementId: element.elementId, zIndex: index,
              })),
            groups: activeGroups.map(cloneSelectionGroup),
            topGroupIds: topGroupIds.slice(), mutation: mutation, operation: historyOperation,
          };
        } catch (e) {
          await store.rollBack();
          throw new Error(`commit original clipboard Paste failed: ${JSON.stringify(e)}`);
        }
      });
  }

  async applyOriginalClipboardPasteHistory(noteId: string,
    sourceMutation: OriginalClipboardPasteMutation, forward: boolean,
    history: HistoryMetadata): Promise<OriginalClipboardPasteHistoryResult> {
    if (this.store === null) {
      throw new Error('StrokePersistence is not initialized');
    }
    validateOriginalClipboardPasteMutation(sourceMutation);
    validateHistoryMetadata(history);
    if (history.effect === HistoryEffect.PUSH ||
      history.coalesceTrack !== HistoryCoalesceTrack.NONE) {
      throw new Error('original clipboard Paste history movement is invalid');
    }
    const mutation: OriginalClipboardPasteMutation = decodeOriginalClipboardPasteMutation(
      encodeOriginalClipboardPasteMutation(sourceMutation));
    const stableHistory: HistoryMetadata = {
      actionId: history.actionId, effect: history.effect,
      coalesceTrack: history.coalesceTrack, actionTime: history.actionTime,
    };
    const pageId: string = mutation.pageMutation.pageId;
    await this.flush(noteId, pageId);
    return editorPersistenceMutex.runExclusive(
      async (): Promise<OriginalClipboardPasteHistoryResult> => {
        if (this.store === null) {
          throw new Error('StrokePersistence is not initialized');
        }
        const store: relationalStore.RdbStore = this.store;
        await store.beginTransaction();
        try {
          if (await this.readEligibleOriginalInkPage(store, noteId, pageId) === null) {
            throw new Error('original clipboard Paste history page is not original-aligned');
          }
          const current: SearchSourceElement[] = await this.loadCurrentSnapshot(store, noteId, pageId);
          const targetElements: SearchSourceElement[] = replayPageMutation(
            current, mutation.pageMutation, forward);
          const activeBefore: OriginalSelectionGroup[] =
            await this.loadOriginalSelectionGroups(store, noteId);
          for (const group of mutation.groups) {
            const stored: OriginalSelectionGroup | null = await this.readStoredGroup(
              store, noteId, group);
            if (stored === null || !sameOriginalSelectionGroups([stored], [group]) ||
              this.containsExactGroup(activeBefore, group) !== !forward) {
              throw new Error('original clipboard Paste history source Group state is stale');
            }
          }
          const targets: OperationIdentity[] = [];
          for (const element of mutation.pageMutation.afterElements) {
            const identity: OperationIdentity | null = decodeOperationId(element.elementId);
            if (identity === null) {
              throw new Error('original clipboard Paste history leaf identity is invalid');
            }
            targets.push(identity);
          }
          for (const group of mutation.groups) {
            targets.push({ timestamp: group.timestamp, siteId: group.siteId });
          }
          if (targets.length > MAX_ORIGINAL_DELETE_ENTITY_COUNT) {
            throw new Error('original clipboard Paste history exceeds one type-25 payload');
          }
          const revisionBefore: number = await this.readLivePageRevision(store, noteId, pageId);
          const identity: AllocatedOperationIdentity = await allocateOperationIdentity(store, noteId);
          const payload: Uint8Array = encodeOriginalEntityVisibility(
            forward ? [] : targets, forward ? targets : []);
          const operation: StoredSyncedOperation = localStoredOperation(
            noteId, allocatedOriginalMetadata(identity),
            ORIGINAL_DELETE_ENTITIES_PAYLOAD_TYPE, payload, null);
          const applied: SyncedOperationApplyResult =
            await new OriginalDeleteEntitiesOperationApplier().apply(store, operation);
          if (applied.deferredReason !== null) {
            throw new Error(`original clipboard Paste visibility was deferred: ${applied.deferredReason}`);
          }
          await this.appendOriginalCreateOperation(store, noteId, identity,
            OpType.ORIGINAL_DELETE_ENTITIES, operation.rawOperation);
          const materialized: SearchSourceElement[] =
            await this.loadCurrentSnapshot(store, noteId, pageId);
          if (!sameSearchSourceElements(materialized, targetElements)) {
            throw new Error('original clipboard Paste history produced an unexpected page');
          }
          const activeAfter: OriginalSelectionGroup[] =
            await this.loadOriginalSelectionGroups(store, noteId);
          for (const group of mutation.groups) {
            if (this.containsExactGroup(activeAfter, group) !== forward) {
              throw new Error('original clipboard Paste history produced unexpected Groups');
            }
          }
          const revisionAfter: number = await this.readLivePageRevision(store, noteId, pageId);
          if (revisionAfter !== revisionBefore + 1) {
            throw new Error('original clipboard Paste history did not advance one page revision');
          }
          await this.appendOriginalClipboardPasteHistory(
            store, noteId, mutation, stableHistory);
          await store.commit();
          return {
            elements: materialized,
            elementOrder: materialized.map(
              (element: SearchSourceElement, index: number): PageElementRef => ({
                kind: element.kind, elementId: element.elementId, zIndex: index,
              })),
            groups: activeAfter,
          };
        } catch (e) {
          await store.rollBack();
          throw new Error(`apply original clipboard Paste history failed: ${JSON.stringify(e)}`);
        }
      });
  }

  async createOriginalGroup(noteId: string, pageId: string, memberIds: string[],
    elementOrderBefore: PageElementRef[], history: HistoryMetadata):
    Promise<OriginalGroupMutationResult> {
    if (this.store === null) {
      throw new Error('StrokePersistence is not initialized');
    }
    validateHistoryMetadata(history);
    if (history.effect !== HistoryEffect.PUSH) {
      throw new Error('new Group requires PUSH history');
    }
    const members: OperationIdentity[] = this.decodeUniqueGroupMembers(memberIds, 2);
    await this.flush(noteId, pageId);
    return editorPersistenceMutex.runExclusive(async (): Promise<OriginalGroupMutationResult> => {
      if (this.store === null) {
        throw new Error('StrokePersistence is not initialized');
      }
      const store: relationalStore.RdbStore = this.store;
      await store.beginTransaction();
      try {
        await this.preflightOriginalGroupPage(store, noteId, pageId, elementOrderBefore);
        const active: OriginalSelectionGroup[] =
          await this.loadOriginalSelectionGroups(store, noteId);
        const current: SearchSourceElement[] = await this.loadCurrentSnapshot(store, noteId, pageId);
        if (!this.localGroupMembersAreValid(memberIds, active, current)) {
          throw new Error('local CREATE_GROUP members are not current top-level page units');
        }
        const identity: AllocatedOperationIdentity = await allocateOperationIdentity(store, noteId);
        const group: OriginalSelectionGroup = {
          id: identity.opId, timestamp: identity.timestamp, siteId: identity.siteId,
          members: memberIds.slice(),
        };
        const payload: Uint8Array = encodeOriginalCreateGroup(members);
        const metadata: OriginalInkCreateMetadata = this.groupOperationMetadata(identity);
        const operation: StoredSyncedOperation = localStoredOperation(
          noteId, metadata, ORIGINAL_CREATE_GROUP_PAYLOAD_TYPE, payload, null);
        const result: SyncedOperationApplyResult =
          await new OriginalShapeGroupOperationApplier().apply(store, operation);
        if (result.deferredReason !== null) {
          throw new Error(`local CREATE_GROUP was deferred: ${result.deferredReason}`);
        }
        await appendOperation(store, {
          noteId: noteId, opId: identity.opId, opType: OpType.ORIGINAL_CREATE_GROUP,
          payload: operation.rawOperation, clientTime: identity.clientTime,
          opTimestamp: identity.timestamp, editorSiteId: identity.siteId, uploadImmediately: true,
        });
        const groups: OriginalSelectionGroup[] =
          await this.loadOriginalSelectionGroups(store, noteId);
        const elementOrderAfter: PageElementRef[] =
          await this.readCurrentPageElementOrder(store, noteId, pageId);
        if (!this.containsExactGroup(groups, group)) {
          throw new Error('local CREATE_GROUP reducer did not materialize the Group');
        }
        const mutation: OriginalGroupMutationOpPayload = {
          pageId: pageId, beforeGroups: [], afterGroups: [group],
          elementOrderBefore: clonePageElementRefs(elementOrderBefore),
          elementOrderAfter: elementOrderAfter,
        };
        validateOriginalGroupMutation(mutation);
        await this.appendOriginalGroupHistory(store, noteId, mutation, history);
        await store.commit();
        return { mutation: mutation, groups: groups };
      } catch (e) {
        await store.rollBack();
        throw new Error(`create original Group failed: ${JSON.stringify(e)}`);
      }
    });
  }

  async ungroupOriginalGroup(noteId: string, pageId: string, group: OriginalSelectionGroup,
    elementOrderBefore: PageElementRef[], history: HistoryMetadata):
    Promise<OriginalGroupMutationResult> {
    if (this.store === null) {
      throw new Error('StrokePersistence is not initialized');
    }
    validateHistoryMetadata(history);
    if (history.effect !== HistoryEffect.PUSH) {
      throw new Error('new Ungroup requires PUSH history');
    }
    this.validateSelectionGroup(group);
    await this.flush(noteId, pageId);
    return editorPersistenceMutex.runExclusive(async (): Promise<OriginalGroupMutationResult> => {
      if (this.store === null) {
        throw new Error('StrokePersistence is not initialized');
      }
      const store: relationalStore.RdbStore = this.store;
      await store.beginTransaction();
      try {
        await this.preflightOriginalGroupPage(store, noteId, pageId, elementOrderBefore);
        const active: OriginalSelectionGroup[] =
          await this.loadOriginalSelectionGroups(store, noteId);
        const current: SearchSourceElement[] = await this.loadCurrentSnapshot(store, noteId, pageId);
        if (!this.containsExactGroup(active, group) ||
          !this.groupLeavesBelongToPage(group.id, active, current)) {
          throw new Error('local Ungroup source Group is stale or crosses the current page');
        }
        await this.applyOriginalGroupVisibility(store, noteId, group, true);
        const groups: OriginalSelectionGroup[] =
          await this.loadOriginalSelectionGroups(store, noteId);
        const elementOrderAfter: PageElementRef[] =
          await this.readCurrentPageElementOrder(store, noteId, pageId);
        if (this.containsGroupId(groups, group.id)) {
          throw new Error('local Ungroup reducer left the Group active');
        }
        const mutation: OriginalGroupMutationOpPayload = {
          pageId: pageId, beforeGroups: [cloneSelectionGroup(group)], afterGroups: [],
          elementOrderBefore: clonePageElementRefs(elementOrderBefore),
          elementOrderAfter: elementOrderAfter,
        };
        validateOriginalGroupMutation(mutation);
        await this.appendOriginalGroupHistory(store, noteId, mutation, history);
        await store.commit();
        return { mutation: mutation, groups: groups };
      } catch (e) {
        await store.rollBack();
        throw new Error(`ungroup original Group failed: ${JSON.stringify(e)}`);
      }
    });
  }

  async applyOriginalGroupHistory(noteId: string, mutation: OriginalGroupMutationOpPayload,
    forward: boolean, history: HistoryMetadata): Promise<OriginalGroupMutationResult> {
    if (this.store === null) {
      throw new Error('StrokePersistence is not initialized');
    }
    validateOriginalGroupMutation(mutation);
    validateHistoryMetadata(history);
    if (history.effect === HistoryEffect.PUSH) {
      throw new Error('Group history movement cannot be PUSH');
    }
    await this.flush(noteId, mutation.pageId);
    return editorPersistenceMutex.runExclusive(async (): Promise<OriginalGroupMutationResult> => {
      if (this.store === null) {
        throw new Error('StrokePersistence is not initialized');
      }
      const store: relationalStore.RdbStore = this.store;
      await store.beginTransaction();
      try {
        const sourceGroups: OriginalSelectionGroup[] = forward ?
          mutation.beforeGroups : mutation.afterGroups;
        const targetGroups: OriginalSelectionGroup[] = forward ?
          mutation.afterGroups : mutation.beforeGroups;
        const sourceOrder: PageElementRef[] = forward ?
          mutation.elementOrderBefore : mutation.elementOrderAfter;
        const targetOrder: PageElementRef[] = forward ?
          mutation.elementOrderAfter : mutation.elementOrderBefore;
        await this.preflightOriginalGroupPage(store, noteId, mutation.pageId, sourceOrder);
        const active: OriginalSelectionGroup[] =
          await this.loadOriginalSelectionGroups(store, noteId);
        if (!this.affectedGroupStateMatches(active, sourceGroups, targetGroups)) {
          throw new Error('original Group history source state is stale');
        }
        const group: OriginalSelectionGroup = sourceGroups.length === 1 ?
          sourceGroups[0] : targetGroups[0];
        const stored: OriginalSelectionGroup | null = await this.readStoredGroup(store, noteId, group);
        if (stored === null || !sameOriginalSelectionGroups([stored], [group])) {
          throw new Error('original Group history state no longer matches its CREATE payload');
        }
        await this.applyOriginalGroupVisibility(store, noteId, group, targetGroups.length === 0);
        const groups: OriginalSelectionGroup[] =
          await this.loadOriginalSelectionGroups(store, noteId);
        const actualOrder: PageElementRef[] =
          await this.readCurrentPageElementOrder(store, noteId, mutation.pageId);
        if (!samePageElementOrder(actualOrder, targetOrder) ||
          !this.affectedGroupStateMatches(groups, targetGroups, sourceGroups)) {
          throw new Error('original Group history reducer produced unexpected state');
        }
        await this.appendOriginalGroupHistory(store, noteId, mutation, history);
        await store.commit();
        return { mutation: mutation, groups: groups };
      } catch (e) {
        await store.rollBack();
        throw new Error(`apply original Group history failed: ${JSON.stringify(e)}`);
      }
    });
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
      const originalCreate: PreparedElement | null = this.singleReservedOriginalCreate(
        current, snapshot.elements);
      const snapshotRevision: number = currentRevision + 1;
      const mutation: PageMutationOpPayload = createPageMutation(
        snapshot.pageId, currentRevision, snapshotRevision, current, snapshot.elements);
      const originalVisibility: OriginalEntityVisibilityMutation | null =
        await this.originalEntityVisibilityMutation(
          store, snapshot.noteId, current, snapshot.elements);
      if (originalVisibility !== null) {
        await this.applyOriginalEntityVisibility(store, snapshot, originalVisibility,
          snapshotRevision);
        await this.rebuildPageSearchState(store, snapshot, snapshotRevision,
          handwritingSourceChanged(current, snapshot.elements));
        await this.appendHistoryCompanion(store, snapshot, mutation);
        await store.commit();
        return;
      }
      const originalPositionLock: OriginalPositionLockMutation | null =
        await this.originalPositionLockMutation(
          store, snapshot.noteId, current, snapshot.elements);
      if (originalPositionLock !== null) {
        await this.applyOriginalPositionLock(
          store, snapshot, originalPositionLock, snapshotRevision);
        await this.rebuildPageSearchState(store, snapshot, snapshotRevision, false);
        await this.appendHistoryCompanion(store, snapshot, mutation);
        await store.commit();
        return;
      }
      const originalText: OriginalTextMutation | null = await this.originalTextMutation(
        store, snapshot.noteId, snapshot.pageId, current, snapshot.elements);
      if (originalText !== null) {
        await this.applyOriginalTextMutation(store, snapshot, originalText, snapshotRevision);
        await this.rebuildPageSearchState(store, snapshot, snapshotRevision, false);
        await this.appendHistoryCompanion(store, snapshot, mutation);
        await store.commit();
        return;
      }
      const originalStyle: OriginalRenderMutation | null =
        await this.originalRenderMutation(store, snapshot.noteId, current, snapshot.elements);
      if (originalStyle !== null) {
        await this.applyOriginalRenderStyle(store, snapshot, originalStyle, snapshotRevision);
        await this.rebuildPageSearchState(store, snapshot, snapshotRevision,
          originalStyle.inkBatches.length > 0);
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
      if (originalCreate !== null) {
        if (originalCreate.kind === PageElementKind.STROKE) {
          await this.writeOriginalCreateInk(store, snapshot, current, originalCreate,
            mutation, currentRevision, snapshotRevision);
        } else if (originalCreate.kind === PageElementKind.SHAPE) {
          await this.writeOriginalCreateShape(store, snapshot, originalCreate,
            mutation, currentRevision, snapshotRevision);
        } else {
          await this.writeOriginalCreateText(store, snapshot, originalCreate,
            mutation, currentRevision, snapshotRevision);
        }
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
    try {
      const persisted: PersistedElement = decodePersistedElement(added.payload);
      if (added.kind === PageElementKind.STROKE && persisted.kind === 'stroke') {
        const stroke: StrokeElementData = persisted.data as StrokeElementData;
        const original: OriginalInkCreateMetadata | undefined = stroke.originalCreate;
        const identity: OperationIdentity | null = decodeOperationId(stroke.id);
        return original !== undefined && identity !== null &&
          identity.timestamp === original.timestamp && identity.siteId === original.siteId ?
            added : null;
      }
      if (added.kind === PageElementKind.SHAPE && persisted.kind === 'shape') {
        const shape: ShapeElement = persisted.data as ShapeElement;
        const original: OriginalShapeCreateMetadata | undefined = shape.originalCreate;
        const identity: OperationIdentity | null = decodeOperationId(shape.id);
        if (original === undefined || identity === null ||
          identity.timestamp !== original.timestamp || identity.siteId !== original.siteId) {
          return null;
        }
        encodeOriginalLocalCreateShape({ timestamp: original.pageTimestamp,
          siteId: original.pageSiteId, index: original.pageIndex }, shape, original.averageForce);
        return added;
      }
      if (added.kind === PageElementKind.TEXT && persisted.kind === 'text') {
        const text: TextBlockElement = persisted.data as TextBlockElement;
        const original: OriginalInkCreateMetadata | undefined = text.originalCreate;
        const identity: OperationIdentity | null = decodeOperationId(text.id);
        if (original === undefined || identity === null || text.richText.length === 0 ||
          identity.timestamp !== original.timestamp || identity.siteId !== original.siteId) {
          return null;
        }
        encodeOriginalLocalCreateTextBlock({ timestamp: original.pageTimestamp,
          siteId: original.pageSiteId, index: original.pageIndex }, text);
        encodeOriginalInitialInsertString(identity, text.richText);
        return added;
      }
      return null;
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

  private async writeOriginalCreateShape(store: relationalStore.RdbStore,
    snapshot: PreparedPageSave, added: PreparedElement, mutation: PageMutationOpPayload,
    currentRevision: number, snapshotRevision: number): Promise<void> {
    const persisted: PersistedElement = decodePersistedElement(added.payload);
    const shape: ShapeElement = persisted.data as ShapeElement;
    const metadata: OriginalShapeCreateMetadata =
      shape.originalCreate as OriginalShapeCreateMetadata;
    const page: OriginalSequenceIdentity = {
      timestamp: metadata.pageTimestamp, siteId: metadata.pageSiteId, index: metadata.pageIndex,
    };
    const eligible: OriginalSequenceIdentity | null = await this.readEligibleOriginalInkPage(
      store, snapshot.noteId, snapshot.pageId);
    if (eligible === null || eligible.timestamp !== page.timestamp || eligible.siteId !== page.siteId ||
      eligible.index !== page.index) {
      throw new Error('reserved local CREATE_SHAPE page is no longer original-aligned');
    }
    const payload: Uint8Array = encodeOriginalLocalCreateShape(
      page, shape, metadata.averageForce);
    const operation: StoredSyncedOperation = localStoredOperation(
      snapshot.noteId, metadata, ORIGINAL_CREATE_SHAPE_PAYLOAD_TYPE, payload, null);
    const result: SyncedOperationApplyResult =
      await new OriginalShapeGroupOperationApplier().apply(store, operation);
    if (result.deferredReason !== null) {
      throw new Error(`local CREATE_SHAPE was deferred: ${result.deferredReason}`);
    }
    await appendOperation(store, {
      noteId: snapshot.noteId, opId: shape.id, opType: OpType.ORIGINAL_CREATE_SHAPE,
      payload: operation.rawOperation, clientTime: metadata.clientTime,
      opTimestamp: metadata.timestamp, editorSiteId: metadata.siteId, uploadImmediately: true,
    });
    const materialized: SearchSourceElement[] = await this.loadCurrentSnapshot(
      store, snapshot.noteId, snapshot.pageId);
    if (!samePreparedIdentityOrder(materialized, snapshot.elements)) {
      throw new Error('local CREATE_SHAPE reducer produced an unexpected element order');
    }
    await this.reconcilePreparedRows(store, snapshot, snapshotRevision);
    await this.rebuildPageSearchState(store, snapshot, snapshotRevision, false);
    await this.appendHistoryCompanion(store, snapshot, mutation);
    if (currentRevision + 1 !== snapshotRevision) {
      throw new Error('local CREATE_SHAPE revision contract changed');
    }
  }

  private async writeOriginalCreateText(store: relationalStore.RdbStore,
    snapshot: PreparedPageSave, added: PreparedElement, mutation: PageMutationOpPayload,
    currentRevision: number, snapshotRevision: number): Promise<void> {
    if (snapshotRevision !== currentRevision + 1) {
      throw new Error('local CREATE_BLOCK revision contract changed');
    }
    const persisted: PersistedElement = decodePersistedElement(added.payload);
    const text: TextBlockElement = persisted.data as TextBlockElement;
    const metadata: OriginalInkCreateMetadata = text.originalCreate as OriginalInkCreateMetadata;
    const page: OriginalSequenceIdentity = {
      timestamp: metadata.pageTimestamp, siteId: metadata.pageSiteId, index: metadata.pageIndex,
    };
    const eligible: OriginalSequenceIdentity | null = await this.readEligibleOriginalInkPage(
      store, snapshot.noteId, snapshot.pageId);
    if (eligible === null || eligible.timestamp !== page.timestamp ||
      eligible.siteId !== page.siteId || eligible.index !== page.index) {
      throw new Error('reserved local CREATE_BLOCK page is no longer original-aligned');
    }
    const createPayload: Uint8Array = encodeOriginalLocalCreateTextBlock(page, text);
    const createOperation: StoredSyncedOperation = localStoredOperation(
      snapshot.noteId, metadata, ORIGINAL_CREATE_BLOCK_PAYLOAD_TYPE, createPayload, null);
    const revisionBatch: OriginalPageMutationBatch = new OriginalPageMutationBatch();
    const createResult: SyncedOperationApplyResult =
      await new OriginalCreateBlockOperationApplier().applyBatchedPayload(
        store, createOperation,
        decodeOriginalCreateBlock(createOperation.rawOperation, metadata.clientTime.toString()),
        revisionBatch);
    if (createResult.deferredReason !== null) {
      throw new Error(`local CREATE_BLOCK was deferred: ${createResult.deferredReason}`);
    }
    await appendOperation(store, {
      noteId: snapshot.noteId, opId: text.id, opType: OpType.ORIGINAL_CREATE_BLOCK,
      payload: createOperation.rawOperation, clientTime: metadata.clientTime,
      opTimestamp: metadata.timestamp, editorSiteId: metadata.siteId, uploadImmediately: true,
    });

    const insertIdentity: AllocatedOperationIdentity = await allocateOperationIdentity(
      store, snapshot.noteId);
    const insertMetadata: OriginalInkCreateMetadata = {
      timestamp: insertIdentity.timestamp, siteId: insertIdentity.siteId,
      clientTime: insertIdentity.clientTime, pageTimestamp: 0, pageSiteId: 0,
      pageIndex: 0, pencilSeed: 0,
    };
    const insertPayload: Uint8Array = encodeOriginalInitialInsertString(
      { timestamp: metadata.timestamp, siteId: metadata.siteId }, text.richText);
    const insertOperation: StoredSyncedOperation = localStoredOperation(
      snapshot.noteId, insertMetadata, ORIGINAL_INSERT_STRING_PAYLOAD_TYPE, insertPayload, null);
    const insertResult: SyncedOperationApplyResult =
      await new OriginalInsertTextOperationApplier().applyBatchedPayload(
        store, insertOperation,
        decodeOriginalInsertText(insertOperation.rawOperation, ORIGINAL_INSERT_STRING_PAYLOAD_TYPE),
        revisionBatch);
    if (insertResult.deferredReason !== null) {
      throw new Error(`local INSERT_STRING was deferred: ${insertResult.deferredReason}`);
    }
    await appendOperation(store, {
      noteId: snapshot.noteId, opId: insertIdentity.opId, opType: OpType.ORIGINAL_INSERT_TEXT,
      payload: insertOperation.rawOperation, clientTime: insertIdentity.clientTime,
      opTimestamp: insertIdentity.timestamp, editorSiteId: insertIdentity.siteId,
      uploadImmediately: true,
    });
    await revisionBatch.flush(store, snapshot.noteId);

    const materialized: SearchSourceElement[] = await this.loadCurrentSnapshot(
      store, snapshot.noteId, snapshot.pageId);
    if (!samePreparedIdentityOrder(materialized, snapshot.elements)) {
      throw new Error('local CREATE_BLOCK reducer produced an unexpected element order');
    }
    const created: SearchSourceElement | undefined = materialized.find(
      (element: SearchSourceElement): boolean => element.elementId === text.id &&
        element.kind === PageElementKind.TEXT);
    const expected: TextBlockElement = cloneTextBlockElement(text);
    expected.originalCreate = undefined;
    if (created === undefined || !sameByteArrays(created.payload,
      encodePersistedElement({ kind: 'text', data: expected }))) {
      throw new Error('local CREATE_BLOCK reducer produced unexpected Text state');
    }
    await this.reconcilePreparedRows(store, snapshot, snapshotRevision);
    await this.rebuildPageSearchState(store, snapshot, snapshotRevision, false);
    await this.appendHistoryCompanion(store, snapshot, mutation);
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
          await this.originalEntityVisibilityMutation(
            store, step.noteId, current, step.elements);
        const originalPositionLock: OriginalPositionLockMutation | null =
          originalVisibility === null ? await this.originalPositionLockMutation(
            store, step.noteId, current, step.elements) : null;
        const originalText: OriginalTextMutation | null = originalVisibility === null &&
          originalPositionLock === null ? await this.originalTextMutation(
            store, step.noteId, step.pageId, current, step.elements) : null;
        const originalStyle: OriginalRenderMutation | null = originalVisibility === null &&
          originalPositionLock === null && originalText === null ?
          await this.originalRenderMutation(store, step.noteId, current, step.elements) : null;
        const originalImageFlip: OriginalImageFlipMutation | null =
          originalVisibility === null && originalPositionLock === null && originalText === null &&
            originalStyle === null ?
            classifyOriginalImageFlipMutation(current, step.elements) : null;
        const originalImageCrop: OriginalImageCropMutation | null =
          originalVisibility === null && originalPositionLock === null && originalText === null &&
            originalStyle === null && originalImageFlip === null ?
            classifyOriginalImageCropMutation(current, step.elements) : null;
        const originalPositions: OriginalModifyPositionsMutation | null =
          originalVisibility === null && originalPositionLock === null && originalText === null &&
            originalStyle === null && originalImageFlip === null && originalImageCrop === null ?
            await this.originalModifyPositionsMutation(store, step.noteId, step.pageId,
              current, step.elements, step.history, step.originalZOrderHint) : null;
        if (originalVisibility !== null) {
          await this.applyOriginalEntityVisibility(store, step, originalVisibility,
            nextRevision);
        } else if (originalPositionLock !== null) {
          await this.applyOriginalPositionLock(store, step, originalPositionLock, nextRevision);
        } else if (originalText !== null) {
          await this.applyOriginalTextMutation(store, step, originalText, nextRevision);
        } else if (originalStyle !== null) {
          await this.applyOriginalRenderStyle(store, step, originalStyle, nextRevision);
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

  private async originalEntityVisibilityMutation(store: relationalStore.RdbStore, noteId: string,
    current: SearchSourceElement[], next: PreparedElement[]): Promise<OriginalEntityVisibilityMutation | null> {
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
        const target: SearchSourceElement | PreparedElement = larger[largerIndex];
        const identity: OperationIdentity | null = this.originalEntityIdentity(target);
        if (identity === null) {
          return null;
        }
        if (!await this.originalEntityStateExists(store, noteId, target.kind, identity)) {
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

  private async originalTextMutation(store: relationalStore.RdbStore, noteId: string,
    pageId: string, current: SearchSourceElement[], next: PreparedElement[]):
    Promise<OriginalTextMutation | null> {
    if (current.length !== next.length ||
      await this.readEligibleOriginalInkPage(store, noteId, pageId) === null) {
      return null;
    }
    let changedIndex: number = -1;
    for (let index: number = 0; index < current.length; index++) {
      if (current[index].elementId !== next[index].elementId ||
        current[index].kind !== next[index].kind) {
        return null;
      }
      if (!sameByteArrays(current[index].payload, next[index].payload)) {
        if (changedIndex >= 0) {
          return null;
        }
        changedIndex = index;
      }
    }
    if (changedIndex < 0 || current[changedIndex].kind !== PageElementKind.TEXT) {
      return null;
    }
    let beforePersisted: PersistedElement;
    let afterPersisted: PersistedElement;
    try {
      beforePersisted = decodePersistedElement(current[changedIndex].payload);
      afterPersisted = decodePersistedElement(next[changedIndex].payload);
    } catch (_error) {
      return null;
    }
    if (beforePersisted.kind !== 'text' || afterPersisted.kind !== 'text') {
      return null;
    }
    const before: TextBlockElement = beforePersisted.data as TextBlockElement;
    const after: TextBlockElement = afterPersisted.data as TextBlockElement;
    if (before.id !== current[changedIndex].elementId ||
      after.id !== next[changedIndex].elementId || before.id !== after.id ||
      before.richText === after.richText ||
      !Number.isFinite(after.blockWidth) || !Number.isFinite(after.blockHeight) ||
      after.blockWidth <= 0 || after.blockHeight <= 0) {
      return null;
    }
    const sizeChanged: boolean = !numbersNear(before.blockWidth, after.blockWidth) ||
      !numbersNear(before.blockHeight, after.blockHeight);
    const width: number = sizeChanged ? Math.fround(after.blockWidth) : before.blockWidth;
    const height: number = sizeChanged ? Math.fround(after.blockHeight) : before.blockHeight;
    const candidate: TextBlockElement = cloneTextBlockElement(before);
    candidate.richText = after.richText;
    candidate.characterStyleRuns = after.characterStyleRuns;
    candidate.paragraphStyleRuns = after.paragraphStyleRuns;
    candidate.blockWidth = width;
    candidate.blockHeight = height;
    candidate.bounds = textBlockWorldBounds(candidate);
    if (!sameByteArrays(encodePersistedElement({ kind: 'text', data: candidate }),
      encodePersistedElement(afterPersisted))) {
      return null;
    }
    const block: OperationIdentity | null = decodeOperationId(before.id);
    if (block === null || !await this.isLiveOriginalTextBlock(
      store, noteId, pageId, block)) {
      return null;
    }
    const textState: OriginalInsertTextOperationApplier =
      new OriginalInsertTextOperationApplier();
    const characters: StoredCharacter[] | null = await textState.readCharacters(
      store, noteId, block);
    if (characters === null) {
      return null;
    }
    const styleOperations: StoredOriginalTextStyleOperation[] | null =
      await readOriginalTextStyleOperations(store, noteId, block);
    const checkboxStates: StoredOriginalCheckboxState[] | null =
      await readOriginalCheckboxStates(store, noteId, block);
    if (styleOperations === null || checkboxStates === null) {
      return null;
    }
    const beforeStyles = materializeOriginalTextStyles(
      characters, styleOperations, checkboxStates);
    if (beforeStyles === null || !sameTextStyleRuns(before,
      beforeStyles.characterRuns, beforeStyles.paragraphRuns)) {
      return null;
    }
    const plan: OriginalLocalTextMutationPlan | null =
      planOriginalLocalTextMutation(characters, before.richText, after.richText);
    if (plan === null) {
      return null;
    }
    const insertionIdentity: OperationIdentity | null = await this.predictTextInsertionIdentity(
      store, noteId, plan);
    if (plan.insertedScalars.length > 0 && insertionIdentity === null) {
      return null;
    }
    const preview: OriginalLocalTextMutationPreview | null =
      previewOriginalLocalTextMutation(characters, styleOperations, checkboxStates,
        before.richText, after.richText, insertionIdentity);
    if (preview === null || !sameTextStyleRuns(after,
      preview.characterStyleRuns, preview.paragraphStyleRuns)) {
      return null;
    }
    return {
      block: block, plan: preview.plan, width: width, height: height,
      sizeChanged: sizeChanged,
    };
  }

  private async predictTextInsertionIdentity(store: relationalStore.RdbStore, noteId: string,
    plan: OriginalLocalTextMutationPlan): Promise<OperationIdentity | null> {
    if (plan.insertedScalars.length === 0) {
      return null;
    }
    const rows = await store.querySql(
      `SELECT editor_site_id, max_op_timestamp FROM note_sync_metadata WHERE note_id = ? LIMIT 1`,
      [noteId]);
    try {
      if (!rows.goToFirstRow()) {
        return null;
      }
      return predictOriginalTextInsertionIdentity(
        rows.getLong(rows.getColumnIndex('max_op_timestamp')),
        rows.getLong(rows.getColumnIndex('editor_site_id')), plan);
    } finally {
      rows.close();
    }
  }

  private async isLiveOriginalTextBlock(store: relationalStore.RdbStore, noteId: string,
    pageId: string, block: OperationIdentity): Promise<boolean> {
    const rows = await store.querySql(
      `SELECT 1 FROM original_element_z_index element
       JOIN original_page_identity page ON page.note_id = element.note_id
        AND page.seq_timestamp = element.page_timestamp
        AND page.seq_site_id = element.page_site_id AND page.seq_index = element.page_index
       JOIN original_block_state state ON state.note_id = element.note_id
        AND state.block_timestamp = element.element_timestamp
        AND state.block_site_id = element.element_site_id
       WHERE element.note_id = ? AND page.page_id = ? AND page.visible = 1
        AND element.element_timestamp = ? AND element.element_site_id = ?
        AND element.kind = ? AND element.visible = 1 AND state.block_type = ? LIMIT 1`,
      [noteId, pageId, block.timestamp, block.siteId, PageElementKind.TEXT,
        OriginalBlockType.TEXT]);
    try {
      return rows.goToFirstRow();
    } finally {
      rows.close();
    }
  }

  private async originalRenderMutation(store: relationalStore.RdbStore, noteId: string,
    current: SearchSourceElement[], next: PreparedElement[]): Promise<OriginalRenderMutation | null> {
    const mutation: OriginalRenderMutation | null =
      classifyOriginalRenderMutation(current, next);
    if (mutation === null || mutation.shapeBatches.length === 0) {
      return mutation;
    }
    for (const batch of mutation.shapeBatches) {
      if (batch.identities.length !== batch.expectedTools.length ||
        batch.identities.length !== batch.expectedStyles.length) {
        return null;
      }
      for (let index: number = 0; index < batch.identities.length; index++) {
        const identity: OperationIdentity = batch.identities[index];
        const rows = await store.querySql(
          `SELECT resolved_payload FROM original_shape_state WHERE note_id = ?
           AND shape_timestamp = ? AND shape_site_id = ? LIMIT 1`,
          [noteId, identity.timestamp, identity.siteId]);
        try {
          const metadata: OriginalShapeStateRenderMetadata | null = !rows.goToFirstRow() ? null :
            decodeOriginalShapeStateRenderMetadata(
              rows.getString(rows.getColumnIndex('resolved_payload')));
          if (metadata === null || metadata.tool !== batch.expectedTools[index] ||
            metadata.style !== batch.expectedStyles[index]) {
            return null;
          }
        } finally {
          rows.close();
        }
      }
    }
    return mutation;
  }

  private async originalPositionLockMutation(store: relationalStore.RdbStore, noteId: string,
    current: SearchSourceElement[], next: PreparedElement[]): Promise<OriginalPositionLockMutation | null> {
    const mutation: OriginalPositionLockMutation | null =
      classifyOriginalPositionLockMutation(current, next);
    if (mutation === null) {
      return null;
    }
    for (const batch of mutation.shapeBatches) {
      if (batch.identities.length !== batch.expectedLocked.length) {
        return null;
      }
      for (let index: number = 0; index < batch.identities.length; index++) {
        const identity: OperationIdentity = batch.identities[index];
        const rows = await store.querySql(
          `SELECT resolved_payload FROM original_shape_state WHERE note_id = ?
           AND shape_timestamp = ? AND shape_site_id = ? LIMIT 1`,
          [noteId, identity.timestamp, identity.siteId]);
        try {
          const metadata: OriginalShapeStateRenderMetadata | null = !rows.goToFirstRow() ? null :
            decodeOriginalShapeStateRenderMetadata(
              rows.getString(rows.getColumnIndex('resolved_payload')));
          if (metadata === null || metadata.positionLocked !== batch.expectedLocked[index]) {
            return null;
          }
        } finally {
          rows.close();
        }
      }
    }
    for (const batch of mutation.blockBatches) {
      if (batch.identities.length !== batch.expectedLocked.length) {
        return null;
      }
      for (let index: number = 0; index < batch.identities.length; index++) {
        const identity: OperationIdentity = batch.identities[index];
        const rows = await store.querySql(
          `SELECT create_position_locked, position_locked_value,
             position_locked_winner_present FROM original_block_state WHERE note_id = ?
           AND block_timestamp = ? AND block_site_id = ? LIMIT 1`,
          [noteId, identity.timestamp, identity.siteId]);
        try {
          if (!rows.goToFirstRow()) {
            return null;
          }
          const baseColumn: number = rows.getColumnIndex('create_position_locked');
          const valueColumn: number = rows.getColumnIndex('position_locked_value');
          const winnerColumn: number = rows.getColumnIndex('position_locked_winner_present');
          const base: number = rows.getLong(baseColumn);
          const winnerPresent: number = rows.getLong(winnerColumn);
          if ((base !== 0 && base !== 1) || (winnerPresent !== 0 && winnerPresent !== 1) ||
            (winnerPresent === 1 && rows.isColumnNull(valueColumn))) {
            return null;
          }
          const value: number = winnerPresent === 1 ? rows.getLong(valueColumn) : base;
          if ((value !== 0 && value !== 1) ||
            (value !== 0) !== batch.expectedLocked[index]) {
            return null;
          }
        } finally {
          rows.close();
        }
      }
    }
    return mutation;
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

  private originalEntityIdentity(target: SearchSourceElement | PreparedElement): OperationIdentity | null {
    try {
      const persisted: PersistedElement = decodePersistedElement(target.payload);
      const kindMatches: boolean =
        (target.kind === PageElementKind.STROKE && persisted.kind === 'stroke') ||
        (target.kind === PageElementKind.SHAPE && persisted.kind === 'shape') ||
        (target.kind === PageElementKind.TEXT && persisted.kind === 'text') ||
        (target.kind === PageElementKind.IMAGE && persisted.kind === 'image') ||
        (target.kind === PageElementKind.MATH && persisted.kind === 'math');
      if (!kindMatches || target.elementId !== persisted.data.id) {
        return null;
      }
      return decodeOperationId(persisted.data.id);
    } catch (_error) {
      return null;
    }
  }

  private async originalEntityStateExists(store: relationalStore.RdbStore, noteId: string,
    kind: number, identity: OperationIdentity): Promise<boolean> {
    let sql: string;
    let args: Array<string | number>;
    if (kind === PageElementKind.STROKE) {
      sql = `SELECT 1 FROM original_element_z_index element
        JOIN original_ink_state state ON state.note_id = element.note_id
         AND state.ink_timestamp = element.element_timestamp
         AND state.ink_site_id = element.element_site_id
        WHERE element.note_id = ? AND element.element_timestamp = ?
         AND element.element_site_id = ? AND element.kind = ? LIMIT 1`;
      args = [noteId, identity.timestamp, identity.siteId, kind];
    } else if (kind === PageElementKind.SHAPE) {
      sql = `SELECT 1 FROM original_element_z_index element
        JOIN original_shape_state state ON state.note_id = element.note_id
         AND state.shape_timestamp = element.element_timestamp
         AND state.shape_site_id = element.element_site_id
        WHERE element.note_id = ? AND element.element_timestamp = ?
         AND element.element_site_id = ? AND element.kind = ? LIMIT 1`;
      args = [noteId, identity.timestamp, identity.siteId, kind];
    } else {
      const blockType: number = kind === PageElementKind.TEXT ? OriginalBlockType.TEXT :
        kind === PageElementKind.IMAGE ? OriginalBlockType.IMAGE :
          kind === PageElementKind.MATH ? OriginalBlockType.MATH : -1;
      if (blockType < 0) {
        return false;
      }
      sql = `SELECT 1 FROM original_element_z_index element
        JOIN original_block_state state ON state.note_id = element.note_id
         AND state.block_timestamp = element.element_timestamp
         AND state.block_site_id = element.element_site_id
        WHERE element.note_id = ? AND element.element_timestamp = ?
         AND element.element_site_id = ? AND element.kind = ?
         AND state.block_type = ? LIMIT 1`;
      args = [noteId, identity.timestamp, identity.siteId, kind, blockType];
    }
    const rows = await store.querySql(sql, args);
    try {
      return rows.goToFirstRow();
    } finally {
      rows.close();
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
      throw new Error(`local entity visibility was deferred: ${result.deferredReason}`);
    }
    await appendOperation(store, {
      noteId: step.noteId, opId: identity.opId, opType: OpType.ORIGINAL_DELETE_ENTITIES,
      payload: operation.rawOperation, clientTime: identity.clientTime, opTimestamp: identity.timestamp,
      editorSiteId: identity.siteId, uploadImmediately: true,
    });
    const materialized: SearchSourceElement[] = await this.loadCurrentSnapshot(
      store, step.noteId, step.pageId);
    if (!samePreparedIdentityOrder(materialized, step.elements) ||
      !samePreparedMembersAndPayloads(materialized, step.elements)) {
      throw new Error('local entity visibility reducer produced unexpected page state');
    }
    await this.reconcilePreparedRows(store, step, expectedRevision);
  }

  private async applyOriginalTextMutation(store: relationalStore.RdbStore,
    step: PreparedPageSave, mutation: OriginalTextMutation,
    expectedRevision: number): Promise<void> {
    if (await this.readEligibleOriginalInkPage(store, step.noteId, step.pageId) === null) {
      throw new Error('local Text edit page is no longer original-aligned');
    }
    const revisionBatch: OriginalPageMutationBatch = new OriginalPageMutationBatch();
    const visibilityApplier: OriginalTextVisibilityOperationApplier =
      new OriginalTextVisibilityOperationApplier();
    const visibilityUpdates: OriginalSequenceIdentity[][] = [
      mutation.plan.removed, mutation.plan.revived,
    ];
    for (let index: number = 0; index < visibilityUpdates.length; index++) {
      const locations: OriginalSequenceIdentity[] = visibilityUpdates[index];
      if (locations.length === 0) {
        continue;
      }
      const visible: boolean = index === 1;
      const encoded: EncodedOriginalTextOperation = encodeOriginalTextVisibility(
        locations, mutation.block, visible);
      const identity: AllocatedOperationIdentity = await allocateOperationIdentity(
        store, step.noteId);
      const metadata: OriginalInkCreateMetadata = allocatedOriginalMetadata(identity);
      const operation: StoredSyncedOperation = localStoredOperation(
        step.noteId, metadata, encoded.payloadType, encoded.payload, null);
      const result: SyncedOperationApplyResult = await visibilityApplier.applyBatchedPayload(
        store, operation,
        decodeOriginalTextVisibility(operation.rawOperation, encoded.payloadType), revisionBatch);
      if (result.deferredReason !== null) {
        throw new Error(`local Text visibility was deferred: ${result.deferredReason}`);
      }
      await appendOperation(store, {
        noteId: step.noteId, opId: identity.opId,
        opType: OpType.ORIGINAL_TEXT_VISIBILITY, payload: operation.rawOperation,
        clientTime: identity.clientTime, opTimestamp: identity.timestamp,
        editorSiteId: identity.siteId, uploadImmediately: true,
      });
    }
    if (mutation.plan.insertedScalars.length > 0) {
      let value: string = '';
      for (const scalar of mutation.plan.insertedScalars) {
        value += String.fromCodePoint(scalar);
      }
      const encoded: EncodedOriginalTextOperation = encodeOriginalTextInsertion(
        mutation.plan.insertionLocation, value, mutation.block);
      const identity: AllocatedOperationIdentity = await allocateOperationIdentity(
        store, step.noteId);
      const metadata: OriginalInkCreateMetadata = allocatedOriginalMetadata(identity);
      const operation: StoredSyncedOperation = localStoredOperation(
        step.noteId, metadata, encoded.payloadType, encoded.payload, null);
      const result: SyncedOperationApplyResult =
        await new OriginalInsertTextOperationApplier().applyBatchedPayload(
          store, operation,
          decodeOriginalInsertText(operation.rawOperation, encoded.payloadType), revisionBatch);
      if (result.deferredReason !== null) {
        throw new Error(`local Text insertion was deferred: ${result.deferredReason}`);
      }
      await appendOperation(store, {
        noteId: step.noteId, opId: identity.opId, opType: OpType.ORIGINAL_INSERT_TEXT,
        payload: operation.rawOperation, clientTime: identity.clientTime,
        opTimestamp: identity.timestamp, editorSiteId: identity.siteId,
        uploadImmediately: true,
      });
    }
    if (mutation.sizeChanged) {
      const identity: AllocatedOperationIdentity = await allocateOperationIdentity(
        store, step.noteId);
      const metadata: OriginalInkCreateMetadata = allocatedOriginalMetadata(identity);
      const payload: Uint8Array = encodeOriginalBlockSize(
        [mutation.block], mutation.width, mutation.height);
      const operation: StoredSyncedOperation = localStoredOperation(
        step.noteId, metadata, ORIGINAL_MODIFY_BLOCK_PAYLOAD_TYPE, payload, null);
      const result: SyncedOperationApplyResult =
        await new OriginalModifyBlockOperationApplier().applyBatchedPayload(
          store, operation, decodeOriginalModifyBlock(operation.rawOperation), revisionBatch);
      if (result.deferredReason !== null) {
        throw new Error(`local Text size was deferred: ${result.deferredReason}`);
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
    if (!samePreparedMembersAndPayloads(materialized, step.elements)) {
      throw new Error('local Text reducers produced unexpected final state');
    }
    await this.reconcilePreparedRows(store, step, expectedRevision);
  }

  private async applyOriginalRenderStyle(store: relationalStore.RdbStore,
    step: PreparedPageSave, mutation: OriginalRenderMutation,
    expectedRevision: number): Promise<void> {
    if (await this.readEligibleOriginalInkPage(store, step.noteId, step.pageId) === null) {
      throw new Error('local MODIFY_INK page is no longer original-aligned');
    }
    const revisionBatch: OriginalPageMutationBatch = new OriginalPageMutationBatch();
    const applier: OriginalModifyInkOperationApplier = new OriginalModifyInkOperationApplier();
    for (const batch of mutation.inkBatches) {
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
    const shapeApplier: OriginalShapeGroupOperationApplier =
      new OriginalShapeGroupOperationApplier();
    for (const batch of mutation.shapeBatches) {
      const identity: AllocatedOperationIdentity = await allocateOperationIdentity(store, step.noteId);
      const payload: Uint8Array = encodeOriginalShapeRenderRegisters(batch.identities, batch);
      const metadata: OriginalInkCreateMetadata = {
        timestamp: identity.timestamp, siteId: identity.siteId, clientTime: identity.clientTime,
        pageTimestamp: 0, pageSiteId: 0, pageIndex: 0, pencilSeed: 0,
      };
      const operation: StoredSyncedOperation = localStoredOperation(
        step.noteId, metadata, ORIGINAL_MODIFY_SHAPE_PAYLOAD_TYPE, payload, null);
      const decoded: OriginalModifyShapePayload = decodeOriginalModifyShape(operation.rawOperation);
      const result: SyncedOperationApplyResult = await shapeApplier.applyPositionPayload(
        store, operation, decoded, revisionBatch);
      if (result.deferredReason !== null) {
        throw new Error(`local MODIFY_SHAPE was deferred: ${result.deferredReason}`);
      }
      await appendOperation(store, {
        noteId: step.noteId, opId: identity.opId, opType: OpType.ORIGINAL_MODIFY_SHAPE,
        payload: operation.rawOperation, clientTime: identity.clientTime,
        opTimestamp: identity.timestamp, editorSiteId: identity.siteId, uploadImmediately: true,
      });
    }
    await revisionBatch.flush(store, step.noteId);
    const materialized: SearchSourceElement[] = await this.loadCurrentSnapshot(
      store, step.noteId, step.pageId);
    if (!samePreparedIdentityOrder(materialized, step.elements)) {
      throw new Error('local render register reducer produced an unexpected element order');
    }
    await this.reconcilePreparedRows(store, step, expectedRevision);
  }

  private async applyOriginalPositionLock(store: relationalStore.RdbStore,
    step: PreparedPageSave, mutation: OriginalPositionLockMutation,
    expectedRevision: number): Promise<void> {
    if (await this.readEligibleOriginalInkPage(store, step.noteId, step.pageId) === null) {
      throw new Error('local position-lock page is no longer original-aligned');
    }
    const revisionBatch: OriginalPageMutationBatch = new OriginalPageMutationBatch();
    const shapeApplier: OriginalShapeGroupOperationApplier =
      new OriginalShapeGroupOperationApplier();
    for (const batch of mutation.shapeBatches) {
      const identity: AllocatedOperationIdentity = await allocateOperationIdentity(store, step.noteId);
      const payload: Uint8Array = encodeOriginalShapeRenderRegisters(batch.identities, {
        style: null, color: null, borderWidth: null, fillColorPresent: false,
        fillColor: null, positionLocked: batch.locked,
      });
      const metadata: OriginalInkCreateMetadata = {
        timestamp: identity.timestamp, siteId: identity.siteId, clientTime: identity.clientTime,
        pageTimestamp: 0, pageSiteId: 0, pageIndex: 0, pencilSeed: 0,
      };
      const operation: StoredSyncedOperation = localStoredOperation(
        step.noteId, metadata, ORIGINAL_MODIFY_SHAPE_PAYLOAD_TYPE, payload, null);
      const decoded: OriginalModifyShapePayload = decodeOriginalModifyShape(operation.rawOperation);
      const result: SyncedOperationApplyResult = await shapeApplier.applyPositionPayload(
        store, operation, decoded, revisionBatch);
      if (result.deferredReason !== null) {
        throw new Error(`local MODIFY_SHAPE position lock was deferred: ${result.deferredReason}`);
      }
      await appendOperation(store, {
        noteId: step.noteId, opId: identity.opId, opType: OpType.ORIGINAL_MODIFY_SHAPE,
        payload: operation.rawOperation, clientTime: identity.clientTime,
        opTimestamp: identity.timestamp, editorSiteId: identity.siteId, uploadImmediately: true,
      });
    }
    const blockApplier: OriginalModifyBlockOperationApplier =
      new OriginalModifyBlockOperationApplier();
    for (const batch of mutation.blockBatches) {
      const identity: AllocatedOperationIdentity = await allocateOperationIdentity(store, step.noteId);
      const payload: Uint8Array = encodeOriginalBlockPositionLocked(
        batch.identities, batch.locked);
      const metadata: OriginalInkCreateMetadata = {
        timestamp: identity.timestamp, siteId: identity.siteId, clientTime: identity.clientTime,
        pageTimestamp: 0, pageSiteId: 0, pageIndex: 0, pencilSeed: 0,
      };
      const operation: StoredSyncedOperation = localStoredOperation(
        step.noteId, metadata, ORIGINAL_MODIFY_BLOCK_PAYLOAD_TYPE, payload, null);
      const decoded: OriginalModifyBlockPayload = decodeOriginalModifyBlock(operation.rawOperation);
      const result: SyncedOperationApplyResult = await blockApplier.applyBatchedPayload(
        store, operation, decoded, revisionBatch);
      if (result.deferredReason !== null) {
        throw new Error(`local MODIFY_BLOCK position lock was deferred: ${result.deferredReason}`);
      }
      await appendOperation(store, {
        noteId: step.noteId, opId: identity.opId, opType: OpType.ORIGINAL_MODIFY_BLOCK,
        payload: operation.rawOperation, clientTime: identity.clientTime,
        opTimestamp: identity.timestamp, editorSiteId: identity.siteId, uploadImmediately: true,
      });
    }
    await revisionBatch.flush(store, step.noteId);
    const materialized: SearchSourceElement[] = await this.loadCurrentSnapshot(
      store, step.noteId, step.pageId);
    if (!samePreparedIdentityOrder(materialized, step.elements)) {
      throw new Error('local position-lock reducer produced an unexpected element order');
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

  private async readLivePageRevision(store: relationalStore.RdbStore,
    noteId: string, pageId: string): Promise<number> {
    const rows = await store.querySql(
      'SELECT content_revision FROM page_info WHERE note_id = ? AND page_id = ?',
      [noteId, pageId]);
    try {
      if (!rows.goToFirstRow()) {
        throw new Error('original clipboard Paste page disappeared');
      }
      const revision: number = rows.getLong(rows.getColumnIndex('content_revision'));
      if (!Number.isSafeInteger(revision) || revision < 0) {
        throw new Error('original clipboard Paste page revision is invalid');
      }
      return revision;
    } finally {
      rows.close();
    }
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
      const originalShapeMetadata: Map<string, OriginalShapeStateRenderMetadata> =
        await this.loadOriginalShapeMetadata(store, noteId);
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
              const originalMetadata: OriginalShapeStateRenderMetadata | undefined =
                originalShapeMetadata.get(shape.id);
              if (originalMetadata !== undefined) {
                if (shape.originalTool === undefined) {
                  shape.originalTool = originalMetadata.tool;
                }
                if (shape.originalStyle === undefined) {
                  shape.originalStyle = originalMetadata.style;
                }
              }
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

  private async loadOriginalShapeMetadata(store: relationalStore.RdbStore,
    noteId: string): Promise<Map<string, OriginalShapeStateRenderMetadata>> {
    const rows = await store.querySql(
      `SELECT shape_timestamp, shape_site_id, resolved_payload
       FROM original_shape_state WHERE note_id = ?`, [noteId]);
    const result: Map<string, OriginalShapeStateRenderMetadata> =
      new Map<string, OriginalShapeStateRenderMetadata>();
    try {
      while (rows.goToNextRow()) {
        try {
          const metadata: OriginalShapeStateRenderMetadata | null =
            decodeOriginalShapeStateRenderMetadata(
            rows.getString(rows.getColumnIndex('resolved_payload')));
          if (metadata !== null) {
            result.set(encodeOperationId({
              timestamp: rows.getLong(rows.getColumnIndex('shape_timestamp')),
              siteId: rows.getLong(rows.getColumnIndex('shape_site_id')),
            }), metadata);
          }
        } catch (_error) {
          // A malformed state row must not prevent the remaining page elements from loading.
        }
      }
    } finally {
      rows.close();
    }
    return result;
  }

  private async preflightOriginalGroupPage(store: relationalStore.RdbStore, noteId: string,
    pageId: string, expectedOrder: PageElementRef[]): Promise<void> {
    if (await this.readEligibleOriginalInkPage(store, noteId, pageId) === null) {
      throw new Error('local Group page is not original-aligned');
    }
    const actual: PageElementRef[] = await this.readCurrentPageElementOrder(store, noteId, pageId);
    if (!samePageElementOrder(actual, expectedOrder)) {
      throw new Error('local Group page order changed before apply');
    }
  }

  private async readCurrentPageElementOrder(store: relationalStore.RdbStore,
    noteId: string, pageId: string): Promise<PageElementRef[]> {
    const current: SearchSourceElement[] = await this.loadCurrentSnapshot(store, noteId, pageId);
    return current.map((element: SearchSourceElement, index: number): PageElementRef => ({
      kind: element.kind, elementId: element.elementId, zIndex: index,
    }));
  }

  private decodeUniqueGroupMembers(memberIds: string[], minimum: number): OperationIdentity[] {
    if (memberIds.length < minimum || memberIds.length > 10000) {
      throw new Error('local Group member count is invalid');
    }
    const result: OperationIdentity[] = [];
    const seen: Set<string> = new Set<string>();
    for (const memberId of memberIds) {
      const identity: OperationIdentity | null = decodeOperationId(memberId);
      if (identity === null || seen.has(memberId)) {
        throw new Error('local Group member identity is invalid');
      }
      seen.add(memberId);
      result.push(identity);
    }
    return result;
  }

  private validateSelectionGroup(group: OriginalSelectionGroup): void {
    const identity: OperationIdentity | null = decodeOperationId(group.id);
    if (identity === null || identity.timestamp !== group.timestamp || identity.siteId !== group.siteId) {
      throw new Error('local Group identity is invalid');
    }
    this.decodeUniqueGroupMembers(group.members, 1);
  }

  private localGroupMembersAreValid(memberIds: string[], groups: OriginalSelectionGroup[],
    current: SearchSourceElement[]): boolean {
    const available: Set<string> = new Set<string>(current.map(
      (element: SearchSourceElement): string => element.elementId));
    const byId: Map<string, OriginalSelectionGroup> = this.groupMap(groups);
    const parentMembers: Set<string> = new Set<string>();
    for (const group of groups) {
      for (const member of group.members) {
        parentMembers.add(member);
      }
    }
    const leaves: Set<string> = new Set<string>();
    for (const memberId of memberIds) {
      const group: OriginalSelectionGroup | undefined = byId.get(memberId);
      if (parentMembers.has(memberId)) {
        return false;
      }
      if (group === undefined) {
        if (!available.has(memberId) || leaves.has(memberId)) {
          return false;
        }
        leaves.add(memberId);
        continue;
      }
      const expanded: string[] | null = this.expandStoredGroup(
        group.id, byId, available, new Set<string>());
      if (expanded === null || expanded.length === 0) {
        return false;
      }
      for (const leaf of expanded) {
        if (leaves.has(leaf)) {
          return false;
        }
        leaves.add(leaf);
      }
    }
    return leaves.size >= 2;
  }

  private groupLeavesBelongToPage(groupId: string, groups: OriginalSelectionGroup[],
    current: SearchSourceElement[]): boolean {
    const available: Set<string> = new Set<string>(current.map(
      (element: SearchSourceElement): string => element.elementId));
    const expanded: string[] | null = this.expandStoredGroup(
      groupId, this.groupMap(groups), available, new Set<string>());
    return expanded !== null && expanded.length > 0;
  }

  private expandStoredGroup(groupId: string, byId: Map<string, OriginalSelectionGroup>,
    available: Set<string>, visiting: Set<string>): string[] | null {
    if (visiting.has(groupId)) {
      return null;
    }
    const group: OriginalSelectionGroup | undefined = byId.get(groupId);
    if (group === undefined) {
      return null;
    }
    visiting.add(groupId);
    const leaves: string[] = [];
    const seen: Set<string> = new Set<string>();
    for (const member of group.members) {
      if (byId.has(member)) {
        const nested: string[] | null = this.expandStoredGroup(member, byId, available, visiting);
        if (nested === null) {
          visiting.delete(groupId);
          return null;
        }
        for (const leaf of nested) {
          if (!seen.has(leaf)) {
            seen.add(leaf);
            leaves.push(leaf);
          }
        }
      } else if (!available.has(member)) {
        visiting.delete(groupId);
        return null;
      } else if (!seen.has(member)) {
        seen.add(member);
        leaves.push(member);
      }
    }
    visiting.delete(groupId);
    return leaves;
  }

  private groupMap(groups: OriginalSelectionGroup[]): Map<string, OriginalSelectionGroup> {
    const result: Map<string, OriginalSelectionGroup> = new Map<string, OriginalSelectionGroup>();
    for (const group of groups) {
      if (result.has(group.id)) {
        return new Map<string, OriginalSelectionGroup>();
      }
      result.set(group.id, group);
    }
    return result;
  }

  private containsExactGroup(groups: OriginalSelectionGroup[], group: OriginalSelectionGroup): boolean {
    const found: OriginalSelectionGroup | undefined = groups.find(
      (candidate: OriginalSelectionGroup): boolean => candidate.id === group.id);
    return found !== undefined && sameOriginalSelectionGroups([found], [group]);
  }

  private containsGroupId(groups: OriginalSelectionGroup[], groupId: string): boolean {
    return groups.some((group: OriginalSelectionGroup): boolean => group.id === groupId);
  }

  private affectedGroupStateMatches(active: OriginalSelectionGroup[],
    expected: OriginalSelectionGroup[], other: OriginalSelectionGroup[]): boolean {
    const group: OriginalSelectionGroup = expected.length === 1 ? expected[0] : other[0];
    return expected.length === 1 ? this.containsExactGroup(active, group) :
      !this.containsGroupId(active, group.id);
  }

  private async readStoredGroup(store: relationalStore.RdbStore, noteId: string,
    expected: OriginalSelectionGroup): Promise<OriginalSelectionGroup | null> {
    const rows = await store.querySql(
      `SELECT members_value FROM original_group_state WHERE note_id = ?
       AND group_timestamp = ? AND group_site_id = ? LIMIT 1`,
      [noteId, expected.timestamp, expected.siteId]);
    try {
      if (!rows.goToFirstRow()) {
        return null;
      }
      const raw: PersistedGroupMember[] = JSON.parse(
        rows.getString(rows.getColumnIndex('members_value'))) as PersistedGroupMember[];
      if (!Array.isArray(raw) || raw.length === 0 || raw.length > 10000) {
        return null;
      }
      const members: string[] = [];
      const seen: Set<string> = new Set<string>();
      for (const value of raw) {
        const member: OperationIdentity = { timestamp: value.timestamp, siteId: value.siteId };
        validateOperationIdentity(member);
        const memberId: string = encodeOperationId(member);
        if (seen.has(memberId)) {
          return null;
        }
        seen.add(memberId);
        members.push(memberId);
      }
      return { id: expected.id, timestamp: expected.timestamp,
        siteId: expected.siteId, members: members };
    } catch (_error) {
      return null;
    } finally {
      rows.close();
    }
  }

  private groupOperationMetadata(identity: AllocatedOperationIdentity): OriginalInkCreateMetadata {
    return {
      timestamp: identity.timestamp, siteId: identity.siteId, clientTime: identity.clientTime,
      pageTimestamp: 0, pageSiteId: 0, pageIndex: 0, pencilSeed: 0,
    };
  }

  private async applyOriginalGroupVisibility(store: relationalStore.RdbStore, noteId: string,
    group: OriginalSelectionGroup, deleted: boolean): Promise<void> {
    const identity: AllocatedOperationIdentity = await allocateOperationIdentity(store, noteId);
    const target: OperationIdentity = { timestamp: group.timestamp, siteId: group.siteId };
    const payload: Uint8Array = encodeOriginalEntityVisibility(
      deleted ? [target] : [], deleted ? [] : [target]);
    const operation: StoredSyncedOperation = localStoredOperation(
      noteId, this.groupOperationMetadata(identity), ORIGINAL_DELETE_ENTITIES_PAYLOAD_TYPE,
      payload, null);
    const result: SyncedOperationApplyResult =
      await new OriginalDeleteEntitiesOperationApplier().apply(store, operation);
    if (result.deferredReason !== null) {
      throw new Error(`local Group visibility was deferred: ${result.deferredReason}`);
    }
    await appendOperation(store, {
      noteId: noteId, opId: identity.opId, opType: OpType.ORIGINAL_DELETE_ENTITIES,
      payload: operation.rawOperation, clientTime: identity.clientTime,
      opTimestamp: identity.timestamp, editorSiteId: identity.siteId, uploadImmediately: true,
    });
  }

  private async appendOriginalGroupHistory(store: relationalStore.RdbStore, noteId: string,
    mutation: OriginalGroupMutationOpPayload, history: HistoryMetadata): Promise<void> {
    const identity: AllocatedOperationIdentity = await allocateOperationIdentity(store, noteId);
    await appendOperation(store, {
      noteId: noteId, opId: identity.opId, opType: OpType.GROUP_ELEMENTS,
      payload: encodeOriginalGroupMutation(mutation), clientTime: identity.clientTime,
      opTimestamp: identity.timestamp, editorSiteId: identity.siteId, history: history,
    });
  }

  private async appendOriginalClipboardPasteHistory(store: relationalStore.RdbStore,
    noteId: string, mutation: OriginalClipboardPasteMutation,
    history: HistoryMetadata): Promise<Op> {
    const identity: AllocatedOperationIdentity = await allocateOperationIdentity(store, noteId);
    const operation: Op = {
      noteId: noteId, opId: identity.opId, opType: OpType.ORIGINAL_CLIPBOARD_PASTE,
      payload: encodeOriginalClipboardPasteMutation(mutation), clientTime: identity.clientTime,
      opTimestamp: identity.timestamp, editorSiteId: identity.siteId, history: history,
    };
    await appendOperation(store, operation);
    return operation;
  }

  private async appendOriginalCreateOperation(store: relationalStore.RdbStore,
    noteId: string, identity: AllocatedOperationIdentity, opType: OpType,
    payload: Uint8Array): Promise<void> {
    await appendOperation(store, {
      noteId: noteId, opId: identity.opId, opType: opType, payload: payload,
      clientTime: identity.clientTime, opTimestamp: identity.timestamp,
      editorSiteId: identity.siteId, uploadImmediately: true,
    });
  }

  private reconcileOriginalClipboardPasteSnapshot(noteId: string, pageId: string,
    before: SearchSourceElement[], materialized: SearchSourceElement[],
    created: PreparedElement[], history: HistoryMetadata): PreparedPageSave {
    if (materialized.length !== before.length + created.length) {
      throw new Error('original clipboard Paste materialized an unexpected element count');
    }
    const beforeByKey: Map<string, SearchSourceElement> = new Map<string, SearchSourceElement>();
    const createdByKey: Map<string, PreparedElement> = new Map<string, PreparedElement>();
    for (const element of before) {
      beforeByKey.set(`${element.kind}:${element.elementId}`, element);
    }
    for (const element of created) {
      createdByKey.set(`${element.kind}:${element.elementId}`, element);
    }
    const elements: PreparedElement[] = [];
    for (const actual of materialized) {
      const key: string = `${actual.kind}:${actual.elementId}`;
      const pasted: PreparedElement | undefined = createdByKey.get(key);
      if (pasted !== undefined) {
        elements.push({
          elementId: pasted.elementId, kind: pasted.kind,
          payload: pasted.payload, searchText: pasted.searchText,
        });
        createdByKey.delete(key);
        continue;
      }
      const previous: SearchSourceElement | undefined = beforeByKey.get(key);
      if (previous === undefined || !sameByteArrays(previous.payload, actual.payload)) {
        throw new Error('original clipboard Paste changed a pre-existing element');
      }
      elements.push({
        elementId: previous.elementId, kind: previous.kind, payload: previous.payload,
        searchText: searchTextForElement(previous.kind, previous.payload),
      });
      beforeByKey.delete(key);
    }
    if (beforeByKey.size !== 0 || createdByKey.size !== 0) {
      throw new Error('original clipboard Paste materialized an incomplete page');
    }
    return { noteId: noteId, pageId: pageId, elements: elements, history: history };
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

function sameTextStyleRuns(text: TextBlockElement,
  characterRuns: RichTextCharacterStyleRun[],
  paragraphRuns: RichTextParagraphStyleRun[]): boolean {
  return JSON.stringify(text.characterStyleRuns ?? []) === JSON.stringify(characterRuns) &&
    JSON.stringify(text.paragraphStyleRuns ?? []) === JSON.stringify(paragraphRuns);
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

function sameSearchSourceElements(left: SearchSourceElement[],
  right: SearchSourceElement[]): boolean {
  if (left.length !== right.length) {
    return false;
  }
  for (let index: number = 0; index < left.length; index++) {
    if (!sameElement(left[index], right[index])) {
      return false;
    }
  }
  return true;
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

function clonePageElementRefs(order: PageElementRef[]): PageElementRef[] {
  return order.map((ref: PageElementRef): PageElementRef => ({
    kind: ref.kind,
    elementId: ref.elementId,
    zIndex: ref.zIndex,
  }));
}

function cloneSelectionGroup(group: OriginalSelectionGroup): OriginalSelectionGroup {
  return {
    id: group.id,
    timestamp: group.timestamp,
    siteId: group.siteId,
    members: group.members.slice(),
  };
}

function cloneStrokeThroughPersistence(stroke: StrokeElementData): StrokeElementData {
  const persisted: PersistedElement = decodePersistedElement(
    encodePersistedElement({ kind: 'stroke', data: stroke }));
  if (persisted.kind !== 'stroke') {
    throw new Error('original clipboard Paste Ink clone changed kind');
  }
  return persisted.data as StrokeElementData;
}

function cloneOriginalClipboardPastePlan(
  plan: OriginalClipboardPastePlan): OriginalClipboardPastePlan {
  return {
    strokes: plan.strokes.map(cloneStrokeThroughPersistence),
    shapes: plan.shapes.map(cloneShapeElement),
    textBlocks: plan.textBlocks.map(cloneTextBlockElement),
    images: plan.images.map(cloneImageElement),
    mathBlocks: plan.mathBlocks.map(cloneMathElement),
    elementOrder: clonePageElementRefs(plan.elementOrder),
    groups: plan.groups.map(cloneSelectionGroup),
    topGroupIds: plan.topGroupIds.slice(),
  };
}

function materializeOriginalMathCreate(id: string,
  payload: OriginalCreateBlockPayload): MathElement {
  if (payload.blockType !== OriginalBlockType.MATH || payload.mathLatex === null ||
    payload.mathColor === null) {
    throw new Error('original clipboard Math CREATE_BLOCK decoded to a different kind');
  }
  const rotation: number = payload.rotation === null ? 0 : payload.rotation;
  const scaleX: number = payload.scaleX === null ? 1 : payload.scaleX;
  const scaleY: number = payload.scaleY === null ? 1 : payload.scaleY;
  const cosine: number = Math.cos(rotation);
  const sine: number = Math.sin(rotation);
  const math: MathElement = {
    id: id, type: ElementType.MATH,
    transform: [
      cosine * scaleX, -sine * scaleY, payload.originX,
      sine * scaleX, cosine * scaleY, payload.originY,
      0, 0, 1,
    ],
    bounds: { left: 0, top: 0, right: 0, bottom: 0 },
    latex: payload.mathLatex, color: payload.mathColor,
    blockWidth: payload.width, blockHeight: payload.height,
    rotationRadians: rotation, corner: payload.corner, textWrap: payload.textWrap,
    enableCaption: payload.enableCaption, positionLocked: payload.positionLocked,
  };
  math.bounds = mathBlockWorldBounds(math);
  return math;
}

function materializeOriginalTextCreate(id: string, payload: OriginalCreateBlockPayload,
  richText: string, metadata: OriginalInkCreateMetadata): TextBlockElement {
  if (payload.blockType !== OriginalBlockType.TEXT) {
    throw new Error('original clipboard Text CREATE_BLOCK decoded to a different kind');
  }
  const rotation: number = payload.rotation === null ? 0 : payload.rotation;
  const scaleX: number = payload.scaleX === null ? 1 : payload.scaleX;
  const scaleY: number = payload.scaleY === null ? 1 : payload.scaleY;
  const cosine: number = Math.cos(rotation);
  const sine: number = Math.sin(rotation);
  const text: TextBlockElement = {
    id: id, type: ElementType.TEXT,
    transform: [
      cosine * scaleX, -sine * scaleY, payload.originX,
      sine * scaleX, cosine * scaleY, payload.originY,
      0, 0, 1,
    ],
    bounds: { left: 0, top: 0, right: 0, bottom: 0 },
    richText: richText, textOrigin: { x: 0, y: 0 },
    blockWidth: payload.width, blockHeight: payload.height,
    rotationRadians: rotation,
    contentLeftInset: payload.margins.left, contentTopInset: payload.margins.top,
    fontSize: 17, fontColor: -16777216,
    corner: payload.corner, textWrap: payload.textWrap,
    enableCaption: payload.enableCaption, paper: null,
    resizesWidthToFitText: payload.resizesWidthToFitText,
    positionLocked: payload.positionLocked,
    originalCreate: {
      timestamp: metadata.timestamp, siteId: metadata.siteId,
      clientTime: metadata.clientTime,
      pageTimestamp: metadata.pageTimestamp, pageSiteId: metadata.pageSiteId,
      pageIndex: metadata.pageIndex, pencilSeed: metadata.pencilSeed,
    },
  };
  text.bounds = textBlockWorldBounds(text);
  return text;
}

function materializeOriginalImageCreate(id: string,
  payload: OriginalCreateBlockPayload): ImageElement {
  if (payload.blockType !== OriginalBlockType.IMAGE || payload.image === null) {
    throw new Error('original clipboard Image CREATE_BLOCK decoded to a different kind');
  }
  const rotation: number = payload.rotation === null ? 0 : payload.rotation;
  const scaleX: number = payload.scaleX === null ? 1 : payload.scaleX;
  const scaleY: number = payload.scaleY === null ? 1 : payload.scaleY;
  const cosine: number = Math.cos(rotation);
  const sine: number = Math.sin(rotation);
  const asset = payload.image;
  const image: ImageElement = {
    id: id, type: ElementType.IMAGE,
    transform: [
      cosine * scaleX, -sine * scaleY, payload.originX,
      sine * scaleX, cosine * scaleY, payload.originY,
      0, 0, 1,
    ],
    bounds: { left: 0, top: 0, right: 0, bottom: 0 },
    assetHash: originalAssetHashKey(asset.assetHash.bits),
    assetHashBits: asset.assetHash.bits.slice(),
    fileName: asset.fileName, mimeType: asset.mimeType, fileSize: asset.fileSize,
    intrinsicWidth: asset.width, intrinsicHeight: asset.height,
    cropRect: payload.cropRect === null ? null : {
      left: payload.cropRect.x, top: payload.cropRect.y,
      right: payload.cropRect.x + payload.cropRect.width,
      bottom: payload.cropRect.y + payload.cropRect.height,
    },
    blockWidth: payload.width, blockHeight: payload.height,
    rotationRadians: rotation, corner: payload.corner, textWrap: payload.textWrap,
    enableCaption: payload.enableCaption, webUrl: payload.webUrl,
    imageFlippedHorizontally: payload.imageFlippedHorizontally,
    imageFlippedVertically: payload.imageFlippedVertically,
    positionLocked: payload.positionLocked,
  };
  image.bounds = imageBlockWorldBounds(image);
  return image;
}

function searchTextForElement(kind: number, payload: Uint8Array): string | null {
  try {
    const persisted: PersistedElement = decodePersistedElement(payload);
    if (kind === PageElementKind.TEXT && persisted.kind === 'text') {
      return foldSearchText((persisted.data as TextBlockElement).richText);
    }
    if (kind === PageElementKind.SHAPE && persisted.kind === 'shape') {
      return foldSearchText((persisted.data as ShapeElement).richText ?? '');
    }
  } catch (_error) {
    return null;
  }
  return null;
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

function allocatedOriginalMetadata(identity: AllocatedOperationIdentity): OriginalInkCreateMetadata {
  return {
    timestamp: identity.timestamp, siteId: identity.siteId, clientTime: identity.clientTime,
    pageTimestamp: 0, pageSiteId: 0, pageIndex: 0, pencilSeed: 0,
  };
}
