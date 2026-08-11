import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const read = value => fs.readFileSync(new URL('../../../' + value, import.meta.url), 'utf8');
const originalTi9 = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/ti9.java', 'utf8');
const originalZh9 = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/zh9.java', 'utf8');
const originalU5j = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/u5j.java', 'utf8');
const encoder = read('note/src/main/ets/data/OriginalModifyInkPayloadEncoder.ets');
const persistence = read('note/src/main/ets/data/StrokePersistence.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const toolbar = read('note/src/main/ets/ui/editor/EditorToolbar.ets');
const history = read('note/src/main/ets/data/PersistentHistory.ets');
const tests = read('note/src/test/OriginalCreateInkPayloadEncoder.test.ets');

assert.match(originalTi9, /rh9Var instanceof zg9/);
assert.match(originalZh9, /s06VarX\.k != u16Var/);
assert.match(originalZh9, /u5j\.q\(x09VarN3, arrayList, null, null, l2f\.a\(y31Var\), 28670\)/);
assert.match(originalU5j, /t16Var2 != null \? hw3\.I : null/);
assert.match(encoder, /fields\[0\] = 4/);
assert.match(encoder, /fields\[5\]/);
assert.match(encoder, /fields\[6\]/);
assert.match(encoder, /fields\[7\]/);
assert.match(encoder, /fields\[12\]/);
assert.match(persistence, /classifyOriginalRenderMutation/);
assert.match(persistence, /applyOriginalRenderStyle/);
assert.match(persistence, /applier\.applyPositionPayload\(/);
assert.match(persistence, /await revisionBatch\.flush\(store, step\.noteId\)/);
assert.match(persistence, /OpType\.ORIGINAL_MODIFY_INK/);
assert.match(canvas, /modifySelectedInkStyle/);
assert.match(canvas, /stroke\.renderSpec\.isPencil/);
assert.match(canvas, /replacement\.styleMap = \[\]/);
assert.match(canvas, /type: UndoableActionType\.TRANSFORM_STROKES/);
assert.match(canvas, /originalCreate: s\.originalCreate/);
assert.match(toolbar, /SelectionStyleButton/);
assert.match(history, /OpType\.ORIGINAL_MODIFY_INK/);
assert.match(tests, /round-trips batched original MODIFY_INK render registers/);

const db = new DatabaseSync(':memory:');
db.exec(`CREATE TABLE ink(id TEXT PRIMARY KEY,style INTEGER,style_map TEXT);
  CREATE TABLE operations(seq INTEGER PRIMARY KEY AUTOINCREMENT,kind TEXT,targets TEXT,style INTEGER);
  INSERT INTO ink VALUES('op:1:7',1,'phase'),('op:2:7',3,'phase');`);

function modify(ids, style, fail = false) {
  db.exec('BEGIN IMMEDIATE');
  try {
    const update = db.prepare('UPDATE ink SET style=?,style_map=? WHERE id=?');
    for (const id of ids) update.run(style, '[]', id);
    db.prepare('INSERT INTO operations(kind,targets,style) VALUES(?,?,?)')
      .run('MODIFY_INK', JSON.stringify(ids), style);
    if (fail) throw new Error('injected modify failure');
    db.prepare('INSERT INTO operations(kind,targets,style) VALUES(?,?,?)')
      .run('HISTORY', JSON.stringify(ids), style);
    db.exec('COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

modify(['op:1:7', 'op:2:7'], 2);
assert.deepEqual(db.prepare('SELECT style,style_map FROM ink ORDER BY id').all().map(row => ({ ...row })), [
  { style: 2, style_map: '[]' }, { style: 2, style_map: '[]' },
]);
assert.equal(db.prepare(`SELECT count(*) count FROM operations WHERE kind='MODIFY_INK'`).get().count, 1);
const beforeFailure = JSON.stringify({
  ink: db.prepare('SELECT * FROM ink ORDER BY id').all(),
  operations: db.prepare('SELECT * FROM operations ORDER BY seq').all(),
});
assert.throws(() => modify(['op:1:7', 'op:2:7'], 0, true), /injected modify failure/);
assert.equal(JSON.stringify({
  ink: db.prepare('SELECT * FROM ink ORDER BY id').all(),
  operations: db.prepare('SELECT * FROM operations ORDER BY seq').all(),
}), beforeFailure);
db.close();

console.log('localModifyInkStyle=original-batch-style-map-history-rollback');
