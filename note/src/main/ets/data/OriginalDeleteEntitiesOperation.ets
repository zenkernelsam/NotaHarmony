import { relationalStore } from '@kit.ArkData';
import {
  compareOperationIdentity, encodeOperationId, encodeOriginalSequenceId, OperationIdentity,
  OriginalSequenceIdentity, validateOperationIdentity, validateOriginalSequenceIdentity,
} from './OperationIdentity';
import { OriginalPageOrderStore } from './OriginalPageOrderStore';
import {
  OriginalFlatBufferTableReader, readOriginalPayloadTable,
} from './OriginalSyncedOperationFlatBuffer';
import {
  StoredSyncedOperation, SyncedOperationApplier, SyncedOperationApplyResult,
} from './SyncedOperationInbox';
import { compareUnsignedLongDecimal } from './UnsignedDecimal';

export const ORIGINAL_DELETE_ENTITIES_PAYLOAD_TYPE: number = 25;
export const MAX_ORIGINAL_DELETE_ENTITY_COUNT: number = 10000;

export interface OriginalDeleteEntitiesPayload {
  entityDeletes: OperationIdentity[];
  entityUndeletes: OperationIdentity[];
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

interface StoredEntityTarget {
  entity: OperationIdentity;
  page: OriginalSequenceIdentity;
  pageId: string;
  kind: number;
  zIndex: string;
  visible: boolean;
  archivedPage: boolean;
  pageTable: string;
  revisionTable: string;
  revision: number;
}

interface StoredEntitySnapshot {
  elementId: string;
  kind: number;
  payload: Uint8Array;
  revision: number;
  elementOrder: number;
}

interface PlannedEntityVisibility {
  target: StoredEntityTarget;
  winner: VisibilityWinner | null;
  deleted: boolean;
  changesVisibility: boolean;
}

interface StoredEntityOrderRow {
  elementId: string;
  kind: number;
  timestamp: number;
  siteId: number;
  zIndex: string;
}

export function decodeOriginalDeleteEntities(bytes: Uint8Array): OriginalDeleteEntitiesPayload {
  const table: OriginalFlatBufferTableReader =
    readOriginalPayloadTable(bytes, ORIGINAL_DELETE_ENTITIES_PAYLOAD_TYPE);
  return decodeOriginalDeleteEntitiesTable(table);
}

export function decodeOriginalDeleteEntitiesTable(
  table: OriginalFlatBufferTableReader): OriginalDeleteEntitiesPayload {
  const entityDeletes: OperationIdentity[] = decodeEntityVector(table, 0);
  const entityUndeletes: OperationIdentity[] = decodeEntityVector(table, 1);
  return {
    entityDeletes: entityDeletes,
    entityUndeletes: entityUndeletes,
    entityDeleteCount: entityDeletes.length,
    entityUndeleteCount: entityUndeletes.length,
    pageDeletes: decodePageVector(table, 2),
    pageUndeletes: decodePageVector(table, 3),
  };
}

function decodeEntityVector(table: OriginalFlatBufferTableReader,
  field: number): OperationIdentity[] {
  const rawEntities: number[][] = table.readInlineOperationIdentityVector(
    field, MAX_ORIGINAL_DELETE_ENTITY_COUNT);
  const entities: OperationIdentity[] = [];
  const seen: Set<string> = new Set<string>();
  for (const raw of rawEntities) {
    const entity: OperationIdentity = { timestamp: raw[0], siteId: raw[1] };
    validateOperationIdentity(entity);
    const key: string = encodeOperationId(entity);
    if (!seen.has(key)) {
      seen.add(key);
      entities.push(entity);
    }
  }
  return entities;
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
    return this.applyPayload(store, operation, payload, true);
  }

  preflightTable(table: OriginalFlatBufferTableReader): string | null {
    let payload: OriginalDeleteEntitiesPayload;
    try {
      payload = decodeOriginalDeleteEntitiesTable(table);
    } catch (_error) {
      return 'MALFORMED_DELETE_ENTITIES_PAYLOAD';
    }
    return payload.entityDeletes.length === 0 && payload.entityUndeletes.length === 0 &&
      payload.pageDeletes.length === 0 && payload.pageUndeletes.length === 0 ?
      'DELETE_ENTITIES_HAS_NO_TARGETS' : null;
  }

