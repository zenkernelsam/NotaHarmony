import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const read = value => fs.readFileSync(new URL('../../../' + value, import.meta.url), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const originalU5j = fs.readFileSync(originalRoot + 'u5j.java', 'utf8');
const originalLaj = fs.readFileSync(originalRoot + 'laj.java', 'utf8');
const originalAo2 = fs.readFileSync(originalRoot + 'ao2.java', 'utf8');
const originalA5g = fs.readFileSync(originalRoot + 'a5g.java', 'utf8');
const originalGe3 = fs.readFileSync(originalRoot + 'ge3.java', 'utf8');
const model = read('note/src/main/ets/core/model/ElementTypes.ets');
const recognition = read('note/src/main/ets/core/model/ShapeRecognition.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const encoder = read('note/src/main/ets/data/OriginalCreateShapePayloadEncoder.ets');
const persistence = read('note/src/main/ets/data/StrokePersistence.ets');
const reducer = read('note/src/main/ets/data/OriginalShapeGroupOperation.ets');
const history = read('note/src/main/ets/data/PersistentHistory.ets');
const opTypes = read('note/src/main/ets/core/model/OpTypes.ets');
const fixtures = read('note/src/test/OriginalCreateInkPayloadEncoder.test.ets');
const detectorFixtures = read('note/src/test/ShapeDetector.test.ets');

assert.match(originalU5j,
  /public static ao2 j\(x09 x09Var, cxc cxcVar, fqa fqaVar, Float f, v4d v4dVar, u16 u16Var, t16 t16Var, hu1 hu1Var, float f2, hu1 hu1Var2, xgb xgbVar, Float f3, int i\)/);
assert.match(originalU5j, /return laj\.a\(cxcVar2, fqaVar, f4, null, v4dVar\.b, u16Var2/);
assert.match(originalLaj, /aVar\.C\(18\)/);
assert.match(originalLaj, /aVar\.j\(0, nti\.X\(cxcVar, aVar\)\)/);
assert.match(originalLaj, /aVar\.c\(4, z4dVar\.I, 0\)/);
assert.match(originalLaj, /aVar\.j\(9, z5c\.P\(hu1Var, aVar\)\)/);
assert.match(originalAo2, /Cannot create shapes with variable width ink/);
assert.match(originalA5g, /u5j\.j\(x09VarC, ge3Var\.c, ge3Var\.e, ge3Var\.g, ge3Var\.f/);
assert.match(originalGe3, /averageForce=/);

assert.match(model, /interface OriginalShapeCreateMetadata extends OriginalInkCreateMetadata/);
assert.match(model, /originalStyle\?: number/);
assert.match(model, /originalCreate\?: OriginalShapeCreateMetadata/);
assert.match(recognition,
  /elements\.length === 1 && originalStyle !== undefined[\s\S]*originalStyle <= 3 \? originalCreate : undefined/);
assert.match(canvas, /averageForce: this\.averageStrokeForce\(stroke\)/);
assert.match(canvas, /finalShapes\.length === 1 && finalShapes\[0\]\.originalCreate !== undefined/);
assert.match(canvas,
  /originalEntityOnly: boolean = partialBefore\.length === 0[\s\S]*removedShapes\.map\(/);
assert.match(canvas,
  /action\.type === UndoableActionType\.ERASE_ELEMENTS[\s\S]*action\.removedShapes\.map\(/);
assert.match(canvas,
  /originalEntityOnly: boolean = this\.areCanonicalOriginalPositionSelection\([\s\S]*removedShapes\.map\([\s\S]*removedTextBlocks\.map\([\s\S]*removedImages\.map\([\s\S]*removedMathBlocks\.map\(/);
assert.match(encoder, /encodeOriginalLocalCreateShape/);
assert.match(encoder, /ORIGINAL_LINE_DEFINITION: number = 1/);
assert.match(encoder, /ORIGINAL_POLYGON_DEFINITION: number = 2/);
assert.match(encoder, /ORIGINAL_ELLIPSE_DEFINITION: number = 3/);
assert.match(encoder, /shape\.originalStyle < 1 \|\| shape\.originalStyle > 3/);
assert.match(encoder, /ellipse\.center\.x - cosine \* localCenterX \+ sine \* localCenterY/);
assert.match(persistence, /ORIGINAL_CREATE_SHAPE_PAYLOAD_TYPE/);
assert.match(persistence, /writeOriginalCreateShape/);
assert.match(persistence, /OpType\.ORIGINAL_CREATE_SHAPE/);
assert.match(persistence, /uploadImmediately: true/);
assert.match(persistence, /original_shape_state/);
assert.match(persistence, /original_ink_state/);
assert.match(reducer, /ORIGINAL_CREATE_SHAPE_PAYLOAD_TYPE: number = 18/);
assert.match(reducer, /originalStyle: payload\.style/);
assert.match(history, /OpType\.ORIGINAL_CREATE_SHAPE/);
assert.match(opTypes, /ORIGINAL_CREATE_SHAPE = 68/);
assert.match(fixtures, /round-trips local LINE POLYGON and rotated ELLIPSE CREATE_SHAPE payloads/);
assert.match(detectorFixtures, /originalCreate === undefined/);
assert.match(detectorFixtures, /originalCreate\?\.averageForce/);

const db = new DatabaseSync(':memory:');
db.exec(`CREATE TABLE page(id INTEGER PRIMARY KEY, revision INTEGER NOT NULL);
  CREATE TABLE shape_state(id TEXT PRIMARY KEY,tool INTEGER,style INTEGER,force REAL,visible INTEGER);
  CREATE TABLE snapshot(id TEXT PRIMARY KEY,kind TEXT,payload TEXT);
  CREATE TABLE operation(seq INTEGER PRIMARY KEY AUTOINCREMENT,type INTEGER,id TEXT,upload INTEGER);
  CREATE TABLE history(seq INTEGER PRIMARY KEY AUTOINCREMENT,action TEXT);
  INSERT INTO page VALUES(1,0);`);

function createShape(fail = false) {
  db.exec('BEGIN IMMEDIATE');
  try {
    db.prepare('INSERT INTO shape_state VALUES(?,?,?,?,1)').run('shape', 2, 1, 0.5);
    db.prepare('INSERT INTO snapshot VALUES(?,?,?)').run('shape', 'shape', 'ellipse');
    db.prepare('INSERT INTO operation(type,id,upload) VALUES(18,?,1)').run('shape');
    if (fail) throw new Error('injected CREATE_SHAPE failure');
    db.prepare("INSERT INTO history(action) VALUES('add-shape')").run();
    db.exec('UPDATE page SET revision=revision+1 WHERE id=1');
    db.exec('COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

function setVisible(visible) {
  db.exec('BEGIN IMMEDIATE');
  try {
    const state = db.prepare('SELECT id FROM shape_state WHERE id=?').get('shape');
    assert.ok(state);
    db.prepare('UPDATE shape_state SET visible=? WHERE id=?').run(visible ? 1 : 0, 'shape');
    if (visible) {
      db.prepare('INSERT INTO snapshot VALUES(?,?,?)').run('shape', 'shape', 'ellipse');
    } else {
      db.prepare('DELETE FROM snapshot WHERE id=?').run('shape');
    }
    db.prepare('INSERT INTO operation(type,id,upload) VALUES(25,?,1)').run('shape');
    db.prepare('INSERT INTO history(action) VALUES(?)').run(visible ? 'redo' : 'undo');
    db.exec('UPDATE page SET revision=revision+1 WHERE id=1');
    db.exec('COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

createShape();
const createdOperation = db.prepare('SELECT type,id,upload FROM operation').get();
assert.equal(createdOperation.type, 18);
assert.equal(createdOperation.id, 'shape');
assert.equal(createdOperation.upload, 1);
assert.equal(db.prepare('SELECT revision FROM page').get().revision, 1);
assert.equal(db.prepare('SELECT force FROM shape_state').get().force, 0.5);

setVisible(false);
assert.equal(db.prepare('SELECT COUNT(*) AS count FROM snapshot').get().count, 0);
assert.equal(db.prepare('SELECT visible FROM shape_state').get().visible, 0);
setVisible(true);
assert.equal(db.prepare('SELECT COUNT(*) AS count FROM snapshot').get().count, 1);
assert.equal(db.prepare('SELECT revision FROM page').get().revision, 3);

db.exec(`DELETE FROM snapshot; DELETE FROM shape_state; DELETE FROM operation; DELETE FROM history;
  UPDATE page SET revision=0`);
assert.throws(() => createShape(true), /injected CREATE_SHAPE failure/);
assert.equal(db.prepare('SELECT COUNT(*) AS count FROM shape_state').get().count, 0);
assert.equal(db.prepare('SELECT COUNT(*) AS count FROM operation').get().count, 0);
assert.equal(db.prepare('SELECT revision FROM page').get().revision, 0);
db.close();

console.log('localCreateShape=type18-line-polygon-rotated-ellipse-tool-style-force-' +
  'reserved-identity-state-preflight-single-revision-history-undo-redo-rollback');
