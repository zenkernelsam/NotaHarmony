import { InkStyle } from '../core/model/StrokeTypes';
import {
  encodeOperationId, OperationIdentity, validateOperationIdentity,
} from './OperationIdentity';

const MAX_ORIGINAL_MODIFY_INK_COUNT: number = 10000;

export interface OriginalInkRenderRegisterUpdate {
  style: InkStyle | null;
  color: number | null;
  width: number | null;
}

export function encodeOriginalInkRenderRegisters(inks: OperationIdentity[],
  update: OriginalInkRenderRegisterUpdate): Uint8Array {
  const targets: OperationIdentity[] = deduplicateTargets(inks);
  if (targets.length === 0 || targets.length > MAX_ORIGINAL_MODIFY_INK_COUNT) {
    throw new Error('original MODIFY_INK has an invalid target count');
  }
  if (update.style === null && update.color === null && update.width === null) {
    throw new Error('original MODIFY_INK has no render register update');
  }
  if (update.style !== null && update.style !== InkStyle.FIXED_WIDTH &&
    update.style !== InkStyle.VARIABLE_WIDTH && update.style !== InkStyle.DASH &&
    update.style !== InkStyle.DOTS) {
    throw new Error('original MODIFY_INK style is invalid');
  }
  if (update.color !== null && (!Number.isSafeInteger(update.color) ||
    update.color < -2147483648 || update.color > 4294967295)) {
    throw new Error('original MODIFY_INK color is invalid');
  }
  if (update.width !== null && (!Number.isFinite(update.width) || update.width <= 0)) {
    throw new Error('original MODIFY_INK width is invalid');
  }

  // wd8 has 19 fields. u5j.q writes an empty style-map vector whenever style is present.
  const table: number = 48;
  const objectSize: number = 24;
  const inksVector: number = table + objectSize;
  const styleMapVector: number = update.style === null ? 0 : inksVector + 4 + targets.length * 8;
  const total: number = styleMapVector === 0 ? inksVector + 4 + targets.length * 8 : styleMapVector + 4;
  const bytes: Uint8Array = new Uint8Array(total);
  const fields: number[] = new Array<number>(19).fill(0);
  fields[0] = 4;
  fields[5] = update.style === null ? 0 : 12;
  fields[6] = update.color === null ? 0 : 16;
  fields[7] = update.width === null ? 0 : 20;
  fields[12] = styleMapVector === 0 ? 0 : 8;

  writeU32(bytes, 0, table);
  writeVtable(bytes, 4, objectSize, fields);
  writeU32(bytes, table, table - 4);
  writeU32(bytes, table + 4, inksVector - (table + 4));
  if (styleMapVector !== 0) {
    writeU32(bytes, table + 8, styleMapVector - (table + 8));
  }
  if (update.style !== null) {
    bytes[table + 12] = originalStyle(update.style);
  }
  if (update.color !== null) {
    writeColor(bytes, table + 16, update.color);
  }
  if (update.width !== null) {
    writeF32(bytes, table + 20, update.width);
  }
  writeTargets(bytes, inksVector, targets);
  if (styleMapVector !== 0) {
    writeU32(bytes, styleMapVector, 0);
  }
  return bytes;
}

function deduplicateTargets(inks: OperationIdentity[]): OperationIdentity[] {
  const result: OperationIdentity[] = [];
  const seen: Set<string> = new Set<string>();
  for (const ink of inks) {
    validateOperationIdentity(ink);
    const key: string = encodeOperationId(ink);
    if (seen.has(key)) {
      throw new Error('original MODIFY_INK repeats a target Ink');
    }
    seen.add(key);
    result.push({ timestamp: ink.timestamp, siteId: ink.siteId });
  }
  return result;
}

function writeTargets(bytes: Uint8Array, vector: number, targets: OperationIdentity[]): void {
  writeU32(bytes, vector, targets.length);
  for (let index: number = 0; index < targets.length; index++) {
    const offset: number = vector + 4 + index * 8;
    writeU16(bytes, offset, targets[index].siteId);
    writeU32(bytes, offset + 4, targets[index].timestamp);
  }
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
