import { relationalStore } from '@kit.ArkData';
import { HistoryEffect, HistoryMetadata, NoteMetadataHistoryState, OpType } from '../core/model/OpTypes';
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
  NOTE_METADATA_FIELD_ALIGN_TEXT_TO_LINES, NOTE_METADATA_FIELD_BLOCK_WRAP_SUPPORT,
  NOTE_METADATA_FIELD_DEFAULT_FONT_FAMILY, NOTE_METADATA_FIELD_DEFAULT_FONT_SIZE,
  NOTE_METADATA_FIELD_HANDWRITING_LANGUAGE, NOTE_METADATA_FIELD_LAYOUT_MODE,
  NoteMetadataMutation, NoteMetadataMutationState, encodeNoteMetadataMutation,
  sameNoteMetadataMutationState, validateNoteMetadataMutationState,
} from './NoteMetadataMutationCodec';
import {
  allocateOperationIdentity, AllocatedOperationIdentity, appendOperation,
} from './OpStoreImpl';
import { validateHistoryMetadata } from './PersistentHistoryMetadata';
import {
  StoredSyncedOperation, SyncedOperationApplyResult, SyncedOperationInboxState,
} from './SyncedOperationInbox';

export interface PersistedOriginalNoteMetadata {
  before: OriginalNoteMetadataState;
  after: OriginalNoteMetadataState;
  originalPayload: Uint8Array;
  historyMutation: NoteMetadataMutation | null;
}

