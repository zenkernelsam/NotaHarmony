import { relationalStore } from '@kit.ArkData';
import { OpType } from '../core/model/OpTypes';
import {
  decodeOriginalCreatePageTable, MAX_ORIGINAL_CREATE_PAGE_COUNT, OriginalCreatePagePayload,
} from './OriginalCreatePageOperation';
import {
  decodeOriginalDeleteEntitiesTable, OriginalDeleteEntitiesOperationApplier,
  OriginalDeleteEntitiesPayload,
} from './OriginalDeleteEntitiesOperation';
import {
  decodeOriginalModifyPageTable, OriginalModifyPagePayload,
} from './OriginalModifyPageOperation';
import {
  compareOperationIdentity, compareOriginalSequenceIdentity, encodeOriginalPageStorageId,
  encodeOriginalSequenceId,
  OperationIdentity, OriginalSequenceIdentity, validateOperationIdentity,
  validateOriginalSequenceIdentity,
} from './OperationIdentity';
import { OriginalFlatBufferTableReader } from './OriginalSyncedOperationFlatBuffer';
import { validateUnsignedLongDecimal } from './UnsignedDecimal';
import { serializePageBackground } from '../core/model/PageBackgroundModel';
import {
  OriginalDecodedPageBackground, originalPageBackgroundFitsHarmony,
} from './OriginalPageBackgroundOperation';
import {
  decodeOriginalCreateInkTable, ORIGINAL_CREATE_INK_PAYLOAD_TYPE,
  OriginalCreateInkOperationApplier,
} from './OriginalCreateInkOperation';
import {
  ORIGINAL_ADD_PATH_ELEMENTS_PAYLOAD_TYPE, OriginalAddPathElementsOperationApplier,
} from './OriginalAddPathElementsOperation';
import {
  decodeOriginalModifyInkTable, ORIGINAL_MODIFY_INK_PAYLOAD_TYPE,
  OriginalModifyInkOperationApplier,
} from './OriginalModifyInkOperation';
import {
  decodeOriginalCreateBlockTable, ORIGINAL_CREATE_BLOCK_PAYLOAD_TYPE,
  OriginalCreateBlockOperationApplier,
} from './OriginalCreateBlockOperation';
import {
  decodeOriginalModifyBlockTable, ORIGINAL_MODIFY_BLOCK_PAYLOAD_TYPE,
  OriginalModifyBlockOperationApplier,
} from './OriginalModifyBlockOperation';
import {
  decodeOriginalModifyPositionsTable, ORIGINAL_MODIFY_POSITIONS_PAYLOAD_TYPE,
  OriginalModifyPositionsOperationApplier,
} from './OriginalModifyPositionsOperation';
import {
  ORIGINAL_INSERT_CHAR_PAYLOAD_TYPE, ORIGINAL_INSERT_STRING_PAYLOAD_TYPE,
  ORIGINAL_REMOVE_CHAR_PAYLOAD_TYPE, ORIGINAL_REMOVE_CHARS_PAYLOAD_TYPE,
  ORIGINAL_REVIVE_CHARS_PAYLOAD_TYPE, OriginalInsertTextOperationApplier,
  OriginalTextVisibilityOperationApplier,
} from './OriginalInsertTextOperation';
import {
  ORIGINAL_CLEAR_STYLE_PAYLOAD_TYPE, ORIGINAL_MODIFY_PARAGRAPH_STYLE_PAYLOAD_TYPE,
  ORIGINAL_MODIFY_STYLE_PAYLOAD_TYPE, OriginalRichTextStyleOperationApplier,
} from './OriginalRichTextStyleOperation';
import {
  ORIGINAL_UPDATE_CHECKBOX_PAYLOAD_TYPE, OriginalUpdateCheckboxOperationApplier,
} from './OriginalUpdateCheckboxOperation';
import {
  ORIGINAL_MODIFY_PDF_FIELD_PAYLOAD_TYPE, OriginalModifyPdfFieldOperationApplier,
} from './OriginalModifyPdfFieldOperation';
import {
  ORIGINAL_SET_METADATA_PAYLOAD_TYPE, OriginalSetMetadataOperationApplier,
  readEffectiveNoteBackground,
} from './OriginalSetMetadataOperation';
import {
  StoredSyncedOperation, SyncedOperationInboxState, SyncedOperationApplyResult,
} from './SyncedOperationInbox';
import {
  mergeOriginalAssetReference, OriginalAssetReferenceConflict,
} from './OriginalAssetReferenceStore';

export const ORIGINAL_NOTE_BUNDLE_MAX_OPERATION_COUNT: number = 262144;
const ORIGINAL_CREATE_PAGE_PAYLOAD_TYPE: number = 3;
const ORIGINAL_MODIFY_PAGE_PAYLOAD_TYPE: number = 4;
const ORIGINAL_DELETE_ENTITIES_PAYLOAD_TYPE: number = 25;
const ORIGINAL_PAYLOAD_TYPE_MAX: number = 31;

export interface OriginalNoteBundleOperation extends OriginalSequenceIdentity {
  clientTime: string;
  serverTime: string | null;
  payloadType: number;
  transient: boolean;
  payload: OriginalFlatBufferTableReader;
}

export interface OriginalNoteBundle {
  noteId: string;
  editorSiteId: number;
  schemaVersion: number;
  operations: OriginalNoteBundleOperation[];
}

export interface OriginalPageIdentityBootstrapResult {
  applied: boolean;
  deferredReason: string | null;
}

interface BootstrapCreateGroup {
  operation: OriginalNoteBundleOperation;
  location: OriginalSequenceIdentity | null;
  pageCount: number;
  modifiedTime: string;
  pages: OriginalSequenceIdentity[];
}

interface BootstrapPosition {
  position: OriginalSequenceIdentity;
  page: OriginalSequenceIdentity;
}

interface BootstrapPositionGroup {
  operation: OriginalNoteBundleOperation;
  location: OriginalSequenceIdentity | null;
  modifiedTime: string;
  positions: BootstrapPosition[];
}

interface BootstrapPositionWinner extends OperationIdentity {
  positionIndex: number;
}

interface BootstrapVisibilityWinner extends OperationIdentity {
  deleted: boolean;
}

interface BootstrapPageState {
  identity: OriginalSequenceIdentity;
  visibility: BootstrapVisibilityWinner | null;
  background: OriginalDecodedPageBackground | null;
  backgroundWinner: OperationIdentity | null;
  pageInAsset: number;
  pageInAssetWinner: OperationIdentity;
}

interface BootstrapHistory {
  createGroups: BootstrapCreateGroup[];
  positionGroups: BootstrapPositionGroup[];
  pages: Map<string, BootstrapPageState>;
  positionWinners: Map<string, BootstrapPositionWinner>;
  visibleOrder: OriginalSequenceIdentity[];
}

interface BootstrapReplayResult {
  history: BootstrapHistory | null;
  deferredReason: string | null;
}

export function decodeOriginalNoteBundle(bytes: Uint8Array): OriginalNoteBundle {
  const root: OriginalFlatBufferTableReader = OriginalFlatBufferTableReader.fromRoot(bytes);
  const noteIdBytes: Uint8Array | null = root.readInlineBytes(0, 16);
  if (noteIdBytes === null) {
    throw new Error('original note bundle has no required note ID');
  }
  root.validateByteVector(3, true, bytes.length);
  root.validateByteVector(5, true, bytes.length);
  if (!root.hasField(6)) {
    throw new Error('original note bundle has no required operations vector');
  }
  const operationTables: OriginalFlatBufferTableReader[] =
    root.readTableVector(6, ORIGINAL_NOTE_BUNDLE_MAX_OPERATION_COUNT);
  const operations: OriginalNoteBundleOperation[] = [];
  const identities: Set<string> = new Set<string>();
  for (const table of operationTables) {
    const id: Uint8Array | null = table.readInlineBytes(0, 8);
    if (id === null) {
      throw new Error('original note bundle operation has no required ID');
    }
    const payloadType: number = table.readUint8(4, 0);
    if (payloadType < 1 || payloadType > ORIGINAL_PAYLOAD_TYPE_MAX) {
      throw new Error('original note bundle operation has an unknown payload type');
    }
    const payload: OriginalFlatBufferTableReader | null = table.readTable(5);
    if (payload === null) {
      throw new Error('original note bundle operation has no payload table');
    }
    const operation: OriginalNoteBundleOperation = {
      timestamp: readU32(id, 4),
      siteId: readU16(id, 0),
      index: 0,
      clientTime: requireDecimal(table.readUint64Decimal(1, '0')),
      serverTime: table.readUint64Decimal(2, null),
      payloadType: payloadType,
      transient: table.readUint8(3, 0) !== 0,
      payload: payload,
    };
    validateOperationIdentity(operation);
    if (operation.serverTime !== null) {
      validateUnsignedLongDecimal(operation.serverTime);
    }
    const key: string = operationKey(operation);
    if (identities.has(key)) {
      throw new Error('original note bundle repeats an operation identity');
    }
    identities.add(key);
    operations.push(operation);
  }
  return {
    noteId: decodeOriginalUuid(noteIdBytes),
    editorSiteId: root.readUint16(2, 0),
    schemaVersion: root.readUint16(7, 0),
    operations: operations,
  };
}

