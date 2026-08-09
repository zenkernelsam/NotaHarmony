import { relationalStore } from '@kit.ArkData';
import {
  compareOriginalSequenceIdentity, encodeOriginalSequenceId, OperationIdentity,
  OriginalSequenceIdentity, validateOriginalSequenceIdentity,
} from './OperationIdentity';

const MAX_ORIGINAL_PAGE_GROUP_COUNT: number = 10000;

interface PositionRow {
  position: OriginalSequenceIdentity;
  pageId: string | null;
  bound: boolean;
  active: boolean;
  deleted: boolean;
}

interface PositionGroup {
  operation: OriginalSequenceIdentity;
  parent: OriginalSequenceIdentity | null;
  count: number;
  positions: PositionRow[];
}

export class OriginalPageOrderStore {
  async readStoredPageIds(store: relationalStore.RdbStore, noteId: string): Promise<string[]> {
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

  async readOriginalVisibleOrder(store: relationalStore.RdbStore, noteId: string): Promise<string[]> {
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
          timestamp: operation.timestamp,
          siteId: operation.siteId,
          index: rows.getLong(rows.getColumnIndex('pos_index')),
        };
        const pageIdColumn: number = rows.getColumnIndex('page_id');
        group.positions.push({
          position: position,
          pageId: rows.isColumnNull(pageIdColumn) ? null : rows.getString(pageIdColumn),
          bound: rows.getLong(rows.getColumnIndex('visible')) === 1,
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

  samePageIds(left: string[], right: string[]): boolean {
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

  async assignTemporaryIndexes(store: relationalStore.RdbStore,
    noteId: string, pageIds: string[]): Promise<void> {
    for (let index: number = 0; index < pageIds.length; index++) {
      await this.updatePageIndex(store, noteId, pageIds[index], -(index + 1));
    }
  }

  async assignFinalIndexes(store: relationalStore.RdbStore,
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

  async advanceStructureRevision(store: relationalStore.RdbStore,
    noteId: string, operationName: string): Promise<void> {
    const rows = await store.querySql('SELECT structure_revision FROM note_meta WHERE id = ?', [noteId]);
    let revision: number;
    try {
      if (!rows.goToFirstRow()) {
        throw new Error(`original ${operationName} note does not exist`);
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
      throw new Error(`note structure revision changed while applying original ${operationName}`);
    }
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
        if (position.active && position.bound && !position.deleted) {
          if (position.pageId === null) {
            throw new Error('visible original page position has no storage page');
          }
          result.push(position.pageId);
        }
        // A deleted position remains a valid anchor for later insert and move groups.
        this.appendChildren(encodeOriginalSequenceId(position.position), children, visited, result);
      }
    }
  }

  private validateGroup(group: PositionGroup): void {
    validateOriginalSequenceIdentity(group.operation);
    if (!Number.isSafeInteger(group.count) || group.count < 1 ||
      group.count > MAX_ORIGINAL_PAGE_GROUP_COUNT || group.positions.length !== group.count) {
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
        position.bound !== (position.pageId !== null)) {
        throw new Error('stored original page position is invalid');
      }
    }
  }

  private operationKey(identity: OperationIdentity): string {
    return `${identity.timestamp.toString(16)}:${identity.siteId.toString(16)}`;
  }

  private async updatePageIndex(store: relationalStore.RdbStore,
    noteId: string, pageId: string, pageIndex: number): Promise<void> {
    const predicates = new relationalStore.RdbPredicates('page_info');
    predicates.equalTo('note_id', noteId);
    predicates.equalTo('page_id', pageId);
    const updated: number = await store.update({ 'page_index': pageIndex }, predicates);
    if (updated !== 1) {
      throw new Error(`original page index update affected ${updated} rows`);
    }
  }
}
