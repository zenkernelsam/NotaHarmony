import { OpType } from '../core/model/OpTypes';
import {
  BinaryOpReader, BinaryOpWriter, encodeOperationString, MAX_OPERATION_BYTES,
  MAX_OPERATION_ELEMENTS, sameBytes,
} from './BinaryOpCodec';
import { SearchSourceElement } from './SearchIndexPolicy';

const MAGIC: number[] = [0x4E, 0x50, 0x4D, 0x31]; // NPM1

export interface PageMutationOrderRef {
  elementId: string;
  kind: number;
}

export interface PageMutationOpPayload {
  pageId: string;
  fromRevision: number;
  toRevision: number;
  beforeElements: SearchSourceElement[];
  afterElements: SearchSourceElement[];
  beforeOrder: PageMutationOrderRef[];
  afterOrder: PageMutationOrderRef[];
}

export interface PageMutationReplayResult {
  revision: number;
  elements: SearchSourceElement[];
}

interface EncodedOrderRef {
  value: PageMutationOrderRef;
  id: Uint8Array;
}

interface EncodedElement {
  value: SearchSourceElement;
  id: Uint8Array;
}

export function createPageMutation(pageId: string, fromRevision: number, toRevision: number,
  current: SearchSourceElement[], next: SearchSourceElement[]): PageMutationOpPayload {
  const currentMap: Map<string, SearchSourceElement> = elementMap(current, 'current page');
  const nextMap: Map<string, SearchSourceElement> = elementMap(next, 'next page');
  const beforeElements: SearchSourceElement[] = [];
  const afterElements: SearchSourceElement[] = [];
  currentMap.forEach((element: SearchSourceElement, key: string): void => {
    const target: SearchSourceElement | undefined = nextMap.get(key);
    if (target === undefined || !sameBytes(element.payload, target.payload)) {
      beforeElements.push(element);
    }
  });
  nextMap.forEach((element: SearchSourceElement, key: string): void => {
    const source: SearchSourceElement | undefined = currentMap.get(key);
    if (source === undefined || !sameBytes(source.payload, element.payload)) {
      afterElements.push(element);
    }
  });
  const mutation: PageMutationOpPayload = {
    pageId: pageId,
    fromRevision: fromRevision,
    toRevision: toRevision,
    beforeElements: beforeElements,
    afterElements: afterElements,
    beforeOrder: current.map((element: SearchSourceElement): PageMutationOrderRef =>
      ({ elementId: element.elementId, kind: element.kind })),
    afterOrder: next.map((element: SearchSourceElement): PageMutationOrderRef =>
      ({ elementId: element.elementId, kind: element.kind })),
  };
  validateMutation(mutation);
  if (beforeElements.length === 0 && afterElements.length === 0 &&
    sameOrder(mutation.beforeOrder, mutation.afterOrder)) {
    throw new Error('page mutation does not change state');
  }
  return mutation;
}

export function classifyPageMutation(mutation: PageMutationOpPayload): OpType {
  validateMutation(mutation);
  if (mutation.beforeElements.length === 0 && mutation.afterElements.length === 0) {
    if (sameOrder(mutation.beforeOrder, mutation.afterOrder)) {
      throw new Error('page mutation does not change state');
    }
    return OpType.REORDER_ELEMENTS;
  }
  if (mutation.beforeElements.length === 0) {
    return OpType.INSERT_ELEMENTS;
  }
  if (mutation.afterElements.length === 0) {
    return OpType.DELETE_ELEMENTS;
  }
  return OpType.REPLACE_ELEMENTS;
}

