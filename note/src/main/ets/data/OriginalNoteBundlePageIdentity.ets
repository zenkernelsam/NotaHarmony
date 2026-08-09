import { relationalStore } from '@kit.ArkData';
import { OpType } from '../core/model/OpTypes';
import {
  decodeOriginalCreatePageTable, MAX_ORIGINAL_CREATE_PAGE_COUNT, OriginalCreatePagePayload,
} from './OriginalCreatePageOperation';
import {
  compareOriginalSequenceIdentity, encodeOriginalSequenceId, OriginalSequenceIdentity,
  validateOperationIdentity, validateOriginalSequenceIdentity,
} from './OperationIdentity';
import { OriginalFlatBufferTableReader } from './OriginalSyncedOperationFlatBuffer';
import { validateUnsignedLongDecimal } from './UnsignedDecimal';

export const ORIGINAL_NOTE_BUNDLE_MAX_OPERATION_COUNT: number = 262144;
const ORIGINAL_DELETE_ENTITIES_PAYLOAD_TYPE: number = 25;
const ORIGINAL_MODIFY_PAGE_PAYLOAD_TYPE: number = 4;
const ORIGINAL_PAYLOAD_TYPE_MAX: number = 31;

export interface OriginalNoteBundleOperation extends OriginalSequenceIdentity {
  clientTime: string;
  serverTime: string | null;
  payloadType: number;
  payload: OriginalFlatBufferTableReader;
}

export interface OriginalNoteBundle {
  noteId: string;
  editorSiteId: number;
  schemaVersion: number;
  operations: OriginalNoteBundleOperation[];
}

export interface OriginalPageIdentityBootstrapResult {
  applied: boolean;
  deferredReason: string | null;
}

interface BootstrapGroup {
  operation: OriginalNoteBundleOperation;
  location: OriginalSequenceIdentity | null;
  pageCount: number;
  modifiedTime: string;
  pages: OriginalSequenceIdentity[];
}

interface ExistingGroupRow {
  operation: OriginalSequenceIdentity;
  location: OriginalSequenceIdentity | null;
  pageCount: number;
  modifiedTime: string;
}

interface ExistingIdentityRow extends OriginalSequenceIdentity {
  pageId: string | null;
  visible: boolean;
}

export function decodeOriginalNoteBundle(bytes: Uint8Array): OriginalNoteBundle {
  const root: OriginalFlatBufferTableReader = OriginalFlatBufferTableReader.fromRoot(bytes);
  const noteIdBytes: Uint8Array | null = root.readInlineBytes(0, 16);
  if (noteIdBytes === null) {
    throw new Error('original note bundle has no required note ID');
  }
  // r29 requires both user-id strings and the ops vector even though page identity does not use them.
  root.validateByteVector(3, true, bytes.length);
  root.validateByteVector(5, true, bytes.length);
  if (!root.hasField(6)) {
    throw new Error('original note bundle has no required operations vector');
  }
  const operationTables: OriginalFlatBufferTableReader[] =
    root.readTableVector(6, ORIGINAL_NOTE_BUNDLE_MAX_OPERATION_COUNT);
  const operations: OriginalNoteBundleOperation[] = [];
  const identities: Set<string> = new Set<string>();
  for (const table of operationTables) {
    const id: Uint8Array | null = table.readInlineBytes(0, 8);
    if (id === null) {
      throw new Error('original note bundle operation has no required ID');
    }
    const payloadType: number = table.readUint8(4, 0);
    if (payloadType < 1 || payloadType > ORIGINAL_PAYLOAD_TYPE_MAX) {
      throw new Error('original note bundle operation has an unknown payload type');
    }
    const payload: OriginalFlatBufferTableReader | null = table.readTable(5);
    if (payload === null) {
      throw new Error('original note bundle operation has no payload table');
    }
    const operation: OriginalNoteBundleOperation = {
      timestamp: readU32(id, 4),
      siteId: readU16(id, 0),
      index: 0,
      clientTime: requireDecimal(table.readUint64Decimal(1, '0')),
      serverTime: table.readUint64Decimal(2, null),
      payloadType: payloadType,
      payload: payload,
    };
    validateOperationIdentity(operation);
    if (operation.serverTime !== null) {
      validateUnsignedLongDecimal(operation.serverTime);
    }
    const key: string = operationKey(operation);
    if (identities.has(key)) {
      throw new Error('original note bundle repeats an operation identity');
    }
    identities.add(key);
    operations.push(operation);
  }
  return {
    noteId: decodeOriginalUuid(noteIdBytes),
    editorSiteId: root.readUint16(2, 0),
    schemaVersion: root.readUint16(7, 0),
    operations: operations,
  };
}

