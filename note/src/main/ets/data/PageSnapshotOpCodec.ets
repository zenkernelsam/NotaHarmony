import {
  BinaryOpReader, BinaryOpWriter, encodeOperationString, MAX_OPERATION_BYTES,
  MAX_OPERATION_ELEMENTS,
} from './BinaryOpCodec';

const MAGIC: number[] = [0x4E, 0x50, 0x53, 0x31]; // NPS1

export interface PageSnapshotOpElement {
  elementId: string;
  kind: number;
  payload: Uint8Array;
}

export interface PageSnapshotOpPayload {
  pageId: string;
  revision: number;
  elements: PageSnapshotOpElement[];
}

export function encodePageSnapshotOp(value: PageSnapshotOpPayload): Uint8Array {
  validateSnapshot(value);
  const pageId: Uint8Array = encodeOperationString(value.pageId, 'page snapshot page ID');
  const ids: Uint8Array[] = [];
  let size: number = MAGIC.length + 4 + pageId.length + 8 + 4;
  for (const element of value.elements) {
    const id: Uint8Array = encodeOperationString(element.elementId, 'page snapshot element ID');
    ids.push(id);
    size += 4 + id.length + 4 + 4 + element.payload.length;
  }
  if (size > MAX_OPERATION_BYTES) {
    throw new Error('page snapshot operation is too large');
  }
  const result = new Uint8Array(size);
  const writer = new BinaryOpWriter(result);
  writer.writeBytes(new Uint8Array(MAGIC));
  writer.writeSizedBytes(pageId);
  writer.writeSafeInteger(value.revision);
  writer.writeUint32(value.elements.length);
  for (let i: number = 0; i < value.elements.length; i++) {
    writer.writeSizedBytes(ids[i]);
    writer.writeUint32(value.elements[i].kind);
    writer.writeSizedBytes(value.elements[i].payload);
  }
  return writer.finish();
}

export function decodePageSnapshotOp(bytes: Uint8Array): PageSnapshotOpPayload {
  const reader = new BinaryOpReader(bytes);
  reader.readMagic(MAGIC);
  const pageId: string = reader.readString();
  const revision: number = reader.readSafeInteger();
  const count: number = reader.readUint32();
  if (count > MAX_OPERATION_ELEMENTS) {
    throw new Error('page snapshot element count exceeds budget');
  }
  const elements: PageSnapshotOpElement[] = [];
  for (let i: number = 0; i < count; i++) {
    const elementId: string = reader.readString();
    const kind: number = reader.readUint32();
    const payload: Uint8Array = reader.readSizedBytes(MAX_OPERATION_BYTES);
    elements.push({ elementId: elementId, kind: kind, payload: payload });
  }
  if (!reader.atEnd()) {
    throw new Error('page snapshot operation has trailing bytes');
  }
  const result: PageSnapshotOpPayload = { pageId: pageId, revision: revision, elements: elements };
  validateSnapshot(result);
  return result;
}

function validateSnapshot(value: PageSnapshotOpPayload): void {
  if (value.pageId.length === 0) {
    throw new Error('page snapshot page ID is empty');
  }
  if (!Number.isSafeInteger(value.revision) || value.revision < 0) {
    throw new Error('page snapshot revision is invalid');
  }
  if (value.elements.length > MAX_OPERATION_ELEMENTS) {
    throw new Error('page snapshot element count exceeds budget');
  }
  for (const element of value.elements) {
    if (element.elementId.length === 0 || !Number.isSafeInteger(element.kind) || element.kind < 0) {
      throw new Error('page snapshot element identity is invalid');
    }
    if (element.payload.length > MAX_OPERATION_BYTES) {
      throw new Error('page snapshot element payload is too large');
    }
  }
}