export function replayPageMutation(current: SearchSourceElement[], mutation: PageMutationOpPayload,
  forward: boolean): SearchSourceElement[] {
  validateMutation(mutation);
  const sourceOrder: PageMutationOrderRef[] = forward ? mutation.beforeOrder : mutation.afterOrder;
  const targetOrder: PageMutationOrderRef[] = forward ? mutation.afterOrder : mutation.beforeOrder;
  const sourceAffected: SearchSourceElement[] = forward ? mutation.beforeElements : mutation.afterElements;
  const targetAffected: SearchSourceElement[] = forward ? mutation.afterElements : mutation.beforeElements;
  const currentMap: Map<string, SearchSourceElement> = elementMap(current, 'replay source');
  if (!sameOrder(sourceOrder, current.map((element: SearchSourceElement): PageMutationOrderRef =>
    ({ elementId: element.elementId, kind: element.kind })))) {
    throw new Error('page mutation source order mismatch');
  }
  const sourceMap: Map<string, SearchSourceElement> = elementMap(sourceAffected, 'mutation source');
  const targetMap: Map<string, SearchSourceElement> = elementMap(targetAffected, 'mutation target');
  const affected: Set<string> = new Set<string>();
  sourceMap.forEach((_value: SearchSourceElement, key: string): void => { affected.add(key); });
  targetMap.forEach((_value: SearchSourceElement, key: string): void => { affected.add(key); });
  affected.forEach((key: string): void => {
    const actual: SearchSourceElement | undefined = currentMap.get(key);
    const expected: SearchSourceElement | undefined = sourceMap.get(key);
    if (expected === undefined) {
      if (actual !== undefined) {
        throw new Error('page mutation expected an absent source element');
      }
    } else if (actual === undefined || !sameBytes(actual.payload, expected.payload)) {
      throw new Error('page mutation source element mismatch');
    }
    currentMap.delete(key);
  });
  targetMap.forEach((element: SearchSourceElement, key: string): void => {
    if (currentMap.has(key)) {
      throw new Error('page mutation target collides with an unchanged element');
    }
    currentMap.set(key, element);
  });
  const result: SearchSourceElement[] = [];
  for (const ref of targetOrder) {
    const key: string = identity(ref);
    const element: SearchSourceElement | undefined = currentMap.get(key);
    if (element === undefined) {
      throw new Error('page mutation target order references a missing element');
    }
    result.push(element);
    currentMap.delete(key);
  }
  if (currentMap.size !== 0) {
    throw new Error('page mutation target order omits elements');
  }
  return result;
}

export function replayPageMutationAtRevision(current: SearchSourceElement[], currentRevision: number,
  mutation: PageMutationOpPayload, forward: boolean): PageMutationReplayResult {
  const expectedRevision: number = forward ? mutation.fromRevision : mutation.toRevision;
  if (!Number.isSafeInteger(currentRevision) || currentRevision !== expectedRevision) {
    throw new Error('page mutation source revision mismatch');
  }
  return {
    revision: forward ? mutation.toRevision : mutation.fromRevision,
    elements: replayPageMutation(current, mutation, forward),
  };
}

export function encodePageMutationOp(mutation: PageMutationOpPayload): Uint8Array {
  validateMutation(mutation);
  const pageId: Uint8Array = encodeOperationString(mutation.pageId, 'page mutation page ID');
  const beforeOrder: EncodedOrderRef[] = encodeOrder(mutation.beforeOrder);
  const afterOrder: EncodedOrderRef[] = encodeOrder(mutation.afterOrder);
  const beforeElements: EncodedElement[] = encodeElements(mutation.beforeElements);
  const afterElements: EncodedElement[] = encodeElements(mutation.afterElements);
  let size: number = MAGIC.length + 4 + pageId.length + 8 + 8;
  size += encodedOrderSize(beforeOrder) + encodedOrderSize(afterOrder);
  size += encodedElementSize(beforeElements) + encodedElementSize(afterElements);
  if (size > MAX_OPERATION_BYTES) {
    throw new Error('page mutation operation is too large');
  }
  const writer = new BinaryOpWriter(new Uint8Array(size));
  writer.writeBytes(new Uint8Array(MAGIC));
  writer.writeSizedBytes(pageId);
  writer.writeSafeInteger(mutation.fromRevision);
  writer.writeSafeInteger(mutation.toRevision);
  writeOrder(writer, beforeOrder);
  writeOrder(writer, afterOrder);
  writeElements(writer, beforeElements);
  writeElements(writer, afterElements);
  return writer.finish();
}

