import { relationalStore } from '@kit.ArkData';
import {
  compareOperationIdentity, compareOriginalSequenceIdentity, encodeOriginalSequenceId,
  OperationIdentity, OriginalSequenceIdentity, validateOriginalSequenceIdentity,
} from './OperationIdentity';
import {
  OriginalFlatBufferTableReader, readOriginalPayloadTable,
} from './OriginalSyncedOperationFlatBuffer';
import {
  StoredSyncedOperation, SyncedOperationApplier, SyncedOperationApplyResult,
} from './SyncedOperationInbox';
import { OriginalPageOrderStore } from './OriginalPageOrderStore';
import { serializePageBackground } from '../core/model/PageBackgroundModel';
import {
  decodeOriginalPageBackgroundTable, OriginalDecodedPageBackground,
  originalPageBackgroundFitsHarmony,
} from './OriginalPageBackgroundOperation';
import { readEffectiveNoteBackground } from './OriginalSetMetadataOperation';
import {
  mergeOriginalAssetReference, OriginalAssetReferenceConflict,
} from './OriginalAssetReferenceStore';
import { applyOriginalPageInAsset } from './OriginalPageInAssetState';

export const ORIGINAL_MODIFY_PAGE_PAYLOAD_TYPE: number = 4;
export const MAX_ORIGINAL_MODIFY_PAGE_COUNT: number = 10000;

export interface OriginalModifyPagePayload {
  pages: OriginalSequenceIdentity[];
  hasMove: boolean;
  moveTo: OriginalSequenceIdentity | null;
  hasBackground: boolean;
  background: OriginalDecodedPageBackground | null;
  hasBookmarked: boolean;
}

interface PositionRow {
  position: OriginalSequenceIdentity;
  pageId: string | null;
  visible: boolean;
  active: boolean;
  deleted: boolean;
}

interface PositionGroup {
  operation: OriginalSequenceIdentity;
  parent: OriginalSequenceIdentity | null;
  count: number;
  positions: PositionRow[];
}

interface WinnerRow extends OperationIdentity {
  positionIndex: number;
}

export function decodeOriginalModifyPage(bytes: Uint8Array): OriginalModifyPagePayload {
  const table: OriginalFlatBufferTableReader =
    readOriginalPayloadTable(bytes, ORIGINAL_MODIFY_PAGE_PAYLOAD_TYPE);
  return decodeOriginalModifyPageTable(table);
}

export function decodeOriginalModifyPageTable(
  table: OriginalFlatBufferTableReader): OriginalModifyPagePayload {
  const rawPages: number[][] = table.readInlineSequenceVector(0, MAX_ORIGINAL_MODIFY_PAGE_COUNT);
  const pages: OriginalSequenceIdentity[] = [];
  for (const raw of rawPages) {
    const page: OriginalSequenceIdentity = {
      timestamp: raw[0], siteId: raw[1], index: raw[2],
    };
    validateOriginalSequenceIdentity(page);
    pages.push(page);
  }
  const move: OriginalFlatBufferTableReader | null = table.readTable(1);
  const rawTarget: number[] | null = move === null ? null : move.readInlineSequence(0);
  const moveTo: OriginalSequenceIdentity | null = rawTarget === null ? null : {
    timestamp: rawTarget[0], siteId: rawTarget[1], index: rawTarget[2],
  };
  if (moveTo !== null) {
    validateOriginalSequenceIdentity(moveTo);
  }
  const backgroundSetter: OriginalFlatBufferTableReader | null = table.readTable(2);
  const backgroundTable: OriginalFlatBufferTableReader | null =
    backgroundSetter === null ? null : backgroundSetter.readTable(0);
  return {
    pages: pages,
    hasMove: move !== null,
    moveTo: moveTo,
    hasBackground: backgroundSetter !== null,
    background: backgroundTable === null ? null : decodeOriginalPageBackgroundTable(backgroundTable),
    hasBookmarked: table.hasField(3),
  };
}

export class OriginalModifyPageOperationApplier implements SyncedOperationApplier {
  private orderStore: OriginalPageOrderStore = new OriginalPageOrderStore();

  supports(payloadType: number): boolean {
    return payloadType === ORIGINAL_MODIFY_PAGE_PAYLOAD_TYPE;
  }

