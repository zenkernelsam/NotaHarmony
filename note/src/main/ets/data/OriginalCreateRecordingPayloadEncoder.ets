import { util } from '@kit.ArkTS';
import { originalAssetStorageHash } from '../core/model/ImageBlockGeometry';
import { OriginalAssetMetadata } from '../core/model/NoteTypes';
import { compareUnsignedLongDecimal, validateUnsignedLongDecimal } from './UnsignedDecimal';

const MAX_UINT32: number = 0xFFFFFFFF;
const MAX_FILE_NAME_BYTES: number = 65536;

export function encodeOriginalLocalCreateRecording(metadata: OriginalAssetMetadata,
  startTime: string, endTime: string): Uint8Array {
  validateMetadata(metadata);
  validateUnsignedLongDecimal(startTime);
  validateUnsignedLongDecimal(endTime);
  if (compareUnsignedLongDecimal(startTime, endTime) > 0) {
    throw new Error('local CreateRecording starts after it ends');
  }
  const fileName: Uint8Array = new util.TextEncoder().encodeInto(metadata.fileName);
  const mimeType: Uint8Array = new util.TextEncoder().encodeInto(metadata.mimeType);
  if (fileName.length === 0 || fileName.length > MAX_FILE_NAME_BYTES || mimeType.length === 0) {
    throw new Error('local CreateRecording asset strings are invalid');
  }

  // CreateRecording has recording, startTime, endTime, name, segmentation and zIndex. The local
  // original writer uses the asset file name as name, omits segmentation and writes zIndex=0.
  const createVtable: number = 4;
  const createTable: number = 24;
  const recordingVtable: number = 64;
  const recordingTable: number = 72;
  const metadataVtable: number = 80;
  const metadataTable: number = 96;
  const fileNameVector: number = 176;
  const mimeTypeVector: number = align4(fileNameVector + 4 + fileName.length + 1);
  const recordingNameVector: number = align4(mimeTypeVector + 4 + mimeType.length + 1);
  const total: number = align4(recordingNameVector + 4 + fileName.length + 1);
  const bytes: Uint8Array = new Uint8Array(total);

  writeU32(bytes, 0, createTable);
  writeVtable(bytes, createVtable, 40, [4, 8, 16, 24, 0, 32]);
  writeU32(bytes, createTable, createTable - createVtable);
  writeU32(bytes, createTable + 4, recordingTable - (createTable + 4));
  writeUint64Decimal(bytes, createTable + 8, startTime);
  writeUint64Decimal(bytes, createTable + 16, endTime);
  writeU32(bytes, createTable + 24, recordingNameVector - (createTable + 24));
  writeUint64Decimal(bytes, createTable + 32, '0');

  writeVtable(bytes, recordingVtable, 8, [4]);
  writeU32(bytes, recordingTable, recordingTable - recordingVtable);
  writeU32(bytes, recordingTable + 4, metadataTable - (recordingTable + 4));

  writeVtable(bytes, metadataVtable, 80, [4, 68, 72, 76]);
  writeU32(bytes, metadataTable, metadataTable - metadataVtable);
  writeHash(bytes, metadataTable + 4, metadata.assetHashBits);
  writeU32(bytes, metadataTable + 68, fileNameVector - (metadataTable + 68));
  writeU32(bytes, metadataTable + 72, mimeTypeVector - (metadataTable + 72));
  writeU32(bytes, metadataTable + 76, metadata.fileSize);

  writeString(bytes, fileNameVector, fileName);
  writeString(bytes, mimeTypeVector, mimeType);
  writeString(bytes, recordingNameVector, fileName);
  return bytes;
}

function validateMetadata(metadata: OriginalAssetMetadata): void {
  if (!Number.isSafeInteger(metadata.fileSize) || metadata.fileSize <= 0 ||
    metadata.fileSize > MAX_UINT32 || metadata.fileName.length === 0 || metadata.mimeType.length === 0) {
    throw new Error('local CreateRecording asset metadata is invalid');
  }
  originalAssetStorageHash(metadata.assetHashBits);
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
    const divided: DecimalDivision = divideDecimalBy256(remaining);
    bytes[offset + index] = divided.remainder;
    remaining = divided.quotient;
  }
  if (remaining !== '0') {
    throw new Error('local CreateRecording uint64 exceeds its field');
  }
}

interface DecimalDivision {
  quotient: string;
  remainder: number;
}

function divideDecimalBy256(value: string): DecimalDivision {
  let quotient: string = '';
  let remainder: number = 0;
  for (let index: number = 0; index < value.length; index++) {
    const current: number = remainder * 10 + value.charCodeAt(index) - 0x30;
    const digit: number = Math.floor(current / 256);
    remainder = current % 256;
    if (quotient.length > 0 || digit !== 0) {
      quotient += digit.toString();
    }
  }
  return { quotient: quotient.length === 0 ? '0' : quotient, remainder: remainder };
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
