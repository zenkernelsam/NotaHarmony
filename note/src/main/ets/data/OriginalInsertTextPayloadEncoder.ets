import { util } from '@kit.ArkTS';
import { OperationIdentity, validateOperationIdentity } from './OperationIdentity';

const MAX_INSERT_STRING_BYTES: number = 1048576;

export function encodeOriginalInitialInsertString(block: OperationIdentity,
  value: string): Uint8Array {
  validateOperationIdentity(block);
  const encoded: Uint8Array = new util.TextEncoder().encodeInto(value);
  if (encoded.length === 0 || encoded.length > MAX_INSERT_STRING_BYTES ||
    util.TextDecoder.create('utf-8').decodeToString(encoded) !== value) {
    throw new Error('original INSERT_STRING value is invalid');
  }
  const table: number = 16;
  const objectSize: number = 16;
  const vector: number = table + objectSize;
  const bytes: Uint8Array = new Uint8Array(vector + 4 + encoded.length);
  writeU32(bytes, 0, table);
  writeVtable(bytes, 4, objectSize, [0, 4, 8]);
  writeU32(bytes, table, table - 4);
  writeU32(bytes, table + 4, vector - (table + 4));
  writeU16(bytes, table + 8, block.siteId);
  writeU32(bytes, table + 12, block.timestamp);
  writeU32(bytes, vector, encoded.length);
  bytes.set(encoded, vector + 4);
  return bytes;
}

function writeVtable(bytes: Uint8Array, offset: number, objectSize: number,
  fields: number[]): void {
  writeU16(bytes, offset, 4 + fields.length * 2);
  writeU16(bytes, offset + 2, objectSize);
  for (let index: number = 0; index < fields.length; index++) {
    writeU16(bytes, offset + 4 + index * 2, fields[index]);
  }
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
