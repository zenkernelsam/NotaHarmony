import { OpType } from '../core/model/OpTypes';
import { PageElementKind } from '../core/model/PageElementOrder';
import { decodeOperationId } from './OperationIdentity';
import {
  BinaryOpReader, BinaryOpWriter, encodeOperationString, MAX_OPERATION_BYTES,
  MAX_OPERATION_ELEMENTS,
} from './BinaryOpCodec';
import { MAX_ORIGINAL_DELETE_ENTITY_COUNT } from './OriginalDeleteEntitiesOperation';
import {
  classifyPageMutation, decodePageMutationOp, encodePageMutationOp, PageMutationOpPayload,
} from './PageMutationOpCodec';
import { decodeStoredPageElement, PersistedElement } from './PersistedElementCodec';
import { SearchSourceElement } from './SearchIndexPolicy';

// HWC1 = Harmony companion for one original xsc/bt1 Convert-to-Text transaction.
const MAGIC: number[] = [0x48, 0x57, 0x43, 0x31];

/**
 * The page snapshot is retained for durable editor history.  The explicit IDs
 * are intentionally duplicated: they are the exact DELETE_ENTITIES source
 * set and the CREATE_BLOCK identity, so a future reader cannot infer a
 * different conversion from a generic REPLACE_ELEMENTS payload.
 */
export interface OriginalHandwritingConversionMutation {
  pageMutation: PageMutationOpPayload;
  sourceStrokeIds: string[];
  textId: string;
}

export function encodeOriginalHandwritingConversionMutation(
  mutation: OriginalHandwritingConversionMutation): Uint8Array {
  validateOriginalHandwritingConversionMutation(mutation);
  const pageBytes: Uint8Array = encodePageMutationOp(mutation.pageMutation);
  const sourceBytes: Uint8Array[] = mutation.sourceStrokeIds.map(
    (id: string): Uint8Array => encodeOperationString(id,
      'original handwriting conversion source ID'));
  const textBytes: Uint8Array = encodeOperationString(
    mutation.textId, 'original handwriting conversion Text ID');
  let size: number = MAGIC.length + 4 + pageBytes.length + 4 + 4 + textBytes.length;
  for (const source of sourceBytes) {
    size += 4 + source.length;
  }
  if (size > MAX_OPERATION_BYTES) {
    throw new Error('original handwriting conversion mutation exceeds operation byte budget');
  }
  const writer: BinaryOpWriter = new BinaryOpWriter(new Uint8Array(size));
  writer.writeBytes(new Uint8Array(MAGIC));
  writer.writeSizedBytes(pageBytes);
  writer.writeUint32(sourceBytes.length);
  for (const source of sourceBytes) {
    writer.writeSizedBytes(source);
  }
  writer.writeSizedBytes(textBytes);
  return writer.finish();
}

export function decodeOriginalHandwritingConversionMutation(
  bytes: Uint8Array): OriginalHandwritingConversionMutation {
  const reader: BinaryOpReader = new BinaryOpReader(bytes);
  reader.readMagic(MAGIC);
  const pageMutation: PageMutationOpPayload = decodePageMutationOp(
    reader.readSizedBytes(MAX_OPERATION_BYTES));
  const sourceCount: number = reader.readUint32();
  if (sourceCount === 0 || sourceCount > MAX_ORIGINAL_DELETE_ENTITY_COUNT ||
    sourceCount > MAX_OPERATION_ELEMENTS) {
    throw new Error('original handwriting conversion source count is invalid');
  }
  const sourceStrokeIds: string[] = [];
  for (let index: number = 0; index < sourceCount; index++) {
    sourceStrokeIds.push(reader.readString());
  }
  const textId: string = reader.readString();
  if (!reader.atEnd()) {
    throw new Error('original handwriting conversion mutation has trailing bytes');
  }
  const mutation: OriginalHandwritingConversionMutation = {
    pageMutation: pageMutation, sourceStrokeIds: sourceStrokeIds, textId: textId,
  };
  validateOriginalHandwritingConversionMutation(mutation);
  return mutation;
}

export function validateOriginalHandwritingConversionMutation(
  mutation: OriginalHandwritingConversionMutation): void {
  if (mutation === null || mutation === undefined ||
    !Array.isArray(mutation.sourceStrokeIds) || typeof mutation.textId !== 'string') {
    throw new Error('original handwriting conversion mutation has invalid identity fields');
  }
  const pageMutation: PageMutationOpPayload = mutation.pageMutation;
  if (classifyPageMutation(pageMutation) !== OpType.REPLACE_ELEMENTS ||
    pageMutation.beforeElements.length === 0 || pageMutation.afterElements.length !== 1 ||
    mutation.sourceStrokeIds.length !== pageMutation.beforeElements.length ||
    mutation.sourceStrokeIds.length > MAX_ORIGINAL_DELETE_ENTITY_COUNT) {
    throw new Error('original handwriting conversion must replace Ink with one Text block');
  }
  const sourceSet: Set<string> = new Set<string>();
  for (const element of pageMutation.beforeElements) {
    if (element.kind !== PageElementKind.STROKE || typeof element.elementId !== 'string' ||
      decodeOperationId(element.elementId) === null ||
      sourceSet.has(element.elementId)) {
      throw new Error('original handwriting conversion has an invalid source Ink');
    }
    const persisted: PersistedElement = decodeStoredPageElement(
      element.elementId, PageElementKind.STROKE, element.payload);
    if (persisted.kind !== 'stroke' || persisted.data.id !== element.elementId) {
      throw new Error('original handwriting conversion source Ink payload is invalid');
    }
    sourceSet.add(element.elementId);
  }
  const listedSet: Set<string> = new Set<string>();
  for (const id of mutation.sourceStrokeIds) {
    if (typeof id !== 'string' || decodeOperationId(id) === null || listedSet.has(id) ||
      !sourceSet.has(id)) {
      throw new Error('original handwriting conversion source ID set is invalid');
    }
    listedSet.add(id);
  }
  if (listedSet.size !== sourceSet.size) {
    throw new Error('original handwriting conversion source ID set is incomplete');
  }
  const created: SearchSourceElement = pageMutation.afterElements[0];
  if (created.kind !== PageElementKind.TEXT || typeof created.elementId !== 'string' ||
    created.elementId !== mutation.textId || decodeOperationId(created.elementId) === null ||
    sourceSet.has(created.elementId)) {
    throw new Error('original handwriting conversion Text identity is invalid');
  }
  const persistedText: PersistedElement = decodeStoredPageElement(
    created.elementId, PageElementKind.TEXT, pageMutation.afterElements[0].payload);
  if (persistedText.kind !== 'text' || persistedText.data.id !== created.elementId) {
    throw new Error('original handwriting conversion Text payload is invalid');
  }
  const beforeOrder: Set<string> = new Set<string>(
    pageMutation.beforeOrder.map((ref): string => ref.elementId));
  const afterOrder: Set<string> = new Set<string>(
    pageMutation.afterOrder.map((ref): string => ref.elementId));
  for (const id of sourceSet) {
    if (!beforeOrder.has(id) || afterOrder.has(id)) {
      throw new Error('original handwriting conversion did not remove every source Ink');
    }
  }
  if (beforeOrder.has(mutation.textId) || !afterOrder.has(mutation.textId)) {
    throw new Error('original handwriting conversion did not insert its Text block');
  }
  if (pageMutation.beforeElements.length + pageMutation.afterElements.length >
    MAX_ORIGINAL_DELETE_ENTITY_COUNT) {
    throw new Error('original handwriting conversion exceeds one visibility payload');
  }
}
