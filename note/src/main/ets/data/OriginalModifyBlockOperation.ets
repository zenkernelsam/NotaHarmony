import { relationalStore } from '@kit.ArkData';
import {
  ImageElement, MathElement, RichTextCharacterStyle, RichTextCharacterStyleRun,
  RichTextParagraphStyle, RichTextParagraphStyleRun, TextBlockElement,
} from '../core/model/ElementTypes';
import { Rect2D, TransformMatrix } from '../core/model/GeometryTypes';
import {
  cloneImageElement, imageBlockWorldBounds, originalAssetHashKey,
} from '../core/model/ImageBlockGeometry';
import { PagePaperBackground } from '../core/model/NoteTypes';
import { PageElementKind } from '../core/model/PageElementOrder';
import { textBlockWorldBounds } from '../core/model/TextBlockGeometry';
import { cloneMathElement, mathBlockWorldBounds } from '../core/model/MathBlockGeometry';
import { cloneOriginalPaper, validateOriginalPaper } from '../core/model/PageBackgroundModel';
import {
  compareOperationIdentity, encodeOperationId, OperationIdentity, OriginalSequenceIdentity,
  validateOperationIdentity, validateOriginalSequenceIdentity,
} from './OperationIdentity';
import { OriginalBlockRect, OriginalBlockType } from './OriginalCreateBlockOperation';
import { decodeOriginalPaper } from './OriginalPageBackgroundOperation';
import {
  OriginalFlatBufferTableReader, readOriginalInlineFloat32, readOriginalPayloadTable,
} from './OriginalSyncedOperationFlatBuffer';
import { originalGroupLayerRanks, OriginalLayeringEntity } from './OriginalGroupLayering';
import { SearchItemType } from './SearchItemType';
import { OriginalMutationPageTarget, OriginalPageMutationBatch } from './OriginalPageMutationBatch';
import { decodePersistedElement, encodePersistedElement, PersistedElement } from './StrokePersistence';
import {
  StoredSyncedOperation, SyncedOperationApplier, SyncedOperationApplyResult,
} from './SyncedOperationInbox';
import { compareUnsignedLongDecimal, validateUnsignedLongDecimal } from './UnsignedDecimal';

export const ORIGINAL_MODIFY_BLOCK_PAYLOAD_TYPE: number = 23;
const MAX_ORIGINAL_MODIFY_BLOCK_COUNT: number = 10000;
const MAX_ORIGINAL_MATH_LATEX_BYTES: number = 1048576;
const DEFAULT_MATH_COLOR: number = -16777216;

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
  paper: NullableBlockRegisterUpdate<PagePaperBackground>;
  resizesWidthToFitText: boolean | null;
  cropRect: NullableBlockRegisterUpdate<OriginalBlockRect>;
  imageFlippedHorizontally: boolean | null;
  imageFlippedVertically: boolean | null;
  zIndex: string | null;
  positionLocked: boolean | null;
  mathLatex: NullableBlockRegisterUpdate<string>;
  mathColor: NullableBlockRegisterUpdate<number>;
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
  basePaper: PagePaperBackground | null;
  paper: StoredRegister<PagePaperBackground>;
  baseResizesWidth: boolean;
  resizesWidth: StoredRegister<boolean>;
  baseImageCrop: OriginalBlockRect | null;
  imageCrop: StoredRegister<OriginalBlockRect>;
  baseImageFlipHorizontal: boolean;
  imageFlipHorizontal: StoredRegister<boolean>;
  baseImageFlipVertical: boolean;
  imageFlipVertical: StoredRegister<boolean>;
  baseImageHashBits: string[] | null;
  baseImageFileName: string | null;
  baseImageMimeType: string | null;
  baseImageFileSize: number | null;
  baseImageWidth: number | null;
  baseImageHeight: number | null;
  baseImageWebUrl: string | null;
  baseMathLatex: string | null;
  mathLatex: StoredRegister<string>;
  baseMathColor: number | null;
  mathColor: StoredRegister<number>;
  basePositionLocked: boolean;
  positionLocked: StoredRegister<boolean>;
  baseLeftInset: number;
  baseTopInset: number;
  baseZIndex: string;
  zIndex: StoredRegister<string>;
}

interface StoredPageTarget extends OriginalMutationPageTarget {
  table: string;
}

interface StoredBlockTarget extends StoredPageTarget {
  block: OperationIdentity;
  zIndex: string;
  kind: PageElementKind;
  blockType: OriginalBlockType;
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

interface AffectedPage {
  target: StoredPageTarget;
  textChanged: boolean;
}

type ModifiableBlockElement = TextBlockElement | ImageElement | MathElement;

interface PlannedBlockReplacement {
  target: StoredBlockTarget;
  destination: StoredPageTarget;
  state: StoredBlockState;
  element: ModifiableBlockElement;
  updatedElement: ModifiableBlockElement;
  pageOriginValue: OriginalBlockPageOrigin;
  rotationValue: number | null;
  scaleValue: OriginalBlockScale | null;
  sizeValue: OriginalBlockScale;
  cornerValue: number;
  textWrapValue: number;
  enableCaptionValue: boolean;
  paperValue: PagePaperBackground | null;
  resizesWidthValue: boolean;
  imageCropValue: OriginalBlockRect | null;
  imageFlipHorizontalValue: boolean;
  imageFlipVerticalValue: boolean;
  mathLatexValue: string | null;
  mathColorValue: number | null;
  positionLockedValue: boolean;
  zIndexValue: string;
  replacePageOrigin: boolean;
  replaceRotation: boolean;
  replaceScale: boolean;
  replaceSize: boolean;
  replaceCorner: boolean;
  replaceTextWrap: boolean;
  replaceEnableCaption: boolean;
  replacePaper: boolean;
  replaceResizesWidth: boolean;
  replaceImageCrop: boolean;
  replaceImageFlipHorizontal: boolean;
  replaceImageFlipVertical: boolean;
  replaceMathLatex: boolean;
  replaceMathColor: boolean;
  replacePositionLocked: boolean;
  replaceZIndex: boolean;
}

export function decodeOriginalModifyBlock(bytes: Uint8Array): OriginalModifyBlockPayload {
  const table: OriginalFlatBufferTableReader = readOriginalPayloadTable(
    bytes, ORIGINAL_MODIFY_BLOCK_PAYLOAD_TYPE);
  return decodeOriginalModifyBlockTable(table);
}

export function decodeOriginalModifyBlockTable(
  table: OriginalFlatBufferTableReader): OriginalModifyBlockPayload {
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
  const cropSetter: OriginalFlatBufferTableReader | null = table.readTable(12);
  const cropBytes: Uint8Array | null = cropSetter === null ? null :
    cropSetter.readInlineBytes(0, 16);
  const paperSetter: OriginalFlatBufferTableReader | null = table.readTable(13);
  const paperTable: OriginalFlatBufferTableReader | null = paperSetter === null ? null :
    paperSetter.readTable(0);
  const zIndex: string | null = table.readUint64Decimal(9);
  const mathLatexSetter: OriginalFlatBufferTableReader | null = table.readTable(10);
  const mathColorSetter: OriginalFlatBufferTableReader | null = table.readTable(11);
  const mathColorBytes: Uint8Array | null = mathColorSetter === null ? null :
    mathColorSetter.readInlineBytes(0, 4);
  if (zIndex !== null) {
    validateUnsignedLongDecimal(zIndex);
  }
  const cropRect: OriginalBlockRect | null = cropBytes === null ? null : {
    x: readOriginalInlineFloat32(cropBytes, 0),
    y: readOriginalInlineFloat32(cropBytes, 4),
    width: readOriginalInlineFloat32(cropBytes, 8),
    height: readOriginalInlineFloat32(cropBytes, 12),
  };
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
    paper: {
      present: paperSetter !== null,
      value: paperTable === null ? null : decodeOriginalPaper(paperTable),
    },
    resizesWidthToFitText: table.hasField(16) ? table.readUint8(16, 0) !== 0 : null,
    cropRect: { present: cropSetter !== null, value: cropRect },
    imageFlippedHorizontally: table.hasField(14) ? table.readUint8(14, 0) !== 0 : null,
    imageFlippedVertically: table.hasField(15) ? table.readUint8(15, 0) !== 0 : null,
    zIndex: zIndex,
    positionLocked: table.hasField(17) ? table.readUint8(17, 0) !== 0 : null,
    mathLatex: {
      present: mathLatexSetter !== null,
      value: mathLatexSetter === null ? null :
        mathLatexSetter.readUtf8String(0, false, MAX_ORIGINAL_MATH_LATEX_BYTES),
    },
    mathColor: {
      present: mathColorSetter !== null,
      value: mathColorBytes === null ? null : rgbaBytesToArgb(mathColorBytes),
    },
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
    return this.applyPayload(store, operation, payload);
  }

