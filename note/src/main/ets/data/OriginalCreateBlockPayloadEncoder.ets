import { util } from '@kit.ArkTS';
import { ImageElement, MathElement, TextBlockElement } from '../core/model/ElementTypes';
import { TransformMatrix } from '../core/model/GeometryTypes';
import { originalAssetHashKey, originalAssetStorageHash } from
  '../core/model/ImageBlockGeometry';
import { textBlockTransformComponents, TextBlockTransformComponents } from
  '../core/model/TextBlockGeometry';
import { OriginalSequenceIdentity, validateOriginalSequenceIdentity } from './OperationIdentity';
import { PagePaperBackground } from '../core/model/NoteTypes';
import { validateOriginalPaper } from '../core/model/PageBackgroundModel';

const DEFAULT_TEXT_COLOR: number = -16777216;
const DEFAULT_TEXT_SIZE: number = 17;
const EPSILON: number = 0.000001;
const MAX_UINT32: number = 0xFFFFFFFF;
const MAX_ASSET_FILE_NAME_BYTES: number = 65536;
const MAX_ASSET_MIME_TYPE_BYTES: number = 4096;
const MAX_BLOCK_WEB_URL_BYTES: number = 1048576;
const MAX_MATH_LATEX_BYTES: number = 1048576;

interface OriginalBlockPlacement {
  originX: number;
  originY: number;
  rotation: number;
  scaleX: number;
  scaleY: number;
}

