import { relationalStore } from '@kit.ArkData';
import { TextBlockElement } from '../core/model/ElementTypes';
import { cloneTextBlockElement } from '../core/model/TextBlockGeometry';
import { PageElementKind } from '../core/model/PageElementOrder';
import {
  compareOperationIdentity, OperationIdentity, OriginalSequenceIdentity,
  validateOperationIdentity, validateOriginalSequenceIdentity,
} from './OperationIdentity';
import {
  OriginalInsertTextOperationApplier, OriginalInsertTextPayload, StoredCharacter,
  StoredRichTextElement, StoredTextTarget,
} from './OriginalInsertTextOperation';
import {
  materializeOriginalTextStyles, readOriginalCheckboxStates, readOriginalTextStyleOperations,
  StoredOriginalCheckboxState, StoredOriginalTextStyleOperation,
} from './OriginalRichTextStyleState';
import { OriginalFlatBufferTableReader, readOriginalPayloadTable } from
  './OriginalSyncedOperationFlatBuffer';
import {
  StoredSyncedOperation, SyncedOperationApplier, SyncedOperationApplyResult,
} from './SyncedOperationInbox';

export const ORIGINAL_UPDATE_CHECKBOX_PAYLOAD_TYPE: number = 28;

export interface OriginalUpdateCheckboxPayload {
  textField: OperationIdentity;
  location: OriginalSequenceIdentity;
  isChecked: boolean;
}

export function encodeOriginalUpdateCheckbox(payload: OriginalUpdateCheckboxPayload): Uint8Array {
  validateOperationIdentity(payload.textField);
  validateOriginalSequenceIdentity(payload.location);
  if (typeof payload.isChecked !== 'boolean') {
    throw new Error('UpdateCheckbox has an invalid boolean');
  }
  const table: number = 16;
  const objectSize: number = 28;
  const bytes: Uint8Array = new Uint8Array(table + objectSize);
  writeU32(bytes, 0, table);
  writeVtable(bytes, 4, objectSize, [4, 12, payload.isChecked ? 24 : 0]);
  writeU32(bytes, table, table - 4);
  writeIdentity(bytes, table + 4, payload.textField);
  writeSequence(bytes, table + 12, payload.location);
  if (payload.isChecked) {
    bytes[table + 24] = 1;
  }
  return bytes;
}

export function decodeOriginalUpdateCheckbox(bytes: Uint8Array): OriginalUpdateCheckboxPayload {
  return decodeOriginalUpdateCheckboxTable(
    readOriginalPayloadTable(bytes, ORIGINAL_UPDATE_CHECKBOX_PAYLOAD_TYPE));
}

export function decodeOriginalUpdateCheckboxTable(
  table: OriginalFlatBufferTableReader): OriginalUpdateCheckboxPayload {
  for (let field: number = 3; field <= 1024; field++) {
    if (table.hasField(field)) {
      throw new Error('UpdateCheckbox has unsupported fields');
    }
  }
  const targetBytes: Uint8Array | null = table.readInlineBytes(0, 8);
  const rawLocation: number[] | null = table.readInlineSequence(1);
  if (targetBytes === null || rawLocation === null) {
    throw new Error('UpdateCheckbox has no required target or location');
  }
  const textField: OperationIdentity = {
    timestamp: readU32(targetBytes, 4), siteId: readU16(targetBytes, 0),
  };
  const location: OriginalSequenceIdentity = {
    timestamp: rawLocation[0], siteId: rawLocation[1], index: rawLocation[2],
  };
  validateOperationIdentity(textField);
  validateOriginalSequenceIdentity(location);
  const checked: number = table.readUint8(2, 0);
  if (checked !== 0 && checked !== 1) {
    throw new Error('UpdateCheckbox bool is not canonical');
  }
  return { textField: textField, location: location, isChecked: checked === 1 };
}

export class OriginalUpdateCheckboxOperationApplier implements SyncedOperationApplier {
  private textState: OriginalInsertTextOperationApplier = new OriginalInsertTextOperationApplier();

  supports(payloadType: number): boolean {
    return payloadType === ORIGINAL_UPDATE_CHECKBOX_PAYLOAD_TYPE;
  }