  async apply(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation): Promise<SyncedOperationApplyResult> {
    let payload: OriginalModifyPagePayload;
    try {
      payload = decodeOriginalModifyPage(operation.rawOperation);
    } catch (_error) {
      return { deferredReason: 'MALFORMED_MODIFY_PAGE_PAYLOAD' };
    }
    if (payload.pages.length < 1) {
      return { deferredReason: 'MODIFY_PAGE_HAS_NO_PAGES' };
    }
    if (payload.background !== null && !originalPageBackgroundFitsHarmony(payload.background)) {
      return { deferredReason: 'MODIFY_PAGE_BACKGROUND_SIZE_UNSUPPORTED' };
    }
    if (payload.background !== null && payload.background.background.pdf !== undefined &&
      payload.background.background.pdf !== null &&
      payload.background.background.pdf.pagesConsumed !== payload.pages.length) {
      return { deferredReason: 'MODIFY_PAGE_PDF_PAGE_COUNT_MISMATCH' };
    }
    if (payload.hasBookmarked) {
      return { deferredReason: 'MODIFY_PAGE_BOOKMARK_UNSUPPORTED' };
    }
    if (this.hasRepeatedPage(payload.pages)) {
      return { deferredReason: 'MODIFY_PAGE_REPEATS_PAGE' };
    }
    if (payload.hasMove && await this.groupExists(store, operation.noteId, operation)) {
      throw new Error('original modify-page operation was applied twice');
    }
    for (const page of payload.pages) {
      if (!await this.pageIdentityExists(store, operation.noteId, page)) {
        return { deferredReason: 'MODIFY_PAGE_PAGE_MISSING' };
      }
    }
    if (payload.moveTo !== null &&
      !await this.positionExists(store, operation.noteId, payload.moveTo)) {
      return { deferredReason: 'MODIFY_PAGE_TARGET_MISSING' };
    }
    const assetReason: string | null = await this.mergePdfAsset(store, operation.noteId, payload.background);
    if (assetReason !== null) {
      return { deferredReason: assetReason };
    }

    let changed: boolean = false;
    if (payload.hasMove) {
      const storedOrder: string[] = await this.orderStore.readStoredPageIds(store, operation.noteId);
      const originalOrder: string[] = await this.orderStore.readOriginalVisibleOrder(store, operation.noteId);
      if (!this.orderStore.samePageIds(storedOrder, originalOrder)) {
        return { deferredReason: 'ORIGINAL_PAGE_ORDER_DIVERGED' };
      }
      await this.insertPositionGroup(store, operation, payload);
      await this.insertPositionsAndUpdateWinners(store, operation, payload.pages);
      const newOrder: string[] = await this.orderStore.readOriginalVisibleOrder(store, operation.noteId);
      if (newOrder.length !== storedOrder.length) {
        throw new Error('original page move changed the visible page set');
      }
      await this.orderStore.assignTemporaryIndexes(store, operation.noteId, storedOrder);
      await this.orderStore.assignFinalIndexes(store, operation.noteId, newOrder);
      changed = true;
    }
    if (payload.hasBackground &&
      await this.applyBackground(store, operation, payload.pages, payload.background)) {
      changed = true;
    }
    if (payload.hasBackground && payload.background !== null &&
      payload.background.background.pdf !== undefined && payload.background.background.pdf !== null) {
      const offset: number = payload.background.background.pdf.pageOffset;
      for (let index: number = 0; index < payload.pages.length; index++) {
        if (await applyOriginalPageInAsset(store, operation, payload.pages[index], offset + index)) {
          changed = true;
        }
      }
    }
    if (changed) {
      await this.orderStore.advanceStructureRevision(store, operation.noteId, 'modify-page');
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
      return 'MODIFY_PAGE_PDF_ASSET_METADATA_CONFLICT';
    }
    if (conflict === OriginalAssetReferenceConflict.LOCAL_PATH) {
      return 'MODIFY_PAGE_PDF_ASSET_PATH_CONFLICT';
    }
    return null;
  }

  private async applyBackground(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation, pages: OriginalSequenceIdentity[],
    background: OriginalDecodedPageBackground | null): Promise<boolean> {
    let changed: boolean = false;
    for (const page of pages) {
      const winner: OperationIdentity | null =
        await this.readBackgroundWinner(store, operation.noteId, page);
      // fqb.c in 1.0.3 replaces a Register only when the incoming Op ID is strictly greater.
      if (winner !== null && compareOperationIdentity(operation, winner) <= 0) {
        continue;
      }
      await this.writeBackgroundWinner(store, operation, page, background, winner);
      await this.updateMaterializedBackground(store, operation.noteId, page, background);
      changed = true;
    }
    return changed;
  }