export function encodeOriginalLocalCreateImageBlock(page: OriginalSequenceIdentity,
  image: ImageElement): Uint8Array {
  validateOriginalSequenceIdentity(page);
  const placement: OriginalBlockPlacement = blockPlacement(image.transform, image.rotationRadians);
  validateLocalImageBlock(image, placement);
  const encoder: util.TextEncoder = new util.TextEncoder();
  const fileName: Uint8Array = encoder.encodeInto(image.fileName);
  const mimeType: Uint8Array = encoder.encodeInto(image.mimeType);
  const webUrl: Uint8Array | null = image.webUrl === null ? null : encoder.encodeInto(image.webUrl);
  if (!validUtf8RoundTrip(fileName, image.fileName) || fileName.length === 0 ||
    fileName.length > MAX_ASSET_FILE_NAME_BYTES ||
    !validUtf8RoundTrip(mimeType, image.mimeType) || mimeType.length === 0 ||
    mimeType.length > MAX_ASSET_MIME_TYPE_BYTES ||
    (webUrl !== null && (!validUtf8RoundTrip(webUrl, image.webUrl as string) ||
      webUrl.length > MAX_BLOCK_WEB_URL_BYTES))) {
    throw new Error('local Image Block asset strings are invalid');
  }
  const hasRotation: boolean = Math.abs(placement.rotation) > EPSILON;
  const hasScale: boolean = Math.abs(placement.scaleX - 1) > EPSILON ||
    Math.abs(placement.scaleY - 1) > EPSILON;
  const rootTable: number = 52;
  const rootObjectSize: number = 80;
  const imageVtable: number = rootTable + rootObjectSize;
  const imageTable: number = imageVtable + 8;
  const metadataVtable: number = imageTable + 16;
  const metadataTable: number = metadataVtable + 12;
  const fileNameVector: number = metadataTable + 80;
  const mimeTypeVector: number = align4(fileNameVector + 4 + fileName.length + 1);
  const webUrlVector: number = align4(mimeTypeVector + 4 + mimeType.length + 1);
  const total: number = align4(webUrl === null ? webUrlVector :
    webUrlVector + 4 + webUrl.length + 1);
  const bytes: Uint8Array = new Uint8Array(total);
  const fields: number[] = new Array<number>(21).fill(0);
  fields[0] = 4;
  fields[1] = image.corner === 0 ? 0 : 5;
  fields[2] = 8;
  fields[3] = 20;
  fields[4] = hasRotation ? 28 : 0;
  fields[5] = hasScale ? 32 : 0;
  fields[6] = 40;
  fields[7] = image.textWrap === 0 ? 0 : 48;
  fields[8] = image.enableCaption ? 49 : 0;
  fields[10] = 52;
  fields[11] = image.cropRect === null ? 0 : 56;
  fields[12] = webUrl === null ? 0 : 72;
  fields[16] = image.imageFlippedHorizontally ? 76 : 0;
  fields[17] = image.imageFlippedVertically ? 77 : 0;
  fields[20] = image.positionLocked ? 78 : 0;

  writeU32(bytes, 0, rootTable);
  writeVtable(bytes, 4, rootObjectSize, fields);
  writeU32(bytes, rootTable, rootTable - 4);
  writeU8(bytes, rootTable + 4, 1);
  if (image.corner !== 0) {
    writeU8(bytes, rootTable + 5, image.corner);
  }
  writeSequence(bytes, rootTable + 8, page);
  writeF32(bytes, rootTable + 20, placement.originX);
  writeF32(bytes, rootTable + 24, placement.originY);
  if (hasRotation) {
    writeF32(bytes, rootTable + 28, placement.rotation);
  }
  if (hasScale) {
    writeF32(bytes, rootTable + 32, placement.scaleX);
    writeF32(bytes, rootTable + 36, placement.scaleY);
  }
  writeF32(bytes, rootTable + 40, image.blockWidth);
  writeF32(bytes, rootTable + 44, image.blockHeight);
  if (image.textWrap !== 0) {
    writeU8(bytes, rootTable + 48, image.textWrap);
  }
  if (image.enableCaption) {
    writeU8(bytes, rootTable + 49, 1);
  }
  writeU32(bytes, rootTable + 52, imageTable - (rootTable + 52));
  if (image.cropRect !== null) {
    writeF32(bytes, rootTable + 56, image.cropRect.left);
    writeF32(bytes, rootTable + 60, image.cropRect.top);
    writeF32(bytes, rootTable + 64, image.cropRect.right - image.cropRect.left);
    writeF32(bytes, rootTable + 68, image.cropRect.bottom - image.cropRect.top);
  }
  if (webUrl !== null) {
    writeU32(bytes, rootTable + 72, webUrlVector - (rootTable + 72));
  }
  if (image.imageFlippedHorizontally) {
    writeU8(bytes, rootTable + 76, 1);
  }
  if (image.imageFlippedVertically) {
    writeU8(bytes, rootTable + 77, 1);
  }
  if (image.positionLocked) {
    writeU8(bytes, rootTable + 78, 1);
  }

  writeVtable(bytes, imageVtable, 16, [4, 8]);
  writeU32(bytes, imageTable, imageTable - imageVtable);
  writeU32(bytes, imageTable + 4, metadataTable - (imageTable + 4));
  writeF32(bytes, imageTable + 8, image.intrinsicWidth);
  writeF32(bytes, imageTable + 12, image.intrinsicHeight);

  writeVtable(bytes, metadataVtable, 80, [4, 68, 72, 76]);
  writeU32(bytes, metadataTable, metadataTable - metadataVtable);
  writeHash(bytes, metadataTable + 4, image.assetHashBits);
  writeU32(bytes, metadataTable + 68, fileNameVector - (metadataTable + 68));
  writeU32(bytes, metadataTable + 72, mimeTypeVector - (metadataTable + 72));
  writeU32(bytes, metadataTable + 76, image.fileSize);
  writeString(bytes, fileNameVector, fileName);
  writeString(bytes, mimeTypeVector, mimeType);
  if (webUrl !== null) {
    writeString(bytes, webUrlVector, webUrl);
  }
  return bytes;
}

