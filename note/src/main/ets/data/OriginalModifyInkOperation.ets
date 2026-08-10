import { relationalStore } from '@kit.ArkData';
import { PageElementKind } from '../core/model/PageElementOrder';
import { InkStyle, StrokeElementData } from '../core/model/StrokeTypes';
import {
  compareOperationIdentity, encodeOperationId, OperationIdentity, OriginalSequenceIdentity,
  validateOperationIdentity, validateOriginalSequenceIdentity,
} from './OperationIdentity';
import {
  isSupportedOriginalStoredStroke, OriginalInkAppendRecord,
  originalInkGeometryMatches, rebuildOriginalInkGeometry, RebuiltOriginalInkGeometry,
} from './OriginalAddPathElementsOperation';
import {
  decodeOriginalInkPathReplacement, DecodedOriginalInkPath, OriginalInkPathDeferredError,
} from './OriginalInkPathCodec';
import {
  OriginalFlatBufferTableReader, readOriginalPayloadTable,
} from './OriginalSyncedOperationFlatBuffer';
import { SearchItemType } from './SearchItemType';
import {
  decodePersistedElement, encodePersistedElement, PersistedElement,
} from './StrokePersistence';
import {
  StoredSyncedOperation, SyncedOperationApplier, SyncedOperationApplyResult,
} from './SyncedOperationInbox';

export const ORIGINAL_MODIFY_INK_PAYLOAD_TYPE: number = 17;
const MAX_ORIGINAL_MODIFY_INK_COUNT: number = 10000;
const MAX_ORIGINAL_INK_PATH_BYTES: number = 16 * 1024 * 1024;

export interface OriginalModifyInkPayload {
  inks: OperationIdentity[];
  centerPath: Uint8Array | null;
  hasUnsupportedFields: boolean;
}

interface StoredInkState {
  basePath: Uint8Array;
  winner: OperationIdentity;
}

interface StoredInkTarget {
  ink: OperationIdentity;
  page: OriginalSequenceIdentity;
  pageId: string;
  table: string;
  revisionTable: string;
  revision: number;
  archived: boolean;
}

interface PlannedReplacement {
  target: StoredInkTarget;
  state: StoredInkState;
  stroke: StrokeElementData;
  geometry: RebuiltOriginalInkGeometry;
}

export function decodeOriginalModifyInk(bytes: Uint8Array): OriginalModifyInkPayload {
  return decodeOriginalModifyInkTable(
    readOriginalPayloadTable(bytes, ORIGINAL_MODIFY_INK_PAYLOAD_TYPE));
}

export function decodeOriginalModifyInkTable(table: OriginalFlatBufferTableReader):
  OriginalModifyInkPayload {
  const rawInks: number[][] = table.readInlineOperationIdentityVector(
    0, MAX_ORIGINAL_MODIFY_INK_COUNT);
  if (rawInks.length === 0) {
    throw new Error('original modify-ink contains no target inks');
  }
  const inks: OperationIdentity[] = [];
  const identities: Set<string> = new Set<string>();
  for (const raw of rawInks) {
    const ink: OperationIdentity = { timestamp: raw[0], siteId: raw[1] };
    validateOperationIdentity(ink);
    const identity: string = encodeOperationId(ink);
    if (identities.has(identity)) {
      throw new Error('original modify-ink repeats a target ink');
    }
    identities.add(identity);
    inks.push(ink);
  }
  let hasUnsupportedFields: boolean = false;
  for (let field: number = 1; field <= 18; field++) {
    if (field !== 8 && table.hasField(field)) {
      hasUnsupportedFields = true;
    }
  }
  return {
    inks: inks,
    centerPath: table.readByteVector(8, false, MAX_ORIGINAL_INK_PATH_BYTES),
    hasUnsupportedFields: hasUnsupportedFields,
  };
}

export class OriginalModifyInkOperationApplier implements SyncedOperationApplier {
  supports(payloadType: number): boolean {
    return payloadType === ORIGINAL_MODIFY_INK_PAYLOAD_TYPE;
  }

