import { relationalStore } from '@kit.ArkData';
import { OpType } from '../core/model/OpTypes';
import { PageInfo, PaperTemplate } from '../core/model/NoteTypes';
import { clonePageInfo, parsePageBackground } from '../core/model/PageBackgroundModel';
import { encodeOriginalLocalCreatePage } from './OriginalCreatePagePayloadEncoder';
import {
  ORIGINAL_CREATE_PAGE_PAYLOAD_TYPE, OriginalCreatePageOperationApplier,
} from './OriginalCreatePageOperation';
import { encodeOriginalModifyPageMove } from './OriginalModifyPagePayloadEncoder';
import {
  ORIGINAL_MODIFY_PAGE_PAYLOAD_TYPE, OriginalModifyPageOperationApplier,
} from './OriginalModifyPageOperation';
import { encodeOriginalPageStorageId, OriginalSequenceIdentity } from './OperationIdentity';
import { allocateOperationIdentity, AllocatedOperationIdentity, appendOperation } from './OpStoreImpl';
import { OriginalPageOrderStore } from './OriginalPageOrderStore';
import {
  OriginalPageReorderPlan, planOriginalPageReorder,
} from './OriginalPageReorderPlanner';
import {
  encodeOriginalPageVisibility,
} from './OriginalDeleteEntitiesPayloadEncoder';
import {
  ORIGINAL_DELETE_ENTITIES_PAYLOAD_TYPE, OriginalDeleteEntitiesOperationApplier,
} from './OriginalDeleteEntitiesOperation';
import {
  StoredSyncedOperation, SyncedOperationApplyResult, SyncedOperationInboxState,
} from './SyncedOperationInbox';
import { encodeOriginalOperationEnvelope } from './OriginalOperationEnvelopeEncoder';

export interface PersistedOriginalPageMutation {
  page: PageInfo;
  payload: Uint8Array;
}

export interface PersistedOriginalPageReorder {
  movedPageId: string;
  predecessorPageId: string | null;
  payload: Uint8Array;
}

export async function hasCompleteOriginalPageIdentity(store: relationalStore.RdbStore,
  noteId: string): Promise<boolean> {
  const rows = await store.querySql(
    `SELECT (SELECT COUNT(*) FROM page_info WHERE note_id = ?) AS live_count,
      (SELECT COUNT(*) FROM page_info page JOIN original_page_identity identity
        ON identity.note_id = page.note_id AND identity.page_id = page.page_id
       WHERE page.note_id = ? AND identity.visible = 1) AS mapped_count`, [noteId, noteId]);
  try {
    if (!rows.goToFirstRow()) {
      throw new Error('original page coverage query returned no row');
    }
    return rows.getLong(rows.getColumnIndex('live_count')) ===
      rows.getLong(rows.getColumnIndex('mapped_count'));
  } finally {
    rows.close();
  }
}

export async function hasAlignedOriginalPageState(store: relationalStore.RdbStore,
  noteId: string): Promise<boolean> {
  if (!await hasCompleteOriginalPageIdentity(store, noteId)) {
    return false;
  }
  const orderStore: OriginalPageOrderStore = new OriginalPageOrderStore();
  return orderStore.samePageIds(await orderStore.readStoredPageIds(store, noteId),
    await orderStore.readOriginalVisibleOrder(store, noteId));
}

export async function persistOriginalCreatePage(store: relationalStore.RdbStore, noteId: string,
  requestedPage: PageInfo | null): Promise<PersistedOriginalPageMutation> {
  if (noteId.length === 0 || !await hasAlignedOriginalPageState(store, noteId)) {
    throw new Error('local CreatePage requires complete original page identity coverage');
  }
  if (requestedPage !== null && (requestedPage.template !== PaperTemplate.PLAIN ||
    (requestedPage.background !== undefined && requestedPage.background !== null))) {
    throw new Error('local CreatePage cannot encode a styled or asset-backed page yet');
  }
  const location: OriginalSequenceIdentity | null = await readTailPosition(store, noteId);
  const identity: AllocatedOperationIdentity = await allocateOperationIdentity(store, noteId);
  const payload: Uint8Array = requestedPage === null
    ? encodeOriginalLocalCreatePage(location)
    : encodeOriginalLocalCreatePage(location, requestedPage.widthMm, requestedPage.heightMm);
  const operation: StoredSyncedOperation = storedOperation(
    noteId, identity, ORIGINAL_CREATE_PAGE_PAYLOAD_TYPE, payload);
  const result: SyncedOperationApplyResult = await new OriginalCreatePageOperationApplier().apply(
    store, operation);
  if (result.deferredReason !== null) {
    throw new Error(`local CreatePage was deferred: ${result.deferredReason}`);
  }
  await appendOperation(store, {
    noteId: noteId, opId: identity.opId, opType: OpType.ORIGINAL_CREATE_PAGE,
    payload: operation.rawOperation, clientTime: identity.clientTime, opTimestamp: identity.timestamp,
    editorSiteId: identity.siteId, uploadImmediately: true,
  });
  const pageId: string = encodeOriginalPageStorageId(noteId, {
    timestamp: identity.timestamp, siteId: identity.siteId, index: 0,
  });
  return { page: await readPage(store, noteId, pageId), payload: operation.rawOperation };
}

