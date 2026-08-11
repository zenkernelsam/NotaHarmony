import { relationalStore } from '@kit.ArkData';
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

export const ORIGINAL_SET_METADATA_PAYLOAD_TYPE: number = 1;

export interface OriginalSetMetadataPayload {
  hasTitle: boolean;
  title: string | null;
  hasPageBackground: boolean;
  pageBackground: OriginalDecodedPageBackground | null;
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

export function decodeOriginalSetMetadataTable(
  table: OriginalFlatBufferTableReader): OriginalSetMetadataPayload {
  const titleSetter: OriginalFlatBufferTableReader | null = table.readTable(0);
  const setter: OriginalFlatBufferTableReader | null = table.readTable(1);
  const value: OriginalFlatBufferTableReader | null = setter === null ? null : setter.readTable(0);
  return {
    hasTitle: titleSetter !== null,
    title: titleSetter === null ? null : titleSetter.readUtf8String(0, false, 1024),
    hasPageBackground: setter !== null,
    pageBackground: value === null ? null : decodeOriginalPageBackgroundTable(value),
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
    // Phase 70 accepts the title/background combination emitted by original note bundles.
    if (table.hasField(2) || table.hasField(3) || table.hasField(4) ||
      table.hasField(5) || table.hasField(6) || table.hasField(7)) {
      return 'SET_METADATA_FIELDS_UNSUPPORTED';
    }
    if (payload.hasTitle && (payload.title === null || payload.title.length < 1 || payload.title.length > 256)) {
      return 'SET_METADATA_TITLE_UNSUPPORTED';
    }
    if (!payload.hasPageBackground) {
      return 'SET_METADATA_HAS_NO_SUPPORTED_FIELD';
    }
    if (payload.pageBackground !== null && payload.pageBackground.hasPdf) {
      return 'SET_METADATA_PDF_BACKGROUND_UNSUPPORTED';
    }
    if (payload.pageBackground !== null && !originalPageBackgroundFitsHarmony(payload.pageBackground)) {
      return 'SET_METADATA_BACKGROUND_SIZE_UNSUPPORTED';
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
    const winner: StoredNoteBackgroundWinner | null = await this.readBackgroundWinner(store, operation.noteId);
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
    let applyBackground: boolean = true;
    if (winner !== null) {
      const compared: number = compareOperationIdentity(operation, winner);
      if (compared < 0) {
        applyBackground = false;
      } else if (compared === 0) {
        if (!storedBackgroundMatches(winner, payload.pageBackground)) {
          return { deferredReason: 'SET_METADATA_BACKGROUND_IDENTITY_CONFLICT' };
        }
        applyBackground = false;
      }
    }
    if (applyTitle && payload.title !== null) {
      await this.writeTitleWinner(store, operation, payload.title, titleWinner);
      await this.materializeTitle(store, operation.noteId, payload.title);
    }
    if (applyBackground) {
      await this.writeBackgroundWinner(store, operation, payload.pageBackground, winner);
      await this.materializeFallbackPages(store, operation.noteId, payload.pageBackground);
    }
    if (applyTitle || applyBackground) {
      await this.advanceStructureRevision(store, operation.noteId);
    }
    return { deferredReason: null };
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
  const rows = await store.querySql(
    `SELECT size, template, orientation, width_mm, height_mm, background_json
     FROM original_note_background_winner WHERE note_id = ?`, [noteId]);
  try {
    if (!rows.goToFirstRow()) {
      return defaultDecodedBackground();
    }
    const backgroundColumn: number = rows.getColumnIndex('background_json');
    if (rows.isColumnNull(backgroundColumn)) {
      return defaultDecodedBackground();
    }
    const background: PageBackground | null = parsePageBackground(rows.getString(backgroundColumn));
    if (background === null) {
      throw new Error('stored original note background unexpectedly decoded as null');
    }
    return {
      background: background,
      size: rows.getLong(rows.getColumnIndex('size')) as PaperSize,
      template: rows.getLong(rows.getColumnIndex('template')) as PaperTemplate,
      orientation: rows.getLong(rows.getColumnIndex('orientation')) as PageOrientation,
      widthMm: rows.getDouble(rows.getColumnIndex('width_mm')),
      heightMm: rows.getDouble(rows.getColumnIndex('height_mm')),
      hasPdf: false,
    };
  } finally {
    rows.close();
  }
}
