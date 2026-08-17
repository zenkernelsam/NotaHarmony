import { relationalStore } from '@kit.ArkData';
import {
  isOriginalDefaultFontFamily, isOriginalDefaultFontSize, isOriginalHandwritingLanguage,
  isOriginalNoteBlockWrapSupport, isOriginalNoteLayoutMode,
  OriginalNoteBlockWrapSupport, OriginalNoteLayoutMode,
} from '../core/model/OriginalNoteMetadataPolicy';
import { isOriginalNoteTitleWireValue } from '../core/model/OriginalNoteTitlePolicy';
import { PageBackground, PageOrientation, PaperSize, PaperTemplate } from '../core/model/NoteTypes';
import {
  originalDefaultNoteBackground, parsePageBackground, serializePageBackground,
} from '../core/model/PageBackgroundModel';
import { compareOperationIdentity, OperationIdentity } from './OperationIdentity';
import { SearchItemType } from './SearchItemType';
import { foldSearchText } from './SearchText';
import {
  decodeOriginalPageBackgroundTable, OriginalDecodedPageBackground,
  originalPageBackgroundFitsHarmony,
} from './OriginalPageBackgroundOperation';
import {
  OriginalFlatBufferTableReader, readOriginalPayloadTable,
} from './OriginalSyncedOperationFlatBuffer';
import {
  StoredSyncedOperation, SyncedOperationApplier, SyncedOperationApplyResult,
} from './SyncedOperationInbox';
import {
  mergeOriginalAssetReference, OriginalAssetReferenceConflict,
} from './OriginalAssetReferenceStore';

export const ORIGINAL_SET_METADATA_PAYLOAD_TYPE: number = 1;
const MAX_HANDWRITING_LANGUAGE_BYTES: number = 1024;
const MAX_DEFAULT_FONT_FAMILY_BYTES: number = 120;

export interface OriginalSetMetadataPayload {
  hasTitle: boolean;
  title: string | null;
  hasPageBackground: boolean;
  pageBackground: OriginalDecodedPageBackground | null;
  hasHandwritingLanguage: boolean;
  handwritingLanguage: string | null;
  hasAlignTextToLines: boolean;
  alignTextToLines: boolean;
  hasDefaultFontFamily: boolean;
  defaultFontFamily: string;
  hasDefaultFontSize: boolean;
  defaultFontSize: number;
  hasLayoutMode: boolean;
  layoutMode: number;
  hasBlockWrapSupport: boolean;
  blockWrapSupport: number;
}

// The original register value and its effective rendering value are not the
// same state: a null winner renders as the Letter fallback, but Undo must keep
// the nullable value so it can emit an explicit SetPageBackground(null).
export interface OriginalNoteBackgroundState {
  registerValue: OriginalDecodedPageBackground | null;
  effective: OriginalDecodedPageBackground;
}

export interface OriginalNoteMetadataState {
  hasHandwritingLanguage: boolean;
  handwritingLanguage: string | null;
  alignTextToLines: boolean | null;
  defaultFontFamily: string | null;
  defaultFontSize: number | null;
  layoutMode: OriginalNoteLayoutMode | null;
  blockWrapSupport: OriginalNoteBlockWrapSupport | null;
}

interface StoredNoteBackgroundWinner extends OperationIdentity {
  size: number | null;
  template: number | null;
  orientation: number | null;
  widthMm: number | null;
  heightMm: number | null;
  backgroundJson: string | null;
}

interface StoredNoteTitleWinner extends OperationIdentity {
  title: string;
}

interface StoredNoteHandwritingLanguageWinner extends OperationIdentity {
  value: string | null;
}

interface StoredNoteBooleanWinner extends OperationIdentity {
  value: boolean;
}

interface StoredNoteStringWinner extends OperationIdentity {
  value: string;
}

interface StoredNoteNumberWinner extends OperationIdentity {
  value: number;
}

export function decodeOriginalSetMetadataTable(
  table: OriginalFlatBufferTableReader): OriginalSetMetadataPayload {
  const titleSetter: OriginalFlatBufferTableReader | null = table.readTable(0);
  const setter: OriginalFlatBufferTableReader | null = table.readTable(1);
  const value: OriginalFlatBufferTableReader | null = setter === null ? null : setter.readTable(0);
  const handwritingSetter: OriginalFlatBufferTableReader | null = table.readTable(2);
  const hasDefaultFontFamily: boolean = table.hasField(4);
  return {
    hasTitle: titleSetter !== null,
    title: titleSetter === null ? null : titleSetter.readUtf8String(0, false, 1024),
    hasPageBackground: setter !== null,
    pageBackground: value === null ? null : decodeOriginalPageBackgroundTable(value),
    hasHandwritingLanguage: handwritingSetter !== null,
    handwritingLanguage: handwritingSetter === null ? null :
      handwritingSetter.readUtf8String(0, false, MAX_HANDWRITING_LANGUAGE_BYTES),
    hasAlignTextToLines: table.hasField(3),
    alignTextToLines: table.readUint8(3, 0) !== 0,
    hasDefaultFontFamily: hasDefaultFontFamily,
    defaultFontFamily: hasDefaultFontFamily ?
      requirePresentString(table, 4, MAX_DEFAULT_FONT_FAMILY_BYTES) : '',
    hasDefaultFontSize: table.hasField(5),
    defaultFontSize: table.readFloat32(5, 0),
    hasLayoutMode: table.hasField(6),
    layoutMode: table.readUint8(6, OriginalNoteLayoutMode.PAGED),
    hasBlockWrapSupport: table.hasField(7),
    blockWrapSupport: table.readUint8(7, OriginalNoteBlockWrapSupport.WRAP_ENABLED),
  };
}

