import { relationalStore } from '@kit.ArkData';
import { util } from '@kit.ArkTS';
import { TextBlockElement } from '../core/model/ElementTypes';
import { PageElementKind } from '../core/model/PageElementOrder';
import {
  encodeOriginalSequenceId, OperationIdentity, OriginalSequenceIdentity,
  validateOperationIdentity, validateOriginalSequenceIdentity,
} from './OperationIdentity';
import {
  OriginalInsertTextOperationApplier, OriginalInsertTextPayload, StoredCharacter, StoredTextTarget,
} from './OriginalInsertTextOperation';
import {
  emptyOriginalTextStyleAttributes, materializeOriginalTextStyles,
  OriginalTextBoundary, OriginalTextBoundaryType, OriginalTextStyleAttributes,
  readOriginalTextStyleOperations, StoredOriginalTextStyleOperation,
} from './OriginalRichTextStyleState';
import { OriginalFlatBufferTableReader, readOriginalPayloadTable } from
  './OriginalSyncedOperationFlatBuffer';
import { decodePersistedElement, encodePersistedElement, PersistedElement } from './StrokePersistence';
import {
  StoredSyncedOperation, SyncedOperationApplier, SyncedOperationApplyResult,
} from './SyncedOperationInbox';

export const ORIGINAL_MODIFY_STYLE_PAYLOAD_TYPE: number = 12;
export const ORIGINAL_MODIFY_PARAGRAPH_STYLE_PAYLOAD_TYPE: number = 13;
export const ORIGINAL_CLEAR_STYLE_PAYLOAD_TYPE: number = 14;
const ROOT: OriginalSequenceIdentity = { timestamp: 0, siteId: 0xFFFF, index: 0 };
const MAX_STYLE_STRING_BYTES: number = 65536;

export interface OriginalRichTextStylePayload {
  start: OriginalTextBoundary;
  end: OriginalTextBoundary;
  textField: OperationIdentity | null;
  paragraph: boolean;
  clearAll: boolean;
  attributes: OriginalTextStyleAttributes;
}

interface BoolField { present: boolean; value: boolean | null; }
interface NumberField { present: boolean; value: number | null; }
interface StringField { present: boolean; value: string | null; }

export function decodeOriginalRichTextStyle(bytes: Uint8Array,
  payloadType: number): OriginalRichTextStylePayload {
  if (payloadType !== ORIGINAL_MODIFY_STYLE_PAYLOAD_TYPE &&
    payloadType !== ORIGINAL_MODIFY_PARAGRAPH_STYLE_PAYLOAD_TYPE &&
    payloadType !== ORIGINAL_CLEAR_STYLE_PAYLOAD_TYPE) {
    throw new Error('original rich-text style payload type is unsupported');
  }
  const table: OriginalFlatBufferTableReader = readOriginalPayloadTable(bytes, payloadType);
  if (payloadType === ORIGINAL_MODIFY_STYLE_PAYLOAD_TYPE) {
    return decodeCharacterStyle(table);
  }
  if (payloadType === ORIGINAL_MODIFY_PARAGRAPH_STYLE_PAYLOAD_TYPE) {
    return decodeParagraphStyle(table);
  }
  return decodeClearStyle(table);
}

export class OriginalRichTextStyleOperationApplier implements SyncedOperationApplier {
  private textState: OriginalInsertTextOperationApplier = new OriginalInsertTextOperationApplier();

  supports(payloadType: number): boolean {
    return payloadType === ORIGINAL_MODIFY_STYLE_PAYLOAD_TYPE ||
      payloadType === ORIGINAL_MODIFY_PARAGRAPH_STYLE_PAYLOAD_TYPE ||
      payloadType === ORIGINAL_CLEAR_STYLE_PAYLOAD_TYPE;
  }