export async function persistOriginalPageVisibility(store: relationalStore.RdbStore,
  noteId: string, pageId: string, deleted: boolean): Promise<PersistedOriginalPageMutation> {
  if (!await hasAlignedOriginalPageState(store, noteId)) {
    throw new Error('local page visibility requires complete original page identity coverage');
  }
  const page: OriginalSequenceIdentity = await readPageIdentity(store, noteId, pageId);
  const identity: AllocatedOperationIdentity = await allocateOperationIdentity(store, noteId);
  const payload: Uint8Array = encodeOriginalPageVisibility(
    deleted ? [page] : [], deleted ? [] : [page]);
  const operation: StoredSyncedOperation = storedOperation(
    noteId, identity, ORIGINAL_DELETE_ENTITIES_PAYLOAD_TYPE, payload);
  const result: SyncedOperationApplyResult = await new OriginalDeleteEntitiesOperationApplier().apply(
    store, operation);
  if (result.deferredReason !== null) {
    throw new Error(`local page visibility was deferred: ${result.deferredReason}`);
  }
  await appendOperation(store, {
    noteId: noteId, opId: identity.opId, opType: OpType.ORIGINAL_DELETE_ENTITIES,
    payload: operation.rawOperation, clientTime: identity.clientTime, opTimestamp: identity.timestamp,
    editorSiteId: identity.siteId, uploadImmediately: true,
  });
  return { page: deleted ? emptyArchivedPage(pageId) : await readPage(store, noteId, pageId),
    payload: operation.rawOperation };
}

export async function persistOriginalPageReorder(store: relationalStore.RdbStore,
  noteId: string, requestedOrder: string[], movedPageId: string): Promise<PersistedOriginalPageReorder> {
  if (noteId.length === 0 || !await hasAlignedOriginalPageState(store, noteId)) {
    throw new Error('local ModifyPage requires complete aligned original page identity coverage');
  }
  const orderStore: OriginalPageOrderStore = new OriginalPageOrderStore();
  const currentOrder: string[] = await orderStore.readStoredPageIds(store, noteId);
  const plan: OriginalPageReorderPlan = planOriginalPageReorder(
    currentOrder, requestedOrder, movedPageId);
  const movedPage: OriginalSequenceIdentity = await readPageIdentity(
    store, noteId, plan.movedPageId);
  const moveTo: OriginalSequenceIdentity | null = plan.predecessorPageId === null ? null :
    await readWinningPosition(store, noteId, plan.predecessorPageId);
  const identity: AllocatedOperationIdentity = await allocateOperationIdentity(store, noteId);
  const payload: Uint8Array = encodeOriginalModifyPageMove([movedPage], moveTo);
  const operation: StoredSyncedOperation = storedOperation(
    noteId, identity, ORIGINAL_MODIFY_PAGE_PAYLOAD_TYPE, payload);
  const result: SyncedOperationApplyResult = await new OriginalModifyPageOperationApplier().apply(
    store, operation);
  if (result.deferredReason !== null) {
    throw new Error(`local ModifyPage was deferred: ${result.deferredReason}`);
  }
  const materializedOrder: string[] = await orderStore.readStoredPageIds(store, noteId);
  if (!orderStore.samePageIds(materializedOrder, requestedOrder)) {
    throw new Error('local ModifyPage reducer produced an unexpected page order');
  }
  const originalOrder: string[] = await orderStore.readOriginalVisibleOrder(store, noteId);
  if (!orderStore.samePageIds(originalOrder, requestedOrder)) {
    throw new Error('local ModifyPage CRDT order diverged after reducer apply');
  }
  await appendOperation(store, {
    noteId: noteId, opId: identity.opId, opType: OpType.ORIGINAL_MODIFY_PAGE,
    payload: operation.rawOperation, clientTime: identity.clientTime, opTimestamp: identity.timestamp,
    editorSiteId: identity.siteId, uploadImmediately: true,
  });
  return {
    movedPageId: plan.movedPageId,
    predecessorPageId: plan.predecessorPageId,
    payload: operation.rawOperation,
  };
}

export async function originalPageIdentityExists(store: relationalStore.RdbStore,
  noteId: string, pageId: string): Promise<boolean> {
  const rows = await store.querySql(
    'SELECT 1 FROM original_page_identity WHERE note_id = ? AND page_id = ? LIMIT 1',
    [noteId, pageId]);
  try {
    return rows.goToFirstRow();
  } finally {
    rows.close();
  }
}