export class OriginalSetMetadataOperationApplier implements SyncedOperationApplier {
  supports(payloadType: number): boolean {
    return payloadType === ORIGINAL_SET_METADATA_PAYLOAD_TYPE;
  }

  async apply(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation): Promise<SyncedOperationApplyResult> {
    let table: OriginalFlatBufferTableReader;
    try {
      table = readOriginalPayloadTable(operation.rawOperation, ORIGINAL_SET_METADATA_PAYLOAD_TYPE);
    } catch (_error) {
      return { deferredReason: 'MALFORMED_SET_METADATA_PAYLOAD' };
    }
    return this.applyTable(store, operation, table);
  }

  preflightTable(table: OriginalFlatBufferTableReader): string | null {
    let payload: OriginalSetMetadataPayload;
    try {
      payload = decodeOriginalSetMetadataTable(table);
    } catch (_error) {
      return 'MALFORMED_SET_METADATA_PAYLOAD';
    }
    if (payload.hasTitle && !isOriginalNoteTitleWireValue(payload.title)) {
      return 'SET_METADATA_TITLE_UNSUPPORTED';
    }
    if (!hasMetadataField(payload)) {
      return 'SET_METADATA_HAS_NO_SUPPORTED_FIELD';
    }
    if (payload.pageBackground !== null && !originalPageBackgroundFitsHarmony(payload.pageBackground)) {
      return 'SET_METADATA_BACKGROUND_SIZE_UNSUPPORTED';
    }
    if (payload.pageBackground?.background.pdf !== undefined &&
      payload.pageBackground.background.pdf !== null &&
      payload.pageBackground.background.pdf.pagesConsumed !== 1) {
      return 'SET_METADATA_TEMPLATE_PDF_PAGE_COUNT_UNSUPPORTED';
    }
    if (payload.hasHandwritingLanguage &&
      !isOriginalHandwritingLanguage(payload.handwritingLanguage)) {
      return 'SET_METADATA_HANDWRITING_LANGUAGE_UNSUPPORTED';
    }
    if (payload.hasDefaultFontFamily && !isOriginalDefaultFontFamily(payload.defaultFontFamily)) {
      return 'SET_METADATA_DEFAULT_FONT_FAMILY_UNSUPPORTED';
    }
    if (payload.hasDefaultFontSize && !isOriginalDefaultFontSize(payload.defaultFontSize)) {
      return 'SET_METADATA_DEFAULT_FONT_SIZE_UNSUPPORTED';
    }
    if (payload.hasLayoutMode && !isOriginalNoteLayoutMode(payload.layoutMode)) {
      return 'SET_METADATA_LAYOUT_MODE_UNSUPPORTED';
    }
    if (payload.hasBlockWrapSupport &&
      !isOriginalNoteBlockWrapSupport(payload.blockWrapSupport)) {
      return 'SET_METADATA_BLOCK_WRAP_SUPPORT_UNSUPPORTED';
    }
    return null;
  }

