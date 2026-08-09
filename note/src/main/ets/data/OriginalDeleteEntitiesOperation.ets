import { relationalStore } from '@kit.ArkData';
import {
  compareOperationIdentity, encodeOriginalSequenceId, OperationIdentity,
  OriginalSequenceIdentity, validateOriginalSequenceIdentity,
} from './OperationIdentity';
import { OriginalPageOrderStore } from './OriginalPageOrderStore';
import {
  OriginalFlatBufferTableReader, readOriginalPayloadTable,
} from './OriginalSyncedOperationFlatBuffer';
import {
  StoredSyncedOperation, SyncedOperationApplier, SyncedOperationApplyResult,
} from './SyncedOperationInbox';

export const ORIGINAL_DELETE_ENTITIES_PAYLOAD_TYPE: number = 25;
export const MAX_ORIGINAL_DELETE_ENTITY_COUNT: number = 10000;

export interface OriginalDeleteEntitiesPayload {
  entityDeleteCount: number;
  entityUndeleteCount: number;
  pageDeletes: OriginalSequenceIdentity[];
  pageUndeletes: OriginalSequenceIdentity[];
}

interface StoredPageIdentity {
  identity: OriginalSequenceIdentity;
  pageId: string | null;
}

interface VisibilityWinner extends OperationIdentity {
  deleted: boolean;
}

export function decodeOriginalDeleteEntities(bytes: Uint8Array): OriginalDeleteEntitiesPayload {
  const table: OriginalFlatBufferTableReader =
    readOriginalPayloadTable(bytes, ORIGINAL_DELETE_ENTITIES_PAYLOAD_TYPE);
  return decodeOriginalDeleteEntitiesTable(table);
}

export function decodeOriginalDeleteEntitiesTable(
  table: OriginalFlatBufferTableReader): OriginalDeleteEntitiesPayload {
  return {
    entityDeleteCount: table.readInlineVectorCount(0, 8, MAX_ORIGINAL_DELETE_ENTITY_COUNT),
    entityUndeleteCount: table.readInlineVectorCount(1, 8, MAX_ORIGINAL_DELETE_ENTITY_COUNT),
    pageDeletes: decodePageVector(table, 2),
    pageUndeletes: decodePageVector(table, 3),
  };
}

function decodePageVector(table: OriginalFlatBufferTableReader,
  field: number): OriginalSequenceIdentity[] {
  const rawPages: number[][] = table.readInlineSequenceVector(field, MAX_ORIGINAL_DELETE_ENTITY_COUNT);
  const pages: OriginalSequenceIdentity[] = [];
  const seen: Set<string> = new Set<string>();
  for (const raw of rawPages) {
    const page: OriginalSequenceIdentity = {
      timestamp: raw[0], siteId: raw[1], index: raw[2],
    };
    validateOriginalSequenceIdentity(page);
    const key: string = encodeOriginalSequenceId(page);
    if (!seen.has(key)) {
      seen.add(key);
      pages.push(page);
    }
  }
  return pages;
}

export class OriginalDeleteEntitiesOperationApplier implements SyncedOperationApplier {
  private orderStore: OriginalPageOrderStore = new OriginalPageOrderStore();

  supports(payloadType: number): boolean {
    return payloadType === ORIGINAL_DELETE_ENTITIES_PAYLOAD_TYPE;
  }

