import { util } from '@kit.ArkTS';
import {
  OperationIdentity, OriginalSequenceIdentity, validateOperationIdentity,
  validateOriginalSequenceIdentity,
} from './OperationIdentity';
import {
  ORIGINAL_INSERT_CHAR_PAYLOAD_TYPE, ORIGINAL_INSERT_STRING_PAYLOAD_TYPE,
  ORIGINAL_REMOVE_CHAR_PAYLOAD_TYPE, ORIGINAL_REMOVE_CHARS_PAYLOAD_TYPE,
  ORIGINAL_REVIVE_CHARS_PAYLOAD_TYPE,
} from './OriginalInsertTextOperation';

export const MAX_ORIGINAL_INSERT_STRING_BYTES: number = 1048576;
const MAX_TEXT_VISIBILITY_LOCATIONS: number = 1048576;

export enum OriginalInsertStringValueStatus {
  VALID = 0,
  EMPTY = 1,
  INVALID_UNICODE = 2,
  TOO_LARGE = 3,
}

export interface OriginalInsertStringValueInspection {
  status: OriginalInsertStringValueStatus;
  byteLength: number;
}

export interface EncodedOriginalTextOperation {
  payloadType: number;
  payload: Uint8Array;
}

export function encodeOriginalInitialInsertString(block: OperationIdentity,
  value: string): Uint8Array {
  validateOperationIdentity(block);
  const encoded: Uint8Array = new util.TextEncoder().encodeInto(value);
  if (inspectEncodedOriginalInsertString(value, encoded).status !==
    OriginalInsertStringValueStatus.VALID) {
    throw new Error('original INSERT_STRING value is invalid');
  }
  const table: number = 16;
  const objectSize: number = 16;
  const vector: number = table + objectSize;
  const bytes: Uint8Array = new Uint8Array(vector + 4 + encoded.length);
  writeU32(bytes, 0, table);
  writeVtable(bytes, 4, objectSize, [0, 4, 8]);
  writeU32(bytes, table, table - 4);
  writeU32(bytes, table + 4, vector - (table + 4));
  writeU16(bytes, table + 8, block.siteId);
  writeU32(bytes, table + 12, block.timestamp);
  writeU32(bytes, vector, encoded.length);
  bytes.set(encoded, vector + 4);
  return bytes;
}

export function encodeOriginalTextInsertion(location: OriginalSequenceIdentity | null,
  value: string, block: OperationIdentity): EncodedOriginalTextOperation {
  validateOperationIdentity(block);
  if (location !== null) {
    validateOriginalSequenceIdentity(location);
  }
  const scalars: number[] = strictStringScalars(value);
  if (scalars.length === 0) {
    throw new Error('original text insertion is empty');
  }
  if (scalars.length === 1) {
    return { payloadType: ORIGINAL_INSERT_CHAR_PAYLOAD_TYPE,
      payload: encodeInsertChar(location, scalars[0], block) };
  }
  return { payloadType: ORIGINAL_INSERT_STRING_PAYLOAD_TYPE,
    payload: encodeInsertString(location, value, block) };
}

export function encodeOriginalTextVisibility(locations: OriginalSequenceIdentity[],
  block: OperationIdentity, visible: boolean): EncodedOriginalTextOperation {
  validateOperationIdentity(block);
  if (locations.length === 0 || locations.length > MAX_TEXT_VISIBILITY_LOCATIONS) {
    throw new Error('original text visibility has an invalid target count');
  }
  const unique: Set<string> = new Set<string>();
  for (const location of locations) {
    validateOriginalSequenceIdentity(location);
    const key: string = `${location.timestamp}:${location.siteId}:${location.index}`;
    if (unique.has(key)) {
      throw new Error('original text visibility repeats a character');
    }
    unique.add(key);
  }
  if (!visible && locations.length === 1) {
    return { payloadType: ORIGINAL_REMOVE_CHAR_PAYLOAD_TYPE,
      payload: encodeSingleVisibility(locations[0], block) };
  }
  return { payloadType: visible ? ORIGINAL_REVIVE_CHARS_PAYLOAD_TYPE :
    ORIGINAL_REMOVE_CHARS_PAYLOAD_TYPE,
    payload: encodeVisibilityVector(locations, block) };
}

function encodeInsertChar(location: OriginalSequenceIdentity | null, scalar: number,
  block: OperationIdentity): Uint8Array {
  const anchored: boolean = location !== null;
  const table: number = 16;
  const objectSize: number = anchored ? 28 : 16;
  const bytes: Uint8Array = new Uint8Array(table + objectSize);
  writeU32(bytes, 0, table);
  writeVtable(bytes, 4, objectSize, anchored ? [4, 16, 20] : [0, 4, 8]);
  writeU32(bytes, table, table - 4);
  if (location !== null) {
    writeSequence(bytes, table + 4, location);
    writeU32(bytes, table + 16, scalar);
    writeOperationIdentity(bytes, table + 20, block);
  } else {
    writeU32(bytes, table + 4, scalar);
    writeOperationIdentity(bytes, table + 8, block);
  }
  return bytes;
}

