import { util } from '@kit.ArkTS';
import {
  RichTextCharacterStyle, RichTextCharacterStyleRun, RichTextParagraphStyle,
  RichTextParagraphStyleRun, TextBlockElement,
} from '../core/model/ElementTypes';
import {
  OperationIdentity, OriginalSequenceIdentity, validateOperationIdentity,
} from './OperationIdentity';
import {
  ORIGINAL_MODIFY_PARAGRAPH_STYLE_PAYLOAD_TYPE, ORIGINAL_MODIFY_STYLE_PAYLOAD_TYPE,
} from './OriginalRichTextStyleOperation';
import { OriginalTextBoundaryType } from './OriginalRichTextStyleState';

const MAX_STYLE_STRING_BYTES: number = 65536;

export interface EncodedOriginalRichTextStyleOperation {
  payloadType: number;
  payload: Uint8Array;
}

interface EncodedField {
  field: number;
  kind: number;
  boolValue?: boolean;
  numberValue?: number;
  stringValue?: string;
}

const FIELD_BOOL: number = 0;
const FIELD_FLOAT: number = 1;
const FIELD_COLOR: number = 2;
const FIELD_STRING: number = 3;
const FIELD_ENUM: number = 4;

export function encodeOriginalInitialRichTextStyles(block: OperationIdentity,
  insertion: OperationIdentity, text: TextBlockElement): EncodedOriginalRichTextStyleOperation[] {
  validateOperationIdentity(block);
  validateOperationIdentity(insertion);
  const length: number = strictCodePointLength(text.richText);
  const characterRuns: RichTextCharacterStyleRun[] = text.characterStyleRuns ?? [];
  const paragraphRuns: RichTextParagraphStyleRun[] = text.paragraphStyleRuns ?? [];
  validateRuns(characterRuns, length, false);
  validateRuns(paragraphRuns, length, true);
  const result: EncodedOriginalRichTextStyleOperation[] = [];
  for (const run of characterRuns) {
    result.push({
      payloadType: ORIGINAL_MODIFY_STYLE_PAYLOAD_TYPE,
      payload: encodeCharacterStyle(block, insertion, length, run),
    });
  }
  for (const run of paragraphRuns) {
    result.push({
      payloadType: ORIGINAL_MODIFY_PARAGRAPH_STYLE_PAYLOAD_TYPE,
      payload: encodeParagraphStyle(block, insertion, length, run),
    });
  }
  return result;
}

function encodeCharacterStyle(block: OperationIdentity, insertion: OperationIdentity,
  length: number, run: RichTextCharacterStyleRun): Uint8Array {
  const fields: EncodedField[] = characterFields(run.style);
  if (fields.length === 0) {
    throw new Error('original character style run has no recognized attributes');
  }
  const builder: ForwardFlatBufferBuilder = new ForwardFlatBufferBuilder();
  const offsets: number[] = new Array<number>(15).fill(0);
  offsets[0] = 4;
  offsets[1] = 20;
  offsets[2] = 36;
  for (const field of fields) {
    offsets[field.field] = 44 + (field.field - 3) * 4;
  }
  const table: number = builder.table(offsets, 88);
  builder.boundary(table + 4, characterIdentity(insertion, run.start),
    OriginalTextBoundaryType.BEFORE);
  if (run.end === length) {
    builder.boundary(table + 20, { timestamp: 0, siteId: 0xFFFF, index: 0 },
      OriginalTextBoundaryType.END_OF_DOC);
  } else {
    builder.boundary(table + 20, characterIdentity(insertion, run.end),
      OriginalTextBoundaryType.BEFORE);
  }
  builder.identity(table + 36, block);
  for (const field of fields) {
    builder.pointer(table + offsets[field.field], encodeWrapper(builder, field));
  }
  return builder.finish(table);
}

function encodeParagraphStyle(block: OperationIdentity, insertion: OperationIdentity,
  length: number, run: RichTextParagraphStyleRun): Uint8Array {
  if (run.style.isChecked !== undefined) {
    throw new Error('original initial checkbox state requires UpdateCheckbox replay');
  }
  const fields: EncodedField[] = paragraphFields(run.style);
  if (fields.length === 0) {
    throw new Error('original paragraph style run has no recognized attributes');
  }
  const builder: ForwardFlatBufferBuilder = new ForwardFlatBufferBuilder();
  const offsets: number[] = new Array<number>(10).fill(0);
  offsets[0] = 4;
  offsets[1] = run.end === length ? 0 : 16;
  for (const field of fields) {
    offsets[field.field] = field.field <= 5 ? 28 + (field.field - 2) * 4 :
      52 + (field.field - 8) * 4;
  }
  offsets[7] = 44;
  const table: number = builder.table(offsets, 60);
  builder.sequence(table + 4, characterIdentity(insertion, run.start));
  if (run.end !== length) {
    builder.sequence(table + 16, characterIdentity(insertion, run.end));
  }
  builder.identity(table + 44, block);
  for (const field of fields) {
    builder.pointer(table + offsets[field.field], encodeWrapper(builder, field));
  }
  return builder.finish(table);
}

