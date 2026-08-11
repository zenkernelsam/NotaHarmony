import { OperationIdentity, validateOperationIdentity } from './OperationIdentity';

export function encodeOriginalTransientInteractionEndedPayload(
  interactionId: OperationIdentity, replacedByOp: OperationIdentity | null): Uint8Array {
  validateOperationIdentity(interactionId);
  if (replacedByOp !== null) {
    validateOperationIdentity(replacedByOp);
  }
  const table: number = 16;
  const bytes: Uint8Array = new Uint8Array(36);
  writeU32(bytes, 0, table);
  writeVtable(bytes, 4, 20, [4, replacedByOp === null ? 0 : 12]);
  writeU32(bytes, table, table - 4);
  writeIdentity(bytes, table + 4, interactionId);
  if (replacedByOp !== null) {
    writeIdentity(bytes, table + 12, replacedByOp);
  }
  return bytes;
}

function writeIdentity(bytes: Uint8Array, offset: number, value: OperationIdentity): void {
  writeU16(bytes, offset, value.siteId);
  writeU32(bytes, offset + 4, value.timestamp);
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