export function encodeOriginalLocalCreateTextBlock(page: OriginalSequenceIdentity,
  text: TextBlockElement): Uint8Array {
  validateOriginalSequenceIdentity(page);
  const placement: TextBlockTransformComponents = textBlockTransformComponents(text);
  validateLocalTextBlock(text, placement);
  const hasRotation: boolean = Math.abs(placement.rotationRadians) > EPSILON;
  const hasScale: boolean = Math.abs(placement.scaleX - 1) > EPSILON ||
    Math.abs(placement.scaleY - 1) > EPSILON;
  const paper: PagePaperBackground | null = text.paper === undefined ? null : text.paper;
  const table: number = 52;
  const objectSize: number = 72;
  const paperVtable: number = table + objectSize;
  const paperTable: number = paperVtable + 16;
  const bytes: Uint8Array = new Uint8Array(paper === null ? paperVtable : paperTable + 16);
  const fields: number[] = new Array<number>(21).fill(0);
  fields[1] = (text.corner ?? 0) === 0 ? 0 : 4;
  fields[2] = 8;
  fields[3] = 20;
  fields[4] = hasRotation ? 28 : 0;
  fields[5] = hasScale ? 32 : 0;
  fields[6] = 40;
  fields[7] = (text.textWrap ?? 0) === 0 ? 0 : 48;
  fields[8] = text.enableCaption === true ? 49 : 0;
  fields[15] = paper === null ? 0 : 52;
  fields[18] = text.resizesWidthToFitText === true ? 50 : 0;
  fields[19] = 56;
  fields[20] = text.positionLocked === true ? 51 : 0;

  writeU32(bytes, 0, table);
  writeVtable(bytes, 4, objectSize, fields);
  writeU32(bytes, table, table - 4);
  if ((text.corner ?? 0) !== 0) {
    writeU8(bytes, table + 4, text.corner as number);
  }
  writeSequence(bytes, table + 8, page);
  writeF32(bytes, table + 20, placement.origin.x);
  writeF32(bytes, table + 24, placement.origin.y);
  if (hasRotation) {
    writeF32(bytes, table + 28, placement.rotationRadians);
  }
  if (hasScale) {
    writeF32(bytes, table + 32, placement.scaleX);
    writeF32(bytes, table + 36, placement.scaleY);
  }
  writeF32(bytes, table + 40, text.blockWidth);
  writeF32(bytes, table + 44, text.blockHeight);
  if ((text.textWrap ?? 0) !== 0) {
    writeU8(bytes, table + 48, text.textWrap as number);
  }
  if (text.enableCaption === true) {
    writeU8(bytes, table + 49, 1);
  }
  if (text.resizesWidthToFitText === true) {
    writeU8(bytes, table + 50, 1);
  }
  if (text.positionLocked === true) {
    writeU8(bytes, table + 51, 1);
  }
  if (paper !== null) {
    writeU32(bytes, table + 52, paperTable - (table + 52));
  }
  writeF32(bytes, table + 56, text.contentTopInset);
  writeF32(bytes, table + 60, text.contentBottomInset ?? text.contentTopInset);
  writeF32(bytes, table + 64, text.contentLeftInset);
  writeF32(bytes, table + 68, text.contentRightInset ?? text.contentLeftInset);
  if (paper !== null) {
    writePaper(bytes, paperVtable, paperTable, paper);
  }
  return bytes;
}

export function encodeOriginalLocalCreateMathBlock(page: OriginalSequenceIdentity,
  math: MathElement): Uint8Array {
  validateOriginalSequenceIdentity(page);
  const placement: OriginalBlockPlacement = blockPlacement(math.transform, math.rotationRadians);
  validateLocalMathBlock(math, placement);
  const latex: Uint8Array = new util.TextEncoder().encodeInto(math.latex);
  if (latex.length > MAX_MATH_LATEX_BYTES ||
    util.TextDecoder.create('utf-8').decodeToString(latex) !== math.latex) {
    throw new Error('local Math Block latex is invalid');
  }
  const hasRotation: boolean = Math.abs(placement.rotation) > EPSILON;
  const hasScale: boolean = Math.abs(placement.scaleX - 1) > EPSILON ||
    Math.abs(placement.scaleY - 1) > EPSILON;
  const table: number = 52;
  const objectSize: number = 64;
  const latexVector: number = table + objectSize;
  const bytes: Uint8Array = new Uint8Array(
    align4(latexVector + 4 + latex.length + 1));
  const fields: number[] = new Array<number>(21).fill(0);
  fields[0] = 4;
  fields[1] = math.corner === 0 ? 0 : 5;
  fields[2] = 8;
  fields[3] = 20;
  fields[4] = hasRotation ? 28 : 0;
  fields[5] = hasScale ? 32 : 0;
  fields[6] = 40;
  fields[7] = math.textWrap === 0 ? 0 : 48;
  fields[8] = math.enableCaption ? 49 : 0;
  fields[13] = 52;
  fields[14] = 56;
  fields[20] = math.positionLocked ? 60 : 0;

  writeU32(bytes, 0, table);
  writeVtable(bytes, 4, objectSize, fields);
  writeU32(bytes, table, table - 4);
  writeU8(bytes, table + 4, 2);
  if (math.corner !== 0) {
    writeU8(bytes, table + 5, math.corner);
  }
  writeSequence(bytes, table + 8, page);
  writeF32(bytes, table + 20, placement.originX);
  writeF32(bytes, table + 24, placement.originY);
  if (hasRotation) {
    writeF32(bytes, table + 28, placement.rotation);
  }
  if (hasScale) {
    writeF32(bytes, table + 32, placement.scaleX);
    writeF32(bytes, table + 36, placement.scaleY);
  }
  writeF32(bytes, table + 40, math.blockWidth);
  writeF32(bytes, table + 44, math.blockHeight);
  if (math.textWrap !== 0) {
    writeU8(bytes, table + 48, math.textWrap);
  }
  if (math.enableCaption) {
    writeU8(bytes, table + 49, 1);
  }
  writeU32(bytes, table + 52, latexVector - (table + 52));
  writeColor(bytes, table + 56, math.color);
  if (math.positionLocked) {
    writeU8(bytes, table + 60, 1);
  }
  writeString(bytes, latexVector, latex);
  return bytes;
}