  async apply(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation): Promise<SyncedOperationApplyResult> {
    let payload: OriginalDeleteEntitiesPayload;
    try {
      payload = decodeOriginalDeleteEntities(operation.rawOperation);
    } catch (_error) {
      return { deferredReason: 'MALFORMED_DELETE_ENTITIES_PAYLOAD' };
    }
    if (payload.entityDeleteCount > 0 || payload.entityUndeleteCount > 0) {
      return { deferredReason: 'DELETE_ENTITIES_ENTITY_MUTATION_UNSUPPORTED' };
    }
    if (payload.pageDeletes.length === 0 && payload.pageUndeletes.length === 0) {
      return { deferredReason: 'DELETE_ENTITIES_HAS_NO_PAGES' };
    }

    const affected: StoredPageIdentity[] = [];
    const affectedKeys: Set<string> = new Set<string>();
    for (const page of payload.pageDeletes) {
      const stored: StoredPageIdentity | null = await this.readPageIdentity(store, operation.noteId, page);
      if (stored === null) {
        return { deferredReason: 'DELETE_ENTITIES_PAGE_MISSING' };
      }
      affected.push(stored);
      affectedKeys.add(encodeOriginalSequenceId(page));
    }
    for (const page of payload.pageUndeletes) {
      const key: string = encodeOriginalSequenceId(page);
      if (affectedKeys.has(key)) {
        continue;
      }
      const stored: StoredPageIdentity | null = await this.readPageIdentity(store, operation.noteId, page);
      if (stored === null) {
        return { deferredReason: 'DELETE_ENTITIES_PAGE_MISSING' };
      }
      affected.push(stored);
      affectedKeys.add(key);
    }

    const storedOrder: string[] = await this.orderStore.readStoredPageIds(store, operation.noteId);
    const originalOrder: string[] =
      await this.orderStore.readOriginalVisibleOrder(store, operation.noteId);
    if (!this.orderStore.samePageIds(storedOrder, originalOrder)) {
      return { deferredReason: 'ORIGINAL_PAGE_ORDER_DIVERGED' };
    }
    for (const page of affected) {
      if (!await this.storageMatchesWinner(store, operation.noteId, page)) {
        return { deferredReason: 'ORIGINAL_PAGE_VISIBILITY_DIVERGED' };
      }
      if (page.pageId === null && !await this.unboundPageRemainsDeleted(
        store, operation.noteId, operation, page.identity, payload)) {
        return { deferredReason: 'DELETE_ENTITIES_UNBOUND_PAGE_CONTENT_UNAVAILABLE' };
      }
    }

    // Move every live row out of the final non-negative index domain before delete/restore.
    await this.orderStore.assignTemporaryIndexes(store, operation.noteId, storedOrder);
    let restoredCount: number = 0;
    for (const page of payload.pageDeletes) {
      restoredCount = await this.applyVisibility(store, operation, page, true,
        storedOrder.length, restoredCount);
    }
    // v69 applies deletes before undeletes, so an identity present in both ends visible.
    for (const page of payload.pageUndeletes) {
      restoredCount = await this.applyVisibility(store, operation, page, false,
        storedOrder.length, restoredCount);
    }

    const newOrder: string[] = await this.orderStore.readOriginalVisibleOrder(store, operation.noteId);
    const liveIds: string[] = await this.orderStore.readStoredPageIds(store, operation.noteId);
    if (liveIds.length !== newOrder.length || !this.sameSet(liveIds, newOrder)) {
      throw new Error('original page visibility changed the wrong storage page set');
    }
    await this.orderStore.assignFinalIndexes(store, operation.noteId, newOrder);
    await this.orderStore.advanceStructureRevision(store, operation.noteId, 'delete-entities');
    return { deferredReason: null };
  }

  private async applyVisibility(store: relationalStore.RdbStore, operation: StoredSyncedOperation,
    page: OriginalSequenceIdentity, deleted: boolean,
    initialLiveCount: number, restoredCount: number): Promise<number> {
    const winner: VisibilityWinner | null = await this.readWinner(store, operation.noteId, page);
    if (winner !== null && compareOperationIdentity(operation, winner) < 0) {
      return restoredCount;
    }
    const wasDeleted: boolean = winner === null ? false : winner.deleted;
    if (wasDeleted !== deleted) {
      if (deleted) {
        await this.archivePage(store, operation.noteId, page);
      } else {
        await this.restorePage(store, operation.noteId, page,
          -(initialLiveCount + restoredCount + 1));
        restoredCount++;
      }
    }
    await this.writeWinner(store, operation.noteId, page, operation, deleted, winner);
    return restoredCount;
  }

  private async readPageIdentity(store: relationalStore.RdbStore, noteId: string,
    identity: OriginalSequenceIdentity): Promise<StoredPageIdentity | null> {
    const rows = await store.querySql(
      `SELECT page_id, visible FROM original_page_identity
       WHERE note_id = ? AND seq_timestamp = ? AND seq_site_id = ? AND seq_index = ?`,
      [noteId, identity.timestamp, identity.siteId, identity.index]);
    try {
      if (!rows.goToFirstRow()) {
        return null;
      }
      const pageIdColumn: number = rows.getColumnIndex('page_id');
      const bound: boolean = rows.getLong(rows.getColumnIndex('visible')) === 1;
      if (!bound) {
        return rows.isColumnNull(pageIdColumn) ? { identity: identity, pageId: null } : null;
      }
      if (rows.isColumnNull(pageIdColumn)) {
        return null;
      }
      const pageId: string = rows.getString(pageIdColumn);
      return pageId.length === 0 ? null : { identity: identity, pageId: pageId };
    } finally {
      rows.close();
    }
  }