  preflightTable(table: OriginalFlatBufferTableReader): string | null {
    let payload: OriginalModifyBlockPayload;
    try {
      payload = decodeOriginalModifyBlockTable(table);
    } catch (_error) {
      return 'MALFORMED_MODIFY_BLOCK_PAYLOAD';
    }
    return preflightOriginalModifyBlock(payload);
  }

  async applyTable(store: relationalStore.RdbStore, operation: StoredSyncedOperation,
    table: OriginalFlatBufferTableReader): Promise<SyncedOperationApplyResult> {
    let payload: OriginalModifyBlockPayload;
    try {
      payload = decodeOriginalModifyBlockTable(table);
    } catch (_error) {
      return { deferredReason: 'MALFORMED_MODIFY_BLOCK_PAYLOAD' };
    }
    return this.applyPayload(store, operation, payload);
  }

  async applyPositionPayload(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation, payload: OriginalModifyBlockPayload,
    revisionBatch: OriginalPageMutationBatch): Promise<SyncedOperationApplyResult> {
    return this.applyPayload(store, operation, payload, revisionBatch);
  }

  private async applyPayload(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation,
    payload: OriginalModifyBlockPayload,
    revisionBatch: OriginalPageMutationBatch | null = null): Promise<SyncedOperationApplyResult> {
    const preflightReason: string | null = preflightOriginalModifyBlock(payload);
    if (preflightReason !== null) {
      return { deferredReason: preflightReason };
    }
    if (payload.pageOrigin === null && !payload.rotation.present && !payload.scale.present &&
      payload.width === null && payload.corner === null && payload.textWrap === null &&
      payload.enableCaption === null && !payload.paper.present &&
      payload.resizesWidthToFitText === null && payload.positionLocked === null &&
      !payload.cropRect.present && payload.imageFlippedHorizontally === null &&
      payload.imageFlippedVertically === null &&
      !payload.mathLatex.present && !payload.mathColor.present &&
      payload.zIndex === null) {
      return { deferredReason: null };
    }

    const planned: PlannedBlockReplacement[] = [];
    for (const block of payload.blocks) {
      const target: StoredBlockTarget | null = await this.readTarget(store, operation.noteId, block);
      if (target === null) {
        return { deferredReason: 'MODIFY_BLOCK_TARGET_MISSING_OR_UNBOUND' };
      }
      if (target.blockType !== OriginalBlockType.IMAGE &&
        (payload.cropRect.present || payload.imageFlippedHorizontally !== null ||
          payload.imageFlippedVertically !== null)) {
        return { deferredReason: 'MODIFY_BLOCK_IMAGE_FIELDS_ON_NON_IMAGE' };
      }
      if (target.blockType !== OriginalBlockType.TEXT &&
        (payload.paper.present || payload.resizesWidthToFitText !== null)) {
        return { deferredReason: 'MODIFY_BLOCK_TEXT_FIELDS_ON_NON_TEXT' };
      }
      if (target.blockType !== OriginalBlockType.MATH &&
        (payload.mathLatex.present || payload.mathColor.present)) {
        return { deferredReason: 'MODIFY_BLOCK_MATH_FIELDS_ON_NON_MATH' };
      }
      const state: StoredBlockState | null = await this.readState(store, operation.noteId, block);
      const element: ModifiableBlockElement | null = await this.readBlockElement(
        store, operation.noteId, target);
      if (state === null || element === null || !this.currentStateMatches(target, state, element)) {
        return { deferredReason: 'MODIFY_BLOCK_STATE_DIVERGED' };
      }
      assertMatchingModifyBlockWinners(payload, state, operation);
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
      const replacePaper: boolean = payload.paper.present &&
        registerAccepts(operation, state.paper.winner);
      const replaceResizesWidth: boolean = payload.resizesWidthToFitText !== null &&
        registerAccepts(operation, state.resizesWidth.winner);
      const replaceImageCrop: boolean = payload.cropRect.present &&
        registerAccepts(operation, state.imageCrop.winner);
      const replaceImageFlipHorizontal: boolean = payload.imageFlippedHorizontally !== null &&
        registerAccepts(operation, state.imageFlipHorizontal.winner);
      const replaceImageFlipVertical: boolean = payload.imageFlippedVertically !== null &&
        registerAccepts(operation, state.imageFlipVertical.winner);
      const replaceMathLatex: boolean = payload.mathLatex.present &&
        registerAccepts(operation, state.mathLatex.winner);
      const replaceMathColor: boolean = payload.mathColor.present &&
        registerAccepts(operation, state.mathColor.winner);
      const replacePositionLocked: boolean = payload.positionLocked !== null &&
        registerAccepts(operation, state.positionLocked.winner);
      const replaceZIndex: boolean = payload.zIndex !== null &&
        registerAccepts(operation, state.zIndex.winner);
      if (!replacePageOrigin && !replaceRotation && !replaceScale && !replaceSize &&
        !replaceCorner && !replaceTextWrap && !replaceEnableCaption && !replacePaper &&
        !replaceResizesWidth && !replaceImageCrop && !replaceImageFlipHorizontal &&
        !replaceImageFlipVertical && !replaceMathLatex && !replaceMathColor &&
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
      if (destination === null || (!target.hidden &&
        (target.revision >= Number.MAX_SAFE_INTEGER ||
          destination.revision >= Number.MAX_SAFE_INTEGER))) {
        return { deferredReason: 'MODIFY_BLOCK_DESTINATION_MISSING_OR_EXHAUSTED' };
      }
      const updatedElement: ModifiableBlockElement = target.kind === PageElementKind.TEXT ?
        cloneText(element as TextBlockElement) : target.kind === PageElementKind.IMAGE ?
          cloneImageElement(element as ImageElement) : cloneMathElement(element as MathElement);
      const scale: OriginalBlockScale = scaleValue === null ? { x: 1, y: 1 } : scaleValue;
      updatedElement.transform = blockTransform(pageOriginValue.originX, pageOriginValue.originY,
        rotationValue === null ? 0 : rotationValue, scale.x, scale.y);
      updatedElement.rotationRadians = rotationValue === null ? 0 : rotationValue;
      updatedElement.blockWidth = sizeValue.x;
      updatedElement.blockHeight = sizeValue.y;
      if (replaceCorner) {
        updatedElement.corner = payload.corner as number;
      }
      if (replaceTextWrap) {
        updatedElement.textWrap = payload.textWrap as number;
      }
      if (replaceEnableCaption) {
        updatedElement.enableCaption = payload.enableCaption as boolean;
      }
      if (target.kind === PageElementKind.TEXT) {
        const updatedText: TextBlockElement = updatedElement as TextBlockElement;
        if (replacePaper) {
          updatedText.paper = cloneOriginalPaper(payload.paper.value);
        }
        if (replaceResizesWidth) {
          updatedText.resizesWidthToFitText = payload.resizesWidthToFitText as boolean;
        }
        updatedText.bounds = textBlockWorldBounds(updatedText);
      } else if (target.kind === PageElementKind.IMAGE) {
        const updatedImage: ImageElement = updatedElement as ImageElement;
        if (replaceImageCrop) {
          updatedImage.cropRect = originalRectToRect(payload.cropRect.value);
        }
        if (replaceImageFlipHorizontal) {
          updatedImage.imageFlippedHorizontally = payload.imageFlippedHorizontally as boolean;
        }
        if (replaceImageFlipVertical) {
          updatedImage.imageFlippedVertically = payload.imageFlippedVertically as boolean;
        }
        updatedImage.bounds = imageBlockWorldBounds(updatedImage);
      } else {
        const updatedMath: MathElement = updatedElement as MathElement;
        if (replaceMathLatex) {
          updatedMath.latex = payload.mathLatex.value === null ? '' : payload.mathLatex.value;
        }
        if (replaceMathColor) {
          updatedMath.color = payload.mathColor.value === null ? DEFAULT_MATH_COLOR :
            payload.mathColor.value;
        }
        updatedMath.bounds = mathBlockWorldBounds(updatedMath);
      }
      updatedElement.positionLocked = replacePositionLocked ? payload.positionLocked as boolean :
        effectiveBoolean(state.basePositionLocked, state.positionLocked);
      planned.push({
        target: target, destination: destination, state: state, element: element,
        updatedElement: updatedElement,
        pageOriginValue: pageOriginValue, rotationValue: rotationValue, scaleValue: scaleValue,
        sizeValue: sizeValue,
        cornerValue: replaceCorner ? payload.corner as number : effectiveNumber(state.baseCorner, state.corner),
        textWrapValue: replaceTextWrap ? payload.textWrap as number :
          effectiveNumber(state.baseTextWrap, state.textWrap),
        enableCaptionValue: replaceEnableCaption ? payload.enableCaption as boolean :
          effectiveBoolean(state.baseEnableCaption, state.enableCaption),
        paperValue: replacePaper ? cloneOriginalPaper(payload.paper.value) :
          cloneOriginalPaper(effectiveNullable(state.basePaper, state.paper)),
        resizesWidthValue: replaceResizesWidth ? payload.resizesWidthToFitText as boolean :
          effectiveBoolean(state.baseResizesWidth, state.resizesWidth),
        imageCropValue: replaceImageCrop ? cloneOriginalRect(payload.cropRect.value) :
          cloneOriginalRect(effectiveNullable(state.baseImageCrop, state.imageCrop)),
        imageFlipHorizontalValue: replaceImageFlipHorizontal ?
          payload.imageFlippedHorizontally as boolean : effectiveBoolean(
            state.baseImageFlipHorizontal, state.imageFlipHorizontal),
        imageFlipVerticalValue: replaceImageFlipVertical ?
          payload.imageFlippedVertically as boolean : effectiveBoolean(
            state.baseImageFlipVertical, state.imageFlipVertical),
        mathLatexValue: replaceMathLatex ? payload.mathLatex.value :
          effectiveNullable(state.baseMathLatex, state.mathLatex),
        mathColorValue: replaceMathColor ? payload.mathColor.value :
          effectiveNullable(state.baseMathColor, state.mathColor),
        positionLockedValue: replacePositionLocked ? payload.positionLocked as boolean :
          effectiveBoolean(state.basePositionLocked, state.positionLocked),
        zIndexValue: zIndexValue,
        replacePageOrigin: replacePageOrigin, replaceRotation: replaceRotation,
        replaceScale: replaceScale, replaceSize: replaceSize, replaceCorner: replaceCorner,
        replaceTextWrap: replaceTextWrap, replaceEnableCaption: replaceEnableCaption,
        replacePaper: replacePaper, replaceResizesWidth: replaceResizesWidth,
        replaceImageCrop: replaceImageCrop,
        replaceImageFlipHorizontal: replaceImageFlipHorizontal,
        replaceImageFlipVertical: replaceImageFlipVertical,
        replaceMathLatex: replaceMathLatex, replaceMathColor: replaceMathColor,
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
    const affected: Map<string, AffectedPage> = new Map<string, AffectedPage>();
    for (const replacement of planned) {
      if (!replacement.target.hidden) {
        mergeAffectedPage(affected, replacement.target,
          replacement.target.kind === PageElementKind.TEXT);
        mergeAffectedPage(affected, replacement.destination,
          replacement.target.kind === PageElementKind.TEXT);
      }
      await this.updateState(store, operation.noteId, replacement, operation);
      if (replacement.target.hidden) {
        await this.updateHiddenBlockElement(store, operation.noteId, replacement);
      } else if (samePageIdentity(replacement.target.page, replacement.destination.page)) {
        if (replacement.replaceZIndex) {
          await this.updateTrackedElement(store, operation.noteId, replacement, false);
        }
        await this.updateBlockElement(store, operation.noteId, replacement);
      } else {
        await this.moveBlockElement(store, operation.noteId, replacement, mutations);
      }
    }
    for (const mutation of mutations.values()) {
      await this.materializeOrder(store, operation.noteId, mutation);
    }
    for (const page of affected.values()) {
      if (revisionBatch === null) {
        await this.advanceRevisionAndInvalidateSearch(
          store, operation.noteId, page.target, page.textChanged);
      } else {
        revisionBatch.recordBlock(page.target, page.textChanged);
      }
    }
    return { deferredReason: null };
  }

  private async readTarget(store: relationalStore.RdbStore, noteId: string,
    block: OperationIdentity): Promise<StoredBlockTarget | null> {
    const rows = await store.querySql(
      `SELECT element.kind, element.page_timestamp, element.page_site_id, element.page_index,
              identity.page_id, identity.visible, element.z_index, state.block_type,
              element.visible AS element_visible
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
    let targetKind: PageElementKind;
    let targetBlockType: OriginalBlockType;
    let hidden: boolean;
    try {
      if (!rows.goToFirstRow() ||
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
      const kind: number = rows.getLong(rows.getColumnIndex('kind'));
      const blockType: number = rows.getLong(rows.getColumnIndex('block_type'));
      if ((blockType === OriginalBlockType.TEXT && kind !== PageElementKind.TEXT) ||
        (blockType === OriginalBlockType.IMAGE && kind !== PageElementKind.IMAGE) ||
        (blockType === OriginalBlockType.MATH && kind !== PageElementKind.MATH) ||
        (blockType !== OriginalBlockType.TEXT && blockType !== OriginalBlockType.IMAGE &&
          blockType !== OriginalBlockType.MATH)) {
        return null;
      }
      targetKind = kind as PageElementKind;
      targetBlockType = blockType as OriginalBlockType;
      hidden = rows.getLong(rows.getColumnIndex('element_visible')) === 0;
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
      archived: target.archived, zIndex: zIndex, kind: targetKind, blockType: targetBlockType,
      hidden: hidden,
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
      const basePaper: PagePaperBackground | null = parseStoredPaper(
        readNullableString(rows, 'create_text_paper'));
      const paperWinner: OperationIdentity | null = readOptionalWinner(rows, 'text_paper');
      const paperValue: PagePaperBackground | null = paperWinner === null ? null :
        parseStoredPaper(readNullableString(rows, 'text_paper_value'));
      const baseResizesWidth: number = rows.getLong(rows.getColumnIndex('create_resizes_width'));
      const baseImageCrop: OriginalBlockRect | null = readNullableOriginalRect(rows,
        'create_image_crop_x', 'create_image_crop_y',
        'create_image_crop_width', 'create_image_crop_height');
      const imageCropWinner: OperationIdentity | null = readOptionalWinner(rows, 'image_crop');
      const imageCropValue: OriginalBlockRect | null = imageCropWinner === null ? null :
        readNullableOriginalRect(rows, 'image_crop_x_value', 'image_crop_y_value',
          'image_crop_width_value', 'image_crop_height_value');
      const baseImageFlipHorizontal: number | null = readNullableLong(
        rows, 'create_image_flipped_horizontally');
      const baseImageFlipVertical: number | null = readNullableLong(
        rows, 'create_image_flipped_vertically');
      const baseImageHashBits: string[] | null = parseStoredHashBits(
        readNullableString(rows, 'create_image_hash_bits'));
      const baseImageFileName: string | null = readNullableString(rows, 'create_image_file_name');
      const baseImageMimeType: string | null = readNullableString(rows, 'create_image_mime_type');
      const baseImageFileSize: number | null = readNullableLong(rows, 'create_image_file_size');
      const baseImageWidth: number | null = readNullableDouble(rows, 'create_image_width');
      const baseImageHeight: number | null = readNullableDouble(rows, 'create_image_height');
      const baseImageWebUrl: string | null = readNullableString(rows, 'create_image_web_url');
      const baseMathLatex: string | null = readNullableString(rows, 'create_math_latex');
      const mathLatexWinner: OperationIdentity | null = readOptionalWinner(rows, 'math_latex');
      const mathLatexValue: string | null = mathLatexWinner === null ? null :
        readNullableString(rows, 'math_latex_value');
      const baseMathColor: number | null = readNullableLong(rows, 'create_math_color');
      const mathColorWinner: OperationIdentity | null = readOptionalWinner(rows, 'math_color');
      const mathColorValue: number | null = mathColorWinner === null ? null :
        readNullableLong(rows, 'math_color_value');
      const basePositionLocked: number = rows.getLong(rows.getColumnIndex('create_position_locked'));
      const baseLeftInset: number = rows.getDouble(rows.getColumnIndex('create_margin_left'));
      const baseTopInset: number = rows.getDouble(rows.getColumnIndex('create_margin_top'));
      if (![baseOriginX, baseOriginY, baseWidth, baseHeight, baseLeftInset, baseTopInset]
        .every((value: number) => Number.isFinite(value)) || baseWidth < 0 || baseHeight < 0 ||
        baseLeftInset < 0 || baseTopInset < 0 || baseCorner < 0 || baseCorner > 1 ||
        baseTextWrap < 0 || baseTextWrap > 1 ||
        (baseEnableCaption !== 0 && baseEnableCaption !== 1) ||
        (baseResizesWidth !== 0 && baseResizesWidth !== 1) ||
        (baseImageFlipHorizontal !== null && baseImageFlipHorizontal !== 0 &&
          baseImageFlipHorizontal !== 1) ||
        (baseImageFlipVertical !== null && baseImageFlipVertical !== 0 &&
          baseImageFlipVertical !== 1) ||
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
        basePaper: basePaper, paper: { value: paperValue, winner: paperWinner },
        baseResizesWidth: baseResizesWidth !== 0,
        resizesWidth: readBooleanRegister(rows, 'resizes_width'),
        baseImageCrop: baseImageCrop,
        imageCrop: { value: imageCropValue, winner: imageCropWinner },
        baseImageFlipHorizontal: baseImageFlipHorizontal === 1,
        imageFlipHorizontal: readBooleanRegister(rows, 'image_flip_horizontal'),
        baseImageFlipVertical: baseImageFlipVertical === 1,
        imageFlipVertical: readBooleanRegister(rows, 'image_flip_vertical'),
        baseImageHashBits: baseImageHashBits,
        baseImageFileName: baseImageFileName,
        baseImageMimeType: baseImageMimeType,
        baseImageFileSize: baseImageFileSize,
        baseImageWidth: baseImageWidth,
        baseImageHeight: baseImageHeight,
        baseImageWebUrl: baseImageWebUrl,
        baseMathLatex: baseMathLatex,
        mathLatex: { value: mathLatexValue, winner: mathLatexWinner },
        baseMathColor: baseMathColor,
        mathColor: { value: mathColorValue, winner: mathColorWinner },
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

  private async readBlockElement(store: relationalStore.RdbStore, noteId: string,
    target: StoredBlockTarget): Promise<ModifiableBlockElement | null> {
    const id: string = encodeOperationId(target.block);
    const rows = target.hidden ? await store.querySql(
      `SELECT payload FROM original_deleted_entity WHERE note_id = ?
       AND entity_timestamp = ? AND entity_site_id = ?
       AND page_timestamp = ? AND page_site_id = ? AND page_index = ?
       AND element_id = ? AND kind = ?`,
      [noteId, target.block.timestamp, target.block.siteId,
        target.page.timestamp, target.page.siteId, target.page.index, id, target.kind]) :
      target.archived ? await store.querySql(
      `SELECT payload FROM original_deleted_page_element WHERE note_id = ?
       AND page_timestamp = ? AND page_site_id = ? AND page_index = ?
       AND element_id = ? AND kind = ?`,
      [noteId, target.page.timestamp, target.page.siteId, target.page.index,
        id, target.kind]) : await store.querySql(
      `SELECT payload FROM page_element_snapshot WHERE note_id = ? AND page_id = ?
        AND element_id = ? AND kind = ?`, [noteId, target.pageId, id, target.kind]);
    try {
      if (!rows.goToFirstRow()) {
        return null;
      }
      const persisted: PersistedElement = decodePersistedElement(
        rows.getBlob(rows.getColumnIndex('payload')));
      if (target.kind === PageElementKind.TEXT && persisted.kind === 'text') {
        return persisted.data as TextBlockElement;
      }
      if (target.kind === PageElementKind.IMAGE && persisted.kind === 'image') {
        return persisted.data as ImageElement;
      }
      return target.kind === PageElementKind.MATH && persisted.kind === 'math' ?
        persisted.data as MathElement : null;
    } catch (_error) {
      return null;
    } finally {
      rows.close();
    }
  }

  private currentStateMatches(target: StoredBlockTarget, state: StoredBlockState,
    element: ModifiableBlockElement): boolean {
    const pageOrigin: OriginalBlockPageOrigin = effectivePageOrigin(state);
    const rotation: number | null = effectiveNullable(state.baseRotation, state.rotation);
    const scaleValue: OriginalBlockScale | null = effectiveNullable(state.baseScale, state.scale);
    const scale: OriginalBlockScale = scaleValue === null ? { x: 1, y: 1 } : scaleValue;
    const size: OriginalBlockScale = effectiveSize(state);
    const expectedTransform: TransformMatrix = blockTransform(
      pageOrigin.originX, pageOrigin.originY, rotation === null ? 0 : rotation, scale.x, scale.y);
    const commonMatches: boolean = samePageIdentity(target.page, pageOrigin.page) &&
      target.zIndex === effectiveZIndex(state) &&
      transformMatricesNear(element.transform, expectedTransform) &&
      element.blockWidth === size.x && element.blockHeight === size.y &&
      numbersNear(element.rotationRadians, rotation === null ? 0 : rotation) &&
      (element.corner === undefined ? 0 : element.corner) ===
        effectiveNumber(state.baseCorner, state.corner) &&
      (element.textWrap === undefined ? 0 : element.textWrap) ===
        effectiveNumber(state.baseTextWrap, state.textWrap) &&
      (element.enableCaption === true) ===
        effectiveBoolean(state.baseEnableCaption, state.enableCaption) &&
      (element.positionLocked === true) ===
        effectiveBoolean(state.basePositionLocked, state.positionLocked) &&
      element.id === encodeOperationId(target.block);
    if (!commonMatches) {
      return false;
    }
    if (target.kind === PageElementKind.TEXT) {
      const text: TextBlockElement = element as TextBlockElement;
      const expectedText: TextBlockElement = cloneText(text);
      expectedText.transform = expectedTransform;
      expectedText.blockWidth = size.x;
      expectedText.blockHeight = size.y;
      expectedText.paper = cloneOriginalPaper(effectiveNullable(state.basePaper, state.paper));
      expectedText.resizesWidthToFitText = effectiveBoolean(
        state.baseResizesWidth, state.resizesWidth);
      return rectsNear(text.bounds, textBlockWorldBounds(expectedText)) &&
        text.textOrigin.x === 0 && text.textOrigin.y === 0 &&
        text.contentLeftInset === state.baseLeftInset && text.contentTopInset === state.baseTopInset &&
        JSON.stringify(text.paper ?? null) === JSON.stringify(expectedText.paper ?? null) &&
        (text.resizesWidthToFitText === true) === (expectedText.resizesWidthToFitText === true);
    }
    if (target.kind === PageElementKind.MATH) {
      const math: MathElement = element as MathElement;
      const expectedMath: MathElement = cloneMathElement(math);
      expectedMath.transform = expectedTransform;
      expectedMath.blockWidth = size.x;
      expectedMath.blockHeight = size.y;
      const latex: string | null = effectiveNullable(state.baseMathLatex, state.mathLatex);
      const color: number | null = effectiveNullable(state.baseMathColor, state.mathColor);
      expectedMath.latex = latex === null ? '' : latex;
      expectedMath.color = color === null ? DEFAULT_MATH_COLOR : color;
      return math.latex === expectedMath.latex && math.color === expectedMath.color &&
        rectsNear(math.bounds, mathBlockWorldBounds(expectedMath));
    }
    const image: ImageElement = element as ImageElement;
    const expectedImage: ImageElement = cloneImageElement(image);
    expectedImage.transform = expectedTransform;
    expectedImage.blockWidth = size.x;
    expectedImage.blockHeight = size.y;
    expectedImage.cropRect = originalRectToRect(effectiveNullable(
      state.baseImageCrop, state.imageCrop));
    expectedImage.imageFlippedHorizontally = effectiveBoolean(
      state.baseImageFlipHorizontal, state.imageFlipHorizontal);
    expectedImage.imageFlippedVertically = effectiveBoolean(
      state.baseImageFlipVertical, state.imageFlipVertical);
    return rectsNear(image.bounds, imageBlockWorldBounds(expectedImage)) &&
      state.baseImageHashBits !== null &&
      image.assetHash === originalAssetHashKey(state.baseImageHashBits) &&
      JSON.stringify(image.assetHashBits) === JSON.stringify(state.baseImageHashBits) &&
      image.fileName === state.baseImageFileName && image.mimeType === state.baseImageMimeType &&
      image.fileSize === state.baseImageFileSize && image.intrinsicWidth === state.baseImageWidth &&
      image.intrinsicHeight === state.baseImageHeight && image.webUrl === state.baseImageWebUrl &&
      JSON.stringify(image.cropRect) === JSON.stringify(expectedImage.cropRect) &&
      image.imageFlippedHorizontally === expectedImage.imageFlippedHorizontally &&
      image.imageFlippedVertically === expectedImage.imageFlippedVertically;
  }

  private async preparePageMutations(store: relationalStore.RdbStore, noteId: string,
    planned: PlannedBlockReplacement[]): Promise<Map<string, PageMutation> | null> {
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
      const id: string = replacement.element.id;
      const sourceIndex: number = source.rows.findIndex((row: StoredZIndexRow) =>
        row.elementId === id && row.kind === replacement.target.kind);
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
        continue;
      }
      const destination: PageMutation | null = await this.loadPageMutation(
        store, noteId, replacement.destination, mutations);
      if (destination === null || destination.rows.some((row: StoredZIndexRow) =>
        row.elementId === id && row.kind === replacement.target.kind)) {
        return null;
      }
      source.rows.splice(sourceIndex, 1);
      destination.rows.push(moved);
    }
    for (const mutation of mutations.values()) {
      if (!await sortStoredZIndexRows(store, noteId, mutation.rows)) {
        return null;
      }
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
       AND page_site_id = ? AND page_index = ? AND visible = 1`,
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
    if (replacement.replacePaper) {
      addWinnerPredicates(predicates, 'text_paper', replacement.state.paper.winner);
      values['text_paper_value'] = replacement.paperValue === null ? null :
        JSON.stringify(replacement.paperValue);
      addWinnerValues(values, 'text_paper', winner);
    }
    if (replacement.replaceResizesWidth) {
      addWinnerPredicates(predicates, 'resizes_width', replacement.state.resizesWidth.winner);
      values['resizes_width_value'] = replacement.resizesWidthValue ? 1 : 0;
      addWinnerValues(values, 'resizes_width', winner);
    }
    if (replacement.replaceImageCrop) {
      addWinnerPredicates(predicates, 'image_crop', replacement.state.imageCrop.winner);
      values['image_crop_x_value'] = replacement.imageCropValue === null ? null :
        replacement.imageCropValue.x;
      values['image_crop_y_value'] = replacement.imageCropValue === null ? null :
        replacement.imageCropValue.y;
      values['image_crop_width_value'] = replacement.imageCropValue === null ? null :
        replacement.imageCropValue.width;
      values['image_crop_height_value'] = replacement.imageCropValue === null ? null :
        replacement.imageCropValue.height;
      addWinnerValues(values, 'image_crop', winner);
    }
    if (replacement.replaceImageFlipHorizontal) {
      addWinnerPredicates(predicates, 'image_flip_horizontal',
        replacement.state.imageFlipHorizontal.winner);
      values['image_flip_horizontal_value'] = replacement.imageFlipHorizontalValue ? 1 : 0;
      addWinnerValues(values, 'image_flip_horizontal', winner);
    }
    if (replacement.replaceImageFlipVertical) {
      addWinnerPredicates(predicates, 'image_flip_vertical',
        replacement.state.imageFlipVertical.winner);
      values['image_flip_vertical_value'] = replacement.imageFlipVerticalValue ? 1 : 0;
      addWinnerValues(values, 'image_flip_vertical', winner);
    }
    if (replacement.replaceMathLatex) {
      addWinnerPredicates(predicates, 'math_latex', replacement.state.mathLatex.winner);
      values['math_latex_value'] = replacement.mathLatexValue;
      addWinnerValues(values, 'math_latex', winner);
    }
    if (replacement.replaceMathColor) {
      addWinnerPredicates(predicates, 'math_color', replacement.state.mathColor.winner);
      values['math_color_value'] = replacement.mathColorValue;
      addWinnerValues(values, 'math_color', winner);
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
    predicates.equalTo('kind', target.kind);
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

  private async updateBlockElement(store: relationalStore.RdbStore, noteId: string,
    replacement: PlannedBlockReplacement): Promise<void> {
    const predicates = pageElementPredicates(noteId, replacement.target,
      replacement.element.id, replacement.target.kind);
    const persisted: PersistedElement = persistedBlockElement(
      replacement.target.kind, replacement.updatedElement);
    const updated: number = await store.update({
      'payload': encodePersistedElement(persisted), 'revision': replacement.target.revision + 1,
    }, predicates);
    if (updated !== 1) {
      throw new Error('original modify-block lost its target element');
    }
  }

  private async updateHiddenBlockElement(store: relationalStore.RdbStore, noteId: string,
    replacement: PlannedBlockReplacement): Promise<void> {
    const source: StoredBlockTarget = replacement.target;
    const persisted: PersistedElement = persistedBlockElement(
      source.kind, replacement.updatedElement);
    const archive = new relationalStore.RdbPredicates('original_deleted_entity');
    archive.equalTo('note_id', noteId);
    archive.equalTo('entity_timestamp', source.block.timestamp);
    archive.equalTo('entity_site_id', source.block.siteId);
    archive.equalTo('page_timestamp', source.page.timestamp);
    archive.equalTo('page_site_id', source.page.siteId);
    archive.equalTo('page_index', source.page.index);
    archive.equalTo('element_id', replacement.element.id);
    archive.equalTo('kind', source.kind);
    const updatedArchive: number = await store.update({
      'page_timestamp': replacement.destination.page.timestamp,
      'page_site_id': replacement.destination.page.siteId,
      'page_index': replacement.destination.page.index,
      'payload': encodePersistedElement(persisted),
    }, archive);
    if (updatedArchive !== 1) {
      throw new Error('original modify-block lost its hidden element');
    }
    const tracked = new relationalStore.RdbPredicates('original_element_z_index');
    tracked.equalTo('note_id', noteId);
    tracked.equalTo('element_timestamp', source.block.timestamp);
    tracked.equalTo('element_site_id', source.block.siteId);
    tracked.equalTo('page_timestamp', source.page.timestamp);
    tracked.equalTo('page_site_id', source.page.siteId);
    tracked.equalTo('page_index', source.page.index);
    tracked.equalTo('kind', source.kind);
    tracked.equalTo('visible', 0);
    tracked.equalTo('z_index', source.zIndex);
    const updatedTracked: number = await store.update({
      'page_timestamp': replacement.destination.page.timestamp,
      'page_site_id': replacement.destination.page.siteId,
      'page_index': replacement.destination.page.index,
      'z_index': replacement.zIndexValue,
    }, tracked);
    if (updatedTracked !== 1) {
      throw new Error('original modify-block lost its hidden tracked state');
    }
  }

  private async moveBlockElement(store: relationalStore.RdbStore, noteId: string,
    replacement: PlannedBlockReplacement, mutations: Map<string, PageMutation>): Promise<void> {
    const deleted: number = await store.delete(pageElementPredicates(
      noteId, replacement.target, replacement.element.id, replacement.target.kind));
    if (deleted !== 1) {
      throw new Error('original modify-block lost its source element');
    }
    const mutation: PageMutation | undefined = mutations.get(pageKey(replacement.destination));
    if (mutation === undefined) {
      throw new Error('original modify-block has no destination order');
    }
    const order: number = mutation.rows.findIndex((row: StoredZIndexRow) =>
      row.elementId === replacement.element.id && row.kind === replacement.target.kind);
    if (order < 0) {
      throw new Error('original modify-block destination lost its element');
    }
    const persisted: PersistedElement = persistedBlockElement(
      replacement.target.kind, replacement.updatedElement);
    const values: relationalStore.ValuesBucket = {
      'note_id': noteId, 'element_id': replacement.element.id, 'kind': replacement.target.kind,
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
    noteId: string, target: StoredPageTarget, textChanged: boolean): Promise<void> {
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
    if (target.archived && textChanged) {
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
    } else if (!target.archived) {
      await store.executeSql('DELETE FROM search_page_state WHERE note_id = ? AND page_id = ?',
        [noteId, target.pageId]);
      if (textChanged) {
        await store.executeSql(
          'DELETE FROM search_item WHERE note_id = ? AND page_id = ? AND type = ?',
          [noteId, target.pageId, SearchItemType.TEXT_BLOCK]);
      }
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

function mergeAffectedPage(affected: Map<string, AffectedPage>, target: StoredPageTarget,
  textChanged: boolean): void {
  const key: string = pageKey(target);
  const current: AffectedPage | undefined = affected.get(key);
  affected.set(key, {
    target: target,
    textChanged: textChanged || (current !== undefined && current.textChanged),
  });
}

function persistedBlockElement(kind: PageElementKind,
  element: ModifiableBlockElement): PersistedElement {
  return kind === PageElementKind.TEXT ?
    { kind: 'text', data: element as TextBlockElement } : kind === PageElementKind.IMAGE ?
      { kind: 'image', data: element as ImageElement } :
      { kind: 'math', data: element as MathElement };
}

function rgbaBytesToArgb(bytes: Uint8Array): number {
  return ((bytes[3] << 24) | (bytes[0] << 16) | (bytes[1] << 8) | bytes[2]) | 0;
}

function cloneOriginalRect(rect: OriginalBlockRect | null): OriginalBlockRect | null {
  return rect === null ? null : {
    x: rect.x, y: rect.y, width: rect.width, height: rect.height,
  };
}

function originalRectToRect(rect: OriginalBlockRect | null): Rect2D | null {
  return rect === null ? null : {
    left: rect.x, top: rect.y, right: rect.x + rect.width, bottom: rect.y + rect.height,
  };
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

function readNullableOriginalRect(rows: relationalStore.ResultSet, xColumn: string,
  yColumn: string, widthColumn: string, heightColumn: string): OriginalBlockRect | null {
  const x: number | null = readNullableDouble(rows, xColumn);
  const y: number | null = readNullableDouble(rows, yColumn);
  const width: number | null = readNullableDouble(rows, widthColumn);
  const height: number | null = readNullableDouble(rows, heightColumn);
  const count: number = [x, y, width, height]
    .filter((value: number | null) => value !== null).length;
  if (count === 0) {
    return null;
  }
  if (count !== 4 || (width as number) < 0 || (height as number) < 0) {
    throw new Error('original modify-block has a partial or invalid crop rect');
  }
  return { x: x as number, y: y as number, width: width as number, height: height as number };
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

function parseStoredPaper(encoded: string | null): PagePaperBackground | null {
  if (encoded === null) {
    return null;
  }
  const paper: PagePaperBackground = JSON.parse(encoded) as PagePaperBackground;
  validateOriginalPaper(paper);
  return cloneOriginalPaper(paper);
}

function parseStoredHashBits(encoded: string | null): string[] | null {
  if (encoded === null) {
    return null;
  }
  const parsed: Object = JSON.parse(encoded) as Object;
  if (!Array.isArray(parsed) || parsed.length !== 8) {
    throw new Error('original modify-block has invalid image hash bits');
  }
  const bits: string[] = parsed as string[];
  for (const bit of bits) {
    validateUnsignedLongDecimal(bit);
  }
  return bits.slice();
}

function requireValue<T>(value: T | null, label: string): T {
  if (value === null) {
    throw new Error(`original modify-block is missing ${label}`);
  }
  return value;
}

function preflightOriginalModifyBlock(payload: OriginalModifyBlockPayload): string | null {
  if ((payload.pageOrigin !== null && (!Number.isFinite(payload.pageOrigin.originX) ||
    !Number.isFinite(payload.pageOrigin.originY))) ||
    (payload.rotation.value !== null && !Number.isFinite(payload.rotation.value)) ||
    (payload.scale.value !== null && (!Number.isFinite(payload.scale.value.x) ||
      !Number.isFinite(payload.scale.value.y))) ||
    (payload.width !== null && (!Number.isFinite(payload.width) || payload.width < 0)) ||
    (payload.height !== null && (!Number.isFinite(payload.height) || payload.height < 0))) {
    return 'MODIFY_BLOCK_GEOMETRY_UNSUPPORTED';
  }
  if (payload.cropRect.value !== null && (!Number.isFinite(payload.cropRect.value.x) ||
    !Number.isFinite(payload.cropRect.value.y) ||
    !Number.isFinite(payload.cropRect.value.width) ||
    !Number.isFinite(payload.cropRect.value.height) || payload.cropRect.value.width < 0 ||
    payload.cropRect.value.height < 0)) {
    return 'MODIFY_BLOCK_GEOMETRY_UNSUPPORTED';
  }
  const mathFields: boolean = payload.mathLatex.present || payload.mathColor.present;
  const imageFields: boolean = payload.cropRect.present ||
    payload.imageFlippedHorizontally !== null || payload.imageFlippedVertically !== null;
  const textFields: boolean = payload.paper.present || payload.resizesWidthToFitText !== null;
  if ([mathFields, imageFields, textFields].filter((present: boolean) => present).length > 1) {
    return 'MODIFY_BLOCK_MIXED_TYPE_SPECIFIC_FIELDS';
  }
  return null;
}

function assertMatchingModifyBlockWinners(payload: OriginalModifyBlockPayload,
  state: StoredBlockState, operation: OperationIdentity): void {
  if (payload.pageOrigin !== null && winnerMatches(state.pageOrigin.winner, operation) &&
    !sameNullableBlockPageOrigin(state.pageOrigin.value, payload.pageOrigin)) {
    throw new Error('original modify-block identity conflicts with persisted page/origin');
  }
  if (payload.rotation.present && winnerMatches(state.rotation.winner, operation) &&
    state.rotation.value !== payload.rotation.value) {
    throw new Error('original modify-block identity conflicts with persisted rotation');
  }
  if (payload.scale.present && winnerMatches(state.scale.winner, operation) &&
    !sameNullableBlockScale(state.scale.value, payload.scale.value)) {
    throw new Error('original modify-block identity conflicts with persisted scale');
  }
  if (payload.width !== null && winnerMatches(state.size.winner, operation) &&
    !sameNullableBlockScale(state.size.value,
      { x: payload.width, y: payload.height as number })) {
    throw new Error('original modify-block identity conflicts with persisted size');
  }
  if (payload.corner !== null && winnerMatches(state.corner.winner, operation) &&
    state.corner.value !== payload.corner) {
    throw new Error('original modify-block identity conflicts with persisted corner');
  }
  if (payload.textWrap !== null && winnerMatches(state.textWrap.winner, operation) &&
    state.textWrap.value !== payload.textWrap) {
    throw new Error('original modify-block identity conflicts with persisted text wrap');
  }
  if (payload.enableCaption !== null && winnerMatches(state.enableCaption.winner, operation) &&
    state.enableCaption.value !== payload.enableCaption) {
    throw new Error('original modify-block identity conflicts with persisted caption');
  }
  if (payload.paper.present && winnerMatches(state.paper.winner, operation) &&
    !sameNullablePaper(state.paper.value, payload.paper.value)) {
    throw new Error('original modify-block identity conflicts with persisted paper');
  }
  if (payload.resizesWidthToFitText !== null &&
    winnerMatches(state.resizesWidth.winner, operation) &&
    state.resizesWidth.value !== payload.resizesWidthToFitText) {
    throw new Error('original modify-block identity conflicts with persisted resize behavior');
  }
  if (payload.cropRect.present && winnerMatches(state.imageCrop.winner, operation) &&
    !sameNullableOriginalRect(state.imageCrop.value, payload.cropRect.value)) {
    throw new Error('original modify-block identity conflicts with persisted image crop');
  }
  if (payload.imageFlippedHorizontally !== null &&
    winnerMatches(state.imageFlipHorizontal.winner, operation) &&
    state.imageFlipHorizontal.value !== payload.imageFlippedHorizontally) {
    throw new Error('original modify-block identity conflicts with persisted horizontal flip');
  }
  if (payload.imageFlippedVertically !== null &&
    winnerMatches(state.imageFlipVertical.winner, operation) &&
    state.imageFlipVertical.value !== payload.imageFlippedVertically) {
    throw new Error('original modify-block identity conflicts with persisted vertical flip');
  }
  if (payload.mathLatex.present && winnerMatches(state.mathLatex.winner, operation) &&
    state.mathLatex.value !== payload.mathLatex.value) {
    throw new Error('original modify-block identity conflicts with persisted math latex');
  }
  if (payload.mathColor.present && winnerMatches(state.mathColor.winner, operation) &&
    state.mathColor.value !== payload.mathColor.value) {
    throw new Error('original modify-block identity conflicts with persisted math color');
  }
  if (payload.positionLocked !== null &&
    winnerMatches(state.positionLocked.winner, operation) &&
    state.positionLocked.value !== payload.positionLocked) {
    throw new Error('original modify-block identity conflicts with persisted position lock');
  }
  if (payload.zIndex !== null && winnerMatches(state.zIndex.winner, operation) &&
    state.zIndex.value !== payload.zIndex) {
    throw new Error('original modify-block identity conflicts with persisted z-index');
  }
}

function winnerMatches(winner: OperationIdentity | null,
  operation: OperationIdentity): boolean {
  return winner !== null && compareOperationIdentity(winner, operation) === 0;
}

function sameNullableBlockScale(left: OriginalBlockScale | null,
  right: OriginalBlockScale | null): boolean {
  return left === null || right === null ? left === right : left.x === right.x && left.y === right.y;
}

function sameNullableBlockPageOrigin(left: OriginalBlockPageOrigin | null,
  right: OriginalBlockPageOrigin | null): boolean {
  return left === null || right === null ? left === right :
    samePageIdentity(left.page, right.page) && left.originX === right.originX &&
      left.originY === right.originY;
}

function sameNullableOriginalRect(left: OriginalBlockRect | null,
  right: OriginalBlockRect | null): boolean {
  return left === null || right === null ? left === right :
    left.x === right.x && left.y === right.y && left.width === right.width &&
      left.height === right.height;
}

function sameNullablePaper(left: PagePaperBackground | null,
  right: PagePaperBackground | null): boolean {
  return left === null || right === null ? left === right :
    JSON.stringify(left) === JSON.stringify(right);
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

function transformMatricesNear(left: TransformMatrix, right: TransformMatrix): boolean {
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

function rectsNear(left: Rect2D, right: Rect2D): boolean {
  return numbersNear(left.left, right.left) && numbersNear(left.top, right.top) &&
    numbersNear(left.right, right.right) && numbersNear(left.bottom, right.bottom);
}

function numbersNear(left: number, right: number): boolean {
  return Math.abs(left - right) <= 0.000001 * Math.max(1, Math.abs(left), Math.abs(right));
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
    characterStyleRuns: cloneCharacterStyleRuns(text.characterStyleRuns),
    paragraphStyleRuns: cloneParagraphStyleRuns(text.paragraphStyleRuns),
    corner: text.corner, textWrap: text.textWrap, enableCaption: text.enableCaption,
    paper: cloneOriginalPaper(text.paper === undefined ? null : text.paper),
    resizesWidthToFitText: text.resizesWidthToFitText,
    positionLocked: text.positionLocked === true,
  };
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

function samePageIdentity(left: OriginalSequenceIdentity,
  right: OriginalSequenceIdentity): boolean {
  return left.timestamp === right.timestamp && left.siteId === right.siteId &&
    left.index === right.index;
}

function pageKey(target: StoredPageTarget): string {
  return `${target.page.timestamp}:${target.page.siteId}:${target.page.index}`;
}

async function sortStoredZIndexRows(store: relationalStore.RdbStore, noteId: string,
  rows: StoredZIndexRow[]): Promise<boolean> {
  const entities: OriginalLayeringEntity[] = rows.map(
    (row: StoredZIndexRow): OriginalLayeringEntity => ({
      id: row.elementId, timestamp: row.timestamp, siteId: row.siteId, zIndex: row.zIndex,
    }));
  const ranks: Map<string, number> | null = await originalGroupLayerRanks(store, noteId, entities);
  if (ranks === null || ranks.size !== rows.length) {
    return false;
  }
  rows.sort((left: StoredZIndexRow, right: StoredZIndexRow): number =>
    (ranks.get(left.elementId) as number) - (ranks.get(right.elementId) as number));
  return true;
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