export class OriginalNoteBundlePageIdentityBootstrapper {
  async apply(store: relationalStore.RdbStore, expectedNoteId: string,
    expectedSchemaVersion: number, bytes: Uint8Array): Promise<OriginalPageIdentityBootstrapResult> {
    let bundle: OriginalNoteBundle;
    try {
      bundle = decodeOriginalNoteBundle(bytes);
    } catch (_error) {
      return deferred('MALFORMED_NOTE_BUNDLE');
    }
    if (!originalNoteIdsMatch(expectedNoteId, bundle.noteId)) {
      return deferred('NOTE_BUNDLE_NOTE_ID_MISMATCH');
    }
    if (bundle.schemaVersion !== expectedSchemaVersion) {
      return deferred('NOTE_BUNDLE_SCHEMA_VERSION_MISMATCH');
    }

    let replay: BootstrapReplayResult;
    try {
      replay = replayBootstrapHistory(bundle.operations);
    } catch (_error) {
      return deferred('MALFORMED_NOTE_BUNDLE_PAGE_SEQUENCE');
    }
    if (replay.deferredReason !== null) {
      return deferred(replay.deferredReason);
    }
    const history: BootstrapHistory = requireHistory(replay);
    const contentPreflightReason: string | null = preflightBundleContent(bundle, history);
    if (contentPreflightReason !== null) {
      return deferred(contentPreflightReason);
    }
    const pdfAssetReason: string | null = await mergeBootstrapPdfAssets(
      store, expectedNoteId, history.pages);
    if (pdfAssetReason !== null) {
      return deferred(pdfAssetReason);
    }
    const pageIds: string[] = await readPageIds(store, expectedNoteId);
    if (pageIds.length !== history.visibleOrder.length) {
      return deferred('NOTE_BUNDLE_PAGE_COUNT_MISMATCH');
    }
    const divergentLocalMutationCount: number = await countRows(store,
      `SELECT COUNT(*) AS value FROM operation_log WHERE note_id = ?
       AND op_type IN (?, ?, ?)`, [expectedNoteId, OpType.DELETE_PAGE,
        OpType.UPDATE_PAGE, OpType.REORDER_PAGES]);
    if (divergentLocalMutationCount !== 0) {
      return deferred('LOCAL_PAGE_STRUCTURE_DIVERGED');
    }
    const pageIdBySequence: Map<string, string> = bindVisiblePages(history.visibleOrder, pageIds);
    bindArchivedContentPages(history, bundle, expectedNoteId, pageIdBySequence);
    let applied: boolean = false;
    if (!await existingMappingMatches(store, expectedNoteId, history, pageIdBySequence)) {
      if (await hasExistingMapping(store, expectedNoteId)) {
        return deferred('ORIGINAL_PAGE_IDENTITY_CONFLICT');
      }
      if (history.createGroups.length > 0) {
        await insertBootstrapHistory(store, expectedNoteId, history, pageIdBySequence);
        applied = true;
      }
    }
    const contentResult: OriginalPageIdentityBootstrapResult =
      await applyBundleContent(store, bundle);
    if (contentResult.deferredReason !== null) {
      return contentResult;
    }
    const backgroundChanged: boolean = await applyBootstrapBackgrounds(
      store, expectedNoteId, history, pageIdBySequence);
    return { applied: applied || contentResult.applied || backgroundChanged, deferredReason: null };
  }
}

async function mergeBootstrapPdfAssets(store: relationalStore.RdbStore, noteId: string,
  pages: Map<string, BootstrapPageState>): Promise<string | null> {
  const merged: Set<string> = new Set<string>();
  const states: BootstrapPageState[] = [];
  pages.forEach((state: BootstrapPageState): void => states.push(state));
  for (const state of states) {
    if (state.background === null || state.background.background.pdf === undefined ||
      state.background.background.pdf === null) {
      continue;
    }
    const key: string = JSON.stringify(state.background.background.pdf.metadata.assetHashBits);
    if (merged.has(key)) {
      continue;
    }
    merged.add(key);
    const conflict: OriginalAssetReferenceConflict = await mergeOriginalAssetReference(
      store, noteId, state.background.background.pdf.metadata);
    if (conflict === OriginalAssetReferenceConflict.METADATA) {
      return 'NOTE_BUNDLE_PDF_ASSET_METADATA_CONFLICT';
    }
    if (conflict === OriginalAssetReferenceConflict.LOCAL_PATH) {
      return 'NOTE_BUNDLE_PDF_ASSET_PATH_CONFLICT';
    }
  }
  return null;
}

