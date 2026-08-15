import { InkStyle, InkStyleMapEntry, StrokeElementData, TapePattern } from '../core/model/StrokeTypes';
import { OriginalSequenceIdentity, validateOriginalSequenceIdentity } from './OperationIdentity';
import { encodeOriginalInkCenterPath } from './OriginalInkPathEncoder';
import { validateUnsignedLongDecimal } from './UnsignedDecimal';

const MAX_UINT32: number = 0xFFFFFFFF;

interface EncodedInkTransform {
  originX: number;
  originY: number;
  rotation: number;
  scaleX: number;
  scaleY: number;
  identity: boolean;
}

export function encodeOriginalLocalCreateInk(page: OriginalSequenceIdentity,
  stroke: StrokeElementData, zIndex?: string): Uint8Array {
  validateOriginalSequenceIdentity(page);
  validateStroke(stroke);
  if (zIndex !== undefined) {
    validateUnsignedLongDecimal(zIndex);
  }
  const transform: EncodedInkTransform = decomposeInkTransform(stroke.transform);
  const centerPath: Uint8Array = encodeOriginalInkCenterPath(stroke);
  const hasAudioDuration: boolean = stroke.audioDuration !== undefined &&
    stroke.audioDuration !== null;
  if (!transform.identity || zIndex !== undefined || hasAudioDuration) {
    return encodeTransformedCreateInk(page, stroke, centerPath, transform, zIndex);
  }
  const table: number = 48;
  const centerVector: number = 112;
  const hasStyleMap: boolean = stroke.styleMap !== undefined && stroke.styleMap.length === 1;
  const styleVector: number = hasStyleMap ? align4(centerVector + 4 + centerPath.length) : 0;
  const total: number = hasStyleMap ? styleVector + 24 : align4(centerVector + 4 + centerPath.length);
  const bytes: Uint8Array = new Uint8Array(total);
  const tape: boolean = stroke.renderSpec.tapePattern !== undefined;
  const effects: string = stroke.renderSpec.inkEffects ?? '0';
  const tinted: boolean = stroke.renderSpec.inkEffectsTinted !== false;

  writeU32(bytes, 0, table);
  writeVtable(bytes, 4, 64, [
    4, 16, 0, 0, 24, 25, tape ? 26 : 0, 28, 32, 36,
    0, 0, 0, hasStyleMap ? 40 : 0, 0, 0, 0, 0,
    effects === '0' ? 0 : 48, tinted ? 0 : 56,
  ]);
  writeU32(bytes, table, table - 4);
  writeSequence(bytes, table + 4, page);
  writeF32(bytes, table + 16, 0);
  writeF32(bytes, table + 20, 0);
  bytes[table + 24] = originalTool(stroke);
  bytes[table + 25] = originalStyle(stroke.renderSpec.inkStyle);
  if (tape) {
    bytes[table + 26] = stroke.renderSpec.tapePattern as TapePattern;
  }
  writeColor(bytes, table + 28, stroke.renderSpec.color);
  writeF32(bytes, table + 32, stroke.renderSpec.brushWidth);
  writeU32(bytes, table + 36, centerVector - (table + 36));
  if (hasStyleMap) {
    writeU32(bytes, table + 40, styleVector - (table + 40));
  }
  if (effects !== '0') {
    writeUint64Decimal(bytes, table + 48, effects);
  }
  if (!tinted) {
    bytes[table + 56] = 0;
  }
  writeU32(bytes, centerVector, centerPath.length);
  bytes.set(centerPath, centerVector + 4);
  if (hasStyleMap) {
    const entry: InkStyleMapEntry = (stroke.styleMap as InkStyleMapEntry[])[0];
    writeU32(bytes, styleVector, 1);
    writeI32(bytes, styleVector + 4, entry.backingPencilSeed);
    writeF32(bytes, styleVector + 8, entry.backingPencilReferencePoint.x);
    writeF32(bytes, styleVector + 12, entry.backingPencilReferencePoint.y);
    writeF32(bytes, styleVector + 16, entry.backingDashPhase);
    writeF32(bytes, styleVector + 20, entry.backingDashPeriod);
  }
  return bytes;
}

