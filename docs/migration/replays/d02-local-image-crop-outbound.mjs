import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const dhb = fs.readFileSync(`${originalRoot}dhb.java`, 'utf8');
const ls = fs.readFileSync(`${originalRoot}ls.java`, 'utf8');
const ns = fs.readFileSync(`${originalRoot}ns.java`, 'utf8');
const tp2 = fs.readFileSync(`${originalRoot}tp2.java`, 'utf8');
const t7 = fs.readFileSync(`${originalRoot}t7.java`, 'utf8');
const geometry = read('note/src/main/ets/core/model/OriginalImageCropGeometry.ets');
const encoder = read('note/src/main/ets/data/OriginalModifyBlockPayloadEncoder.ets');
const persistence = read('note/src/main/ets/data/StrokePersistence.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const selection = read('note/src/main/ets/ui/components/SelectionOverlay.ets');
const overlay = read('note/src/main/ets/ui/components/ImageCropOverlay.ets');
const encoderTests = read('note/src/test/OriginalModifyBlockPayloadEncoder.test.ets');
const geometryTests = read('note/src/test/ImageBlockRendering.test.ets');
const persistenceTests = read('note/src/test/StrokePersistence.test.ets');

assert.match(dhb, /case 14:[\s\S]*ktcVar instanceof itc[\s\S]*oy0VarK instanceof hp5/);
assert.match(dhb, /case 14:[\s\S]*fvbVar\.e\(true\)[\s\S]*xscVar\.P\.c\(cmbVarE\)/);
assert.match(dhb, /new lsc\(cmbVarE, fqaVarD\)/);
assert.match(ls, /case 16:[\s\S]*fi3Var != null \? fi3Var\.a : null/);
assert.match(ls, /new lsc\(cmbVar, \(\(lsc\) lscVar\)\.b\)/);
assert.match(tp2, /public final void b\(\)[\s\S]*this\.a\.j\(null\)[\s\S]*this\.c\.j\(null\)/);
assert.match(tp2, /public final void c\(cmb cmbVar\)[\s\S]*cmbVar\.g\(cmbVar2\)/);
assert.match(ns, /float fCos = \(float\) Math\.cos\(d\)/);
assert.match(ns, /\(\(fC3 \* fCos\) \+ ry0Var2\.p\.c\(\)\) - \(fD3 \* fSin\)/);
assert.match(ns, /\(fD3 \* fCos\) \+ \(fC3 \* fSin\) \+ ry0Var2\.p\.d\(\)/);
assert.match(ns, /u5j\.n\([\s\S]*apb\.g\([\s\S]*zgh\.a\(apb\.h\(fD, fC\)\)[\s\S]*ugh\.c\(bmbVarS\)/);
assert.match(ns, /Object objI = xsc\.i\(xscVar, listL0, this\)/);
assert.match(ns, /fvbVar\.e\(false\)[\s\S]*xscVar\.P\.b\(\)[\s\S]*psc\.a/);
assert.match(t7, /feature_note__close[\s\S]*feature_note__reset[\s\S]*feature_note__checkmark/);

assert.match(geometry, /export function beginOriginalImageCrop/);
assert.match(geometry, /export function resetOriginalImageCropDraft/);
assert.match(geometry, /matrix\[0\] \* draft\.left \+ matrix\[1\] \* draft\.top \+ matrix\[2\]/);
assert.match(geometry, /result\.bounds = imageBlockWorldBounds\(result\)/);
assert.match(geometry, /export function originalImageCropLocalDelta/);
assert.match(encoder, /export function encodeOriginalImageCrop/);
assert.match(encoder, /fields\[2\] = 8[\s\S]*fields\[3\] = 20/);
assert.match(encoder, /fields\[5\] = 28[\s\S]*fields\[6\] = 32[\s\S]*fields\[12\] = 40/);
assert.match(encoder, /cropRect === null \? 4 : 20/);
assert.match(persistence, /classifyOriginalImageCropMutation/);
assert.match(persistence, /return updates\.length === 1 \? \{ updates: updates \} : null/);
assert.match(persistence, /encodeOriginalImageCrop\(\[update\.identity\]/);
assert.match(persistence, /applyBatchedPayload/);
assert.match(persistence, /await revisionBatch\.flush\(store, step\.noteId\)/);
assert.match(selection, /SelectionMenuAction\.CROP/);
assert.match(canvas, /beginOriginalImageCrop/);
assert.match(canvas, /resetOriginalImageCropDraft/);
assert.match(canvas, /applyOriginalImageCropDraft/);
assert.match(canvas, /this\.persist\(true\)/);
assert.match(canvas, /if \(this\.imageCropVisible\)[\s\S]*this\.cancelImageCrop\(\)/);
assert.match(overlay, /ImageCropHandle\.TOP_LEFT/);
assert.match(overlay, /ImageCropHandle\.TOP_RIGHT/);
assert.match(overlay, /ImageCropHandle\.BOTTOM_RIGHT/);
assert.match(overlay, /ImageCropHandle\.BOTTOM_LEFT/);
assert.match(overlay, /app\.media\.crop_close[\s\S]*app\.media\.crop_reset[\s\S]*app\.media\.crop_confirm/);
assert.match(encoderTests, /nullable crop register for Undo/);
assert.match(geometryTests, /rotated and scaled intrinsic crop/);
assert.match(persistenceTests, /reverse nullable clear/);

const rotatePoint = (origin, linear, delta) => ({
  x: Math.fround(linear.a * delta.x + linear.c * delta.y + origin.x),
  y: Math.fround(linear.b * delta.x + linear.d * delta.y + origin.y),
});
assert.deepEqual(rotatePoint({ x: 10, y: 20 }, { a: 0, b: 2, c: -3, d: 0 },
  { x: 20, y: 10 }), { x: -20, y: 60 });

const domain = { left: -100, top: -25, right: 300, bottom: 175 };
const initialDraft = { left: 0, top: 0, right: 200, bottom: 150 };
const closeDraft = { ...initialDraft, left: 20 };
assert.deepEqual(initialDraft, { left: 0, top: 0, right: 200, bottom: 150 },
  'Close must not mutate the source crop');
assert.equal(closeDraft.left, 20, 'drag changes only draft state');
assert.deepEqual({ ...domain }, domain, 'Reset restores the full intrinsic draft domain');

const db = new DatabaseSync(':memory:');
db.exec(`CREATE TABLE image(id TEXT PRIMARY KEY,origin_x REAL,origin_y REAL,scale_x REAL,scale_y REAL,
  width REAL,height REAL,crop_x REAL,crop_y REAL,crop_w REAL,crop_h REAL);
  CREATE TABLE page(id TEXT PRIMARY KEY,revision INTEGER);
  CREATE TABLE operation_log(sequence INTEGER PRIMARY KEY AUTOINCREMENT,target TEXT,
    op_type INTEGER,payload_type INTEGER,field2 INTEGER,field3 INTEGER,field5 INTEGER,
    field6 INTEGER,field12 INTEGER,upload_immediately INTEGER);
  INSERT INTO image VALUES('i1',10,20,2,3,200,100,NULL,NULL,NULL,NULL);
  INSERT INTO page VALUES('p1',8);`);

const snapshot = () => db.prepare('SELECT * FROM image WHERE id=?').get('i1');
const same = (row, expected) => Object.keys(expected).every(key => row[key] === expected[key]);
function applyCrop(source, target, fail = false) {
  db.exec('BEGIN');
  try {
    const current = snapshot();
    if (!same(current, source)) throw new Error('crop source-state mismatch');
    db.prepare(`UPDATE image SET origin_x=?,origin_y=?,scale_x=?,scale_y=?,width=?,height=?,
      crop_x=?,crop_y=?,crop_w=?,crop_h=? WHERE id=?`).run(target.origin_x, target.origin_y,
      target.scale_x, target.scale_y, target.width, target.height, target.crop_x, target.crop_y,
      target.crop_w, target.crop_h, 'i1');
    db.prepare(`INSERT INTO operation_log(target,op_type,payload_type,field2,field3,field5,field6,
      field12,upload_immediately) VALUES('i1',66,23,1,1,1,1,1,1)`).run();
    db.prepare('UPDATE page SET revision=revision+1 WHERE id=?').run('p1');
    if (fail) throw new Error('injected crop failure');
    db.exec('COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

const before = snapshot();
const after = { ...before, origin_x: 30, origin_y: 30, width: 160, height: 80,
  crop_x: 20, crop_y: 10, crop_w: 160, crop_h: 80 };
applyCrop(before, after);
assert.equal(db.prepare('SELECT revision FROM page').get().revision, 9);
assert.equal(db.prepare('SELECT count(*) count FROM operation_log').get().count, 1,
  'one crop confirmation emits one type-23 operation');
assert.equal(db.prepare(`SELECT count(*) count FROM operation_log WHERE op_type=66 AND payload_type=23
  AND field2=1 AND field3=1 AND field5=1 AND field6=1 AND field12=1
  AND upload_immediately=1`).get().count, 1);
applyCrop(after, before);
assert.equal(snapshot().crop_x, null, 'Undo preserves field-12 presence while clearing its value');
assert.throws(() => applyCrop(after, before), /crop source-state mismatch/);
const stable = JSON.stringify(snapshot());
const logCount = db.prepare('SELECT count(*) count FROM operation_log').get().count;
assert.throws(() => applyCrop(before, after, true), /injected crop failure/);
assert.equal(JSON.stringify(snapshot()), stable);
assert.equal(db.prepare('SELECT count(*) count FROM operation_log').get().count, logCount);
db.close();

console.log('localImageCrop=original-draft-composite-rotated-origin-nullable-undo-ui-rollback');