function blockPlacement(matrix: TransformMatrix, rotation: number): OriginalBlockPlacement {
  const scaleX: number = matrix.length === 9 ?
    Math.sqrt(matrix[0] * matrix[0] + matrix[3] * matrix[3]) : Number.NaN;
  const determinant: number = matrix.length === 9 ?
    matrix[0] * matrix[4] - matrix[1] * matrix[3] : Number.NaN;
  return {
    originX: matrix.length === 9 ? matrix[2] : Number.NaN,
    originY: matrix.length === 9 ? matrix[5] : Number.NaN,
    rotation: rotation,
    scaleX: scaleX,
    scaleY: scaleX > EPSILON ? determinant / scaleX : Number.NaN,
  };
}

function validateLocalImageBlock(image: ImageElement,
  placement: OriginalBlockPlacement): void {
  const cropValid: boolean = image.cropRect === null ||
    (Number.isFinite(image.cropRect.left) && Number.isFinite(image.cropRect.top) &&
      Number.isFinite(image.cropRect.right) && Number.isFinite(image.cropRect.bottom) &&
      image.cropRect.right >= image.cropRect.left &&
      image.cropRect.bottom >= image.cropRect.top);
  let hashValid: boolean = false;
  try {
    hashValid = image.assetHash === originalAssetHashKey(image.assetHashBits);
    originalAssetStorageHash(image.assetHashBits);
  } catch (_error) {
    hashValid = false;
  }
  if (!hashValid || !Number.isSafeInteger(image.fileSize) || image.fileSize <= 0 ||
    image.fileSize > MAX_UINT32 || !Number.isFinite(image.intrinsicWidth) ||
    image.intrinsicWidth < 0 || !Number.isFinite(image.intrinsicHeight) ||
    image.intrinsicHeight < 0 || !Number.isFinite(image.blockWidth) || image.blockWidth < 0 ||
    !Number.isFinite(image.blockHeight) || image.blockHeight < 0 || !cropValid ||
    !Number.isInteger(image.corner) || image.corner < 0 || image.corner > 1 ||
    !Number.isInteger(image.textWrap) || image.textWrap < 0 || image.textWrap > 1 ||
    typeof image.enableCaption !== 'boolean' || typeof image.imageFlippedHorizontally !== 'boolean' ||
    typeof image.imageFlippedVertically !== 'boolean' || typeof image.positionLocked !== 'boolean' ||
    (image.webUrl !== null && typeof image.webUrl !== 'string') ||
    !Number.isFinite(placement.originX) || !Number.isFinite(placement.originY) ||
    !Number.isFinite(placement.rotation) || !Number.isFinite(placement.scaleX) ||
    !Number.isFinite(placement.scaleY) || Math.abs(placement.scaleX) <= EPSILON ||
    Math.abs(placement.scaleY) <= EPSILON ||
    !isRepresentableBlockTransform(image.transform, placement)) {
    throw new Error('local Image Block cannot be represented by original CREATE_BLOCK');
  }
}

function validateLocalMathBlock(math: MathElement,
  placement: OriginalBlockPlacement): void {
  if (typeof math.latex !== 'string' || !validColor(math.color) ||
    !Number.isFinite(math.blockWidth) || math.blockWidth < 0 ||
    !Number.isFinite(math.blockHeight) || math.blockHeight < 0 ||
    !Number.isInteger(math.corner) || math.corner < 0 || math.corner > 1 ||
    !Number.isInteger(math.textWrap) || math.textWrap < 0 || math.textWrap > 1 ||
    typeof math.enableCaption !== 'boolean' || typeof math.positionLocked !== 'boolean' ||
    !Number.isFinite(placement.originX) || !Number.isFinite(placement.originY) ||
    !Number.isFinite(placement.rotation) || !Number.isFinite(placement.scaleX) ||
    !Number.isFinite(placement.scaleY) || Math.abs(placement.scaleX) <= EPSILON ||
    Math.abs(placement.scaleY) <= EPSILON ||
    !isRepresentableBlockTransform(math.transform, placement)) {
    throw new Error('local Math Block cannot be represented by original CREATE_BLOCK');
  }
}