export function decodePageMutationOp(bytes: Uint8Array): PageMutationOpPayload {
  const reader = new BinaryOpReader(bytes);
  reader.readMagic(MAGIC);
  const mutation: PageMutationOpPayload = {
    pageId: reader.readString(),
    fromRevision: reader.readSafeInteger(),
    toRevision: reader.readSafeInteger(),
    beforeOrder: readOrder(reader),
    afterOrder: readOrder(reader),
    beforeElements: readElements(reader),
    afterElements: readElements(reader),
  };
  if (!reader.atEnd()) {
    throw new Error('page mutation operation has trailing bytes');
  }
  validateMutation(mutation);
  return mutation;
}

function validateMutation(mutation: PageMutationOpPayload): void {
  if (mutation.pageId.length === 0 || !Number.isSafeInteger(mutation.fromRevision) ||
    mutation.fromRevision < 0 || !Number.isSafeInteger(mutation.toRevision) ||
    mutation.toRevision !== mutation.fromRevision + 1) {
    throw new Error('page mutation identity or revision is invalid');
  }
  validateOrder(mutation.beforeOrder, 'before order');
  validateOrder(mutation.afterOrder, 'after order');
  const beforeMap: Map<string, SearchSourceElement> = elementMap(mutation.beforeElements, 'before elements');
  const afterMap: Map<string, SearchSourceElement> = elementMap(mutation.afterElements, 'after elements');
  const beforeOrderKeys: Set<string> = orderKeys(mutation.beforeOrder);
  const afterOrderKeys: Set<string> = orderKeys(mutation.afterOrder);
  beforeMap.forEach((_value: SearchSourceElement, key: string): void => {
    if (!beforeOrderKeys.has(key)) {
      throw new Error('before mutation element is absent from before order');
    }
  });
  afterMap.forEach((_value: SearchSourceElement, key: string): void => {
    if (!afterOrderKeys.has(key)) {
      throw new Error('after mutation element is absent from after order');
    }
  });
  const affectedKeys: Set<string> = new Set<string>();
  beforeMap.forEach((_value: SearchSourceElement, key: string): void => { affectedKeys.add(key); });
  afterMap.forEach((_value: SearchSourceElement, key: string): void => { affectedKeys.add(key); });
  affectedKeys.forEach((key: string): void => {
    const before: SearchSourceElement | undefined = beforeMap.get(key);
    const after: SearchSourceElement | undefined = afterMap.get(key);
    const existedBefore: boolean = beforeOrderKeys.has(key);
    const existsAfter: boolean = afterOrderKeys.has(key);
    if ((before === undefined && existedBefore) || (after === undefined && existsAfter) ||
      (before !== undefined && !existedBefore) || (after !== undefined && !existsAfter)) {
      throw new Error('mutation affected elements contradict page order membership');
    }
    if (before !== undefined && after !== undefined && sameBytes(before.payload, after.payload)) {
      throw new Error('mutation redundantly stores an unchanged element');
    }
  });
  beforeOrderKeys.forEach((key: string): void => {
    if (!afterOrderKeys.has(key) && !beforeMap.has(key)) {
      throw new Error('removed order identity has no before element');
    }
  });
  afterOrderKeys.forEach((key: string): void => {
    if (!beforeOrderKeys.has(key) && !afterMap.has(key)) {
      throw new Error('inserted order identity has no after element');
    }
  });
}

function validateOrder(order: PageMutationOrderRef[], label: string): void {
  if (order.length > MAX_OPERATION_ELEMENTS) {
    throw new Error(`${label} exceeds element budget`);
  }
  const keys: Set<string> = new Set<string>();
  for (const ref of order) {
    if (ref.elementId.length === 0 || !Number.isSafeInteger(ref.kind) || ref.kind < 0) {
      throw new Error(`${label} contains an invalid identity`);
    }
    const key: string = identity(ref);
    if (keys.has(key)) {
      throw new Error(`${label} contains a duplicate identity`);
    }
    keys.add(key);
  }
}

