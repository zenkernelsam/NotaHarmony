import { relationalStore } from '@kit.ArkData';
import { validateOriginalNoteTitleWireValue } from '../core/model/OriginalNoteTitlePolicy';
import { HistoryMetadata, OpType } from '../core/model/OpTypes';
import { encodeNoteTitleMutation } from './NoteTitleMutationCodec';
import { encodeOriginalOperationEnvelope } from './OriginalOperationEnvelopeEncoder';
import { encodeOriginalSetMetadataTitle } from './OriginalSetMetadataPayloadEncoder';
import {
  ORIGINAL_SET_METADATA_PAYLOAD_TYPE, OriginalSetMetadataOperationApplier,
} from './OriginalSetMetadataOperation';
import { allocateOperationIdentity, AllocatedOperationIdentity, appendOperation } from './OpStoreImpl';
import {
  StoredSyncedOperation, SyncedOperationApplyResult, SyncedOperationInboxState,
} from './SyncedOperationInbox';

interface StoredNoteTitleState {
  title: string;
  structureRevision: number;
}

export interface PersistedOriginalNoteTitle {
  before: string;
  after: string;
  originalPayload: Uint8Array;
}

// Caller owns the database transaction and shared database writer mutex.
export async function persistOriginalNoteTitle(store: relationalStore.RdbStore,
  noteId: string, requested: string, selectedPageId?: string,
  history?: HistoryMetadata): Promise<PersistedOriginalNoteTitle> {
  if (noteId.length === 0) {
    throw new Error('local note title requires a note identity');
  }
  validateOriginalNoteTitleWireValue(requested);
  if (history !== undefined) {
    if (selectedPageId === undefined || selectedPageId.length === 0) {
      throw new Error('local note title history requires a selected page identity');
    }
    await requireLiveSelectedPage(store, noteId, selectedPageId);
  }
  const before: StoredNoteTitleState = await readTitleState(store, noteId);
  validateOriginalNoteTitleWireValue(before.title);
  if (before.title === requested) {
    throw new Error('local SET_METADATA note title is unchanged');
  }

  const identity: AllocatedOperationIdentity = await allocateOperationIdentity(store, noteId);
  const payloadTable: Uint8Array = encodeOriginalSetMetadataTitle(requested);
  const rawOperation: Uint8Array = encodeOriginalOperationEnvelope({
    identity: { timestamp: identity.timestamp, siteId: identity.siteId },
    clientTime: identity.clientTime.toString(), serverTime: null, audioTime: null,
    payloadType: ORIGINAL_SET_METADATA_PAYLOAD_TYPE,
  }, payloadTable);
  const operation: StoredSyncedOperation = storedOperation(noteId, identity, rawOperation);
  const applied: SyncedOperationApplyResult = await new OriginalSetMetadataOperationApplier().apply(
    store, operation);
  if (applied.deferredReason !== null) {
    throw new Error(`local title SET_METADATA was deferred: ${applied.deferredReason}`);
  }
  const after: StoredNoteTitleState = await readTitleState(store, noteId);
  if (after.title !== requested) {
    throw new Error('local SET_METADATA reducer produced an unexpected note title');
  }
  if (after.structureRevision !== before.structureRevision + 1) {
    throw new Error('local title SET_METADATA did not advance structure revision exactly once');
  }
  await touchNoteUpdatedAt(store, noteId, identity.clientTime);
  await appendOperation(store, {
    noteId: noteId, opId: identity.opId, opType: OpType.ORIGINAL_SET_METADATA,
    payload: rawOperation, clientTime: identity.clientTime,
    opTimestamp: identity.timestamp, editorSiteId: identity.siteId, uploadImmediately: true,
  });
  if (history !== undefined && selectedPageId !== undefined) {
    const companion: AllocatedOperationIdentity = await allocateOperationIdentity(store, noteId);
    await appendOperation(store, {
      noteId: noteId, opId: companion.opId, opType: OpType.UPDATE_TITLE,
      payload: encodeNoteTitleMutation({
        fromRevision: before.structureRevision, toRevision: after.structureRevision,
        selectedPageId: selectedPageId, before: before.title, after: after.title,
      }),
      clientTime: companion.clientTime, opTimestamp: companion.timestamp,
      editorSiteId: companion.siteId, history: history,
    });
  }
  return { before: before.title, after: after.title, originalPayload: rawOperation };
}

async function readTitleState(store: relationalStore.RdbStore,
  noteId: string): Promise<StoredNoteTitleState> {
  const rows = await store.querySql(
    'SELECT title, structure_revision FROM note_meta WHERE id = ?', [noteId]);
  try {
    if (!rows.goToFirstRow()) {
      throw new Error('local SET_METADATA note does not exist');
    }
    const structureRevision: number = rows.getLong(rows.getColumnIndex('structure_revision'));
    if (!Number.isSafeInteger(structureRevision) || structureRevision < 0 ||
      structureRevision >= Number.MAX_SAFE_INTEGER) {
      throw new Error('local SET_METADATA structure revision is invalid or exhausted');
    }
    return {
      title: rows.getString(rows.getColumnIndex('title')),
      structureRevision: structureRevision,
    };
  } finally {
    rows.close();
  }
}

async function requireLiveSelectedPage(store: relationalStore.RdbStore, noteId: string,
  pageId: string): Promise<void> {
  const rows = await store.querySql(
    'SELECT 1 FROM page_info WHERE note_id = ? AND page_id = ? LIMIT 1', [noteId, pageId]);
  try {
    if (!rows.goToFirstRow()) {
      throw new Error('local note title selected page is not live in the note');
    }
  } finally {
    rows.close();
  }
}

async function touchNoteUpdatedAt(store: relationalStore.RdbStore, noteId: string,
  updatedAt: number): Promise<void> {
  const rows = await store.querySql('SELECT updated_at FROM note_meta WHERE id = ?', [noteId]);
  let current: number;
  try {
    if (!rows.goToFirstRow()) {
      throw new Error('local note title metadata row does not exist');
    }
    current = rows.getLong(rows.getColumnIndex('updated_at'));
  } finally {
    rows.close();
  }
  if (!Number.isSafeInteger(current) || current < 0 ||
    !Number.isSafeInteger(updatedAt) || updatedAt < 0) {
    throw new Error('local note title metadata time is invalid');
  }
  const predicates = new relationalStore.RdbPredicates('note_meta');
  predicates.equalTo('id', noteId);
  if (await store.update({ 'updated_at': Math.max(current, updatedAt) }, predicates) !== 1) {
    throw new Error('local note title could not update note metadata time');
  }
}

function storedOperation(noteId: string, identity: AllocatedOperationIdentity,
  rawOperation: Uint8Array): StoredSyncedOperation {
  return {
    noteId: noteId, timestamp: identity.timestamp, siteId: identity.siteId,
    clientTime: identity.clientTime.toString(), serverTime: '0', audioTime: null,
    schemaVersion: 1, payloadType: ORIGINAL_SET_METADATA_PAYLOAD_TYPE,
    rawOperation: rawOperation, state: SyncedOperationInboxState.APPLIED,
    deferredReason: null, receivedAt: identity.clientTime,
  };
}
