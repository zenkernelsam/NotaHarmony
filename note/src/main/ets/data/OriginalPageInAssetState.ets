import { relationalStore } from '@kit.ArkData';
import { compareOperationIdentity, OperationIdentity, OriginalSequenceIdentity } from './OperationIdentity';
import { StoredSyncedOperation } from './SyncedOperationInbox';

interface StoredPageInAssetWinner extends OperationIdentity {
  pageInAsset: number;
}

export async function initializeOriginalPageInAsset(store: relationalStore.RdbStore,
  noteId: string, page: OriginalSequenceIdentity, winner: OperationIdentity,
  pageInAsset: number): Promise<void> {
  validatePageInAsset(pageInAsset);
  await store.insert('original_page_in_asset_winner', {
    'note_id': noteId,
    'page_timestamp': page.timestamp,
    'page_site_id': page.siteId,
    'page_index': page.index,
    'winner_timestamp': winner.timestamp,
    'winner_site_id': winner.siteId,
    'page_in_asset': pageInAsset,
  });
}

export async function applyOriginalPageInAsset(store: relationalStore.RdbStore,
  operation: StoredSyncedOperation, page: OriginalSequenceIdentity,
  pageInAsset: number): Promise<boolean> {
  validatePageInAsset(pageInAsset);
  const previous: StoredPageInAssetWinner | null = await readWinner(store, operation.noteId, page);
  if (previous !== null) {
    const compared: number = compareOperationIdentity(operation, previous);
    if (compared < 0) {
      return false;
    }
    if (compared === 0) {
      if (previous.pageInAsset !== pageInAsset) {
        throw new Error('original pageInAsset register has an identity conflict');
      }
      return false;
    }
  }
  const values: relationalStore.ValuesBucket = {
    'note_id': operation.noteId,
    'page_timestamp': page.timestamp,
    'page_site_id': page.siteId,
    'page_index': page.index,
    'winner_timestamp': operation.timestamp,
    'winner_site_id': operation.siteId,
    'page_in_asset': pageInAsset,
  };
  if (previous === null) {
    await store.insert('original_page_in_asset_winner', values);
  } else {
    const predicates = winnerPredicates(operation.noteId, page, previous);
    if (await store.update(values, predicates) !== 1) {
      throw new Error('original pageInAsset winner changed concurrently');
    }
  }
  await materializePageInAsset(store, operation.noteId, page, pageInAsset);
  return true;
}

async function readWinner(store: relationalStore.RdbStore, noteId: string,
  page: OriginalSequenceIdentity): Promise<StoredPageInAssetWinner | null> {
  const rows = await store.querySql(
    `SELECT winner_timestamp, winner_site_id, page_in_asset
     FROM original_page_in_asset_winner WHERE note_id = ?
       AND page_timestamp = ? AND page_site_id = ? AND page_index = ?`,
    [noteId, page.timestamp, page.siteId, page.index]);
  try {
    if (!rows.goToFirstRow()) {
      return null;
    }
    return {
      timestamp: rows.getLong(rows.getColumnIndex('winner_timestamp')),
      siteId: rows.getLong(rows.getColumnIndex('winner_site_id')),
      pageInAsset: rows.getLong(rows.getColumnIndex('page_in_asset')),
    };
  } finally {
    rows.close();
  }
}

function winnerPredicates(noteId: string, page: OriginalSequenceIdentity,
  winner: OperationIdentity): relationalStore.RdbPredicates {
  const predicates = new relationalStore.RdbPredicates('original_page_in_asset_winner');
  predicates.equalTo('note_id', noteId);
  predicates.equalTo('page_timestamp', page.timestamp);
  predicates.equalTo('page_site_id', page.siteId);
  predicates.equalTo('page_index', page.index);
  predicates.equalTo('winner_timestamp', winner.timestamp);
  predicates.equalTo('winner_site_id', winner.siteId);
  return predicates;
}

async function materializePageInAsset(store: relationalStore.RdbStore, noteId: string,
  page: OriginalSequenceIdentity, pageInAsset: number): Promise<void> {
  const identity = await store.querySql(
    `SELECT page_id FROM original_page_identity WHERE note_id = ?
       AND seq_timestamp = ? AND seq_site_id = ? AND seq_index = ?`,
    [noteId, page.timestamp, page.siteId, page.index]);
  let pageId: string | null;
  try {
    if (!identity.goToFirstRow()) {
      throw new Error('original pageInAsset page identity is missing');
    }
    const column: number = identity.getColumnIndex('page_id');
    pageId = identity.isColumnNull(column) ? null : identity.getString(column);
  } finally {
    identity.close();
  }
  if (pageId === null) {
    return;
  }
  const live = new relationalStore.RdbPredicates('page_info');
  live.equalTo('note_id', noteId);
  live.equalTo('page_id', pageId);
  const liveUpdated: number = await store.update({ 'original_page_in_asset': pageInAsset }, live);
  if (liveUpdated === 1) {
    return;
  }
  if (liveUpdated !== 0) {
    throw new Error(`original pageInAsset updated ${liveUpdated} live pages`);
  }
  const archived = new relationalStore.RdbPredicates('original_deleted_page');
  archived.equalTo('note_id', noteId);
  archived.equalTo('page_timestamp', page.timestamp);
  archived.equalTo('page_site_id', page.siteId);
  archived.equalTo('page_index', page.index);
  if (await store.update({ 'original_page_in_asset': pageInAsset }, archived) !== 1) {
    throw new Error('original pageInAsset archived page is missing');
  }
}

function validatePageInAsset(value: number): void {
  if (!Number.isSafeInteger(value) || value < 0 || value > 4294967295) {
    throw new Error('original pageInAsset is not uint32');
  }
}
