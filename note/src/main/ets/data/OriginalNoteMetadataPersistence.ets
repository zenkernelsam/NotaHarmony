import { relationalStore } from '@kit.ArkData';
import { OpType } from '../core/model/OpTypes';
import {
  OriginalNoteMetadataPatch, encodeOriginalSetMetadataFields,
  validateOriginalNoteMetadataPatch,
} from './OriginalSetMetadataPayloadEncoder';
import { encodeOriginalOperationEnvelope } from './OriginalOperationEnvelopeEncoder';
import {
  decodeOriginalSetMetadataTable, ORIGINAL_SET_METADATA_PAYLOAD_TYPE,
  OriginalSetMetadataPayload, OriginalNoteMetadataState, OriginalSetMetadataOperationApplier,
  readOriginalNoteMetadataState,
} from './OriginalSetMetadataOperation';
import { OriginalFlatBufferTableReader } from './OriginalSyncedOperationFlatBuffer';
import {
  allocateOperationIdentity, AllocatedOperationIdentity, appendOperation,
} from './OpStoreImpl';
import {
  StoredSyncedOperation, SyncedOperationApplyResult, SyncedOperationInboxState,
} from './SyncedOperationInbox';

export interface PersistedOriginalNoteMetadata {
  before: OriginalNoteMetadataState;
  after: OriginalNoteMetadataState;
  originalPayload: Uint8Array;
}

// The caller owns the database transaction and the shared metadata-writer mutex.
// This deliberately has no Harmony history companion yet: the original six
// preference registers are persisted and uploaded atomically, while their
// editor Undo/Redo consumer remains a separately audited scope.
export async function persistOriginalNoteMetadata(store: relationalStore.RdbStore,
  noteId: string, requested: OriginalNoteMetadataPatch): Promise<PersistedOriginalNoteMetadata> {
  if (noteId.length === 0) {
    throw new Error('local note metadata requires a note identity');
  }
  validateOriginalNoteMetadataPatch(requested);

  // Decode our own bytes before allocating an operation identity. Besides
  // validating the exact FlatBuffer shape, this gives Float32 fields the same
  // canonical value that the production reducer will read back.
  const payloadTable: Uint8Array = encodeOriginalSetMetadataFields(requested);
  const payload: OriginalSetMetadataPayload = decodeOriginalSetMetadataTable(
    OriginalFlatBufferTableReader.fromRoot(payloadTable));
  const before: OriginalNoteMetadataState = await readOriginalNoteMetadataState(store, noteId);
  if (!patchChangesState(before, payload)) {
    throw new Error('local SET_METADATA note metadata is unchanged');
  }
  const beforeRevision: number = await readStructureRevision(store, noteId);

  const identity: AllocatedOperationIdentity = await allocateOperationIdentity(store, noteId);
  const rawOperation: Uint8Array = encodeOriginalOperationEnvelope({
    identity: { timestamp: identity.timestamp, siteId: identity.siteId },
    clientTime: identity.clientTime.toString(), serverTime: null, audioTime: null,
    payloadType: ORIGINAL_SET_METADATA_PAYLOAD_TYPE,
  }, payloadTable);
  const operation: StoredSyncedOperation = storedOperation(noteId, identity, rawOperation);
  const applied: SyncedOperationApplyResult = await new OriginalSetMetadataOperationApplier().apply(
    store, operation);
  if (applied.deferredReason !== null) {
    throw new Error(`local metadata SET_METADATA was deferred: ${applied.deferredReason}`);
  }

  const after: OriginalNoteMetadataState = await readOriginalNoteMetadataState(store, noteId);
  assertMetadataMutation(before, after, payload);
  const afterRevision: number = await readStructureRevision(store, noteId);
  if (afterRevision !== beforeRevision + 1) {
    throw new Error('local metadata SET_METADATA did not advance structure revision exactly once');
  }
  await touchNoteUpdatedAt(store, noteId, identity.clientTime);
  await appendOperation(store, {
    noteId: noteId, opId: identity.opId, opType: OpType.ORIGINAL_SET_METADATA,
    payload: rawOperation, clientTime: identity.clientTime,
    opTimestamp: identity.timestamp, editorSiteId: identity.siteId, uploadImmediately: true,
  });
  return { before: before, after: after, originalPayload: rawOperation };
}

