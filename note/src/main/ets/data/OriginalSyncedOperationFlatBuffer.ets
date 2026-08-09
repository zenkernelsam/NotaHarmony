export const ORIGINAL_PAYLOAD_TYPE_MIN: number = 1;
export const ORIGINAL_PAYLOAD_TYPE_MAX: number = 31;

export interface OriginalSyncedOperationEnvelope {
  timestamp: number;
  siteId: number;
  clientTime: string;
  serverTime: string;
  payloadType: number;
  payloadTypeKnown: boolean;
}

export interface OriginalSyncedOperationCandidate {
  timestamp: number;
  siteId: number;
  clientTime: string;
  serverTime: string;
  payloadType: number;
  rawOperation: Uint8Array;
}

interface FlatBufferTable {
  table: number;
  vtable: number;
  vtableSize: number;
  objectSize: number;
}

export class OriginalFlatBufferTableReader {
  private bytes: Uint8Array;
  private table: FlatBufferTable;

  private constructor(bytes: Uint8Array, tablePosition: number, vtable: number,
    vtableSize: number, objectSize: number) {
    this.bytes = bytes;
    this.table = {
      table: tablePosition, vtable: vtable, vtableSize: vtableSize, objectSize: objectSize,
    };
  }

  hasField(field: number): boolean {
    this.validateFieldNumber(field);
    return fieldOffset(this.bytes, this.table, field) !== 0;
  }

  readUint8(field: number, defaultValue: number = 0): number {
    const offset: number = this.readFieldOffset(field);
    if (offset === 0) {
      return defaultValue;
    }
    requireObjectBytes(this.table, offset, 1, `field ${field}`);
    return this.bytes[this.table.table + offset];
  }

  readUint32(field: number, defaultValue: number): number {
    const offset: number = this.readFieldOffset(field);
    if (offset === 0) {
      return defaultValue;
    }
    requireObjectBytes(this.table, offset, 4, `field ${field}`);
    return readU32(this.bytes, this.table.table + offset);
  }

  readInlineSequence(field: number): number[] | null {
    const offset: number = this.readFieldOffset(field);
    if (offset === 0) {
      return null;
    }
    requireObjectBytes(this.table, offset, 12, `sequence field ${field}`);
    const position: number = this.table.table + offset;
    return [readU32(this.bytes, position + 4), readU16(this.bytes, position),
      readU32(this.bytes, position + 8)];
  }

  private readFieldOffset(field: number): number {
    this.validateFieldNumber(field);
    return fieldOffset(this.bytes, this.table, field);
  }

  private validateFieldNumber(field: number): void {
    if (!Number.isSafeInteger(field) || field < 0 || field > 1024) {
      throw new Error('FlatBuffer field number is invalid');
    }
  }

  static fromPayload(bytes: Uint8Array, expectedPayloadType: number): OriginalFlatBufferTableReader {
    if (!Number.isSafeInteger(expectedPayloadType) ||
      expectedPayloadType < ORIGINAL_PAYLOAD_TYPE_MIN || expectedPayloadType > ORIGINAL_PAYLOAD_TYPE_MAX) {
      throw new Error('expected original payload type is invalid');
    }
    const root: FlatBufferTable = readFlatBufferRoot(bytes);
    const typeOffset: number = fieldOffset(bytes, root, 4);
    const payloadOffset: number = fieldOffset(bytes, root, 5);
    const payloadType: number = typeOffset === 0 ? 0 : bytes[root.table + typeOffset];
    if (payloadType !== expectedPayloadType || payloadOffset === 0) {
      throw new Error('synced FlatBuffer operation has the wrong payload type');
    }
    requireObjectBytes(root, payloadOffset, 4, 'payload');
    const pointer: number = root.table + payloadOffset;
    const relative: number = readU32(bytes, pointer);
    if (relative < 4 || pointer + relative > bytes.length - 4) {
      throw new Error('synced FlatBuffer payload offset is invalid');
    }
    const payload: FlatBufferTable = readFlatBufferTable(bytes, pointer + relative);
    return new OriginalFlatBufferTableReader(bytes, payload.table, payload.vtable,
      payload.vtableSize, payload.objectSize);
  }
}

