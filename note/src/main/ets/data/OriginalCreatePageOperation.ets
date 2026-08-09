import { relationalStore } from '@kit.ArkData';
import { PageOrientation, PaperSize, PaperTemplate } from '../core/model/NoteTypes';
import {
  compareOriginalSequenceIdentity, encodeOriginalPageStorageId, encodeOriginalSequenceId,
  OriginalSequenceIdentity, validateOriginalSequenceIdentity,
} from './OperationIdentity';
import {
  OriginalFlatBufferTableReader, readOriginalPayloadTable,
} from './OriginalSyncedOperationFlatBuffer';
import {
  StoredSyncedOperation, SyncedOperationApplier, SyncedOperationApplyResult,
} from './SyncedOperationInbox';
import { OriginalPageOrderStore } from './OriginalPageOrderStore';

export const ORIGINAL_CREATE_PAGE_PAYLOAD_TYPE: number = 3;
export const MAX_ORIGINAL_CREATE_PAGE_COUNT: number = 10000;
export const ORIGINAL_DEFAULT_PAGE_WIDTH_MM: number = 215.9;
export const ORIGINAL_DEFAULT_PAGE_HEIGHT_MM: number = 279.4;

export interface OriginalCreatePagePayload {
  location: OriginalSequenceIdentity | null;
  hasBackground: boolean;
  pageCount: number;
  bookmarked: boolean;
}

interface OriginalPagePositionRow {
  position: OriginalSequenceIdentity;
  page: OriginalSequenceIdentity;
  pageId: string | null;
  visible: boolean;
  active: boolean;
  deleted: boolean;
}

interface OriginalPageInsertGroup {
  operation: OriginalSequenceIdentity;
  location: OriginalSequenceIdentity | null;
  pageCount: number;
  pages: OriginalPagePositionRow[];
}

export function decodeOriginalCreatePage(bytes: Uint8Array): OriginalCreatePagePayload {
  const table: OriginalFlatBufferTableReader =
    readOriginalPayloadTable(bytes, ORIGINAL_CREATE_PAGE_PAYLOAD_TYPE);
  return decodeOriginalCreatePageTable(table);
}

export function decodeOriginalCreatePageTable(
  table: OriginalFlatBufferTableReader): OriginalCreatePagePayload {
  const rawLocation: number[] | null = table.readInlineSequence(0);
  const location: OriginalSequenceIdentity | null = rawLocation === null ? null : {
    timestamp: rawLocation[0], siteId: rawLocation[1], index: rawLocation[2],
  };
  if (location !== null) {
    validateOriginalSequenceIdentity(location);
  }
  return {
    location: location,
    hasBackground: table.hasField(1),
    pageCount: table.readUint32(2, 1),
    // ln2.k() maps every unknown enum byte back to UNBOOKMARKED.
    bookmarked: table.readUint8(3, 0) === 1,
  };
}

export class OriginalCreatePageOperationApplier implements SyncedOperationApplier {
  private orderStore: OriginalPageOrderStore = new OriginalPageOrderStore();

  supports(payloadType: number): boolean {
    return payloadType === ORIGINAL_CREATE_PAGE_PAYLOAD_TYPE;
  }