  async apply(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation): Promise<SyncedOperationApplyResult> {
    let payload: OriginalRichTextStylePayload;
    try {
      payload = decodeOriginalRichTextStyle(operation.rawOperation, operation.payloadType);
    } catch (_error) {
      return { deferredReason: 'MALFORMED_RICH_TEXT_STYLE_PAYLOAD' };
    }
    if (!payload.clearAll && !hasRecognizedAttributes(payload.attributes, payload.paragraph)) {
      // Android 1.0.3 logs and skips code-only or otherwise unrecognized style payloads.
      return { deferredReason: null };
    }
    const block: OperationIdentity | null = await this.resolveBlock(
      store, operation.noteId, payload);
    if (block === null) {
      return { deferredReason: 'RICH_TEXT_STYLE_TARGET_MISSING_OR_CROSS_BLOCK' };
    }
    const targetPayload: OriginalInsertTextPayload = {
      location: null, scalars: [], textField: block,
    };
    const target: StoredTextTarget | null = await this.textState.resolveTarget(
      store, operation, targetPayload);
    if (target === null) {
      return { deferredReason: 'RICH_TEXT_STYLE_TARGET_MISSING' };
    }
    const text: TextBlockElement | null = await this.textState.readText(store, operation.noteId, target);
    const characters: StoredCharacter[] | null = await this.textState.readCharacters(
      store, operation.noteId, block);
    const existing: StoredOriginalTextStyleOperation[] | null =
      await readOriginalTextStyleOperations(store, operation.noteId, block);
    if (text === null || characters === null || existing === null ||
      target.revision >= Number.MAX_SAFE_INTEGER) {
      return { deferredReason: 'RICH_TEXT_STYLE_STATE_DIVERGED' };
    }
    const before = materializeOriginalTextStyles(characters, existing);
    if (before === null || !sameStyles(text, before.characterRuns, before.paragraphRuns)) {
      return { deferredReason: 'RICH_TEXT_STYLE_STATE_DIVERGED' };
    }
    const nextOperation: StoredOriginalTextStyleOperation = {
      identity: { timestamp: operation.timestamp, siteId: operation.siteId },
      paragraph: payload.paragraph, clearAll: payload.clearAll,
      start: payload.start, end: payload.end, attributes: payload.attributes,
    };
    const after = materializeOriginalTextStyles(characters, existing.concat([nextOperation]));
    if (after === null) {
      return { deferredReason: 'RICH_TEXT_STYLE_BOUNDARY_MISSING_OR_REVERSED' };
    }
    await store.insert('original_text_style_operation', {
      'note_id': operation.noteId,
      'block_timestamp': block.timestamp,
      'block_site_id': block.siteId,
      'operation_timestamp': operation.timestamp,
      'operation_site_id': operation.siteId,
      'paragraph': payload.paragraph ? 1 : 0,
      'clear_all': payload.clearAll ? 1 : 0,
      'start_timestamp': payload.start.location.timestamp,
      'start_site_id': payload.start.location.siteId,
      'start_index': payload.start.location.index,
      'start_type': payload.start.type,
      'end_timestamp': payload.end.location.timestamp,
      'end_site_id': payload.end.location.siteId,
      'end_index': payload.end.location.index,
      'end_type': payload.end.type,
      'attributes_json': JSON.stringify(payload.attributes),
    });
    if (sameStyles(text, after.characterRuns, after.paragraphRuns)) {
      return { deferredReason: null };
    }
    const updatedText: TextBlockElement = cloneText(text);
    updatedText.characterStyleRuns = after.characterRuns;
    updatedText.paragraphStyleRuns = after.paragraphRuns;
    const predicates: relationalStore.RdbPredicates = elementPredicates(
      operation.noteId, target, text.id);
    const persisted: PersistedElement = { kind: 'text', data: updatedText };
    const updated: number = await store.update({
      'payload': encodePersistedElement(persisted), 'revision': target.revision + 1,
    }, predicates);
    if (updated !== 1) {
      throw new Error('original rich-text style lost its target snapshot');
    }
    await advanceContentRevision(store, operation.noteId, target);
    return { deferredReason: null };
  }

  private async resolveBlock(store: relationalStore.RdbStore, noteId: string,
    payload: OriginalRichTextStylePayload): Promise<OperationIdentity | null> {
    let block: OperationIdentity | null = payload.textField;
    for (const boundary of [payload.start, payload.end]) {
      if (isDocumentBoundary(boundary)) {
        continue;
      }
      const anchorBlock: OperationIdentity | null = await this.textState.readAnchorBlock(
        store, noteId, boundary.location);
      if (anchorBlock === null || (block !== null && !sameOperation(block, anchorBlock))) {
        return null;
      }
      block = anchorBlock;
    }
    return block;
  }
}