function isRepresentableBlockTransform(matrix: TransformMatrix,
  placement: OriginalBlockPlacement): boolean {
  if (matrix.length !== 9 || Math.abs(matrix[6]) > EPSILON ||
    Math.abs(matrix[7]) > EPSILON || Math.abs(matrix[8] - 1) > EPSILON) {
    return false;
  }
  const cosine: number = Math.cos(placement.rotation);
  const sine: number = Math.sin(placement.rotation);
  const expected: number[] = [
    cosine * placement.scaleX, -sine * placement.scaleY, placement.originX,
    sine * placement.scaleX, cosine * placement.scaleY, placement.originY, 0, 0, 1,
  ];
  return matrix.every((value: number, index: number): boolean =>
    Number.isFinite(value) && Math.abs(value - expected[index]) <= EPSILON);
}

function validUtf8RoundTrip(bytes: Uint8Array, value: string): boolean {
  return util.TextDecoder.create('utf-8').decodeToString(bytes) === value;
}

function validateLocalTextBlock(text: TextBlockElement,
  placement: TextBlockTransformComponents): void {
  const paper: PagePaperBackground | null = text.paper === undefined ? null : text.paper;
  try {
    validateOriginalPaper(paper);
  } catch (_error) {
    throw new Error('local Text Block cannot be represented by original CREATE_BLOCK');
  }
  const bottomInset: number = text.contentBottomInset ?? text.contentTopInset;
  const rightInset: number = text.contentRightInset ?? text.contentLeftInset;
  if (!Number.isFinite(text.blockWidth) || text.blockWidth < 0 ||
    !Number.isFinite(text.blockHeight) || text.blockHeight < 0 ||
    !Number.isFinite(placement.origin.x) || !Number.isFinite(placement.origin.y) ||
    !Number.isFinite(placement.rotationRadians) || !Number.isFinite(placement.scaleX) ||
    !Number.isFinite(placement.scaleY) || Math.abs(placement.scaleX) <= EPSILON ||
    Math.abs(placement.scaleY) <= EPSILON || !Number.isFinite(text.contentLeftInset) ||
    text.contentLeftInset < 0 || !Number.isFinite(text.contentTopInset) ||
    text.contentTopInset < 0 || !Number.isFinite(rightInset) || rightInset < 0 ||
    !Number.isFinite(bottomInset) || bottomInset < 0 || text.fontSize !== DEFAULT_TEXT_SIZE ||
    text.fontColor !== DEFAULT_TEXT_COLOR || !Number.isInteger(text.corner ?? 0) ||
    (text.corner ?? 0) < 0 || (text.corner ?? 0) > 1 ||
    !Number.isInteger(text.textWrap ?? 0) || (text.textWrap ?? 0) < 0 ||
    (text.textWrap ?? 0) > 1 ||
    (text.enableCaption !== undefined && typeof text.enableCaption !== 'boolean') ||
    (text.resizesWidthToFitText !== undefined &&
      typeof text.resizesWidthToFitText !== 'boolean') ||
    (text.positionLocked !== undefined && typeof text.positionLocked !== 'boolean') ||
    (text.characterStyleRuns !== undefined && text.characterStyleRuns.length !== 0) ||
    (text.paragraphStyleRuns !== undefined && text.paragraphStyleRuns.length !== 0) ||
    !isRepresentableTransform(text.transform, placement)) {
    throw new Error('local Text Block cannot be represented by original CREATE_BLOCK');
  }
}