const CRC32_TABLE: number[] = buildCrc32Table();

export function parseOriginalSyncedOperationEnvelope(bytes: Uint8Array): OriginalSyncedOperationEnvelope {
  const root: FlatBufferTable = readFlatBufferRoot(bytes);
  const idOffset: number = requireField(bytes, root, 0, 8, 'id');
  const clientOffset: number = fieldOffset(bytes, root, 1);
  const serverOffset: number = fieldOffset(bytes, root, 2);
  const payloadTypeOffset: number = fieldOffset(bytes, root, 4);
  const payloadOffset: number = fieldOffset(bytes, root, 5);
  if (clientOffset !== 0) {
    requireObjectBytes(root, clientOffset, 8, 'clientTime');
  }
  if (serverOffset === 0) {
    throw new Error('synced FlatBuffer operation has no serverTime');
  }
  requireObjectBytes(root, serverOffset, 8, 'serverTime');
  const payloadType: number = payloadTypeOffset === 0 ? 0 : bytes[root.table + payloadTypeOffset];
  if (payloadType !== 0) {
    if (payloadOffset === 0) {
      throw new Error('synced FlatBuffer operation has a payload type without a payload');
    }
    requireObjectBytes(root, payloadOffset, 4, 'payload');
    const pointer: number = root.table + payloadOffset;
    const relative: number = readU32(bytes, pointer);
    if (relative < 4 || pointer + relative > bytes.length - 4) {
      throw new Error('synced FlatBuffer payload offset is invalid');
    }
    readFlatBufferTable(bytes, pointer + relative);
  }
  return {
    siteId: readU16(bytes, root.table + idOffset),
    timestamp: readU32(bytes, root.table + idOffset + 4),
    clientTime: clientOffset === 0 ? '0' : unsignedLongBytesToDecimal(bytes, root.table + clientOffset),
    serverTime: unsignedLongBytesToDecimal(bytes, root.table + serverOffset),
    payloadType: payloadType,
    payloadTypeKnown: payloadType >= ORIGINAL_PAYLOAD_TYPE_MIN && payloadType <= ORIGINAL_PAYLOAD_TYPE_MAX,
  };
}

export function validateOriginalSyncedOperation(operation: OriginalSyncedOperationCandidate):
  OriginalSyncedOperationEnvelope {
  const envelope: OriginalSyncedOperationEnvelope =
    parseOriginalSyncedOperationEnvelope(operation.rawOperation);
  if (envelope.timestamp !== operation.timestamp || envelope.siteId !== operation.siteId ||
    envelope.clientTime !== operation.clientTime || envelope.serverTime !== operation.serverTime ||
    envelope.payloadType !== operation.payloadType) {
    throw new Error('synced FlatBuffer metadata does not match its persisted envelope');
  }
  return envelope;
}

export function validateFlatBufferRoot(bytes: Uint8Array): void {
  readFlatBufferRoot(bytes);
}

export function readOriginalPayloadTable(bytes: Uint8Array,
  expectedPayloadType: number): OriginalFlatBufferTableReader {
  return OriginalFlatBufferTableReader.fromPayload(bytes, expectedPayloadType);
}

export function crc32Signed(bytes: Uint8Array): number {
  let crc: number = 0xFFFFFFFF;
  for (let index: number = 0; index < bytes.length; index++) {
    crc = (crc >>> 8) ^ CRC32_TABLE[(crc ^ bytes[index]) & 0xFF];
  }
  return (crc ^ 0xFFFFFFFF) | 0;
}

function buildCrc32Table(): number[] {
  const table: number[] = [];
  for (let value: number = 0; value < 256; value++) {
    let current: number = value;
    for (let bit: number = 0; bit < 8; bit++) {
      current = (current & 1) === 0 ? current >>> 1 : 0xEDB88320 ^ (current >>> 1);
    }
    table.push(current >>> 0);
  }
  return table;
}

function readFlatBufferRoot(bytes: Uint8Array): FlatBufferTable {
  if (bytes.length < 8) {
    throw new Error('FlatBuffer root is truncated');
  }
  const rootOffset: number = readU32(bytes, 0);
  if (rootOffset < 4 || rootOffset > bytes.length - 4) {
    throw new Error('FlatBuffer root offset is invalid');
  }
  return readFlatBufferTable(bytes, rootOffset);
}

