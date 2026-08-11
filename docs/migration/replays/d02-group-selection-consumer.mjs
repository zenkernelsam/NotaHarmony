import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const resolverSource = read('note/src/main/ets/core/model/OriginalGroupSelection.ets');
const persistenceSource = read('note/src/main/ets/data/StrokePersistence.ets');
const selectionSource = read('note/src/main/ets/rendering/SelectionTool.ets');
const canvasSource = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const shapeSource = read('note/src/main/ets/data/OriginalShapeGroupOperation.ets');
const shapeGeometrySource = read('note/src/main/ets/core/model/ShapeGeometry.ets');
const packageSource = read('note/src/main/ets/data/NotePackageSpec.ets');

const group = (id, timestamp, siteId, members) => ({ id, timestamp, siteId, members });
const compare = (left, right) => left.timestamp === right.timestamp ?
  Math.sign(left.siteId - right.siteId) : Math.sign(left.timestamp - right.timestamp);

function resolve(selectedIds, availableIds, groups) {
  const available = new Set(availableIds);
  const byId = new Map();
  const parentByMember = new Map();
  for (const candidate of groups) {
    if (!candidate.id || candidate.members.length === 0) continue;
    byId.set(candidate.id, candidate);
    for (const member of candidate.members) {
      const current = parentByMember.get(member);
      if (!current || compare(candidate, current) > 0) parentByMember.set(member, candidate);
    }
  }
  const selected = new Set();
  const selectedGroups = new Set();
  const handled = new Set();
  for (const entityId of selectedIds) {
    if (!available.has(entityId)) continue;
    let current = parentByMember.get(entityId);
    const visited = new Set();
    while (current && !visited.has(current.id) && parentByMember.has(current.id)) {
      visited.add(current.id);
      current = parentByMember.get(current.id);
    }
    if (current && visited.has(current.id)) current = null;
    if (!current) {
      selected.add(entityId);
      continue;
    }
    if (handled.has(current.id)) continue;
    const expansion = expand(current.id, byId, available, new Set());
    if (!expansion) {
      selected.add(entityId);
      continue;
    }
    handled.add(current.id);
    selectedGroups.add(current.id);
    for (const leaf of expansion) selected.add(leaf);
  }
  return { entityIds: [...selected], groupIds: [...selectedGroups] };
}

function expand(groupId, byId, available, visiting) {
  if (visiting.has(groupId)) return null;
  const candidate = byId.get(groupId);
  if (!candidate) return null;
  visiting.add(groupId);
  const leaves = new Set();
  for (const member of candidate.members) {
    if (byId.has(member)) {
      const nested = expand(member, byId, available, visiting);
      if (!nested) return null;
      for (const leaf of nested) leaves.add(leaf);
    } else if (!available.has(member)) {
      return null;
    } else {
      leaves.add(member);
    }
  }
  visiting.delete(groupId);
  return [...leaves];
}

let result = resolve(['a'], ['a', 'b', 'c'], [
  group('older', 10, 9, ['a', 'b']), group('newer', 11, 1, ['a', 'c']),
]);
assert.deepEqual(result, { entityIds: ['a', 'c'], groupIds: ['newer'] });

result = resolve(['a'], ['a', 'b', 'c'], [
  group('lower-site', 20, 1, ['a', 'b']), group('higher-site', 20, 2, ['a', 'c']),
]);
assert.deepEqual(result, { entityIds: ['a', 'c'], groupIds: ['higher-site'] });

result = resolve(['a'], ['a', 'b', 'c'], [
  group('inner', 30, 1, ['a', 'b']), group('outer', 31, 1, ['inner', 'c']),
]);
assert.deepEqual(result, { entityIds: ['a', 'b', 'c'], groupIds: ['outer'] });

assert.deepEqual(resolve(['a'], ['a'], [group('missing', 40, 1, ['a', 'other-page'])]),
  { entityIds: ['a'], groupIds: [] });
assert.deepEqual(resolve(['a'], ['a'], [
  group('one', 50, 1, ['a', 'two']), group('two', 51, 1, ['one']),
]), { entityIds: ['a'], groupIds: [] });

const db = new DatabaseSync(':memory:');
db.exec(`CREATE TABLE original_group_state(
    note_id TEXT, group_timestamp INTEGER, group_site_id INTEGER, members_value TEXT);
  CREATE TABLE original_entity_visibility_winner(
    note_id TEXT, entity_timestamp INTEGER, entity_site_id INTEGER, deleted INTEGER);
  INSERT INTO original_group_state VALUES
    ('note',60,1,'[{"timestamp":1,"siteId":1}]'),
    ('note',61,1,'[{"timestamp":2,"siteId":1}]'),
    ('other',62,1,'[{"timestamp":3,"siteId":1}]');
  INSERT INTO original_entity_visibility_winner VALUES('note',61,1,1);`);
const rows = db.prepare(`SELECT state.group_timestamp, state.group_site_id, state.members_value
  FROM original_group_state state
  LEFT JOIN original_entity_visibility_winner visibility
    ON visibility.note_id=state.note_id
    AND visibility.entity_timestamp=state.group_timestamp
    AND visibility.entity_site_id=state.group_site_id
  WHERE state.note_id=? AND (visibility.deleted IS NULL OR visibility.deleted=0)
  ORDER BY state.group_timestamp,state.group_site_id`).all('note');
assert.equal(rows.length, 1);
assert.equal(rows[0].group_timestamp, 60);
db.close();

assert.match(resolverSource, /compareGroupIdentity\(group, current\) > 0/);
assert.match(resolverSource, /topContainingGroup\(entityId, parentByMember\)/);
assert.match(resolverSource, /expandGroup\(top\.id, byId, available/);
assert.match(resolverSource, /return \{ valid: false, leaves: \[\] \}/);
assert.match(persistenceSource, /state\.members_value/);
assert.match(persistenceSource, /visibility\.deleted IS NULL OR visibility\.deleted = 0/);
assert.match(persistenceSource, /result\.groups = await this\.loadOriginalSelectionGroups/);
assert.match(selectionSource, /if \(this\.elementBoundsSelected\(shape\.bounds\)\)/);
assert.match(shapeGeometrySource,
  /!selected\.has\(shape\.id\) \|\| shape\.positionLocked === true/);
assert.match(selectionSource, /resolveOriginalGroupSelection\(/);
assert.match(selectionSource, /this\.state\.selectedGroupIds = grouped\.groupIds/);
assert.match(canvasSource, /this\.selectionGroups = loaded\.groups/);
assert.match(canvasSource, /selectedGroupIds/);
assert.equal((shapeSource.match(/positionLocked: payload\.positionLocked/g) || []).length, 3);
assert.equal((shapeGeometrySource.match(/positionLocked: shape\.positionLocked/g) || []).length, 3);
assert.match(packageSource,
  /shape\.positionLocked !== undefined && typeof shape\.positionLocked !== 'boolean'/);

console.log('D02_GROUP_SELECTION_CONSUMER_REPLAY_OK ' +
  'latest-containing=2|nested-top=1|missing-cycle-fallback=2|deleted-group=1|' +
  'shape-lock-materialization=3|locked-selectable-for-unlock=1|selection-state-group-id=1|' +
  'outbound-group-writer=pending');
