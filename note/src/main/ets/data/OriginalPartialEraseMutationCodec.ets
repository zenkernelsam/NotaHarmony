import { OpType } from '../core/model/OpTypes';
import { PageElementKind } from '../core/model/PageElementOrder';
import { MAX_ORIGINAL_DELETE_ENTITY_COUNT } from './OriginalDeleteEntitiesOperation';
import { decodeOperationId } from './OperationIdentity';
import {
  classifyPageMutation, decodePageMutationOp, encodePageMutationOp, PageMutationOpPayload,
} from './PageMutationOpCodec';

export type OriginalPartialEraseMutation = PageMutationOpPayload;

export function encodeOriginalPartialEraseMutation(
  mutation: OriginalPartialEraseMutation): Uint8Array {
  validateOriginalPartialEraseMutation(mutation);
  return encodePageMutationOp(mutation);
}

export function decodeOriginalPartialEraseMutation(
  bytes: Uint8Array): OriginalPartialEraseMutation {
  const mutation: OriginalPartialEraseMutation = decodePageMutationOp(bytes);
  validateOriginalPartialEraseMutation(mutation);
  return mutation;
}

export function validateOriginalPartialEraseMutation(
  mutation: OriginalPartialEraseMutation): void {
  if (mutation.beforeElements.length === 0 ||
    mutation.beforeElements.length + mutation.afterElements.length >
      MAX_ORIGINAL_DELETE_ENTITY_COUNT) {
    throw new Error('original partial erase must fit one type-25 visibility payload');
  }
  const type: OpType = classifyPageMutation(mutation);
  if ((type !== OpType.REPLACE_ELEMENTS && type !== OpType.DELETE_ELEMENTS) ||
    mutation.beforeElements.length === 0) {
    throw new Error('original partial erase must replace or delete at least one Ink');
  }
  const beforeIds: Set<string> = new Set<string>();
  for (const element of mutation.beforeElements) {
    if (element.kind !== PageElementKind.STROKE || decodeOperationId(element.elementId) === null ||
      beforeIds.has(element.elementId)) {
      throw new Error('original partial erase has an invalid source Ink identity');
    }
    beforeIds.add(element.elementId);
  }
  const afterIds: Set<string> = new Set<string>();
  for (const element of mutation.afterElements) {
    if (element.kind !== PageElementKind.STROKE || decodeOperationId(element.elementId) === null ||
      beforeIds.has(element.elementId) || afterIds.has(element.elementId)) {
      throw new Error('original partial erase has an invalid remnant Ink identity');
    }
    afterIds.add(element.elementId);
  }
  const beforeOrder: Set<string> = new Set<string>();
  for (const ref of mutation.beforeOrder) {
    if (ref.kind === PageElementKind.STROKE) {
      beforeOrder.add(ref.elementId);
    }
  }
  const afterOrder: Set<string> = new Set<string>();
  for (const ref of mutation.afterOrder) {
    if (ref.kind === PageElementKind.STROKE) {
      afterOrder.add(ref.elementId);
    }
  }
  beforeIds.forEach((id: string): void => {
    if (!beforeOrder.has(id) || afterOrder.has(id)) {
      throw new Error('original partial erase did not remove a source Ink');
    }
  });
  afterIds.forEach((id: string): void => {
    if (beforeOrder.has(id) || !afterOrder.has(id)) {
      throw new Error('original partial erase did not insert a remnant Ink');
    }
  });
}