function readFlatBufferTable(bytes: Uint8Array, table: number): FlatBufferTable {
  requireRange(bytes, table, 4, 'FlatBuffer table');
  const vtableDistance: number = readI32(bytes, table);
  if (vtableDistance <= 0 || vtableDistance > table) {
    throw new Error('FlatBuffer vtable distance is invalid');
  }
  const vtable: number = table - vtableDistance;
  requireRange(bytes, vtable, 4, 'FlatBuffer vtable');
  const vtableSize: number = readU16(bytes, vtable);
  const objectSize: number = readU16(bytes, vtable + 2);
  if (vtableSize < 4 || (vtableSize & 1) !== 0 || objectSize < 4) {
    throw new Error('FlatBuffer table header is invalid');
  }
  requireRange(bytes, vtable, vtableSize, 'FlatBuffer vtable');
  requireRange(bytes, table, objectSize, 'FlatBuffer object');
  for (let entry: number = vtable + 4; entry < vtable + vtableSize; entry += 2) {
    const offset: number = readU16(bytes, entry);
    if (offset !== 0 && (offset < 4 || offset >= objectSize)) {
      throw new Error('FlatBuffer field offset is outside its object');
    }
  }
  return { table: table, vtable: vtable, vtableSize: vtableSize, objectSize: objectSize };
}

function fieldOffset(bytes: Uint8Array, table: FlatBufferTable, field: number): number {
  const entry: number = table.vtable + 4 + field * 2;
  return entry + 2 <= table.vtable + table.vtableSize ? readU16(bytes, entry) : 0;
}

function requireField(bytes: Uint8Array, table: FlatBufferTable, field: number,
  size: number, name: string): number {
  const offset: number = fieldOffset(bytes, table, field);
  if (offset === 0) {
    throw new Error(`synced FlatBuffer operation has no required ${name}`);
  }
  requireObjectBytes(table, offset, size, name);
  return offset;
}

function requireObjectBytes(table: FlatBufferTable, offset: number, size: number, name: string): void {
  if (offset < 4 || offset + size > table.objectSize) {
    throw new Error(`synced FlatBuffer ${name} is truncated`);
  }
}

function requireRange(bytes: Uint8Array, offset: number, size: number, name: string): void {
  if (!Number.isSafeInteger(offset) || !Number.isSafeInteger(size) || offset < 0 || size < 0 ||
    offset > bytes.length || size > bytes.length - offset) {
    throw new Error(`${name} is outside its byte buffer`);
  }
}

function readU16(bytes: Uint8Array, offset: number): number {
  requireRange(bytes, offset, 2, 'uint16');
  return bytes[offset] + bytes[offset + 1] * 0x100;
}

function readU32(bytes: Uint8Array, offset: number): number {
  requireRange(bytes, offset, 4, 'uint32');
  return bytes[offset] + bytes[offset + 1] * 0x100 + bytes[offset + 2] * 0x10000 +
    bytes[offset + 3] * 0x1000000;
}

function readI32(bytes: Uint8Array, offset: number): number {
  const value: number = readU32(bytes, offset);
  return value >= 0x80000000 ? value - 0x100000000 : value;
}

function unsignedLongBytesToDecimal(bytes: Uint8Array, offset: number): string {
  requireRange(bytes, offset, 8, 'uint64');
  const digits: number[] = [0];
  for (let byteIndex: number = 7; byteIndex >= 0; byteIndex--) {
    let carry: number = bytes[offset + byteIndex];
    for (let digitIndex: number = 0; digitIndex < digits.length; digitIndex++) {
      const value: number = digits[digitIndex] * 256 + carry;
      digits[digitIndex] = value % 10;
      carry = Math.floor(value / 10);
    }
    while (carry > 0) {
      digits.push(carry % 10);
      carry = Math.floor(carry / 10);
    }
  }
  let result: string = '';
  for (let index: number = digits.length - 1; index >= 0; index--) {
    result += digits[index].toString();
  }
  return result;
}