function elementMap(elements: SearchSourceElement[], label: string): Map<string, SearchSourceElement> {
  if (elements.length > MAX_OPERATION_ELEMENTS) {
    throw new Error(`${label} exceeds element budget`);
  }
  const result: Map<string, SearchSourceElement> = new Map<string, SearchSourceElement>();
  for (const element of elements) {
    if (element.elementId.length === 0 || !Number.isSafeInteger(element.kind) || element.kind < 0 ||
      element.payload.length > MAX_OPERATION_BYTES) {
      throw new Error(`${label} contains an invalid element`);
    }
    const key: string = identity(element);
    if (result.has(key)) {
      throw new Error(`${label} contains a duplicate identity`);
    }
    result.set(key, element);
  }
  return result;
}

function identity(value: PageMutationOrderRef | SearchSourceElement): string {
  return `${value.kind}:${value.elementId.length}:${value.elementId}`;
}

function sameOrder(left: PageMutationOrderRef[], right: PageMutationOrderRef[]): boolean {
  if (left.length !== right.length) {
    return false;
  }
  for (let i: number = 0; i < left.length; i++) {
    if (left[i].kind !== right[i].kind || left[i].elementId !== right[i].elementId) {
      return false;
    }
  }
  return true;
}

function orderKeys(order: PageMutationOrderRef[]): Set<string> {
  const result: Set<string> = new Set<string>();
  for (const ref of order) {
    result.add(identity(ref));
  }
  return result;
}

function encodeOrder(order: PageMutationOrderRef[]): EncodedOrderRef[] {
  return order.map((value: PageMutationOrderRef): EncodedOrderRef => ({
    value: value,
    id: encodeOperationString(value.elementId, 'page mutation order ID'),
  }));
}

function encodeElements(elements: SearchSourceElement[]): EncodedElement[] {
  return elements.map((value: SearchSourceElement): EncodedElement => ({
    value: value,
    id: encodeOperationString(value.elementId, 'page mutation element ID'),
  }));
}

function encodedOrderSize(order: EncodedOrderRef[]): number {
  let size: number = 4;
  for (const ref of order) {
    size += 4 + 4 + ref.id.length;
  }
  return size;
}

function encodedElementSize(elements: EncodedElement[]): number {
  let size: number = 4;
  for (const element of elements) {
    size += 4 + 4 + element.id.length + 4 + element.value.payload.length;
  }
  return size;
}

function writeOrder(writer: BinaryOpWriter, order: EncodedOrderRef[]): void {
  writer.writeUint32(order.length);
  for (const ref of order) {
    writer.writeUint32(ref.value.kind);
    writer.writeSizedBytes(ref.id);
  }
}

function writeElements(writer: BinaryOpWriter, elements: EncodedElement[]): void {
  writer.writeUint32(elements.length);
  for (const element of elements) {
    writer.writeUint32(element.value.kind);
    writer.writeSizedBytes(element.id);
    writer.writeSizedBytes(element.value.payload);
  }
}

function readOrder(reader: BinaryOpReader): PageMutationOrderRef[] {
  const count: number = reader.readUint32();
  if (count > MAX_OPERATION_ELEMENTS) {
    throw new Error('page mutation order exceeds element budget');
  }
  const result: PageMutationOrderRef[] = [];
  for (let i: number = 0; i < count; i++) {
    result.push({ kind: reader.readUint32(), elementId: reader.readString() });
  }
  return result;
}

function readElements(reader: BinaryOpReader): SearchSourceElement[] {
  const count: number = reader.readUint32();
  if (count > MAX_OPERATION_ELEMENTS) {
    throw new Error('page mutation elements exceed element budget');
  }
  const result: SearchSourceElement[] = [];
  for (let i: number = 0; i < count; i++) {
    result.push({
      kind: reader.readUint32(),
      elementId: reader.readString(),
      payload: reader.readSizedBytes(MAX_OPERATION_BYTES),
    });
  }
  return result;
}