  async applyTable(store: relationalStore.RdbStore, operation: StoredSyncedOperation,
    table: OriginalFlatBufferTableReader): Promise<SyncedOperationApplyResult> {
    const reason: string | null = this.preflightTable(table);
    if (reason !== null) {
      return { deferredReason: reason };
    }
    const payload: OriginalSetMetadataPayload = decodeOriginalSetMetadataTable(table);
    const titleWinner: StoredNoteTitleWinner | null = payload.hasTitle
      ? await this.readTitleWinner(store, operation.noteId) : null;
    const backgroundWinner: StoredNoteBackgroundWinner | null = payload.hasPageBackground
      ? await this.readBackgroundWinner(store, operation.noteId) : null;
    const handwritingWinner: StoredNoteHandwritingLanguageWinner | null =
      payload.hasHandwritingLanguage ?
        await this.readHandwritingLanguageWinner(store, operation.noteId) : null;
    const alignWinner: StoredNoteBooleanWinner | null = payload.hasAlignTextToLines ?
      await this.readAlignTextToLinesWinner(store, operation.noteId) : null;
    const familyWinner: StoredNoteStringWinner | null = payload.hasDefaultFontFamily ?
      await this.readDefaultFontFamilyWinner(store, operation.noteId) : null;
    const sizeWinner: StoredNoteNumberWinner | null = payload.hasDefaultFontSize ?
      await this.readDefaultFontSizeWinner(store, operation.noteId) : null;
    const layoutWinner: StoredNoteNumberWinner | null = payload.hasLayoutMode ?
      await this.readLayoutModeWinner(store, operation.noteId) : null;
    const wrapWinner: StoredNoteNumberWinner | null = payload.hasBlockWrapSupport ?
      await this.readBlockWrapSupportWinner(store, operation.noteId) : null;
    let applyTitle: boolean = payload.hasTitle;
    if (payload.hasTitle && titleWinner !== null) {
      const titleCompared: number = compareOperationIdentity(operation, titleWinner);
      if (titleCompared < 0) {
        applyTitle = false;
      } else if (titleCompared === 0) {
        if (titleWinner.title !== payload.title) {
          return { deferredReason: 'SET_METADATA_TITLE_IDENTITY_CONFLICT' };
        }
        applyTitle = false;
      }
    }
    let applyBackground: boolean = payload.hasPageBackground;
    if (payload.hasPageBackground && backgroundWinner !== null) {
      const compared: number = compareOperationIdentity(operation, backgroundWinner);
      if (compared < 0) {
        applyBackground = false;
      } else if (compared === 0) {
        if (!storedBackgroundMatches(backgroundWinner, payload.pageBackground)) {
          return { deferredReason: 'SET_METADATA_BACKGROUND_IDENTITY_CONFLICT' };
        }
        applyBackground = false;
      }
    }
    let applyHandwriting: boolean = payload.hasHandwritingLanguage;
    if (payload.hasHandwritingLanguage && handwritingWinner !== null) {
      const compared: number = compareOperationIdentity(operation, handwritingWinner);
      if (compared < 0) {
        applyHandwriting = false;
      } else if (compared === 0) {
        if (handwritingWinner.value !== payload.handwritingLanguage) {
          return { deferredReason: 'SET_METADATA_HANDWRITING_LANGUAGE_IDENTITY_CONFLICT' };
        }
        applyHandwriting = false;
      }
    }
    let applyAlign: boolean = payload.hasAlignTextToLines;
    if (payload.hasAlignTextToLines && alignWinner !== null) {
      const compared: number = compareOperationIdentity(operation, alignWinner);
      if (compared < 0) {
        applyAlign = false;
      } else if (compared === 0) {
        if (alignWinner.value !== payload.alignTextToLines) {
          return { deferredReason: 'SET_METADATA_ALIGN_TEXT_TO_LINES_IDENTITY_CONFLICT' };
        }
        applyAlign = false;
      }
    }
    let applyFamily: boolean = payload.hasDefaultFontFamily;
    if (payload.hasDefaultFontFamily && familyWinner !== null) {
      const compared: number = compareOperationIdentity(operation, familyWinner);
      if (compared < 0) {
        applyFamily = false;
      } else if (compared === 0) {
        if (familyWinner.value !== payload.defaultFontFamily) {
          return { deferredReason: 'SET_METADATA_DEFAULT_FONT_FAMILY_IDENTITY_CONFLICT' };
        }
        applyFamily = false;
      }
    }
    let applySize: boolean = payload.hasDefaultFontSize;
    if (payload.hasDefaultFontSize && sizeWinner !== null) {
      const compared: number = compareOperationIdentity(operation, sizeWinner);
      if (compared < 0) {
        applySize = false;
      } else if (compared === 0) {
        if (sizeWinner.value !== payload.defaultFontSize) {
          return { deferredReason: 'SET_METADATA_DEFAULT_FONT_SIZE_IDENTITY_CONFLICT' };
        }
        applySize = false;
      }
    }
    let applyLayout: boolean = payload.hasLayoutMode;
    if (payload.hasLayoutMode && layoutWinner !== null) {
      const compared: number = compareOperationIdentity(operation, layoutWinner);
      if (compared < 0) {
        applyLayout = false;
      } else if (compared === 0) {
        if (layoutWinner.value !== payload.layoutMode) {
          return { deferredReason: 'SET_METADATA_LAYOUT_MODE_IDENTITY_CONFLICT' };
        }
        applyLayout = false;
      }
    }
    let applyWrap: boolean = payload.hasBlockWrapSupport;
    if (payload.hasBlockWrapSupport && wrapWinner !== null) {
      const compared: number = compareOperationIdentity(operation, wrapWinner);
      if (compared < 0) {
        applyWrap = false;
      } else if (compared === 0) {
        if (wrapWinner.value !== payload.blockWrapSupport) {
          return { deferredReason: 'SET_METADATA_BLOCK_WRAP_SUPPORT_IDENTITY_CONFLICT' };
        }
        applyWrap = false;
      }
    }
    // The inbox commits deferred results. Keep every deferrable identity decision
    // ahead of mergeOriginalAssetReference(), which may insert/update note_asset.
    // A stale background register is a complete no-op and must not attach its PDF.
    const assetReason: string | null = applyBackground
      ? await this.mergePdfAsset(store, operation.noteId, payload.pageBackground) : null;
    if (assetReason !== null) {
      return { deferredReason: assetReason };
    }
    if (applyTitle && payload.title !== null) {
      await this.writeTitleWinner(store, operation, payload.title, titleWinner);
      await this.materializeTitle(store, operation.noteId, payload.title);
    }
    if (applyBackground) {
      await this.writeBackgroundWinner(
        store, operation, payload.pageBackground, backgroundWinner);
      await this.materializeFallbackPages(store, operation.noteId, payload.pageBackground);
    }
    if (applyHandwriting) {
      await this.writeHandwritingLanguageWinner(
        store, operation, payload.handwritingLanguage, handwritingWinner);
    }
    if (applyAlign) {
      await this.writeAlignTextToLinesWinner(
        store, operation, payload.alignTextToLines, alignWinner);
    }
    if (applyFamily) {
      await this.writeDefaultFontFamilyWinner(
        store, operation, payload.defaultFontFamily, familyWinner);
    }
    if (applySize) {
      await this.writeDefaultFontSizeWinner(
        store, operation, payload.defaultFontSize, sizeWinner);
    }
    if (applyLayout) {
      await this.writeLayoutModeWinner(store, operation, payload.layoutMode, layoutWinner);
    }
    if (applyWrap) {
      await this.writeBlockWrapSupportWinner(
        store, operation, payload.blockWrapSupport, wrapWinner);
    }
    if (applyTitle || applyBackground || applyHandwriting || applyAlign || applyFamily ||
      applySize || applyLayout || applyWrap) {
      await this.advanceStructureRevision(store, operation.noteId);
    }
    return { deferredReason: null };
  }

