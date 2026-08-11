import { relationalStore } from '@kit.ArkData';
import {
  compareOperationIdentity, encodeOperationId, OperationIdentity, validateOperationIdentity,
} from './OperationIdentity';
import { compareUnsignedLongDecimal, validateUnsignedLongDecimal } from './UnsignedDecimal';

export interface OriginalLayeringEntity extends OperationIdentity {
  id: string;
  zIndex: string;
}

export interface OriginalLayeringUnit extends OperationIdentity {
  id: string;
  zIndex: string;
  group: boolean;
  entities: OriginalLayeringEntity[];
}

interface OriginalLayeringGroup extends OperationIdentity {
  id: string;
  zIndex: string | null;
  members: string[];
}

interface PersistedGroupMember {
  timestamp: number;
  siteId: number;
}

interface StoredLayeringPage extends OperationIdentity {
  index: number;
}

interface StoredLayeringPageTarget {
  page: StoredLayeringPage;
  pageId: string;
  table: string;
  revisionTable: string;
  revision: number;
  archived: boolean;
}

interface StoredLayeringPageEntity extends OriginalLayeringEntity {
  kind: number;
  order: number;
}

export async function originalGroupLayerRanks(store: relationalStore.RdbStore, noteId: string,
  entities: OriginalLayeringEntity[]): Promise<Map<string, number> | null> {
  const units: OriginalLayeringUnit[] | null =
    await originalGroupLayerUnits(store, noteId, entities);
  if (units === null) {
    return null;
  }
  const ranks: Map<string, number> = new Map<string, number>();
  for (const unit of units) {
    for (const entity of unit.entities) {
      ranks.set(entity.id, ranks.size);
    }
  }
  return ranks;
}

export async function originalGroupLayerUnits(store: relationalStore.RdbStore, noteId: string,
  entities: OriginalLayeringEntity[]): Promise<OriginalLayeringUnit[] | null> {
  const entityIds: Set<string> = new Set<string>();
  for (const entity of entities) {
    try {
      validateOperationIdentity(entity);
      validateUnsignedLongDecimal(entity.zIndex);
    } catch (_error) {
      return null;
    }
    if (entity.id !== encodeOperationId(entity) || entityIds.has(entity.id)) {
      return null;
    }
    entityIds.add(entity.id);
  }
  const groups: OriginalLayeringGroup[] | null = await readActiveGroups(store, noteId);
  if (groups === null) {
    return null;
  }
  const parentByMember: Map<string, OriginalLayeringGroup> =
    new Map<string, OriginalLayeringGroup>();
  for (const group of groups) {
    for (const member of group.members) {
      const previous: OriginalLayeringGroup | undefined = parentByMember.get(member);
      if (previous === undefined || compareOperationIdentity(group, previous) > 0) {
        parentByMember.set(member, group);
      }
    }
  }
  const unitsById: Map<string, OriginalLayeringUnit> = new Map<string, OriginalLayeringUnit>();
  for (const entity of entities) {
    const group: OriginalLayeringGroup | null | false = topGroup(entity.id, parentByMember);
    if (group === false) {
      return null;
    }
    if (group !== null && group.zIndex === null) {
      return null;
    }
    const unitId: string = group === null ? entity.id : group.id;
    const existing: OriginalLayeringUnit | undefined = unitsById.get(unitId);
    if (existing === undefined) {
      unitsById.set(unitId, {
        id: unitId,
        timestamp: group === null ? entity.timestamp : group.timestamp,
        siteId: group === null ? entity.siteId : group.siteId,
        zIndex: group === null ? entity.zIndex : group.zIndex as string,
        group: group !== null,
        entities: [entity],
      });
    } else {
      existing.entities.push(entity);
    }
  }
  const units: OriginalLayeringUnit[] = Array.from(unitsById.values());
  for (const unit of units) {
    unit.entities.sort(compareLayeringEntities);
  }
  units.sort(compareLayeringUnits);
  return units;
}

export async function refreshOriginalGroupLayeredOrder(store: relationalStore.RdbStore,
  noteId: string): Promise<boolean> {
  const pages = await store.querySql(
    `SELECT DISTINCT page_timestamp, page_site_id, page_index
     FROM original_element_z_index WHERE note_id = ? AND visible = 1`, [noteId]);
  const identities: StoredLayeringPage[] = [];
  try {
    while (pages.goToNextRow()) {
      identities.push({
        timestamp: pages.getLong(pages.getColumnIndex('page_timestamp')),
        siteId: pages.getLong(pages.getColumnIndex('page_site_id')),
        index: pages.getLong(pages.getColumnIndex('page_index')),
      });
    }
  } finally {
    pages.close();
  }
  for (const page of identities) {
    if (!await refreshPageOrder(store, noteId, page)) {
      return false;
    }
  }
  return true;
}