  async apply(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation): Promise<SyncedOperationApplyResult> {
    let payload: OriginalModifyInkPayload;
    try {
      payload = decodeOriginalModifyInk(operation.rawOperation);
    } catch (_error) {
      return { deferredReason: 'MALFORMED_MODIFY_INK_PAYLOAD' };
    }
    if (payload.hasUnsupportedFields) {
      return { deferredReason: 'MODIFY_INK_ADDITIONAL_FIELDS_UNSUPPORTED' };
    }
    if (payload.centerPath === null) {
      return { deferredReason: null };
    }
    let decodedPath: DecodedOriginalInkPath;
    try {
      decodedPath = decodeOriginalInkPathReplacement(payload.centerPath);
    } catch (_error) {
      if (_error instanceof OriginalInkPathDeferredError) {
        return { deferredReason: _error.deferredReason };
      }
      return { deferredReason: 'MALFORMED_MODIFY_INK_PAYLOAD' };
    }

    const planned: PlannedReplacement[] = [];
    const affectedPages: Map<string, StoredInkTarget> = new Map<string, StoredInkTarget>();
    for (const ink of payload.inks) {
      const target: StoredInkTarget | null = await this.readTarget(store, operation.noteId, ink);
      if (target === null) {
        return { deferredReason: 'MODIFY_INK_TARGET_MISSING_OR_UNBOUND' };
      }
      const state: StoredInkState | null = await this.readState(store, operation.noteId, ink);
      if (state === null) {
        return { deferredReason: 'MODIFY_INK_BASE_STATE_MISSING' };
      }
      if (compareOperationIdentity(operation, state.winner) <= 0) {
        continue;
      }
      const stroke: StrokeElementData | null = await this.readStroke(store, operation.noteId, target);
      if (stroke === null || !isSupportedOriginalStoredStroke(stroke)) {
        return { deferredReason: 'MODIFY_INK_STROKE_DIVERGED' };
      }
      if (stroke.renderSpec.isPencil || stroke.splatPoints.length > 0) {
        return { deferredReason: 'MODIFY_INK_PENCIL_UNSUPPORTED' };
      }
      if (stroke.renderSpec.inkStyle === InkStyle.VARIABLE_WIDTH && !decodedPath.attributed) {
        return { deferredReason: 'MODIFY_INK_VARIABLE_PATH_ATTRIBUTES_MISSING' };
      }
      const appends: OriginalInkAppendRecord[] = await this.readAppends(
        store, operation.noteId, ink);
      let expected: RebuiltOriginalInkGeometry;
      let replacement: RebuiltOriginalInkGeometry;
      try {
        expected = rebuildOriginalInkGeometry(state.basePath, appends, stroke);
        replacement = rebuildOriginalInkGeometry(payload.centerPath, appends, stroke);
      } catch (_error) {
        return { deferredReason: 'MODIFY_INK_TRACKED_STATE_INVALID' };
      }
      if (!originalInkGeometryMatches(stroke, expected)) {
        return { deferredReason: 'MODIFY_INK_STROKE_DIVERGED' };
      }
      if (target.revision >= Number.MAX_SAFE_INTEGER) {
        return { deferredReason: 'MODIFY_INK_PAGE_REVISION_EXHAUSTED' };
      }
      planned.push({ target: target, state: state, stroke: stroke, geometry: replacement });
      affectedPages.set(pageKey(target), target);
    }

    for (const replacement of planned) {
      await this.updateState(store, operation.noteId, replacement.target.ink,
        replacement.state.winner, operation, payload.centerPath);
      await this.updateStroke(store, operation.noteId, replacement);
    }
    for (const target of affectedPages.values()) {
      await this.advanceRevisionAndInvalidateSearch(store, operation.noteId, target);
    }
    return { deferredReason: null };
  }

  private async readTarget(store: relationalStore.RdbStore, noteId: string,
    ink: OperationIdentity): Promise<StoredInkTarget | null> {
    const rows = await store.querySql(
      `SELECT element.kind, element.page_timestamp, element.page_site_id, element.page_index,
              identity.page_id, identity.visible
       FROM original_element_z_index element
       JOIN original_page_identity identity ON identity.note_id = element.note_id
        AND identity.seq_timestamp = element.page_timestamp
        AND identity.seq_site_id = element.page_site_id AND identity.seq_index = element.page_index
       WHERE element.note_id = ? AND element.element_timestamp = ? AND element.element_site_id = ?`,
      [noteId, ink.timestamp, ink.siteId]);
    let page: OriginalSequenceIdentity;
    let pageId: string;
    try {
      if (!rows.goToFirstRow() || rows.getLong(rows.getColumnIndex('kind')) !== PageElementKind.STROKE ||
        rows.getLong(rows.getColumnIndex('visible')) !== 1 ||
        rows.isColumnNull(rows.getColumnIndex('page_id'))) {
        return null;
      }
      page = {
        timestamp: rows.getLong(rows.getColumnIndex('page_timestamp')),
        siteId: rows.getLong(rows.getColumnIndex('page_site_id')),
        index: rows.getLong(rows.getColumnIndex('page_index')),
      };
      pageId = rows.getString(rows.getColumnIndex('page_id'));
    } finally {
      rows.close();
    }
    validateOriginalSequenceIdentity(page);
    const liveRevision: number | null = await readSingleRevision(store,
      'SELECT content_revision FROM page_info WHERE note_id = ? AND page_id = ?', [noteId, pageId]);
    const archivedRevision: number | null = await readSingleRevision(store,
      `SELECT content_revision FROM original_deleted_page WHERE note_id = ?
       AND page_timestamp = ? AND page_site_id = ? AND page_index = ?`,
      [noteId, page.timestamp, page.siteId, page.index]);
    if ((liveRevision === null) === (archivedRevision === null)) {
      return null;
    }
    return liveRevision !== null ? {
      ink: ink, page: page, pageId: pageId, table: 'page_element_snapshot',
      revisionTable: 'page_info', revision: liveRevision, archived: false,
    } : {
      ink: ink, page: page, pageId: pageId, table: 'original_deleted_page_element',
      revisionTable: 'original_deleted_page', revision: archivedRevision as number, archived: true,
    };
  }