async function readTailPosition(store: relationalStore.RdbStore,
  noteId: string): Promise<OriginalSequenceIdentity | null> {
  const rows = await store.querySql(
    `SELECT winner.winner_timestamp, winner.winner_site_id, winner.position_index
       FROM page_info page JOIN original_page_identity identity
         ON identity.note_id = page.note_id AND identity.page_id = page.page_id
       JOIN original_page_position_winner winner ON winner.note_id = identity.note_id
        AND winner.page_timestamp = identity.seq_timestamp
        AND winner.page_site_id = identity.seq_site_id AND winner.page_index = identity.seq_index
      WHERE page.note_id = ? ORDER BY page.page_index DESC LIMIT 1`, [noteId]);
  try {
    if (!rows.goToFirstRow()) {
      return null;
    }
    return {
      timestamp: rows.getLong(rows.getColumnIndex('winner_timestamp')),
      siteId: rows.getLong(rows.getColumnIndex('winner_site_id')),
      index: rows.getLong(rows.getColumnIndex('position_index')),
    };
  } finally {
    rows.close();
  }
}

async function readWinningPosition(store: relationalStore.RdbStore, noteId: string,
  pageId: string): Promise<OriginalSequenceIdentity> {
  const rows = await store.querySql(
    `SELECT winner.winner_timestamp, winner.winner_site_id, winner.position_index
       FROM original_page_identity identity JOIN original_page_position_winner winner
         ON winner.note_id = identity.note_id
        AND winner.page_timestamp = identity.seq_timestamp
        AND winner.page_site_id = identity.seq_site_id
        AND winner.page_index = identity.seq_index
      WHERE identity.note_id = ? AND identity.page_id = ? AND identity.visible = 1`,
    [noteId, pageId]);
  try {
    if (!rows.goToFirstRow()) {
      throw new Error('local ModifyPage predecessor has no winning position');
    }
    return {
      timestamp: rows.getLong(rows.getColumnIndex('winner_timestamp')),
      siteId: rows.getLong(rows.getColumnIndex('winner_site_id')),
      index: rows.getLong(rows.getColumnIndex('position_index')),
    };
  } finally {
    rows.close();
  }
}

async function readPageIdentity(store: relationalStore.RdbStore, noteId: string,
  pageId: string): Promise<OriginalSequenceIdentity> {
  const rows = await store.querySql(
    `SELECT seq_timestamp, seq_site_id, seq_index FROM original_page_identity
      WHERE note_id = ? AND page_id = ?`, [noteId, pageId]);
  try {
    if (!rows.goToFirstRow()) {
      throw new Error('original page identity does not exist');
    }
    return {
      timestamp: rows.getLong(rows.getColumnIndex('seq_timestamp')),
      siteId: rows.getLong(rows.getColumnIndex('seq_site_id')),
      index: rows.getLong(rows.getColumnIndex('seq_index')),
    };
  } finally {
    rows.close();
  }
}

async function readPage(store: relationalStore.RdbStore, noteId: string,
  pageId: string): Promise<PageInfo> {
  const rows = await store.querySql(
    `SELECT page_id, page_index, size, template, orientation, width_mm, height_mm,
      background_json, original_page_in_asset
       FROM page_info WHERE note_id = ? AND page_id = ?`, [noteId, pageId]);
  try {
    if (!rows.goToFirstRow()) {
      throw new Error('materialized original page does not exist');
    }
    const backgroundColumn: number = rows.getColumnIndex('background_json');
    const pageInAssetColumn: number = rows.getColumnIndex('original_page_in_asset');
    return clonePageInfo({
      pageId: rows.getString(rows.getColumnIndex('page_id')),
      pageIndex: rows.getLong(rows.getColumnIndex('page_index')),
      size: rows.getLong(rows.getColumnIndex('size')),
      template: rows.getLong(rows.getColumnIndex('template')),
      orientation: rows.getLong(rows.getColumnIndex('orientation')),
      widthMm: rows.getDouble(rows.getColumnIndex('width_mm')),
      heightMm: rows.getDouble(rows.getColumnIndex('height_mm')),
      background: parsePageBackground(rows.isColumnNull(backgroundColumn) ? null :
        rows.getString(backgroundColumn)),
      originalPageInAsset: rows.isColumnNull(pageInAssetColumn) ? 0 :
        rows.getLong(pageInAssetColumn),
    });
  } finally {
    rows.close();
  }
}

function storedOperation(noteId: string, identity: AllocatedOperationIdentity,
  payloadType: number, payload: Uint8Array): StoredSyncedOperation {
  const rawOperation: Uint8Array = encodeOriginalOperationEnvelope({
    identity: { timestamp: identity.timestamp, siteId: identity.siteId },
    clientTime: identity.clientTime.toString(), serverTime: null, audioTime: null,
    payloadType: payloadType,
  }, payload);
  return {
    noteId: noteId, timestamp: identity.timestamp, siteId: identity.siteId,
    clientTime: identity.clientTime.toString(), serverTime: '0', audioTime: null,
    schemaVersion: 1, payloadType: payloadType, rawOperation: rawOperation,
    state: SyncedOperationInboxState.APPLIED, deferredReason: null,
    receivedAt: identity.clientTime,
  };
}

function emptyArchivedPage(pageId: string): PageInfo {
  return {
    pageId: pageId, pageIndex: -1, size: 0, template: 0, orientation: 0,
    widthMm: 1, heightMm: 1,
  };
}