async function refreshPageOrder(store: relationalStore.RdbStore, noteId: string,
  page: StoredLayeringPage): Promise<boolean> {
  const target: StoredLayeringPageTarget | null = await readPageTarget(store, noteId, page);
  if (target === null) {
    return false;
  }
  const tracked = await store.querySql(
    `SELECT element_timestamp, element_site_id, kind, z_index
     FROM original_element_z_index WHERE note_id = ? AND page_timestamp = ?
       AND page_site_id = ? AND page_index = ? AND visible = 1`,
    [noteId, page.timestamp, page.siteId, page.index]);
  const entities: StoredLayeringPageEntity[] = [];
  try {
    while (tracked.goToNextRow()) {
      const timestamp: number = tracked.getLong(tracked.getColumnIndex('element_timestamp'));
      const siteId: number = tracked.getLong(tracked.getColumnIndex('element_site_id'));
      entities.push({ id: encodeOperationId({ timestamp: timestamp, siteId: siteId }),
        timestamp: timestamp, siteId: siteId,
        zIndex: tracked.getString(tracked.getColumnIndex('z_index')),
        kind: tracked.getLong(tracked.getColumnIndex('kind')), order: -1 });
    }
  } finally {
    tracked.close();
  }
  const stored = target.archived ? await store.querySql(
    `SELECT element_id, kind, element_order FROM original_deleted_page_element
     WHERE note_id = ? AND page_timestamp = ? AND page_site_id = ? AND page_index = ?`,
    [noteId, page.timestamp, page.siteId, page.index]) : await store.querySql(
    `SELECT element_id, kind, element_order FROM page_element_snapshot
     WHERE note_id = ? AND page_id = ?`, [noteId, target.pageId]);
  const storedOrder: Map<string, number> = new Map<string, number>();
  try {
    while (stored.goToNextRow()) {
      const key: string = `${stored.getLong(stored.getColumnIndex('kind'))}:` +
        stored.getString(stored.getColumnIndex('element_id'));
      if (storedOrder.has(key)) {
        return false;
      }
      storedOrder.set(key, stored.getLong(stored.getColumnIndex('element_order')));
    }
  } finally {
    stored.close();
  }
  if (storedOrder.size !== entities.length) {
    return false;
  }
  for (const entity of entities) {
    const value: number | undefined = storedOrder.get(`${entity.kind}:${entity.id}`);
    if (value === undefined) {
      return false;
    }
    entity.order = value;
  }
  const ranks: Map<string, number> | null = await originalGroupLayerRanks(store, noteId, entities);
  if (ranks === null || ranks.size !== entities.length) {
    return false;
  }
  let changed: boolean = false;
  for (const entity of entities) {
    if (entity.order !== ranks.get(entity.id)) {
      changed = true;
      break;
    }
  }
  if (!changed) {
    return true;
  }
  for (const entity of entities) {
    const predicates = new relationalStore.RdbPredicates(target.table);
    predicates.equalTo('note_id', noteId);
    if (target.archived) {
      predicates.equalTo('page_timestamp', page.timestamp);
      predicates.equalTo('page_site_id', page.siteId);
      predicates.equalTo('page_index', page.index);
    } else {
      predicates.equalTo('page_id', target.pageId);
    }
    predicates.equalTo('element_id', entity.id);
    predicates.equalTo('kind', entity.kind);
    if (await store.update({ 'element_order': ranks.get(entity.id) as number }, predicates) !== 1) {
      return false;
    }
  }
  const revisionPredicates = new relationalStore.RdbPredicates(target.revisionTable);
  revisionPredicates.equalTo('note_id', noteId);
  if (target.archived) {
    revisionPredicates.equalTo('page_timestamp', page.timestamp);
    revisionPredicates.equalTo('page_site_id', page.siteId);
    revisionPredicates.equalTo('page_index', page.index);
  } else {
    revisionPredicates.equalTo('page_id', target.pageId);
  }
  revisionPredicates.equalTo('content_revision', target.revision);
  const values: relationalStore.ValuesBucket = { 'content_revision': target.revision + 1 };
  if (target.archived) {
    values['indexed_revision'] = null;
  }
  if (await store.update(values, revisionPredicates) !== 1) {
    return false;
  }
  if (!target.archived) {
    await store.executeSql('DELETE FROM search_page_state WHERE note_id = ? AND page_id = ?',
      [noteId, target.pageId]);
  }
  return true;
}