  private async readState(store: relationalStore.RdbStore, noteId: string,
    ink: OperationIdentity): Promise<StoredInkState | null> {
    const rows = await store.querySql(
      `SELECT base_center_path, center_path_winner_timestamp, center_path_winner_site_id
       FROM original_ink_state WHERE note_id = ? AND ink_timestamp = ? AND ink_site_id = ?`,
      [noteId, ink.timestamp, ink.siteId]);
    try {
      if (!rows.goToFirstRow()) {
        return null;
      }
      const winner: OperationIdentity = {
        timestamp: rows.getLong(rows.getColumnIndex('center_path_winner_timestamp')),
        siteId: rows.getLong(rows.getColumnIndex('center_path_winner_site_id')),
      };
      validateOperationIdentity(winner);
      return { basePath: rows.getBlob(rows.getColumnIndex('base_center_path')), winner: winner };
    } finally {
      rows.close();
    }
  }

  private async readAppends(store: relationalStore.RdbStore, noteId: string,
    ink: OperationIdentity): Promise<OriginalInkAppendRecord[]> {
    const rows = await store.querySql(
      `SELECT append_timestamp, append_site_id, center_path_elements
       FROM original_ink_path_append WHERE note_id = ? AND ink_timestamp = ? AND ink_site_id = ?`,
      [noteId, ink.timestamp, ink.siteId]);
    const result: OriginalInkAppendRecord[] = [];
    try {
      while (rows.goToNextRow()) {
        const append: OriginalInkAppendRecord = {
          timestamp: rows.getLong(rows.getColumnIndex('append_timestamp')),
          siteId: rows.getLong(rows.getColumnIndex('append_site_id')),
          bytes: rows.getBlob(rows.getColumnIndex('center_path_elements')),
        };
        validateOperationIdentity(append);
        result.push(append);
      }
    } finally {
      rows.close();
    }
    return result;
  }

  private async readStroke(store: relationalStore.RdbStore, noteId: string,
    target: StoredInkTarget): Promise<StrokeElementData | null> {
    const elementId: string = encodeOperationId(target.ink);
    const rows = target.archived ? await store.querySql(
      `SELECT payload FROM original_deleted_page_element WHERE note_id = ?
       AND page_timestamp = ? AND page_site_id = ? AND page_index = ?
       AND element_id = ? AND kind = ?`,
      [noteId, target.page.timestamp, target.page.siteId, target.page.index,
        elementId, PageElementKind.STROKE]) : await store.querySql(
      `SELECT payload FROM page_element_snapshot WHERE note_id = ? AND page_id = ?
       AND element_id = ? AND kind = ?`,
      [noteId, target.pageId, elementId, PageElementKind.STROKE]);
    try {
      if (!rows.goToFirstRow()) {
        return null;
      }
      const persisted: PersistedElement = decodePersistedElement(
        rows.getBlob(rows.getColumnIndex('payload')));
      return persisted.kind === 'stroke' ? persisted.data as StrokeElementData : null;
    } catch (_error) {
      return null;
    } finally {
      rows.close();
    }
  }