  private async storageMatchesWinner(store: relationalStore.RdbStore,
    noteId: string, page: StoredPageIdentity): Promise<boolean> {
    const winner: VisibilityWinner | null = await this.readWinner(store, noteId, page.identity);
    const deleted: boolean = winner === null ? false : winner.deleted;
    if (page.pageId === null) {
      const archivedExists: boolean = await this.rowExists(store,
        `SELECT 1 FROM original_deleted_page
         WHERE note_id = ? AND page_timestamp = ? AND page_site_id = ? AND page_index = ? LIMIT 1`,
        [noteId, page.identity.timestamp, page.identity.siteId, page.identity.index]);
      return winner !== null && deleted && !archivedExists;
    }
    const liveExists: boolean = await this.rowExists(store,
      'SELECT 1 FROM page_info WHERE note_id = ? AND page_id = ? LIMIT 1', [noteId, page.pageId]);
    const liveValid: boolean = await this.rowExists(store,
      `SELECT 1 FROM page_info live
       LEFT JOIN search_page_state state ON state.note_id = live.note_id AND state.page_id = live.page_id
       WHERE live.note_id = ? AND live.page_id = ? AND live.content_revision >= 0
        AND (state.indexed_revision IS NULL OR
          (state.indexed_revision >= 0 AND state.indexed_revision <= live.content_revision)) LIMIT 1`,
      [noteId, page.pageId]);
    const archivedExists: boolean = await this.rowExists(store,
      `SELECT 1 FROM original_deleted_page
       WHERE note_id = ? AND page_timestamp = ? AND page_site_id = ? AND page_index = ? LIMIT 1`,
      [noteId, page.identity.timestamp, page.identity.siteId, page.identity.index]);
    const archivedValid: boolean = await this.rowExists(store,
      `SELECT 1 FROM original_deleted_page
       WHERE note_id = ? AND page_timestamp = ? AND page_site_id = ? AND page_index = ?
        AND page_id = ? AND content_revision >= 0
        AND (indexed_revision IS NULL OR
          (indexed_revision >= 0 AND indexed_revision <= content_revision)) LIMIT 1`,
      [noteId, page.identity.timestamp, page.identity.siteId, page.identity.index, page.pageId]);
    return deleted ? !liveExists && archivedExists && archivedValid :
      liveExists && liveValid && !archivedExists;
  }

  private async unboundPageRemainsDeleted(store: relationalStore.RdbStore, noteId: string,
    operation: OperationIdentity, page: OriginalSequenceIdentity,
    payload: OriginalDeleteEntitiesPayload): Promise<boolean> {
    const winner: VisibilityWinner | null = await this.readWinner(store, noteId, page);
    if (winner === null || !winner.deleted) {
      return false;
    }
    let deleted: boolean = winner.deleted;
    if (compareOperationIdentity(operation, winner) >= 0 &&
      this.containsPage(payload.pageDeletes, page)) {
      deleted = true;
    }
    // Delete is applied first, so an undelete in the same winning payload requires content.
    if (compareOperationIdentity(operation, winner) >= 0 &&
      this.containsPage(payload.pageUndeletes, page)) {
      deleted = false;
    }
    return deleted;
  }

  private containsPage(pages: OriginalSequenceIdentity[],
    expected: OriginalSequenceIdentity): boolean {
    const expectedKey: string = encodeOriginalSequenceId(expected);
    for (const page of pages) {
      if (encodeOriginalSequenceId(page) === expectedKey) {
        return true;
      }
    }
    return false;
  }

