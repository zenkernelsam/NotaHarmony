import { OpType } from '../core/model/OpTypes';
import { PageInfo, PageOrientation, PaperSize, PaperTemplate } from '../core/model/NoteTypes';
import {
  parsePageBackground, serializePageBackground,
} from '../core/model/PageBackgroundModel';
import {
  BinaryOpReader, BinaryOpWriter, encodeOperationString, MAX_OPERATION_BYTES,
} from './BinaryOpCodec';

const MAGIC_V1: number[] = [0x44, 0x43, 0x50, 0x31]; // DCP1
const MAX_PAGE_IDS: number = 10000;

// Harmony history companion for the original de2.i delete-compensation
// transaction: when a page delete would leave fewer than two pages, the
// original appends u5j.i(x09, size - 1, 0, 14) to the same op stream, so the
// note always retains a page. The compound changes membership by two (the
// victim leaves, a blank page arrives), which PageStructureMutation cannot
// express — this payload binds the hide + create pair into one undoable
// action. The inserted page always lands at the victim's slot.
export interface DeletePageCompensationMutation {
  fromRevision: number;
  toRevision: number;
  deletedPageId: string;
  insertedPage: PageInfo;
  pageOrderBefore: string[];
  pageOrderAfter: string[];
}

export function validateDeletePageCompensationMutation(
  mutation: DeletePageCompensationMutation): void {
  if (!Number.isSafeInteger(mutation.fromRevision) || mutation.fromRevision < 0 ||
    !Number.isSafeInteger(mutation.toRevision) ||
    mutation.toRevision <= mutation.fromRevision) {
    throw new Error('delete-page compensation mutation revision is invalid');
  }
  if (mutation.deletedPageId.length === 0 || mutation.insertedPage.pageId.length === 0 ||
    mutation.deletedPageId === mutation.insertedPage.pageId) {
    throw new Error('delete-page compensation mutation identity is invalid');
  }
  validatePageOrder(mutation.pageOrderBefore, 'before order');
  validatePageOrder(mutation.pageOrderAfter, 'after order');
  if (mutation.pageOrderAfter.length !== mutation.pageOrderBefore.length) {
    throw new Error('delete-page compensation must replace exactly one membership');
  }
  // The roles are fixed (deletedPageId = victim, insertedPage = blank) while
  // the orders describe the recorded transaction: PUSH/REDO move
  // victim -> inserted, UNDO moves inserted -> victim.
  const beforeIds: Set<string> = new Set<string>(mutation.pageOrderBefore);
  const afterIds: Set<string> = new Set<string>(mutation.pageOrderAfter);
  const forward: boolean = beforeIds.has(mutation.deletedPageId) &&
    afterIds.has(mutation.insertedPage.pageId) &&
    !beforeIds.has(mutation.insertedPage.pageId) && !afterIds.has(mutation.deletedPageId);
  const reverse: boolean = beforeIds.has(mutation.insertedPage.pageId) &&
    afterIds.has(mutation.deletedPageId) &&
    !beforeIds.has(mutation.deletedPageId) && !afterIds.has(mutation.insertedPage.pageId);
  if (!forward && !reverse) {
    throw new Error('delete-page compensation is not a victim/blank swap');
  }
  const source: string[] = forward ? mutation.pageOrderBefore : mutation.pageOrderAfter;
  const target: string[] = forward ? mutation.pageOrderAfter : mutation.pageOrderBefore;
  const expected: string[] = [];
  for (const pageId of source) {
    expected.push(pageId === mutation.deletedPageId ? mutation.insertedPage.pageId : pageId);
  }
  if (!sameStrings(expected, target)) {
    throw new Error('delete-page compensation is not a single ordered replacement');
  }
  const host: string[] = forward ? mutation.pageOrderAfter : mutation.pageOrderBefore;
  if (mutation.insertedPage.pageIndex < 0 ||
    mutation.insertedPage.pageIndex >= host.length ||
    host[mutation.insertedPage.pageIndex] !== mutation.insertedPage.pageId) {
    throw new Error('compensation page index does not match its materialized slot');
  }
}

