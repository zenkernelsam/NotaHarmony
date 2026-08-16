import { relationalStore } from '@kit.ArkData';
import { validateOriginalNoteTitleWireValue } from '../core/model/OriginalNoteTitlePolicy';
import { OpType } from '../core/model/OpTypes';
import { NoteBackgroundSettings, PageInfo } from '../core/model/NoteTypes';
import {
  originalPaperOrientation, sameNoteBackgroundSettings, validateNoteBackgroundSettings,
} from '../core/model/PageBackgroundModel';
import { SearchItemType } from './SearchItemType';
import { foldSearchText } from './SearchText';
import { encodeOriginalOperationEnvelope } from './OriginalOperationEnvelopeEncoder';
import {
  hasAlignedOriginalPageState, PersistedOriginalPageGroup, persistOriginalCreatePages,
} from './OriginalPagePersistence';
import {
  encodeOriginalSetMetadataTitleAndPageBackground,
} from './OriginalSetMetadataPayloadEncoder';
import {
  ORIGINAL_SET_METADATA_PAYLOAD_TYPE, OriginalNoteBackgroundState,
  OriginalSetMetadataOperationApplier, readOriginalNoteBackgroundState,
} from './OriginalSetMetadataOperation';
import { allocateOperationIdentity, AllocatedOperationIdentity, appendOperation } from './OpStoreImpl';
import {
  StoredSyncedOperation, SyncedOperationApplyResult, SyncedOperationInboxState,
} from './SyncedOperationInbox';

export const ORIGINAL_BLANK_NOTE_PAGE_COUNT: number = 2;

export interface PersistedOriginalBlankNoteBootstrap {
  pages: PageInfo[];
  metadataPayload: Uint8Array;
  createPagePayload: Uint8Array;
}

// Caller owns the outer SQLite transaction and the shared library writer. Original id7.d()
// builds one ordered list: combined SET_METADATA first, then CREATE_PAGE(pageCount=2).
export async function persistOriginalBlankNoteBootstrap(store: relationalStore.RdbStore,
  noteId: string, title: string,
  requestedBackground: NoteBackgroundSettings): Promise<PersistedOriginalBlankNoteBootstrap> {
  if (noteId.length === 0) {
    throw new Error('blank-note bootstrap requires a note identity');
  }
  validateOriginalNoteTitleWireValue(title);
  validateNoteBackgroundSettings(requestedBackground);
  if (requestedBackground.registerBackground === null ||
    (requestedBackground.background.pdf !== undefined &&
      requestedBackground.background.pdf !== null)) {
    throw new Error('blank-note bootstrap requires a concrete paper-only default template');
  }
  await requireFreshNote(store, noteId, title);
  if (!await hasAlignedOriginalPageState(store, noteId)) {
    throw new Error('blank-note bootstrap requires an empty aligned original page state');
  }

  const metadataIdentity: AllocatedOperationIdentity =
    await allocateOperationIdentity(store, noteId);
  const metadataTable: Uint8Array = encodeOriginalSetMetadataTitleAndPageBackground(
    title, requestedBackground.registerBackground);
  const metadataRaw: Uint8Array = encodeOriginalOperationEnvelope({
    identity: { timestamp: metadataIdentity.timestamp, siteId: metadataIdentity.siteId },
    clientTime: metadataIdentity.clientTime.toString(), serverTime: null, audioTime: null,
    payloadType: ORIGINAL_SET_METADATA_PAYLOAD_TYPE,
  }, metadataTable);
  const metadataOperation: StoredSyncedOperation = storedOperation(
    noteId, metadataIdentity, ORIGINAL_SET_METADATA_PAYLOAD_TYPE, metadataRaw);
  const metadataApplied: SyncedOperationApplyResult =
    await new OriginalSetMetadataOperationApplier().apply(store, metadataOperation);
  if (metadataApplied.deferredReason !== null) {
    throw new Error(`blank-note SET_METADATA was deferred: ${metadataApplied.deferredReason}`);
  }
  await requireMaterializedMetadata(
    store, noteId, title, requestedBackground, metadataIdentity, 1);
  await appendOperation(store, {
    noteId: noteId, opId: metadataIdentity.opId, opType: OpType.ORIGINAL_SET_METADATA,
    payload: metadataRaw, clientTime: metadataIdentity.clientTime,
    opTimestamp: metadataIdentity.timestamp, editorSiteId: metadataIdentity.siteId,
    uploadImmediately: true,
  });

  const created: PersistedOriginalPageGroup = await persistOriginalCreatePages(
    store, noteId, null, ORIGINAL_BLANK_NOTE_PAGE_COUNT);
  await requireCreatedPages(store, noteId, created.pages, requestedBackground);
  await requireBootstrapOperations(store, noteId, metadataIdentity);
  return {
    pages: created.pages,
    metadataPayload: metadataRaw,
    createPagePayload: created.payload,
  };
}