async function readPageTarget(store: relationalStore.RdbStore, noteId: string,
  page: StoredLayeringPage): Promise<StoredLayeringPageTarget | null> {
  const identity = await store.querySql(
    `SELECT page_id, visible FROM original_page_identity WHERE note_id = ?
     AND seq_timestamp = ? AND seq_site_id = ? AND seq_index = ?`,
    [noteId, page.timestamp, page.siteId, page.index]);
  let pageId: string;
  try {
    if (!identity.goToFirstRow() || identity.getLong(identity.getColumnIndex('visible')) !== 1 ||
      identity.isColumnNull(identity.getColumnIndex('page_id'))) {
      return null;
    }
    pageId = identity.getString(identity.getColumnIndex('page_id'));
  } finally {
    identity.close();
  }
  const live: number | null = await readRevision(store,
    'SELECT content_revision FROM page_info WHERE note_id = ? AND page_id = ?', [noteId, pageId]);
  const archived: number | null = await readRevision(store,
    `SELECT content_revision FROM original_deleted_page WHERE note_id = ?
     AND page_timestamp = ? AND page_site_id = ? AND page_index = ?`,
    [noteId, page.timestamp, page.siteId, page.index]);
  if ((live === null) === (archived === null)) {
    return null;
  }
  return live !== null ? { page: page, pageId: pageId, table: 'page_element_snapshot',
    revisionTable: 'page_info', revision: live, archived: false } :
    { page: page, pageId: pageId, table: 'original_deleted_page_element',
      revisionTable: 'original_deleted_page', revision: archived as number, archived: true };
}

async function readRevision(store: relationalStore.RdbStore, sql: string,
  args: relationalStore.ValueType[]): Promise<number | null> {
  const rows = await store.querySql(sql, args);
  try {
    return rows.goToFirstRow() ? rows.getLong(rows.getColumnIndex('content_revision')) : null;
  } finally {
    rows.close();
  }
}

async function readActiveGroups(store: relationalStore.RdbStore,
  noteId: string): Promise<OriginalLayeringGroup[] | null> {
  const rows = await store.querySql(
    `SELECT state.group_timestamp, state.group_site_id, state.members_value, state.z_index
     FROM original_group_state state
     LEFT JOIN original_entity_visibility_winner visibility
      ON visibility.note_id = state.note_id
      AND visibility.entity_timestamp = state.group_timestamp
      AND visibility.entity_site_id = state.group_site_id
     WHERE state.note_id = ? AND (visibility.deleted IS NULL OR visibility.deleted = 0)
     ORDER BY state.group_timestamp, state.group_site_id`, [noteId]);
  const groups: OriginalLayeringGroup[] = [];
  try {
    while (rows.goToNextRow()) {
      try {
        const timestamp: number = rows.getLong(rows.getColumnIndex('group_timestamp'));
        const siteId: number = rows.getLong(rows.getColumnIndex('group_site_id'));
        const identity: OperationIdentity = { timestamp: timestamp, siteId: siteId };
        validateOperationIdentity(identity);
        const encoded: string = rows.getString(rows.getColumnIndex('members_value'));
        const raw: PersistedGroupMember[] = JSON.parse(encoded) as PersistedGroupMember[];
        if (!Array.isArray(raw) || raw.length === 0 || raw.length > 10000) {
          return null;
        }
        const members: string[] = [];
        const seen: Set<string> = new Set<string>();
        for (const value of raw) {
          const member: OperationIdentity = { timestamp: value.timestamp, siteId: value.siteId };
          validateOperationIdentity(member);
          const memberId: string = encodeOperationId(member);
          if (!seen.has(memberId)) {
            seen.add(memberId);
            members.push(memberId);
          }
        }
        let zIndex: string | null = null;
        if (!rows.isColumnNull(rows.getColumnIndex('z_index'))) {
          zIndex = rows.getString(rows.getColumnIndex('z_index'));
          validateUnsignedLongDecimal(zIndex);
        }
        groups.push({ id: encodeOperationId(identity), timestamp: timestamp, siteId: siteId,
          zIndex: zIndex, members: members });
      } catch (_error) {
        return null;
      }
    }
  } finally {
    rows.close();
  }
  return groups;
}

function topGroup(entityId: string,
  parentByMember: Map<string, OriginalLayeringGroup>): OriginalLayeringGroup | null | false {
  let current: OriginalLayeringGroup | undefined = parentByMember.get(entityId);
  if (current === undefined) {
    return null;
  }
  const visited: Set<string> = new Set<string>();
  while (current !== undefined) {
    if (visited.has(current.id)) {
      return false;
    }
    visited.add(current.id);
    const parent: OriginalLayeringGroup | undefined = parentByMember.get(current.id);
    if (parent === undefined) {
      return current;
    }
    current = parent;
  }
  return false;
}

function compareLayeringUnits(left: OriginalLayeringUnit, right: OriginalLayeringUnit): number {
  let compared: number = compareUnsignedLongDecimal(left.zIndex, right.zIndex);
  if (compared !== 0) {
    return compared;
  }
  return compareOperationIdentity(left, right);
}

function compareLayeringEntities(left: OriginalLayeringEntity,
  right: OriginalLayeringEntity): number {
  const compared: number = compareUnsignedLongDecimal(left.zIndex, right.zIndex);
  return compared !== 0 ? compared : compareOperationIdentity(left, right);
}