function encodeTransformedCreateInk(page: OriginalSequenceIdentity, stroke: StrokeElementData,
  centerPath: Uint8Array, transform: EncodedInkTransform, zIndex?: string): Uint8Array {
  const table: number = 48;
  const centerVector: number = 128;
  const hasStyleMap: boolean = stroke.styleMap !== undefined && stroke.styleMap.length === 1;
  const styleVector: number = hasStyleMap ? align4(centerVector + 4 + centerPath.length) : 0;
  const total: number = hasStyleMap ? styleVector + 24 : align4(centerVector + 4 + centerPath.length);
  const bytes: Uint8Array = new Uint8Array(total);
  const tape: boolean = stroke.renderSpec.tapePattern !== undefined;
  const effects: string = stroke.renderSpec.inkEffects ?? '0';
  const tinted: boolean = stroke.renderSpec.inkEffectsTinted !== false;
  const hasAudioDuration: boolean = stroke.audioDuration !== undefined &&
    stroke.audioDuration !== null;

  writeU32(bytes, 0, table);
  writeVtable(bytes, 4, 80, [
    4, 16, 24, 28, 36, 37, tape ? 38 : 0, 40, 44, 48,
    0, 0, 0, hasStyleMap ? 52 : 0, zIndex === undefined ? 0 : 56,
    hasAudioDuration ? 76 : 0, 0, 0,
    effects === '0' ? 0 : 64, tinted ? 0 : 72,
  ]);
  writeU32(bytes, table, table - 4);
  writeSequence(bytes, table + 4, page);
  writeF32(bytes, table + 16, transform.originX);
  writeF32(bytes, table + 20, transform.originY);
  writeF32(bytes, table + 24, transform.rotation);
  writeF32(bytes, table + 28, transform.scaleX);
  writeF32(bytes, table + 32, transform.scaleY);
  bytes[table + 36] = originalTool(stroke);
  bytes[table + 37] = originalStyle(stroke.renderSpec.inkStyle);
  if (tape) {
    bytes[table + 38] = stroke.renderSpec.tapePattern as TapePattern;
  }
  writeColor(bytes, table + 40, stroke.renderSpec.color);
  writeF32(bytes, table + 44, stroke.renderSpec.brushWidth);
  writeU32(bytes, table + 48, centerVector - (table + 48));
  if (hasStyleMap) {
    writeU32(bytes, table + 52, styleVector - (table + 52));
  }
  if (zIndex !== undefined) {
    writeUint64Decimal(bytes, table + 56, zIndex);
  }
  if (effects !== '0') {
    writeUint64Decimal(bytes, table + 64, effects);
  }
  if (!tinted) {
    bytes[table + 72] = 0;
  }
  if (hasAudioDuration) {
    writeU32(bytes, table + 76, stroke.audioDuration as number);
  }
  writeU32(bytes, centerVector, centerPath.length);
  bytes.set(centerPath, centerVector + 4);
  if (hasStyleMap) {
    const entry: InkStyleMapEntry = (stroke.styleMap as InkStyleMapEntry[])[0];
    writeU32(bytes, styleVector, 1);
    writeI32(bytes, styleVector + 4, entry.backingPencilSeed);
    writeF32(bytes, styleVector + 8, entry.backingPencilReferencePoint.x);
    writeF32(bytes, styleVector + 12, entry.backingPencilReferencePoint.y);
    writeF32(bytes, styleVector + 16, entry.backingDashPhase);
    writeF32(bytes, styleVector + 20, entry.backingDashPeriod);
  }
  return bytes;
}

function validateStroke(stroke: StrokeElementData): void {
  if (stroke.pathPoints.length === 0 || !Number.isFinite(stroke.renderSpec.brushWidth) ||
    stroke.renderSpec.brushWidth <= 0 || stroke.maskPath.length !== 0 ||
    stroke.customPath !== undefined && stroke.customPath !== null ||
    stroke.fillPath !== undefined && stroke.fillPath !== null ||
    stroke.fillColor !== undefined && stroke.fillColor !== null) {
    throw new Error('local stroke cannot be represented by original CREATE_INK');
  }
  const effects: string = stroke.renderSpec.inkEffects ?? '0';
  validateUnsignedLongDecimal(effects);
  const audioDuration: number | null | undefined = stroke.audioDuration;
  if (audioDuration !== undefined && audioDuration !== null &&
    (!Number.isInteger(audioDuration) || audioDuration < 0 || audioDuration > MAX_UINT32)) {
    throw new Error('local CREATE_INK audio duration is not uint32');
  }
  decomposeInkTransform(stroke.transform);
}