  private async mergePdfAsset(store: relationalStore.RdbStore, noteId: string,
    background: OriginalDecodedPageBackground | null): Promise<string | null> {
    if (background === null || background.background.pdf === undefined ||
      background.background.pdf === null) {
      return null;
    }
    const conflict: OriginalAssetReferenceConflict = await mergeOriginalAssetReference(
      store, noteId, background.background.pdf.metadata);
    if (conflict === OriginalAssetReferenceConflict.METADATA) {
      return 'SET_METADATA_PDF_ASSET_METADATA_CONFLICT';
    }
    if (conflict === OriginalAssetReferenceConflict.LOCAL_PATH) {
      return 'SET_METADATA_PDF_ASSET_PATH_CONFLICT';
    }
    return null;
  }

  private async readBackgroundWinner(store: relationalStore.RdbStore,
    noteId: string): Promise<StoredNoteBackgroundWinner | null> {
    const rows = await store.querySql(
      `SELECT winner_timestamp, winner_site_id, size, template, orientation,
        width_mm, height_mm, background_json
       FROM original_note_background_winner WHERE note_id = ?`, [noteId]);
    try {
      if (!rows.goToFirstRow()) {
        return null;
      }
      const backgroundColumn: number = rows.getColumnIndex('background_json');
      const sizeColumn: number = rows.getColumnIndex('size');
      const templateColumn: number = rows.getColumnIndex('template');
      const orientationColumn: number = rows.getColumnIndex('orientation');
      const widthColumn: number = rows.getColumnIndex('width_mm');
      const heightColumn: number = rows.getColumnIndex('height_mm');
      return {
        timestamp: rows.getLong(rows.getColumnIndex('winner_timestamp')),
        siteId: rows.getLong(rows.getColumnIndex('winner_site_id')),
        size: rows.isColumnNull(sizeColumn) ? null : rows.getLong(sizeColumn),
        template: rows.isColumnNull(templateColumn) ? null : rows.getLong(templateColumn),
        orientation: rows.isColumnNull(orientationColumn) ? null : rows.getLong(orientationColumn),
        widthMm: rows.isColumnNull(widthColumn) ? null : rows.getDouble(widthColumn),
        heightMm: rows.isColumnNull(heightColumn) ? null : rows.getDouble(heightColumn),
        backgroundJson: rows.isColumnNull(backgroundColumn) ? null : rows.getString(backgroundColumn),
      };
    } finally {
      rows.close();
    }
  }

  private async writeBackgroundWinner(store: relationalStore.RdbStore, operation: StoredSyncedOperation,
    background: OriginalDecodedPageBackground | null,
    previous: StoredNoteBackgroundWinner | null): Promise<void> {
    const values: relationalStore.ValuesBucket = this.backgroundValues(background);
    values['note_id'] = operation.noteId;
    values['winner_timestamp'] = operation.timestamp;
    values['winner_site_id'] = operation.siteId;
    if (previous === null) {
      await store.insert('original_note_background_winner', values);
      return;
    }
    const predicates = new relationalStore.RdbPredicates('original_note_background_winner');
    predicates.equalTo('note_id', operation.noteId);
    predicates.equalTo('winner_timestamp', previous.timestamp);
    predicates.equalTo('winner_site_id', previous.siteId);
    if (await store.update(values, predicates) !== 1) {
      throw new Error('original note background winner changed concurrently');
    }
  }

  private async readTitleWinner(store: relationalStore.RdbStore,
    noteId: string): Promise<StoredNoteTitleWinner | null> {
    const rows = await store.querySql(
      `SELECT winner_timestamp, winner_site_id, title
       FROM original_note_title_winner WHERE note_id = ?`, [noteId]);
    try {
      if (!rows.goToFirstRow()) {
        return null;
      }
      return {
        timestamp: rows.getLong(rows.getColumnIndex('winner_timestamp')),
        siteId: rows.getLong(rows.getColumnIndex('winner_site_id')),
        title: rows.getString(rows.getColumnIndex('title')),
      };
    } finally {
      rows.close();
    }
  }