function characterFields(style: RichTextCharacterStyle): EncodedField[] {
  const result: EncodedField[] = [];
  addBool(result, 3, style.bold);
  addBool(result, 4, style.italic);
  addBool(result, 5, style.underline);
  addColor(result, 6, style.highlightColor);
  addString(result, 7, style.familyName, true);
  addFloat(result, 8, style.fontSize, true);
  addColor(result, 9, style.foregroundColor);
  addString(result, 10, style.link, false);
  addBool(result, 11, style.superscript);
  addBool(result, 12, style.subscript);
  addBool(result, 13, style.strikethrough);
  if (style.superscript === true && style.subscript === true) {
    throw new Error('original character style cannot be superscript and subscript');
  }
  return result;
}

function paragraphFields(style: RichTextParagraphStyle): EncodedField[] {
  const result: EncodedField[] = [];
  addEnum(result, 2, style.indentLevel, 0, 7);
  addEnum(result, 3, style.alignment, 1, 3);
  if (style.lineSpacing !== undefined && ![0, 1, 1.5, 2].some(
    (value: number): boolean => Math.abs(value - (style.lineSpacing as number)) < 0.01)) {
    throw new Error('original paragraph line spacing is invalid');
  }
  addFloat(result, 4, style.lineSpacing, false);
  addEnum(result, 5, style.decoratorStyle, 0, 5);
  addString(result, 8, style.programmingLanguage, false);
  addEnum(result, 9, style.writingDirection, 0, 1);
  return result;
}

function addBool(result: EncodedField[], field: number, value: boolean | undefined): void {
  if (value === undefined) {
    return;
  }
  if (typeof value !== 'boolean') {
    throw new Error('original rich-text boolean is invalid');
  }
  result.push({ field: field, kind: FIELD_BOOL, boolValue: value });
}

function addFloat(result: EncodedField[], field: number, value: number | undefined,
  positive: boolean): void {
  if (value === undefined) {
    return;
  }
  if (!Number.isFinite(value) || (positive && value <= 0) || Math.fround(value) !== value) {
    throw new Error('original rich-text float is invalid');
  }
  result.push({ field: field, kind: FIELD_FLOAT, numberValue: value });
}

function addColor(result: EncodedField[], field: number, value: number | undefined): void {
  if (value === undefined) {
    return;
  }
  if (!Number.isSafeInteger(value) || value < -2147483648 || value > 2147483647) {
    throw new Error('original rich-text color is invalid');
  }
  result.push({ field: field, kind: FIELD_COLOR, numberValue: value });
}

function addString(result: EncodedField[], field: number, value: string | undefined,
  nonEmpty: boolean): void {
  if (value === undefined) {
    return;
  }
  const bytes: Uint8Array = new util.TextEncoder().encodeInto(value);
  if ((nonEmpty && value.length === 0) || bytes.length > MAX_STYLE_STRING_BYTES ||
    util.TextDecoder.create('utf-8').decodeToString(bytes) !== value) {
    throw new Error('original rich-text string is invalid');
  }
  result.push({ field: field, kind: FIELD_STRING, stringValue: value });
}

function addEnum(result: EncodedField[], field: number, value: number | undefined,
  minimum: number, maximum: number): void {
  if (value === undefined) {
    return;
  }
  if (!Number.isSafeInteger(value) || value < minimum || value > maximum) {
    throw new Error('original rich-text enum is invalid');
  }
  result.push({ field: field, kind: FIELD_ENUM, numberValue: value });
}

function encodeWrapper(builder: ForwardFlatBufferBuilder, field: EncodedField): number {
  const table: number = builder.table([4], 8);
  if (field.kind === FIELD_BOOL) {
    builder.uint8(table + 4, field.boolValue === true ? 1 : 0);
  } else if (field.kind === FIELD_FLOAT) {
    builder.float32(table + 4, field.numberValue as number);
  } else if (field.kind === FIELD_COLOR) {
    builder.color(table + 4, field.numberValue as number);
  } else if (field.kind === FIELD_ENUM) {
    builder.uint8(table + 4, field.numberValue as number);
  } else {
    builder.pointer(table + 4, builder.string(field.stringValue as string));
  }
  return table;
}