function preflightBundleContent(bundle: OriginalNoteBundle,
  history: BootstrapHistory): string | null {
  const createInk: OriginalCreateInkOperationApplier = new OriginalCreateInkOperationApplier();
  const addPath: OriginalAddPathElementsOperationApplier =
    new OriginalAddPathElementsOperationApplier();
  const modifyInk: OriginalModifyInkOperationApplier = new OriginalModifyInkOperationApplier();
  const deleteEntities: OriginalDeleteEntitiesOperationApplier =
    new OriginalDeleteEntitiesOperationApplier();
  const createBlock: OriginalCreateBlockOperationApplier =
    new OriginalCreateBlockOperationApplier();
  const modifyBlock: OriginalModifyBlockOperationApplier =
    new OriginalModifyBlockOperationApplier();
  const insertText: OriginalInsertTextOperationApplier =
    new OriginalInsertTextOperationApplier();
  const textVisibility: OriginalTextVisibilityOperationApplier =
    new OriginalTextVisibilityOperationApplier();
  const textStyle: OriginalRichTextStyleOperationApplier =
    new OriginalRichTextStyleOperationApplier();
  const updateCheckbox: OriginalUpdateCheckboxOperationApplier =
    new OriginalUpdateCheckboxOperationApplier();
  const modifyPdfField: OriginalModifyPdfFieldOperationApplier =
    new OriginalModifyPdfFieldOperationApplier();
  const setMetadata: OriginalSetMetadataOperationApplier = new OriginalSetMetadataOperationApplier();
  const modifyPositions: OriginalModifyPositionsOperationApplier =
    new OriginalModifyPositionsOperationApplier();
  for (const operation of bundle.operations) {
    if (operation.transient) {
      return 'NOTE_BUNDLE_TRANSIENT_OPERATION_UNSUPPORTED';
    }
    if (operation.payloadType === ORIGINAL_SET_METADATA_PAYLOAD_TYPE) {
      const reason: string | null = setMetadata.preflightTable(operation.payload);
      if (reason !== null) {
        return `NOTE_BUNDLE_${reason}`;
      }
      continue;
    }
    if (operation.payloadType === ORIGINAL_CREATE_PAGE_PAYLOAD_TYPE ||
      operation.payloadType === ORIGINAL_MODIFY_PAGE_PAYLOAD_TYPE) {
      continue;
    }
    if (operation.payloadType === ORIGINAL_DELETE_ENTITIES_PAYLOAD_TYPE) {
      const reason: string | null = deleteEntities.preflightTable(operation.payload);
      if (reason !== null) {
        return `NOTE_BUNDLE_${reason}`;
      }
      continue;
    }
    if (operation.payloadType === ORIGINAL_ADD_PATH_ELEMENTS_PAYLOAD_TYPE) {
      const reason: string | null = addPath.preflightTable(operation.payload);
      if (reason !== null) {
        return `NOTE_BUNDLE_${reason}`;
      }
      continue;
    }
    if (operation.payloadType === ORIGINAL_MODIFY_INK_PAYLOAD_TYPE) {
      const reason: string | null = modifyInk.preflightTable(operation.payload);
      if (reason !== null) {
        return `NOTE_BUNDLE_${reason}`;
      }
      const pageOrigin = decodeOriginalModifyInkTable(operation.payload).pageOrigin;
      if (pageOrigin !== null && !history.pages.has(encodeOriginalSequenceId(pageOrigin.page))) {
        return 'NOTE_BUNDLE_MODIFY_INK_DESTINATION_PAGE_MISSING';
      }
      continue;
    }
    if (operation.payloadType === ORIGINAL_CREATE_BLOCK_PAYLOAD_TYPE) {
      const reason: string | null = createBlock.preflightTable(
        operation.payload, operation.clientTime);
      if (reason !== null) {
        return `NOTE_BUNDLE_${reason}`;
      }
      let pageKey: string;
      try {
        const rawPage: number[] | null = operation.payload.readInlineSequence(2);
        if (rawPage === null) {
          return 'NOTE_BUNDLE_MALFORMED_CREATE_BLOCK_PAYLOAD';
        }
        pageKey = encodeOriginalSequenceId({
          timestamp: rawPage[0], siteId: rawPage[1], index: rawPage[2],
        });
      } catch (_error) {
        return 'NOTE_BUNDLE_MALFORMED_CREATE_BLOCK_PAYLOAD';
      }
      if (!history.pages.has(pageKey)) {
        return 'NOTE_BUNDLE_CREATE_BLOCK_PAGE_MISSING';
      }
      continue;
    }
    if (operation.payloadType === ORIGINAL_MODIFY_BLOCK_PAYLOAD_TYPE) {
      const reason: string | null = modifyBlock.preflightTable(operation.payload);
      if (reason !== null) {
        return `NOTE_BUNDLE_${reason}`;
      }
      const pageOrigin = decodeOriginalModifyBlockTable(operation.payload).pageOrigin;
      if (pageOrigin !== null && !history.pages.has(encodeOriginalSequenceId(pageOrigin.page))) {
        return 'NOTE_BUNDLE_MODIFY_BLOCK_DESTINATION_PAGE_MISSING';
      }
      continue;
    }
    if (operation.payloadType === ORIGINAL_MODIFY_POSITIONS_PAYLOAD_TYPE) {
      const reason: string | null = modifyPositions.preflightTable(operation.payload);
      if (reason !== null) {
        return `NOTE_BUNDLE_${reason}`;
      }
      const positions = decodeOriginalModifyPositionsTable(operation.payload);
      for (const modification of positions.modifications) {
        if (modification.pageOrigin !== null &&
          !history.pages.has(encodeOriginalSequenceId(modification.pageOrigin.page))) {
          return 'NOTE_BUNDLE_MODIFY_POSITIONS_DESTINATION_PAGE_MISSING';
        }
      }
      continue;
    }
    if (operation.payloadType === ORIGINAL_INSERT_CHAR_PAYLOAD_TYPE ||
      operation.payloadType === ORIGINAL_INSERT_STRING_PAYLOAD_TYPE) {
      const reason: string | null = insertText.preflightTable(
        operation.payload, operation.payloadType);
      if (reason !== null) {
        return `NOTE_BUNDLE_${reason}`;
      }
      continue;
    }
    if (operation.payloadType === ORIGINAL_REMOVE_CHAR_PAYLOAD_TYPE ||
      operation.payloadType === ORIGINAL_REMOVE_CHARS_PAYLOAD_TYPE ||
      operation.payloadType === ORIGINAL_REVIVE_CHARS_PAYLOAD_TYPE) {
      const reason: string | null = textVisibility.preflightTable(
        operation.payload, operation.payloadType);
      if (reason !== null) {
        return `NOTE_BUNDLE_${reason}`;
      }
      continue;
    }
    if (operation.payloadType === ORIGINAL_MODIFY_STYLE_PAYLOAD_TYPE ||
      operation.payloadType === ORIGINAL_MODIFY_PARAGRAPH_STYLE_PAYLOAD_TYPE ||
      operation.payloadType === ORIGINAL_CLEAR_STYLE_PAYLOAD_TYPE) {
      const reason: string | null = textStyle.preflightTable(
        operation.payload, operation.payloadType);
      if (reason !== null) {
        return `NOTE_BUNDLE_${reason}`;
      }
      continue;
    }
    if (operation.payloadType === ORIGINAL_UPDATE_CHECKBOX_PAYLOAD_TYPE) {
      const reason: string | null = updateCheckbox.preflightTable(operation.payload);
      if (reason !== null) {
        return `NOTE_BUNDLE_${reason}`;
      }
      continue;
    }
    if (operation.payloadType === ORIGINAL_MODIFY_PDF_FIELD_PAYLOAD_TYPE) {
      const reason: string | null = modifyPdfField.preflightTable(operation.payload);
      if (reason !== null) {
        return `NOTE_BUNDLE_${reason}`;
      }
      continue;
    }
    if (operation.payloadType !== ORIGINAL_CREATE_INK_PAYLOAD_TYPE) {
      return `NOTE_BUNDLE_PAYLOAD_${operation.payloadType}_UNSUPPORTED`;
    }
    const reason: string | null = createInk.preflightTable(operation.payload, operation.clientTime);
    if (reason !== null) {
      return `NOTE_BUNDLE_${reason}`;
    }
    let pageKey: string;
    try {
      const rawPage: number[] | null = operation.payload.readInlineSequence(0);
      if (rawPage === null) {
        return 'NOTE_BUNDLE_MALFORMED_CREATE_INK_PAYLOAD';
      }
      pageKey = encodeOriginalSequenceId({
        timestamp: rawPage[0], siteId: rawPage[1], index: rawPage[2],
      });
    } catch (_error) {
      return 'NOTE_BUNDLE_MALFORMED_CREATE_INK_PAYLOAD';
    }
    const page: BootstrapPageState | undefined = history.pages.get(pageKey);
    if (page === undefined) {
      return 'NOTE_BUNDLE_CREATE_INK_PAGE_MISSING';
    }
  }
  return null;
}