  private async readBackgroundWinner(store: relationalStore.RdbStore, noteId: string,
    page: OriginalSequenceIdentity): Promise<OperationIdentity | null> {
    const rows = await store.querySql(
      `SELECT winner_timestamp, winner_site_id FROM original_page_background_winner
       WHERE note_id = ? AND page_timestamp = ? AND page_site_id = ? AND page_index = ?`,
      [noteId, page.timestamp, page.siteId, page.index]);
    try {
      if (!rows.goToFirstRow()) {
        return null;
      }
      return {
        timestamp: rows.getLong(rows.getColumnIndex('winner_timestamp')),
        siteId: rows.getLong(rows.getColumnIndex('winner_site_id')),
      };
    } finally {
      rows.close();
    }
  }

  private async writeBackgroundWinner(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation, page: OriginalSequenceIdentity,
    background: OriginalDecodedPageBackground | null, previous: OperationIdentity | null): Promise<void> {
    const values: relationalStore.ValuesBucket = {
      'note_id': operation.noteId,
      'page_timestamp': page.timestamp,
      'page_site_id': page.siteId,
      'page_index': page.index,
      'winner_timestamp': operation.timestamp,
      'winner_site_id': operation.siteId,
      'size': background === null ? null : background.size,
      'template': background === null ? null : background.template,
      'orientation': background === null ? null : background.orientation,
      'width_mm': background === null ? null : background.widthMm,
      'height_mm': background === null ? null : background.heightMm,
      'background_json': background === null ? null : serializePageBackground(background.background),
    };
    if (previous === null) {
      await store.insert('original_page_background_winner', values);
      return;
    }
    const predicates = new relationalStore.RdbPredicates('original_page_background_winner');
    predicates.equalTo('note_id', operation.noteId);
    predicates.equalTo('page_timestamp', page.timestamp);
    predicates.equalTo('page_site_id', page.siteId);
    predicates.equalTo('page_index', page.index);
    predicates.equalTo('winner_timestamp', previous.timestamp);
    predicates.equalTo('winner_site_id', previous.siteId);
    const updated: number = await store.update(values, predicates);
    if (updated !== 1) {
      throw new Error('original page background winner changed concurrently');
    }
  }

  private async updateMaterializedBackground(store: relationalStore.RdbStore, noteId: string,
    page: OriginalSequenceIdentity, background: OriginalDecodedPageBackground | null): Promise<void> {
    const rows = await store.querySql(
      `SELECT page_id FROM original_page_identity
       WHERE note_id = ? AND seq_timestamp = ? AND seq_site_id = ? AND seq_index = ?`,
      [noteId, page.timestamp, page.siteId, page.index]);
    let pageId: string | null;
    try {
      if (!rows.goToFirstRow()) {
        throw new Error('original background page identity is missing');
      }
      const column: number = rows.getColumnIndex('page_id');
      pageId = rows.isColumnNull(column) ? null : rows.getString(column);
    } finally {
      rows.close();
    }
    if (pageId === null) {
      return;
    }
    const materialized: OriginalDecodedPageBackground = background === null
      ? await readEffectiveNoteBackground(store, noteId) : background;
    const values: relationalStore.ValuesBucket = {
      'size': materialized.size,
      'template': materialized.template,
      'orientation': materialized.orientation,
      'width_mm': materialized.widthMm,
      'height_mm': materialized.heightMm,
      'background_json': background === null ? null : serializePageBackground(background.background),
    };
    const live = new relationalStore.RdbPredicates('page_info');
    live.equalTo('note_id', noteId);
    live.equalTo('page_id', pageId);
    const liveUpdated: number = await store.update(values, live);
    if (liveUpdated === 1) {
      return;
    }
    if (liveUpdated !== 0) {
      throw new Error(`original background updated ${liveUpdated} live pages`);
    }
    const archived = new relationalStore.RdbPredicates('original_deleted_page');
    archived.equalTo('note_id', noteId);
    archived.equalTo('page_timestamp', page.timestamp);
    archived.equalTo('page_site_id', page.siteId);
    archived.equalTo('page_index', page.index);
    const archivedUpdated: number = await store.update(values, archived);
    if (archivedUpdated !== 1) {
      throw new Error(`original background updated ${archivedUpdated} archived pages`);
    }
  }

