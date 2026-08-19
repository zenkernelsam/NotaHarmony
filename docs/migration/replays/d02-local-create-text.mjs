import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const read = value => fs.readFileSync(new URL('../../../' + value, import.meta.url), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const originalHaa = fs.readFileSync(originalRoot + 'haa.java', 'utf8');
const originalBaj = fs.readFileSync(originalRoot + 'baj.java', 'utf8');
const originalKci = fs.readFileSync(originalRoot + 'kci.java', 'utf8');
const originalF46 = fs.readFileSync(originalRoot + 'f46.java', 'utf8');
const model = read('note/src/main/ets/core/model/ElementTypes.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const createEncoder = read('note/src/main/ets/data/OriginalCreateBlockPayloadEncoder.ets');
const insertEncoder = read('note/src/main/ets/data/OriginalInsertTextPayloadEncoder.ets');
const createReducer = read('note/src/main/ets/data/OriginalCreateBlockOperation.ets');
const insertReducer = read('note/src/main/ets/data/OriginalInsertTextOperation.ets');
const persistence = read('note/src/main/ets/data/StrokePersistence.ets');
const history = read('note/src/main/ets/data/PersistentHistory.ets');
const opTypes = read('note/src/main/ets/core/model/OpTypes.ets');
const fixtures = read('note/src/test/OriginalCreateTextPayloadEncoder.test.ets');

assert.match(originalHaa, /INSERT_STRING\(\(byte\) 8\)/);
assert.match(originalHaa, /CREATE_BLOCK\(\(byte\) 22\)/);
assert.match(originalBaj, /aVar\.C\(21\)/);
assert.match(originalBaj, /aVar\.j\(2, nti\.X\(cxcVar, aVar\)\)/);
assert.match(originalBaj, /aVar\.j\(3, apb\.Y\(fqaVar, aVar\)\)/);
assert.match(originalKci, /public static f46 b\(exc excVar, String str, qo5 qo5Var\)/);
assert.match(originalKci, /aVarA\.h\(1, iC\)/);
assert.match(originalKci, /aVarA\.j\(2, rh8\.O\(qo5Var, aVarA\)\)/);
assert.match(originalF46, /Cannot insert empty string/);

assert.match(model, /originalCreate\?: OriginalInkCreateMetadata/);
assert.match(canvas, /this\.textBlockTool\.createTextBlock\(position,[\s\S]*-16777216, 17\)/);
assert.match(canvas, /element\.id = encodeOperationId/);
assert.match(canvas, /element\.textOrigin = \{ x: 0, y: 0 \}/);
assert.match(canvas, /this\.persist\(rearmOriginalCreate\)/);
assert.match(canvas, /cancelledOriginalCreate[\s\S]*refreshOriginalInkReservation/);
assert.match(createEncoder, /encodeOriginalLocalCreateTextBlock/);
assert.match(createEncoder, /text\.fontSize !== DEFAULT_TEXT_SIZE/);
assert.match(insertEncoder, /encodeOriginalInitialInsertString/);
assert.match(insertEncoder, /original INSERT_STRING value is invalid/);
assert.match(createReducer, /applyBatchedPayload/);
assert.match(createReducer, /revisionBatch\.recordBlock/);
assert.match(insertReducer, /applyBatchedPayload/);
assert.match(insertReducer, /revisionBatch\.recordBlock\(batchTarget, true\)/);
assert.match(persistence, /writeOriginalCreateText/);
assert.match(persistence, /const snapshotRevision: number = currentRevision \+ 1/);
assert.match(persistence, /OpType\.ORIGINAL_CREATE_BLOCK/);
assert.match(persistence, /OpType\.ORIGINAL_INSERT_TEXT/);
assert.match(persistence, /await revisionBatch\.flush\(store, snapshot\.noteId\)/);
assert.match(persistence, /uploadImmediately: true/);
assert.match(history, /OpType\.ORIGINAL_CREATE_BLOCK/);
assert.match(history, /OpType\.ORIGINAL_INSERT_TEXT/);
assert.match(opTypes, /ORIGINAL_CREATE_BLOCK = 71/);
assert.match(opTypes, /ORIGINAL_INSERT_TEXT = 72/);
assert.match(fixtures,
  /flushes Ink visibility CREATE_BLOCK and INSERT_STRING as one page revision/);

const db = new DatabaseSync(':memory:');
db.exec(`CREATE TABLE page(id INTEGER PRIMARY KEY, revision INTEGER NOT NULL);
  CREATE TABLE block_state(id TEXT PRIMARY KEY, rich_text TEXT NOT NULL, visible INTEGER NOT NULL);
  CREATE TABLE character(block_id TEXT, char_index INTEGER, scalar INTEGER,
    PRIMARY KEY(block_id,char_index));
  CREATE TABLE snapshot(id TEXT PRIMARY KEY, payload TEXT NOT NULL, revision INTEGER NOT NULL);
  CREATE TABLE operation(seq INTEGER PRIMARY KEY AUTOINCREMENT, type INTEGER, id TEXT, upload INTEGER);
  CREATE TABLE history(seq INTEGER PRIMARY KEY AUTOINCREMENT, action TEXT, identity TEXT);
  INSERT INTO page VALUES(1,0);`);

const text = 'A\u{1F600}\u4E2D';

function createText(failAt = null) {
  db.exec('BEGIN IMMEDIATE');
  try {
    db.prepare('INSERT INTO block_state VALUES(?, ?, 1)').run('op:100:7', '');
    db.prepare('INSERT INTO snapshot VALUES(?, ?, 1)').run('op:100:7', '');
    if (failAt === 'reducer') throw new Error('injected reducer failure');
    db.prepare('INSERT INTO operation(type,id,upload) VALUES(22,?,1)').run('op:100:7');
    if (failAt === 'journal') throw new Error('injected journal failure');
    for (const [index, scalar] of Array.from(text).entries()) {
      db.prepare('INSERT INTO character VALUES(?,?,?)')
        .run('op:100:7', index, scalar.codePointAt(0));
    }
    db.prepare('UPDATE block_state SET rich_text=? WHERE id=?').run(text, 'op:100:7');
    db.prepare('UPDATE snapshot SET payload=? WHERE id=?').run(text, 'op:100:7');
    db.prepare('INSERT INTO operation(type,id,upload) VALUES(8,?,1)').run('op:101:7');
    db.exec('UPDATE page SET revision=revision+1 WHERE id=1');
    if (failAt === 'history') throw new Error('injected history failure');
    db.prepare("INSERT INTO history(action,identity) VALUES('create-text',?)").run('op:100:7');
    db.exec('COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

function setVisible(visible) {
  db.exec('BEGIN IMMEDIATE');
  try {
    const state = db.prepare('SELECT rich_text FROM block_state WHERE id=?').get('op:100:7');
    assert.ok(state);
    db.prepare('UPDATE block_state SET visible=? WHERE id=?').run(visible ? 1 : 0, 'op:100:7');
    if (visible) {
      db.prepare('INSERT INTO snapshot VALUES(?,?,?)')
        .run('op:100:7', state.rich_text, db.prepare('SELECT revision+1 AS value FROM page').get().value);
    } else {
      db.prepare('DELETE FROM snapshot WHERE id=?').run('op:100:7');
    }
    db.prepare('INSERT INTO operation(type,id,upload) VALUES(25,?,1)').run('op:100:7');
    db.prepare('INSERT INTO history(action,identity) VALUES(?,?)')
      .run(visible ? 'redo' : 'undo', 'op:100:7');
    db.exec('UPDATE page SET revision=revision+1 WHERE id=1');
    db.exec('COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

createText();
assert.deepEqual(db.prepare('SELECT type,upload FROM operation ORDER BY seq').all()
  .map(row => ({ type: row.type, upload: row.upload })), [
  { type: 22, upload: 1 }, { type: 8, upload: 1 },
]);
assert.equal(db.prepare('SELECT revision FROM page').get().revision, 1);
assert.equal(db.prepare('SELECT rich_text FROM block_state').get().rich_text, text);
assert.deepEqual(db.prepare('SELECT scalar FROM character ORDER BY char_index').all()
  .map(row => ({ scalar: row.scalar })), [
  { scalar: 0x41 }, { scalar: 0x1F600 }, { scalar: 0x4E2D },
]);

setVisible(false);
assert.equal(db.prepare('SELECT COUNT(*) AS count FROM snapshot').get().count, 0);
setVisible(true);
assert.equal(db.prepare('SELECT payload FROM snapshot').get().payload, text);
assert.equal(db.prepare('SELECT revision FROM page').get().revision, 3);
assert.deepEqual(db.prepare('SELECT DISTINCT identity FROM history').all()
  .map(row => ({ identity: row.identity })), [{ identity: 'op:100:7' }]);

for (const failAt of ['reducer', 'journal', 'history']) {
  db.exec(`DELETE FROM snapshot; DELETE FROM character; DELETE FROM block_state;
    DELETE FROM operation; DELETE FROM history; UPDATE page SET revision=0`);
  assert.throws(() => createText(failAt), new RegExp(`injected ${failAt} failure`));
  assert.equal(db.prepare('SELECT COUNT(*) AS count FROM block_state').get().count, 0);
  assert.equal(db.prepare('SELECT COUNT(*) AS count FROM operation').get().count, 0);
  assert.equal(db.prepare('SELECT revision FROM page').get().revision, 0);
}
db.close();

console.log('localCreateText=type22-empty-block-type8-unicode-single-revision-' +
  'persistent-undo-redo-rollback');
