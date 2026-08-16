import { OriginalSequenceIdentity, validateOriginalSequenceIdentity } from './OperationIdentity';

const MM_TO_POINTS: number = 72.0 / 25.4;

export function encodeOriginalLocalCreatePage(location: OriginalSequenceIdentity | null,
  widthMm: number | null = null, heightMm: number | null = null,
  pageCount: number = 1): Uint8Array {
  if (location !== null) {
    validateOriginalSequenceIdentity(location);
  }
  if (!Number.isSafeInteger(pageCount) || pageCount < 1 || pageCount > 10000) {
    throw new Error('local CreatePage count is invalid');
  }
  const hasSize: boolean = widthMm !== null || heightMm !== null;
  if (hasSize && (widthMm === null || heightMm === null || !Number.isFinite(widthMm) ||
    !Number.isFinite(heightMm) || widthMm <= 0 || heightMm <= 0)) {
    throw new Error('local CreatePage dimensions are invalid');
  }

  // ln2 fields are location(cxc), background(nz9), pageCount and bookmark. The local writer
  // creates an unbookmarked page group. A missing background inherits note SET_METADATA;
  // an explicit nz9.sourceSize preserves custom/A-series page dimensions without inventing paper.
  const rootVtable: number = 4;
  const rootTable: number = 16;
  const backgroundVtable: number = 44;
  const backgroundTable: number = 60;
  const total: number = hasSize ? 72 : 44;
  const bytes: Uint8Array = new Uint8Array(total);
  writeU32(bytes, 0, rootTable);
  writeVtable(bytes, rootVtable, 28, [
    location === null ? 0 : 4, hasSize ? 16 : 0, pageCount === 1 ? 0 : 20, 0,
  ]);
  writeU32(bytes, rootTable, rootTable - rootVtable);
  if (location !== null) {
    writeSequence(bytes, rootTable + 4, location);
  }
  if (hasSize) {
    writeU32(bytes, rootTable + 16, backgroundTable - (rootTable + 16));
    writeVtable(bytes, backgroundVtable, 12, [0, 0, 0, 4, 0]);
    writeU32(bytes, backgroundTable, backgroundTable - backgroundVtable);
    writeF32(bytes, backgroundTable + 4, (widthMm as number) * MM_TO_POINTS);
    writeF32(bytes, backgroundTable + 8, (heightMm as number) * MM_TO_POINTS);
  }
  if (pageCount !== 1) {
    writeU32(bytes, rootTable + 20, pageCount);
  }
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

function writeSequence(bytes: Uint8Array, offset: number,
  value: OriginalSequenceIdentity): void {
  writeU16(bytes, offset, value.siteId);
  writeU32(bytes, offset + 4, value.timestamp);
  writeU32(bytes, offset + 8, value.index);
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
