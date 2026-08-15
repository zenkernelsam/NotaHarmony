import {
  encodeOriginalSequenceId, OriginalSequenceIdentity, validateOriginalSequenceIdentity,
} from './OperationIdentity';

const MAX_ORIGINAL_MODIFY_PAGE_COUNT: number = 10000;

export function encodeOriginalModifyPageMove(pages: OriginalSequenceIdentity[],
  moveTo: OriginalSequenceIdentity | null): Uint8Array {
  if (pages.length < 1 || pages.length > MAX_ORIGINAL_MODIFY_PAGE_COUNT) {
    throw new Error('local ModifyPage move page count is invalid');
  }
  const seen: Set<string> = new Set<string>();
  for (const page of pages) {
    validateOriginalSequenceIdentity(page);
    const key: string = encodeOriginalSequenceId(page);
    if (seen.has(key)) {
      throw new Error('local ModifyPage move repeats a page identity');
    }
    seen.add(key);
  }
  if (moveTo !== null) {
    validateOriginalSequenceIdentity(moveTo);
  }

  // ge8 fields are pages(vector<SeqId>), moveTo(SeqMove), background and bookmark.
  // A pure local reorder always writes the SeqMove table. Moving to the root therefore
  // keeps field 1 present while omitting only lxc field 0, matching egh.a(null).
  const rootVtable: number = 4;
  const rootTable: number = 16;
  const pageVector: number = 28;
  const moveVtable: number = pageVector + 4 + pages.length * 12;
  const moveTable: number = align4(moveVtable + 6);
  const moveObjectSize: number = moveTo === null ? 4 : 16;
  const bytes: Uint8Array = new Uint8Array(moveTable + moveObjectSize);

  writeU32(bytes, 0, rootTable);
  writeVtable(bytes, rootVtable, 12, [4, 8, 0, 0]);
  writeU32(bytes, rootTable, rootTable - rootVtable);
  writeU32(bytes, rootTable + 4, pageVector - (rootTable + 4));
  writeU32(bytes, rootTable + 8, moveTable - (rootTable + 8));
  writeU32(bytes, pageVector, pages.length);
  for (let index: number = 0; index < pages.length; index++) {
    writeSequence(bytes, pageVector + 4 + index * 12, pages[index]);
  }

  writeVtable(bytes, moveVtable, moveObjectSize, [moveTo === null ? 0 : 4]);
  writeU32(bytes, moveTable, moveTable - moveVtable);
  if (moveTo !== null) {
    writeSequence(bytes, moveTable + 4, moveTo);
  }
  return bytes;
}

function align4(value: number): number {
  return (value + 3) & ~3;
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
