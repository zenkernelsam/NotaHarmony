import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const avc = fs.readFileSync(`${originalRoot}avc.java`, 'utf8');
const u5j = fs.readFileSync(`${originalRoot}u5j.java`, 'utf8');
const x0j = fs.readFileSync(`${originalRoot}x0j.java`, 'utf8');
const w0j = fs.readFileSync(`${originalRoot}w0j.java`, 'utf8');
const encoder = read('note/src/main/ets/data/OriginalModifyPositionsPayloadEncoder.ets');
const persistence = read('note/src/main/ets/data/StrokePersistence.ets');
const reducer = read('note/src/main/ets/data/OriginalModifyPositionsOperation.ets');
const inkReducer = read('note/src/main/ets/data/OriginalModifyInkOperation.ets');
const blockReducer = read('note/src/main/ets/data/OriginalModifyBlockOperation.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const selection = read('note/src/main/ets/rendering/SelectionTool.ets');
const tests = read('note/src/test/OriginalCreateInkPayloadEncoder.test.ets');
const history = read('note/src/main/ets/data/PersistentHistory.ets');

for (const method of ['t', 'l', 'o', 'p', 'q']) {
  assert.match(avc, new RegExp(`avcVar\\.${method}\\(`));
}
assert.match(avc, /if \(je8VarQ\.j\(\) > 0\)[\s\S]*new wq9\(je8VarQ, null, false/);
assert.match(u5j, /je8 v\(x09 x09Var, List list\)[\s\S]*x0j\.a\(list, true\)/);
assert.match(x0j, /new q5\(24, \(ie8\)/);
assert.match(w0j, /aVar\.C\(6\)/);
assert.match(w0j, /aVar\.j\(0, rh8\.O\(qo5Var, aVar\)\)/);
assert.match(w0j, /aVar\.j\(1, nti\.X\(cxcVar, aVar\)\)/);
assert.match(w0j, /aVar\.j\(2, apb\.Y\(fqaVar, aVar\)\)/);
assert.match(w0j, /aVar\.h\(3, numValueOf\.intValue\(\)\)/);
assert.match(w0j, /aVar\.h\(4, numValueOf2\.intValue\(\)\)/);
assert.match(w0j, /aVar\.f\(5, tmfVar\.I\)/);

assert.match(encoder, /writeVtable\(bytes, layout\.vtable, 48/);
assert.match(encoder, /modification\.rotation\.value === null \? 0 : 4/);
assert.match(encoder, /modification\.scale\.value === null \? 0 : 4/);
assert.match(encoder, /writeUint64Decimal\(bytes, layout\.table \+ 40/);
assert.match(persistence, /originalModifyPositionsMutation/);
assert.match(persistence, /new OriginalModifyPositionsOperationApplier\(\)\.apply/);
assert.match(persistence, /opType: OpType\.ORIGINAL_MODIFY_POSITIONS/);
assert.match(persistence, /payload: operation\.rawOperation/);
assert.match(persistence, /uploadImmediately: true/);
assert.match(persistence, /await this\.reconcilePreparedRows\(store, step, expectedRevision\)/);
assert.match(persistence,
  /originalVisibility === null && originalPositionLock === null && originalText === null &&[\s\S]*originalStyle === null[\s\S]*originalModifyPositionsMutation/);
assert.match(persistence, /positionComponents[\s\S]*determinant <= 0\.000001/);
assert.match(persistence, /positionOnlyMutation/);
assert.match(reducer, /PositionTargetType\.INK/);
assert.match(reducer, /PositionTargetType\.BLOCK/);
assert.match(reducer, /PositionTargetType\.SHAPE/);
assert.match(reducer, /SAVEPOINT \$\{SAVEPOINT_NAME\}/);
assert.match(inkReducer, /function transformMatricesEqual[\s\S]*tolerance/);
assert.match(blockReducer, /transformMatricesNear\(element\.transform, expectedTransform\)/);
assert.match(canvas, /type: UndoableActionType\.TRANSFORM_ELEMENTS/);
assert.match(canvas, /persist\(this\.areCanonicalOriginalPositionSelection/);
assert.match(canvas, /action\.type === UndoableActionType\.TRANSFORM_ELEMENTS[\s\S]*areCanonicalOriginalPositionSelection/);
assert.match(selection, /originalCreate: s\.originalCreate/);
assert.match(tests, /round-trips batched original MODIFY_POSITIONS registers/);
assert.match(history, /OpType\.ORIGINAL_MODIFY_POSITIONS/);

const near = (left, right) => Math.abs(left - right) <=
  0.000001 * Math.max(1, Math.abs(left), Math.abs(right));

function components(matrix) {
  if (matrix.length !== 9 || matrix.some(value => !Number.isFinite(value)) ||
    !near(matrix[6], 0) || !near(matrix[7], 0) || !near(matrix[8], 1)) return null;
  const scaleX = Math.hypot(matrix[0], matrix[3]);
  const determinant = matrix[0] * matrix[4] - matrix[1] * matrix[3];
  if (scaleX <= 0.000001 || determinant <= 0.000001) return null;
  const scaleY = determinant / scaleX;
  const rotation = Math.atan2(matrix[3], matrix[0]);
  const expected = [Math.cos(rotation) * scaleX, -Math.sin(rotation) * scaleY, matrix[2],
    Math.sin(rotation) * scaleX, Math.cos(rotation) * scaleY, matrix[5], 0, 0, 1];
  return matrix.every((value, index) => near(value, expected[index])) ?
    { originX: matrix[2], originY: matrix[5], rotation, scaleX, scaleY } : null;
}

const angle = 0.4;
const valid = [Math.cos(angle) * 2, -Math.sin(angle) * 3, 40,
  Math.sin(angle) * 2, Math.cos(angle) * 3, -20, 0, 0, 1];
const decoded = components(valid);
assert.ok(decoded !== null);
assert.ok(near(decoded.originX, 40) && near(decoded.originY, -20));
assert.ok(near(decoded.rotation, angle));
assert.ok(near(decoded.scaleX, 2) && near(decoded.scaleY, 3));
assert.equal(components([1, 0.2, 0, 0, 1, 0, 0, 0, 1]), null, 'shear must fall back');
assert.equal(components([-1, 0, 0, 0, 1, 0, 0, 0, 1]), null, 'reflection must fall back');

const db = new DatabaseSync(':memory:');
db.exec(`CREATE TABLE state(id TEXT PRIMARY KEY,kind INTEGER,origin_x REAL,origin_y REAL,
  rotation REAL,scale_x REAL,scale_y REAL,winner_timestamp INTEGER,winner_site INTEGER);
  CREATE TABLE operation_log(sequence INTEGER PRIMARY KEY AUTOINCREMENT,op_type INTEGER,
    payload_type INTEGER,upload_immediately INTEGER,payload BLOB);
  INSERT INTO state VALUES('ink',1,0,0,0,1,1,10,1);
  INSERT INTO state VALUES('text',2,5,6,0,1,1,10,1);
  INSERT INTO state VALUES('shape',3,8,9,0,1,1,10,1);`);

function applyBatch(modifications, operation, failAfter = -1) {
  db.exec('BEGIN');
  try {
    for (let index = 0; index < modifications.length; index++) {
      const row = db.prepare('SELECT * FROM state WHERE id=?').get(modifications[index].id);
      if (row === undefined) throw new Error('missing target');
      if (operation.timestamp > row.winner_timestamp ||
        operation.timestamp === row.winner_timestamp && operation.site > row.winner_site) {
        db.prepare(`UPDATE state SET origin_x=?,origin_y=?,rotation=?,scale_x=?,scale_y=?,
          winner_timestamp=?,winner_site=? WHERE id=?`).run(
          modifications[index].originX, modifications[index].originY,
          modifications[index].rotation, modifications[index].scaleX,
          modifications[index].scaleY, operation.timestamp, operation.site,
          modifications[index].id);
      }
      if (index === failAfter) throw new Error('injected failure');
    }
    db.prepare('INSERT INTO operation_log(op_type,payload_type,upload_immediately,payload) VALUES(65,24,1,?)')
      .run(Buffer.from([24]));
    db.exec('COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

const batch = ['ink', 'text', 'shape'].map((id, index) => ({ id, originX: 20 + index,
  originY: 30 + index, rotation: 0.5, scaleX: 2, scaleY: 2 }));
applyBatch(batch, { timestamp: 20, site: 2 });
assert.equal(db.prepare('SELECT COUNT(*) AS value FROM state WHERE winner_timestamp=20').get().value, 3);
const journal = db.prepare(
  'SELECT op_type,payload_type,upload_immediately FROM operation_log').get();
assert.equal(journal.op_type, 65);
assert.equal(journal.payload_type, 24);
assert.equal(journal.upload_immediately, 1);
const beforeFailure = JSON.stringify(db.prepare('SELECT * FROM state ORDER BY id').all());
assert.throws(() => applyBatch(batch, { timestamp: 30, site: 2 }, 1), /injected failure/);
assert.equal(JSON.stringify(db.prepare('SELECT * FROM state ORDER BY id').all()), beforeFailure);
assert.equal(db.prepare('SELECT COUNT(*) AS value FROM operation_log').get().value, 1);
db.close();

console.log('localModifyPositions=original-batch-position-writer-history-envelope-rollback');