  async apply(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation): Promise<SyncedOperationApplyResult> {
    let payload: OriginalCreatePagePayload;
    try {
      payload = decodeOriginalCreatePage(operation.rawOperation);
    } catch (_error) {
      return { deferredReason: 'MALFORMED_CREATE_PAGE_PAYLOAD' };
    }
    if (payload.pageCount < 1 || payload.pageCount > MAX_ORIGINAL_CREATE_PAGE_COUNT) {
      return { deferredReason: 'UNSUPPORTED_CREATE_PAGE_COUNT' };
    }
    if (payload.hasBackground) {
      return { deferredReason: 'CREATE_PAGE_BACKGROUND_UNSUPPORTED' };
    }
    if (payload.bookmarked) {
      return { deferredReason: 'CREATE_PAGE_BOOKMARK_UNSUPPORTED' };
    }
    if (await this.groupExists(store, operation.noteId, operation)) {
      throw new Error('original create-page operation was applied twice');
    }
    if (payload.location !== null &&
      !await this.positionExists(store, operation.noteId, payload.location)) {
      return { deferredReason: 'CREATE_PAGE_LOCATION_MISSING' };
    }
    const existingPageIds: string[] = await this.orderStore.readStoredPageIds(store, operation.noteId);
    const mappedPageIds: string[] = await this.orderStore.readOriginalVisibleOrder(store, operation.noteId);
    if (!this.orderStore.samePageIds(existingPageIds, mappedPageIds)) {
      return { deferredReason: 'ORIGINAL_PAGE_ORDER_DIVERGED' };
    }
    await this.insertGroup(store, operation, payload);
    const newPageIds: string[] = await this.insertIdentities(store, operation, payload.pageCount);
    const orderedPageIds: string[] = await this.orderStore.readOriginalVisibleOrder(store, operation.noteId);
    if (orderedPageIds.length !== existingPageIds.length + newPageIds.length) {
      throw new Error('original page sequence did not materialize every visible page');
    }

    await this.orderStore.assignTemporaryIndexes(store, operation.noteId, existingPageIds);
    await this.insertBlankPages(store, operation.noteId, newPageIds, existingPageIds.length);
    await this.orderStore.assignFinalIndexes(store, operation.noteId, orderedPageIds);
    await this.orderStore.advanceStructureRevision(store, operation.noteId, 'create-page');
    return { deferredReason: null };
  }

  private async groupExists(store: relationalStore.RdbStore, noteId: string,
    identity: OriginalSequenceIdentity): Promise<boolean> {
    const rows = await store.querySql(
      `SELECT 1 FROM original_page_insert_group
       WHERE note_id = ? AND op_timestamp = ? AND op_site_id = ? LIMIT 1`,
      [noteId, identity.timestamp, identity.siteId]);
    try {
      return rows.goToFirstRow();
    } finally {
      rows.close();
    }
  }

  private async positionExists(store: relationalStore.RdbStore, noteId: string,
    identity: OriginalSequenceIdentity): Promise<boolean> {
    const rows = await store.querySql(
      `SELECT 1 FROM original_page_position
       WHERE note_id = ? AND pos_timestamp = ? AND pos_site_id = ? AND pos_index = ? LIMIT 1`,
      [noteId, identity.timestamp, identity.siteId, identity.index]);
    try {
      return rows.goToFirstRow();
    } finally {
      rows.close();
    }
  }