export class OriginalNoteBundlePageIdentityBootstrapper {
  async apply(store: relationalStore.RdbStore, expectedNoteId: string,
    expectedSchemaVersion: number, bytes: Uint8Array): Promise<OriginalPageIdentityBootstrapResult> {
    let bundle: OriginalNoteBundle;
    try {
      bundle = decodeOriginalNoteBundle(bytes);
    } catch (_error) {
      return deferred('MALFORMED_NOTE_BUNDLE');
    }
    if (!originalNoteIdsMatch(expectedNoteId, bundle.noteId)) {
      return deferred('NOTE_BUNDLE_NOTE_ID_MISMATCH');
    }
    if (bundle.schemaVersion !== expectedSchemaVersion) {
      return deferred('NOTE_BUNDLE_SCHEMA_VERSION_MISMATCH');
    }

    let groups: BootstrapGroup[];
    try {
      groups = collectBootstrapGroups(bundle.operations);
    } catch (_error) {
      return deferred('MALFORMED_NOTE_BUNDLE_PAGE_SEQUENCE');
    }
    try {
      for (const operation of bundle.operations) {
        if (operation.payloadType === ORIGINAL_MODIFY_PAGE_PAYLOAD_TYPE) {
          return deferred('NOTE_BUNDLE_MODIFY_PAGE_UNSUPPORTED');
        }
        if (operation.payloadType === ORIGINAL_DELETE_ENTITIES_PAYLOAD_TYPE &&
          hasPageVisibilityMutation(operation.payload)) {
          return deferred('NOTE_BUNDLE_PAGE_VISIBILITY_UNSUPPORTED');
        }
      }
    } catch (_error) {
      return deferred('MALFORMED_NOTE_BUNDLE_PAGE_SEQUENCE');
    }

    let order: OriginalSequenceIdentity[];
    try {
      order = materializeBootstrapOrder(groups);
    } catch (_error) {
      return deferred('MALFORMED_NOTE_BUNDLE_PAGE_SEQUENCE');
    }
    const pageIds: string[] = await readPageIds(store, expectedNoteId);
    if (pageIds.length !== order.length) {
      return deferred('NOTE_BUNDLE_PAGE_COUNT_MISMATCH');
    }
    const divergentLocalMutationCount: number = await countRows(store,
      `SELECT COUNT(*) AS value FROM operation_log WHERE note_id = ?
       AND op_type IN (?, ?, ?)`, [expectedNoteId, OpType.DELETE_PAGE,
        OpType.UPDATE_PAGE, OpType.REORDER_PAGES]);
    if (divergentLocalMutationCount !== 0) {
      return deferred('LOCAL_PAGE_STRUCTURE_DIVERGED');
    }
    if (groups.length === 0) {
      return { applied: false, deferredReason: null };
    }
    if (await existingMappingMatches(store, expectedNoteId, groups, order, pageIds)) {
      return { applied: false, deferredReason: null };
    }
    const existingGroupCount: number = await countRows(store,
      'SELECT COUNT(*) AS value FROM original_page_insert_group WHERE note_id = ?', [expectedNoteId]);
    const existingIdentityCount: number = await countRows(store,
      'SELECT COUNT(*) AS value FROM original_page_identity WHERE note_id = ?', [expectedNoteId]);
    if (existingGroupCount !== 0 || existingIdentityCount !== 0) {
      return deferred('ORIGINAL_PAGE_IDENTITY_CONFLICT');
    }

    for (const group of groups) {
      const values: relationalStore.ValuesBucket = {
        'note_id': expectedNoteId,
        'op_timestamp': group.operation.timestamp,
        'op_site_id': group.operation.siteId,
        'page_count': group.pageCount,
        'modified_time': group.modifiedTime,
      };
      if (group.location !== null) {
        values['parent_timestamp'] = group.location.timestamp;
        values['parent_site_id'] = group.location.siteId;
        values['parent_index'] = group.location.index;
      }
      await store.insert('original_page_insert_group', values);
    }
    const pageIdBySequence: Map<string, string> = new Map<string, string>();
    for (let index: number = 0; index < order.length; index++) {
      pageIdBySequence.set(encodeOriginalSequenceId(order[index]), pageIds[index]);
    }
    for (const group of groups) {
      for (const page of group.pages) {
        const pageId: string | undefined = pageIdBySequence.get(encodeOriginalSequenceId(page));
        if (pageId === undefined) {
          throw new Error('note bundle page sequence was not assigned a storage page');
        }
        await store.insert('original_page_identity', {
          'note_id': expectedNoteId,
          'seq_timestamp': page.timestamp,
          'seq_site_id': page.siteId,
          'seq_index': page.index,
          'page_id': pageId,
          'visible': 1,
        });
      }
    }
    return { applied: true, deferredReason: null };
  }
}