  async apply(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation): Promise<SyncedOperationApplyResult> {
    let payload: OriginalUpdateCheckboxPayload;
    try {
      payload = decodeOriginalUpdateCheckbox(operation.rawOperation);
    } catch (_error) {
      return { deferredReason: 'MALFORMED_UPDATE_CHECKBOX_PAYLOAD' };
    }
    return this.applyPayload(store, operation, payload);
  }

  preflightTable(table: OriginalFlatBufferTableReader): string | null {
    try {
      decodeOriginalUpdateCheckboxTable(table);
      return null;
    } catch (_error) {
      return 'MALFORMED_UPDATE_CHECKBOX_PAYLOAD';
    }
  }

  async applyTable(store: relationalStore.RdbStore, operation: StoredSyncedOperation,
    table: OriginalFlatBufferTableReader): Promise<SyncedOperationApplyResult> {
    let payload: OriginalUpdateCheckboxPayload;
    try {
      payload = decodeOriginalUpdateCheckboxTable(table);
    } catch (_error) {
      return { deferredReason: 'MALFORMED_UPDATE_CHECKBOX_PAYLOAD' };
    }
    return this.applyPayload(store, operation, payload);
  }

  private async applyPayload(store: relationalStore.RdbStore, operation: StoredSyncedOperation,
    payload: OriginalUpdateCheckboxPayload): Promise<SyncedOperationApplyResult> {
    const targetPayload: OriginalInsertTextPayload = {
      location: payload.location, scalars: [], textField: payload.textField,
    };
    const target: StoredTextTarget | null = await this.textState.resolveTarget(
      store, operation, targetPayload);
    if (target === null || target.kind !== PageElementKind.TEXT) {
      return { deferredReason: 'UPDATE_CHECKBOX_TARGET_MISSING_OR_CROSS_BLOCK' };
    }
    const richText: StoredRichTextElement | null = await this.textState.readText(
      store, operation.noteId, target);
    const text: TextBlockElement | null = richText === null ? null :
      richText as Object as TextBlockElement;
    const characters: StoredCharacter[] | null = await this.textState.readCharacters(
      store, operation.noteId, target.block);
    const styles: StoredOriginalTextStyleOperation[] | null =
      await readOriginalTextStyleOperations(store, operation.noteId, target.block);
    const checkboxes: StoredOriginalCheckboxState[] | null =
      await readOriginalCheckboxStates(store, operation.noteId, target.block);
    if (text === null || characters === null || styles === null || checkboxes === null ||
      (!target.hidden && target.revision >= Number.MAX_SAFE_INTEGER)) {
      return { deferredReason: 'UPDATE_CHECKBOX_STATE_DIVERGED' };
    }
    const before = materializeOriginalTextStyles(characters, styles, checkboxes);
    if (before === null || !sameStyles(text, before.characterRuns, before.paragraphRuns)) {
      return { deferredReason: 'UPDATE_CHECKBOX_STATE_DIVERGED' };
    }
    const identityStatus: number = await this.identityStatus(store, operation, target.block, payload);
    if (identityStatus < 0) {
      throw new Error('original UpdateCheckbox identity conflicts with persisted state');
    }
    if (identityStatus > 0) {
      return { deferredReason: null };
    }
    const current: StoredOriginalCheckboxState | undefined = checkboxes.find(
      (state: StoredOriginalCheckboxState): boolean => sameLocation(state.location, payload.location));
    const identity: OperationIdentity = { timestamp: operation.timestamp, siteId: operation.siteId };
    if (current !== undefined && compareOperationIdentity(identity, current.winner) <= 0) {
      return { deferredReason: null };
    }
    const next: StoredOriginalCheckboxState = {
      location: payload.location, isChecked: payload.isChecked, winner: identity,
    };
    if (current === undefined) {
      await store.insert('original_text_checkbox_state', checkboxValues(
        operation.noteId, target.block, next));
    } else {
      const predicates = new relationalStore.RdbPredicates('original_text_checkbox_state');
      predicates.equalTo('note_id', operation.noteId);
      predicates.equalTo('block_timestamp', target.block.timestamp);
      predicates.equalTo('block_site_id', target.block.siteId);
      predicates.equalTo('location_timestamp', payload.location.timestamp);
      predicates.equalTo('location_site_id', payload.location.siteId);
      predicates.equalTo('location_index', payload.location.index);
      if (await store.update({
        'is_checked': payload.isChecked ? 1 : 0,
        'winner_timestamp': operation.timestamp,
        'winner_site_id': operation.siteId,
      }, predicates) !== 1) {
        throw new Error('original UpdateCheckbox lost its persisted register');
      }
    }
    const afterStates: StoredOriginalCheckboxState[] = checkboxes.filter(
      (state: StoredOriginalCheckboxState): boolean => !sameLocation(state.location, payload.location));
    afterStates.push(next);
    const after = materializeOriginalTextStyles(characters, styles, afterStates);
    if (after === null) {
      throw new Error('original UpdateCheckbox produced invalid RichText state');
    }
    if (sameStyles(text, after.characterRuns, after.paragraphRuns)) {
      return { deferredReason: null };
    }
    const updatedText: StoredRichTextElement = cloneText(text);
    updatedText.characterStyleRuns = after.characterRuns;
    updatedText.paragraphStyleRuns = after.paragraphRuns;
    await this.textState.writeTextPayload(store, operation.noteId, target, updatedText,
      'original UpdateCheckbox lost its target snapshot');
    return { deferredReason: null };
  }

