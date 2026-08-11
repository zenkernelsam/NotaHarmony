import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const dhb = fs.readFileSync(`${originalRoot}dhb.java`, 'utf8');
const u5j = fs.readFileSync(`${originalRoot}u5j.java`, 'utf8');
const td8 = fs.readFileSync(`${originalRoot}td8.java`, 'utf8');
const rl2 = fs.readFileSync(`${originalRoot}rl2.java`, 'utf8');
const encoder = read('note/src/main/ets/data/OriginalModifyBlockPayloadEncoder.ets');
const persistence = read('note/src/main/ets/data/StrokePersistence.ets');
const reducer = read('note/src/main/ets/data/OriginalModifyBlockOperation.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const overlay = read('note/src/main/ets/ui/components/SelectionOverlay.ets');
const history = read('note/src/main/ets/data/PersistentHistory.ets');
const tests = read('note/src/test/OriginalModifyBlockPayloadEncoder.test.ets');

assert.match(dhb, /new mub\(xscVar, ktcVar\.h\(\), tk4\.I, cg2Var, 5\)/);
assert.match(dhb, /new mub\(xscVar, ktcVar\.h\(\), tk4\.J, cg2Var, 5\)/);
assert.match(u5j, /aVarA\.C\(18\)/);
assert.match(u5j, /aVarA\.a\(14, bool2\.booleanValue\(\), false\)/);
assert.match(u5j, /aVarA\.a\(15, bool3\.booleanValue\(\), false\)/);
assert.match(td8, /imageFlippedHorizontally=/);
assert.match(td8, /imageFlippedVertically=/);
assert.match(rl2, /Cannot flip non-Image Block/);

assert.match(encoder, /fields\[12\] = cropRect === null \? 0 : 8/);
assert.match(encoder, /fields\[14\] = horizontal === null \? 0 : 12/);
assert.match(encoder, /fields\[15\] = vertical === null \? 0 : 13/);
assert.match(encoder, /bytes\[table \+ 12\] = horizontal \? 1 : 0/);
assert.match(encoder, /writeF32\(bytes, cropTable \+ 16, cropRect\.height\)/);
assert.match(persistence, /classifyOriginalImageFlipMutation/);
assert.match(persistence, /reflectImageCropRect/);
assert.match(persistence, /for \(const update of mutation\.updates\)/);
assert.match(persistence, /applyBatchedPayload/);
assert.match(persistence, /await revisionBatch\.flush\(store, step\.noteId\)/);
assert.match(persistence, /opType: OpType\.ORIGINAL_MODIFY_BLOCK/);
assert.match(reducer, /async applyBatchedPayload/);
assert.match(canvas, /replacement\.imageFlippedHorizontally = !replacement\.imageFlippedHorizontally/);
assert.match(canvas, /replacement\.cropRect = reflectImageCropRect/);
assert.doesNotMatch(canvas, /const flip: number\[\] = horizontal/);
assert.match(overlay, /if \(this\.canFlip\)/);
assert.match(history, /OpType\.ORIGINAL_MODIFY_POSITIONS/);
assert.match(history, /OpType\.ORIGINAL_MODIFY_BLOCK/);
assert.match(tests, /explicit false presence/);

const db = new DatabaseSync(':memory:');
db.exec(`CREATE TABLE image(id TEXT PRIMARY KEY,h INTEGER,v INTEGER,crop_x REAL,crop_y REAL,
  crop_w REAL,crop_h REAL,intrinsic_w REAL,intrinsic_h REAL);
  CREATE TABLE page(id TEXT PRIMARY KEY,revision INTEGER);
  CREATE TABLE operation_log(sequence INTEGER PRIMARY KEY AUTOINCREMENT,target TEXT,
    op_type INTEGER,payload_type INTEGER,upload_immediately INTEGER,h INTEGER,v INTEGER);
  INSERT INTO page VALUES('p1',10);
  INSERT INTO image VALUES('i1',0,0,20,10,80,40,200,100);
  INSERT INTO image VALUES('i2',1,0,NULL,NULL,NULL,NULL,300,200);`);

function flip(ids, horizontal, failAt = -1) {
  db.exec('BEGIN');
  try {
    for (let index = 0; index < ids.length; index++) {
      const row = db.prepare('SELECT * FROM image WHERE id=?').get(ids[index]);
      if (row === undefined) throw new Error('missing image');
      const h = horizontal ? Number(!row.h) : row.h;
      const v = horizontal ? row.v : Number(!row.v);
      let x = row.crop_x;
      let y = row.crop_y;
      if (x !== null) {
        if (horizontal) x = row.intrinsic_w - (row.crop_x + row.crop_w);
        else y = row.intrinsic_h - (row.crop_y + row.crop_h);
      }
      db.prepare('UPDATE image SET h=?,v=?,crop_x=?,crop_y=? WHERE id=?')
        .run(h, v, x, y, ids[index]);
      db.prepare(`INSERT INTO operation_log(target,op_type,payload_type,upload_immediately,h,v)
        VALUES(?,66,23,1,?,?)`).run(ids[index], horizontal ? h : null, horizontal ? null : v);
      if (index === failAt) throw new Error('injected flip failure');
    }
    db.prepare('UPDATE page SET revision=revision+1 WHERE id=?').run('p1');
    db.exec('COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

flip(['i1', 'i2'], true);
let rows = db.prepare('SELECT * FROM image ORDER BY id').all();
assert.equal(rows[0].h, 1);
assert.equal(rows[0].crop_x, 100);
assert.equal(rows[1].h, 0, 'mixed initial values must toggle per image');
assert.equal(db.prepare('SELECT revision FROM page').get().revision, 11,
  'multi-operation flip advances the Harmony page revision once');
assert.equal(db.prepare('SELECT count(*) count FROM operation_log').get().count, 2);
assert.equal(db.prepare(`SELECT count(*) count FROM operation_log WHERE op_type=66 AND payload_type=23
  AND upload_immediately=1`).get().count, 2);
const beforeFailure = JSON.stringify(rows);
assert.throws(() => flip(['i1', 'missing'], false), /missing image/);
rows = db.prepare('SELECT * FROM image ORDER BY id').all();
assert.equal(JSON.stringify(rows), beforeFailure);
assert.equal(db.prepare('SELECT count(*) count FROM operation_log').get().count, 2);
db.close();

console.log('localImageFlip=singleton-modify-block-per-image-crop-reflection-batched-revision-rollback');
