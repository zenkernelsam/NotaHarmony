import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const read = value => fs.readFileSync(new URL('../../../' + value, import.meta.url), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const originalWj9 = fs.readFileSync(originalRoot + 'wj9.java', 'utf8');
const originalDhb = fs.readFileSync(originalRoot + 'dhb.java', 'utf8');
const originalU5j = fs.readFileSync(originalRoot + 'u5j.java', 'utf8');
const originalO0j = fs.readFileSync(originalRoot + 'o0j.java', 'utf8');
const originalW4g = fs.readFileSync(originalRoot + 'w4g.java', 'utf8');
const originalAa6 = fs.readFileSync(originalRoot + 'aa6.java', 'utf8');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const toolbar = read('note/src/main/ets/ui/editor/EditorToolbar.ets');
const page = read('note/src/main/ets/ui/editor/NotePage.ets');
const persistence = read('note/src/main/ets/data/StrokePersistence.ets');
const encoder = read('note/src/main/ets/data/OriginalModifyInkPayloadEncoder.ets');
const fixtures = read('note/src/test/OriginalCreateInkPayloadEncoder.test.ets');
const pencilGeometry = read('note/src/main/ets/core/adaptation/OriginalPencilWidthGeometry.ets');
const pencilFixtures = read('note/src/test/PencilSplatGenerator.test.ets');

assert.match(originalWj9, /new zn3\(xscVar, setH, j, null\)/);
assert.match(originalWj9, /new zh9\(xscVar2, \(Set\) obj2, \(iu1\) obj, null, 26\)/);
assert.match(originalDhb, /new ks0\(xscVar2, set2, fFloatValue, \(ef2\) null, 4\)/);
assert.match(originalU5j, /o0j\.a\(arrayList[\s\S]*t16Var2, hu1Var2, f2/);
assert.match(originalO0j, /aVarA\.j\(6, z5c\.P\(hu1Var, aVarA\)\)/);
assert.match(originalO0j, /aVarA\.d\(7, f\.floatValue\(\), 0\.0d\)/);
assert.match(originalW4g, /Float\.valueOf\(0\.5f\)/);
assert.match(originalW4g, /Float\.valueOf\(30\.0f\)/);
assert.match(originalAa6, /fE0\.floatValue\(\)\) \/ 768\.0d/);

assert.match(toolbar, /supportsBrushControls\(\) \|\| this\.viewModel\.isSelectionActive\(\)/);
assert.match(toolbar, /onSelectionColor/);
assert.match(toolbar, /onSelectionWidth/);
assert.match(toolbar, /selectionMaximum: this\.selectionWidthMaximum/);
assert.match(page, /selectionColorSignal\+\+/);
assert.match(page, /selectionWidthSignal\+\+/);
assert.match(canvas, /stroke\.renderSpec\.isHighlighter \? 107 : 255/);
assert.match(canvas, /bounded \* this\.getPaperWidth\(\) \/ 768/);
assert.match(canvas, /stroke\.renderSpec\.isPencil \? 1 : 0\.5/);
assert.match(canvas, /selectedMaximum = tape \? 64 : stroke\.renderSpec\.isPencil \? 10 : 30/);
assert.match(canvas, /rebuildOriginalPencilWidth\(\s*stroke, persistedWidth\)/);
assert.match(canvas, /type: UndoableActionType\.TRANSFORM_STROKES/);
assert.match(persistence, /Map<string, OriginalInkRenderMutationBatch>/);
assert.match(persistence, /styleMap: styleUpdated \? \[\] : before\.styleMap/);
assert.match(persistence, /pencilWidth = rebuildOriginalPencilWidth\(before, after\.renderSpec\.brushWidth\)/);
assert.match(persistence, /applyPositionPayload\([\s\S]*revisionBatch/);
assert.match(persistence, /await revisionBatch\.flush\(store, step\.noteId\)/);
assert.match(encoder, /styleMapVector: number = update\.style === null \? 0/);
assert.match(fixtures, /keeps style-map absent for original color-only and width-only updates/);
assert.match(pencilGeometry, /ORIGINAL_PENCIL_WIDTH_MULTIPLIER: number = 2\.84/);
assert.match(pencilGeometry, /generator\.generate\(\s*stroke\.cubicSegments, stroke\.pathPoints/);
assert.match(pencilGeometry, /recoverQuadraticControl/);
assert.match(pencilFixtures, /rebuilds an original Pencil snapshot for a local width register update/);

const db = new DatabaseSync(':memory:');
db.exec(`CREATE TABLE ink(id TEXT PRIMARY KEY,tool TEXT,color INTEGER,width REAL);
  CREATE TABLE operation(seq INTEGER PRIMARY KEY AUTOINCREMENT,kind TEXT,targets TEXT,value TEXT);
  CREATE TABLE page(id INTEGER PRIMARY KEY,revision INTEGER NOT NULL);
  INSERT INTO page VALUES(1,0);
  INSERT INTO ink VALUES
    ('pen','pen',-16777216,4),('pencil','pencil',-16777216,4),
    ('marker','highlighter',1795162112,12),('tape','tape',-16777216,8);`);

function command(kind, value, fail = false) {
  db.exec('BEGIN IMMEDIATE');
  try {
    const rows = db.prepare('SELECT * FROM ink ORDER BY id').all();
    const batches = new Map();
    for (const row of rows) {
      let target;
      if (kind === 'color') {
        const alpha = row.tool === 'highlighter' ? 107 : 255;
        target = ((alpha << 24) | (value & 0x00ffffff)) | 0;
      } else {
        const min = row.tool === 'tape' ? 2 : row.tool === 'pencil' ? 1 : 0.5;
        const max = row.tool === 'tape' ? 64 : row.tool === 'pencil' ? 10 : 30;
        target = Math.min(max, Math.max(min, value)) * 800 / 768;
      }
      const key = String(target);
      const ids = batches.get(key) ?? [];
      ids.push(row.id);
      batches.set(key, ids);
    }
    for (const [target, ids] of batches) {
      const update = db.prepare(`UPDATE ink SET ${kind}=? WHERE id=?`);
      for (const id of ids) update.run(Number(target), id);
      db.prepare('INSERT INTO operation(kind,targets,value) VALUES(?,?,?)')
        .run(kind, JSON.stringify(ids), target);
    }
    if (fail) throw new Error('injected batch failure');
    db.prepare("INSERT INTO operation(kind,targets,value) VALUES('history','[]','1')").run();
    db.exec('UPDATE page SET revision=revision+1 WHERE id=1');
    db.exec('COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

command('color', 0x00112233);
assert.equal(db.prepare("SELECT count(*) count FROM operation WHERE kind='color'").get().count, 2);
assert.equal(db.prepare('SELECT revision FROM page WHERE id=1').get().revision, 1);
assert.equal(db.prepare("SELECT color FROM ink WHERE id='marker'").get().color,
  ((107 << 24) | 0x112233) | 0);
assert.equal(db.prepare("SELECT color FROM ink WHERE id='pen'").get().color,
  ((255 << 24) | 0x112233) | 0);
const oldWidths = db.prepare('SELECT id,width FROM ink ORDER BY id').all();
command('width', 40);
assert.equal(db.prepare("SELECT width FROM ink WHERE id='pen'").get().width, 30 * 800 / 768);
assert.equal(db.prepare("SELECT width FROM ink WHERE id='pencil'").get().width, 10 * 800 / 768);
assert.equal(db.prepare("SELECT width FROM ink WHERE id='tape'").get().width, 40 * 800 / 768);
assert.equal(db.prepare('SELECT revision FROM page WHERE id=1').get().revision, 2);

db.exec('BEGIN IMMEDIATE');
const undoBatches = new Map();
for (const row of oldWidths) {
  const ids = undoBatches.get(row.width) ?? [];
  ids.push(row.id);
  undoBatches.set(row.width, ids);
}
for (const [width, ids] of undoBatches) {
  for (const id of ids) db.prepare('UPDATE ink SET width=? WHERE id=?').run(width, id);
  db.prepare("INSERT INTO operation(kind,targets,value) VALUES('width-undo',?,?)")
    .run(JSON.stringify(ids), width);
}
db.exec('UPDATE page SET revision=revision+1 WHERE id=1');
db.exec('COMMIT');
assert.equal(undoBatches.size, 3);
assert.deepEqual(db.prepare('SELECT id,width FROM ink ORDER BY id').all(), oldWidths);
assert.equal(db.prepare('SELECT revision FROM page WHERE id=1').get().revision, 3);
const beforeFailure = JSON.stringify({
  ink: db.prepare('SELECT * FROM ink ORDER BY id').all(),
  operations: db.prepare('SELECT * FROM operation ORDER BY seq').all(),
  page: db.prepare('SELECT * FROM page').all(),
});
assert.throws(() => command('color', 0x00445566, true), /injected batch failure/);
assert.equal(JSON.stringify({
  ink: db.prepare('SELECT * FROM ink ORDER BY id').all(),
  operations: db.prepare('SELECT * FROM operation ORDER BY seq').all(),
  page: db.prepare('SELECT * FROM page').all(),
}), beforeFailure);
db.close();

console.log('localModifyInkColorWidth=alpha-width-scale-pencil-rebuild-multibatch-' +
  'single-revision-undo-rollback');