// The caller owns the database transaction and the shared metadata-writer mutex.
export async function persistOriginalNoteMetadata(store: relationalStore.RdbStore,
  noteId: string, requested: OriginalNoteMetadataPatch, selectedPageId?: string,
  history?: HistoryMetadata, expectedSource?: NoteMetadataMutationState):
  Promise<PersistedOriginalNoteMetadata> {
  if (noteId.length === 0) {
    throw new Error('local note metadata requires a note identity');
  }
  validateOriginalNoteMetadataPatch(requested);
  if (history !== undefined) {
    validateHistoryMetadata(history);
    if (selectedPageId === undefined || selectedPageId.length === 0) {
      throw new Error('local note metadata history requires a selected page identity');
    }
    await requireLiveSelectedPage(store, noteId, selectedPageId);
    if (history.effect !== HistoryEffect.PUSH && expectedSource === undefined) {
      throw new Error('local note metadata undo/redo requires an expected source state');
    }
  } else if (selectedPageId !== undefined || expectedSource !== undefined) {
    throw new Error('local note metadata history arguments require history metadata');
  }

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
  const fieldMask: number = fieldMaskFromPayload(payload);
  let beforeHistoryState: NoteMetadataMutationState | null = null;
  if (history !== undefined) {
    beforeHistoryState = historyStateFromOriginalState(before, fieldMask, 'before');
    if (expectedSource !== undefined) {
      validateNoteMetadataMutationState(expectedSource, fieldMask, 'expected source');
      if (!sameNoteMetadataMutationState(beforeHistoryState, expectedSource, fieldMask)) {
        throw new Error('local note metadata history source state changed concurrently');
      }
    }
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
  let historyMutation: NoteMetadataMutation | null = null;
  if (history !== undefined && selectedPageId !== undefined && beforeHistoryState !== null) {
    const afterHistoryState: NoteMetadataMutationState = historyStateFromOriginalState(
      after, fieldMask, 'after');
    historyMutation = {
      fromRevision: beforeRevision,
      toRevision: afterRevision,
      selectedPageId: selectedPageId,
      fieldMask: fieldMask,
      before: beforeHistoryState,
      after: afterHistoryState,
    };
    const companion: AllocatedOperationIdentity = await allocateOperationIdentity(store, noteId);
    await appendOperation(store, {
      noteId: noteId, opId: companion.opId, opType: OpType.UPDATE_NOTE_METADATA,
      payload: encodeNoteMetadataMutation(historyMutation),
      clientTime: companion.clientTime, opTimestamp: companion.timestamp,
      editorSiteId: companion.siteId, history: history,
    });
  }
  return {
    before: before, after: after, originalPayload: rawOperation,
    historyMutation: historyMutation,
  };
}

function fieldMaskFromPayload(payload: OriginalSetMetadataPayload): number {
  let mask: number = 0;
  if (payload.hasHandwritingLanguage) {
    mask |= NOTE_METADATA_FIELD_HANDWRITING_LANGUAGE;
  }
  if (payload.hasAlignTextToLines) {
    mask |= NOTE_METADATA_FIELD_ALIGN_TEXT_TO_LINES;
  }
  if (payload.hasDefaultFontFamily) {
    mask |= NOTE_METADATA_FIELD_DEFAULT_FONT_FAMILY;
  }
  if (payload.hasDefaultFontSize) {
    mask |= NOTE_METADATA_FIELD_DEFAULT_FONT_SIZE;
  }
  if (payload.hasLayoutMode) {
    mask |= NOTE_METADATA_FIELD_LAYOUT_MODE;
  }
  if (payload.hasBlockWrapSupport) {
    mask |= NOTE_METADATA_FIELD_BLOCK_WRAP_SUPPORT;
  }
  return mask;
}

function historyStateFromOriginalState(state: OriginalNoteMetadataState, fieldMask: number,
  label: string): NoteMetadataMutationState {
  if ((fieldMask & NOTE_METADATA_FIELD_HANDWRITING_LANGUAGE) !== 0 &&
    !state.hasHandwritingLanguage) {
    throw new Error(`local note metadata ${label} handwriting winner is absent`);
  }
  if ((fieldMask & NOTE_METADATA_FIELD_ALIGN_TEXT_TO_LINES) !== 0 &&
    state.alignTextToLines === null) {
    throw new Error(`local note metadata ${label} align winner is absent`);
  }
  if ((fieldMask & NOTE_METADATA_FIELD_DEFAULT_FONT_FAMILY) !== 0 &&
    state.defaultFontFamily === null) {
    throw new Error(`local note metadata ${label} font-family winner is absent`);
  }
  if ((fieldMask & NOTE_METADATA_FIELD_DEFAULT_FONT_SIZE) !== 0 &&
    state.defaultFontSize === null) {
    throw new Error(`local note metadata ${label} font-size winner is absent`);
  }
  if ((fieldMask & NOTE_METADATA_FIELD_LAYOUT_MODE) !== 0 &&
    state.layoutMode === null) {
    throw new Error(`local note metadata ${label} layout winner is absent`);
  }
  if ((fieldMask & NOTE_METADATA_FIELD_BLOCK_WRAP_SUPPORT) !== 0 &&
    state.blockWrapSupport === null) {
    throw new Error(`local note metadata ${label} block-wrap winner is absent`);
  }
  const result: NoteMetadataHistoryState = {
    handwritingLanguage: (fieldMask & NOTE_METADATA_FIELD_HANDWRITING_LANGUAGE) !== 0
      ? state.handwritingLanguage : null,
    alignTextToLines: (fieldMask & NOTE_METADATA_FIELD_ALIGN_TEXT_TO_LINES) !== 0
      ? state.alignTextToLines : null,
    defaultFontFamily: (fieldMask & NOTE_METADATA_FIELD_DEFAULT_FONT_FAMILY) !== 0
      ? state.defaultFontFamily : null,
    defaultFontSize: (fieldMask & NOTE_METADATA_FIELD_DEFAULT_FONT_SIZE) !== 0
      ? state.defaultFontSize : null,
    layoutMode: (fieldMask & NOTE_METADATA_FIELD_LAYOUT_MODE) !== 0
      ? state.layoutMode : null,
    blockWrapSupport: (fieldMask & NOTE_METADATA_FIELD_BLOCK_WRAP_SUPPORT) !== 0
      ? state.blockWrapSupport : null,
  };
  validateNoteMetadataMutationState(result, fieldMask, label);
  return result;
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

async function requireLiveSelectedPage(store: relationalStore.RdbStore, noteId: string,
  pageId: string): Promise<void> {
  const rows = await store.querySql(
    'SELECT 1 FROM page_info WHERE note_id = ? AND page_id = ? LIMIT 1', [noteId, pageId]);
  try {
    if (!rows.goToFirstRow()) {
      throw new Error('local note metadata selected page is not live in the note');
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
