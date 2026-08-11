import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const read = value => fs.readFileSync(new URL('../../../' + value, import.meta.url), 'utf8');
const originalFactory = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/u5j.java', 'utf8');
const originalPayload = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/s83.java', 'utf8');
const persistence = read('note/src/main/ets/data/StrokePersistence.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');

assert.match(originalFactory,
  /public static final s83 k\(x09 x09Var, List list, List list2, List list3, List list4\)/);
assert.match(originalFactory, /return fsi\.d\(list, list2, list3, list4\)/);
assert.match(originalPayload,
  /DeleteEntities\(entityDeletes=.*entityUndeletes=.*pageDeletes=.*pageUndeletes=/);
assert.match(persistence, /originalEntityStateExists/);
assert.match(persistence, /JOIN original_block_state state/);
assert.match(persistence, /state\.block_type = \?/);
assert.match(persistence, /target\.elementId !== persisted\.data\.id/);
assert.match(persistence, /samePreparedMembersAndPayloads\(materialized, step\.elements\)/);
assert.match(persistence, /local entity visibility reducer produced unexpected page state/);
assert.match(canvas, /action\.type === UndoableActionType\.ADD_ELEMENT/);
assert.match(canvas, /action\.removedTextBlocks\.map/);
assert.match(canvas, /action\.removedImages\.map/);
assert.match(canvas, /action\.removedMathBlocks \?\? \[\]/);

const db = new DatabaseSync(':memory:');
db.exec(`CREATE TABLE page(id TEXT PRIMARY KEY, revision INTEGER NOT NULL);
  CREATE TABLE entity(id TEXT PRIMARY KEY, kind INTEGER NOT NULL, z INTEGER NOT NULL,
    payload TEXT NOT NULL, visible INTEGER NOT NULL, block_type INTEGER);
  CREATE TABLE archive(id TEXT PRIMARY KEY, kind INTEGER NOT NULL, z INTEGER NOT NULL,
    payload TEXT NOT NULL);
  CREATE TABLE operation(identity INTEGER PRIMARY KEY, deleted INTEGER NOT NULL,
    target_count INTEGER NOT NULL, upload INTEGER NOT NULL);
  INSERT INTO page VALUES('p',0);
  INSERT INTO entity VALUES('op:8:7',1,20,'stroke-v1',1,NULL);
  INSERT INTO entity VALUES('op:9:7',3,60,'shape-v1',1,NULL);
  INSERT INTO entity VALUES('op:10:7',2,100,'text-v1',1,0);
  INSERT INTO entity VALUES('op:11:7',4,200,'image-v1',1,1);
  INSERT INTO entity VALUES('op:12:7',5,300,'math-v1',1,2);`);

function expectedBlockType(kind) {
  return kind === 2 ? 0 : kind === 4 ? 1 : kind === 5 ? 2 : null;
}

function applyVisibility(identity, ids, deleted, expectedPayloads, failAfter = false) {
  db.exec('BEGIN IMMEDIATE');
  try {
    const revision = db.prepare("SELECT revision FROM page WHERE id='p'").get().revision;
    for (const id of ids) {
      const state = db.prepare('SELECT * FROM entity WHERE id=?').get(id);
      assert.notEqual(state, undefined);
      assert.equal(state.block_type, expectedBlockType(state.kind));
      if (deleted) {
        assert.equal(state.visible, 1);
        db.prepare('INSERT INTO archive VALUES(?,?,?,?)').run(
          state.id, state.kind, state.z, state.payload);
        db.prepare('UPDATE entity SET visible=0 WHERE id=?').run(id);
      } else {
        const archived = db.prepare('SELECT * FROM archive WHERE id=?').get(id);
        assert.notEqual(archived, undefined);
        assert.equal(archived.payload, expectedPayloads.get(id));
        db.prepare('UPDATE entity SET visible=1,payload=? WHERE id=?').run(
          archived.payload, id);
        db.prepare('DELETE FROM archive WHERE id=?').run(id);
      }
    }
    const visible = db.prepare('SELECT id,payload FROM entity WHERE visible=1 ORDER BY z').all();
    for (const row of visible) {
      assert.equal(row.payload, expectedPayloads.get(row.id));
    }
    db.prepare('INSERT INTO operation VALUES(?,?,?,1)').run(identity, deleted ? 1 : 0, ids.length);
    db.prepare("UPDATE page SET revision=? WHERE id='p'").run(revision + 1);
    if (failAfter) throw new Error('injected block visibility companion failure');
    db.exec('COMMIT');
  } catch (error) {
    db.exec('ROLLBACK'); throw error;
  }
}

const ids = ['op:8:7', 'op:9:7', 'op:10:7', 'op:11:7', 'op:12:7'];
const canonical = new Map([
  ['op:8:7', 'stroke-v1'], ['op:9:7', 'shape-v1'],
  ['op:10:7', 'text-v1'], ['op:11:7', 'image-v1'], ['op:12:7', 'math-v1'],
]);
applyVisibility(20, ids, true, canonical);
assert.equal(db.prepare("SELECT revision FROM page WHERE id='p'").get().revision, 1);
assert.equal(db.prepare('SELECT COUNT(*) count FROM archive').get().count, 5);
assert.deepEqual(db.prepare('SELECT deleted,target_count,upload FROM operation').all()
  .map(row => ({ deleted: row.deleted, target_count: row.target_count, upload: row.upload })),
[{ deleted: 1, target_count: 5, upload: 1 }]);

applyVisibility(21, ids, false, canonical);
assert.equal(db.prepare("SELECT revision FROM page WHERE id='p'").get().revision, 2);
assert.deepEqual(db.prepare('SELECT id,payload FROM entity WHERE visible=1 ORDER BY z').all()
  .map(row => ({ id: row.id, payload: row.payload })), [
  { id: 'op:8:7', payload: 'stroke-v1' },
  { id: 'op:9:7', payload: 'shape-v1' },
  { id: 'op:10:7', payload: 'text-v1' },
  { id: 'op:11:7', payload: 'image-v1' },
  { id: 'op:12:7', payload: 'math-v1' },
]);

applyVisibility(22, ids, true, canonical);
const beforeFailure = JSON.stringify({
  page: db.prepare('SELECT * FROM page').all(),
  entity: db.prepare('SELECT * FROM entity ORDER BY z').all(),
  archive: db.prepare('SELECT * FROM archive ORDER BY z').all(),
  operation: db.prepare('SELECT * FROM operation ORDER BY identity').all(),
});
const tampered = new Map(canonical);
tampered.set('op:10:7', 'tampered-history-text');
assert.throws(() => applyVisibility(23, ids, false, tampered), /Expected values to be strictly equal/);
assert.equal(JSON.stringify({
  page: db.prepare('SELECT * FROM page').all(),
  entity: db.prepare('SELECT * FROM entity ORDER BY z').all(),
  archive: db.prepare('SELECT * FROM archive ORDER BY z').all(),
  operation: db.prepare('SELECT * FROM operation ORDER BY identity').all(),
}), beforeFailure);

db.prepare("UPDATE entity SET block_type=2 WHERE id='op:10:7'").run();
assert.throws(() => applyVisibility(24, ['op:10:7'], false, canonical),
  /Expected values to be strictly equal/);
db.close();

console.log('localBlockVisibility=type25-ink-shape-text-image-math-mixed-batch-state-type-' +
  'payload-preflight-single-revision-new-text-undo-redo-rollback');
