import { util } from '@kit.ArkTS';

const MAGIC: number[] = [0x4E, 0x50, 0x53, 0x31]; // NPS1
const MAX_ELEMENTS: number = 100000;
const MAX_STRING_BYTES: number = 1024 * 1024;
const MAX_PAYLOAD_BYTES: number = 64 * 1024 * 1024;

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
  const encoder = new util.TextEncoder();
  const pageId: Uint8Array = encoder.encodeInto(value.pageId);
  if (pageId.length > MAX_STRING_BYTES) {
    throw new Error('page snapshot page ID is too large');
  }
  const ids: Uint8Array[] = [];
  let size: number = MAGIC.length + 4 + pageId.length + 8 + 4;
  for (const element of value.elements) {
    const id: Uint8Array = encoder.encodeInto(element.elementId);
    if (id.length > MAX_STRING_BYTES) {
      throw new Error('page snapshot element ID is too large');
    }
    ids.push(id);
    size += 4 + id.length + 4 + 4 + element.payload.length;
  }
  if (size > MAX_PAYLOAD_BYTES) {
    throw new Error('page snapshot operation is too large');
  }
  const result = new Uint8Array(size);
  const writer = new ByteWriter(result);
  writer.writeBytes(new Uint8Array(MAGIC));
  writer.writeSizedBytes(pageId);
  writer.writeSafeInteger(value.revision);
  writer.writeUint32(value.elements.length);
  for (let i: number = 0; i < value.elements.length; i++) {
    writer.writeSizedBytes(ids[i]);
    writer.writeUint32(value.elements[i].kind);
    writer.writeSizedBytes(value.elements[i].payload);
  }
  return result;
}

export function decodePageSnapshotOp(bytes: Uint8Array): PageSnapshotOpPayload {
  if (bytes.length > MAX_PAYLOAD_BYTES) {
    throw new Error('page snapshot operation is too large');
  }
  const reader = new ByteReader(bytes);
  for (const expected of MAGIC) {
    if (reader.readByte() !== expected) {
      throw new Error('invalid page snapshot operation magic');
    }
  }
  const pageId: string = reader.readString(MAX_STRING_BYTES);
  const revision: number = reader.readSafeInteger();
  const count: number = reader.readUint32();
  if (count > MAX_ELEMENTS) {
    throw new Error('page snapshot element count exceeds budget');
  }
  const elements: PageSnapshotOpElement[] = [];
  for (let i: number = 0; i < count; i++) {
    const elementId: string = reader.readString(MAX_STRING_BYTES);
    const kind: number = reader.readUint32();
    const payload: Uint8Array = reader.readSizedBytes(MAX_PAYLOAD_BYTES);
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
  if (value.elements.length > MAX_ELEMENTS) {
    throw new Error('page snapshot element count exceeds budget');
  }
  for (const element of value.elements) {
    if (element.elementId.length === 0 || !Number.isSafeInteger(element.kind) || element.kind < 0) {
      throw new Error('page snapshot element identity is invalid');
    }
    if (element.payload.length > MAX_PAYLOAD_BYTES) {
      throw new Error('page snapshot element payload is too large');
    }
  }
}

class ByteWriter {
  private output: Uint8Array;
  private offset: number = 0;

  constructor(output: Uint8Array) {
    this.output = output;
  }

  writeByte(value: number): void {
    this.output[this.offset++] = value & 0xFF;
  }

  writeUint32(value: number): void {
    if (!Number.isSafeInteger(value) || value < 0 || value > 0xFFFFFFFF) {
      throw new Error('uint32 value is out of range');
    }
    this.writeByte(value);
    this.writeByte(value / 0x100);
    this.writeByte(value / 0x10000);
    this.writeByte(value / 0x1000000);
  }

  writeSafeInteger(value: number): void {
    const low: number = value % 0x100000000;
    const high: number = Math.floor(value / 0x100000000);
    this.writeUint32(low);
    this.writeUint32(high);
  }

  writeSizedBytes(value: Uint8Array): void {
    this.writeUint32(value.length);
    this.writeBytes(value);
  }

  writeBytes(value: Uint8Array): void {
    this.output.set(value, this.offset);
    this.offset += value.length;
  }
}

class ByteReader {
  private input: Uint8Array;
  private offset: number = 0;

  constructor(input: Uint8Array) {
    this.input = input;
  }

  readByte(): number {
    this.require(1);
    return this.input[this.offset++];
  }

  readUint32(): number {
    this.require(4);
    const value: number = this.input[this.offset] + this.input[this.offset + 1] * 0x100 +
      this.input[this.offset + 2] * 0x10000 + this.input[this.offset + 3] * 0x1000000;
    this.offset += 4;
    return value;
  }

  readSafeInteger(): number {
    const low: number = this.readUint32();
    const high: number = this.readUint32();
    const value: number = low + high * 0x100000000;
    if (!Number.isSafeInteger(value)) {
      throw new Error('integer exceeds JavaScript safe range');
    }
    return value;
  }

  readSizedBytes(maxLength: number): Uint8Array {
    const length: number = this.readUint32();
    if (length > maxLength) {
      throw new Error('length exceeds page snapshot budget');
    }
    this.require(length);
    const value: Uint8Array = this.input.slice(this.offset, this.offset + length);
    this.offset += length;
    return value;
  }

  readString(maxLength: number): string {
    const bytes: Uint8Array = this.readSizedBytes(maxLength);
    const decoder = util.TextDecoder.create('utf-8');
    const value: string = decoder.decodeToString(bytes);
    const encoded: Uint8Array = new util.TextEncoder().encodeInto(value);
    if (!sameBytes(bytes, encoded)) {
      throw new Error('invalid UTF-8 in page snapshot operation');
    }
    return value;
  }

  atEnd(): boolean {
    return this.offset === this.input.length;
  }

  private require(length: number): void {
    if (length < 0 || this.offset + length > this.input.length) {
      throw new Error('truncated page snapshot operation');
    }
  }
}

function sameBytes(left: Uint8Array, right: Uint8Array): boolean {
  if (left.length !== right.length) {
    return false;
  }
  for (let i: number = 0; i < left.length; i++) {
    if (left[i] !== right[i]) {
      return false;
    }
  }
  return true;
}