function decodeCharacterStyle(table: OriginalFlatBufferTableReader): OriginalRichTextStylePayload {
  const start: OriginalTextBoundary = readBoundary(table, 0, true);
  const end: OriginalTextBoundary = readBoundary(table, 1, false);
  const attributes: OriginalTextStyleAttributes = emptyOriginalTextStyleAttributes();
  assignBool(attributes, 'bold', readBool(table, 3));
  assignBool(attributes, 'italic', readBool(table, 4));
  assignBool(attributes, 'underline', readBool(table, 5));
  assignNumber(attributes, 'highlightColor', readColor(table, 6));
  assignString(attributes, 'familyName', readString(table, 7));
  assignNumber(attributes, 'fontSize', readFloat(table, 8));
  assignNumber(attributes, 'foregroundColor', readColor(table, 9));
  assignString(attributes, 'link', readString(table, 10));
  assignBool(attributes, 'superscript', readBool(table, 11));
  assignBool(attributes, 'subscript', readBool(table, 12));
  assignBool(attributes, 'strikethrough', readBool(table, 13));
  if (attributes.familyNamePresent && attributes.familyName === '') {
    throw new Error('original rich-text font family is empty');
  }
  if (attributes.fontSizePresent && attributes.fontSize !== null &&
    (!Number.isFinite(attributes.fontSize) || attributes.fontSize <= 0)) {
    throw new Error('original rich-text font size is invalid');
  }
  if (attributes.superscript === true && attributes.subscript === true) {
    throw new Error('original rich-text styles are mutually exclusive');
  }
  return { start: start, end: end, textField: readIdentity(table, 2),
    paragraph: false, clearAll: false, attributes: attributes };
}

function decodeParagraphStyle(table: OriginalFlatBufferTableReader): OriginalRichTextStylePayload {
  if (table.hasField(6)) {
    throw new Error('original paragraph isChecked field is deprecated');
  }
  const startLocation: OriginalSequenceIdentity | null = readSequence(table, 0);
  const endLocation: OriginalSequenceIdentity | null = readSequence(table, 1);
  if (startLocation !== null && endLocation !== null &&
    encodeOriginalSequenceId(startLocation) === encodeOriginalSequenceId(endLocation)) {
    throw new Error('original paragraph style range is empty');
  }
  const attributes: OriginalTextStyleAttributes = emptyOriginalTextStyleAttributes();
  assignNumber(attributes, 'indentLevel', readEnum(table, 2, 0, 7));
  assignNumber(attributes, 'alignment', readEnum(table, 3, 1, 3));
  const spacing: NumberField = readFloat(table, 4);
  if (spacing.present && spacing.value !== null && !isLineSpacing(spacing.value)) {
    throw new Error('original paragraph line spacing is invalid');
  }
  assignNumber(attributes, 'lineSpacing', spacing);
  assignNumber(attributes, 'decoratorStyle', readEnum(table, 5, 0, 5));
  assignString(attributes, 'programmingLanguage', readString(table, 8));
  assignNumber(attributes, 'writingDirection', readEnum(table, 9, 0, 1));
  return {
    start: startLocation === null ? documentBoundary(OriginalTextBoundaryType.START_OF_DOC) :
      { location: startLocation, type: OriginalTextBoundaryType.BEFORE },
    end: endLocation === null ? documentBoundary(OriginalTextBoundaryType.END_OF_DOC) :
      { location: endLocation, type: OriginalTextBoundaryType.BEFORE },
    textField: readIdentity(table, 7), paragraph: true, clearAll: false, attributes: attributes,
  };
}

function decodeClearStyle(table: OriginalFlatBufferTableReader): OriginalRichTextStylePayload {
  return {
    start: readBoundary(table, 0, true), end: readBoundary(table, 1, false),
    textField: readIdentity(table, 3), paragraph: table.readUint8(2, 0) !== 0,
    clearAll: true, attributes: emptyOriginalTextStyleAttributes(),
  };
}