async function applyBundleContent(store: relationalStore.RdbStore,
  bundle: OriginalNoteBundle): Promise<OriginalPageIdentityBootstrapResult> {
  const createInk: OriginalCreateInkOperationApplier = new OriginalCreateInkOperationApplier();
  const addPath: OriginalAddPathElementsOperationApplier =
    new OriginalAddPathElementsOperationApplier();
  const modifyInk: OriginalModifyInkOperationApplier = new OriginalModifyInkOperationApplier();
  const deleteEntities: OriginalDeleteEntitiesOperationApplier =
    new OriginalDeleteEntitiesOperationApplier();
  const createBlock: OriginalCreateBlockOperationApplier =
    new OriginalCreateBlockOperationApplier();
  const modifyBlock: OriginalModifyBlockOperationApplier =
    new OriginalModifyBlockOperationApplier();
  const insertText: OriginalInsertTextOperationApplier =
    new OriginalInsertTextOperationApplier();
  const textVisibility: OriginalTextVisibilityOperationApplier =
    new OriginalTextVisibilityOperationApplier();
  const textStyle: OriginalRichTextStyleOperationApplier =
    new OriginalRichTextStyleOperationApplier();
  const updateCheckbox: OriginalUpdateCheckboxOperationApplier =
    new OriginalUpdateCheckboxOperationApplier();
  const modifyPdfField: OriginalModifyPdfFieldOperationApplier =
    new OriginalModifyPdfFieldOperationApplier();
  const setMetadata: OriginalSetMetadataOperationApplier = new OriginalSetMetadataOperationApplier();
  const modifyPositions: OriginalModifyPositionsOperationApplier =
    new OriginalModifyPositionsOperationApplier();
  const before: number = await countRows(store,
    'SELECT COUNT(*) AS value FROM original_element_z_index WHERE note_id = ?', [bundle.noteId]);
  const revisionBefore: number = await contentRevisionTotal(store, bundle.noteId);
  const structureRevisionBefore: number = await countRows(store,
    'SELECT structure_revision AS value FROM note_meta WHERE id = ?', [bundle.noteId]);
  const pdfFieldStateBefore: string = await originalPdfFieldStateSignature(store, bundle.noteId);
  for (const operation of bundle.operations) {
    if (operation.payloadType !== ORIGINAL_SET_METADATA_PAYLOAD_TYPE &&
      operation.payloadType !== ORIGINAL_CREATE_INK_PAYLOAD_TYPE &&
      operation.payloadType !== ORIGINAL_ADD_PATH_ELEMENTS_PAYLOAD_TYPE &&
      operation.payloadType !== ORIGINAL_MODIFY_INK_PAYLOAD_TYPE &&
      operation.payloadType !== ORIGINAL_DELETE_ENTITIES_PAYLOAD_TYPE &&
      operation.payloadType !== ORIGINAL_CREATE_BLOCK_PAYLOAD_TYPE &&
      operation.payloadType !== ORIGINAL_MODIFY_BLOCK_PAYLOAD_TYPE &&
      operation.payloadType !== ORIGINAL_MODIFY_POSITIONS_PAYLOAD_TYPE &&
      operation.payloadType !== ORIGINAL_INSERT_CHAR_PAYLOAD_TYPE &&
      operation.payloadType !== ORIGINAL_INSERT_STRING_PAYLOAD_TYPE &&
      operation.payloadType !== ORIGINAL_REMOVE_CHAR_PAYLOAD_TYPE &&
      operation.payloadType !== ORIGINAL_REMOVE_CHARS_PAYLOAD_TYPE &&
      operation.payloadType !== ORIGINAL_REVIVE_CHARS_PAYLOAD_TYPE &&
      operation.payloadType !== ORIGINAL_MODIFY_STYLE_PAYLOAD_TYPE &&
      operation.payloadType !== ORIGINAL_MODIFY_PARAGRAPH_STYLE_PAYLOAD_TYPE &&
      operation.payloadType !== ORIGINAL_CLEAR_STYLE_PAYLOAD_TYPE &&
      operation.payloadType !== ORIGINAL_UPDATE_CHECKBOX_PAYLOAD_TYPE &&
      operation.payloadType !== ORIGINAL_MODIFY_PDF_FIELD_PAYLOAD_TYPE) {
      continue;
    }
    const stored: StoredSyncedOperation = {
      noteId: bundle.noteId,
      timestamp: operation.timestamp,
      siteId: operation.siteId,
      clientTime: operation.clientTime,
      serverTime: operation.serverTime === null ? operation.clientTime : operation.serverTime,
      schemaVersion: bundle.schemaVersion,
      payloadType: operation.payloadType,
      rawOperation: new Uint8Array(0),
      state: SyncedOperationInboxState.RECEIVED,
      deferredReason: null,
      receivedAt: 0,
    };
    let result: SyncedOperationApplyResult;
    if (operation.payloadType === ORIGINAL_SET_METADATA_PAYLOAD_TYPE) {
      result = await setMetadata.applyTable(store, stored, operation.payload);
    } else if (operation.payloadType === ORIGINAL_CREATE_INK_PAYLOAD_TYPE) {
      result = await createInk.applyTable(store, stored, operation.payload);
    } else if (operation.payloadType === ORIGINAL_ADD_PATH_ELEMENTS_PAYLOAD_TYPE) {
      result = await addPath.applyTable(store, stored, operation.payload);
    } else if (operation.payloadType === ORIGINAL_MODIFY_INK_PAYLOAD_TYPE) {
      result = await modifyInk.applyTable(store, stored, operation.payload);
    } else if (operation.payloadType === ORIGINAL_DELETE_ENTITIES_PAYLOAD_TYPE) {
      result = await deleteEntities.applyEntityTable(store, stored, operation.payload);
    } else if (operation.payloadType === ORIGINAL_CREATE_BLOCK_PAYLOAD_TYPE) {
      result = await createBlock.applyTable(store, stored, operation.payload);
    } else if (operation.payloadType === ORIGINAL_MODIFY_BLOCK_PAYLOAD_TYPE) {
      result = await modifyBlock.applyTable(store, stored, operation.payload);
    } else if (operation.payloadType === ORIGINAL_MODIFY_POSITIONS_PAYLOAD_TYPE) {
      result = await modifyPositions.applyTable(store, stored, operation.payload);
    } else if (operation.payloadType === ORIGINAL_INSERT_CHAR_PAYLOAD_TYPE ||
      operation.payloadType === ORIGINAL_INSERT_STRING_PAYLOAD_TYPE) {
      result = await insertText.applyTable(store, stored, operation.payload);
    } else if (operation.payloadType === ORIGINAL_REMOVE_CHAR_PAYLOAD_TYPE ||
      operation.payloadType === ORIGINAL_REMOVE_CHARS_PAYLOAD_TYPE ||
      operation.payloadType === ORIGINAL_REVIVE_CHARS_PAYLOAD_TYPE) {
      result = await textVisibility.applyTable(store, stored, operation.payload);
    } else if (operation.payloadType === ORIGINAL_UPDATE_CHECKBOX_PAYLOAD_TYPE) {
      result = await updateCheckbox.applyTable(store, stored, operation.payload);
    } else if (operation.payloadType === ORIGINAL_MODIFY_PDF_FIELD_PAYLOAD_TYPE) {
      result = await modifyPdfField.applyTable(store, stored, operation.payload);
    } else {
      result = await textStyle.applyTable(store, stored, operation.payload);
    }
    if (result.deferredReason !== null) {
      throw new Error(`NOTE_BUNDLE content diverged after preflight: ${result.deferredReason}`);
    }
  }
  const after: number = await countRows(store,
    'SELECT COUNT(*) AS value FROM original_element_z_index WHERE note_id = ?', [bundle.noteId]);
  const revisionAfter: number = await contentRevisionTotal(store, bundle.noteId);
  const structureRevisionAfter: number = await countRows(store,
    'SELECT structure_revision AS value FROM note_meta WHERE id = ?', [bundle.noteId]);
  return { applied: after > before || revisionAfter > revisionBefore ||
    structureRevisionAfter > structureRevisionBefore ||
    await originalPdfFieldStateSignature(store, bundle.noteId) !== pdfFieldStateBefore,
    deferredReason: null };
}

async function originalPdfFieldStateSignature(store: relationalStore.RdbStore,
  noteId: string): Promise<string> {
  const rows = await store.querySql(
    `SELECT asset_hash, field_key, value_type, string_value, boolean_value,
            winner_timestamp, winner_site_id
     FROM original_pdf_field_state WHERE note_id = ? ORDER BY asset_hash, field_key`, [noteId]);
  let signature: string = '';
  try {
    while (rows.goToNextRow()) {
      const assetHash: string = rows.getString(rows.getColumnIndex('asset_hash'));
      const fieldKey: string = rows.getString(rows.getColumnIndex('field_key'));
      const valueType: number = rows.getLong(rows.getColumnIndex('value_type'));
      const value: string = valueType === 0 ?
        rows.getString(rows.getColumnIndex('string_value')) :
        rows.getLong(rows.getColumnIndex('boolean_value')).toString();
      signature += `${assetHash.length}:${assetHash}${fieldKey.length}:${fieldKey}` +
        `${valueType}:${value.length}:${value}:` +
        `${rows.getLong(rows.getColumnIndex('winner_timestamp'))}:` +
        `${rows.getLong(rows.getColumnIndex('winner_site_id'))};`;
    }
  } finally {
    rows.close();
  }
  return signature;
}

async function contentRevisionTotal(store: relationalStore.RdbStore,
  noteId: string): Promise<number> {
  const live: number = await countRows(store,
    'SELECT COALESCE(SUM(content_revision), 0) AS value FROM page_info WHERE note_id = ?', [noteId]);
  const archived: number = await countRows(store,
    `SELECT COALESCE(SUM(content_revision), 0) AS value FROM original_deleted_page
     WHERE note_id = ?`, [noteId]);
  const total: number = live + archived;
  if (!Number.isSafeInteger(total) || total < 0) {
    throw new Error('note bundle content revision total is invalid');
  }
  return total;
}