  private async writeTitleWinner(store: relationalStore.RdbStore, operation: StoredSyncedOperation,
    title: string, previous: StoredNoteTitleWinner | null): Promise<void> {
    const values: relationalStore.ValuesBucket = {
      'note_id': operation.noteId,
      'winner_timestamp': operation.timestamp,
      'winner_site_id': operation.siteId,
      'title': title,
    };
    if (previous === null) {
      await store.insert('original_note_title_winner', values);
      return;
    }
    const predicates = new relationalStore.RdbPredicates('original_note_title_winner');
    predicates.equalTo('note_id', operation.noteId);
    predicates.equalTo('winner_timestamp', previous.timestamp);
    predicates.equalTo('winner_site_id', previous.siteId);
    if (await store.update(values, predicates) !== 1) {
      throw new Error('original note title winner changed concurrently');
    }
  }

  private async readHandwritingLanguageWinner(store: relationalStore.RdbStore,
    noteId: string): Promise<StoredNoteHandwritingLanguageWinner | null> {
    return readNullableStringWinner(store, 'original_note_handwriting_language_winner',
      'handwriting_language', noteId);
  }

  private async writeHandwritingLanguageWinner(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation, value: string | null,
    previous: StoredNoteHandwritingLanguageWinner | null): Promise<void> {
    await writeMetadataWinner(store, operation, 'original_note_handwriting_language_winner',
      'handwriting_language', value, previous);
  }

  private async readAlignTextToLinesWinner(store: relationalStore.RdbStore,
    noteId: string): Promise<StoredNoteBooleanWinner | null> {
    const winner: StoredNoteNumberWinner | null = await readIntegerWinner(
      store, 'original_note_align_text_to_lines_winner', 'align_text_to_lines', noteId);
    return winner === null ? null : {
      timestamp: winner.timestamp, siteId: winner.siteId, value: winner.value !== 0,
    };
  }

  private async writeAlignTextToLinesWinner(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation, value: boolean,
    previous: StoredNoteBooleanWinner | null): Promise<void> {
    await writeMetadataWinner(store, operation, 'original_note_align_text_to_lines_winner',
      'align_text_to_lines', value ? 1 : 0, previous);
  }

  private async readDefaultFontFamilyWinner(store: relationalStore.RdbStore,
    noteId: string): Promise<StoredNoteStringWinner | null> {
    return readStringWinner(store, 'original_note_default_font_family_winner',
      'default_font_family', noteId);
  }

  private async writeDefaultFontFamilyWinner(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation, value: string,
    previous: StoredNoteStringWinner | null): Promise<void> {
    await writeMetadataWinner(store, operation, 'original_note_default_font_family_winner',
      'default_font_family', value, previous);
  }

  private async readDefaultFontSizeWinner(store: relationalStore.RdbStore,
    noteId: string): Promise<StoredNoteNumberWinner | null> {
    return readRealWinner(store, 'original_note_default_font_size_winner',
      'default_font_size', noteId);
  }

  private async writeDefaultFontSizeWinner(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation, value: number,
    previous: StoredNoteNumberWinner | null): Promise<void> {
    await writeMetadataWinner(store, operation, 'original_note_default_font_size_winner',
      'default_font_size', value, previous);
  }

  private async readLayoutModeWinner(store: relationalStore.RdbStore,
    noteId: string): Promise<StoredNoteNumberWinner | null> {
    return readIntegerWinner(store, 'original_note_layout_mode_winner', 'layout_mode', noteId);
  }

  private async writeLayoutModeWinner(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation, value: number,
    previous: StoredNoteNumberWinner | null): Promise<void> {
    await writeMetadataWinner(store, operation, 'original_note_layout_mode_winner',
      'layout_mode', value, previous);
  }

  private async readBlockWrapSupportWinner(store: relationalStore.RdbStore,
    noteId: string): Promise<StoredNoteNumberWinner | null> {
    return readIntegerWinner(
      store, 'original_note_block_wrap_support_winner', 'block_wrap_support', noteId);
  }

  private async writeBlockWrapSupportWinner(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation, value: number,
    previous: StoredNoteNumberWinner | null): Promise<void> {
    await writeMetadataWinner(store, operation, 'original_note_block_wrap_support_winner',
      'block_wrap_support', value, previous);
  }