function collectBootstrapGroups(operations: OriginalNoteBundleOperation[]): BootstrapGroup[] {
  const groups: BootstrapGroup[] = [];
  let totalPageCount: number = 0;
  for (const operation of operations) {
    if (operation.payloadType !== 3) {
      continue;
    }
    const payload: OriginalCreatePagePayload = decodeOriginalCreatePageTable(operation.payload);
    if (payload.pageCount < 1 || payload.pageCount > MAX_ORIGINAL_CREATE_PAGE_COUNT) {
      throw new Error('note bundle create-page count is invalid');
    }
    totalPageCount += payload.pageCount;
    if (!Number.isSafeInteger(totalPageCount) || totalPageCount > ORIGINAL_NOTE_BUNDLE_MAX_OPERATION_COUNT) {
      throw new Error('note bundle page count exceeds the identity budget');
    }
    const pages: OriginalSequenceIdentity[] = [];
    for (let index: number = 0; index < payload.pageCount; index++) {
      pages.push({ timestamp: operation.timestamp, siteId: operation.siteId, index: index });
    }
    groups.push({
      operation: operation,
      location: payload.location,
      pageCount: payload.pageCount,
      modifiedTime: operation.serverTime === null ? operation.clientTime : operation.serverTime,
      pages: pages,
    });
  }
  return groups;
}

function materializeBootstrapOrder(groups: BootstrapGroup[]): OriginalSequenceIdentity[] {
  const children: Map<string, BootstrapGroup[]> = new Map<string, BootstrapGroup[]>();
  const identities: Set<string> = new Set<string>();
  const operations: Set<string> = new Set<string>();
  for (const group of groups) {
    const opKey: string = operationKey(group.operation);
    if (operations.has(opKey) || group.pages.length !== group.pageCount) {
      throw new Error('note bundle repeats or truncates a create-page group');
    }
    operations.add(opKey);
    for (const page of group.pages) {
      validateOriginalSequenceIdentity(page);
      const key: string = encodeOriginalSequenceId(page);
      if (identities.has(key)) {
        throw new Error('note bundle repeats a page identity');
      }
      identities.add(key);
    }
  }
  for (const group of groups) {
    if (group.location !== null && !identities.has(encodeOriginalSequenceId(group.location))) {
      throw new Error('note bundle create-page location is missing');
    }
    const parentKey: string = group.location === null ? 'ROOT' : encodeOriginalSequenceId(group.location);
    const siblings: BootstrapGroup[] | undefined = children.get(parentKey);
    if (siblings === undefined) {
      children.set(parentKey, [group]);
    } else {
      siblings.push(group);
    }
  }
  children.forEach((siblings: BootstrapGroup[]): void => {
    siblings.sort((left: BootstrapGroup, right: BootstrapGroup): number =>
      -compareOriginalSequenceIdentity(left.pages[left.pages.length - 1],
        right.pages[right.pages.length - 1]));
  });
  const result: OriginalSequenceIdentity[] = [];
  const visited: Set<string> = new Set<string>();
  appendBootstrapChildren('ROOT', children, visited, result);
  if (visited.size !== groups.length) {
    throw new Error('note bundle page sequence contains an orphan or cycle');
  }
  return result;
}

