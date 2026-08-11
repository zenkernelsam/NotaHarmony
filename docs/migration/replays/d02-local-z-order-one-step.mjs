import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const py = fs.readFileSync(`${originalRoot}py.java`, 'utf8');
const dhb = fs.readFileSync(`${originalRoot}dhb.java`, 'utf8');
const zh9 = fs.readFileSync(`${originalRoot}zh9.java`, 'utf8');
const persistence = read('note/src/main/ets/data/StrokePersistence.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const order = read('note/src/main/ets/core/model/PageElementOrder.ets');
const groups = read('note/src/main/ets/core/model/OriginalGroupSelection.ets');
const orderTests = read('note/src/test/PageElementOrder.test.ets');
const groupTests = read('note/src/test/OriginalGroupSelection.test.ets');

assert.match(dhb, /case 6:[\s\S]*new py\([^\r\n]*26/);
assert.match(dhb, /case 7:[\s\S]*new py\([^\r\n]*26/);
assert.match(py, /case 26:[\s\S]*int i3 = z \? 1 : -1/);
assert.match(py, /linkedHashSet2\.contains\(sscVar2\.a\) && !sscVar2\.c/);
assert.match(py, /au1\.g1\(i2 \+ i3, list2\)/);
assert.match(py, /if \(sscVar\.c\)[\s\S]*new xgb\(z \? j \+ 1 : j == 0 \? 0L : j - 1\)/);
assert.match(py, /new xgb\(j\), 94[\s\S]*new xgb\(sscVar2\.b\), 94/);
assert.match(zh9, /new rsc\(listK1, arrayList3, linkedHashSetJ\)/);

assert.match(canvas, /movePageElementRefsOneStep\([\s\S]*selectedIds, groupIds, this\.selectionGroups, forward/);
assert.match(canvas, /OriginalZOrderCommand\.BRING_FORWARD : OriginalZOrderCommand\.SEND_BACKWARD/);
assert.match(order, /export function movePageElementRefsOneStep/);
assert.match(order, /selectedUnits\.has\(units\[index\]\.id\) && !units\[index\]\.group/);
assert.match(groups, /export function resolveOriginalSelectionLayerUnits/);
assert.match(groups, /closedUnits\.has\(unitId\)/);
assert.match(persistence, /hint\.command === OriginalZOrderCommand\.BRING_FORWARD/);
assert.match(persistence, /neighbor\.zIndex === '0' \? '0' : subtractUnsignedSmall/);
assert.match(persistence, /appendZOrderChange\(before, after, unit\.entries\[0\], neighbor\.zIndex\)/);
assert.match(persistence, /appendZOrderChange\(before, after, neighbor\.entries\[0\], unit\.zIndex\)/);
assert.match(orderTests, /moves each selected original unit exactly one layer forward or backward/);
assert.match(orderTests, /crosses an adjacent Group as one unit/);
assert.match(groupTests, /materializes contiguous top-level layer units/);

const compare = (left, right) => left.z === right.z ? left.identity - right.identity :
  left.z < right.z ? -1 : 1;
const sortedIds = units => units.slice().sort(compare).flatMap(unit => unit.entities);

function oneStep(units, selected, forward) {
  const selectedSet = new Set(selected);
  const before = new Map();
  const after = new Map();
  const offset = forward ? 1 : -1;
  for (let index = 0; index < units.length; index++) {
    const unit = units[index];
    if (!selectedSet.has(unit.id) || unit.group) continue;
    const neighbor = units[index + offset];
    if (neighbor === undefined || selectedSet.has(neighbor.id)) continue;
    before.set(unit.id, unit.z);
    if (neighbor.group) {
      after.set(unit.id, forward ? neighbor.z + 1n : neighbor.z === 0n ? 0n : neighbor.z - 1n);
    } else {
      before.set(neighbor.id, neighbor.z);
      after.set(unit.id, neighbor.z);
      after.set(neighbor.id, unit.z);
    }
  }
  const projected = units.map(unit => ({ ...unit, z: after.has(unit.id) ? after.get(unit.id) : unit.z }));
  return { before, after, projected };
}

const base = [
  { id: 'A', identity: 1, z: 0n, group: false, entities: ['A'] },
  { id: 'B', identity: 2, z: 10n, group: false, entities: ['B'] },
  { id: 'C', identity: 3, z: 20n, group: false, entities: ['C'] },
  { id: 'D', identity: 4, z: 30n, group: false, entities: ['D'] },
  { id: 'E', identity: 5, z: 40n, group: false, entities: ['E'] },
];
const forward = oneStep(base, ['B', 'D'], true);
assert.deepEqual(sortedIds(forward.projected), ['A', 'C', 'B', 'E', 'D']);
assert.deepEqual([...forward.after.entries()], [['B', 20n], ['C', 10n], ['D', 40n], ['E', 30n]]);
const backward = oneStep(base, ['B', 'D'], false);
assert.deepEqual(sortedIds(backward.projected), ['B', 'A', 'D', 'C', 'E']);
const adjacent = oneStep(base, ['B', 'C'], true);
assert.deepEqual(sortedIds(adjacent.projected), ['A', 'B', 'D', 'C', 'E']);

const withGroup = [
  { id: 'A', identity: 1, z: 4n, group: false, entities: ['A'] },
  { id: 'G', identity: 2, z: 10n, group: true, entities: ['G1', 'G2'] },
  { id: 'B', identity: 3, z: 20n, group: false, entities: ['B'] },
];
const overGroup = oneStep(withGroup, ['A'], true);
assert.deepEqual([...overGroup.after.entries()], [['A', 11n]]);
assert.deepEqual(sortedIds(overGroup.projected), ['G1', 'G2', 'A', 'B']);
assert.equal(oneStep(withGroup, ['G'], true).after.size, 0, 'selected Groups are immovable');
const behindGroup = oneStep(withGroup, ['B'], false);
assert.deepEqual([...behindGroup.after.entries()], [['B', 9n]]);
assert.deepEqual(sortedIds(behindGroup.projected), ['A', 'B', 'G1', 'G2']);
assert.equal(oneStep(base, ['E'], true).after.size, 0, 'front boundary must be a no-op');

const db = new DatabaseSync(':memory:');
db.exec(`CREATE TABLE z_state(id TEXT PRIMARY KEY,z TEXT NOT NULL);
  CREATE TABLE z_history(action_id TEXT PRIMARY KEY,before_values TEXT,after_values TEXT);
  CREATE TABLE journal(sequence INTEGER PRIMARY KEY AUTOINCREMENT,payload_type INTEGER);
  INSERT INTO z_state VALUES('A','0'),('B','10'),('C','20'),('D','30'),('E','40');`);
const values = map => [...map.entries()].map(([id, z]) => ({ id, z: z.toString() }));
const durable = { before: values(forward.before), after: values(forward.after) };
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
      db.prepare('INSERT INTO z_history VALUES(?,?,?)').run(
        'step', JSON.stringify(history.before), JSON.stringify(history.after));
    }
    db.prepare('INSERT INTO journal(payload_type) VALUES(24)').run();
    if (fail) throw new Error('injected failure');
    db.exec('COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}
apply('push', durable);
const stored = db.prepare('SELECT before_values,after_values FROM z_history WHERE action_id=?').get('step');
const restarted = { before: JSON.parse(stored.before_values), after: JSON.parse(stored.after_values) };
apply('undo', restarted);
apply('redo', restarted);
db.prepare('UPDATE z_state SET z=? WHERE id=?').run('99', 'B');
assert.throws(() => apply('undo', restarted), /source-state mismatch/);
db.prepare('UPDATE z_state SET z=? WHERE id=?').run('20', 'B');
const stateBeforeFailure = JSON.stringify(db.prepare('SELECT * FROM z_state ORDER BY id').all());
const journalBeforeFailure = db.prepare('SELECT COUNT(*) AS value FROM journal').get().value;
assert.throws(() => apply('undo', restarted, true), /injected failure/);
assert.equal(JSON.stringify(db.prepare('SELECT * FROM z_state ORDER BY id').all()), stateBeforeFailure);
assert.equal(db.prepare('SELECT COUNT(*) AS value FROM journal').get().value, journalBeforeFailure);
db.close();

console.log('localZOrderStep=original-py26-unit-neighbor-group-durable-history-rollback');
