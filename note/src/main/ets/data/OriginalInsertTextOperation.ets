import { relationalStore } from '@kit.ArkData';
import { util } from '@kit.ArkTS';
import { TextBlockElement } from '../core/model/ElementTypes';
import { PageElementKind } from '../core/model/PageElementOrder';
import {
  compareOriginalSequenceIdentity, encodeOperationId, encodeOriginalSequenceId,
  OperationIdentity, OriginalSequenceIdentity, validateOperationIdentity,
  validateOriginalSequenceIdentity,
} from './OperationIdentity';
import { OriginalBlockType } from './OriginalCreateBlockOperation';
import { OriginalFlatBufferTableReader, readOriginalPayloadTable } from './OriginalSyncedOperationFlatBuffer';
import { SearchItemType } from './SearchItemType';
import { decodePersistedElement, encodePersistedElement, PersistedElement } from './StrokePersistence';
import {
  StoredSyncedOperation, SyncedOperationApplier, SyncedOperationApplyResult,
} from './SyncedOperationInbox';

export const ORIGINAL_INSERT_CHAR_PAYLOAD_TYPE: number = 7;
export const ORIGINAL_INSERT_STRING_PAYLOAD_TYPE: number = 8;
const MAX_INSERT_STRING_BYTES: number = 1048576;

export interface OriginalInsertTextPayload {
  location: OriginalSequenceIdentity | null;
  scalars: number[];
  textField: OperationIdentity | null;
}

interface StoredTextTarget {
  block: OperationIdentity;
  page: OriginalSequenceIdentity;
  pageId: string;
  table: string;
  revisionTable: string;
  revision: number;
  archived: boolean;
}

interface StoredCharacter {
  identity: OriginalSequenceIdentity;
  parent: OriginalSequenceIdentity | null;
  scalar: number;
  visible: boolean;
}

export function decodeOriginalInsertText(bytes: Uint8Array,
  payloadType: number): OriginalInsertTextPayload {
  if (payloadType !== ORIGINAL_INSERT_CHAR_PAYLOAD_TYPE &&
    payloadType !== ORIGINAL_INSERT_STRING_PAYLOAD_TYPE) {
    throw new Error('original insert-text payload type is unsupported');
  }
  const table: OriginalFlatBufferTableReader = readOriginalPayloadTable(bytes, payloadType);
  const rawLocation: number[] | null = table.readInlineSequence(0);
  const location: OriginalSequenceIdentity | null = rawLocation === null || isRoot(rawLocation) ? null : {
    timestamp: rawLocation[0], siteId: rawLocation[1], index: rawLocation[2],
  };
  if (location !== null) {
    validateOriginalSequenceIdentity(location);
  }
  const textField: OperationIdentity | null = readOperationIdentity(table, 2);
  let scalars: number[];
  if (payloadType === ORIGINAL_INSERT_CHAR_PAYLOAD_TYPE) {
    const scalar: number = table.readUint32(1, 0);
    if (!isUnicodeScalar(scalar)) {
      throw new Error('original insert-char has an invalid Unicode scalar');
    }
    scalars = [scalar];
  } else {
    table.validateByteVector(1, true, MAX_INSERT_STRING_BYTES);
    const encoded: Uint8Array | null = table.readByteVector(1, true, MAX_INSERT_STRING_BYTES);
    if (encoded === null || encoded.length === 0) {
      throw new Error('original insert-string is empty');
    }
    const decoded: string = util.TextDecoder.create('utf-8').decodeToString(encoded);
    scalars = stringScalars(decoded);
    if (scalars.length === 0) {
      throw new Error('original insert-string produced no characters');
    }
  }
  return { location: location, scalars: scalars, textField: textField };
}

export class OriginalInsertTextOperationApplier implements SyncedOperationApplier {
  supports(payloadType: number): boolean {
    return payloadType === ORIGINAL_INSERT_CHAR_PAYLOAD_TYPE ||
      payloadType === ORIGINAL_INSERT_STRING_PAYLOAD_TYPE;
  }