function replayBootstrapHistory(operations: OriginalNoteBundleOperation[]): BootstrapReplayResult {
  const createGroups: BootstrapCreateGroup[] = [];
  const positionGroups: BootstrapPositionGroup[] = [];
  const pages: Map<string, BootstrapPageState> = new Map<string, BootstrapPageState>();
  const positions: Set<string> = new Set<string>();
  const positionWinners: Map<string, BootstrapPositionWinner> =
    new Map<string, BootstrapPositionWinner>();
  let totalPageCount: number = 0;

  for (const operation of operations) {
    if (operation.payloadType !== ORIGINAL_CREATE_PAGE_PAYLOAD_TYPE) {
      continue;
    }
    const payload: OriginalCreatePagePayload = decodeOriginalCreatePageTable(operation.payload);
    if (payload.pageCount < 1 || payload.pageCount > MAX_ORIGINAL_CREATE_PAGE_COUNT) {
      return replayDeferred('NOTE_BUNDLE_CREATE_PAGE_COUNT_UNSUPPORTED');
    }
    if (payload.background !== null && !originalPageBackgroundFitsHarmony(payload.background)) {
      return replayDeferred('NOTE_BUNDLE_CREATE_PAGE_BACKGROUND_SIZE_UNSUPPORTED');
    }
    if (payload.background !== null && payload.background.background.pdf !== undefined &&
      payload.background.background.pdf !== null &&
      payload.background.background.pdf.pagesConsumed !== payload.pageCount) {
      return replayDeferred('NOTE_BUNDLE_CREATE_PAGE_PDF_PAGE_COUNT_MISMATCH');
    }
    totalPageCount += payload.pageCount;
    if (!Number.isSafeInteger(totalPageCount) || totalPageCount > ORIGINAL_NOTE_BUNDLE_MAX_OPERATION_COUNT) {
      return replayDeferred('NOTE_BUNDLE_PAGE_IDENTITY_BUDGET_EXCEEDED');
    }
    const groupPages: OriginalSequenceIdentity[] = [];
    const groupPositions: BootstrapPosition[] = [];
    for (let index: number = 0; index < payload.pageCount; index++) {
      const identity: OriginalSequenceIdentity = {
        timestamp: operation.timestamp, siteId: operation.siteId, index: index,
      };
      const key: string = encodeOriginalSequenceId(identity);
      if (pages.has(key) || positions.has(key)) {
        throw new Error('note bundle repeats a page identity');
      }
      const initialPageInAsset: number = payload.background === null ||
        payload.background.background.pdf === undefined || payload.background.background.pdf === null
        ? index : payload.background.background.pdf.pageOffset + index;
      pages.set(key, {
        identity: identity, visibility: null, background: payload.background,
        backgroundWinner: { timestamp: operation.timestamp, siteId: operation.siteId },
        pageInAsset: initialPageInAsset,
        pageInAssetWinner: { timestamp: operation.timestamp, siteId: operation.siteId },
      });
      positions.add(key);
      positionWinners.set(key, {
        timestamp: operation.timestamp, siteId: operation.siteId, positionIndex: index,
      });
      groupPages.push(identity);
      groupPositions.push({ position: identity, page: identity });
    }
    const modifiedTime: string = effectiveTime(operation);
    createGroups.push({
      operation: operation, location: payload.location, pageCount: payload.pageCount,
      modifiedTime: modifiedTime, pages: groupPages,
    });
    positionGroups.push({
      operation: operation, location: payload.location,
      modifiedTime: modifiedTime, positions: groupPositions,
    });
  }

  const pendingMoves: OriginalNoteBundleOperation[] = [];
  for (const operation of operations) {
    if (operation.payloadType !== ORIGINAL_MODIFY_PAGE_PAYLOAD_TYPE) {
      continue;
    }
    const payload: OriginalModifyPagePayload = decodeOriginalModifyPageTable(operation.payload);
    if (payload.pages.length < 1) {
      return replayDeferred('NOTE_BUNDLE_MODIFY_PAGE_HAS_NO_PAGES');
    }
    if (payload.background !== null && !originalPageBackgroundFitsHarmony(payload.background)) {
      return replayDeferred('NOTE_BUNDLE_MODIFY_PAGE_BACKGROUND_SIZE_UNSUPPORTED');
    }
    if (payload.background !== null && payload.background.background.pdf !== undefined &&
      payload.background.background.pdf !== null &&
      payload.background.background.pdf.pagesConsumed !== payload.pages.length) {
      return replayDeferred('NOTE_BUNDLE_MODIFY_PAGE_PDF_PAGE_COUNT_MISMATCH');
    }
    if (payload.hasBookmarked) {
      return replayDeferred('NOTE_BUNDLE_MODIFY_PAGE_BOOKMARK_UNSUPPORTED');
    }
    if (hasRepeatedPages(payload.pages)) {
      return replayDeferred('NOTE_BUNDLE_MODIFY_PAGE_REPEATS_PAGE');
    }
    for (const page of payload.pages) {
      if (!pages.has(encodeOriginalSequenceId(page))) {
        return replayDeferred('NOTE_BUNDLE_MODIFY_PAGE_PAGE_MISSING');
      }
    }
    if (payload.hasBackground) {
      for (let pageIndex: number = 0; pageIndex < payload.pages.length; pageIndex++) {
        const page: OriginalSequenceIdentity = payload.pages[pageIndex];
        const state: BootstrapPageState | undefined = pages.get(encodeOriginalSequenceId(page));
        if (state === undefined) {
          throw new Error('validated note bundle background page disappeared');
        }
        if (state.backgroundWinner === null ||
          compareOperationIdentity(operation, state.backgroundWinner) > 0) {
          state.background = payload.background;
          state.backgroundWinner = { timestamp: operation.timestamp, siteId: operation.siteId };
        }
        if (payload.background !== null && payload.background.background.pdf !== undefined &&
          payload.background.background.pdf !== null &&
          compareOperationIdentity(operation, state.pageInAssetWinner) > 0) {
          state.pageInAsset = payload.background.background.pdf.pageOffset + pageIndex;
          state.pageInAssetWinner = { timestamp: operation.timestamp, siteId: operation.siteId };
        }
      }
    }
    if (payload.hasMove) {
      pendingMoves.push(operation);
    }
  }
  while (pendingMoves.length > 0) {
    let progressed: boolean = false;
    for (let index: number = 0; index < pendingMoves.length;) {
      const operation: OriginalNoteBundleOperation = pendingMoves[index];
      const payload: OriginalModifyPagePayload = decodeOriginalModifyPageTable(operation.payload);
      if (payload.moveTo !== null && !positions.has(encodeOriginalSequenceId(payload.moveTo))) {
        index++;
        continue;
      }
      const groupPositions: BootstrapPosition[] = [];
      for (let positionIndex: number = 0; positionIndex < payload.pages.length; positionIndex++) {
        const position: OriginalSequenceIdentity = {
          timestamp: operation.timestamp, siteId: operation.siteId, index: positionIndex,
        };
        const positionKey: string = encodeOriginalSequenceId(position);
        if (positions.has(positionKey)) {
          throw new Error('note bundle repeats a page position identity');
        }
        positions.add(positionKey);
        const page: OriginalSequenceIdentity = payload.pages[positionIndex];
        groupPositions.push({ position: position, page: page });
        const pageKey: string = encodeOriginalSequenceId(page);
        const winner: BootstrapPositionWinner | undefined = positionWinners.get(pageKey);
        if (winner === undefined || compareOperationIdentity(operation, winner) >= 0) {
          positionWinners.set(pageKey, {
            timestamp: operation.timestamp, siteId: operation.siteId,
            positionIndex: positionIndex,
          });
        }
      }
      positionGroups.push({
        operation: operation, location: payload.moveTo,
        modifiedTime: effectiveTime(operation), positions: groupPositions,
      });
      pendingMoves.splice(index, 1);
      progressed = true;
    }
    if (!progressed) {
      return replayDeferred('NOTE_BUNDLE_MODIFY_PAGE_TARGET_MISSING');
    }
  }

  for (const operation of operations) {
    if (operation.payloadType !== ORIGINAL_DELETE_ENTITIES_PAYLOAD_TYPE) {
      continue;
    }
    const payload: OriginalDeleteEntitiesPayload =
      decodeOriginalDeleteEntitiesTable(operation.payload);
    for (const page of payload.pageDeletes) {
      if (!applyBootstrapVisibility(pages, operation, page, true)) {
        return replayDeferred('NOTE_BUNDLE_PAGE_VISIBILITY_PAGE_MISSING');
      }
    }
    // The original applies deletes before undeletes inside one operation.
    for (const page of payload.pageUndeletes) {
      if (!applyBootstrapVisibility(pages, operation, page, false)) {
        return replayDeferred('NOTE_BUNDLE_PAGE_VISIBILITY_PAGE_MISSING');
      }
    }
  }

  const history: BootstrapHistory = {
    createGroups: createGroups,
    positionGroups: positionGroups,
    pages: pages,
    positionWinners: positionWinners,
    visibleOrder: [],
  };
  history.visibleOrder = materializeBootstrapOrder(history, positions);
  return { history: history, deferredReason: null };
}

function materializeBootstrapOrder(history: BootstrapHistory,
  knownPositions: Set<string>): OriginalSequenceIdentity[] {
  const children: Map<string, BootstrapPositionGroup[]> =
    new Map<string, BootstrapPositionGroup[]>();
  for (const group of history.positionGroups) {
    if (group.positions.length < 1 || group.positions.length > MAX_ORIGINAL_CREATE_PAGE_COUNT) {
      throw new Error('note bundle has an invalid position group');
    }
    if (group.location !== null && !knownPositions.has(encodeOriginalSequenceId(group.location))) {
      throw new Error('note bundle page position location is missing');
    }
    const parentKey: string = group.location === null ? 'ROOT' : encodeOriginalSequenceId(group.location);
    const siblings: BootstrapPositionGroup[] | undefined = children.get(parentKey);
    if (siblings === undefined) {
      children.set(parentKey, [group]);
    } else {
      siblings.push(group);
    }
  }
  children.forEach((siblings: BootstrapPositionGroup[]): void => {
    siblings.sort((left: BootstrapPositionGroup, right: BootstrapPositionGroup): number =>
      -compareOriginalSequenceIdentity(left.positions[left.positions.length - 1].position,
        right.positions[right.positions.length - 1].position));
  });
  const result: OriginalSequenceIdentity[] = [];
  const visible: Set<string> = new Set<string>();
  const visited: Set<string> = new Set<string>();
  appendBootstrapChildren('ROOT', children, history, visited, visible, result);
  if (visited.size !== history.positionGroups.length) {
    throw new Error('note bundle page positions contain an orphan or cycle');
  }
  let expectedVisibleCount: number = 0;
  history.pages.forEach((page: BootstrapPageState): void => {
    if (page.visibility === null || !page.visibility.deleted) {
      expectedVisibleCount++;
    }
  });
  if (result.length !== expectedVisibleCount || visible.size !== result.length) {
    throw new Error('note bundle page positions do not materialize every visible identity once');
  }
  return result;
}

