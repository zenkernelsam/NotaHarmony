import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const original = name => fs.readFileSync(`${originalRoot}${name}.java`, 'utf8');
const cfcSource = original('cfc');
const l85 = original('l85');
const vnd = original('vnd');
const zh9 = original('zh9');
const database = read('note/src/main/ets/data/DatabaseHelper.ets');
const layering = read('note/src/main/ets/data/OriginalGroupLayering.ets');
const shapeGroup = read('note/src/main/ets/data/OriginalShapeGroupOperation.ets');
const createInk = read('note/src/main/ets/data/OriginalCreateInkOperation.ets');
const createBlock = read('note/src/main/ets/data/OriginalCreateBlockOperation.ets');
const modifyInk = read('note/src/main/ets/data/OriginalModifyInkOperation.ets');
const modifyBlock = read('note/src/main/ets/data/OriginalModifyBlockOperation.ets');
const visibility = read('note/src/main/ets/data/OriginalDeleteEntitiesOperation.ets');
const noteBundle = read('note/src/main/ets/data/OriginalNoteBundlePageIdentity.ets');
const persistence = read('note/src/main/ets/data/StrokePersistence.ets');
const selection = read('note/src/main/ets/core/model/OriginalGroupSelection.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');

assert.match(l85, /this\.e = uq9Var\.k\(\)/);
assert.match(vnd, /undVar2 != null \? undVar2\.b\(\) : ly3Var\.g\(\)/);
assert.match(vnd, /numC2 = c\(ly3Var\.g\(\), ly3Var2\.g\(\)/);
assert.match(zh9, /new ssc\(qo5Var, undVar2 != null \? undVar2\.b : vndVar2\.I\.g\(\), undVar2 != null\)/);
assert.match(zh9, /if \(!sscVar\.c && ktcVar\.f\(\)\.contains\(sscVar\.a\)\)/);
assert.match(cfcSource, /case 8:[\s\S]*if \(!sscVar2\.c\)/);
assert.match(cfcSource, /case 9:[\s\S]*rscVar2\.b/);

assert.match(database, /DB_VERSION: number = 61/);
assert.match(database, /original_group_state ADD COLUMN z_index/);
assert.match(database, /timing\.payload_type = 20/);
assert.match(layering, /export async function originalGroupLayerUnits/);
assert.match(layering, /compareOperationIdentity\(group, previous\) > 0/);
assert.match(layering, /unit\.entities\.sort\(compareLayeringEntities\)/);
assert.match(shapeGroup, /'z_index': operation\.clientTime/);
assert.match(shapeGroup, /refreshOriginalGroupLayeredOrder\(store, operation\.noteId\)/);
assert.match(noteBundle, /members_value, z_index/);
assert.match(noteBundle, /groups\.isColumnNull\(3\) \? 'null' : groups\.getString\(3\)/);
for (const source of [createInk, createBlock, modifyInk, modifyBlock, visibility, shapeGroup]) {
  assert.match(source, /originalGroupLayerRanks|refreshOriginalGroupLayeredOrder/);
}
assert.ok(createInk.indexOf('sortStoredZIndexRows(store, operation.noteId, existingRows)') <
  createInk.indexOf("store.insert('original_element_z_index'"));
assert.ok(createBlock.indexOf('sortStoredZIndexRows(store, operation.noteId, existingRows)') <
  createBlock.indexOf("store.insert('original_element_z_index'"));
assert.doesNotMatch(modifyInk, /rows\.sort\(compareStoredZIndexRows\)/);
assert.doesNotMatch(modifyBlock, /rows\.sort\(compareStoredZIndexRows\)/);
assert.match(persistence, /selected\.some\([^\n]*entry\.unitGroup/);
assert.match(persistence, /if \(compareUnsignedLongDecimal\(unit\.zIndex, candidate\) < 0 && !unit\.group\)/);
assert.match(selection, /resolveOriginalSelectedGroupLeaves/);
assert.match(canvas, /selectedGroupIds: groupIds\.slice\(\)/);
assert.match(canvas, /if \(selectedIds\.length === 0\)/);

const compareIdentity = (left, right) => left.timestamp === right.timestamp ?
  left.siteId - right.siteId : left.timestamp - right.timestamp;
const compareZIdentity = (left, right) => left.z === right.z ?
  compareIdentity(left, right) : left.z < right.z ? -1 : 1;

function layer(entities, groups, deleted = new Set()) {
  const active = groups.filter(group => !deleted.has(group.id));
  const parent = new Map();
  for (const group of active) {
    for (const member of group.members) {
      const previous = parent.get(member);
      if (previous === undefined || compareIdentity(group, previous) > 0) parent.set(member, group);
    }
  }
  const top = id => {
    let value = parent.get(id);
    const seen = new Set();
    while (value !== undefined) {
      if (seen.has(value.id)) return false;
      seen.add(value.id);
      const next = parent.get(value.id);
      if (next === undefined) return value;
      value = next;
    }
    return null;
  };
  const units = new Map();
  for (const entity of entities) {
    const group = top(entity.id);
    if (group === false || (group !== null && group.z === null)) return null;
    const unit = group ?? entity;
    if (!units.has(unit.id)) units.set(unit.id, { ...unit, group: group !== null, entities: [] });
    units.get(unit.id).entities.push(entity);
  }
  return [...units.values()].sort(compareZIdentity).flatMap(unit =>
    unit.entities.sort(compareZIdentity).map(entity => entity.id));
}

const entities = [
  { id: 'A', timestamp: 1, siteId: 1, z: 0n },
  { id: 'B', timestamp: 2, siteId: 1, z: 100n },
  { id: 'C', timestamp: 3, siteId: 1, z: 40n },
  { id: 'D', timestamp: 4, siteId: 1, z: 60n },
];
const group = { id: 'G', timestamp: 10, siteId: 1, z: 50n, members: ['A', 'B'] };
assert.deepEqual(layer(entities, [group]), ['C', 'A', 'B', 'D']);
assert.deepEqual(layer(entities, [group], new Set(['G'])), ['A', 'C', 'D', 'B']);
const outer = { id: 'H', timestamp: 20, siteId: 1, z: 70n, members: ['G', 'D'] };
assert.deepEqual(layer(entities, [group, outer]), ['C', 'A', 'D', 'B']);
const newer = { id: 'N', timestamp: 11, siteId: 2, z: 30n, members: ['A'] };
assert.deepEqual(layer(entities, [group, newer]), ['A', 'C', 'B', 'D']);
assert.equal(layer(entities, [group, { ...outer, members: ['G', 'H'] }]), null);
assert.equal(layer(entities, [{ ...group, z: null }]), null);

function cfc(units, selectedEntities, selectedUnits, command) {
  const ordered = units.slice().sort(compareZIdentity);
  const selected = ordered.filter(unit => !unit.group && selectedEntities.has(unit.id));
  const changes = new Map();
  if (command === 'front') {
    const maximum = ordered.at(-1)?.z ?? 0n;
    selected.forEach((unit, index) => changes.set(unit.id, maximum + BigInt(index + 1)));
  } else {
    const first = ordered[0];
    if (first === undefined) return changes;
    const start = first.group ? (first.z >= BigInt(selected.length) ?
      first.z - BigInt(selected.length) : 0n) : first.z;
    selected.forEach((unit, index) => changes.set(unit.id, start + BigInt(index)));
    if (!first.group) {
      ordered.filter(unit => !selectedUnits.has(unit.id)).forEach((unit, index) => {
        const candidate = first.z + BigInt(selected.length + index);
        if (unit.z < candidate && !unit.group) changes.set(unit.id, candidate);
      });
    }
  }
  return changes;
}

const units = [
  { id: 'G', timestamp: 10, siteId: 1, z: 50n, group: true },
  { id: 'C', timestamp: 3, siteId: 1, z: 40n, group: false },
];
assert.equal(cfc(units, new Set(), new Set(['G']), 'front').size, 0);
const front = cfc(units, new Set(['C']), new Set(['G', 'C']), 'front');
assert.equal(front.size, 1);
assert.equal(front.get('C'), 51n);
const back = cfc([
  { id: 'G', timestamp: 10, siteId: 1, z: 40n, group: true },
  { id: 'C', timestamp: 3, siteId: 1, z: 50n, group: false },
], new Set(['C']), new Set(['G', 'C']), 'back');
assert.equal(back.get('C'), 39n);
assert.equal(back.has('G'), false);

const db = new DatabaseSync(':memory:');
db.exec(`CREATE TABLE original_group_state(
    note_id TEXT, group_timestamp INTEGER, group_site_id INTEGER,
    PRIMARY KEY(note_id, group_timestamp, group_site_id));
  CREATE TABLE original_applied_operation_time(
    note_id TEXT, op_timestamp INTEGER, op_site_id INTEGER, client_time TEXT, payload_type INTEGER);
  INSERT INTO original_group_state VALUES('n', 10, 1), ('n', 20, 1);
  INSERT INTO original_applied_operation_time VALUES('n', 10, 1, '50', 20);`);
db.exec(`ALTER TABLE original_group_state ADD COLUMN z_index TEXT;
  UPDATE original_group_state SET z_index = (
    SELECT timing.client_time FROM original_applied_operation_time timing
    WHERE timing.note_id = original_group_state.note_id
      AND timing.op_timestamp = original_group_state.group_timestamp
      AND timing.op_site_id = original_group_state.group_site_id
      AND timing.payload_type = 20
  ) WHERE z_index IS NULL;`);
assert.equal(db.prepare('SELECT z_index FROM original_group_state WHERE group_timestamp=10').get().z_index,
  '50');
assert.equal(db.prepare('SELECT z_index FROM original_group_state WHERE group_timestamp=20').get().z_index,
  null);
db.close();

console.log('originalGroupLayering=create-time-unit-order-nested-visibility-cfc-migration-rollback');