  async apply(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation): Promise<SyncedOperationApplyResult> {
    let payload: OriginalInsertTextPayload;
    try {
      payload = decodeOriginalInsertText(operation.rawOperation, operation.payloadType);
    } catch (_error) {
      return { deferredReason: 'MALFORMED_INSERT_TEXT_PAYLOAD' };
    }
    if (payload.scalars.length - 1 > 0xFFFFFFFF) {
      return { deferredReason: 'INSERT_TEXT_SEQUENCE_EXHAUSTED' };
    }
    const target: StoredTextTarget | null = await this.resolveTarget(store, operation, payload);
    if (target === null) {
      return { deferredReason: 'INSERT_TEXT_TARGET_MISSING_OR_UNBOUND' };
    }
    const text: TextBlockElement | null = await this.readText(store, operation.noteId, target);
    const existing: StoredCharacter[] | null = await this.readCharacters(
      store, operation.noteId, target.block);
    if (text === null || existing === null) {
      return { deferredReason: 'INSERT_TEXT_STATE_DIVERGED' };
    }
    const before: string | null = materializeCharacters(existing);
    if (before === null || before !== text.richText || target.revision >= Number.MAX_SAFE_INTEGER) {
      return { deferredReason: 'INSERT_TEXT_STATE_DIVERGED' };
    }
    if (payload.location !== null && !existing.some((character: StoredCharacter): boolean =>
      sameSequence(character.identity, payload.location as OriginalSequenceIdentity))) {
      return { deferredReason: 'INSERT_TEXT_ANCHOR_MISSING' };
    }
    let parent: OriginalSequenceIdentity | null = payload.location;
    for (let index: number = 0; index < payload.scalars.length; index++) {
      const identity: OriginalSequenceIdentity = {
        timestamp: operation.timestamp, siteId: operation.siteId, index: index,
      };
      await store.insert('original_text_character', {
        'note_id': operation.noteId,
        'block_timestamp': target.block.timestamp,
        'block_site_id': target.block.siteId,
        'char_timestamp': identity.timestamp,
        'char_site_id': identity.siteId,
        'char_index': identity.index,
        'parent_timestamp': parent === null ? null : parent.timestamp,
        'parent_site_id': parent === null ? null : parent.siteId,
        'parent_index': parent === null ? null : parent.index,
        'unicode_scalar': payload.scalars[index],
        'visible': 1,
      });
      parent = identity;
    }
    const updatedCharacters: StoredCharacter[] | null = await this.readCharacters(
      store, operation.noteId, target.block);
    const updatedValue: string | null = updatedCharacters === null ? null :
      materializeCharacters(updatedCharacters);
    if (updatedValue === null) {
      throw new Error('original insert-text produced an invalid sequence tree');
    }
    const updatedText: TextBlockElement = cloneText(text);
    updatedText.richText = updatedValue;
    const predicates: relationalStore.RdbPredicates = pageElementPredicates(
      operation.noteId, target, text.id);
    const persisted: PersistedElement = { kind: 'text', data: updatedText };
    const updated: number = await store.update({
      'payload': encodePersistedElement(persisted), 'revision': target.revision + 1,
    }, predicates);
    if (updated !== 1) {
      throw new Error('original insert-text lost its target snapshot');
    }
    await this.advanceRevisionAndInvalidateSearch(store, operation.noteId, target);
    return { deferredReason: null };
  }