function appendBootstrapChildren(parentKey: string,
  children: Map<string, BootstrapPositionGroup[]>, history: BootstrapHistory,
  visited: Set<string>, visible: Set<string>, result: OriginalSequenceIdentity[]): void {
  const groups: BootstrapPositionGroup[] | undefined = children.get(parentKey);
  if (groups === undefined) {
    return;
  }
  for (const group of groups) {
    const groupKey: string = operationKey(group.operation);
    if (visited.has(groupKey)) {
      throw new Error('note bundle page positions contain a cycle');
    }
    visited.add(groupKey);
    for (const entry of group.positions) {
      const pageKey: string = encodeOriginalSequenceId(entry.page);
      const winner: BootstrapPositionWinner | undefined = history.positionWinners.get(pageKey);
      const page: BootstrapPageState | undefined = history.pages.get(pageKey);
      if (winner === undefined || page === undefined) {
        throw new Error('note bundle position references an unknown page');
      }
      const active: boolean = winner.timestamp === entry.position.timestamp &&
        winner.siteId === entry.position.siteId && winner.positionIndex === entry.position.index;
      const deleted: boolean = page.visibility !== null && page.visibility.deleted;
      if (active && !deleted) {
        if (visible.has(pageKey)) {
          throw new Error('note bundle materialized one page more than once');
        }
        visible.add(pageKey);
        result.push(page.identity);
      }
      // Inactive and deleted positions remain anchors, matching the original sequence tree.
      appendBootstrapChildren(encodeOriginalSequenceId(entry.position), children,
        history, visited, visible, result);
    }
  }
}

function applyBootstrapVisibility(pages: Map<string, BootstrapPageState>,
  operation: OriginalNoteBundleOperation, identity: OriginalSequenceIdentity,
  deleted: boolean): boolean {
  const page: BootstrapPageState | undefined = pages.get(encodeOriginalSequenceId(identity));
  if (page === undefined) {
    return false;
  }
  if (page.visibility === null || compareOperationIdentity(operation, page.visibility) >= 0) {
    page.visibility = {
      timestamp: operation.timestamp, siteId: operation.siteId, deleted: deleted,
    };
  }
  return true;
}

function hasRepeatedPages(pages: OriginalSequenceIdentity[]): boolean {
  const seen: Set<string> = new Set<string>();
  for (const page of pages) {
    const key: string = encodeOriginalSequenceId(page);
    if (seen.has(key)) {
      return true;
    }
    seen.add(key);
  }
  return false;
}

function bindVisiblePages(order: OriginalSequenceIdentity[],
  pageIds: string[]): Map<string, string> {
  const result: Map<string, string> = new Map<string, string>();
  for (let index: number = 0; index < order.length; index++) {
    result.set(encodeOriginalSequenceId(order[index]), pageIds[index]);
  }
  return result;
}

function bindArchivedContentPages(history: BootstrapHistory, bundle: OriginalNoteBundle,
  noteId: string, pageIdBySequence: Map<string, string>): void {
  const contentPages: Set<string> = new Set<string>();
  for (const operation of bundle.operations) {
    if (operation.payloadType === ORIGINAL_MODIFY_POSITIONS_PAYLOAD_TYPE) {
      const positions = decodeOriginalModifyPositionsTable(operation.payload);
      for (const modification of positions.modifications) {
        if (modification.pageOrigin !== null) {
          contentPages.add(encodeOriginalSequenceId(modification.pageOrigin.page));
        }
      }
      continue;
    }
    let page: OriginalSequenceIdentity | null = null;
    if (operation.payloadType === ORIGINAL_CREATE_INK_PAYLOAD_TYPE) {
      page = decodeOriginalCreateInkTable(operation.payload, operation.clientTime).page;
    } else if (operation.payloadType === ORIGINAL_CREATE_BLOCK_PAYLOAD_TYPE) {
      page = decodeOriginalCreateBlockTable(operation.payload, operation.clientTime).page;
    } else if (operation.payloadType === ORIGINAL_MODIFY_INK_PAYLOAD_TYPE) {
      const pageOrigin = decodeOriginalModifyInkTable(operation.payload).pageOrigin;
      page = pageOrigin === null ? null : pageOrigin.page;
    } else if (operation.payloadType === ORIGINAL_MODIFY_BLOCK_PAYLOAD_TYPE) {
      const pageOrigin = decodeOriginalModifyBlockTable(operation.payload).pageOrigin;
      page = pageOrigin === null ? null : pageOrigin.page;
    }
    if (page !== null) {
      contentPages.add(encodeOriginalSequenceId(page));
    }
  }
  contentPages.forEach((key: string): void => {
    const page: BootstrapPageState | undefined = history.pages.get(key);
    if (page === undefined) {
      throw new Error('validated note bundle content page disappeared');
    }
    if (page.visibility !== null && page.visibility.deleted && !pageIdBySequence.has(key)) {
      pageIdBySequence.set(key, encodeOriginalPageStorageId(noteId, page.identity));
    }
  });
}

async function insertBootstrapHistory(store: relationalStore.RdbStore, noteId: string,
  history: BootstrapHistory, pageIdBySequence: Map<string, string>): Promise<void> {
  for (const group of history.createGroups) {
    const values: relationalStore.ValuesBucket = groupValues(noteId, group.operation,
      group.location, 'page_count', group.pageCount, group.modifiedTime);
    await store.insert('original_page_insert_group', values);
  }
  const pageStates: BootstrapPageState[] = [];
  history.pages.forEach((page: BootstrapPageState): void => {
    pageStates.push(page);
  });
  for (const page of pageStates) {
    const pageId: string | undefined = pageIdBySequence.get(encodeOriginalSequenceId(page.identity));
    const values: relationalStore.ValuesBucket = {
      'note_id': noteId,
      'seq_timestamp': page.identity.timestamp,
      'seq_site_id': page.identity.siteId,
      'seq_index': page.identity.index,
      'page_id': pageId === undefined ? null : pageId,
      'visible': pageId === undefined ? 0 : 1,
    };
    await store.insert('original_page_identity', values);
  }
  for (const group of history.positionGroups) {
    const values: relationalStore.ValuesBucket = groupValues(noteId, group.operation,
      group.location, 'position_count', group.positions.length, group.modifiedTime);
    await store.insert('original_page_position_group', values);
  }
  for (const group of history.positionGroups) {
    for (const entry of group.positions) {
      await store.insert('original_page_position', {
        'note_id': noteId,
        'pos_timestamp': entry.position.timestamp,
        'pos_site_id': entry.position.siteId,
        'pos_index': entry.position.index,
        'page_timestamp': entry.page.timestamp,
        'page_site_id': entry.page.siteId,
        'page_index': entry.page.index,
      });
    }
  }
  for (const page of pageStates) {
    const winner: BootstrapPositionWinner | undefined =
      history.positionWinners.get(encodeOriginalSequenceId(page.identity));
    if (winner === undefined) {
      throw new Error('note bundle page has no position winner');
    }
    await store.insert('original_page_position_winner', {
      'note_id': noteId,
      'page_timestamp': page.identity.timestamp,
      'page_site_id': page.identity.siteId,
      'page_index': page.identity.index,
      'winner_timestamp': winner.timestamp,
      'winner_site_id': winner.siteId,
      'position_index': winner.positionIndex,
    });
    if (page.visibility !== null) {
      await store.insert('original_page_visibility_winner', {
        'note_id': noteId,
        'page_timestamp': page.identity.timestamp,
        'page_site_id': page.identity.siteId,
        'page_index': page.identity.index,
        'winner_timestamp': page.visibility.timestamp,
        'winner_site_id': page.visibility.siteId,
        'deleted': page.visibility.deleted ? 1 : 0,
      });
    }
    if (page.backgroundWinner !== null) {
      const background: OriginalDecodedPageBackground | null = page.background;
      await store.insert('original_page_background_winner', {
        'note_id': noteId,
        'page_timestamp': page.identity.timestamp,
        'page_site_id': page.identity.siteId,
        'page_index': page.identity.index,
        'winner_timestamp': page.backgroundWinner.timestamp,
        'winner_site_id': page.backgroundWinner.siteId,
        'size': background === null ? null : background.size,
        'template': background === null ? null : background.template,
        'orientation': background === null ? null : background.orientation,
        'width_mm': background === null ? null : background.widthMm,
        'height_mm': background === null ? null : background.heightMm,
        'background_json': background === null ? null : serializePageBackground(background.background),
      });
    }
    await store.insert('original_page_in_asset_winner', {
      'note_id': noteId,
      'page_timestamp': page.identity.timestamp,
      'page_site_id': page.identity.siteId,
      'page_index': page.identity.index,
      'winner_timestamp': page.pageInAssetWinner.timestamp,
      'winner_site_id': page.pageInAssetWinner.siteId,
      'page_in_asset': page.pageInAsset,
    });
  }
  let fallback: OriginalDecodedPageBackground | null = null;
  for (const page of pageStates) {
    const key: string = encodeOriginalSequenceId(page.identity);
    const pageId: string | undefined = pageIdBySequence.get(key);
    const archived: boolean = page.visibility !== null && page.visibility.deleted;
    if (pageId === undefined || !archived) {
      continue;
    }
    if (page.background === null && fallback === null) {
      fallback = await readEffectiveNoteBackground(store, noteId);
    }
    const materialized: OriginalDecodedPageBackground = page.background === null
      ? fallback as OriginalDecodedPageBackground : page.background;
    await store.insert('original_deleted_page', {
      'note_id': noteId,
      'page_timestamp': page.identity.timestamp,
      'page_site_id': page.identity.siteId,
      'page_index': page.identity.index,
      'page_id': pageId,
      'size': materialized.size,
      'template': materialized.template,
      'orientation': materialized.orientation,
      'width_mm': materialized.widthMm,
      'height_mm': materialized.heightMm,
      'background_json': page.background === null ? null :
        serializePageBackground(page.background.background),
      'original_page_in_asset': page.pageInAsset,
      'content_revision': 0,
      'indexed_revision': null,
    });
  }
}

