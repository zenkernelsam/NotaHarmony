import { OpType } from '../core/model/OpTypes';
import {
  BinaryOpReader, BinaryOpWriter, encodeOperationString, MAX_OPERATION_BYTES,
} from './BinaryOpCodec';

const MAGIC_V1: number[] = [0x4E, 0x44, 0x50, 0x31]; // NDP1
const MAX_PAGE_IDS: number = 10000;

// Harmony history companion for the original ae2/u5j.e Duplicate Page action.
// The original emits a CreatePage + transcoded content op stream anchored after
// the last selected page (de2.j); Harmony writes one CreatePage op plus a
// compound clipboard-paste op, and this payload is the durable history record
// binding them into a single undoable action. Page-structure mutations cannot
// express it: classifyPageStructureMutation collapses any single insert to
// CREATE_PAGE, whose materializer requires a tail append.
export interface DuplicatePageMutation {
  fromRevision: number;
  toRevision: number;
  sourcePageId: string;
  pageId: string;
  pageOrderBefore: string[];
  pageOrderAfter: string[];
}

export function validateDuplicatePageMutation(mutation: DuplicatePageMutation): void {
  if (!Number.isSafeInteger(mutation.fromRevision) || mutation.fromRevision < 0 ||
    !Number.isSafeInteger(mutation.toRevision) ||
    mutation.toRevision !== mutation.fromRevision + 1) {
    throw new Error('duplicate page mutation revision is invalid');
  }
  if (mutation.sourcePageId.length === 0 || mutation.pageId.length === 0 ||
    mutation.sourcePageId === mutation.pageId) {
    throw new Error('duplicate page mutation identity is invalid');
  }
  validatePageOrder(mutation.pageOrderBefore, 'before order');
  validatePageOrder(mutation.pageOrderAfter, 'after order');
  if (mutation.pageOrderAfter.length !== mutation.pageOrderBefore.length + 1) {
    throw new Error('duplicate page mutation must insert exactly one page');
  }
  const beforeIds: Set<string> = new Set<string>(mutation.pageOrderBefore);
  let inserted: number = 0;
  const retained: string[] = [];
  for (const pageId of mutation.pageOrderAfter) {
    if (beforeIds.has(pageId)) {
      retained.push(pageId);
    } else if (pageId === mutation.pageId) {
      inserted++;
    } else {
      throw new Error('duplicate page mutation introduces an unrelated page identity');
    }
  }
  if (inserted !== 1 || !sameStrings(retained, mutation.pageOrderBefore)) {
    throw new Error('duplicate page mutation is not a single ordered insert');
  }
  if (!beforeIds.has(mutation.sourcePageId)) {
    throw new Error('duplicate page mutation source is not in the before order');
  }
  const sourceIndex: number = mutation.pageOrderBefore.indexOf(mutation.sourcePageId);
  if (mutation.pageOrderAfter[sourceIndex + 1] !== mutation.pageId) {
    throw new Error('duplicate page is not inserted after its source');
  }
}

export function encodeDuplicatePageMutation(mutation: DuplicatePageMutation): Uint8Array {
  validateDuplicatePageMutation(mutation);
  const source: Uint8Array = encodeOperationString(mutation.sourcePageId, 'duplicate source page');
  const page: Uint8Array = encodeOperationString(mutation.pageId, 'duplicate page id');
  const size: number = MAGIC_V1.length + 8 + 8 + 4 + source.length + 4 + page.length +
    pageOrderSize(mutation.pageOrderBefore) + pageOrderSize(mutation.pageOrderAfter);
  if (size > MAX_OPERATION_BYTES) {
    throw new Error('duplicate page operation is too large');
  }
  const writer = new BinaryOpWriter(new Uint8Array(size));
  writer.writeBytes(new Uint8Array(MAGIC_V1));
  writer.writeSafeInteger(mutation.fromRevision);
  writer.writeSafeInteger(mutation.toRevision);
  writer.writeSizedBytes(source);
  writer.writeSizedBytes(page);
  writePageOrder(writer, mutation.pageOrderBefore);
  writePageOrder(writer, mutation.pageOrderAfter);
  return writer.finish();
}

export function decodeDuplicatePageMutation(bytes: Uint8Array): DuplicatePageMutation {
  const reader = new BinaryOpReader(bytes);
  reader.readMagic(MAGIC_V1);
  const mutation: DuplicatePageMutation = {
    fromRevision: reader.readSafeInteger(),
    toRevision: reader.readSafeInteger(),
    sourcePageId: reader.readString(),
    pageId: reader.readString(),
    pageOrderBefore: readPageOrder(reader),
    pageOrderAfter: readPageOrder(reader),
  };
  if (!reader.atEnd()) {
    throw new Error('duplicate page operation has trailing bytes');
  }
  validateDuplicatePageMutation(mutation);
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
    throw new Error('duplicate page operation page count is invalid');
  }
  const order: string[] = [];
  for (let index: number = 0; index < count; index++) {
    order.push(reader.readString());
  }
  return order;
}

export const DUPLICATE_PAGE_OP_TYPE: OpType = OpType.DUPLICATE_PAGE;