  private async resolveTarget(store: relationalStore.RdbStore, operation: StoredSyncedOperation,
    payload: OriginalInsertTextPayload): Promise<StoredTextTarget | null> {
    let block: OperationIdentity | null = payload.textField;
    if (payload.location !== null) {
      const anchorBlock: OperationIdentity | null = await this.readAnchorBlock(
        store, operation.noteId, payload.location);
      if (anchorBlock === null || (block !== null && !sameOperation(block, anchorBlock))) {
        return null;
      }
      block = anchorBlock;
    }
    if (block === null) {
      return null;
    }
    const rows = await store.querySql(
      `SELECT element.page_timestamp, element.page_site_id, element.page_index,
              identity.page_id, identity.visible, state.block_type
       FROM original_element_z_index element
       JOIN original_page_identity identity ON identity.note_id = element.note_id
        AND identity.seq_timestamp = element.page_timestamp
        AND identity.seq_site_id = element.page_site_id AND identity.seq_index = element.page_index
       JOIN original_block_state state ON state.note_id = element.note_id
        AND state.block_timestamp = element.element_timestamp
        AND state.block_site_id = element.element_site_id
       WHERE element.note_id = ? AND element.element_timestamp = ? AND element.element_site_id = ?
        AND element.kind = ?`,
      [operation.noteId, block.timestamp, block.siteId, PageElementKind.TEXT]);
    let page: OriginalSequenceIdentity;
    let pageId: string;
    try {
      if (!rows.goToFirstRow() || rows.getLong(rows.getColumnIndex('visible')) !== 1 ||
        rows.getLong(rows.getColumnIndex('block_type')) !== OriginalBlockType.TEXT ||
        rows.isColumnNull(rows.getColumnIndex('page_id'))) {
        return null;
      }
      page = {
        timestamp: rows.getLong(rows.getColumnIndex('page_timestamp')),
        siteId: rows.getLong(rows.getColumnIndex('page_site_id')),
        index: rows.getLong(rows.getColumnIndex('page_index')),
      };
      pageId = rows.getString(rows.getColumnIndex('page_id'));
    } finally {
      rows.close();
    }
    validateOriginalSequenceIdentity(page);
    const liveRevision: number | null = await readSingleRevision(store,
      'SELECT content_revision FROM page_info WHERE note_id = ? AND page_id = ?',
      [operation.noteId, pageId]);
    const archivedRevision: number | null = await readSingleRevision(store,
      `SELECT content_revision FROM original_deleted_page WHERE note_id = ?
       AND page_timestamp = ? AND page_site_id = ? AND page_index = ?`,
      [operation.noteId, page.timestamp, page.siteId, page.index]);
    if ((liveRevision === null) === (archivedRevision === null)) {
      return null;
    }
    return liveRevision !== null ? {
      block: block, page: page, pageId: pageId, table: 'page_element_snapshot',
      revisionTable: 'page_info', revision: liveRevision, archived: false,
    } : {
      block: block, page: page, pageId: pageId, table: 'original_deleted_page_element',
      revisionTable: 'original_deleted_page', revision: archivedRevision as number, archived: true,
    };
  }

  private async readAnchorBlock(store: relationalStore.RdbStore, noteId: string,
    location: OriginalSequenceIdentity): Promise<OperationIdentity | null> {
    const rows = await store.querySql(
      `SELECT block_timestamp, block_site_id FROM original_text_character WHERE note_id = ?
       AND char_timestamp = ? AND char_site_id = ? AND char_index = ?`,
      [noteId, location.timestamp, location.siteId, location.index]);
    try {
      if (!rows.goToFirstRow()) {
        return null;
      }
      const block: OperationIdentity = {
        timestamp: rows.getLong(rows.getColumnIndex('block_timestamp')),
        siteId: rows.getLong(rows.getColumnIndex('block_site_id')),
      };
      validateOperationIdentity(block);
      return block;
    } finally {
      rows.close();
    }
  }

  private async readText(store: relationalStore.RdbStore, noteId: string,
    target: StoredTextTarget): Promise<TextBlockElement | null> {
    const rows = await store.querySql(target.archived ?
      `SELECT payload FROM original_deleted_page_element WHERE note_id = ?
       AND page_timestamp = ? AND page_site_id = ? AND page_index = ?
       AND element_id = ? AND kind = ?` :
      `SELECT payload FROM page_element_snapshot WHERE note_id = ? AND page_id = ?
       AND element_id = ? AND kind = ?`, target.archived ?
      [noteId, target.page.timestamp, target.page.siteId, target.page.index,
        encodeOperationId(target.block), PageElementKind.TEXT] :
      [noteId, target.pageId, encodeOperationId(target.block), PageElementKind.TEXT]);
    try {
      if (!rows.goToFirstRow()) {
        return null;
      }
      const persisted: PersistedElement = decodePersistedElement(
        rows.getBlob(rows.getColumnIndex('payload')));
      if (persisted.kind !== 'text') {
        return null;
      }
      const text: TextBlockElement = persisted.data as TextBlockElement;
      return text.id === encodeOperationId(target.block) ? text : null;
    } catch (_error) {
      return null;
    } finally {
      rows.close();
    }
  }