async function requireFreshNote(store: relationalStore.RdbStore,
  noteId: string, title: string): Promise<void> {
  const rows = await store.querySql(
    `SELECT note.title, note.structure_revision,
      (SELECT COUNT(*) FROM page_info WHERE note_id = note.id) AS page_count,
      (SELECT COUNT(*) FROM original_note_title_winner WHERE note_id = note.id) AS title_winners,
      (SELECT COUNT(*) FROM original_note_background_winner WHERE note_id = note.id) AS background_winners,
      (SELECT COUNT(*) FROM operation_log WHERE note_id = note.id) AS operation_count,
      (SELECT COUNT(*) FROM note_sync_metadata WHERE note_id = note.id) AS sync_count
     FROM note_meta note WHERE note.id = ?`, [noteId]);
  try {
    if (!rows.goToFirstRow() || rows.getString(rows.getColumnIndex('title')) !== title ||
      rows.getLong(rows.getColumnIndex('structure_revision')) !== 0 ||
      rows.getLong(rows.getColumnIndex('page_count')) !== 0 ||
      rows.getLong(rows.getColumnIndex('title_winners')) !== 0 ||
      rows.getLong(rows.getColumnIndex('background_winners')) !== 0 ||
      rows.getLong(rows.getColumnIndex('operation_count')) !== 0 ||
      rows.getLong(rows.getColumnIndex('sync_count')) !== 0) {
      throw new Error('blank-note bootstrap target is not a fresh inserted note');
    }
  } finally {
    rows.close();
  }
}

async function requireMaterializedMetadata(store: relationalStore.RdbStore, noteId: string,
  title: string, requested: NoteBackgroundSettings,
  identity: AllocatedOperationIdentity, expectedRevision: number): Promise<void> {
  const rows = await store.querySql(
    `SELECT note.title, note.structure_revision,
      title.winner_timestamp AS title_timestamp, title.winner_site_id AS title_site,
      title.title AS winner_title,
      background.winner_timestamp AS background_timestamp,
      background.winner_site_id AS background_site
     FROM note_meta note
     JOIN original_note_title_winner title ON title.note_id = note.id
     JOIN original_note_background_winner background ON background.note_id = note.id
     WHERE note.id = ?`, [noteId]);
  try {
    if (!rows.goToFirstRow() || rows.getString(rows.getColumnIndex('title')) !== title ||
      rows.getLong(rows.getColumnIndex('structure_revision')) !== expectedRevision ||
      rows.getLong(rows.getColumnIndex('title_timestamp')) !== identity.timestamp ||
      rows.getLong(rows.getColumnIndex('title_site')) !== identity.siteId ||
      rows.getString(rows.getColumnIndex('winner_title')) !== title ||
      rows.getLong(rows.getColumnIndex('background_timestamp')) !== identity.timestamp ||
      rows.getLong(rows.getColumnIndex('background_site')) !== identity.siteId) {
      throw new Error('blank-note combined metadata did not materialize both winners');
    }
  } finally {
    rows.close();
  }
  const state: OriginalNoteBackgroundState = await readOriginalNoteBackgroundState(store, noteId);
  if (state.registerValue === null) {
    throw new Error('blank-note combined metadata stored a null background register');
  }
  const materialized: NoteBackgroundSettings = {
    background: state.effective.background,
    registerBackground: state.registerValue.background,
    template: state.effective.template,
    size: state.effective.size,
    orientation: originalPaperOrientation(state.effective.background),
    widthMm: state.effective.widthMm,
    heightMm: state.effective.heightMm,
  };
  if (!sameNoteBackgroundSettings(materialized, requested)) {
    throw new Error('blank-note combined metadata produced an unexpected default template');
  }
  const search = await store.querySql(
    `SELECT folded_text FROM search_item
      WHERE note_id = ? AND type = ? AND sub_id = ? AND page_id IS NULL`,
    [noteId, SearchItemType.TITLE, noteId]);
  try {
    if (!search.goToFirstRow() ||
      search.getString(search.getColumnIndex('folded_text')) !== foldSearchText(title) ||
      search.goToNextRow()) {
      throw new Error('blank-note title search materialization is not exact');
    }
  } finally {
    search.close();
  }
}