function writePaper(bytes: Uint8Array, vtable: number, table: number,
  paper: PagePaperBackground): void {
  const fields: number[] = new Array<number>(6).fill(0);
  fields[0] = paper.flair === null ? 0 : 4;
  fields[1] = paper.flairSpacingPt === null ? 0 : 8;
  fields[2] = paper.flairBleeds === null ? 0 : 5;
  fields[3] = paper.flairCentered === null ? 0 : 6;
  fields[4] = paper.colorR === null ? 0 : 12;
  fields[5] = paper.legacyPaperIndex === null ? 0 : 7;
  writeVtable(bytes, vtable, 16, fields);
  writeU32(bytes, table, table - vtable);
  if (paper.flair !== null) {
    writeU8(bytes, table + 4, paper.flair);
  }
  if (paper.flairBleeds !== null) {
    writeU8(bytes, table + 5, paper.flairBleeds ? 1 : 0);
  }
  if (paper.flairCentered !== null) {
    writeU8(bytes, table + 6, paper.flairCentered ? 1 : 0);
  }
  if (paper.legacyPaperIndex !== null) {
    writeU8(bytes, table + 7, paper.legacyPaperIndex);
  }
  if (paper.flairSpacingPt !== null) {
    writeF32(bytes, table + 8, paper.flairSpacingPt);
  }
  if (paper.colorR !== null) {
    writeU8(bytes, table + 12, paper.colorR);
    writeU8(bytes, table + 13, paper.colorG as number);
    writeU8(bytes, table + 14, paper.colorB as number);
    writeU8(bytes, table + 15, paper.colorA as number);
  }
}

function isRepresentableTransform(matrix: TransformMatrix,
  placement: TextBlockTransformComponents): boolean {
  if (matrix.length !== 9 || Math.abs(matrix[6]) > EPSILON ||
    Math.abs(matrix[7]) > EPSILON || Math.abs(matrix[8] - 1) > EPSILON) {
    return false;
  }
  const cosine: number = Math.cos(placement.rotationRadians);
  const sine: number = Math.sin(placement.rotationRadians);
  const expected: number[] = [
    cosine * placement.scaleX, -sine * placement.scaleY,
    matrix[2], sine * placement.scaleX, cosine * placement.scaleY, matrix[5], 0, 0, 1,
  ];
  return matrix.every((value: number, index: number): boolean =>
    Number.isFinite(value) && Math.abs(value - expected[index]) <= EPSILON);
}

function writeSequence(bytes: Uint8Array, offset: number,
  value: OriginalSequenceIdentity): void {
  writeU16(bytes, offset, value.siteId);
  writeU32(bytes, offset + 4, value.timestamp);
  writeU32(bytes, offset + 8, value.index);
}

function writeVtable(bytes: Uint8Array, offset: number, objectSize: number,
  fields: number[]): void {
  writeU16(bytes, offset, 4 + fields.length * 2);
  writeU16(bytes, offset + 2, objectSize);
  for (let index: number = 0; index < fields.length; index++) {
    writeU16(bytes, offset + 4 + index * 2, fields[index]);
  }
}

function writeF32(bytes: Uint8Array, offset: number, value: number): void {
  new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength).setFloat32(offset, value, true);
}

function writeU8(bytes: Uint8Array, offset: number, value: number): void {
  bytes[offset] = value & 0xFF;
}

function writeColor(bytes: Uint8Array, offset: number, argb: number): void {
  bytes[offset] = argb >>> 16 & 0xFF;
  bytes[offset + 1] = argb >>> 8 & 0xFF;
  bytes[offset + 2] = argb & 0xFF;
  bytes[offset + 3] = argb >>> 24 & 0xFF;
}

function writeHash(bytes: Uint8Array, offset: number, bits: string[]): void {
  const hex: string = originalAssetStorageHash(bits);
  for (let index: number = 0; index < 64; index++) {
    bytes[offset + index] = parseInt(hex.substring(index * 2, index * 2 + 2), 16);
  }
}

function writeString(bytes: Uint8Array, offset: number, value: Uint8Array): void {
  writeU32(bytes, offset, value.length);
  bytes.set(value, offset + 4);
  bytes[offset + 4 + value.length] = 0;
}

function validColor(color: number): boolean {
  return Number.isSafeInteger(color) && color >= -2147483648 && color <= 4294967295;
}

function align4(value: number): number {
  return (value + 3) & ~3;
}

function writeU16(bytes: Uint8Array, offset: number, value: number): void {
  bytes[offset] = value & 0xFF;
  bytes[offset + 1] = value >>> 8 & 0xFF;
}

function writeU32(bytes: Uint8Array, offset: number, value: number): void {
  bytes[offset] = value & 0xFF;
  bytes[offset + 1] = value >>> 8 & 0xFF;
  bytes[offset + 2] = value >>> 16 & 0xFF;
  bytes[offset + 3] = value >>> 24 & 0xFF;
}