function appendBootstrapChildren(parentKey: string, children: Map<string, BootstrapGroup[]>,
  visited: Set<string>, result: OriginalSequenceIdentity[]): void {
  const groups: BootstrapGroup[] | undefined = children.get(parentKey);
  if (groups === undefined) {
    return;
  }
  for (const group of groups) {
    const key: string = operationKey(group.operation);
    if (visited.has(key)) {
      throw new Error('note bundle page sequence contains a cycle');
    }
    visited.add(key);
    for (const page of group.pages) {
      result.push(page);
      appendBootstrapChildren(encodeOriginalSequenceId(page), children, visited, result);
    }
  }
}

function hasPageVisibilityMutation(payload: OriginalFlatBufferTableReader): boolean {
  return payload.readInlineVectorCount(2, 12, ORIGINAL_NOTE_BUNDLE_MAX_OPERATION_COUNT) > 0 ||
    payload.readInlineVectorCount(3, 12, ORIGINAL_NOTE_BUNDLE_MAX_OPERATION_COUNT) > 0;
}

async function existingMappingMatches(store: relationalStore.RdbStore, noteId: string,
  groups: BootstrapGroup[], order: OriginalSequenceIdentity[], pageIds: string[]): Promise<boolean> {
  const existingGroups: ExistingGroupRow[] = await readExistingGroups(store, noteId);
  const existingIdentities: ExistingIdentityRow[] = await readExistingIdentities(store, noteId);
  if (existingGroups.length === 0 && existingIdentities.length === 0) {
    return false;
  }
  if (existingGroups.length !== groups.length || existingIdentities.length !== order.length) {
    return false;
  }
  const desiredGroups: Map<string, BootstrapGroup> = new Map<string, BootstrapGroup>();
  for (const group of groups) {
    desiredGroups.set(operationKey(group.operation), group);
  }
  for (const existing of existingGroups) {
    const desired: BootstrapGroup | undefined = desiredGroups.get(operationKey(existing.operation));
    if (desired === undefined || desired.pageCount !== existing.pageCount ||
      desired.modifiedTime !== existing.modifiedTime || !sameSequence(desired.location, existing.location)) {
      return false;
    }
  }
  const identities: Map<string, ExistingIdentityRow> = new Map<string, ExistingIdentityRow>();
  for (const existing of existingIdentities) {
    identities.set(encodeOriginalSequenceId(existing), existing);
  }
  for (let index: number = 0; index < order.length; index++) {
    const existing: ExistingIdentityRow | undefined = identities.get(encodeOriginalSequenceId(order[index]));
    if (existing === undefined || !existing.visible || existing.pageId !== pageIds[index]) {
      return false;
    }
  }
  return true;
}

async function readExistingGroups(store: relationalStore.RdbStore,
  noteId: string): Promise<ExistingGroupRow[]> {
  const rows = await store.querySql(
    `SELECT op_timestamp, op_site_id, parent_timestamp, parent_site_id, parent_index,
      page_count, modified_time FROM original_page_insert_group WHERE note_id = ?`, [noteId]);
  const result: ExistingGroupRow[] = [];
  try {
    while (rows.goToNextRow()) {
      const parentColumn: number = rows.getColumnIndex('parent_timestamp');
      result.push({
        operation: {
          timestamp: rows.getLong(rows.getColumnIndex('op_timestamp')),
          siteId: rows.getLong(rows.getColumnIndex('op_site_id')),
          index: 0,
        },
        location: rows.isColumnNull(parentColumn) ? null : {
          timestamp: rows.getLong(parentColumn),
          siteId: rows.getLong(rows.getColumnIndex('parent_site_id')),
          index: rows.getLong(rows.getColumnIndex('parent_index')),
        },
        pageCount: rows.getLong(rows.getColumnIndex('page_count')),
        modifiedTime: rows.getString(rows.getColumnIndex('modified_time')),
      });
    }
  } finally {
    rows.close();
  }
  return result;
}

