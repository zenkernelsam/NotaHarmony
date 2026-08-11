import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalDelete = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/fsi.java', 'utf8');
const originalFactory = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/u5j.java', 'utf8');
const originalWholeErase = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/lg2.java', 'utf8');
const persistence = read('note/src/main/ets/data/StrokePersistence.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const encoderTest = read('note/src/test/OriginalCreateInkPayloadEncoder.test.ets');

assert.match(originalDelete, /public static s83 d\(List list, List list2, List list3, List list4\)/);
assert.match(originalDelete, /aVarA\.D\(8, numValueOf5\.intValue\(\), 4\)/);
assert.match(originalDelete, /aVarA\.h\(0, numValueOf\.intValue\(\)\)/);
assert.match(originalDelete, /aVarA\.h\(1, numValueOf2\.intValue\(\)\)/);
assert.match(originalFactory, /return fsi\.d\(list, list2, list3, list4\)/);
assert.match(originalWholeErase, /java\.util\.Set r1 = r8\.a\(\)/);
assert.match(originalWholeErase, /java\.util\.List r1 = defpackage\.au1\.T1\(r1\)/);
assert.match(originalWholeErase, /s83 r1 = defpackage\.fsi\.d\(r1, r4, r4, r4\)/);

assert.match(persistence, /originalEntityVisibilityMutation/);
assert.match(persistence, /identities: OperationIdentity\[\]/);
assert.match(persistence, /identities\.length !== targetCount/);
assert.match(persistence, /visibility\.deleted \? visibility\.identities : \[\]/);
assert.match(persistence, /MAX_ORIGINAL_DELETE_ENTITY_COUNT/);
assert.match(canvas, /isOriginalInkAction/);
assert.match(canvas, /areCanonicalOriginalStrokes/);
assert.match(canvas, /partialBefore\.length === 0/);
assert.match(canvas,
  /originalEntityOnly: boolean = partialBefore\.length === 0[\s\S]*removedShapes\.map\(/);
assert.match(canvas, /if \(changed\) \{\s*this\.persist\(originalEntityOnly\)/);
assert.match(encoderTest, /entityDeletes\.length\)\.assertEqual\(3\)/);

const db = new DatabaseSync(':memory:');
db.exec(`CREATE TABLE page(id TEXT PRIMARY KEY,revision INTEGER NOT NULL,guarded INTEGER NOT NULL);
  CREATE TABLE visible(id TEXT PRIMARY KEY,z INTEGER NOT NULL,payload TEXT NOT NULL);
  CREATE TABLE archived(id TEXT PRIMARY KEY,z INTEGER NOT NULL,payload TEXT NOT NULL);
  CREATE TABLE operations(seq INTEGER PRIMARY KEY AUTOINCREMENT,kind TEXT NOT NULL,target_count INTEGER NOT NULL);
  INSERT INTO page VALUES('page',0,0);
  INSERT INTO visible VALUES('op:1:7',100,'a'),('op:2:7',200,'b'),('op:3:7',300,'c');`);

function visibility(ids, deleted, injectFailure = false) {
  db.exec('BEGIN IMMEDIATE');
  try {
    const source = deleted ? 'visible' : 'archived';
    const destination = deleted ? 'archived' : 'visible';
    for (const id of ids) {
      const row = db.prepare(`SELECT z,payload FROM ${source} WHERE id=?`).get(id);
      if (row === undefined) throw new Error(`missing ${id}`);
      db.prepare(`INSERT INTO ${destination} VALUES(?,?,?)`).run(id, row.z, row.payload);
      db.prepare(`DELETE FROM ${source} WHERE id=?`).run(id);
    }
    db.prepare('UPDATE page SET revision=revision+1 WHERE id=?').run('page');
    db.prepare('INSERT INTO operations(kind,target_count) VALUES(?,?)')
      .run(deleted ? 'DELETE_ENTITIES' : 'UNDELETE_ENTITIES', ids.length);
    if (injectFailure) throw new Error('injected companion failure');
    db.prepare('INSERT INTO operations(kind,target_count) VALUES(?,?)').run('HISTORY', ids.length);
    db.exec('COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

visibility(['op:1:7', 'op:3:7'], true);
assert.deepEqual(db.prepare('SELECT id FROM visible ORDER BY z').all().map(row => ({ id: row.id })),
  [{ id: 'op:2:7' }]);
assert.equal(db.prepare(`SELECT revision FROM page WHERE id='page'`).get().revision, 1);
assert.deepEqual(db.prepare('SELECT kind,target_count FROM operations ORDER BY seq').all()
  .map(row => ({ kind: row.kind, target_count: row.target_count })), [
  { kind: 'DELETE_ENTITIES', target_count: 2 }, { kind: 'HISTORY', target_count: 2 },
]);
visibility(['op:1:7', 'op:3:7'], false);
assert.deepEqual(db.prepare('SELECT id FROM visible ORDER BY z').all().map(row => ({ id: row.id })), [
  { id: 'op:1:7' }, { id: 'op:2:7' }, { id: 'op:3:7' },
]);
assert.equal(db.prepare(`SELECT revision FROM page WHERE id='page'`).get().revision, 2);

const beforeFailure = JSON.stringify({
  visible: db.prepare('SELECT * FROM visible ORDER BY z').all(),
  archived: db.prepare('SELECT * FROM archived ORDER BY z').all(),
  page: db.prepare('SELECT * FROM page').all(),
  operations: db.prepare('SELECT * FROM operations ORDER BY seq').all(),
});
assert.throws(() => visibility(['op:1:7', 'op:3:7'], true, true), /injected companion failure/);
assert.equal(JSON.stringify({
  visible: db.prepare('SELECT * FROM visible ORDER BY z').all(),
  archived: db.prepare('SELECT * FROM archived ORDER BY z').all(),
  page: db.prepare('SELECT * FROM page').all(),
  operations: db.prepare('SELECT * FROM operations ORDER BY seq').all(),
}), beforeFailure);

db.prepare(`UPDATE page SET guarded=1 WHERE id='page'`).run();
assert.equal(db.prepare(`SELECT guarded FROM page WHERE id='page'`).get().guarded, 1);
db.close();

console.log('localBatchInkVisibility=single-vector-revision-undo-redo-guard-rollback');
