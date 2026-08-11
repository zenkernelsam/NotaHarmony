import {
  OperationIdentity, OriginalSequenceIdentity, validateOperationIdentity,
  validateOriginalSequenceIdentity,
} from './OperationIdentity';
import {
  OriginalFlatBufferTableReader, readOriginalInlineFloat32, readOriginalPayloadTable,
} from './OriginalSyncedOperationFlatBuffer';

export const ORIGINAL_CREATE_COMMENT_PAYLOAD_TYPE: number = 30;
export const ORIGINAL_MODIFY_COMMENT_PAYLOAD_TYPE: number = 31;
const MAX_COMMENT_TEXT_BYTES: number = 128 * 1024 * 1024;
const MAX_COMMENT_ENTITY_ANCHOR_COUNT: number = 10000;

export enum OriginalCommentAnchorType {
  CANVAS = 1,
  TEXT = 2,
  ENTITY = 3,
  REPLY = 4,
}

export interface OriginalCommentPoint {
  x: number;
  y: number;
}

export interface OriginalCommentCanvasAnchor {
  type: OriginalCommentAnchorType.CANVAS;
  page: OriginalSequenceIdentity;
  origin: OriginalCommentPoint;
}

export interface OriginalCommentTextSelection {
  anchor: OriginalSequenceIdentity | null;
  focus: OriginalSequenceIdentity | null;
}

export interface OriginalCommentTextAnchor {
  type: OriginalCommentAnchorType.TEXT;
  textField: OperationIdentity | null;
  selection: OriginalCommentTextSelection;
}

export interface OriginalCommentEntityAnchor {
  type: OriginalCommentAnchorType.ENTITY;
  entities: OperationIdentity[];
}

export interface OriginalCommentReplyAnchor {
  type: OriginalCommentAnchorType.REPLY;
  root: OperationIdentity;
}

export type OriginalCommentAnchor = OriginalCommentCanvasAnchor | OriginalCommentTextAnchor |
  OriginalCommentEntityAnchor | OriginalCommentReplyAnchor;

export interface OriginalCreateCommentPayload {
  anchor: OriginalCommentAnchor;
  text: string;
}

export interface OriginalNullableStringChange {
  value: string | null;
}

export interface OriginalNullableBooleanChange {
  value: boolean | null;
}

export interface OriginalModifyCommentPayload {
  comment: OperationIdentity;
  anchor: OriginalCommentCanvasAnchor | null;
  text: OriginalNullableStringChange | null;
  resolved: OriginalNullableBooleanChange | null;
}

export function decodeOriginalCreateComment(bytes: Uint8Array): OriginalCreateCommentPayload {
  return decodeOriginalCreateCommentTable(
    readOriginalPayloadTable(bytes, ORIGINAL_CREATE_COMMENT_PAYLOAD_TYPE));
}

export function decodeOriginalCreateCommentTable(
  table: OriginalFlatBufferTableReader): OriginalCreateCommentPayload {
  rejectFieldsFrom(table, 3, 'CreateComment payload');
  const rawAnchorType: number = table.readUint8(0, 0);
  if (rawAnchorType < OriginalCommentAnchorType.CANVAS ||
    rawAnchorType > OriginalCommentAnchorType.REPLY) {
    // The generated reader maps unknown union bytes to NONE; tl2 validation rejects NONE.
    throw new Error('CreateComment has no valid anchor');
  }
  const anchorType: OriginalCommentAnchorType = rawAnchorType as OriginalCommentAnchorType;
  let anchor: OriginalCommentAnchor;
  if (anchorType === OriginalCommentAnchorType.CANVAS) {
    anchor = decodeCanvasAnchor(requireIndirectStruct(table, 1, 20, 'CreateComment canvas anchor'));
  } else if (anchorType === OriginalCommentAnchorType.TEXT) {
    anchor = decodeTextAnchor(requireTable(table, 1, 'CreateComment text anchor'));
  } else if (anchorType === OriginalCommentAnchorType.ENTITY) {
    anchor = decodeEntityAnchor(requireTable(table, 1, 'CreateComment entity anchor'));
  } else {
    anchor = {
      type: OriginalCommentAnchorType.REPLY,
      root: readIdentity(requireIndirectStruct(table, 1, 8, 'CreateComment reply anchor'), 0),
    };
  }
  const text: string | null = table.readUtf8String(2, true, MAX_COMMENT_TEXT_BYTES);
  if (text === null || text.length === 0) {
    throw new Error('CreateComment text is empty');
  }
  return { anchor: anchor, text: text };
}

