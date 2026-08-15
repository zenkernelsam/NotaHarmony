import { relationalStore } from '@kit.ArkData';
import { HistoryMetadata, OpType } from '../core/model/OpTypes';
import { NoteBackgroundSettings } from '../core/model/NoteTypes';
import {
  cloneNoteBackgroundSettings, sameNoteBackgroundSettings, validateNoteBackgroundSettings,
  originalPaperOrientation,
} from '../core/model/PageBackgroundModel';
import { encodeNoteBackgroundMutation } from './NoteBackgroundMutationCodec';
import { encodeOriginalOperationEnvelope } from './OriginalOperationEnvelopeEncoder';
import { hasAlignedOriginalPageState } from './OriginalPagePersistence';
import { encodeOriginalSetMetadataPageBackground } from './OriginalSetMetadataPayloadEncoder';
import {
  ORIGINAL_SET_METADATA_PAYLOAD_TYPE, OriginalSetMetadataOperationApplier,
  OriginalNoteBackgroundState, readOriginalNoteBackgroundState,
} from './OriginalSetMetadataOperation';
import { allocateOperationIdentity, AllocatedOperationIdentity, appendOperation } from './OpStoreImpl';
import {
  StoredSyncedOperation, SyncedOperationApplyResult, SyncedOperationInboxState,
} from './SyncedOperationInbox';

export interface PersistedOriginalNoteBackground {
  before: NoteBackgroundSettings;
  after: NoteBackgroundSettings;
  originalPayload: Uint8Array;
}

// Caller owns the database transaction and editorPersistenceMutex. The original envelope,
// reducer mutation and Harmony history companion either commit together or all roll back.
export async function persistOriginalNoteBackground(store: relationalStore.RdbStore,
  noteId: string, requested: NoteBackgroundSettings, selectedPageId: string,
  history?: HistoryMetadata): Promise<PersistedOriginalNoteBackground> {
  if (noteId.length === 0 || selectedPageId.length === 0) {
    throw new Error('local note background requires note and selected-page identities');
  }
  validateNoteBackgroundSettings(requested);
  if (!await hasAlignedOriginalPageState(store, noteId)) {
    throw new Error('local SET_METADATA requires complete aligned original page identity coverage');
  }
  await requireLiveSelectedPage(store, noteId, selectedPageId);
  const fromRevision: number = await readStructureRevision(store, noteId);
  const before: NoteBackgroundSettings = await readSettings(store, noteId);
  if (sameNoteBackgroundSettings(before, requested)) {
    throw new Error('local SET_METADATA note background is unchanged');
  }

  const identity: AllocatedOperationIdentity = await allocateOperationIdentity(store, noteId);
  const payloadTable: Uint8Array = encodeOriginalSetMetadataPageBackground(
    requested.registerBackground);
  const rawOperation: Uint8Array = encodeOriginalOperationEnvelope({
    identity: { timestamp: identity.timestamp, siteId: identity.siteId },
    clientTime: identity.clientTime.toString(), serverTime: null, audioTime: null,
    payloadType: ORIGINAL_SET_METADATA_PAYLOAD_TYPE,
  }, payloadTable);
  const operation: StoredSyncedOperation = storedOperation(noteId, identity, rawOperation);
  const applied: SyncedOperationApplyResult = await new OriginalSetMetadataOperationApplier().apply(
    store, operation);
  if (applied.deferredReason !== null) {
    throw new Error(`local SET_METADATA was deferred: ${applied.deferredReason}`);
  }
  const after: NoteBackgroundSettings = await readSettings(store, noteId);
  if (!sameNoteBackgroundSettings(after, requested)) {
    throw new Error('local SET_METADATA reducer produced an unexpected note background');
  }
  const toRevision: number = await readStructureRevision(store, noteId);
  if (toRevision !== fromRevision + 1) {
    throw new Error('local SET_METADATA did not advance structure revision exactly once');
  }
  await appendOperation(store, {
    noteId: noteId, opId: identity.opId, opType: OpType.ORIGINAL_SET_METADATA,
    payload: rawOperation, clientTime: identity.clientTime,
    opTimestamp: identity.timestamp, editorSiteId: identity.siteId, uploadImmediately: true,
  });
  if (history !== undefined) {
    const companion: AllocatedOperationIdentity = await allocateOperationIdentity(store, noteId);
    await appendOperation(store, {
      noteId: noteId, opId: companion.opId, opType: OpType.UPDATE_NOTE_BACKGROUND,
      payload: encodeNoteBackgroundMutation({
        fromRevision: fromRevision, toRevision: toRevision, selectedPageId: selectedPageId,
        before: before, after: after,
      }),
      clientTime: companion.clientTime, opTimestamp: companion.timestamp,
      editorSiteId: companion.siteId, history: history,
    });
  }
  return {
    before: cloneNoteBackgroundSettings(before),
    after: cloneNoteBackgroundSettings(after),
    originalPayload: rawOperation,
  };
}

async function readSettings(store: relationalStore.RdbStore,
  noteId: string): Promise<NoteBackgroundSettings> {
  const state: OriginalNoteBackgroundState = await readOriginalNoteBackgroundState(store, noteId);
  const value = state.effective;
  const result: NoteBackgroundSettings = {
    background: value.background,
    registerBackground: state.registerValue === null ? null : state.registerValue.background,
    template: value.template,
    size: value.size,
    orientation: originalPaperOrientation(value.background),
    widthMm: value.widthMm,
    heightMm: value.heightMm,
  };
  validateNoteBackgroundSettings(result);
  return cloneNoteBackgroundSettings(result);
}

async function readStructureRevision(store: relationalStore.RdbStore,
  noteId: string): Promise<number> {
  const rows = await store.querySql(
    'SELECT structure_revision FROM note_meta WHERE id = ?', [noteId]);
  try {
    if (!rows.goToFirstRow()) {
      throw new Error('local SET_METADATA note does not exist');
    }
    const revision: number = rows.getLong(rows.getColumnIndex('structure_revision'));
    if (!Number.isSafeInteger(revision) || revision < 0 || revision >= Number.MAX_SAFE_INTEGER) {
      throw new Error('local SET_METADATA structure revision is invalid or exhausted');
    }
    return revision;
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
      throw new Error('local SET_METADATA selected page is not live in the note');
    }
  } finally {
    rows.close();
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
