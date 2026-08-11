import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';
const original = value => fs.readFileSync(originalRoot + value, 'utf8');

const dsc = original('sources/defpackage/dsc.java');
const dhb = original('sources/defpackage/dhb.java');
const ux9 = original('sources/defpackage/ux9.java');
const strings = original('resources/res/values/strings.xml');
const encoder = read('note/src/main/ets/data/OriginalGroupPayloadEncoder.ets');
const mutationCodec = read('note/src/main/ets/data/OriginalGroupMutationOpCodec.ets');
const selection = read('note/src/main/ets/core/model/OriginalGroupSelection.ets');
const persistence = read('note/src/main/ets/data/StrokePersistence.ets');
const history = read('note/src/main/ets/data/PersistentHistory.ets');
const undo = read('note/src/main/ets/rendering/UndoRedoManager.ets');
const overlay = read('note/src/main/ets/ui/components/SelectionOverlay.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const payloadFixtures = read('note/src/test/OriginalGroupPayloadEncoder.test.ets');
const mutationFixtures = read('note/src/test/OriginalGroupMutationOpCodec.test.ets');
const selectionFixtures = read('note/src/test/OriginalGroupSelection.test.ets');
const historyFixtures = read('note/src/test/PersistentHistory.test.ets');

assert.match(dsc, /new dsc\("GROUP", 4\)/);
assert.match(dsc, /new dsc\("UNGROUP", 5\)/);
assert.match(dhb, /case 4:[\s\S]*ktcVar instanceof ftc[\s\S]*ftcVar\.q[\s\S]*ftcVar\.m/);
assert.match(dhb, /arrayListA1\.size\(\) >= 2/);
assert.match(dhb, /new kk9\(29,[\s\S]*arrayListA1/);
assert.match(dhb, /case 5:[\s\S]*ktcVar instanceof gtc[\s\S]*new wsc\(/);
assert.match(ux9, /feature_note__selection_menu_group/);
assert.match(ux9, /feature_note__selection_menu_ungroup/);
assert.match(strings, /feature_note__selection_menu_group">Group</);
assert.match(strings, /feature_note__selection_menu_ungroup">Ungroup</);

assert.match(encoder, /encodeOriginalCreateGroup/);
assert.match(encoder, /encodeOriginalModifyGroup/);
assert.match(encoder, /MAX_ORIGINAL_GROUP_MEMBERS: number = 10000/);
assert.match(mutationCodec, /MAGIC: number\[\] = \[0x4E, 0x47, 0x4D, 0x31\]/);
assert.match(mutationCodec, /ref\.zIndex !== index/);
assert.match(selection, /resolveOriginalGroupAuthoringMembers/);
assert.match(selection, /members\.push\(groupId\)/);
assert.match(persistence, /async createOriginalGroup/);
assert.match(persistence, /async ungroupOriginalGroup/);
assert.match(persistence, /async applyOriginalGroupHistory/);
assert.match(persistence, /ORIGINAL_CREATE_GROUP_PAYLOAD_TYPE/);
assert.match(persistence, /ORIGINAL_DELETE_ENTITIES_PAYLOAD_TYPE/);
assert.match(persistence, /uploadImmediately: true/);
assert.match(persistence, /await this\.appendOriginalGroupHistory/);
assert.match(history, /OpType\.GROUP_ELEMENTS/);
assert.match(history, /decodeOriginalGroupMutation/);
assert.match(undo, /GROUP_ELEMENTS = 18/);
assert.match(overlay, /SelectionMenuAction\.GROUP/);
assert.match(overlay, /SelectionMenuAction\.UNGROUP/);
assert.match(canvas, /resolveOriginalGroupAuthoringMembers/);
assert.match(canvas, /this\.persistence\.createOriginalGroup/);
assert.match(canvas, /this\.persistence\.ungroupOriginalGroup/);
assert.match(canvas, /this\.persistence\.applyOriginalGroupHistory/);
assert.match(payloadFixtures, /round-trips canonical CREATE_GROUP members/);
assert.match(mutationFixtures, /round-trips Group state and both layered orders/);
assert.match(selectionFixtures, /selected Groups as distinct member units/i);
assert.match(historyFixtures, /restores NGM1 Group actions across PUSH UNDO and REDO/);

const db = new DatabaseSync(':memory:');
db.exec(`CREATE TABLE entity(id TEXT PRIMARY KEY,z INTEGER NOT NULL);
  CREATE TABLE group_state(id TEXT PRIMARY KEY,members TEXT NOT NULL,z INTEGER NOT NULL,
    deleted INTEGER NOT NULL CHECK(deleted IN (0,1)));
  CREATE TABLE operation_log(seq INTEGER PRIMARY KEY AUTOINCREMENT,payload_type INTEGER NOT NULL,
    target TEXT NOT NULL,upload_immediately INTEGER NOT NULL);
  CREATE TABLE history(seq INTEGER PRIMARY KEY AUTOINCREMENT,action TEXT NOT NULL,
    effect TEXT NOT NULL,before_order TEXT NOT NULL,after_order TEXT NOT NULL);
  INSERT INTO entity VALUES('a',10),('b',20),('c',30),('d',40);
  INSERT INTO group_state VALUES('inner','["a","b"]',50,0);`);

function activeGroups() {
  return db.prepare('SELECT * FROM group_state WHERE deleted=0').all().map(row => ({
    ...row, members: JSON.parse(row.members),
  }));
}

function layeredOrder() {
  const entities = db.prepare('SELECT * FROM entity').all();
  const groups = activeGroups();
  const byId = new Map(groups.map(group => [group.id, group]));
  const parent = new Map();
  for (const group of groups) for (const member of group.members) parent.set(member, group.id);
  const top = id => {
    let current = id;
    const visited = new Set();
    while (parent.has(current)) {
      if (visited.has(current)) throw new Error('Group cycle');
      visited.add(current);
      current = parent.get(current);
    }
    return current;
  };
  const units = new Map();
  for (const entity of entities) {
    const unit = top(entity.id);
    if (!units.has(unit)) units.set(unit, []);
    units.get(unit).push(entity);
  }
  return [...units.entries()].sort((left, right) => {
    const leftGroup = byId.get(left[0]);
    const rightGroup = byId.get(right[0]);
    const leftZ = leftGroup?.z ?? left[1][0].z;
    const rightZ = rightGroup?.z ?? right[1][0].z;
    return leftZ - rightZ;
  }).flatMap(entry => entry[1].sort((left, right) => left.z - right.z).map(value => value.id));
}

function mutate(action, effect, change, payloadType, target, fail = false) {
  db.exec('BEGIN IMMEDIATE');
  try {
    const before = layeredOrder();
    change();
    db.prepare('INSERT INTO operation_log(payload_type,target,upload_immediately) VALUES(?,?,1)')
      .run(payloadType, target);
    if (fail) throw new Error('injected Group transaction failure');
    const after = layeredOrder();
    db.prepare(`INSERT INTO history(action,effect,before_order,after_order) VALUES(?,?,?,?)`)
      .run(action, effect, JSON.stringify(before), JSON.stringify(after));
    db.exec('COMMIT');
    return { before, after };
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

assert.deepEqual(layeredOrder(), ['c', 'd', 'a', 'b']);
const created = mutate('create-outer', 'PUSH', () => {
  db.prepare('INSERT INTO group_state VALUES(?,?,?,0)').run('outer', '["inner","c"]', 60);
}, 20, 'outer');
assert.deepEqual(created.before, ['c', 'd', 'a', 'b']);
assert.deepEqual(created.after, ['d', 'a', 'b', 'c']);

const ungrouped = mutate('ungroup-outer', 'PUSH', () => {
  db.prepare('UPDATE group_state SET deleted=1 WHERE id=?').run('outer');
}, 25, 'outer');
assert.deepEqual(ungrouped.after, ['c', 'd', 'a', 'b']);
const undoUngroup = mutate('ungroup-outer', 'UNDO', () => {
  db.prepare('UPDATE group_state SET deleted=0 WHERE id=?').run('outer');
}, 25, 'outer');
assert.deepEqual(undoUngroup.after, ['d', 'a', 'b', 'c']);
const redoUngroup = mutate('ungroup-outer', 'REDO', () => {
  db.prepare('UPDATE group_state SET deleted=1 WHERE id=?').run('outer');
}, 25, 'outer');
assert.deepEqual(redoUngroup.after, ['c', 'd', 'a', 'b']);

assert.equal(db.prepare('SELECT COUNT(*) count FROM operation_log WHERE payload_type=20').get().count, 1);
assert.equal(db.prepare('SELECT COUNT(*) count FROM operation_log WHERE payload_type=25').get().count, 3);
assert.equal(db.prepare('SELECT MIN(upload_immediately) value FROM operation_log').get().value, 1);
assert.deepEqual(db.prepare('SELECT effect FROM history ORDER BY seq').all().map(row => row.effect),
  ['PUSH', 'PUSH', 'UNDO', 'REDO']);

const beforeFailure = JSON.stringify(db.prepare('SELECT * FROM group_state ORDER BY id').all());
const operationsBeforeFailure = db.prepare('SELECT COUNT(*) count FROM operation_log').get().count;
const historyBeforeFailure = db.prepare('SELECT COUNT(*) count FROM history').get().count;
assert.throws(() => mutate('failed', 'PUSH', () => {
  db.prepare('INSERT INTO group_state VALUES(?,?,?,0)').run('failed', '["c","d"]', 70);
}, 20, 'failed', true), /injected Group transaction failure/);
assert.equal(JSON.stringify(db.prepare('SELECT * FROM group_state ORDER BY id').all()), beforeFailure);
assert.equal(db.prepare('SELECT COUNT(*) count FROM operation_log').get().count, operationsBeforeFailure);
assert.equal(db.prepare('SELECT COUNT(*) count FROM history').get().count, historyBeforeFailure);
db.close();

console.log('localGroupAuthoring=type20-create-type25-ungroup-nested-unit-layering-' +
  'persistent-undo-redo-rollback');