  private async materializeTitle(store: relationalStore.RdbStore, noteId: string,
    title: string): Promise<void> {
    const note = new relationalStore.RdbPredicates('note_meta');
    note.equalTo('id', noteId);
    if (await store.update({ 'title': title }, note) !== 1) {
      throw new Error('original metadata note does not exist');
    }
    await store.insert('search_item', {
      'note_id': noteId,
      'type': SearchItemType.TITLE,
      'sub_id': noteId,
      'page_id': null,
      'folded_text': foldSearchText(title),
      'rects': null,
    }, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
  }

  private async materializeFallbackPages(store: relationalStore.RdbStore, noteId: string,
    background: OriginalDecodedPageBackground | null): Promise<void> {
    const effective: OriginalDecodedPageBackground = background === null ? defaultDecodedBackground() : background;
    const liveRows = await store.querySql(
      `SELECT page.page_id FROM page_info page
       JOIN original_page_identity identity ON identity.note_id = page.note_id
        AND identity.page_id = page.page_id
       WHERE page.note_id = ? AND page.background_json IS NULL`, [noteId]);
    const pageIds: string[] = [];
    try {
      while (liveRows.goToNextRow()) {
        pageIds.push(liveRows.getString(liveRows.getColumnIndex('page_id')));
      }
    } finally {
      liveRows.close();
    }
    const values: relationalStore.ValuesBucket = this.materializedValues(effective);
    values['background_json'] = null;
    for (const pageId of pageIds) {
      const predicates = new relationalStore.RdbPredicates('page_info');
      predicates.equalTo('note_id', noteId);
      predicates.equalTo('page_id', pageId);
      predicates.isNull('background_json');
      if (await store.update(values, predicates) !== 1) {
        throw new Error('original note background fallback page changed concurrently');
      }
    }
    const archived = new relationalStore.RdbPredicates('original_deleted_page');
    archived.equalTo('note_id', noteId);
    archived.isNull('background_json');
    await store.update(values, archived);
  }

  private backgroundValues(background: OriginalDecodedPageBackground | null): relationalStore.ValuesBucket {
    if (background === null) {
      return { 'size': null, 'template': null, 'orientation': null, 'width_mm': null,
        'height_mm': null, 'background_json': null };
    }
    return this.materializedValues(background);
  }

  private materializedValues(background: OriginalDecodedPageBackground): relationalStore.ValuesBucket {
    return {
      'size': background.size, 'template': background.template,
      'orientation': background.orientation, 'width_mm': background.widthMm,
      'height_mm': background.heightMm,
      'background_json': serializePageBackground(background.background),
    };
  }

  private async advanceStructureRevision(store: relationalStore.RdbStore, noteId: string): Promise<void> {
    const rows = await store.querySql('SELECT structure_revision FROM note_meta WHERE id = ?', [noteId]);
    let revision: number;
    try {
      if (!rows.goToFirstRow()) {
        throw new Error('original metadata note does not exist');
      }
      revision = rows.getLong(rows.getColumnIndex('structure_revision'));
    } finally {
      rows.close();
    }
    if (!Number.isSafeInteger(revision) || revision < 0 || revision >= Number.MAX_SAFE_INTEGER) {
      throw new Error('note structure revision is invalid or exhausted');
    }
    const predicates = new relationalStore.RdbPredicates('note_meta');
    predicates.equalTo('id', noteId);
    predicates.equalTo('structure_revision', revision);
    if (await store.update({ 'structure_revision': revision + 1 }, predicates) !== 1) {
      throw new Error('note structure revision changed while applying original metadata');
    }
  }
}

function requirePresentString(table: OriginalFlatBufferTableReader, field: number,
  maximumBytes: number): string {
  const value: string | null = table.readUtf8String(field, false, maximumBytes);
  if (value === null) {
    throw new Error(`SET_METADATA string field ${field} is present without a value`);
  }
  return value;
}

function hasMetadataField(payload: OriginalSetMetadataPayload): boolean {
  return payload.hasTitle || payload.hasPageBackground || payload.hasHandwritingLanguage ||
    payload.hasAlignTextToLines || payload.hasDefaultFontFamily || payload.hasDefaultFontSize ||
    payload.hasLayoutMode || payload.hasBlockWrapSupport;
}

async function readNullableStringWinner(store: relationalStore.RdbStore, table: string,
  column: string, noteId: string): Promise<StoredNoteHandwritingLanguageWinner | null> {
  const rows = await store.querySql(
    `SELECT winner_timestamp, winner_site_id, ${column} FROM ${table} WHERE note_id = ?`, [noteId]);
  try {
    if (!rows.goToFirstRow()) {
      return null;
    }
    const valueColumn: number = rows.getColumnIndex(column);
    return {
      timestamp: rows.getLong(rows.getColumnIndex('winner_timestamp')),
      siteId: rows.getLong(rows.getColumnIndex('winner_site_id')),
      value: rows.isColumnNull(valueColumn) ? null : rows.getString(valueColumn),
    };
  } finally {
    rows.close();
  }
}

async function readStringWinner(store: relationalStore.RdbStore, table: string,
  column: string, noteId: string): Promise<StoredNoteStringWinner | null> {
  const rows = await store.querySql(
    `SELECT winner_timestamp, winner_site_id, ${column} FROM ${table} WHERE note_id = ?`, [noteId]);
  try {
    if (!rows.goToFirstRow()) {
      return null;
    }
    return {
      timestamp: rows.getLong(rows.getColumnIndex('winner_timestamp')),
      siteId: rows.getLong(rows.getColumnIndex('winner_site_id')),
      value: rows.getString(rows.getColumnIndex(column)),
    };
  } finally {
    rows.close();
  }
}

async function readIntegerWinner(store: relationalStore.RdbStore, table: string,
  column: string, noteId: string): Promise<StoredNoteNumberWinner | null> {
  const rows = await store.querySql(
    `SELECT winner_timestamp, winner_site_id, ${column} FROM ${table} WHERE note_id = ?`, [noteId]);
  try {
    if (!rows.goToFirstRow()) {
      return null;
    }
    return {
      timestamp: rows.getLong(rows.getColumnIndex('winner_timestamp')),
      siteId: rows.getLong(rows.getColumnIndex('winner_site_id')),
      value: rows.getLong(rows.getColumnIndex(column)),
    };
  } finally {
    rows.close();
  }
}

async function readRealWinner(store: relationalStore.RdbStore, table: string,
  column: string, noteId: string): Promise<StoredNoteNumberWinner | null> {
  const rows = await store.querySql(
    `SELECT winner_timestamp, winner_site_id, ${column} FROM ${table} WHERE note_id = ?`, [noteId]);
  try {
    if (!rows.goToFirstRow()) {
      return null;
    }
    return {
      timestamp: rows.getLong(rows.getColumnIndex('winner_timestamp')),
      siteId: rows.getLong(rows.getColumnIndex('winner_site_id')),
      value: rows.getDouble(rows.getColumnIndex(column)),
    };
  } finally {
    rows.close();
  }
}

async function writeMetadataWinner(store: relationalStore.RdbStore,
  operation: StoredSyncedOperation, table: string, column: string,
  value: string | number | null, previous: OperationIdentity | null): Promise<void> {
  const values: relationalStore.ValuesBucket = {
    'note_id': operation.noteId,
    'winner_timestamp': operation.timestamp,
    'winner_site_id': operation.siteId,
  };
  values[column] = value;
  if (previous === null) {
    await store.insert(table, values);
    return;
  }
  const predicates = new relationalStore.RdbPredicates(table);
  predicates.equalTo('note_id', operation.noteId);
  predicates.equalTo('winner_timestamp', previous.timestamp);
  predicates.equalTo('winner_site_id', previous.siteId);
  if (await store.update(values, predicates) !== 1) {
    throw new Error(`${table} winner changed concurrently`);
  }
}

function storedBackgroundMatches(winner: StoredNoteBackgroundWinner,
  background: OriginalDecodedPageBackground | null): boolean {
  if (background === null) {
    return winner.size === null && winner.template === null && winner.orientation === null &&
      winner.widthMm === null && winner.heightMm === null && winner.backgroundJson === null;
  }
  return winner.size === background.size && winner.template === background.template &&
    winner.orientation === background.orientation && winner.widthMm === background.widthMm &&
    winner.heightMm === background.heightMm &&
    winner.backgroundJson === serializePageBackground(background.background);
}

export function defaultDecodedBackground(): OriginalDecodedPageBackground {
  const background: PageBackground = originalDefaultNoteBackground();
  return {
    background: background,
    template: PaperTemplate.PLAIN,
    size: PaperSize.LETTER,
    orientation: PageOrientation.PORTRAIT,
    widthMm: 215.9,
    heightMm: 279.4,
    hasPdf: false,
  };
}

export async function readEffectiveNoteBackground(store: relationalStore.RdbStore,
  noteId: string): Promise<OriginalDecodedPageBackground> {
  return (await readOriginalNoteBackgroundState(store, noteId)).effective;
}

export async function readOriginalNoteBackgroundState(store: relationalStore.RdbStore,
  noteId: string): Promise<OriginalNoteBackgroundState> {
  const rows = await store.querySql(
    `SELECT size, template, orientation, width_mm, height_mm, background_json
     FROM original_note_background_winner WHERE note_id = ?`, [noteId]);
  try {
    if (!rows.goToFirstRow()) {
      return { registerValue: null, effective: defaultDecodedBackground() };
    }
    const backgroundColumn: number = rows.getColumnIndex('background_json');
    if (rows.isColumnNull(backgroundColumn)) {
      return { registerValue: null, effective: defaultDecodedBackground() };
    }
    const sizeColumn: number = rows.getColumnIndex('size');
    const templateColumn: number = rows.getColumnIndex('template');
    const orientationColumn: number = rows.getColumnIndex('orientation');
    const widthColumn: number = rows.getColumnIndex('width_mm');
    const heightColumn: number = rows.getColumnIndex('height_mm');
    if (rows.isColumnNull(sizeColumn) || rows.isColumnNull(templateColumn) ||
      rows.isColumnNull(orientationColumn) || rows.isColumnNull(widthColumn) ||
      rows.isColumnNull(heightColumn)) {
      throw new Error('stored original note background has partial concrete columns');
    }
    const background: PageBackground | null = parsePageBackground(rows.getString(backgroundColumn));
    if (background === null) {
      throw new Error('stored original note background unexpectedly decoded as null');
    }
    const decoded: OriginalDecodedPageBackground = {
      background: background,
      size: rows.getLong(sizeColumn) as PaperSize,
      template: rows.getLong(templateColumn) as PaperTemplate,
      orientation: rows.getLong(orientationColumn) as PageOrientation,
      widthMm: rows.getDouble(widthColumn),
      heightMm: rows.getDouble(heightColumn),
      hasPdf: background.pdf !== undefined && background.pdf !== null,
    };
    if (!originalPageBackgroundFitsHarmony(decoded)) {
      throw new Error('stored original note background no longer fits Harmony');
    }
    return { registerValue: decoded, effective: decoded };
  } finally {
    rows.close();
  }
}

export async function readOriginalNoteMetadataState(store: relationalStore.RdbStore,
  noteId: string): Promise<OriginalNoteMetadataState> {
  // One SQLite statement gives consumers a coherent cross-register snapshot.
  // Using h.note_id for presence keeps a stored explicit-null handwriting value
  // distinct from a missing handwriting winner row.
  const rows = await store.querySql(
    `SELECT
       h.note_id AS handwriting_winner, h.handwriting_language,
       a.note_id AS align_winner, a.align_text_to_lines,
       f.note_id AS family_winner, f.default_font_family,
       s.note_id AS size_winner, s.default_font_size,
       l.note_id AS layout_winner, l.layout_mode,
       w.note_id AS wrap_winner, w.block_wrap_support
     FROM (SELECT ? AS note_id) target
     LEFT JOIN original_note_handwriting_language_winner h ON h.note_id = target.note_id
     LEFT JOIN original_note_align_text_to_lines_winner a ON a.note_id = target.note_id
     LEFT JOIN original_note_default_font_family_winner f ON f.note_id = target.note_id
     LEFT JOIN original_note_default_font_size_winner s ON s.note_id = target.note_id
     LEFT JOIN original_note_layout_mode_winner l ON l.note_id = target.note_id
     LEFT JOIN original_note_block_wrap_support_winner w ON w.note_id = target.note_id`, [noteId]);
  try {
    if (!rows.goToFirstRow()) {
      throw new Error('original note metadata snapshot query returned no row');
    }
    const handwritingPresent: boolean =
      !rows.isColumnNull(rows.getColumnIndex('handwriting_winner'));
    const handwritingColumn: number = rows.getColumnIndex('handwriting_language');
    const handwriting: string | null = !handwritingPresent || rows.isColumnNull(handwritingColumn)
      ? null : rows.getString(handwritingColumn);
    const alignPresent: boolean = !rows.isColumnNull(rows.getColumnIndex('align_winner'));
    const alignColumn: number = rows.getColumnIndex('align_text_to_lines');
    const familyPresent: boolean = !rows.isColumnNull(rows.getColumnIndex('family_winner'));
    const familyColumn: number = rows.getColumnIndex('default_font_family');
    const sizePresent: boolean = !rows.isColumnNull(rows.getColumnIndex('size_winner'));
    const sizeColumn: number = rows.getColumnIndex('default_font_size');
    const layoutPresent: boolean = !rows.isColumnNull(rows.getColumnIndex('layout_winner'));
    const layoutColumn: number = rows.getColumnIndex('layout_mode');
    const wrapPresent: boolean = !rows.isColumnNull(rows.getColumnIndex('wrap_winner'));
    const wrapColumn: number = rows.getColumnIndex('block_wrap_support');
    if ((alignPresent && rows.isColumnNull(alignColumn)) ||
      (familyPresent && rows.isColumnNull(familyColumn)) ||
      (sizePresent && rows.isColumnNull(sizeColumn)) ||
      (layoutPresent && rows.isColumnNull(layoutColumn)) ||
      (wrapPresent && rows.isColumnNull(wrapColumn))) {
      throw new Error('stored original note metadata register has a missing required value');
    }
    const align: number | null = alignPresent ? rows.getLong(alignColumn) : null;
    const family: string | null = familyPresent ? rows.getString(familyColumn) : null;
    const size: number | null = sizePresent ? rows.getDouble(sizeColumn) : null;
    const layout: number | null = layoutPresent ? rows.getLong(layoutColumn) : null;
    const wrap: number | null = wrapPresent ? rows.getLong(wrapColumn) : null;
    if ((handwritingPresent && !isOriginalHandwritingLanguage(handwriting)) ||
      (align !== null && align !== 0 && align !== 1) ||
      (family !== null && !isOriginalDefaultFontFamily(family)) ||
      (size !== null && !isOriginalDefaultFontSize(size)) ||
      (layout !== null && !isOriginalNoteLayoutMode(layout)) ||
      (wrap !== null && !isOriginalNoteBlockWrapSupport(wrap))) {
      throw new Error('stored original note metadata register is invalid');
    }
    return {
      hasHandwritingLanguage: handwritingPresent,
      handwritingLanguage: handwriting,
      alignTextToLines: align === null ? null : align !== 0,
      defaultFontFamily: family,
      defaultFontSize: size,
      layoutMode: layout === null ? null : layout as OriginalNoteLayoutMode,
      blockWrapSupport: wrap === null ? null : wrap as OriginalNoteBlockWrapSupport,
    };
  } finally {
    rows.close();
  }
}