  private async countRows(store: relationalStore.RdbStore, sql: string,
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

  private async readStoredPageIds(store: relationalStore.RdbStore, noteId: string): Promise<string[]> {
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

  private async insertGroup(store: relationalStore.RdbStore, operation: StoredSyncedOperation,
    payload: OriginalCreatePagePayload): Promise<void> {
    const values: relationalStore.ValuesBucket = {
      'note_id': operation.noteId,
      'op_timestamp': operation.timestamp,
      'op_site_id': operation.siteId,
      'page_count': payload.pageCount,
      'modified_time': operation.serverTime,
    };
    if (payload.location !== null) {
      values['parent_timestamp'] = payload.location.timestamp;
      values['parent_site_id'] = payload.location.siteId;
      values['parent_index'] = payload.location.index;
    }
    await store.insert('original_page_insert_group', values);
    const positionValues: relationalStore.ValuesBucket = {
      'note_id': operation.noteId,
      'op_timestamp': operation.timestamp,
      'op_site_id': operation.siteId,
      'position_count': payload.pageCount,
      'modified_time': operation.serverTime,
    };
    if (payload.location !== null) {
      positionValues['parent_timestamp'] = payload.location.timestamp;
      positionValues['parent_site_id'] = payload.location.siteId;
      positionValues['parent_index'] = payload.location.index;
    }
    await store.insert('original_page_position_group', positionValues);
  }

  private async insertIdentities(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation, pageCount: number): Promise<string[]> {
    const pageIds: string[] = [];
    for (let index: number = 0; index < pageCount; index++) {
      const identity: OriginalSequenceIdentity = {
        timestamp: operation.timestamp, siteId: operation.siteId, index: index,
      };
      const pageId: string = encodeOriginalPageStorageId(operation.noteId, identity);
      await store.insert('original_page_identity', {
        'note_id': operation.noteId,
        'seq_timestamp': identity.timestamp,
        'seq_site_id': identity.siteId,
        'seq_index': identity.index,
        'page_id': pageId,
        'visible': 1,
      });
      await store.insert('original_page_position', {
        'note_id': operation.noteId,
        'pos_timestamp': identity.timestamp,
        'pos_site_id': identity.siteId,
        'pos_index': identity.index,
        'page_timestamp': identity.timestamp,
        'page_site_id': identity.siteId,
        'page_index': identity.index,
      });
      await store.insert('original_page_position_winner', {
        'note_id': operation.noteId,
        'page_timestamp': identity.timestamp,
        'page_site_id': identity.siteId,
        'page_index': identity.index,
        'winner_timestamp': identity.timestamp,
        'winner_site_id': identity.siteId,
        'position_index': identity.index,
      });
      pageIds.push(pageId);
    }
    return pageIds;
  }

  private async readOriginalVisibleOrder(store: relationalStore.RdbStore,
    noteId: string): Promise<string[]> {
    const rows = await store.querySql(
      `SELECT groups.op_timestamp, groups.op_site_id, groups.parent_timestamp,
        groups.parent_site_id, groups.parent_index, groups.position_count,
        positions.pos_index, positions.page_timestamp, positions.page_site_id,
        positions.page_index, pages.page_id, pages.visible,
        winners.winner_timestamp, winners.winner_site_id, winners.position_index,
        COALESCE(visibility.deleted, 0) AS deleted
       FROM original_page_position_group groups
       JOIN original_page_position positions ON positions.note_id = groups.note_id
        AND positions.pos_timestamp = groups.op_timestamp
        AND positions.pos_site_id = groups.op_site_id
       JOIN original_page_identity pages ON pages.note_id = positions.note_id
        AND pages.seq_timestamp = positions.page_timestamp
        AND pages.seq_site_id = positions.page_site_id
        AND pages.seq_index = positions.page_index
       JOIN original_page_position_winner winners ON winners.note_id = positions.note_id
        AND winners.page_timestamp = positions.page_timestamp
        AND winners.page_site_id = positions.page_site_id
        AND winners.page_index = positions.page_index
       LEFT JOIN original_page_visibility_winner visibility ON visibility.note_id = positions.note_id
        AND visibility.page_timestamp = positions.page_timestamp
        AND visibility.page_site_id = positions.page_site_id
        AND visibility.page_index = positions.page_index
       WHERE groups.note_id = ?
       ORDER BY groups.op_timestamp, groups.op_site_id, positions.pos_index`, [noteId]);
    const groups: Map<string, OriginalPageInsertGroup> = new Map<string, OriginalPageInsertGroup>();
    try {
      while (rows.goToNextRow()) {
        const operation: OriginalSequenceIdentity = {
          timestamp: rows.getLong(rows.getColumnIndex('op_timestamp')),
          siteId: rows.getLong(rows.getColumnIndex('op_site_id')),
          index: 0,
        };
        const key: string = this.operationKey(operation);
        let group: OriginalPageInsertGroup | undefined = groups.get(key);
        if (group === undefined) {
          const parentTimestampColumn: number = rows.getColumnIndex('parent_timestamp');
          const location: OriginalSequenceIdentity | null = rows.isColumnNull(parentTimestampColumn) ? null : {
            timestamp: rows.getLong(parentTimestampColumn),
            siteId: rows.getLong(rows.getColumnIndex('parent_site_id')),
            index: rows.getLong(rows.getColumnIndex('parent_index')),
          };
          group = {
            operation: operation,
            location: location,
            pageCount: rows.getLong(rows.getColumnIndex('position_count')),
            pages: [],
          };
          groups.set(key, group);
        }
        const pageIdColumn: number = rows.getColumnIndex('page_id');
        const position: OriginalSequenceIdentity = {
          timestamp: operation.timestamp, siteId: operation.siteId,
          index: rows.getLong(rows.getColumnIndex('pos_index')),
        };
        group.pages.push({
          position: position,
          page: {
            timestamp: rows.getLong(rows.getColumnIndex('page_timestamp')),
            siteId: rows.getLong(rows.getColumnIndex('page_site_id')),
            index: rows.getLong(rows.getColumnIndex('page_index')),
          },
          pageId: rows.isColumnNull(pageIdColumn) ? null : rows.getString(pageIdColumn),
          visible: rows.getLong(rows.getColumnIndex('visible')) === 1,
          active: rows.getLong(rows.getColumnIndex('winner_timestamp')) === position.timestamp &&
            rows.getLong(rows.getColumnIndex('winner_site_id')) === position.siteId &&
            rows.getLong(rows.getColumnIndex('position_index')) === position.index,
          deleted: rows.getLong(rows.getColumnIndex('deleted')) === 1,
        });
      }
    } finally {
      rows.close();
    }
    return this.flattenGroups(groups);
  }

  private flattenGroups(groups: Map<string, OriginalPageInsertGroup>): string[] {
    const children: Map<string, OriginalPageInsertGroup[]> =
      new Map<string, OriginalPageInsertGroup[]>();
    groups.forEach((group: OriginalPageInsertGroup): void => {
      this.validateStoredGroup(group);
      const parentKey: string = group.location === null ? 'ROOT' : encodeOriginalSequenceId(group.location);
      const siblings: OriginalPageInsertGroup[] | undefined = children.get(parentKey);
      if (siblings === undefined) {
        children.set(parentKey, [group]);
      } else {
        siblings.push(group);
      }
    });
    children.forEach((siblings: OriginalPageInsertGroup[]): void => {
      siblings.sort((left: OriginalPageInsertGroup, right: OriginalPageInsertGroup): number => {
        const leftLast: OriginalPagePositionRow = left.pages[left.pages.length - 1];
        const rightLast: OriginalPagePositionRow = right.pages[right.pages.length - 1];
        return -compareOriginalSequenceIdentity(leftLast.position, rightLast.position);
      });
    });

    const result: string[] = [];
    const visited: Set<string> = new Set<string>();
    this.appendChildren('ROOT', children, visited, result);
    if (visited.size !== groups.size) {
      throw new Error('original page sequence contains an orphan or cycle');
    }
    return result;
  }

  private appendChildren(parentKey: string, children: Map<string, OriginalPageInsertGroup[]>,
    visited: Set<string>, result: string[]): void {
    const groups: OriginalPageInsertGroup[] | undefined = children.get(parentKey);
    if (groups === undefined) {
      return;
    }
    for (const group of groups) {
      const groupKey: string = this.operationKey(group.operation);
      if (visited.has(groupKey)) {
        throw new Error('original page sequence contains a cycle');
      }
      visited.add(groupKey);
      for (const page of group.pages) {
        if (page.visible && page.active && !page.deleted) {
          if (page.pageId === null) {
            throw new Error('visible original page has no storage ID');
          }
          result.push(page.pageId);
        }
        this.appendChildren(encodeOriginalSequenceId(page.position), children, visited, result);
      }
    }
  }

  private validateStoredGroup(group: OriginalPageInsertGroup): void {
    validateOriginalSequenceIdentity(group.operation);
    if (!Number.isSafeInteger(group.pageCount) || group.pageCount < 1 ||
      group.pageCount > MAX_ORIGINAL_CREATE_PAGE_COUNT || group.pages.length !== group.pageCount) {
      throw new Error('stored original page insert group is incomplete');
    }
    if (group.location !== null) {
      validateOriginalSequenceIdentity(group.location);
    }
    for (let index: number = 0; index < group.pages.length; index++) {
      const page: OriginalPagePositionRow = group.pages[index];
      validateOriginalSequenceIdentity(page.position);
      validateOriginalSequenceIdentity(page.page);
      if (page.position.timestamp !== group.operation.timestamp ||
        page.position.siteId !== group.operation.siteId || page.position.index !== index ||
        page.visible !== (page.pageId !== null)) {
        throw new Error('stored original page position does not match its insert group');
      }
    }
  }

  private operationKey(identity: OriginalSequenceIdentity): string {
    return `${identity.timestamp.toString(16)}:${identity.siteId.toString(16)}`;
  }

  private samePageIds(left: string[], right: string[]): boolean {
    if (left.length !== right.length) {
      return false;
    }
    for (let index: number = 0; index < left.length; index++) {
      if (left[index] !== right[index]) {
        return false;
      }
    }
    return true;
  }

  private async moveExistingPagesToTemporaryIndexes(store: relationalStore.RdbStore,
    noteId: string, pageIds: string[]): Promise<void> {
    for (let index: number = 0; index < pageIds.length; index++) {
      await this.updatePageIndex(store, noteId, pageIds[index], -(index + 1));
    }
  }

  private async insertBlankPages(store: relationalStore.RdbStore, noteId: string,
    pageIds: string[], existingPageCount: number): Promise<void> {
    for (let index: number = 0; index < pageIds.length; index++) {
      await store.insert('page_info', {
        'page_id': pageIds[index],
        'note_id': noteId,
        'page_index': -(existingPageCount + index + 1),
        'size': PaperSize.LETTER,
        'template': PaperTemplate.PLAIN,
        'orientation': PageOrientation.PORTRAIT,
        'width_mm': ORIGINAL_DEFAULT_PAGE_WIDTH_MM,
        'height_mm': ORIGINAL_DEFAULT_PAGE_HEIGHT_MM,
        'content_revision': 0,
      });
    }
  }

  private async assignFinalIndexes(store: relationalStore.RdbStore,
    noteId: string, pageIds: string[]): Promise<void> {
    const seen: Set<string> = new Set<string>();
    for (let index: number = 0; index < pageIds.length; index++) {
      if (seen.has(pageIds[index])) {
        throw new Error('original page sequence materialized a page twice');
      }
      seen.add(pageIds[index]);
      await this.updatePageIndex(store, noteId, pageIds[index], index);
    }
  }

  private async updatePageIndex(store: relationalStore.RdbStore, noteId: string,
    pageId: string, pageIndex: number): Promise<void> {
    const predicates = new relationalStore.RdbPredicates('page_info');
    predicates.equalTo('note_id', noteId);
    predicates.equalTo('page_id', pageId);
    const updated: number = await store.update({ 'page_index': pageIndex }, predicates);
    if (updated !== 1) {
      throw new Error(`original page index update affected ${updated} rows`);
    }
  }

  private async advanceStructureRevision(store: relationalStore.RdbStore, noteId: string): Promise<void> {
    const rows = await store.querySql('SELECT structure_revision FROM note_meta WHERE id = ?', [noteId]);
    let revision: number;
    try {
      if (!rows.goToFirstRow()) {
        throw new Error('original create-page note does not exist');
      }
      revision = rows.getLong(rows.getColumnIndex('structure_revision'));
    } finally {
      rows.close();
    }
    if (!Number.isSafeInteger(revision) || revision < 0 || revision >= Number.MAX_SAFE_INTEGER) {
      throw new Error('note structure revision is invalid or exhausted');
    }
    const predicates = new relationalStore.RdbPredicates('note_meta');
    predicates.equalTo('id', noteId);
    predicates.equalTo('structure_revision', revision);
    const updated: number = await store.update({ 'structure_revision': revision + 1 }, predicates);
    if (updated !== 1) {
      throw new Error('note structure revision changed while applying original create-page');
    }
  }
}