  async applyEntityTable(store: relationalStore.RdbStore, operation: StoredSyncedOperation,
    table: OriginalFlatBufferTableReader): Promise<SyncedOperationApplyResult> {
    let payload: OriginalDeleteEntitiesPayload;
    try {
      payload = decodeOriginalDeleteEntitiesTable(table);
    } catch (_error) {
      return { deferredReason: 'MALFORMED_DELETE_ENTITIES_PAYLOAD' };
    }
    if (payload.entityDeletes.length === 0 && payload.entityUndeletes.length === 0) {
      return { deferredReason: null };
    }
    return this.applyPayload(store, operation, payload, false);
  }

  private async applyPayload(store: relationalStore.RdbStore, operation: StoredSyncedOperation,
    payload: OriginalDeleteEntitiesPayload, applyPages: boolean): Promise<SyncedOperationApplyResult> {
    if (payload.entityDeletes.length === 0 && payload.entityUndeletes.length === 0 &&
      (!applyPages || (payload.pageDeletes.length === 0 && payload.pageUndeletes.length === 0))) {
      return { deferredReason: 'DELETE_ENTITIES_HAS_NO_PAGES' };
    }
    const affected: StoredPageIdentity[] = [];
    const affectedKeys: Set<string> = new Set<string>();
    let storedOrder: string[] = [];
    const appliesPageVisibility: boolean = applyPages &&
      (payload.pageDeletes.length > 0 || payload.pageUndeletes.length > 0);
    if (appliesPageVisibility) {
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

      storedOrder = await this.orderStore.readStoredPageIds(store, operation.noteId);
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
    }

    // All page checks must precede entity writes: the inbox commits a deferred result.
    const entityReason: string | null = await this.applyEntityVisibility(store, operation, payload);
    if (entityReason !== null) {
      return { deferredReason: entityReason };
    }
    if (!appliesPageVisibility) {
      return { deferredReason: null };
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

  private async applyEntityVisibility(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation, payload: OriginalDeleteEntitiesPayload): Promise<string | null> {
    const desired: Map<string, { entity: OperationIdentity, deleted: boolean }> =
      new Map<string, { entity: OperationIdentity, deleted: boolean }>();
    for (const entity of payload.entityDeletes) {
      desired.set(encodeOperationId(entity), { entity: entity, deleted: true });
    }
    // Original v69 applies deletes before undeletes, so undelete wins within one payload.
    for (const entity of payload.entityUndeletes) {
      desired.set(encodeOperationId(entity), { entity: entity, deleted: false });
    }
    if (desired.size === 0) {
      return null;
    }

    const planned: PlannedEntityVisibility[] = [];
    const affectedPages: Map<string, StoredEntityTarget> = new Map<string, StoredEntityTarget>();
    for (const desiredVisibility of desired.values()) {
      const target: StoredEntityTarget | null = await this.readEntityTarget(
        store, operation.noteId, desiredVisibility.entity);
      if (target === null) {
        return 'DELETE_ENTITIES_ENTITY_MISSING_OR_UNBOUND';
      }
      const winner: VisibilityWinner | null = await this.readEntityWinner(
        store, operation.noteId, desiredVisibility.entity);
      if (!await this.entityStorageMatches(store, operation.noteId, target, winner)) {
        return 'ORIGINAL_ENTITY_VISIBILITY_DIVERGED';
      }
      if (winner !== null) {
        const comparison: number = compareOperationIdentity(operation, winner);
        if (comparison === 0 && winner.deleted !== desiredVisibility.deleted) {
          throw new Error('original entity visibility identity conflicts with persisted value');
        }
        if (comparison <= 0) {
          continue;
        }
      }
      const changesVisibility: boolean = target.visible === desiredVisibility.deleted;
      planned.push({
        target: target, winner: winner, deleted: desiredVisibility.deleted,
        changesVisibility: changesVisibility,
      });
      if (changesVisibility) {
        affectedPages.set(encodeOriginalSequenceId(target.page), target);
      }
    }

    for (const mutation of planned) {
      if (mutation.changesVisibility) {
        if (mutation.deleted) {
          await this.archiveEntity(store, operation.noteId, mutation.target);
        } else {
          await this.restoreEntity(store, operation.noteId, mutation.target);
        }
      }
      await this.writeEntityWinner(store, operation.noteId, mutation.target.entity,
        operation, mutation.deleted, mutation.winner);
    }
    for (const target of affectedPages.values()) {
      if (!await this.materializeEntityOrder(store, operation.noteId, target)) {
        throw new Error('original entity order diverged after visibility mutation');
      }
      await this.advanceEntityPageRevision(store, operation.noteId, target);
    }
    return null;
  }

  private async readEntityTarget(store: relationalStore.RdbStore, noteId: string,
    entity: OperationIdentity): Promise<StoredEntityTarget | null> {
    const rows = await store.querySql(
      `SELECT element.page_timestamp, element.page_site_id, element.page_index,
              element.kind, element.z_index, element.visible, identity.page_id, identity.visible AS bound
       FROM original_element_z_index element
       JOIN original_page_identity identity ON identity.note_id = element.note_id
        AND identity.seq_timestamp = element.page_timestamp
        AND identity.seq_site_id = element.page_site_id AND identity.seq_index = element.page_index
       WHERE element.note_id = ? AND element.element_timestamp = ? AND element.element_site_id = ?`,
      [noteId, entity.timestamp, entity.siteId]);
    let page: OriginalSequenceIdentity;
    let pageId: string;
    let kind: number;
    let zIndex: string;
    let visible: boolean;
    try {
      if (!rows.goToFirstRow() || rows.getLong(rows.getColumnIndex('bound')) !== 1 ||
        rows.isColumnNull(rows.getColumnIndex('page_id'))) {
        return null;
      }
      page = {
        timestamp: rows.getLong(rows.getColumnIndex('page_timestamp')),
        siteId: rows.getLong(rows.getColumnIndex('page_site_id')),
        index: rows.getLong(rows.getColumnIndex('page_index')),
      };
      validateOriginalSequenceIdentity(page);
      pageId = rows.getString(rows.getColumnIndex('page_id'));
      kind = rows.getLong(rows.getColumnIndex('kind'));
      zIndex = rows.getString(rows.getColumnIndex('z_index'));
      visible = rows.getLong(rows.getColumnIndex('visible')) === 1;
    } finally {
      rows.close();
    }
    if (pageId.length === 0 || kind < 1 || kind > 5) {
      return null;
    }
    const liveRevision: number | null = await this.readSingleRevision(store,
      'SELECT content_revision FROM page_info WHERE note_id = ? AND page_id = ?', [noteId, pageId]);
    const archivedRevision: number | null = await this.readSingleRevision(store,
      `SELECT content_revision FROM original_deleted_page WHERE note_id = ?
       AND page_timestamp = ? AND page_site_id = ? AND page_index = ?`,
      [noteId, page.timestamp, page.siteId, page.index]);
    if ((liveRevision === null) === (archivedRevision === null)) {
      return null;
    }
    return {
      entity: entity, page: page, pageId: pageId, kind: kind, zIndex: zIndex, visible: visible,
      archivedPage: archivedRevision !== null,
      pageTable: archivedRevision !== null ? 'original_deleted_page_element' : 'page_element_snapshot',
      revisionTable: archivedRevision !== null ? 'original_deleted_page' : 'page_info',
      revision: archivedRevision !== null ? archivedRevision : liveRevision as number,
    };
  }

  private async entityStorageMatches(store: relationalStore.RdbStore, noteId: string,
    target: StoredEntityTarget, winner: VisibilityWinner | null): Promise<boolean> {
    if ((winner === null && !target.visible) ||
      (winner !== null && winner.deleted === target.visible)) {
      return false;
    }
    const elementId: string = encodeOperationId(target.entity);
    const activeCount: number = target.archivedPage ? await this.countRows(store,
      `SELECT COUNT(*) AS value FROM original_deleted_page_element WHERE note_id = ?
       AND page_timestamp = ? AND page_site_id = ? AND page_index = ?
       AND element_id = ? AND kind = ?`,
      [noteId, target.page.timestamp, target.page.siteId, target.page.index,
        elementId, target.kind]) : await this.countRows(store,
      `SELECT COUNT(*) AS value FROM page_element_snapshot WHERE note_id = ? AND page_id = ?
       AND element_id = ? AND kind = ?`, [noteId, target.pageId, elementId, target.kind]);
    const deletedCount: number = await this.countRows(store,
      `SELECT COUNT(*) AS value FROM original_deleted_entity WHERE note_id = ?
       AND entity_timestamp = ? AND entity_site_id = ? AND page_timestamp = ?
       AND page_site_id = ? AND page_index = ? AND element_id = ? AND kind = ?`,
      [noteId, target.entity.timestamp, target.entity.siteId, target.page.timestamp,
        target.page.siteId, target.page.index, elementId, target.kind]);
    return target.visible ? activeCount === 1 && deletedCount === 0 :
      activeCount === 0 && deletedCount === 1;
  }

  private async archiveEntity(store: relationalStore.RdbStore, noteId: string,
    target: StoredEntityTarget): Promise<void> {
    const snapshot: StoredEntitySnapshot | null = await this.readActiveEntity(
      store, noteId, target);
    if (snapshot === null) {
      throw new Error('original entity to delete is not materialized');
    }
    await store.insert('original_deleted_entity', {
      'note_id': noteId,
      'entity_timestamp': target.entity.timestamp,
      'entity_site_id': target.entity.siteId,
      'page_timestamp': target.page.timestamp,
      'page_site_id': target.page.siteId,
      'page_index': target.page.index,
      'element_id': snapshot.elementId,
      'kind': snapshot.kind,
      'payload': snapshot.payload,
      'revision': snapshot.revision,
      'element_order': snapshot.elementOrder,
    });
    const deleted: number = await store.delete(this.entityPagePredicates(
      noteId, target, snapshot.elementId, snapshot.kind));
    if (deleted !== 1) {
      throw new Error('original entity delete lost its page snapshot');
    }
    await this.updateEntityVisible(store, noteId, target, true, false);
    target.visible = false;
  }

  private async restoreEntity(store: relationalStore.RdbStore, noteId: string,
    target: StoredEntityTarget): Promise<void> {
    const rows = await store.querySql(
      `SELECT element_id, kind, payload, revision, element_order FROM original_deleted_entity
       WHERE note_id = ? AND entity_timestamp = ? AND entity_site_id = ?`,
      [noteId, target.entity.timestamp, target.entity.siteId]);
    let snapshot: StoredEntitySnapshot;
    try {
      if (!rows.goToFirstRow()) {
        throw new Error('original deleted entity archive does not exist');
      }
      snapshot = {
        elementId: rows.getString(rows.getColumnIndex('element_id')),
        kind: rows.getLong(rows.getColumnIndex('kind')),
        payload: rows.getBlob(rows.getColumnIndex('payload')),
        revision: rows.getLong(rows.getColumnIndex('revision')),
        elementOrder: rows.getLong(rows.getColumnIndex('element_order')),
      };
    } finally {
      rows.close();
    }
    const values: relationalStore.ValuesBucket = {
      'note_id': noteId, 'element_id': snapshot.elementId, 'kind': snapshot.kind,
      'payload': snapshot.payload, 'revision': snapshot.revision,
      'element_order': snapshot.elementOrder,
    };
    if (target.archivedPage) {
      values['page_timestamp'] = target.page.timestamp;
      values['page_site_id'] = target.page.siteId;
      values['page_index'] = target.page.index;
    } else {
      values['page_id'] = target.pageId;
    }
    await store.insert(target.pageTable, values);
    const archivePredicates = new relationalStore.RdbPredicates('original_deleted_entity');
    archivePredicates.equalTo('note_id', noteId);
    archivePredicates.equalTo('entity_timestamp', target.entity.timestamp);
    archivePredicates.equalTo('entity_site_id', target.entity.siteId);
    if (await store.delete(archivePredicates) !== 1) {
      throw new Error('original entity restore lost its archive row');
    }
    await this.updateEntityVisible(store, noteId, target, false, true);
    target.visible = true;
  }

  private async readActiveEntity(store: relationalStore.RdbStore, noteId: string,
    target: StoredEntityTarget): Promise<StoredEntitySnapshot | null> {
    const elementId: string = encodeOperationId(target.entity);
    const rows = target.archivedPage ? await store.querySql(
      `SELECT element_id, kind, payload, revision, element_order
       FROM original_deleted_page_element WHERE note_id = ? AND page_timestamp = ?
       AND page_site_id = ? AND page_index = ? AND element_id = ? AND kind = ?`,
      [noteId, target.page.timestamp, target.page.siteId, target.page.index,
        elementId, target.kind]) : await store.querySql(
      `SELECT element_id, kind, payload, revision, element_order
       FROM page_element_snapshot WHERE note_id = ? AND page_id = ?
       AND element_id = ? AND kind = ?`, [noteId, target.pageId, elementId, target.kind]);
    try {
      if (!rows.goToFirstRow()) {
        return null;
      }
      return {
        elementId: rows.getString(rows.getColumnIndex('element_id')),
        kind: rows.getLong(rows.getColumnIndex('kind')),
        payload: rows.getBlob(rows.getColumnIndex('payload')),
        revision: rows.getLong(rows.getColumnIndex('revision')),
        elementOrder: rows.getLong(rows.getColumnIndex('element_order')),
      };
    } finally {
      rows.close();
    }
  }

  private entityPagePredicates(noteId: string, target: StoredEntityTarget,
    elementId: string, kind: number): relationalStore.RdbPredicates {
    const predicates = new relationalStore.RdbPredicates(target.pageTable);
    predicates.equalTo('note_id', noteId);
    if (target.archivedPage) {
      predicates.equalTo('page_timestamp', target.page.timestamp);
      predicates.equalTo('page_site_id', target.page.siteId);
      predicates.equalTo('page_index', target.page.index);
    } else {
      predicates.equalTo('page_id', target.pageId);
    }
    predicates.equalTo('element_id', elementId);
    predicates.equalTo('kind', kind);
    return predicates;
  }

  private async updateEntityVisible(store: relationalStore.RdbStore, noteId: string,
    target: StoredEntityTarget, expected: boolean, visible: boolean): Promise<void> {
    const predicates = new relationalStore.RdbPredicates('original_element_z_index');
    predicates.equalTo('note_id', noteId);
    predicates.equalTo('element_timestamp', target.entity.timestamp);
    predicates.equalTo('element_site_id', target.entity.siteId);
    predicates.equalTo('visible', expected ? 1 : 0);
    if (await store.update({ 'visible': visible ? 1 : 0 }, predicates) !== 1) {
      throw new Error('original entity visibility changed concurrently');
    }
  }

  private async readEntityWinner(store: relationalStore.RdbStore, noteId: string,
    entity: OperationIdentity): Promise<VisibilityWinner | null> {
    const rows = await store.querySql(
      `SELECT winner_timestamp, winner_site_id, deleted FROM original_entity_visibility_winner
       WHERE note_id = ? AND entity_timestamp = ? AND entity_site_id = ?`,
      [noteId, entity.timestamp, entity.siteId]);
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

  private async writeEntityWinner(store: relationalStore.RdbStore, noteId: string,
    entity: OperationIdentity, operation: OperationIdentity,
    deleted: boolean, previous: VisibilityWinner | null): Promise<void> {
    if (previous === null) {
      await store.insert('original_entity_visibility_winner', {
        'note_id': noteId,
        'entity_timestamp': entity.timestamp,
        'entity_site_id': entity.siteId,
        'winner_timestamp': operation.timestamp,
        'winner_site_id': operation.siteId,
        'deleted': deleted ? 1 : 0,
      });
      return;
    }
    const predicates = new relationalStore.RdbPredicates('original_entity_visibility_winner');
    predicates.equalTo('note_id', noteId);
    predicates.equalTo('entity_timestamp', entity.timestamp);
    predicates.equalTo('entity_site_id', entity.siteId);
    predicates.equalTo('winner_timestamp', previous.timestamp);
    predicates.equalTo('winner_site_id', previous.siteId);
    predicates.equalTo('deleted', previous.deleted ? 1 : 0);
    const updated: number = await store.update({
      'winner_timestamp': operation.timestamp,
      'winner_site_id': operation.siteId,
      'deleted': deleted ? 1 : 0,
    }, predicates);
    if (updated !== 1) {
      throw new Error('original entity visibility winner changed concurrently');
    }
  }

  private async materializeEntityOrder(store: relationalStore.RdbStore,
    noteId: string, target: StoredEntityTarget): Promise<boolean> {
    const tracked = await store.querySql(
      `SELECT element_timestamp, element_site_id, kind, z_index
       FROM original_element_z_index WHERE note_id = ? AND page_timestamp = ?
       AND page_site_id = ? AND page_index = ? AND visible = 1`,
      [noteId, target.page.timestamp, target.page.siteId, target.page.index]);
    const rows: StoredEntityOrderRow[] = [];
    const trackedKeys: Set<string> = new Set<string>();
    try {
      while (tracked.goToNextRow()) {
        const timestamp: number = tracked.getLong(tracked.getColumnIndex('element_timestamp'));
        const siteId: number = tracked.getLong(tracked.getColumnIndex('element_site_id'));
        const kind: number = tracked.getLong(tracked.getColumnIndex('kind'));
        const elementId: string = encodeOperationId({ timestamp: timestamp, siteId: siteId });
        rows.push({
          elementId: elementId, kind: kind, timestamp: timestamp, siteId: siteId,
          zIndex: tracked.getString(tracked.getColumnIndex('z_index')),
        });
        trackedKeys.add(`${kind}:${elementId}`);
      }
    } finally {
      tracked.close();
    }
    const existing = target.archivedPage ? await store.querySql(
      `SELECT element_id, kind FROM original_deleted_page_element WHERE note_id = ?
       AND page_timestamp = ? AND page_site_id = ? AND page_index = ?`,
      [noteId, target.page.timestamp, target.page.siteId, target.page.index]) :
      await store.querySql(
        'SELECT element_id, kind FROM page_element_snapshot WHERE note_id = ? AND page_id = ?',
        [noteId, target.pageId]);
    let count: number = 0;
    try {
      while (existing.goToNextRow()) {
        const key: string = `${existing.getLong(existing.getColumnIndex('kind'))}:` +
          existing.getString(existing.getColumnIndex('element_id'));
        if (!trackedKeys.has(key)) {
          return false;
        }
        count++;
      }
    } finally {
      existing.close();
    }
    if (count !== rows.length) {
      return false;
    }
    rows.sort(compareStoredEntityOrderRows);
    for (let index: number = 0; index < rows.length; index++) {
      const updated: number = await store.update({ 'element_order': index },
        this.entityPagePredicates(noteId, target, rows[index].elementId, rows[index].kind));
      if (updated !== 1) {
        throw new Error('original entity order materialization lost an element');
      }
    }
    return true;
  }

  private async advanceEntityPageRevision(store: relationalStore.RdbStore,
    noteId: string, target: StoredEntityTarget): Promise<void> {
    if (target.revision >= Number.MAX_SAFE_INTEGER) {
      throw new Error('original entity page revision exhausted');
    }
    const predicates = new relationalStore.RdbPredicates(target.revisionTable);
    predicates.equalTo('note_id', noteId);
    if (target.archivedPage) {
      predicates.equalTo('page_timestamp', target.page.timestamp);
      predicates.equalTo('page_site_id', target.page.siteId);
      predicates.equalTo('page_index', target.page.index);
    } else {
      predicates.equalTo('page_id', target.pageId);
    }
    predicates.equalTo('content_revision', target.revision);
    const values: relationalStore.ValuesBucket = { 'content_revision': target.revision + 1 };
    if (target.archivedPage) {
      values['indexed_revision'] = null;
    }
    if (await store.update(values, predicates) !== 1) {
      throw new Error('original entity page revision changed concurrently');
    }
    if (target.archivedPage) {
      await store.executeSql(
        `DELETE FROM original_deleted_page_search WHERE note_id = ? AND page_timestamp = ?
         AND page_site_id = ? AND page_index = ?`,
        [noteId, target.page.timestamp, target.page.siteId, target.page.index]);
    } else {
      await store.executeSql('DELETE FROM search_page_state WHERE note_id = ? AND page_id = ?',
        [noteId, target.pageId]);
      await store.executeSql('DELETE FROM search_item WHERE note_id = ? AND page_id = ?',
        [noteId, target.pageId]);
    }
  }

  private async readSingleRevision(store: relationalStore.RdbStore,
    sql: string, bindArgs: (string | number)[]): Promise<number | null> {
    const rows = await store.querySql(sql, bindArgs);
    try {
      if (!rows.goToFirstRow()) {
        return null;
      }
      const value: number = rows.getLong(rows.getColumnIndex('content_revision'));
      return Number.isSafeInteger(value) && value >= 0 ? value : null;
    } finally {
      rows.close();
    }
  }

  private async countRows(store: relationalStore.RdbStore,
    sql: string, bindArgs: (string | number)[]): Promise<number> {
    const rows = await store.querySql(sql, bindArgs);
    try {
      if (!rows.goToFirstRow()) {
        throw new Error('original entity count query returned no row');
      }
      return rows.getLong(rows.getColumnIndex('value'));
    } finally {
      rows.close();
    }
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
      `SELECT size, template, orientation, width_mm, height_mm, background_json, content_revision,
        (SELECT indexed_revision FROM search_page_state state
          WHERE state.note_id = page.note_id AND state.page_id = page.page_id) AS indexed_revision
       FROM page_info page WHERE note_id = ? AND page_id = ?`, [noteId, identity.pageId]);
    let values: relationalStore.ValuesBucket;
    try {
      if (!rows.goToFirstRow()) {
        throw new Error('original page to delete is not live');
      }
      const indexedColumn: number = rows.getColumnIndex('indexed_revision');
      const backgroundColumn: number = rows.getColumnIndex('background_json');
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
        'background_json': rows.isColumnNull(backgroundColumn) ? null : rows.getString(backgroundColumn),
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
      `SELECT page_id, size, template, orientation, width_mm, height_mm, background_json,
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
      const backgroundColumn: number = rows.getColumnIndex('background_json');
      values = {
        'page_id': pageId,
        'note_id': noteId,
        'page_index': temporaryIndex,
        'size': rows.getLong(rows.getColumnIndex('size')),
        'template': rows.getLong(rows.getColumnIndex('template')),
        'orientation': rows.getLong(rows.getColumnIndex('orientation')),
        'width_mm': rows.getDouble(rows.getColumnIndex('width_mm')),
        'height_mm': rows.getDouble(rows.getColumnIndex('height_mm')),
        'background_json': rows.isColumnNull(backgroundColumn) ? null : rows.getString(backgroundColumn),
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

function compareStoredEntityOrderRows(left: StoredEntityOrderRow,
  right: StoredEntityOrderRow): number {
  const zOrder: number = compareUnsignedLongDecimal(left.zIndex, right.zIndex);
  if (zOrder !== 0) {
    return zOrder;
  }
  if (left.timestamp !== right.timestamp) {
    return left.timestamp < right.timestamp ? -1 : 1;
  }
  if (left.siteId !== right.siteId) {
    return left.siteId < right.siteId ? -1 : 1;
  }
  return left.kind - right.kind;
}
