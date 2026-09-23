import { OpType } from '../core/model/OpTypes';
import {
  BinaryOpReader, BinaryOpWriter, encodeOperationString, MAX_OPERATION_BYTES,
} from './BinaryOpCodec';

const MAGIC_V1: number[] = [0x4E, 0x50, 0x42, 0x4B]; // NPBK

// Harmony history companion for the original ae2 variant-0 bookmark toggle.
// The original emits u5j.s(x09, pages, null, null, oz9, 6) — a ModifyPage
// carrying only field 3 (the oz9 LWW register) — through the journaled
// x82.I channel (dof = undoable; cof.toString() = "NotUndoable"), so the
// toggle is one undoable action upstream. Page-structure mutations cannot
// express it: bookmarked is deliberately excluded from samePageSettings /
// PageStructureOpCodec (ADR-0508), and a bookmark-only change classifies as
// "does not change state".
export interface PageBookmarkMutation {
  fromRevision: number;
  toRevision: number;
  pageId: string;
  bookmarkedBefore: boolean;
  bookmarkedAfter: boolean;
}

export function validatePageBookmarkMutation(mutation: PageBookmarkMutation): void {
  if (!Number.isSafeInteger(mutation.fromRevision) || mutation.fromRevision < 0 ||
    !Number.isSafeInteger(mutation.toRevision) ||
    mutation.toRevision !== mutation.fromRevision + 1) {
    throw new Error('page bookmark mutation revision is invalid');
  }
  if (mutation.pageId.length === 0) {
    throw new Error('page bookmark mutation identity is invalid');
  }
  if (mutation.bookmarkedBefore === mutation.bookmarkedAfter) {
    throw new Error('page bookmark mutation does not change the register');
  }
}

export function encodePageBookmarkMutation(mutation: PageBookmarkMutation): Uint8Array {
  validatePageBookmarkMutation(mutation);
  const pageId: Uint8Array = encodeOperationString(mutation.pageId, 'page bookmark page id');
  const size: number = MAGIC_V1.length + 8 + 8 + 4 + pageId.length + 1 + 1;
  if (size > MAX_OPERATION_BYTES) {
    throw new Error('page bookmark operation is too large');
  }
  const writer = new BinaryOpWriter(new Uint8Array(size));
  writer.writeBytes(new Uint8Array(MAGIC_V1));
  writer.writeSafeInteger(mutation.fromRevision);
  writer.writeSafeInteger(mutation.toRevision);
  writer.writeSizedBytes(pageId);
  writer.writeByte(mutation.bookmarkedBefore ? 1 : 0);
  writer.writeByte(mutation.bookmarkedAfter ? 1 : 0);
  return writer.finish();
}

export function decodePageBookmarkMutation(bytes: Uint8Array): PageBookmarkMutation {
  const reader = new BinaryOpReader(bytes);
  reader.readMagic(MAGIC_V1);
  const mutation: PageBookmarkMutation = {
    fromRevision: reader.readSafeInteger(),
    toRevision: reader.readSafeInteger(),
    pageId: reader.readString(),
    bookmarkedBefore: reader.readByte() === 1,
    bookmarkedAfter: reader.readByte() === 1,
  };
  if (!reader.atEnd()) {
    throw new Error('page bookmark operation has trailing bytes');
  }
  validatePageBookmarkMutation(mutation);
  return mutation;
}

export const PAGE_BOOKMARK_OP_TYPE: OpType = OpType.PAGE_BOOKMARK;