  private async readWinner(store: relationalStore.RdbStore, noteId: string,
    page: OriginalSequenceIdentity): Promise<VisibilityWinner | null> {
    const rows = await store.querySql(
      `SELECT winner_timestamp, winner_site_id, deleted
       FROM original_page_visibility_winner
       WHERE note_id = ? AND page_timestamp = ? AND page_site_id = ? AND page_index = ?`,
      [noteId, page.timestamp, page.siteId, page.index]);
    try {
      if (!rows.goToFirstRow()) {
        return null;
      }
      return {
        timestamp: rows.getLong(rows.getColumnIndex('winner_timestamp')),
        siteId: rows.getLong(rows.getColumnIndex('winner_site_id')),
        deleted: rows.getLong(rows.getColumnIndex('deleted')) === 1,
      };
    } finally {
      rows.close();
    }
  }

  private async writeWinner(store: relationalStore.RdbStore, noteId: string,
    page: OriginalSequenceIdentity, operation: OperationIdentity,
    deleted: boolean, previous: VisibilityWinner | null): Promise<void> {
    if (previous === null) {
      await store.insert('original_page_visibility_winner', {
        'note_id': noteId,
        'page_timestamp': page.timestamp,
        'page_site_id': page.siteId,
        'page_index': page.index,
        'winner_timestamp': operation.timestamp,
        'winner_site_id': operation.siteId,
        'deleted': deleted ? 1 : 0,
      });
      return;
    }
    const predicates = new relationalStore.RdbPredicates('original_page_visibility_winner');
    predicates.equalTo('note_id', noteId);
    predicates.equalTo('page_timestamp', page.timestamp);
    predicates.equalTo('page_site_id', page.siteId);
    predicates.equalTo('page_index', page.index);
    predicates.equalTo('winner_timestamp', previous.timestamp);
    predicates.equalTo('winner_site_id', previous.siteId);
    predicates.equalTo('deleted', previous.deleted ? 1 : 0);
    const updated: number = await store.update({
      'winner_timestamp': operation.timestamp,
      'winner_site_id': operation.siteId,
      'deleted': deleted ? 1 : 0,
    }, predicates);
    if (updated !== 1) {
      throw new Error('original page visibility winner changed concurrently');
    }
  }

  private async archivePage(store: relationalStore.RdbStore,
    noteId: string, page: OriginalSequenceIdentity): Promise<void> {
    const identity: StoredPageIdentity | null = await this.readPageIdentity(store, noteId, page);
    if (identity === null || identity.pageId === null) {
      throw new Error('cannot archive an unbound original page');
    }
    const rows = await store.querySql(
      `SELECT size, template, orientation, width_mm, height_mm, content_revision,
        (SELECT indexed_revision FROM search_page_state state
          WHERE state.note_id = page.note_id AND state.page_id = page.page_id) AS indexed_revision
       FROM page_info page WHERE note_id = ? AND page_id = ?`, [noteId, identity.pageId]);
    let values: relationalStore.ValuesBucket;
    try {
      if (!rows.goToFirstRow()) {
        throw new Error('original page to delete is not live');
      }
      const indexedColumn: number = rows.getColumnIndex('indexed_revision');
      values = {
        'note_id': noteId,
        'page_timestamp': page.timestamp,
        'page_site_id': page.siteId,
        'page_index': page.index,
        'page_id': identity.pageId,
        'size': rows.getLong(rows.getColumnIndex('size')),
        'template': rows.getLong(rows.getColumnIndex('template')),
        'orientation': rows.getLong(rows.getColumnIndex('orientation')),
        'width_mm': rows.getDouble(rows.getColumnIndex('width_mm')),
        'height_mm': rows.getDouble(rows.getColumnIndex('height_mm')),
        'content_revision': rows.getLong(rows.getColumnIndex('content_revision')),
        'indexed_revision': rows.isColumnNull(indexedColumn) ? null : rows.getLong(indexedColumn),
      };
    } finally {
      rows.close();
    }
    await store.insert('original_deleted_page', values);
    await store.executeSql(
      `INSERT INTO original_deleted_page_element
        (note_id, page_timestamp, page_site_id, page_index,
         element_id, kind, payload, revision, element_order)
       SELECT ?, ?, ?, ?, element_id, kind, payload, revision, element_order
       FROM page_element_snapshot WHERE note_id = ? AND page_id = ?`,
      [noteId, page.timestamp, page.siteId, page.index, noteId, identity.pageId]);
    await store.executeSql(
      `INSERT INTO original_deleted_page_search
        (note_id, page_timestamp, page_site_id, page_index, type, sub_id, folded_text, rects)
       SELECT ?, ?, ?, ?, type, sub_id, folded_text, rects
       FROM search_item WHERE note_id = ? AND page_id = ?`,
      [noteId, page.timestamp, page.siteId, page.index, noteId, identity.pageId]);
    const predicates = new relationalStore.RdbPredicates('page_info');
    predicates.equalTo('note_id', noteId);
    predicates.equalTo('page_id', identity.pageId);
    const deleted: number = await store.delete(predicates);
    if (deleted !== 1) {
      throw new Error(`original page delete affected ${deleted} rows`);
    }
  }