function readBoundary(table: OriginalFlatBufferTableReader, field: number,
  start: boolean): OriginalTextBoundary {
  const bytes: Uint8Array | null = table.readInlineBytes(field, 16);
  if (bytes === null) {
    throw new Error('original rich-text style has no required boundary');
  }
  const location: OriginalSequenceIdentity = {
    timestamp: readU32(bytes, 4), siteId: readU16(bytes, 0), index: readU32(bytes, 8),
  };
  validateOriginalSequenceIdentity(location);
  const type: number = bytes[12];
  if (type < OriginalTextBoundaryType.BEFORE || type > OriginalTextBoundaryType.END_OF_DOC ||
    (start && type !== OriginalTextBoundaryType.BEFORE) ||
    (!start && type === OriginalTextBoundaryType.START_OF_DOC)) {
    throw new Error('original rich-text style boundary type is invalid');
  }
  return { location: location, type: type as OriginalTextBoundaryType };
}

function readSequence(table: OriginalFlatBufferTableReader,
  field: number): OriginalSequenceIdentity | null {
  const raw: number[] | null = table.readInlineSequence(field);
  if (raw === null) {
    return null;
  }
  const value: OriginalSequenceIdentity = { timestamp: raw[0], siteId: raw[1], index: raw[2] };
  validateOriginalSequenceIdentity(value);
  return value;
}

function readIdentity(table: OriginalFlatBufferTableReader, field: number): OperationIdentity | null {
  const bytes: Uint8Array | null = table.readInlineBytes(field, 8);
  if (bytes === null) {
    return null;
  }
  const value: OperationIdentity = { timestamp: readU32(bytes, 4), siteId: readU16(bytes, 0) };
  validateOperationIdentity(value);
  return value;
}

function readBool(table: OriginalFlatBufferTableReader, field: number): BoolField {
  const wrapper: OriginalFlatBufferTableReader | null = table.readTable(field);
  if (wrapper === null) {
    return { present: false, value: null };
  }
  if (!wrapper.hasField(0)) {
    return { present: true, value: null };
  }
  const value: number = wrapper.readUint8(0, 0);
  if (value !== 0 && value !== 1) {
    throw new Error('original SetBool is invalid');
  }
  return { present: true, value: value === 1 };
}

function readFloat(table: OriginalFlatBufferTableReader, field: number): NumberField {
  const wrapper: OriginalFlatBufferTableReader | null = table.readTable(field);
  if (wrapper === null) {
    return { present: false, value: null };
  }
  return { present: true, value: wrapper.hasField(0) ? wrapper.readFloat32(0, 0) : null };
}

function readColor(table: OriginalFlatBufferTableReader, field: number): NumberField {
  const wrapper: OriginalFlatBufferTableReader | null = table.readTable(field);
  if (wrapper === null) {
    return { present: false, value: null };
  }
  const bytes: Uint8Array | null = wrapper.readInlineBytes(0, 4);
  if (bytes === null) {
    return { present: true, value: null };
  }
  return { present: true,
    value: ((bytes[3] << 24) | (bytes[0] << 16) | (bytes[1] << 8) | bytes[2]) | 0 };
}

function readString(table: OriginalFlatBufferTableReader, field: number): StringField {
  const wrapper: OriginalFlatBufferTableReader | null = table.readTable(field);
  if (wrapper === null) {
    return { present: false, value: null };
  }
  const bytes: Uint8Array | null = wrapper.readByteVector(0, false, MAX_STYLE_STRING_BYTES);
  if (bytes === null) {
    return { present: true, value: null };
  }
  return { present: true,
    value: util.TextDecoder.create('utf-8').decodeToString(bytes) };
}

function readEnum(table: OriginalFlatBufferTableReader, field: number,
  minimum: number, maximum: number): NumberField {
  const wrapper: OriginalFlatBufferTableReader | null = table.readTable(field);
  if (wrapper === null) {
    return { present: false, value: null };
  }
  if (!wrapper.hasField(0)) {
    return { present: true, value: null };
  }
  const value: number = wrapper.readUint8(0, 0);
  if (value < minimum || value > maximum) {
    throw new Error('original rich-text style enum is invalid');
  }
  return { present: true, value: value };
}

function assignBool(attributes: OriginalTextStyleAttributes, key: string, field: BoolField): void {
  const values = attributes as Record<string, Object>;
  values[`${key}Present`] = field.present;
  values[key] = field.value;
}

function assignNumber(attributes: OriginalTextStyleAttributes, key: string,
  field: NumberField): void {
  const values = attributes as Record<string, Object>;
  values[`${key}Present`] = field.present;
  values[key] = field.value;
}