export function decodeOriginalModifyComment(bytes: Uint8Array): OriginalModifyCommentPayload {
  return decodeOriginalModifyCommentTable(
    readOriginalPayloadTable(bytes, ORIGINAL_MODIFY_COMMENT_PAYLOAD_TYPE));
}

export function decodeOriginalModifyCommentTable(
  table: OriginalFlatBufferTableReader): OriginalModifyCommentPayload {
  rejectFieldsFrom(table, 4, 'ModifyComment payload');
  const comment: OperationIdentity = readRequiredInlineIdentity(table, 0, 'ModifyComment comment');
  const anchorBytes: Uint8Array | null = table.readInlineBytes(1, 20);
  const anchor: OriginalCommentCanvasAnchor | null = anchorBytes === null ? null :
    decodeCanvasAnchor(anchorBytes);
  const textTable: OriginalFlatBufferTableReader | null = table.readTable(2);
  const resolvedTable: OriginalFlatBufferTableReader | null = table.readTable(3);
  if (anchor === null && textTable === null && resolvedTable === null) {
    throw new Error('ModifyComment changes no field');
  }
  return {
    comment: comment,
    anchor: anchor,
    text: textTable === null ? null : decodeStringChange(textTable),
    resolved: resolvedTable === null ? null : decodeBooleanChange(resolvedTable),
  };
}

export function preflightOriginalCommentTable(table: OriginalFlatBufferTableReader,
  payloadType: number): string | null {
  try {
    if (payloadType === ORIGINAL_CREATE_COMMENT_PAYLOAD_TYPE) {
      decodeOriginalCreateCommentTable(table);
    } else if (payloadType === ORIGINAL_MODIFY_COMMENT_PAYLOAD_TYPE) {
      decodeOriginalModifyCommentTable(table);
    } else {
      return 'COMMENT_PAYLOAD_TYPE_UNSUPPORTED';
    }
    return null;
  } catch (_error) {
    return 'MALFORMED_COMMENT_PAYLOAD';
  }
}

function decodeCanvasAnchor(bytes: Uint8Array): OriginalCommentCanvasAnchor {
  const page: OriginalSequenceIdentity = readSequence(bytes, 0);
  const x: number = readOriginalInlineFloat32(bytes, 12);
  const y: number = readOriginalInlineFloat32(bytes, 16);
  if (!Number.isFinite(x) || !Number.isFinite(y)) {
    throw new Error('Comment canvas anchor origin is not finite');
  }
  return { type: OriginalCommentAnchorType.CANVAS, page: page, origin: { x: x, y: y } };
}

function decodeTextAnchor(table: OriginalFlatBufferTableReader): OriginalCommentTextAnchor {
  rejectFieldsFrom(table, 2, 'Comment text anchor');
  const rawTextField: Uint8Array | null = table.readInlineBytes(0, 8);
  const selectionTable: OriginalFlatBufferTableReader =
    requireTable(table, 1, 'Comment text selection');
  rejectFieldsFrom(selectionTable, 2, 'Comment text selection');
  return {
    type: OriginalCommentAnchorType.TEXT,
    textField: rawTextField === null ? null : readIdentity(rawTextField, 0),
    selection: {
      anchor: readOptionalSequence(selectionTable, 0),
      focus: readOptionalSequence(selectionTable, 1),
    },
  };
}