async function applyBootstrapBackgrounds(store: relationalStore.RdbStore, noteId: string,
  history: BootstrapHistory, pageIdBySequence: Map<string, string>): Promise<boolean> {
  let changed: boolean = false;
  const states: BootstrapPageState[] = [];
  history.pages.forEach((page: BootstrapPageState): void => {
    states.push(page);
  });
  for (const state of states) {
    const pageId: string | undefined = pageIdBySequence.get(encodeOriginalSequenceId(state.identity));
    if (pageId === undefined || (state.background === null && state.backgroundWinner === null)) {
      continue;
    }
    const materialized: OriginalDecodedPageBackground = state.background === null
      ? await readEffectiveNoteBackground(store, noteId) : state.background;
    const backgroundJson: string | null = state.background === null ? null :
      serializePageBackground(state.background.background);
    const archived: boolean = state.visibility !== null && state.visibility.deleted;
    if (await storedPageBackgroundMatches(
      store, noteId, pageId, state.identity, archived,
      materialized, backgroundJson, state.pageInAsset)) {
      continue;
    }
    const table: string = archived ? 'original_deleted_page' : 'page_info';
    const predicates = new relationalStore.RdbPredicates(table);
    predicates.equalTo('note_id', noteId);
    if (archived) {
      predicates.equalTo('page_timestamp', state.identity.timestamp);
      predicates.equalTo('page_site_id', state.identity.siteId);
      predicates.equalTo('page_index', state.identity.index);
      predicates.equalTo('page_id', pageId);
    } else {
      predicates.equalTo('page_id', pageId);
    }
    const updated: number = await store.update({
      'size': materialized.size,
      'template': materialized.template,
      'orientation': materialized.orientation,
      'width_mm': materialized.widthMm,
      'height_mm': materialized.heightMm,
      'background_json': backgroundJson,
      'original_page_in_asset': state.pageInAsset,
    }, predicates);
    if (updated !== 1) {
      throw new Error(`note bundle background update affected ${updated} rows`);
    }
    changed = true;
  }
  return changed;
}

async function storedPageBackgroundMatches(store: relationalStore.RdbStore, noteId: string,
  pageId: string, identity: OriginalSequenceIdentity, archived: boolean,
  expected: OriginalDecodedPageBackground,
  backgroundJson: string | null, pageInAsset: number): Promise<boolean> {
  const rows = archived ? await store.querySql(
    `SELECT size, template, orientation, width_mm, height_mm, background_json,
      original_page_in_asset FROM original_deleted_page
     WHERE note_id = ? AND page_timestamp = ? AND page_site_id = ? AND page_index = ?
       AND page_id = ?`, [noteId, identity.timestamp, identity.siteId, identity.index, pageId]) :
    await store.querySql(
      `SELECT size, template, orientation, width_mm, height_mm, background_json,
        original_page_in_asset FROM page_info WHERE note_id = ? AND page_id = ?`,
      [noteId, pageId]);
  try {
    if (!rows.goToFirstRow()) {
      throw new Error('note bundle background page is missing');
    }
    const backgroundColumn: number = rows.getColumnIndex('background_json');
    const storedBackground: string | null = rows.isColumnNull(backgroundColumn)
      ? null : rows.getString(backgroundColumn);
    return rows.getLong(rows.getColumnIndex('size')) === expected.size &&
      rows.getLong(rows.getColumnIndex('template')) === expected.template &&
      rows.getLong(rows.getColumnIndex('orientation')) === expected.orientation &&
      rows.getDouble(rows.getColumnIndex('width_mm')) === expected.widthMm &&
      rows.getDouble(rows.getColumnIndex('height_mm')) === expected.heightMm &&
      storedBackground === backgroundJson &&
      !rows.isColumnNull(rows.getColumnIndex('original_page_in_asset')) &&
      rows.getLong(rows.getColumnIndex('original_page_in_asset')) === pageInAsset;
  } finally {
    rows.close();
  }
}

function groupValues(noteId: string, operation: OriginalNoteBundleOperation,
  location: OriginalSequenceIdentity | null, countColumn: string,
  count: number, modifiedTime: string): relationalStore.ValuesBucket {
  const values: relationalStore.ValuesBucket = {
    'note_id': noteId,
    'op_timestamp': operation.timestamp,
    'op_site_id': operation.siteId,
    'modified_time': modifiedTime,
  };
  values[countColumn] = count;
  if (location !== null) {
    values['parent_timestamp'] = location.timestamp;
    values['parent_site_id'] = location.siteId;
    values['parent_index'] = location.index;
  }
  return values;
}

async function existingMappingMatches(store: relationalStore.RdbStore, noteId: string,
  history: BootstrapHistory, pageIdBySequence: Map<string, string>): Promise<boolean> {
  if (!await exactCount(store, 'original_page_insert_group', noteId, history.createGroups.length) ||
    !await exactCount(store, 'original_page_identity', noteId, history.pages.size) ||
    !await exactCount(store, 'original_page_position_group', noteId, history.positionGroups.length) ||
    !await exactCount(store, 'original_page_position', noteId, countPositions(history.positionGroups)) ||
    !await exactCount(store, 'original_page_position_winner', noteId, history.pages.size) ||
    !await exactCount(store, 'original_page_visibility_winner', noteId,
      countVisibilityWinners(history.pages)) ||
    !await exactCount(store, 'original_page_background_winner', noteId,
      countBackgroundWinners(history.pages)) ||
    !await exactCount(store, 'original_page_in_asset_winner', noteId, history.pages.size) ||
    !await exactCount(store, 'original_deleted_page', noteId,
      countBoundArchivedPages(history, pageIdBySequence))) {
    return false;
  }
  for (const group of history.createGroups) {
    if (!await groupMatches(store, 'original_page_insert_group', 'page_count', noteId,
      group.operation, group.location, group.pageCount, group.modifiedTime)) {
      return false;
    }
  }
  for (const group of history.positionGroups) {
    if (!await groupMatches(store, 'original_page_position_group', 'position_count', noteId,
      group.operation, group.location, group.positions.length, group.modifiedTime)) {
      return false;
    }
    for (const entry of group.positions) {
      if (!await rowExists(store,
        `SELECT 1 FROM original_page_position WHERE note_id = ?
         AND pos_timestamp = ? AND pos_site_id = ? AND pos_index = ?
         AND page_timestamp = ? AND page_site_id = ? AND page_index = ? LIMIT 1`,
        [noteId, entry.position.timestamp, entry.position.siteId, entry.position.index,
          entry.page.timestamp, entry.page.siteId, entry.page.index])) {
        return false;
      }
    }
  }
  const pageStates: BootstrapPageState[] = [];
  history.pages.forEach((page: BootstrapPageState): void => {
    pageStates.push(page);
  });
  for (const page of pageStates) {
    const key: string = encodeOriginalSequenceId(page.identity);
    const pageId: string | undefined = pageIdBySequence.get(key);
    if (!await identityMatches(store, noteId, page.identity, pageId)) {
      return false;
    }
    if (pageId !== undefined && page.visibility !== null && page.visibility.deleted &&
      !await rowExists(store,
        `SELECT 1 FROM original_deleted_page WHERE note_id = ?
         AND page_timestamp = ? AND page_site_id = ? AND page_index = ?
         AND page_id = ? LIMIT 1`,
        [noteId, page.identity.timestamp, page.identity.siteId, page.identity.index, pageId])) {
      return false;
    }
    const winner: BootstrapPositionWinner | undefined = history.positionWinners.get(key);
    if (winner === undefined || !await rowExists(store,
      `SELECT 1 FROM original_page_position_winner WHERE note_id = ?
       AND page_timestamp = ? AND page_site_id = ? AND page_index = ?
       AND winner_timestamp = ? AND winner_site_id = ? AND position_index = ? LIMIT 1`,
      [noteId, page.identity.timestamp, page.identity.siteId, page.identity.index,
        winner.timestamp, winner.siteId, winner.positionIndex])) {
      return false;
    }
    if (page.visibility !== null && !await rowExists(store,
      `SELECT 1 FROM original_page_visibility_winner WHERE note_id = ?
       AND page_timestamp = ? AND page_site_id = ? AND page_index = ?
       AND winner_timestamp = ? AND winner_site_id = ? AND deleted = ? LIMIT 1`,
      [noteId, page.identity.timestamp, page.identity.siteId, page.identity.index,
        page.visibility.timestamp, page.visibility.siteId, page.visibility.deleted ? 1 : 0])) {
      return false;
    }
    if (page.backgroundWinner !== null) {
      const winnerMatches: boolean = page.background === null ? await rowExists(store,
        `SELECT 1 FROM original_page_background_winner WHERE note_id = ?
         AND page_timestamp = ? AND page_site_id = ? AND page_index = ?
         AND winner_timestamp = ? AND winner_site_id = ?
         AND size IS NULL AND template IS NULL AND orientation IS NULL
         AND width_mm IS NULL AND height_mm IS NULL AND background_json IS NULL LIMIT 1`,
        [noteId, page.identity.timestamp, page.identity.siteId, page.identity.index,
          page.backgroundWinner.timestamp, page.backgroundWinner.siteId]) : await rowExists(store,
        `SELECT 1 FROM original_page_background_winner WHERE note_id = ?
         AND page_timestamp = ? AND page_site_id = ? AND page_index = ?
         AND winner_timestamp = ? AND winner_site_id = ?
         AND size = ? AND template = ? AND orientation = ?
         AND width_mm = ? AND height_mm = ? AND background_json = ? LIMIT 1`,
        [noteId, page.identity.timestamp, page.identity.siteId, page.identity.index,
          page.backgroundWinner.timestamp, page.backgroundWinner.siteId,
          page.background.size, page.background.template, page.background.orientation,
          page.background.widthMm, page.background.heightMm,
          serializePageBackground(page.background.background)]);
      if (!winnerMatches) {
        return false;
      }
    }
    if (!await rowExists(store,
      `SELECT 1 FROM original_page_in_asset_winner WHERE note_id = ?
       AND page_timestamp = ? AND page_site_id = ? AND page_index = ?
       AND winner_timestamp = ? AND winner_site_id = ? AND page_in_asset = ? LIMIT 1`,
      [noteId, page.identity.timestamp, page.identity.siteId, page.identity.index,
        page.pageInAssetWinner.timestamp, page.pageInAssetWinner.siteId, page.pageInAsset])) {
      return false;
    }
  }
  return true;
}