async function readExistingIdentities(store: relationalStore.RdbStore,
  noteId: string): Promise<ExistingIdentityRow[]> {
  const rows = await store.querySql(
    `SELECT seq_timestamp, seq_site_id, seq_index, page_id, visible
     FROM original_page_identity WHERE note_id = ?`, [noteId]);
  const result: ExistingIdentityRow[] = [];
  try {
    while (rows.goToNextRow()) {
      const pageIdColumn: number = rows.getColumnIndex('page_id');
      result.push({
        timestamp: rows.getLong(rows.getColumnIndex('seq_timestamp')),
        siteId: rows.getLong(rows.getColumnIndex('seq_site_id')),
        index: rows.getLong(rows.getColumnIndex('seq_index')),
        pageId: rows.isColumnNull(pageIdColumn) ? null : rows.getString(pageIdColumn),
        visible: rows.getLong(rows.getColumnIndex('visible')) === 1,
      });
    }
  } finally {
    rows.close();
  }
  return result;
}

async function readPageIds(store: relationalStore.RdbStore, noteId: string): Promise<string[]> {
  const rows = await store.querySql(
    'SELECT page_id FROM page_info WHERE note_id = ? ORDER BY page_index', [noteId]);
  const result: string[] = [];
  try {
    while (rows.goToNextRow()) {
      result.push(rows.getString(rows.getColumnIndex('page_id')));
    }
  } finally {
    rows.close();
  }
  return result;
}

async function countRows(store: relationalStore.RdbStore, sql: string,
  bindArgs: relationalStore.ValueType[]): Promise<number> {
  const rows = await store.querySql(sql, bindArgs);
  try {
    if (!rows.goToFirstRow()) {
      throw new Error('count query returned no row');
    }
    const value: number = rows.getLong(rows.getColumnIndex('value'));
    if (!Number.isSafeInteger(value) || value < 0) {
      throw new Error('count query returned an invalid value');
    }
    return value;
  } finally {
    rows.close();
  }
}

function decodeOriginalUuid(bytes: Uint8Array): string {
  if (bytes.length !== 16) {
    throw new Error('original UUID has the wrong size');
  }
  const high: string = littleEndianHex(bytes, 8, 8);
  const low: string = littleEndianHex(bytes, 0, 8);
  const value: string = high + low;
  return `${value.slice(0, 8)}-${value.slice(8, 12)}-${value.slice(12, 16)}-` +
    `${value.slice(16, 20)}-${value.slice(20)}`;
}

function littleEndianHex(bytes: Uint8Array, start: number, count: number): string {
  let result: string = '';
  for (let index: number = start + count - 1; index >= start; index--) {
    result += bytes[index].toString(16).padStart(2, '0');
  }
  return result;
}

function originalNoteIdsMatch(expected: string, actual: string): boolean {
  const expectedCanonical: string | null = canonicalUuid(expected);
  const actualCanonical: string | null = canonicalUuid(actual);
  return expectedCanonical !== null && expectedCanonical === actualCanonical;
}

function canonicalUuid(value: string): string | null {
  const compact: string = value.replace(/-/g, '').toLowerCase();
  return /^[0-9a-f]{32}$/.test(compact) ? compact : null;
}

function operationKey(identity: OriginalSequenceIdentity): string {
  return `${identity.timestamp.toString(16)}:${identity.siteId.toString(16)}`;
}

function sameSequence(left: OriginalSequenceIdentity | null,
  right: OriginalSequenceIdentity | null): boolean {
  return left === null ? right === null : right !== null && left.timestamp === right.timestamp &&
    left.siteId === right.siteId && left.index === right.index;
}

function requireDecimal(value: string | null): string {
  if (value === null) {
    throw new Error('required unsigned timestamp is absent');
  }
  validateUnsignedLongDecimal(value);
  return value;
}

function readU16(bytes: Uint8Array, offset: number): number {
  return bytes[offset] + bytes[offset + 1] * 0x100;
}

function readU32(bytes: Uint8Array, offset: number): number {
  return bytes[offset] + bytes[offset + 1] * 0x100 + bytes[offset + 2] * 0x10000 +
    bytes[offset + 3] * 0x1000000;
}

function deferred(reason: string): OriginalPageIdentityBootstrapResult {
  return { applied: false, deferredReason: reason };
}