function encodeInsertString(location: OriginalSequenceIdentity | null, value: string,
  block: OperationIdentity): Uint8Array {
  const encoded: Uint8Array = new util.TextEncoder().encodeInto(value);
  if (inspectEncodedOriginalInsertString(value, encoded).status !==
    OriginalInsertStringValueStatus.VALID) {
    throw new Error('original INSERT_STRING value is invalid');
  }
  const anchored: boolean = location !== null;
  const table: number = 16;
  const objectSize: number = anchored ? 28 : 16;
  const vector: number = table + objectSize;
  const bytes: Uint8Array = new Uint8Array(vector + 4 + encoded.length);
  writeU32(bytes, 0, table);
  writeVtable(bytes, 4, objectSize, anchored ? [4, 16, 20] : [0, 4, 8]);
  writeU32(bytes, table, table - 4);
  if (location !== null) {
    writeSequence(bytes, table + 4, location);
    writeU32(bytes, table + 16, vector - (table + 16));
    writeOperationIdentity(bytes, table + 20, block);
  } else {
    writeU32(bytes, table + 4, vector - (table + 4));
    writeOperationIdentity(bytes, table + 8, block);
  }
  writeU32(bytes, vector, encoded.length);
  bytes.set(encoded, vector + 4);
  return bytes;
}

/**
 * Shared preflight for every caller that will eventually emit the original
 * INSERT_STRING payload. JavaScript string length counts UTF-16 code units;
 * the wire contract instead accepts at most 1 MiB of strict round-trippable
 * UTF-8. Keeping this inspection beside the encoder prevents planner and
 * persistence gates from drifting away from the actual payload boundary.
 */
export function inspectOriginalInsertStringValue(value: string):
  OriginalInsertStringValueInspection {
  const encoded: Uint8Array = new util.TextEncoder().encodeInto(value);
  return inspectEncodedOriginalInsertString(value, encoded);
}

function inspectEncodedOriginalInsertString(value: string, encoded: Uint8Array):
  OriginalInsertStringValueInspection {
  if (encoded.length === 0) {
    return { status: OriginalInsertStringValueStatus.EMPTY, byteLength: 0 };
  }
  if (util.TextDecoder.create('utf-8').decodeToString(encoded) !== value) {
    return {
      status: OriginalInsertStringValueStatus.INVALID_UNICODE,
      byteLength: encoded.length,
    };
  }
  if (encoded.length > MAX_ORIGINAL_INSERT_STRING_BYTES) {
    return { status: OriginalInsertStringValueStatus.TOO_LARGE, byteLength: encoded.length };
  }
  return { status: OriginalInsertStringValueStatus.VALID, byteLength: encoded.length };
}

function encodeSingleVisibility(location: OriginalSequenceIdentity,
  block: OperationIdentity): Uint8Array {
  const table: number = 12;
  const objectSize: number = 24;
  const bytes: Uint8Array = new Uint8Array(table + objectSize);
  writeU32(bytes, 0, table);
  writeVtable(bytes, 4, objectSize, [4, 16]);
  writeU32(bytes, table, table - 4);
  writeSequence(bytes, table + 4, location);
  writeOperationIdentity(bytes, table + 16, block);
  return bytes;
}

function encodeVisibilityVector(locations: OriginalSequenceIdentity[],
  block: OperationIdentity): Uint8Array {
  const table: number = 12;
  const objectSize: number = 16;
  const vector: number = table + objectSize;
  const bytes: Uint8Array = new Uint8Array(vector + 4 + locations.length * 12);
  writeU32(bytes, 0, table);
  writeVtable(bytes, 4, objectSize, [4, 8]);
  writeU32(bytes, table, table - 4);
  writeU32(bytes, table + 4, vector - (table + 4));
  writeOperationIdentity(bytes, table + 8, block);
  writeU32(bytes, vector, locations.length);
  for (let index: number = 0; index < locations.length; index++) {
    writeSequence(bytes, vector + 4 + index * 12, locations[index]);
  }
  return bytes;
}

function strictStringScalars(value: string): number[] {
  const result: number[] = [];
  for (let index: number = 0; index < value.length;) {
    const scalar: number = value.codePointAt(index) as number;
    if (scalar < 0 || scalar > 0x10FFFF || (scalar >= 0xD800 && scalar <= 0xDFFF)) {
      throw new Error('original text insertion contains invalid Unicode');
    }
    result.push(scalar);
    index += scalar > 0xFFFF ? 2 : 1;
  }
  return result;
}

function writeSequence(bytes: Uint8Array, offset: number,
  identity: OriginalSequenceIdentity): void {
  writeU16(bytes, offset, identity.siteId);
  writeU16(bytes, offset + 2, 0);
  writeU32(bytes, offset + 4, identity.timestamp);
  writeU32(bytes, offset + 8, identity.index);
}

function writeOperationIdentity(bytes: Uint8Array, offset: number,
  identity: OperationIdentity): void {
  writeU16(bytes, offset, identity.siteId);
  writeU16(bytes, offset + 2, 0);
  writeU32(bytes, offset + 4, identity.timestamp);
}

function writeVtable(bytes: Uint8Array, offset: number, objectSize: number,
  fields: number[]): void {
  writeU16(bytes, offset, 4 + fields.length * 2);
  writeU16(bytes, offset + 2, objectSize);
  for (let index: number = 0; index < fields.length; index++) {
    writeU16(bytes, offset + 4 + index * 2, fields[index]);
  }
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