function assignString(attributes: OriginalTextStyleAttributes, key: string,
  field: StringField): void {
  const values = attributes as Record<string, Object>;
  values[`${key}Present`] = field.present;
  values[key] = field.value;
}

function hasRecognizedAttributes(attributes: OriginalTextStyleAttributes,
  paragraph: boolean): boolean {
  return paragraph ? attributes.indentLevelPresent || attributes.alignmentPresent ||
    attributes.lineSpacingPresent || attributes.decoratorStylePresent ||
    attributes.programmingLanguagePresent || attributes.writingDirectionPresent :
    attributes.boldPresent || attributes.italicPresent || attributes.underlinePresent ||
    attributes.highlightColorPresent || attributes.familyNamePresent || attributes.fontSizePresent ||
    attributes.foregroundColorPresent || attributes.linkPresent || attributes.superscriptPresent ||
    attributes.subscriptPresent || attributes.strikethroughPresent;
}

function isDocumentBoundary(boundary: OriginalTextBoundary): boolean {
  return boundary.type === OriginalTextBoundaryType.START_OF_DOC ||
    boundary.type === OriginalTextBoundaryType.END_OF_DOC ||
    (boundary.type === OriginalTextBoundaryType.BEFORE && boundary.location.timestamp === 0 &&
      boundary.location.siteId === 0xFFFF && boundary.location.index === 0);
}

function documentBoundary(type: OriginalTextBoundaryType): OriginalTextBoundary {
  return { location: { timestamp: ROOT.timestamp, siteId: ROOT.siteId, index: ROOT.index }, type: type };
}

function sameOperation(left: OperationIdentity, right: OperationIdentity): boolean {
  return left.timestamp === right.timestamp && left.siteId === right.siteId;
}

function sameStyles(text: TextBlockElement, characterRuns: Object[],
  paragraphRuns: Object[]): boolean {
  return JSON.stringify(text.characterStyleRuns ?? []) === JSON.stringify(characterRuns) &&
    JSON.stringify(text.paragraphStyleRuns ?? []) === JSON.stringify(paragraphRuns);
}

function cloneText(text: TextBlockElement): TextBlockElement {
  const persisted: PersistedElement = decodePersistedElement(encodePersistedElement(
    { kind: 'text', data: text }));
  return persisted.data as TextBlockElement;
}

function elementPredicates(noteId: string, target: StoredTextTarget,
  elementId: string): relationalStore.RdbPredicates {
  const predicates = new relationalStore.RdbPredicates(target.table);
  predicates.equalTo('note_id', noteId);
  if (target.archived) {
    predicates.equalTo('page_timestamp', target.page.timestamp);
    predicates.equalTo('page_site_id', target.page.siteId);
    predicates.equalTo('page_index', target.page.index);
  } else {
    predicates.equalTo('page_id', target.pageId);
  }
  predicates.equalTo('element_id', elementId);
  predicates.equalTo('kind', PageElementKind.TEXT);
  return predicates;
}

async function advanceContentRevision(store: relationalStore.RdbStore,
  noteId: string, target: StoredTextTarget): Promise<void> {
  const predicates = new relationalStore.RdbPredicates(target.revisionTable);
  predicates.equalTo('note_id', noteId);
  if (target.archived) {
    predicates.equalTo('page_timestamp', target.page.timestamp);
    predicates.equalTo('page_site_id', target.page.siteId);
    predicates.equalTo('page_index', target.page.index);
  } else {
    predicates.equalTo('page_id', target.pageId);
  }
  predicates.equalTo('content_revision', target.revision);
  const updated: number = await store.update(
    { 'content_revision': target.revision + 1 }, predicates);
  if (updated !== 1) {
    throw new Error('original rich-text style page revision changed concurrently');
  }
}

function isLineSpacing(value: number): boolean {
  return Math.abs(value) < 0.01 || Math.abs(value - 1) < 0.01 ||
    Math.abs(value - 1.5) < 0.01 || Math.abs(value - 2) < 0.01;
}

function readU16(bytes: Uint8Array, offset: number): number {
  return bytes[offset] + bytes[offset + 1] * 0x100;
}

function readU32(bytes: Uint8Array, offset: number): number {
  return bytes[offset] + bytes[offset + 1] * 0x100 + bytes[offset + 2] * 0x10000 +
    bytes[offset + 3] * 0x1000000;
}