function patchChangesState(before: OriginalNoteMetadataState,
  payload: OriginalSetMetadataPayload): boolean {
  if (payload.hasHandwritingLanguage &&
    (!before.hasHandwritingLanguage || before.handwritingLanguage !== payload.handwritingLanguage)) {
    return true;
  }
  if (payload.hasAlignTextToLines && before.alignTextToLines !== payload.alignTextToLines) {
    return true;
  }
  if (payload.hasDefaultFontFamily && before.defaultFontFamily !== payload.defaultFontFamily) {
    return true;
  }
  if (payload.hasDefaultFontSize && before.defaultFontSize !== payload.defaultFontSize) {
    return true;
  }
  if (payload.hasLayoutMode && before.layoutMode !== payload.layoutMode) {
    return true;
  }
  if (payload.hasBlockWrapSupport && before.blockWrapSupport !== payload.blockWrapSupport) {
    return true;
  }
  return false;
}

function assertMetadataMutation(before: OriginalNoteMetadataState,
  after: OriginalNoteMetadataState,
  payload: OriginalSetMetadataPayload): void {
  if (payload.hasHandwritingLanguage &&
    (!after.hasHandwritingLanguage || after.handwritingLanguage !== payload.handwritingLanguage)) {
    throw new Error('local metadata reducer produced an unexpected handwriting language');
  }
  if (payload.hasAlignTextToLines && after.alignTextToLines !== payload.alignTextToLines) {
    throw new Error('local metadata reducer produced an unexpected align-to-lines value');
  }
  if (payload.hasDefaultFontFamily && after.defaultFontFamily !== payload.defaultFontFamily) {
    throw new Error('local metadata reducer produced an unexpected default font family');
  }
  if (payload.hasDefaultFontSize && after.defaultFontSize !== payload.defaultFontSize) {
    throw new Error('local metadata reducer produced an unexpected default font size');
  }
  if (payload.hasLayoutMode && after.layoutMode !== payload.layoutMode) {
    throw new Error('local metadata reducer produced an unexpected layout mode');
  }
  if (payload.hasBlockWrapSupport && after.blockWrapSupport !== payload.blockWrapSupport) {
    throw new Error('local metadata reducer produced an unexpected block-wrap value');
  }
  if (!payload.hasHandwritingLanguage &&
    (after.hasHandwritingLanguage !== before.hasHandwritingLanguage ||
      after.handwritingLanguage !== before.handwritingLanguage)) {
    throw new Error('local metadata changed an unrequested handwriting language');
  }
  if (!payload.hasAlignTextToLines && after.alignTextToLines !== before.alignTextToLines) {
    throw new Error('local metadata changed an unrequested align-to-lines value');
  }
  if (!payload.hasDefaultFontFamily && after.defaultFontFamily !== before.defaultFontFamily) {
    throw new Error('local metadata changed an unrequested default font family');
  }
  if (!payload.hasDefaultFontSize && after.defaultFontSize !== before.defaultFontSize) {
    throw new Error('local metadata changed an unrequested default font size');
  }
  if (!payload.hasLayoutMode && after.layoutMode !== before.layoutMode) {
    throw new Error('local metadata changed an unrequested layout mode');
  }
  if (!payload.hasBlockWrapSupport && after.blockWrapSupport !== before.blockWrapSupport) {
    throw new Error('local metadata changed an unrequested block-wrap value');
  }
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

async function touchNoteUpdatedAt(store: relationalStore.RdbStore, noteId: string,
  updatedAt: number): Promise<void> {
  const rows = await store.querySql('SELECT updated_at FROM note_meta WHERE id = ?', [noteId]);
  let current: number;
  try {
    if (!rows.goToFirstRow()) {
      throw new Error('local note metadata row does not exist');
    }
    current = rows.getLong(rows.getColumnIndex('updated_at'));
  } finally {
    rows.close();
  }
  if (!Number.isSafeInteger(current) || current < 0 ||
    !Number.isSafeInteger(updatedAt) || updatedAt < 0) {
    throw new Error('local note metadata time is invalid');
  }
  const predicates = new relationalStore.RdbPredicates('note_meta');
  predicates.equalTo('id', noteId);
  if (await store.update({ 'updated_at': Math.max(current, updatedAt) }, predicates) !== 1) {
    throw new Error('local note metadata could not update note metadata time');
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