  private async updateState(store: relationalStore.RdbStore, noteId: string,
    ink: OperationIdentity, oldWinner: OperationIdentity, winner: OperationIdentity,
    basePath: Uint8Array): Promise<void> {
    const predicates = new relationalStore.RdbPredicates('original_ink_state');
    predicates.equalTo('note_id', noteId);
    predicates.equalTo('ink_timestamp', ink.timestamp);
    predicates.equalTo('ink_site_id', ink.siteId);
    predicates.equalTo('center_path_winner_timestamp', oldWinner.timestamp);
    predicates.equalTo('center_path_winner_site_id', oldWinner.siteId);
    const updated: number = await store.update({
      'base_center_path': basePath,
      'center_path_winner_timestamp': winner.timestamp,
      'center_path_winner_site_id': winner.siteId,
    }, predicates);
    if (updated !== 1) {
      throw new Error('original modify-ink center-path winner changed concurrently');
    }
  }

  private async updateStroke(store: relationalStore.RdbStore, noteId: string,
    replacement: PlannedReplacement): Promise<void> {
    const target: StoredInkTarget = replacement.target;
    const stroke: StrokeElementData = replacement.stroke;
    const updatedStroke: StrokeElementData = {
      id: stroke.id,
      pathPoints: replacement.geometry.pathPoints,
      cubicSegments: replacement.geometry.cubicSegments,
      splatPoints: stroke.splatPoints,
      renderSpec: stroke.renderSpec,
      transform: stroke.transform,
      bounds: replacement.geometry.bounds,
      maskPath: stroke.maskPath,
      isFinished: stroke.isFinished,
    };
    const predicates = elementPredicates(noteId, target, stroke.id);
    const persisted: PersistedElement = { kind: 'stroke', data: updatedStroke };
    const updated: number = await store.update({
      'payload': encodePersistedElement(persisted), 'revision': target.revision + 1,
    }, predicates);
    if (updated !== 1) {
      throw new Error('original modify-ink lost its target stroke');
    }
  }

  private async advanceRevisionAndInvalidateSearch(store: relationalStore.RdbStore,
    noteId: string, target: StoredInkTarget): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(target.revisionTable);
    predicates.equalTo('note_id', noteId);
    if (target.archived) {
      predicates.equalTo('page_timestamp', target.page.timestamp);
      predicates.equalTo('page_site_id', target.page.siteId);
      predicates.equalTo('page_index', target.page.index);
    } else {
      predicates.equalTo('page_id', target.pageId);
    }
    predicates.equalTo('content_revision', target.revision);
    const values: relationalStore.ValuesBucket = { 'content_revision': target.revision + 1 };
    if (target.archived) {
      values['indexed_revision'] = null;
    }
    const updated: number = await store.update(values, predicates);
    if (updated !== 1) {
      throw new Error('original modify-ink page revision changed concurrently');
    }
    if (target.archived) {
      await store.executeSql(
        `DELETE FROM original_deleted_page_search WHERE note_id = ? AND page_timestamp = ?
         AND page_site_id = ? AND page_index = ? AND type = ?`,
        [noteId, target.page.timestamp, target.page.siteId, target.page.index, SearchItemType.INK]);
    } else {
      await store.executeSql('DELETE FROM search_page_state WHERE note_id = ? AND page_id = ?',
        [noteId, target.pageId]);
      await store.executeSql(
        'DELETE FROM search_item WHERE note_id = ? AND page_id = ? AND type = ?',
        [noteId, target.pageId, SearchItemType.INK]);
    }
  }
}

function elementPredicates(noteId: string, target: StoredInkTarget,
  elementId: string): relationalStore.RdbPredicates {
  const predicates = new relationalStore.RdbPredicates(target.table);
  predicates.equalTo('note_id', noteId);
  if (target.archived) {
    predicates.equalTo('page_timestamp', target.page.timestamp);
    predicates.equalTo('page_site_id', target.page.siteId);
    predicates.equalTo('page_index', target.page.index);
  } else {
    predicates.equalTo('page_id', target.pageId);
  }
  predicates.equalTo('element_id', elementId);
  predicates.equalTo('kind', PageElementKind.STROKE);
  return predicates;
}

function pageKey(target: StoredInkTarget): string {
  return target.archived ?
    `archive:${target.page.timestamp}:${target.page.siteId}:${target.page.index}` :
    `live:${target.pageId}`;
}

async function readSingleRevision(store: relationalStore.RdbStore, sql: string,
  args: relationalStore.ValueType[]): Promise<number | null> {
  const rows = await store.querySql(sql, args);
  try {
    if (!rows.goToFirstRow()) {
      return null;
    }
    const revision: number = rows.getLong(rows.getColumnIndex('content_revision'));
    if (!Number.isSafeInteger(revision) || revision < 0) {
      throw new Error('original target page has an invalid revision');
    }
    return revision;
  } finally {
    rows.close();
  }
}
