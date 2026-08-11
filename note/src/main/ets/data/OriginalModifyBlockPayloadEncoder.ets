import {
  encodeOperationId, OperationIdentity, validateOperationIdentity,
} from './OperationIdentity';
import { OriginalBlockRect } from './OriginalCreateBlockOperation';

const MAX_ORIGINAL_MODIFY_BLOCK_COUNT: number = 10000;

export function encodeOriginalImageFlip(blocks: OperationIdentity[],
  horizontal: boolean | null, vertical: boolean | null,
  cropRect: OriginalBlockRect | null = null): Uint8Array {
  const targets: OperationIdentity[] = validateTargets(blocks);
  if (targets.length === 0 || targets.length > MAX_ORIGINAL_MODIFY_BLOCK_COUNT) {
    throw new Error('original MODIFY_BLOCK has an invalid target count');
  }
  if (horizontal === null && vertical === null) {
    throw new Error('original MODIFY_BLOCK has no image flip update');
  }
  if (cropRect !== null && (!Number.isFinite(cropRect.x) || !Number.isFinite(cropRect.y) ||
    !Number.isFinite(cropRect.width) || !Number.isFinite(cropRect.height) ||
    cropRect.width < 0 || cropRect.height < 0)) {
    throw new Error('original MODIFY_BLOCK image crop is invalid');
  }

  // td8 has 18 fields. Flip booleans must keep vtable presence even when false.
  const table: number = 44;
  const objectSize: number = 16;
  const vector: number = table + objectSize;
  const vectorEnd: number = vector + 4 + targets.length * 8;
  const cropVtable: number = cropRect === null ? 0 : align4(vectorEnd);
  const cropTable: number = cropRect === null ? 0 : align4(cropVtable + 6);
  const total: number = cropRect === null ? vectorEnd : cropTable + 20;
  const bytes: Uint8Array = new Uint8Array(total);
  const fields: number[] = new Array<number>(18).fill(0);
  fields[0] = 4;
  fields[12] = cropRect === null ? 0 : 8;
  fields[14] = horizontal === null ? 0 : 12;
  fields[15] = vertical === null ? 0 : 13;

  writeU32(bytes, 0, table);
  writeVtable(bytes, 4, objectSize, fields);
  writeU32(bytes, table, table - 4);
  writeU32(bytes, table + 4, vector - (table + 4));
  if (cropRect !== null) {
    writeU32(bytes, table + 8, cropTable - (table + 8));
  }
  if (horizontal !== null) {
    bytes[table + 12] = horizontal ? 1 : 0;
  }
  if (vertical !== null) {
    bytes[table + 13] = vertical ? 1 : 0;
  }
  writeU32(bytes, vector, targets.length);
  for (let index: number = 0; index < targets.length; index++) {
    const offset: number = vector + 4 + index * 8;
    writeU16(bytes, offset, targets[index].siteId);
    writeU32(bytes, offset + 4, targets[index].timestamp);
  }
  if (cropRect !== null) {
    writeVtable(bytes, cropVtable, 20, [4]);
    writeU32(bytes, cropTable, cropTable - cropVtable);
    writeF32(bytes, cropTable + 4, cropRect.x);
    writeF32(bytes, cropTable + 8, cropRect.y);
    writeF32(bytes, cropTable + 12, cropRect.width);
    writeF32(bytes, cropTable + 16, cropRect.height);
  }
  return bytes;
}

function validateTargets(blocks: OperationIdentity[]): OperationIdentity[] {
  const targets: OperationIdentity[] = [];
  const seen: Set<string> = new Set<string>();
  for (const block of blocks) {
    validateOperationIdentity(block);
    const key: string = encodeOperationId(block);
    if (seen.has(key)) {
      throw new Error('original MODIFY_BLOCK repeats a target Block');
    }
    seen.add(key);
    targets.push({ timestamp: block.timestamp, siteId: block.siteId });
  }
  return targets;
}

function writeVtable(bytes: Uint8Array, offset: number, objectSize: number,
  fields: number[]): void {
  writeU16(bytes, offset, 4 + fields.length * 2);
  writeU16(bytes, offset + 2, objectSize);
  for (let index: number = 0; index < fields.length; index++) {
    writeU16(bytes, offset + 4 + index * 2, fields[index]);
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