export function encodeDeletePageCompensationMutation(
  mutation: DeletePageCompensationMutation): Uint8Array {
  validateDeletePageCompensationMutation(mutation);
  const deleted: Uint8Array = encodeOperationString(mutation.deletedPageId,
    'compensation deleted page');
  const insertedId: Uint8Array = encodeOperationString(mutation.insertedPage.pageId,
    'compensation inserted page');
  const width: Uint8Array = encodeNumber(mutation.insertedPage.widthMm, 'compensation width');
  const height: Uint8Array = encodeNumber(mutation.insertedPage.heightMm, 'compensation height');
  const background: Uint8Array = encodeOperationString(
    serializePageBackground(mutation.insertedPage.background) ?? '', 'compensation background');
  const size: number = MAGIC_V1.length + 8 + 8 + 4 + deleted.length + 4 + insertedId.length +
    8 + 4 + 4 + 4 + 4 + width.length + 4 + height.length + 4 + background.length + 8 + 4 +
    pageOrderSize(mutation.pageOrderBefore) + pageOrderSize(mutation.pageOrderAfter);
  if (size > MAX_OPERATION_BYTES) {
    throw new Error('delete-page compensation operation is too large');
  }
  const writer = new BinaryOpWriter(new Uint8Array(size));
  writer.writeBytes(new Uint8Array(MAGIC_V1));
  writer.writeSafeInteger(mutation.fromRevision);
  writer.writeSafeInteger(mutation.toRevision);
  writer.writeSizedBytes(deleted);
  writer.writeSizedBytes(insertedId);
  writer.writeSafeInteger(mutation.insertedPage.pageIndex);
  writer.writeUint32(mutation.insertedPage.size);
  writer.writeUint32(mutation.insertedPage.template);
  writer.writeUint32(mutation.insertedPage.orientation);
  writer.writeSizedBytes(width);
  writer.writeSizedBytes(height);
  writer.writeSizedBytes(background);
  writer.writeSafeInteger(mutation.insertedPage.originalPageInAsset === undefined
    ? -1 : mutation.insertedPage.originalPageInAsset);
  writer.writeUint32(mutation.insertedPage.bookmarked === true ? 1 : 0);
  writePageOrder(writer, mutation.pageOrderBefore);
  writePageOrder(writer, mutation.pageOrderAfter);
  return writer.finish();
}

export function decodeDeletePageCompensationMutation(
  bytes: Uint8Array): DeletePageCompensationMutation {
  const reader = new BinaryOpReader(bytes);
  reader.readMagic(MAGIC_V1);
  const inserted: PageInfo = {
    pageId: '',
    pageIndex: 0,
    size: 0 as PaperSize,
    template: 0 as PaperTemplate,
    orientation: 0 as PageOrientation,
    widthMm: 0,
    heightMm: 0,
    background: null,
  };
  const mutation: DeletePageCompensationMutation = {
    fromRevision: reader.readSafeInteger(),
    toRevision: reader.readSafeInteger(),
    deletedPageId: reader.readString(),
    insertedPage: inserted,
    pageOrderBefore: [],
    pageOrderAfter: [],
  };
  inserted.pageId = reader.readString();
  inserted.pageIndex = reader.readSafeInteger();
  inserted.size = reader.readUint32() as PaperSize;
  inserted.template = reader.readUint32() as PaperTemplate;
  inserted.orientation = reader.readUint32() as PageOrientation;
  inserted.widthMm = readNumber(reader, 'compensation width');
  inserted.heightMm = readNumber(reader, 'compensation height');
  const background: string = reader.readString();
  inserted.background = parsePageBackground(background.length === 0 ? null : background);
  const pageInAsset: number = reader.readSafeInteger();
  if (pageInAsset >= 0) {
    inserted.originalPageInAsset = pageInAsset;
  } else if (pageInAsset !== -1) {
    throw new Error('delete-page compensation operation has an invalid pageInAsset');
  }
  inserted.bookmarked = reader.readUint32() === 1;
  mutation.pageOrderBefore = readPageOrder(reader);
  mutation.pageOrderAfter = readPageOrder(reader);
  if (!reader.atEnd()) {
    throw new Error('delete-page compensation operation has trailing bytes');
  }
  validateDeletePageCompensationMutation(mutation);
  return mutation;
}

function validatePageOrder(order: string[], label: string): void {
  if (order.length < 1 || order.length > MAX_PAGE_IDS) {
    throw new Error(`${label} page count is invalid`);
  }
  const ids: Set<string> = new Set<string>();
  for (const pageId of order) {
    if (pageId.length === 0 || ids.has(pageId)) {
      throw new Error(`${label} contains an invalid page identity`);
    }
    ids.add(pageId);
  }
}

function encodeNumber(value: number, label: string): Uint8Array {
  if (!Number.isFinite(value)) {
    throw new Error(`${label} is invalid`);
  }
  return encodeOperationString(value.toString(), label);
}

function readNumber(reader: BinaryOpReader, label: string): number {
  const encoded: string = reader.readString();
  const value: number = Number(encoded);
  if (!Number.isFinite(value) || value.toString() !== encoded) {
    throw new Error(`${label} is not a canonical finite number`);
  }
  return value;
}

function sameStrings(left: string[], right: string[]): boolean {
  if (left.length !== right.length) {
    return false;
  }
  for (let index: number = 0; index < left.length; index++) {
    if (left[index] !== right[index]) {
      return false;
    }
  }
  return true;
}

function pageOrderSize(order: string[]): number {
  let size: number = 4;
  for (const pageId of order) {
    size += 4 + encodeOperationString(pageId, 'page order id').length;
  }
  return size;
}

function writePageOrder(writer: BinaryOpWriter, order: string[]): void {
  writer.writeUint32(order.length);
  for (const pageId of order) {
    writer.writeSizedBytes(encodeOperationString(pageId, 'page order id'));
  }
}

function readPageOrder(reader: BinaryOpReader): string[] {
  const count: number = reader.readUint32();
  if (count < 1 || count > MAX_PAGE_IDS) {
    throw new Error('delete-page compensation page count is invalid');
  }
  const order: string[] = [];
  for (let index: number = 0; index < count; index++) {
    order.push(reader.readString());
  }
  return order;
}

export const DELETE_PAGE_COMPENSATION_OP_TYPE: OpType = OpType.DELETE_PAGE_COMPENSATION;
