import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';

function database() {
  const db = new DatabaseSync(':memory:');
  db.exec(`
    PRAGMA foreign_keys=ON;
    CREATE TABLE note_meta(id TEXT PRIMARY KEY);
    CREATE TABLE operation_log(sequence INTEGER PRIMARY KEY AUTOINCREMENT, note_id TEXT NOT NULL,
      op_id TEXT NOT NULL, op_type INTEGER NOT NULL, payload BLOB NOT NULL, client_time INTEGER NOT NULL,
      action_id TEXT, history_effect INTEGER, coalesce_track INTEGER, action_time INTEGER,
      UNIQUE(note_id,op_id), FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE);
    CREATE TABLE history_checkpoint(note_id TEXT PRIMARY KEY, through_sequence INTEGER NOT NULL,
      legacy_operation_count INTEGER NOT NULL, created_time INTEGER NOT NULL,
      FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE);
    CREATE TABLE history_checkpoint_action(note_id TEXT NOT NULL, stack_kind INTEGER NOT NULL,
      stack_index INTEGER NOT NULL, action_id TEXT NOT NULL, coalesce_track INTEGER NOT NULL,
      action_time INTEGER NOT NULL, PRIMARY KEY(note_id,stack_kind,stack_index),
      FOREIGN KEY(note_id) REFERENCES history_checkpoint(note_id) ON DELETE CASCADE);
    CREATE TABLE page_delete_checkpoint(note_id TEXT NOT NULL, action_id TEXT NOT NULL,
      PRIMARY KEY(note_id,action_id), FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE);
    INSERT INTO note_meta VALUES ('note');
  `);
  return db;
}

function resetHistory(db, injectFailure = false) {
  db.exec('BEGIN IMMEDIATE');
  try {
    const latest = db.prepare(`SELECT max(sequence) value FROM operation_log WHERE note_id='note'`).get().value;
    db.prepare(`DELETE FROM history_checkpoint WHERE note_id='note'`).run();
    if (latest !== null) {
      db.prepare(`INSERT INTO history_checkpoint VALUES ('note',?,0,100)`).run(latest);
    }
    if (injectFailure) throw new Error('injected reset failure');
    db.prepare(`DELETE FROM page_delete_checkpoint WHERE note_id='note'`).run();
    db.exec('COMMIT');
    return latest ?? 0;
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

function state(db) {
  return JSON.stringify({
    checkpoint: db.prepare(`SELECT * FROM history_checkpoint`).all(),
    actions: db.prepare(`SELECT * FROM history_checkpoint_action`).all(),
    deletes: db.prepare(`SELECT * FROM page_delete_checkpoint`).all(),
    operations: db.prepare(`SELECT sequence,op_id FROM operation_log ORDER BY sequence`).all(),
  });
}

const db = database();
const append = db.prepare(`INSERT INTO operation_log(note_id,op_id,op_type,payload,client_time,
  action_id,history_effect,coalesce_track,action_time) VALUES ('note',?,10,X'01',?,?,0,3,?)`);
append.run('op-1', 1, 'action-1', 1);
append.run('op-2', 2, 'action-2', 2);
append.run('op-3', 3, 'action-3', 3);
db.exec(`
  INSERT INTO history_checkpoint VALUES ('note',999,0,10);
  INSERT INTO history_checkpoint_action VALUES ('note',0,0,'corrupt-action',3,10);
  INSERT INTO page_delete_checkpoint VALUES ('note','delete-action');
`);

const beforeFailure = state(db);
assert.throws(() => resetHistory(db, true), /injected reset failure/);
assert.equal(state(db), beforeFailure, 'failed recovery keeps the corrupt checkpoint and all logs intact');

assert.equal(resetHistory(db), 3);
const recovered = db.prepare(
  `SELECT through_sequence,legacy_operation_count FROM history_checkpoint`).get();
assert.equal(recovered.through_sequence, 3);
assert.equal(recovered.legacy_operation_count, 0);
assert.equal(db.prepare(`SELECT count(*) value FROM history_checkpoint_action`).get().value, 0);
assert.equal(db.prepare(`SELECT count(*) value FROM page_delete_checkpoint`).get().value, 0);
assert.equal(db.prepare(`SELECT count(*) value FROM operation_log`).get().value, 3);

append.run('op-4', 4, 'action-4', 4);
const watermark = db.prepare(`SELECT through_sequence value FROM history_checkpoint`).get().value;
const tail = db.prepare(`SELECT op_id FROM operation_log WHERE sequence>? ORDER BY sequence`).all(watermark);
assert.equal(tail.length, 1);
assert.equal(tail[0].op_id, 'op-4');
db.close();

const empty = database();
empty.exec(`
  INSERT INTO history_checkpoint VALUES ('note',999,0,10);
  INSERT INTO page_delete_checkpoint VALUES ('note','delete-action');
`);
assert.equal(resetHistory(empty), 0);
assert.equal(empty.prepare(`SELECT count(*) value FROM history_checkpoint`).get().value, 0);
assert.equal(empty.prepare(`SELECT count(*) value FROM page_delete_checkpoint`).get().value, 0);
empty.close();

console.log('success|corrupt-overridden=1|log-preserved=3|tail=1|delete-checkpoints=0|rollback=1|empty-log=1');