async function groupMatches(store: relationalStore.RdbStore, table: string, countColumn: string,
  noteId: string, operation: OperationIdentity, location: OriginalSequenceIdentity | null,
  count: number, modifiedTime: string): Promise<boolean> {
  if (location === null) {
    return rowExists(store,
      `SELECT 1 FROM ${table} WHERE note_id = ? AND op_timestamp = ? AND op_site_id = ?
       AND parent_timestamp IS NULL AND parent_site_id IS NULL AND parent_index IS NULL
       AND ${countColumn} = ? AND modified_time = ? LIMIT 1`,
      [noteId, operation.timestamp, operation.siteId, count, modifiedTime]);
  }
  return rowExists(store,
    `SELECT 1 FROM ${table} WHERE note_id = ? AND op_timestamp = ? AND op_site_id = ?
     AND parent_timestamp = ? AND parent_site_id = ? AND parent_index = ?
     AND ${countColumn} = ? AND modified_time = ? LIMIT 1`,
    [noteId, operation.timestamp, operation.siteId, location.timestamp, location.siteId,
      location.index, count, modifiedTime]);
}

async function identityMatches(store: relationalStore.RdbStore, noteId: string,
  identity: OriginalSequenceIdentity, pageId: string | undefined): Promise<boolean> {
  if (pageId === undefined) {
    return rowExists(store,
      `SELECT 1 FROM original_page_identity WHERE note_id = ?
       AND seq_timestamp = ? AND seq_site_id = ? AND seq_index = ?
       AND page_id IS NULL AND visible = 0 LIMIT 1`,
      [noteId, identity.timestamp, identity.siteId, identity.index]);
  }
  return rowExists(store,
    `SELECT 1 FROM original_page_identity WHERE note_id = ?
     AND seq_timestamp = ? AND seq_site_id = ? AND seq_index = ?
     AND page_id = ? AND visible = 1 LIMIT 1`,
    [noteId, identity.timestamp, identity.siteId, identity.index, pageId]);
}

async function hasExistingMapping(store: relationalStore.RdbStore, noteId: string): Promise<boolean> {
  const tables: string[] = [
    'original_page_insert_group', 'original_page_identity', 'original_page_position_group',
    'original_page_position', 'original_page_position_winner',
    'original_page_visibility_winner', 'original_page_background_winner',
    'original_page_in_asset_winner',
    'original_deleted_page',
  ];
  for (const table of tables) {
    if (await countRows(store, `SELECT COUNT(*) AS value FROM ${table} WHERE note_id = ?`,
      [noteId]) !== 0) {
      return true;
    }
  }
  return false;
}

async function exactCount(store: relationalStore.RdbStore, table: string,
  noteId: string, expected: number): Promise<boolean> {
  return await countRows(store, `SELECT COUNT(*) AS value FROM ${table} WHERE note_id = ?`,
    [noteId]) === expected;
}

function countPositions(groups: BootstrapPositionGroup[]): number {
  let result: number = 0;
  for (const group of groups) {
    result += group.positions.length;
  }
  return result;
}

function countVisibilityWinners(pages: Map<string, BootstrapPageState>): number {
  let result: number = 0;
  pages.forEach((page: BootstrapPageState): void => {
    if (page.visibility !== null) {
      result++;
    }
  });
  return result;
}

function countBackgroundWinners(pages: Map<string, BootstrapPageState>): number {
  let result: number = 0;
  pages.forEach((page: BootstrapPageState): void => {
    if (page.backgroundWinner !== null) {
      result++;
    }
  });
  return result;
}

function countBoundArchivedPages(history: BootstrapHistory,
  pageIdBySequence: Map<string, string>): number {
  let result: number = 0;
  history.pages.forEach((page: BootstrapPageState, key: string): void => {
    if (page.visibility !== null && page.visibility.deleted && pageIdBySequence.has(key)) {
      result++;
    }
  });
  return result;
}

async function readPageIds(store: relationalStore.RdbStore, noteId: string): Promise<string[]> {
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

async function countRows(store: relationalStore.RdbStore, sql: string,
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

async function rowExists(store: relationalStore.RdbStore, sql: string,
  args: relationalStore.ValueType[]): Promise<boolean> {
  const rows = await store.querySql(sql, args);
  try {
    return rows.goToFirstRow();
  } finally {
    rows.close();
  }
}

function effectiveTime(operation: OriginalNoteBundleOperation): string {
  return operation.serverTime === null ? operation.clientTime : operation.serverTime;
}

function replayDeferred(reason: string): BootstrapReplayResult {
  return { history: null, deferredReason: reason };
}

function requireHistory(result: BootstrapReplayResult): BootstrapHistory {
  if (result.history === null) {
    throw new Error('note bundle page history is absent');
  }
  return result.history;
}

function decodeOriginalUuid(bytes: Uint8Array): string {
  if (bytes.length !== 16) {
    throw new Error('original UUID has the wrong size');
  }
  const high: string = littleEndianHex(bytes, 8, 8);
  const low: string = littleEndianHex(bytes, 0, 8);
  const value: string = high + low;
  return `${value.slice(0, 8)}-${value.slice(8, 12)}-${value.slice(12, 16)}-` +
    `${value.slice(16, 20)}-${value.slice(20)}`;
}

function littleEndianHex(bytes: Uint8Array, start: number, count: number): string {
  let result: string = '';
  for (let index: number = start + count - 1; index >= start; index--) {
    result += bytes[index].toString(16).padStart(2, '0');
  }
  return result;
}

function originalNoteIdsMatch(expected: string, actual: string): boolean {
  const expectedCanonical: string | null = canonicalUuid(expected);
  const actualCanonical: string | null = canonicalUuid(actual);
  return expectedCanonical !== null && expectedCanonical === actualCanonical;
}

function canonicalUuid(value: string): string | null {
  const compact: string = value.replace(/-/g, '').toLowerCase();
  return /^[0-9a-f]{32}$/.test(compact) ? compact : null;
}

function operationKey(identity: OperationIdentity): string {
  return `${identity.timestamp.toString(16)}:${identity.siteId.toString(16)}`;
}

function requireDecimal(value: string | null): string {
  if (value === null) {
    throw new Error('required unsigned timestamp is absent');
  }
  validateUnsignedLongDecimal(value);
  return value;
}

function readU16(bytes: Uint8Array, offset: number): number {
  return bytes[offset] + bytes[offset + 1] * 0x100;
}

function readU32(bytes: Uint8Array, offset: number): number {
  return bytes[offset] + bytes[offset + 1] * 0x100 + bytes[offset + 2] * 0x10000 +
    bytes[offset + 3] * 0x1000000;
}

function deferred(reason: string): OriginalPageIdentityBootstrapResult {
  return { applied: false, deferredReason: reason };
}