function decodeEntityAnchor(table: OriginalFlatBufferTableReader): OriginalCommentEntityAnchor {
  rejectFieldsFrom(table, 1, 'Comment entity anchor');
  const rows: number[][] =
    table.readInlineOperationIdentityVector(0, MAX_COMMENT_ENTITY_ANCHOR_COUNT);
  const entities: OperationIdentity[] = [];
  const seen: Set<string> = new Set<string>();
  for (const row of rows) {
    const identity: OperationIdentity = { timestamp: row[0], siteId: row[1] };
    validateOperationIdentity(identity);
    const key: string = `${identity.timestamp}:${identity.siteId}`;
    if (!seen.has(key)) {
      seen.add(key);
      entities.push(identity);
    }
  }
  return { type: OriginalCommentAnchorType.ENTITY, entities: entities };
}

function decodeStringChange(table: OriginalFlatBufferTableReader): OriginalNullableStringChange {
  rejectFieldsFrom(table, 1, 'ModifyComment text setter');
  return { value: table.readUtf8String(0, false, MAX_COMMENT_TEXT_BYTES) };
}

function decodeBooleanChange(table: OriginalFlatBufferTableReader): OriginalNullableBooleanChange {
  rejectFieldsFrom(table, 1, 'ModifyComment resolved setter');
  if (!table.hasField(0)) {
    return { value: null };
  }
  // z1d.j() follows the generated FlatBuffer boolean reader: every non-zero byte is true.
  return { value: table.readUint8(0, 0) !== 0 };
}

function readOptionalSequence(table: OriginalFlatBufferTableReader,
  field: number): OriginalSequenceIdentity | null {
  const row: number[] | null = table.readInlineSequence(field);
  if (row === null) {
    return null;
  }
  const identity: OriginalSequenceIdentity = {
    timestamp: row[0], siteId: row[1], index: row[2],
  };
  validateOriginalSequenceIdentity(identity);
  return identity;
}

function readRequiredInlineIdentity(table: OriginalFlatBufferTableReader, field: number,
  name: string): OperationIdentity {
  const bytes: Uint8Array | null = table.readInlineBytes(field, 8);
  if (bytes === null) {
    throw new Error(`${name} is missing`);
  }
  return readIdentity(bytes, 0);
}

function readIdentity(bytes: Uint8Array, offset: number): OperationIdentity {
  const identity: OperationIdentity = {
    timestamp: readU32(bytes, offset + 4), siteId: readU16(bytes, offset),
  };
  validateOperationIdentity(identity);
  return identity;
}

function readSequence(bytes: Uint8Array, offset: number): OriginalSequenceIdentity {
  const identity: OriginalSequenceIdentity = {
    timestamp: readU32(bytes, offset + 4), siteId: readU16(bytes, offset),
    index: readU32(bytes, offset + 8),
  };
  validateOriginalSequenceIdentity(identity);
  return identity;
}

function requireTable(table: OriginalFlatBufferTableReader, field: number,
  name: string): OriginalFlatBufferTableReader {
  const value: OriginalFlatBufferTableReader | null = table.readTable(field);
  if (value === null) {
    throw new Error(`${name} is missing`);
  }
  return value;
}

function requireIndirectStruct(table: OriginalFlatBufferTableReader, field: number,
  size: number, name: string): Uint8Array {
  const value: Uint8Array | null = table.readIndirectInlineBytes(field, size);
  if (value === null) {
    throw new Error(`${name} is missing`);
  }
  return value;
}

function rejectFieldsFrom(table: OriginalFlatBufferTableReader, first: number,
  name: string): void {
  for (let field: number = first; field <= 1024; field++) {
    if (table.hasField(field)) {
      throw new Error(`${name} has an unknown field`);
    }
  }
}

function readU16(bytes: Uint8Array, offset: number): number {
  return bytes[offset] | bytes[offset + 1] << 8;
}

function readU32(bytes: Uint8Array, offset: number): number {
  return (bytes[offset] + bytes[offset + 1] * 0x100 +
    bytes[offset + 2] * 0x10000 + bytes[offset + 3] * 0x1000000) >>> 0;
}
