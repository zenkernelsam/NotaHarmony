import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';
import { assertDatabaseVersionAtLeast } from './support/database-version.mjs';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalWriter = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/ys2.java', 'utf8');
const originalPath = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/ldj.java', 'utf8');
const originalCreate = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/u5j.java', 'utf8');
const encoder = read('note/src/main/ets/data/OriginalCreateInkPayloadEncoder.ets');
const pathEncoder = read('note/src/main/ets/data/OriginalInkPathEncoder.ets');
const persistence = read('note/src/main/ets/data/StrokePersistence.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const session = read('note/src/main/ets/rendering/StrokeSession.ets');
const visibility = read('note/src/main/ets/data/OriginalDeleteEntitiesPayloadEncoder.ets');
const history = read('note/src/main/ets/data/PersistentHistory.ets');
const schema = read('note/src/main/ets/data/DatabaseHelper.ets');
const tests = read('note/src/test/OriginalCreateInkPayloadEncoder.test.ets');

assert.match(originalWriter, /aVar\.C\(20\)/);
assert.match(originalWriter, /aVar\.j\(0, nti\.X\(cxcVar, aVar\)\)/);
assert.match(originalWriter, /aVar\.j\(1, apb\.Y\(fqaVar, aVar\)\)/);
assert.match(originalWriter, /aVar\.h\(9, numValueOf\.intValue\(\)\)/);
assert.match(originalPath, /public static final nl8 M2\(List list, boolean z\)/);
assert.match(originalPath, /zsa zsaVar = zsa\.BITS_32/);
assert.match(originalCreate, /return faj\.a\(cxcVar, fqaVar2/);

assert.match(pathEncoder, /bytes\[0\] = 1/);
assert.match(pathEncoder, /writeF32LE/);
assert.match(pathEncoder, /writeAttributedElement\(bytes, offset, 3/);
assert.match(encoder, /writeVtable\(bytes, 4, 64/);
assert.match(encoder, /encodeOriginalInkCenterPath/);
assert.match(encoder, /backingPencilSeed/);
assert.match(persistence, /reserveOriginalInkCreate/);
assert.match(persistence, /readEligibleOriginalInkPage/);
assert.match(persistence, /OriginalCreateInkOperationApplier\(\)\.apply/);
assert.match(persistence, /uploadImmediately: true/);
assert.match(persistence, /originalEntityVisibilityMutation/);
assert.match(persistence, /OriginalDeleteEntitiesOperationApplier\(\)\.apply/);
assert.match(persistence, /blockOriginalInkAuthoring/);
assert.match(canvas, /originalInkReservation/);
assert.match(canvas, /originalInkIneligiblePages/);
assert.match(canvas, /originalInkReservationGeneration === generation/);
assert.match(canvas, /originalInkReservationPageId === pageId/);
assert.match(canvas, /return this\.refreshOriginalInkReservation\(generation, pageId\)/);
assert.match(session, /originalCreate: OriginalInkCreateMetadata \| null/);
assert.match(visibility, /encodeOriginalEntityVisibility/);
assert.match(history, /OpType\.ORIGINAL_CREATE_INK/);
assertDatabaseVersionAtLeast(schema, 61);
assert.match(schema, /original_local_ink_authoring_guard/);
assert.match(tests, /round-trips a BITS_32 cubic local pen through dm2/);

const db = new DatabaseSync(':memory:');
db.exec(`CREATE TABLE snapshot(id TEXT PRIMARY KEY,kind INTEGER,element_order INTEGER);
  CREATE TABLE z(id TEXT PRIMARY KEY,z_index INTEGER,visible INTEGER);
  CREATE TABLE ink(id TEXT PRIMARY KEY,path TEXT);
  CREATE TABLE guard(page_id TEXT PRIMARY KEY,blocked INTEGER);
  CREATE TABLE operations(seq INTEGER PRIMARY KEY AUTOINCREMENT,kind TEXT,id TEXT);
  INSERT INTO snapshot VALUES('op:1:7',1,0);
  INSERT INTO z VALUES('op:1:7',100,1);
  INSERT INTO ink VALUES('op:1:7','existing');`);

function aligned() {
  if (db.prepare(`SELECT blocked FROM guard WHERE page_id='page'`).get()?.blocked === 1) return false;
  return JSON.stringify(db.prepare('SELECT id,kind FROM snapshot ORDER BY element_order').all()) ===
    JSON.stringify(db.prepare('SELECT id,1 kind FROM z WHERE visible=1 ORDER BY z_index,id').all());
}

function createInk(id, fail = false) {
  assert.equal(aligned(), true);
  db.exec('BEGIN IMMEDIATE');
  try {
    db.prepare('INSERT INTO ink VALUES(?,?)').run(id, 'bits32-cubic');
    db.prepare('INSERT INTO z VALUES(?,?,1)').run(id, 200);
    db.prepare('INSERT INTO snapshot VALUES(?,1,1)').run(id);
    db.prepare('INSERT INTO operations(kind,id) VALUES(?,?)').run('CREATE_INK', id);
    if (fail) throw new Error('injected create failure');
    db.prepare('INSERT INTO operations(kind,id) VALUES(?,?)').run('HISTORY_PUSH', id);
    db.exec('COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

function visibilityChange(id, deleted) {
  db.exec('BEGIN IMMEDIATE');
  if (deleted) {
    db.prepare('UPDATE z SET visible=0 WHERE id=?').run(id);
    db.prepare('DELETE FROM snapshot WHERE id=?').run(id);
  } else {
    db.prepare('UPDATE z SET visible=1 WHERE id=?').run(id);
    db.prepare('INSERT INTO snapshot VALUES(?,1,1)').run(id);
  }
  db.prepare('INSERT INTO operations(kind,id) VALUES(?,?)')
    .run(deleted ? 'ENTITY_DELETE' : 'ENTITY_UNDELETE', id);
  db.prepare('INSERT INTO operations(kind,id) VALUES(?,?)')
    .run(deleted ? 'HISTORY_UNDO' : 'HISTORY_REDO', id);
  db.exec('COMMIT');
}

createInk('op:2:7');
visibilityChange('op:2:7', true);
assert.equal(db.prepare(`SELECT visible FROM z WHERE id='op:2:7'`).get().visible, 0);
visibilityChange('op:2:7', false);
assert.equal(aligned(), true);
const beforeFailure = JSON.stringify({
  snapshot: db.prepare('SELECT * FROM snapshot ORDER BY id').all(),
  z: db.prepare('SELECT * FROM z ORDER BY id').all(),
  operations: db.prepare('SELECT kind,id FROM operations ORDER BY seq').all(),
});
assert.throws(() => createInk('op:3:7', true), /injected create failure/);
assert.equal(JSON.stringify({
  snapshot: db.prepare('SELECT * FROM snapshot ORDER BY id').all(),
  z: db.prepare('SELECT * FROM z ORDER BY id').all(),
  operations: db.prepare('SELECT kind,id FROM operations ORDER BY seq').all(),
}), beforeFailure);
db.prepare(`INSERT INTO guard VALUES('page',1)`).run();
assert.equal(aligned(), false);
db.close();

console.log('localCreateInk=bits32-canonical-original-visibility-history-guard-rollback');