function validateRuns(runs: Array<RichTextCharacterStyleRun | RichTextParagraphStyleRun>,
  length: number, paragraph: boolean): void {
  let end: number = 0;
  for (const run of runs) {
    if (!Number.isSafeInteger(run.start) || !Number.isSafeInteger(run.end) ||
      run.start < end || run.start < 0 || run.end <= run.start || run.end > length ||
      run.style === null || typeof run.style !== 'object') {
      throw new Error('original initial rich-text runs are invalid');
    }
    if (paragraph && (run.style as RichTextParagraphStyle).isChecked !== undefined) {
      throw new Error('original initial checkbox state requires UpdateCheckbox replay');
    }
    end = run.end;
  }
}

function strictCodePointLength(value: string): number {
  let result: number = 0;
  for (let index: number = 0; index < value.length;) {
    const scalar: number = value.codePointAt(index) as number;
    if (scalar < 0 || scalar > 0x10FFFF || (scalar >= 0xD800 && scalar <= 0xDFFF)) {
      throw new Error('original initial rich-text string is invalid');
    }
    result++;
    index += scalar > 0xFFFF ? 2 : 1;
  }
  return result;
}

function characterIdentity(insertion: OperationIdentity, index: number): OriginalSequenceIdentity {
  return { timestamp: insertion.timestamp, siteId: insertion.siteId, index: index };
}

class ForwardFlatBufferBuilder {
  private bytes: Uint8Array = new Uint8Array(1024);
  private cursor: number = 4;

  table(offsets: number[], objectSize: number): number {
    const vtable: number = this.cursor;
    const vtableSize: number = 4 + offsets.length * 2;
    this.ensure(vtableSize + objectSize + 4);
    this.cursor += vtableSize;
    this.align(4);
    const table: number = this.cursor;
    this.cursor += objectSize;
    this.ensure(0);
    this.uint16(vtable, vtableSize);
    this.uint16(vtable + 2, objectSize);
    for (let index: number = 0; index < offsets.length; index++) {
      this.uint16(vtable + 4 + index * 2, offsets[index]);
    }
    this.uint32(table, table - vtable);
    return table;
  }

  string(value: string): number {
    const encoded: Uint8Array = new util.TextEncoder().encodeInto(value);
    this.align(4);
    const vector: number = this.cursor;
    this.cursor += 5 + encoded.length;
    this.ensure(0);
    this.uint32(vector, encoded.length);
    this.bytes.set(encoded, vector + 4);
    this.bytes[vector + 4 + encoded.length] = 0;
    return vector;
  }

  pointer(slot: number, target: number): void {
    this.uint32(slot, target - slot);
  }

  sequence(offset: number, value: OriginalSequenceIdentity): void {
    this.uint16(offset, value.siteId);
    this.uint32(offset + 4, value.timestamp);
    this.uint32(offset + 8, value.index);
  }

  boundary(offset: number, value: OriginalSequenceIdentity,
    type: OriginalTextBoundaryType): void {
    this.sequence(offset, value);
    this.uint8(offset + 12, type);
  }

  identity(offset: number, value: OperationIdentity): void {
    this.uint16(offset, value.siteId);
    this.uint32(offset + 4, value.timestamp);
  }

  color(offset: number, value: number): void {
    this.uint8(offset, value >>> 16 & 0xFF);
    this.uint8(offset + 1, value >>> 8 & 0xFF);
    this.uint8(offset + 2, value & 0xFF);
    this.uint8(offset + 3, value >>> 24 & 0xFF);
  }

  float32(offset: number, value: number): void {
    this.ensureOffset(offset + 4);
    new DataView(this.bytes.buffer).setFloat32(offset, value, true);
  }

  uint8(offset: number, value: number): void {
    this.ensureOffset(offset + 1);
    this.bytes[offset] = value & 0xFF;
  }

  uint16(offset: number, value: number): void {
    this.ensureOffset(offset + 2);
    this.bytes[offset] = value & 0xFF;
    this.bytes[offset + 1] = value >>> 8 & 0xFF;
  }

  uint32(offset: number, value: number): void {
    this.ensureOffset(offset + 4);
    this.bytes[offset] = value & 0xFF;
    this.bytes[offset + 1] = value >>> 8 & 0xFF;
    this.bytes[offset + 2] = value >>> 16 & 0xFF;
    this.bytes[offset + 3] = value >>> 24 & 0xFF;
  }

  finish(root: number): Uint8Array {
    this.uint32(0, root);
    return this.bytes.slice(0, this.cursor);
  }

  private align(value: number): void {
    while ((this.cursor & (value - 1)) !== 0) {
      this.cursor++;
    }
    this.ensure(0);
  }

  private ensure(extra: number): void {
    this.ensureOffset(this.cursor + extra);
  }

  private ensureOffset(required: number): void {
    if (required <= this.bytes.length) {
      return;
    }
    let capacity: number = this.bytes.length;
    while (capacity < required) {
      capacity *= 2;
    }
    const grown: Uint8Array = new Uint8Array(capacity);
    grown.set(this.bytes);
    this.bytes = grown;
  }
}
