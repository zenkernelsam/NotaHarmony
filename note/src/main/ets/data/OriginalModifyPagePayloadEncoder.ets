import {
  encodeOriginalSequenceId, OriginalSequenceIdentity, validateOriginalSequenceIdentity,
} from './OperationIdentity';
import { PageBackground } from '../core/model/NoteTypes';
import { encodeOriginalPageBackgroundTableBlob } from './OriginalSetMetadataPayloadEncoder';

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

export function encodeOriginalModifyPageBookmark(pages: OriginalSequenceIdentity[],
  bookmarked: boolean): Uint8Array {
  if (pages.length < 1 || pages.length > MAX_ORIGINAL_MODIFY_PAGE_COUNT) {
    throw new Error('local ModifyPage bookmark page count is invalid');
  }
  const seen: Set<string> = new Set<string>();
  for (const page of pages) {
    validateOriginalSequenceIdentity(page);
    const key: string = encodeOriginalSequenceId(page);
    if (seen.has(key)) {
      throw new Error('local ModifyPage bookmark repeats a page identity');
    }
    seen.add(key);
  }

  // ge8 fields are pages(vector<SeqId>), moveTo(SeqMove), background and bookmark
  // (oz9 ubyte). A bookmark write keeps field 3 present with the enum byte and
  // omits fields 1-2 entirely; the 4-aligned page vector follows the 13-byte table.
  const rootVtable: number = 4;
  const rootTable: number = 16;
  const pageVector: number = 32;
  const bytes: Uint8Array = new Uint8Array(pageVector + 4 + pages.length * 12);

  writeU32(bytes, 0, rootTable);
  writeVtable(bytes, rootVtable, 13, [4, 0, 0, 12]);
  writeU32(bytes, rootTable, rootTable - rootVtable);
  writeU32(bytes, rootTable + 4, pageVector - (rootTable + 4));
  bytes[rootTable + 12] = bookmarked ? 1 : 0;
  writeU32(bytes, pageVector, pages.length);
  for (let index: number = 0; index < pages.length; index++) {
    writeSequence(bytes, pageVector + 4 + index * 12, pages[index]);
  }
  return bytes;
}

// Original 1.0.3 zd2 case 1 (content-manager Rotate Page) emits a ModifyPage op
// through u5j.s(x09, [page], null, m2d, null, 10): field 0 carries the page
// identities, field 2 the m2d setter whose field 0 nests the new nz9. Fields 1
// (SeqMove) and 3 (oz9 bookmark) stay absent. A null background keeps the m2d
// table while omitting its field 0, which resets the page-level register to the
// note-level fallback exactly like a null m2d.j() read.
export function encodeOriginalModifyPageBackground(pages: OriginalSequenceIdentity[],
  background: PageBackground | null): Uint8Array {
  if (pages.length < 1 || pages.length > MAX_ORIGINAL_MODIFY_PAGE_COUNT) {
    throw new Error('local ModifyPage background page count is invalid');
  }
  const seen: Set<string> = new Set<string>();
  for (const page of pages) {
    validateOriginalSequenceIdentity(page);
    const key: string = encodeOriginalSequenceId(page);
    if (seen.has(key)) {
      throw new Error('local ModifyPage background repeats a page identity');
    }
    seen.add(key);
  }
  const blob: Uint8Array | null = background === null ? null :
    encodeOriginalPageBackgroundTableBlob(background);

  const rootVtable: number = 4;
  const rootTable: number = 16;
  const pageVector: number = 36;
  const setterVtable: number = pageVector + 4 + pages.length * 12;
  const setterTable: number = align4(setterVtable + 6);
  const nz9Offset: number = setterTable + 8;
  const bytes: Uint8Array = new Uint8Array(nz9Offset + (blob === null ? 0 : blob.length));

  writeU32(bytes, 0, rootTable);
  writeVtable(bytes, rootVtable, 20, [4, 0, 12, 0]);
  writeU32(bytes, rootTable, rootTable - rootVtable);
  writeU32(bytes, rootTable + 4, pageVector - (rootTable + 4));
  writeU32(bytes, rootTable + 12, setterTable - (rootTable + 12));
  writeU32(bytes, pageVector, pages.length);
  for (let index: number = 0; index < pages.length; index++) {
    writeSequence(bytes, pageVector + 4 + index * 12, pages[index]);
  }

  writeVtable(bytes, setterVtable, 8, [blob === null ? 0 : 4]);
  writeU32(bytes, setterTable, setterTable - setterVtable);
  if (blob !== null) {
    writeU32(bytes, setterTable + 4, nz9Offset - (setterTable + 4));
    bytes.set(blob, nz9Offset);
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
