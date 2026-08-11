import { util } from '@kit.ArkTS';
import { MathElement, TextBlockElement } from '../core/model/ElementTypes';
import { TransformMatrix } from '../core/model/GeometryTypes';
import { textBlockTransformComponents, TextBlockTransformComponents } from
  '../core/model/TextBlockGeometry';
import { OriginalSequenceIdentity, validateOriginalSequenceIdentity } from './OperationIdentity';

const DEFAULT_TEXT_COLOR: number = -16777216;
const DEFAULT_TEXT_SIZE: number = 17;
const EPSILON: number = 0.000001;
const MAX_MATH_LATEX_BYTES: number = 1048576;

interface OriginalMathBlockPlacement {
  originX: number;
  originY: number;
  rotation: number;
  scaleX: number;
  scaleY: number;
}

export function encodeOriginalLocalCreateTextBlock(page: OriginalSequenceIdentity,
  text: TextBlockElement): Uint8Array {
  validateOriginalSequenceIdentity(page);
  const placement: TextBlockTransformComponents = textBlockTransformComponents(text);
  validateLocalTextBlock(text, placement);
  const hasRotation: boolean = Math.abs(placement.rotationRadians) > EPSILON;
  const hasScale: boolean = Math.abs(placement.scaleX - 1) > EPSILON ||
    Math.abs(placement.scaleY - 1) > EPSILON;
  const table: number = 52;
  const objectSize: number = 44;
  const bytes: Uint8Array = new Uint8Array(table + objectSize);
  const fields: number[] = new Array<number>(21).fill(0);
  fields[2] = 4;
  fields[3] = 16;
  fields[4] = hasRotation ? 24 : 0;
  fields[5] = hasScale ? 28 : 0;
  fields[6] = 36;

  writeU32(bytes, 0, table);
  writeVtable(bytes, 4, objectSize, fields);
  writeU32(bytes, table, table - 4);
  writeSequence(bytes, table + 4, page);
  writeF32(bytes, table + 16, placement.origin.x);
  writeF32(bytes, table + 20, placement.origin.y);
  if (hasRotation) {
    writeF32(bytes, table + 24, placement.rotationRadians);
  }
  if (hasScale) {
    writeF32(bytes, table + 28, placement.scaleX);
    writeF32(bytes, table + 32, placement.scaleY);
  }
  writeF32(bytes, table + 36, text.blockWidth);
  writeF32(bytes, table + 40, text.blockHeight);
  return bytes;
}

export function encodeOriginalLocalCreateMathBlock(page: OriginalSequenceIdentity,
  math: MathElement): Uint8Array {
  validateOriginalSequenceIdentity(page);
  const placement: OriginalMathBlockPlacement = mathBlockPlacement(math);
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

function mathBlockPlacement(math: MathElement): OriginalMathBlockPlacement {
  const matrix: TransformMatrix = math.transform;
  const scaleX: number = matrix.length === 9 ?
    Math.sqrt(matrix[0] * matrix[0] + matrix[3] * matrix[3]) : Number.NaN;
  const determinant: number = matrix.length === 9 ?
    matrix[0] * matrix[4] - matrix[1] * matrix[3] : Number.NaN;
  return {
    originX: matrix.length === 9 ? matrix[2] : Number.NaN,
    originY: matrix.length === 9 ? matrix[5] : Number.NaN,
    rotation: math.rotationRadians,
    scaleX: scaleX,
    scaleY: scaleX > EPSILON ? determinant / scaleX : Number.NaN,
  };
}

function validateLocalMathBlock(math: MathElement,
  placement: OriginalMathBlockPlacement): void {
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
    !isRepresentableMathTransform(math.transform, placement)) {
    throw new Error('local Math Block cannot be represented by original CREATE_BLOCK');
  }
}

function isRepresentableMathTransform(matrix: TransformMatrix,
  placement: OriginalMathBlockPlacement): boolean {
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

function validateLocalTextBlock(text: TextBlockElement,
  placement: TextBlockTransformComponents): void {
  if (!Number.isFinite(text.blockWidth) || text.blockWidth < 0 ||
    !Number.isFinite(text.blockHeight) || text.blockHeight < 0 ||
    !Number.isFinite(placement.origin.x) || !Number.isFinite(placement.origin.y) ||
    !Number.isFinite(placement.rotationRadians) || !Number.isFinite(placement.scaleX) ||
    !Number.isFinite(placement.scaleY) || Math.abs(placement.scaleX) <= EPSILON ||
    Math.abs(placement.scaleY) <= EPSILON || text.contentLeftInset !== 5 ||
    text.contentTopInset !== 3 || text.fontSize !== DEFAULT_TEXT_SIZE ||
    text.fontColor !== DEFAULT_TEXT_COLOR || (text.corner ?? 0) !== 0 ||
    (text.textWrap ?? 0) !== 0 || text.enableCaption === true || text.paper != null ||
    text.resizesWidthToFitText === true || text.positionLocked === true ||
    (text.characterStyleRuns !== undefined && text.characterStyleRuns.length !== 0) ||
    (text.paragraphStyleRuns !== undefined && text.paragraphStyleRuns.length !== 0) ||
    !isRepresentableTransform(text.transform, placement)) {
    throw new Error('local Text Block cannot be represented by original CREATE_BLOCK');
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