  private async restorePage(store: relationalStore.RdbStore, noteId: string,
    page: OriginalSequenceIdentity, temporaryIndex: number): Promise<void> {
    const rows = await store.querySql(
      `SELECT page_id, size, template, orientation, width_mm, height_mm,
        content_revision, indexed_revision
       FROM original_deleted_page
       WHERE note_id = ? AND page_timestamp = ? AND page_site_id = ? AND page_index = ?`,
      [noteId, page.timestamp, page.siteId, page.index]);
    let values: relationalStore.ValuesBucket;
    let pageId: string;
    let indexedRevision: number | null;
    try {
      if (!rows.goToFirstRow()) {
        throw new Error('original deleted page archive does not exist');
      }
      pageId = rows.getString(rows.getColumnIndex('page_id'));
      const indexedColumn: number = rows.getColumnIndex('indexed_revision');
      indexedRevision = rows.isColumnNull(indexedColumn) ? null : rows.getLong(indexedColumn);
      values = {
        'page_id': pageId,
        'note_id': noteId,
        'page_index': temporaryIndex,
        'size': rows.getLong(rows.getColumnIndex('size')),
        'template': rows.getLong(rows.getColumnIndex('template')),
        'orientation': rows.getLong(rows.getColumnIndex('orientation')),
        'width_mm': rows.getDouble(rows.getColumnIndex('width_mm')),
        'height_mm': rows.getDouble(rows.getColumnIndex('height_mm')),
        'content_revision': rows.getLong(rows.getColumnIndex('content_revision')),
      };
    } finally {
      rows.close();
    }
    await store.insert('page_info', values);
    await store.executeSql(
      `INSERT INTO page_element_snapshot
        (note_id, page_id, element_id, kind, payload, revision, element_order)
       SELECT ?, ?, element_id, kind, payload, revision, element_order
       FROM original_deleted_page_element
       WHERE note_id = ? AND page_timestamp = ? AND page_site_id = ? AND page_index = ?`,
      [noteId, pageId, noteId, page.timestamp, page.siteId, page.index]);
    await store.executeSql(
      `INSERT INTO search_item (note_id, type, sub_id, page_id, folded_text, rects)
       SELECT ?, type, sub_id, ?, folded_text, rects
       FROM original_deleted_page_search
       WHERE note_id = ? AND page_timestamp = ? AND page_site_id = ? AND page_index = ?`,
      [noteId, pageId, noteId, page.timestamp, page.siteId, page.index]);
    if (indexedRevision !== null) {
      await store.insert('search_page_state', {
        'note_id': noteId, 'page_id': pageId, 'indexed_revision': indexedRevision,
      });
    }
    const predicates = new relationalStore.RdbPredicates('original_deleted_page');
    predicates.equalTo('note_id', noteId);
    predicates.equalTo('page_timestamp', page.timestamp);
    predicates.equalTo('page_site_id', page.siteId);
    predicates.equalTo('page_index', page.index);
    const deleted: number = await store.delete(predicates);
    if (deleted !== 1) {
      throw new Error(`original deleted page archive cleanup affected ${deleted} rows`);
    }
  }

  private async rowExists(store: relationalStore.RdbStore, sql: string,
    args: relationalStore.ValueType[]): Promise<boolean> {
    const rows = await store.querySql(sql, args);
    try {
      return rows.goToFirstRow();
    } finally {
      rows.close();
    }
  }

  private sameSet(left: string[], right: string[]): boolean {
    if (left.length !== right.length) {
      return false;
    }
    const values: Set<string> = new Set<string>(left);
    if (values.size !== left.length) {
      return false;
    }
    for (const value of right) {
      if (!values.has(value)) {
        return false;
      }
    }
    return true;
  }
}
