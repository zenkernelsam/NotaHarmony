import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const read = value => fs.readFileSync(new URL('../../../' + value, import.meta.url), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const originalU5j = fs.readFileSync(originalRoot + 'u5j.java', 'utf8');
const originalKgh = fs.readFileSync(originalRoot + 'kgh.java', 'utf8');
const originalLe8 = fs.readFileSync(originalRoot + 'le8.java', 'utf8');
const originalW4g = fs.readFileSync(originalRoot + 'w4g.java', 'utf8');
const originalU16 = fs.readFileSync(originalRoot + 'u16.java', 'utf8');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const persistence = read('note/src/main/ets/data/StrokePersistence.ets');
const encoder = read('note/src/main/ets/data/OriginalModifyShapePayloadEncoder.ets');
const reducer = read('note/src/main/ets/data/OriginalShapeGroupOperation.ets');
const history = read('note/src/main/ets/data/PersistentHistory.ets');
const model = read('note/src/main/ets/core/model/ElementTypes.ets');
const fixtures = read('note/src/test/OriginalCreateInkPayloadEncoder.test.ets');
const persistenceFixtures = read('note/src/test/StrokePersistence.test.ets');

assert.match(originalU5j,
  /r\(x09 x09Var, List list, cxc cxcVar, fqa fqaVar, k2d k2dVar, y2d y2dVar, t16 t16Var, hu1 hu1Var, Float f,[\s\S]*g2d g2dVar/);
assert.match(originalU5j,
  /o0j\.a\(list, cxcVar, fqaVar, k2dVar, y2dVar, t16Var, hu1Var, f,[\s\S]*g2dVar/);
assert.match(originalKgh, /public static g2d c\(hu1 hu1Var\)/);
assert.match(originalLe8, /color=" \+ l\(\) \+ ", borderWidth=" \+ k\(\) \+ ", fillColor=" \+ n\(\)/);
assert.match(originalLe8, /Modify shape with `fillColor: SetColor\(value: nil\)` to remove fill/);
assert.match(originalU16, /HIGHLIGHTER\(\(byte\) 2\)/);
assert.match(originalU16, /TAPE\(\(byte\) 3\)/);
assert.match(originalW4g, /Float\.valueOf\(0\.5f\)/);
assert.match(originalW4g, /Float\.valueOf\(64\.0f\)/);

assert.match(model, /originalTool\?: number/);
assert.match(canvas, /shape\.originalTool === undefined \? 0 : shape\.originalTool/);
assert.match(canvas, /const alpha: number = tool === 2 \? 107 : 255/);
assert.match(canvas, /replacement\.fillColor = replacement\.color/);
assert.match(canvas, /replacement\.strokeWidth = Math\.min\(maximum, Math\.max\(minimum, controlWidth\)\)/);
assert.match(canvas, /type: UndoableActionType\.TRANSFORM_ELEMENTS/);
assert.doesNotMatch(canvas,
  /replacement\.strokeWidth =[^;]*getPaperWidth\(\)[^;]*768/);
assert.match(persistence, /classifyOriginalRenderMutation/);
assert.match(persistence, /Map<string, OriginalShapeRenderMutationBatch>/);
assert.match(persistence, /expectedTools: number\[\]/);
assert.match(persistence, /SELECT resolved_payload FROM original_shape_state WHERE note_id/);
assert.match(persistence, /decodeOriginalShapeStateTool[\s\S]*!== batch\.expectedTools\[index\]/);
assert.match(persistence, /encodeOriginalShapeRenderRegisters\(batch\.identities, batch\)/);
assert.match(persistence, /OriginalShapeGroupOperationApplier/);
assert.match(persistence, /applyPositionPayload\([\s\S]*revisionBatch/);
assert.match(persistence, /await revisionBatch\.flush\(store, step\.noteId\)/);
assert.match(persistence, /OpType\.ORIGINAL_MODIFY_SHAPE/);
assert.match(encoder, /fields\[10\] = update\.color/);
assert.match(encoder, /fields\[11\] = update\.borderWidth/);
assert.match(encoder, /fields\[12\] = update\.fillColorPresent/);
assert.match(reducer, /ORIGINAL_MODIFY_SHAPE_PAYLOAD_TYPE: number = 19/);
assert.match(reducer, /originalTool: payload\.tool/);
assert.match(history, /OpType\.ORIGINAL_MODIFY_SHAPE/);
assert.match(fixtures, /round-trips original MODIFY_SHAPE color width and nullable fill registers/);
assert.match(persistenceFixtures, /strictly decodes the original Shape state tool preflight/);

const db = new DatabaseSync(':memory:');
db.exec(`CREATE TABLE shape(id TEXT PRIMARY KEY,tool TEXT,color INTEGER,width REAL,fill INTEGER);
  CREATE TABLE operation(seq INTEGER PRIMARY KEY AUTOINCREMENT,kind TEXT,targets TEXT,value TEXT);
  CREATE TABLE page(id INTEGER PRIMARY KEY,revision INTEGER NOT NULL);
  INSERT INTO page VALUES(1,0);
  INSERT INTO shape VALUES
    ('pen','pen',-16777216,3,NULL),
    ('pencil','pencil',-16777216,4,NULL),
    ('marker','highlighter',1795162112,12,1795162112),
    ('tape','tape',-16777216,8,NULL);`);

function tuple(row, kind, value) {
  if (kind === 'color') {
    const alpha = row.tool === 'highlighter' ? 107 : 255;
    const color = ((alpha << 24) | (value & 0x00ffffff)) | 0;
    return { color, width: null, fillPresent: row.tool === 'highlighter',
      fill: row.tool === 'highlighter' ? color : null };
  }
  const minimum = row.tool === 'tape' ? 2 : row.tool === 'pencil' ? 1 : 0.5;
  const maximum = row.tool === 'tape' ? 64 : row.tool === 'pencil' ? 10 : 30;
  return { color: null, width: Math.min(maximum, Math.max(minimum, value)),
    fillPresent: false, fill: null };
}

function command(kind, value, fail = false) {
  db.exec('BEGIN IMMEDIATE');
  try {
    const rows = db.prepare('SELECT * FROM shape ORDER BY id').all();
    const batches = new Map();
    for (const row of rows) {
      const update = tuple(row, kind, value);
      const key = JSON.stringify(update);
      const batch = batches.get(key) ?? { update, ids: [] };
      batch.ids.push(row.id);
      batches.set(key, batch);
    }
    for (const { update, ids } of batches.values()) {
      for (const id of ids) {
        if (update.color !== null) {
          db.prepare('UPDATE shape SET color=?,fill=CASE WHEN ? THEN ? ELSE fill END WHERE id=?')
            .run(update.color, update.fillPresent ? 1 : 0, update.fill, id);
        } else {
          db.prepare('UPDATE shape SET width=? WHERE id=?').run(update.width, id);
        }
      }
      db.prepare('INSERT INTO operation(kind,targets,value) VALUES(?,?,?)')
        .run('type-19-' + kind, JSON.stringify(ids), JSON.stringify(update));
    }
    // A mixed selection may also append type-17 batches before this shared flush.
    db.prepare("INSERT INTO operation(kind,targets,value) VALUES('type-17-ink','[\"ink\"]','mixed')").run();
    if (fail) throw new Error('injected mixed render batch failure');
    db.exec('UPDATE page SET revision=revision+1 WHERE id=1');
    db.exec('COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

command('color', 0x00112233);
assert.equal(db.prepare("SELECT color FROM shape WHERE id='marker'").get().color,
  ((107 << 24) | 0x112233) | 0);
assert.equal(db.prepare("SELECT fill FROM shape WHERE id='marker'").get().fill,
  ((107 << 24) | 0x112233) | 0);
assert.equal(db.prepare("SELECT color FROM shape WHERE id='pen'").get().color,
  ((255 << 24) | 0x112233) | 0);
assert.equal(db.prepare("SELECT fill FROM shape WHERE id='pen'").get().fill, null);
assert.equal(db.prepare('SELECT revision FROM page').get().revision, 1);

const oldWidths = db.prepare('SELECT id,width FROM shape ORDER BY id').all();
command('width', 40);
assert.equal(db.prepare("SELECT width FROM shape WHERE id='pen'").get().width, 30);
assert.equal(db.prepare("SELECT width FROM shape WHERE id='pencil'").get().width, 10);
assert.equal(db.prepare("SELECT width FROM shape WHERE id='marker'").get().width, 30);
assert.equal(db.prepare("SELECT width FROM shape WHERE id='tape'").get().width, 40);
assert.equal(db.prepare('SELECT revision FROM page').get().revision, 2);

const undoGroups = new Map();
for (const row of oldWidths) {
  const ids = undoGroups.get(row.width) ?? [];
  ids.push(row.id);
  undoGroups.set(row.width, ids);
}
assert.equal(undoGroups.size, 4);
for (const [width, ids] of undoGroups) {
  for (const id of ids) db.prepare('UPDATE shape SET width=? WHERE id=?').run(width, id);
}
assert.deepEqual(db.prepare('SELECT id,width FROM shape ORDER BY id').all(), oldWidths);

const beforeFailure = JSON.stringify({
  shapes: db.prepare('SELECT * FROM shape ORDER BY id').all(),
  operations: db.prepare('SELECT * FROM operation ORDER BY seq').all(),
  page: db.prepare('SELECT * FROM page').all(),
});
assert.throws(() => command('color', 0x00445566, true), /injected mixed render batch failure/);
assert.equal(JSON.stringify({
  shapes: db.prepare('SELECT * FROM shape ORDER BY id').all(),
  operations: db.prepare('SELECT * FROM operation ORDER BY seq').all(),
  page: db.prepare('SELECT * FROM page').all(),
}), beforeFailure);
db.close();

console.log('localModifyShapeColorWidth=type19-tool-alpha-fill-direct-width-mixed-type17-' +
  'tuple-batches-single-revision-undo-rollback');
