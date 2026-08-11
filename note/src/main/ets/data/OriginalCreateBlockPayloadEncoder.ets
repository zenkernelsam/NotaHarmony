import { TextBlockElement } from '../core/model/ElementTypes';
import { TransformMatrix } from '../core/model/GeometryTypes';
import { textBlockTransformComponents, TextBlockTransformComponents } from
  '../core/model/TextBlockGeometry';
import { OriginalSequenceIdentity, validateOriginalSequenceIdentity } from './OperationIdentity';

const DEFAULT_TEXT_COLOR: number = -16777216;
const DEFAULT_TEXT_SIZE: number = 17;
const EPSILON: number = 0.000001;

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
