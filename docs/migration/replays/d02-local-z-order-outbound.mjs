import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const cfc = fs.readFileSync(`${originalRoot}cfc.java`, 'utf8');
const zh9 = fs.readFileSync(`${originalRoot}zh9.java`, 'utf8');
const dhb = fs.readFileSync(`${originalRoot}dhb.java`, 'utf8');
const py = fs.readFileSync(`${originalRoot}py.java`, 'utf8');
const x0j = fs.readFileSync(`${originalRoot}x0j.java`, 'utf8');
const w0j = fs.readFileSync(`${originalRoot}w0j.java`, 'utf8');
const persistence = read('note/src/main/ets/data/StrokePersistence.ets');
const database = read('note/src/main/ets/data/DatabaseHelper.ets');
const manager = read('note/src/main/ets/data/DatabaseManager.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const tests = read('note/src/test/DatabaseHelper.test.ets');

assert.match(dhb, /case 8:[\s\S]*new cfc\(9\)/);
assert.match(dhb, /case 9:[\s\S]*new cfc\(8\)/);
assert.match(dhb, /case 6:[\s\S]*new py\([^\r\n]*26/);
assert.match(py, /case 26:/);
assert.match(cfc, /case 8:[\s\S]*Long\.compareUnsigned\(sscVar2\.b, j4\) < 0/);
assert.match(cfc, /new xgb\(\(\(long\) i4\) \+ j3\)/);
assert.match(cfc, /case 9:[\s\S]*new xgb\(\(\(long\) i3\) \+ j \+ 1\)/);
assert.match(zh9, /au1\.K1\(arrayList2, new bg1\(new yz8\(29\), 9\)\)/);
assert.match(zh9, /x0j\.a\(list, true\)/);
assert.match(zh9, /xsc\.i\(xscVar, listL0, this\)/);
assert.match(x0j, /new q5\(24, \(ie8\)/);
assert.match(w0j, /aVar\.f\(5, tmfVar\.I\)/);

assert.match(database, /DB_VERSION: number = 60/);
assert.match(database, /CREATE TABLE IF NOT EXISTS original_local_z_order_history/);
assert.match(database, /PRIMARY KEY\(note_id, action_id\)/);
assert.match(database, /60: \[DDL_ORIGINAL_LOCAL_Z_ORDER_HISTORY\]/);
assert.match(manager, /DDL_ORIGINAL_LOCAL_Z_ORDER_HISTORY/);
assert.match(tests, /MIGRATIONS\[60\][\s\S]*original_local_z_order_history/);
assert.match(canvas, /OriginalZOrderCommand\.BRING_FRONT : OriginalZOrderCommand\.SEND_BACK/);
assert.match(canvas, /selectedElementIds: selectedIds/);
assert.match(canvas, /action\.type === UndoableActionType\.REORDER_ELEMENTS/);
assert.match(persistence, /samePreparedMembersAndPayloads\(current, next\)/);
assert.match(persistence, /originalPageHasGroups\(store, noteId, current\)/);
assert.match(persistence, /history\.effect === HistoryEffect\.UNDO \?[\s\S]*zHistory\.after : zHistory\.before/);
assert.match(persistence, /history\.effect === HistoryEffect\.UNDO \?[\s\S]*zHistory\.before : zHistory\.after/);
assert.match(persistence, /recordOriginalZOrderHistory/);
assert.match(persistence, /ORDER BY action_time DESC, action_id DESC LIMIT 512/);
assert.match(persistence, /MAX_UNSIGNED_LONG_DECIMAL/);

const MAX = 18446744073709551615n;
const compare = (left, right) => left.z === right.z ? left.id.localeCompare(right.id) :
  left.z < right.z ? -1 : 1;
const sortedIds = entries => entries.slice().sort(compare).map(entry => entry.id);

function addSmall(value, amount) {
  const result = value + BigInt(amount);
  return result > MAX ? null : result;
}

function originalReorder(entries, selectedIds, command, hasGroup = false) {
  if (hasGroup || selectedIds.length === 0 || new Set(selectedIds).size !== selectedIds.length) {
    return null;
  }
  const order = entries.slice().sort(compare);
  const selectedSet = new Set(selectedIds);
  const selected = order.filter(entry => selectedSet.has(entry.id));
  const remaining = order.filter(entry => !selectedSet.has(entry.id));
  if (selected.length !== selectedSet.size || selected.length === order.length) return null;
  const before = new Map();
  const after = new Map();
  const change = (entry, z) => {
    before.set(entry.id, entry.z);
    after.set(entry.id, z);
  };
  if (command === 'front') {
    const maximum = order.at(-1).z;
    for (let index = 0; index < selected.length; index++) {
      const z = addSmall(maximum, index + 1);
      if (z === null) return null;
      change(selected[index], z);
    }
  } else if (command === 'back') {
    const minimum = order[0].z;
    for (let index = 0; index < selected.length; index++) {
      const z = addSmall(minimum, index);
      if (z === null) return null;
      change(selected[index], z);
    }
    let shifted = 0;
    for (const entry of remaining) {
      const candidate = addSmall(minimum, selected.length + shifted);
      if (candidate === null) return null;
      if (entry.z < candidate) {
        change(entry, candidate);
        shifted++;
      }
    }
  } else {
    return null;
  }
  return { before, after, projected: order.map(entry => ({ ...entry,
    z: after.has(entry.id) ? after.get(entry.id) : entry.z })) };
}

const front = originalReorder([
  { id: 'A', z: 0n }, { id: 'B', z: 5n }, { id: 'C', z: 9n }, { id: 'D', z: 20n },
], ['B', 'D'], 'front');
assert.ok(front !== null);
assert.deepEqual(sortedIds(front.projected), ['A', 'C', 'B', 'D']);
assert.equal(front.after.get('B'), 21n);
assert.equal(front.after.get('D'), 22n);

const back = originalReorder([
  { id: 'A', z: 0n }, { id: 'B', z: 1n }, { id: 'C', z: 2n }, { id: 'D', z: 3n },
], ['B', 'D'], 'back');
assert.ok(back !== null);
assert.deepEqual(sortedIds(back.projected), ['B', 'D', 'A', 'C']);
assert.deepEqual([...back.after.entries()], [['B', 0n], ['D', 1n], ['A', 2n], ['C', 3n]]);

const sparse = originalReorder([
  { id: 'A', z: 0n }, { id: 'B', z: 50n }, { id: 'C', z: 100n },
], ['B'], 'back');
assert.ok(sparse !== null);
assert.deepEqual(sortedIds(sparse.projected), ['B', 'A', 'C']);
assert.deepEqual([...sparse.after.entries()], [['B', 0n], ['A', 1n]]);
assert.equal(sparse.after.has('C'), false, 'a sparse unaffected high z-index must not be rewritten');
assert.equal(originalReorder([{ id: 'A', z: MAX - 1n }, { id: 'B', z: MAX }], ['A'], 'front'), null);
assert.equal(originalReorder([{ id: 'A', z: 0n }, { id: 'B', z: 1n }], ['A'], 'back', true), null);

const db = new DatabaseSync(':memory:');
db.exec(`CREATE TABLE z_state(id TEXT PRIMARY KEY,z TEXT NOT NULL);
  CREATE TABLE z_history(note_id TEXT,action_id TEXT,before_values TEXT,after_values TEXT,
    action_time INTEGER,PRIMARY KEY(note_id,action_id));
  CREATE TABLE journal(sequence INTEGER PRIMARY KEY AUTOINCREMENT,payload_type INTEGER);
  INSERT INTO z_state VALUES('A','0'),('B','1'),('C','2'),('D','3');`);

const values = map => [...map.entries()].map(([id, z]) => ({ id, z: z.toString() }));
function apply(effect, history, fail = false) {
  const source = effect === 'undo' ? history.after : history.before;
  const target = effect === 'undo' ? history.before : history.after;
  db.exec('BEGIN');
  try {
    for (const value of source) {
      const row = db.prepare('SELECT z FROM z_state WHERE id=?').get(value.id);
      if (row === undefined || row.z !== value.z) throw new Error('source-state mismatch');
    }
    for (const value of target) {
      db.prepare('UPDATE z_state SET z=? WHERE id=?').run(value.z, value.id);
    }
    if (effect === 'push') {
      db.prepare('INSERT INTO z_history VALUES(?,?,?,?,?)').run(
        'note', 'action', JSON.stringify(history.before), JSON.stringify(history.after), 1);
    }
    db.prepare('INSERT INTO journal(payload_type) VALUES(24)').run();
    if (fail) throw new Error('injected failure');
    db.exec('COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

const durable = { before: values(back.before), after: values(back.after) };
apply('push', durable);
assert.deepEqual(db.prepare('SELECT id FROM z_state ORDER BY CAST(z AS INTEGER),id').all().map(row => row.id),
  ['B', 'D', 'A', 'C']);
const stored = db.prepare('SELECT before_values,after_values FROM z_history WHERE action_id=?').get('action');
const restarted = { before: JSON.parse(stored.before_values), after: JSON.parse(stored.after_values) };
apply('undo', restarted);
assert.deepEqual(db.prepare('SELECT id FROM z_state ORDER BY CAST(z AS INTEGER),id').all().map(row => row.id),
  ['A', 'B', 'C', 'D']);
apply('redo', restarted);
assert.deepEqual(db.prepare('SELECT id FROM z_state ORDER BY CAST(z AS INTEGER),id').all().map(row => row.id),
  ['B', 'D', 'A', 'C']);
db.prepare('UPDATE z_state SET z=? WHERE id=?').run('99', 'A');
assert.throws(() => apply('undo', restarted), /source-state mismatch/);
db.prepare('UPDATE z_state SET z=? WHERE id=?').run('2', 'A');
const beforeFailure = JSON.stringify(db.prepare('SELECT * FROM z_state ORDER BY id').all());
const journalCount = db.prepare('SELECT COUNT(*) AS value FROM journal').get().value;
assert.throws(() => apply('undo', restarted, true), /injected failure/);
assert.equal(JSON.stringify(db.prepare('SELECT * FROM z_state ORDER BY id').all()), beforeFailure);
assert.equal(db.prepare('SELECT COUNT(*) AS value FROM journal').get().value, journalCount);
db.close();

console.log('localZOrder=original-uint64-front-back-durable-history-group-fallback-rollback');