  private hasRepeatedPage(pages: OriginalSequenceIdentity[]): boolean {
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

  private async groupExists(store: relationalStore.RdbStore, noteId: string,
    operation: OperationIdentity): Promise<boolean> {
    return this.rowExists(store,
      `SELECT 1 FROM original_page_position_group
       WHERE note_id = ? AND op_timestamp = ? AND op_site_id = ? LIMIT 1`,
      [noteId, operation.timestamp, operation.siteId]);
  }

  private async pageIdentityExists(store: relationalStore.RdbStore, noteId: string,
    page: OriginalSequenceIdentity): Promise<boolean> {
    return this.rowExists(store,
      `SELECT 1 FROM original_page_identity
       WHERE note_id = ? AND seq_timestamp = ? AND seq_site_id = ? AND seq_index = ? LIMIT 1`,
      [noteId, page.timestamp, page.siteId, page.index]);
  }

  private async positionExists(store: relationalStore.RdbStore, noteId: string,
    position: OriginalSequenceIdentity): Promise<boolean> {
    return this.rowExists(store,
      `SELECT 1 FROM original_page_position
       WHERE note_id = ? AND pos_timestamp = ? AND pos_site_id = ? AND pos_index = ? LIMIT 1`,
      [noteId, position.timestamp, position.siteId, position.index]);
  }

  private async rowExists(store: relationalStore.RdbStore, sql: string,
    args: relationalStore.ValueType[]): Promise<boolean> {
    const rows = await store.querySql(sql, args);
    try {
      return rows.goToFirstRow();
    } finally {
      rows.close();
    }
  }

  private async insertPositionGroup(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation, payload: OriginalModifyPagePayload): Promise<void> {
    const values: relationalStore.ValuesBucket = {
      'note_id': operation.noteId,
      'op_timestamp': operation.timestamp,
      'op_site_id': operation.siteId,
      'position_count': payload.pages.length,
      'modified_time': operation.serverTime,
    };
    if (payload.moveTo !== null) {
      values['parent_timestamp'] = payload.moveTo.timestamp;
      values['parent_site_id'] = payload.moveTo.siteId;
      values['parent_index'] = payload.moveTo.index;
    }
    await store.insert('original_page_position_group', values);
  }

  private async insertPositionsAndUpdateWinners(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation, pages: OriginalSequenceIdentity[]): Promise<void> {
    for (let index: number = 0; index < pages.length; index++) {
      const page: OriginalSequenceIdentity = pages[index];
      await store.insert('original_page_position', {
        'note_id': operation.noteId,
        'pos_timestamp': operation.timestamp,
        'pos_site_id': operation.siteId,
        'pos_index': index,
        'page_timestamp': page.timestamp,
        'page_site_id': page.siteId,
        'page_index': page.index,
      });
      const winner: WinnerRow = await this.readWinner(store, operation.noteId, page);
      if (compareOperationIdentity(operation, winner) >= 0) {
        const predicates = new relationalStore.RdbPredicates('original_page_position_winner');
        predicates.equalTo('note_id', operation.noteId);
        predicates.equalTo('page_timestamp', page.timestamp);
        predicates.equalTo('page_site_id', page.siteId);
        predicates.equalTo('page_index', page.index);
        predicates.equalTo('winner_timestamp', winner.timestamp);
        predicates.equalTo('winner_site_id', winner.siteId);
        predicates.equalTo('position_index', winner.positionIndex);
        const updated: number = await store.update({
          'winner_timestamp': operation.timestamp,
          'winner_site_id': operation.siteId,
          'position_index': index,
        }, predicates);
        if (updated !== 1) {
          throw new Error('original page position winner changed concurrently');
        }
      }
    }
  }

  private async readWinner(store: relationalStore.RdbStore, noteId: string,
    page: OriginalSequenceIdentity): Promise<WinnerRow> {
    const rows = await store.querySql(
      `SELECT winner_timestamp, winner_site_id, position_index
       FROM original_page_position_winner
       WHERE note_id = ? AND page_timestamp = ? AND page_site_id = ? AND page_index = ?`,
      [noteId, page.timestamp, page.siteId, page.index]);
    try {
      if (!rows.goToFirstRow()) {
        throw new Error('original page has no position winner');
      }
      return {
        timestamp: rows.getLong(rows.getColumnIndex('winner_timestamp')),
        siteId: rows.getLong(rows.getColumnIndex('winner_site_id')),
        positionIndex: rows.getLong(rows.getColumnIndex('position_index')),
      };
    } finally {
      rows.close();
    }
  }

  private async readStoredPageIds(store: relationalStore.RdbStore, noteId: string): Promise<string[]> {
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

  private async readOriginalVisibleOrder(store: relationalStore.RdbStore,
    noteId: string): Promise<string[]> {
    const rows = await store.querySql(
      `SELECT groups.op_timestamp, groups.op_site_id, groups.parent_timestamp,
        groups.parent_site_id, groups.parent_index, groups.position_count,
        positions.pos_index, pages.page_id, pages.visible,
        winners.winner_timestamp, winners.winner_site_id, winners.position_index,
        COALESCE(visibility.deleted, 0) AS deleted
       FROM original_page_position_group groups
       JOIN original_page_position positions ON positions.note_id = groups.note_id
        AND positions.pos_timestamp = groups.op_timestamp
        AND positions.pos_site_id = groups.op_site_id
       JOIN original_page_identity pages ON pages.note_id = positions.note_id
        AND pages.seq_timestamp = positions.page_timestamp
        AND pages.seq_site_id = positions.page_site_id
        AND pages.seq_index = positions.page_index
       JOIN original_page_position_winner winners ON winners.note_id = positions.note_id
        AND winners.page_timestamp = positions.page_timestamp
        AND winners.page_site_id = positions.page_site_id
        AND winners.page_index = positions.page_index
       LEFT JOIN original_page_visibility_winner visibility ON visibility.note_id = positions.note_id
        AND visibility.page_timestamp = positions.page_timestamp
        AND visibility.page_site_id = positions.page_site_id
        AND visibility.page_index = positions.page_index
       WHERE groups.note_id = ?
       ORDER BY groups.op_timestamp, groups.op_site_id, positions.pos_index`, [noteId]);
    const groups: Map<string, PositionGroup> = new Map<string, PositionGroup>();
    try {
      while (rows.goToNextRow()) {
        const operation: OriginalSequenceIdentity = {
          timestamp: rows.getLong(rows.getColumnIndex('op_timestamp')),
          siteId: rows.getLong(rows.getColumnIndex('op_site_id')),
          index: 0,
        };
        const key: string = this.operationKey(operation);
        let group: PositionGroup | undefined = groups.get(key);
        if (group === undefined) {
          const parentColumn: number = rows.getColumnIndex('parent_timestamp');
          group = {
            operation: operation,
            parent: rows.isColumnNull(parentColumn) ? null : {
              timestamp: rows.getLong(parentColumn),
              siteId: rows.getLong(rows.getColumnIndex('parent_site_id')),
              index: rows.getLong(rows.getColumnIndex('parent_index')),
            },
            count: rows.getLong(rows.getColumnIndex('position_count')),
            positions: [],
          };
          groups.set(key, group);
        }
        const position: OriginalSequenceIdentity = {
          timestamp: operation.timestamp, siteId: operation.siteId,
          index: rows.getLong(rows.getColumnIndex('pos_index')),
        };
        const pageIdColumn: number = rows.getColumnIndex('page_id');
        group.positions.push({
          position: position,
          pageId: rows.isColumnNull(pageIdColumn) ? null : rows.getString(pageIdColumn),
          visible: rows.getLong(rows.getColumnIndex('visible')) === 1,
          active: rows.getLong(rows.getColumnIndex('winner_timestamp')) === position.timestamp &&
            rows.getLong(rows.getColumnIndex('winner_site_id')) === position.siteId &&
            rows.getLong(rows.getColumnIndex('position_index')) === position.index,
          deleted: rows.getLong(rows.getColumnIndex('deleted')) === 1,
        });
      }
    } finally {
      rows.close();
    }
    return this.flatten(groups);
  }

  private flatten(groups: Map<string, PositionGroup>): string[] {
    const children: Map<string, PositionGroup[]> = new Map<string, PositionGroup[]>();
    groups.forEach((group: PositionGroup): void => {
      this.validateGroup(group);
      const parentKey: string = group.parent === null ? 'ROOT' : encodeOriginalSequenceId(group.parent);
      const siblings: PositionGroup[] | undefined = children.get(parentKey);
      if (siblings === undefined) {
        children.set(parentKey, [group]);
      } else {
        siblings.push(group);
      }
    });
    children.forEach((siblings: PositionGroup[]): void => {
      siblings.sort((left: PositionGroup, right: PositionGroup): number =>
        -compareOriginalSequenceIdentity(left.positions[left.positions.length - 1].position,
          right.positions[right.positions.length - 1].position));
    });
    const result: string[] = [];
    const visited: Set<string> = new Set<string>();
    this.appendChildren('ROOT', children, visited, result);
    if (visited.size !== groups.size) {
      throw new Error('original page positions contain an orphan or cycle');
    }
    return result;
  }

  private appendChildren(parentKey: string, children: Map<string, PositionGroup[]>,
    visited: Set<string>, result: string[]): void {
    const groups: PositionGroup[] | undefined = children.get(parentKey);
    if (groups === undefined) {
      return;
    }
    for (const group of groups) {
      const key: string = this.operationKey(group.operation);
      if (visited.has(key)) {
        throw new Error('original page positions contain a cycle');
      }
      visited.add(key);
      for (const position of group.positions) {
        if (position.active && position.visible && !position.deleted) {
          if (position.pageId === null) {
            throw new Error('visible original page position has no storage page');
          }
          result.push(position.pageId);
        }
        this.appendChildren(encodeOriginalSequenceId(position.position), children, visited, result);
      }
    }
  }

  private validateGroup(group: PositionGroup): void {
    validateOriginalSequenceIdentity(group.operation);
    if (!Number.isSafeInteger(group.count) || group.count < 1 ||
      group.count > MAX_ORIGINAL_MODIFY_PAGE_COUNT || group.positions.length !== group.count) {
      throw new Error('stored original page position group is incomplete');
    }
    if (group.parent !== null) {
      validateOriginalSequenceIdentity(group.parent);
    }
    for (let index: number = 0; index < group.positions.length; index++) {
      const position: PositionRow = group.positions[index];
      validateOriginalSequenceIdentity(position.position);
      if (position.position.timestamp !== group.operation.timestamp ||
        position.position.siteId !== group.operation.siteId || position.position.index !== index ||
        position.visible !== (position.pageId !== null)) {
        throw new Error('stored original page position is invalid');
      }
    }
  }

  private operationKey(identity: OperationIdentity): string {
    return `${identity.timestamp.toString(16)}:${identity.siteId.toString(16)}`;
  }

  private sameStrings(left: string[], right: string[]): boolean {
    if (left.length !== right.length) {
      return false;
    }
    for (let index: number = 0; index < left.length; index++) {
      if (left[index] !== right[index]) {
        return false;
      }
    }
    return true;
  }

  private async assignTemporaryIndexes(store: relationalStore.RdbStore,
    noteId: string, pageIds: string[]): Promise<void> {
    for (let index: number = 0; index < pageIds.length; index++) {
      await this.updatePageIndex(store, noteId, pageIds[index], -(index + 1));
    }
  }

  private async assignFinalIndexes(store: relationalStore.RdbStore,
    noteId: string, pageIds: string[]): Promise<void> {
    const seen: Set<string> = new Set<string>();
    for (let index: number = 0; index < pageIds.length; index++) {
      if (seen.has(pageIds[index])) {
        throw new Error('original page positions materialized a page twice');
      }
      seen.add(pageIds[index]);
      await this.updatePageIndex(store, noteId, pageIds[index], index);
    }
  }

  private async updatePageIndex(store: relationalStore.RdbStore, noteId: string,
    pageId: string, pageIndex: number): Promise<void> {
    const predicates = new relationalStore.RdbPredicates('page_info');
    predicates.equalTo('note_id', noteId);
    predicates.equalTo('page_id', pageId);
    const updated: number = await store.update({ 'page_index': pageIndex }, predicates);
    if (updated !== 1) {
      throw new Error(`original page index update affected ${updated} rows`);
    }
  }

  private async advanceStructureRevision(store: relationalStore.RdbStore, noteId: string): Promise<void> {
    const rows = await store.querySql('SELECT structure_revision FROM note_meta WHERE id = ?', [noteId]);
    let revision: number;
    try {
      if (!rows.goToFirstRow()) {
        throw new Error('original modify-page note does not exist');
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
    const updated: number = await store.update({ 'structure_revision': revision + 1 }, predicates);
    if (updated !== 1) {
      throw new Error('note structure revision changed while applying original modify-page');
    }
  }
}