function decomposeInkTransform(transform: number[]): EncodedInkTransform {
  if (transform.length !== 9 || transform.some((value: number): boolean => !Number.isFinite(value)) ||
    Math.abs(transform[6]) > 0.000001 || Math.abs(transform[7]) > 0.000001 ||
    Math.abs(transform[8] - 1) > 0.000001) {
    throw new Error('local CREATE_INK transform is not affine');
  }
  const a: number = transform[0];
  const b: number = transform[1];
  const c: number = transform[3];
  const d: number = transform[4];
  const scaleX: number = Math.sqrt(a * a + c * c);
  if (scaleX <= 0.000001) {
    throw new Error('local CREATE_INK transform has a zero horizontal scale');
  }
  const rotation: number = Math.atan2(c, a);
  const scaleY: number = (a * d - b * c) / scaleX;
  if (Math.abs(scaleY) <= 0.000001) {
    throw new Error('local CREATE_INK transform has a zero vertical scale');
  }
  const expectedB: number = -Math.sin(rotation) * scaleY;
  const expectedD: number = Math.cos(rotation) * scaleY;
  const tolerance: number = 0.00001 * Math.max(1, Math.abs(a), Math.abs(b), Math.abs(c), Math.abs(d));
  if (Math.abs(b - expectedB) > tolerance || Math.abs(d - expectedD) > tolerance) {
    throw new Error('local CREATE_INK transform contains unsupported shear');
  }
  const identity: boolean = transform[0] === 1 && transform[1] === 0 && transform[2] === 0 &&
    transform[3] === 0 && transform[4] === 1 && transform[5] === 0 &&
    transform[6] === 0 && transform[7] === 0 && transform[8] === 1;
  return {
    originX: transform[2], originY: transform[5], rotation: rotation,
    scaleX: scaleX, scaleY: scaleY, identity: identity,
  };
}

function originalTool(stroke: StrokeElementData): number {
  if (stroke.renderSpec.isPartialEraser === true) {
    return 5;
  }
  if (stroke.renderSpec.tapePattern !== undefined) {
    return 3;
  }
  return stroke.renderSpec.isPencil ? 1 : stroke.renderSpec.isHighlighter ? 2 : 0;
}

function originalStyle(style: InkStyle): number {
  return style === InkStyle.VARIABLE_WIDTH ? 0 : style === InkStyle.FIXED_WIDTH ? 1 :
    style === InkStyle.DASH ? 2 : 3;
}

function writeColor(bytes: Uint8Array, offset: number, argb: number): void {
  bytes[offset] = argb >>> 16 & 0xFF;
  bytes[offset + 1] = argb >>> 8 & 0xFF;
  bytes[offset + 2] = argb & 0xFF;
  bytes[offset + 3] = argb >>> 24 & 0xFF;
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

function writeUint64Decimal(bytes: Uint8Array, offset: number, value: string): void {
  let remaining: string = value;
  for (let index: number = 0; index < 8; index++) {
    let quotient: string = '';
    let remainder: number = 0;
    for (let digitIndex: number = 0; digitIndex < remaining.length; digitIndex++) {
      const current: number = remainder * 10 + remaining.charCodeAt(digitIndex) - 0x30;
      const digit: number = Math.floor(current / 256);
      remainder = current % 256;
      if (quotient.length > 0 || digit !== 0) {
        quotient += digit.toString();
      }
    }
    bytes[offset + index] = remainder;
    remaining = quotient.length === 0 ? '0' : quotient;
  }
  if (remaining !== '0') {
    throw new Error('local CREATE_INK uint64 exceeds its field');
  }
}

function align4(value: number): number {
  return (value + 3) & ~3;
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

function writeI32(bytes: Uint8Array, offset: number, value: number): void {
  new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength).setInt32(offset, value, true);
}
