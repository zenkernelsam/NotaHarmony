import { OperationIdentity, validateOperationIdentity } from './OperationIdentity';
import { validateUnsignedLongDecimal } from './UnsignedDecimal';
import {
  ORIGINAL_PAYLOAD_TYPE_MAX, ORIGINAL_PAYLOAD_TYPE_MIN, validateFlatBufferRoot,
} from './OriginalSyncedOperationFlatBuffer';

export interface OriginalOperationEnvelopeMetadata {
  identity: OperationIdentity;
  clientTime: string;
  serverTime: string | null;
  audioTime: string | null;
  payloadType: number;
  transientInteractionId?: OperationIdentity | null;
}

export function encodeOriginalOperationEnvelope(metadata: OriginalOperationEnvelopeMetadata,
  payloadTable: Uint8Array): Uint8Array {
  validateOperationIdentity(metadata.identity);
  validateUnsignedLongDecimal(metadata.clientTime);
  if (metadata.serverTime !== null) {
    validateUnsignedLongDecimal(metadata.serverTime);
  }
  if (metadata.audioTime !== null) {
    validateUnsignedLongDecimal(metadata.audioTime);
  }
  if (!Number.isSafeInteger(metadata.payloadType) ||
    metadata.payloadType < ORIGINAL_PAYLOAD_TYPE_MIN ||
    metadata.payloadType > ORIGINAL_PAYLOAD_TYPE_MAX) {
    throw new Error('local original operation payload type is invalid');
  }
  validateFlatBufferRoot(payloadTable);
  const childTableOffset: number = readU32(payloadTable, 0);
  if (childTableOffset < 4 || childTableOffset > payloadTable.length - 4) {
    throw new Error('local original payload root is invalid');
  }
  const transient: OperationIdentity | null = metadata.transientInteractionId ?? null;
  if (transient !== null) {
    validateOperationIdentity(transient);
  }

  const rootTable: number = 24;
  const childStart: number = 72;
  const transientVtable: number = align4(childStart + payloadTable.length);
  const transientTable: number = transientVtable + 8;
  const total: number = transient === null ? childStart + payloadTable.length : transientTable + 12;
  const bytes: Uint8Array = new Uint8Array(total);

  writeU32(bytes, 0, rootTable);
  writeVtable(bytes, 4, 48, [4, 12, metadata.serverTime === null ? 0 : 20,
    metadata.audioTime === null ? 0 : 28,
    36, 40, transient === null ? 0 : 44]);
  writeU32(bytes, rootTable, rootTable - 4);
  writeIdentity(bytes, rootTable + 4, metadata.identity);
  writeUint64Decimal(bytes, rootTable + 12, metadata.clientTime);
  if (metadata.serverTime !== null) {
    writeUint64Decimal(bytes, rootTable + 20, metadata.serverTime);
  }
  if (metadata.audioTime !== null) {
    writeUint64Decimal(bytes, rootTable + 28, metadata.audioTime);
  }
  bytes[rootTable + 36] = metadata.payloadType;
  writeU32(bytes, rootTable + 40,
    childStart + childTableOffset - (rootTable + 40));
  bytes.set(payloadTable, childStart);
  if (transient !== null) {
    writeU32(bytes, rootTable + 44, transientTable - (rootTable + 44));
    writeVtable(bytes, transientVtable, 12, [4, 0]);
    writeU32(bytes, transientTable, transientTable - transientVtable);
    writeIdentity(bytes, transientTable + 4, transient);
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
    throw new Error('local original operation uint64 exceeds its field');
  }
}

function align4(value: number): number {
  return (value + 3) & ~3;
}

function readU32(bytes: Uint8Array, offset: number): number {
  return (bytes[offset] + bytes[offset + 1] * 0x100 +
    bytes[offset + 2] * 0x10000 + bytes[offset + 3] * 0x1000000) >>> 0;
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