  private async identityStatus(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation, block: OperationIdentity,
    payload: OriginalUpdateCheckboxPayload): Promise<number> {
    const rows = await store.querySql(
      `SELECT block_timestamp, block_site_id, location_timestamp, location_site_id,
              location_index, is_checked
       FROM original_text_checkbox_state WHERE note_id = ?
       AND winner_timestamp = ? AND winner_site_id = ?`,
      [operation.noteId, operation.timestamp, operation.siteId]);
    try {
      if (!rows.goToFirstRow()) {
        return 0;
      }
      return rows.getLong(rows.getColumnIndex('block_timestamp')) === block.timestamp &&
        rows.getLong(rows.getColumnIndex('block_site_id')) === block.siteId &&
        rows.getLong(rows.getColumnIndex('location_timestamp')) === payload.location.timestamp &&
        rows.getLong(rows.getColumnIndex('location_site_id')) === payload.location.siteId &&
        rows.getLong(rows.getColumnIndex('location_index')) === payload.location.index &&
        rows.getLong(rows.getColumnIndex('is_checked')) === (payload.isChecked ? 1 : 0) ? 1 : -1;
    } finally {
      rows.close();
    }
  }
}

function checkboxValues(noteId: string, block: OperationIdentity,
  state: StoredOriginalCheckboxState): relationalStore.ValuesBucket {
  return {
    'note_id': noteId,
    'block_timestamp': block.timestamp,
    'block_site_id': block.siteId,
    'location_timestamp': state.location.timestamp,
    'location_site_id': state.location.siteId,
    'location_index': state.location.index,
    'is_checked': state.isChecked ? 1 : 0,
    'winner_timestamp': state.winner.timestamp,
    'winner_site_id': state.winner.siteId,
  };
}

function sameLocation(left: OriginalSequenceIdentity, right: OriginalSequenceIdentity): boolean {
  return left.timestamp === right.timestamp && left.siteId === right.siteId &&
    left.index === right.index;
}

function sameStyles(text: TextBlockElement, characterRuns: Object[], paragraphRuns: Object[]): boolean {
  return JSON.stringify(text.characterStyleRuns ?? []) === JSON.stringify(characterRuns) &&
    JSON.stringify(text.paragraphStyleRuns ?? []) === JSON.stringify(paragraphRuns);
}

function cloneText(text: TextBlockElement): StoredRichTextElement {
  return cloneTextBlockElement(text) as Object as StoredRichTextElement;
}

function writeIdentity(bytes: Uint8Array, offset: number, identity: OperationIdentity): void {
  writeU16(bytes, offset, identity.siteId);
  writeU16(bytes, offset + 2, 0);
  writeU32(bytes, offset + 4, identity.timestamp);
}

function writeSequence(bytes: Uint8Array, offset: number,
  identity: OriginalSequenceIdentity): void {
  writeU16(bytes, offset, identity.siteId);
  writeU16(bytes, offset + 2, 0);
  writeU32(bytes, offset + 4, identity.timestamp);
  writeU32(bytes, offset + 8, identity.index);
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

function readU16(bytes: Uint8Array, offset: number): number {
  return bytes[offset] | (bytes[offset + 1] << 8);
}

function readU32(bytes: Uint8Array, offset: number): number {
  return (bytes[offset] | (bytes[offset + 1] << 8) | (bytes[offset + 2] << 16) |
    (bytes[offset + 3] << 24)) >>> 0;
}