async function requireCreatedPages(store: relationalStore.RdbStore, noteId: string,
  pages: PageInfo[], requested: NoteBackgroundSettings): Promise<void> {
  if (pages.length !== ORIGINAL_BLANK_NOTE_PAGE_COUNT) {
    throw new Error('blank-note CREATE_PAGE did not return two pages');
  }
  for (let index: number = 0; index < pages.length; index++) {
    const page: PageInfo = pages[index];
    if (page.pageIndex !== index || page.size !== requested.size ||
      page.template !== requested.template || page.orientation !== requested.orientation ||
      Math.abs(page.widthMm - requested.widthMm) > 0.001 ||
      Math.abs(page.heightMm - requested.heightMm) > 0.001 ||
      (page.background !== undefined && page.background !== null) ||
      page.originalPageInAsset !== index) {
      throw new Error('blank-note CREATE_PAGE materialized an unexpected inherited page');
    }
  }
  const revision = await store.querySql(
    'SELECT structure_revision FROM note_meta WHERE id = ?', [noteId]);
  try {
    if (!revision.goToFirstRow() ||
      revision.getLong(revision.getColumnIndex('structure_revision')) !== 2) {
      throw new Error('blank-note bootstrap did not advance structure revision twice');
    }
  } finally {
    revision.close();
  }
  if (!await hasAlignedOriginalPageState(store, noteId)) {
    throw new Error('blank-note CREATE_PAGE left original page identity state divergent');
  }
}

async function requireBootstrapOperations(store: relationalStore.RdbStore, noteId: string,
  metadataIdentity: AllocatedOperationIdentity): Promise<void> {
  const rows = await store.querySql(
    `SELECT op_type, op_timestamp, editor_site_id, upload_immediately,
      action_id, history_effect FROM operation_log WHERE note_id = ? ORDER BY sequence`, [noteId]);
  try {
    if (!rows.goToNextRow() ||
      rows.getLong(rows.getColumnIndex('op_type')) !== OpType.ORIGINAL_SET_METADATA ||
      rows.getLong(rows.getColumnIndex('op_timestamp')) !== metadataIdentity.timestamp ||
      rows.getLong(rows.getColumnIndex('editor_site_id')) !== metadataIdentity.siteId ||
      rows.getLong(rows.getColumnIndex('upload_immediately')) !== 1 ||
      !rows.isColumnNull(rows.getColumnIndex('action_id')) ||
      !rows.isColumnNull(rows.getColumnIndex('history_effect'))) {
      throw new Error('blank-note first operation is not upload-only SET_METADATA');
    }
    if (!rows.goToNextRow() ||
      rows.getLong(rows.getColumnIndex('op_type')) !== OpType.ORIGINAL_CREATE_PAGE ||
      rows.getLong(rows.getColumnIndex('op_timestamp')) !== metadataIdentity.timestamp + 1 ||
      rows.getLong(rows.getColumnIndex('editor_site_id')) !== metadataIdentity.siteId ||
      rows.getLong(rows.getColumnIndex('upload_immediately')) !== 1 ||
      !rows.isColumnNull(rows.getColumnIndex('action_id')) ||
      !rows.isColumnNull(rows.getColumnIndex('history_effect')) || rows.goToNextRow()) {
      throw new Error('blank-note second operation is not upload-only CREATE_PAGE');
    }
  } finally {
    rows.close();
  }
}

function storedOperation(noteId: string, identity: AllocatedOperationIdentity,
  payloadType: number, rawOperation: Uint8Array): StoredSyncedOperation {
  return {
    noteId: noteId, timestamp: identity.timestamp, siteId: identity.siteId,
    clientTime: identity.clientTime.toString(), serverTime: '0', audioTime: null,
    schemaVersion: 1, payloadType: payloadType, rawOperation: rawOperation,
    state: SyncedOperationInboxState.APPLIED, deferredReason: null,
    receivedAt: identity.clientTime,
  };
}