  private async readCharacters(store: relationalStore.RdbStore, noteId: string,
    block: OperationIdentity): Promise<StoredCharacter[] | null> {
    const rows = await store.querySql(
      `SELECT char_timestamp, char_site_id, char_index, parent_timestamp, parent_site_id,
              parent_index, unicode_scalar, visible
       FROM original_text_character WHERE note_id = ? AND block_timestamp = ? AND block_site_id = ?`,
      [noteId, block.timestamp, block.siteId]);
    const result: StoredCharacter[] = [];
    try {
      while (rows.goToNextRow()) {
        const identity: OriginalSequenceIdentity = {
          timestamp: rows.getLong(rows.getColumnIndex('char_timestamp')),
          siteId: rows.getLong(rows.getColumnIndex('char_site_id')),
          index: rows.getLong(rows.getColumnIndex('char_index')),
        };
        validateOriginalSequenceIdentity(identity);
        const parentTimestampColumn: number = rows.getColumnIndex('parent_timestamp');
        let parent: OriginalSequenceIdentity | null = null;
        if (!rows.isColumnNull(parentTimestampColumn)) {
          parent = {
            timestamp: rows.getLong(parentTimestampColumn),
            siteId: rows.getLong(rows.getColumnIndex('parent_site_id')),
            index: rows.getLong(rows.getColumnIndex('parent_index')),
          };
          validateOriginalSequenceIdentity(parent);
        } else if (!rows.isColumnNull(rows.getColumnIndex('parent_site_id')) ||
          !rows.isColumnNull(rows.getColumnIndex('parent_index'))) {
          return null;
        }
        const scalar: number = rows.getLong(rows.getColumnIndex('unicode_scalar'));
        const visible: number = rows.getLong(rows.getColumnIndex('visible'));
        if (!isUnicodeScalar(scalar) || (visible !== 0 && visible !== 1)) {
          return null;
        }
        result.push({ identity: identity, parent: parent, scalar: scalar, visible: visible === 1 });
      }
      return result;
    } catch (_error) {
      return null;
    } finally {
      rows.close();
    }
  }

  private async advanceRevisionAndInvalidateSearch(store: relationalStore.RdbStore,
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
    const values: relationalStore.ValuesBucket = { 'content_revision': target.revision + 1 };
    if (target.archived) {
      values['indexed_revision'] = null;
    }
    const updated: number = await store.update(values, predicates);
    if (updated !== 1) {
      throw new Error('original insert-text page revision changed concurrently');
    }
    if (target.archived) {
      await store.executeSql(
        `DELETE FROM original_deleted_page_search WHERE note_id = ? AND page_timestamp = ?
         AND page_site_id = ? AND page_index = ? AND type = ?`,
        [noteId, target.page.timestamp, target.page.siteId, target.page.index,
          SearchItemType.TEXT_BLOCK]);
    } else {
      await store.executeSql('DELETE FROM search_page_state WHERE note_id = ? AND page_id = ?',
        [noteId, target.pageId]);
      await store.executeSql(
        'DELETE FROM search_item WHERE note_id = ? AND page_id = ? AND type = ?',
        [noteId, target.pageId, SearchItemType.TEXT_BLOCK]);
    }
  }
}

function materializeCharacters(characters: StoredCharacter[]): string | null {
  const byId: Map<string, StoredCharacter> = new Map<string, StoredCharacter>();
  for (const character of characters) {
    const key: string = encodeOriginalSequenceId(character.identity);
    if (byId.has(key)) {
      return null;
    }
    byId.set(key, character);
  }
  const children: Map<string, StoredCharacter[]> = new Map<string, StoredCharacter[]>();
  for (const character of characters) {
    const parentKey: string = character.parent === null ? 'ROOT' :
      encodeOriginalSequenceId(character.parent);
    if (character.parent !== null && !byId.has(parentKey)) {
      return null;
    }
    const siblings: StoredCharacter[] = children.get(parentKey) ?? [];
    siblings.push(character);
    children.set(parentKey, siblings);
  }
  for (const siblings of children.values()) {
    siblings.sort((left: StoredCharacter, right: StoredCharacter): number =>
      -compareOriginalSequenceIdentity(left.identity, right.identity));
  }
  const visited: Set<string> = new Set<string>();
  const values: string[] = [];
  const pending: StoredCharacter[] = [];
  const roots: StoredCharacter[] | undefined = children.get('ROOT');
  if (roots !== undefined) {
    for (let index: number = roots.length - 1; index >= 0; index--) {
      pending.push(roots[index]);
    }
  }
  while (pending.length > 0) {
    const character: StoredCharacter = pending.pop() as StoredCharacter;
    const key: string = encodeOriginalSequenceId(character.identity);
    if (visited.has(key)) {
      return null;
    }
    visited.add(key);
    if (character.visible) {
      values.push(String.fromCodePoint(character.scalar));
    }
    const descendants: StoredCharacter[] | undefined = children.get(key);
    if (descendants !== undefined) {
      for (let index: number = descendants.length - 1; index >= 0; index--) {
        pending.push(descendants[index]);
      }
    }
  }
  if (visited.size !== characters.length) {
    return null;
  }
  return values.join('');
}

function pageElementPredicates(noteId: string, target: StoredTextTarget,
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

async function readSingleRevision(store: relationalStore.RdbStore, sql: string,
  args: relationalStore.ValueType[]): Promise<number | null> {
  const rows = await store.querySql(sql, args);
  try {
    return rows.goToFirstRow() ? rows.getLong(rows.getColumnIndex('content_revision')) : null;
  } finally {
    rows.close();
  }
}

function readOperationIdentity(table: OriginalFlatBufferTableReader,
  field: number): OperationIdentity | null {
  const bytes: Uint8Array | null = table.readInlineBytes(field, 8);
  if (bytes === null) {
    return null;
  }
  const identity: OperationIdentity = {
    timestamp: readU32(bytes, 4), siteId: bytes[0] + bytes[1] * 0x100,
  };
  validateOperationIdentity(identity);
  return identity;
}

function readU32(bytes: Uint8Array, offset: number): number {
  return bytes[offset] + bytes[offset + 1] * 0x100 + bytes[offset + 2] * 0x10000 +
    bytes[offset + 3] * 0x1000000;
}

function stringScalars(value: string): number[] {
  const result: number[] = [];
  for (let index: number = 0; index < value.length;) {
    const scalar: number = value.codePointAt(index) as number;
    result.push(scalar);
    index += scalar > 0xFFFF ? 2 : 1;
  }
  return result;
}

function isUnicodeScalar(value: number): boolean {
  return Number.isSafeInteger(value) && value >= 0 && value <= 0x10FFFF;
}

function isRoot(raw: number[]): boolean {
  return raw[0] === 0 && raw[1] === 0xFFFF && raw[2] === 0;
}

function sameOperation(left: OperationIdentity, right: OperationIdentity): boolean {
  return left.timestamp === right.timestamp && left.siteId === right.siteId;
}

function sameSequence(left: OriginalSequenceIdentity, right: OriginalSequenceIdentity): boolean {
  return sameOperation(left, right) && left.index === right.index;
}

function cloneText(text: TextBlockElement): TextBlockElement {
  return {
    id: text.id, type: text.type, transform: text.transform.slice(),
    bounds: { left: text.bounds.left, top: text.bounds.top,
      right: text.bounds.right, bottom: text.bounds.bottom },
    richText: text.richText, textOrigin: { x: text.textOrigin.x, y: text.textOrigin.y },
    blockWidth: text.blockWidth, blockHeight: text.blockHeight,
    rotationRadians: text.rotationRadians, contentLeftInset: text.contentLeftInset,
    contentTopInset: text.contentTopInset, fontSize: text.fontSize, fontColor: text.fontColor,
    positionLocked: text.positionLocked === true,
  };
}
