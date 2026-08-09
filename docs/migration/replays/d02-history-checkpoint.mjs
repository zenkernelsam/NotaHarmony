import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';

const checkpointDdl = `
  CREATE TABLE history_checkpoint(note_id TEXT PRIMARY KEY, through_sequence INTEGER NOT NULL,
    legacy_operation_count INTEGER NOT NULL, created_time INTEGER NOT NULL,
    FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE);
  CREATE TABLE history_checkpoint_action(note_id TEXT NOT NULL, stack_kind INTEGER NOT NULL,
    stack_index INTEGER NOT NULL, action_id TEXT NOT NULL, coalesce_track INTEGER NOT NULL,
    action_time INTEGER NOT NULL, CHECK(stack_kind IN (0,1)),
    PRIMARY KEY(note_id,stack_kind,stack_index), UNIQUE(note_id,action_id),
    FOREIGN KEY(note_id) REFERENCES history_checkpoint(note_id) ON DELETE CASCADE);
  CREATE TABLE history_checkpoint_operation(note_id TEXT NOT NULL, stack_kind INTEGER NOT NULL,
    stack_index INTEGER NOT NULL, operation_index INTEGER NOT NULL, op_id TEXT NOT NULL,
    op_type INTEGER NOT NULL, payload BLOB NOT NULL, client_time INTEGER NOT NULL,
    PRIMARY KEY(note_id,stack_kind,stack_index,operation_index),
    FOREIGN KEY(note_id,stack_kind,stack_index)
      REFERENCES history_checkpoint_action(note_id,stack_kind,stack_index) ON DELETE CASCADE);
`;

function database() {
  const db = new DatabaseSync(':memory:');
  db.exec(`
    PRAGMA foreign_keys=ON;
    CREATE TABLE note_meta(id TEXT PRIMARY KEY);
    CREATE TABLE operation_log(sequence INTEGER PRIMARY KEY AUTOINCREMENT, note_id TEXT NOT NULL,
      op_id TEXT NOT NULL, op_type INTEGER NOT NULL, payload BLOB NOT NULL, client_time INTEGER NOT NULL,
      action_id TEXT, history_effect INTEGER, coalesce_track INTEGER, action_time INTEGER,
      UNIQUE(note_id,op_id), FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE);
    CREATE TABLE page_delete_checkpoint(note_id TEXT NOT NULL, action_id TEXT NOT NULL,
      PRIMARY KEY(note_id,action_id), FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE);
    CREATE TABLE page_delete_checkpoint_element(note_id TEXT NOT NULL, action_id TEXT NOT NULL,
      element_id TEXT NOT NULL, PRIMARY KEY(note_id,action_id,element_id),
      FOREIGN KEY(note_id,action_id) REFERENCES page_delete_checkpoint(note_id,action_id) ON DELETE CASCADE);
    INSERT INTO note_meta VALUES ('note');
    PRAGMA user_version=16;
  `);
  return db;
}

function migrate17(db) {
  db.exec('BEGIN');
  try {
    db.exec(checkpointDdl);
    db.exec('PRAGMA user_version=17');
    db.exec('COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

function seed(db, count) {
  const insert = db.prepare(`INSERT INTO operation_log(note_id,op_id,op_type,payload,client_time,
    action_id,history_effect,coalesce_track,action_time) VALUES ('note',?,10,X'01',?,?,0,3,?)`);
  for (let index = 0; index < count; index++) {
    insert.run(`op-${index}`, index + 1, `action-${index}`, index + 1);
  }
  for (const action of new Set(['action-0', `action-${count - 1}`])) {
    db.prepare(`INSERT INTO page_delete_checkpoint VALUES ('note',?)`).run(action);
    db.prepare(`INSERT INTO page_delete_checkpoint_element VALUES ('note',?,'element')`).run(action);
  }
}

function writeCheckpoint(db, maxActions, injectFailure = false) {
  db.exec('BEGIN IMMEDIATE');
  try {
    const rows = db.prepare(`SELECT sequence,op_id,op_type,payload,client_time,action_id,
      coalesce_track,action_time FROM operation_log WHERE note_id='note' AND history_effect=0
      ORDER BY sequence`).all();
    const retained = rows.slice(-maxActions);
    const watermark = rows.at(-1).sequence;
    db.prepare(`DELETE FROM history_checkpoint WHERE note_id='note'`).run();
    db.prepare(`INSERT INTO history_checkpoint VALUES ('note',?,0,100)`).run(watermark);
    for (let index = 0; index < retained.length; index++) {
      const row = retained[index];
      db.prepare(`INSERT INTO history_checkpoint_action VALUES ('note',0,?,?,?,?)`)
        .run(index, row.action_id, row.coalesce_track, row.action_time);
      if (injectFailure && index === 1) throw new Error('injected checkpoint operation failure');
      db.prepare(`INSERT INTO history_checkpoint_operation VALUES ('note',0,?,0,?,?,?,?)`)
        .run(index, row.op_id, row.op_type, row.payload, row.client_time);
    }
    const retainedIds = new Set(retained.map(row => row.action_id));
    for (const row of db.prepare(`SELECT action_id FROM page_delete_checkpoint WHERE note_id='note'`).all()) {
      if (!retainedIds.has(row.action_id)) {
        db.prepare(`DELETE FROM page_delete_checkpoint WHERE note_id='note' AND action_id=?`).run(row.action_id);
      }
    }
    db.exec('COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

function state(db) {
  return JSON.stringify({
    header: db.prepare(`SELECT * FROM history_checkpoint`).all(),
    actions: db.prepare(`SELECT * FROM history_checkpoint_action ORDER BY stack_index`).all(),
    operations: db.prepare(`SELECT op_id FROM history_checkpoint_operation ORDER BY stack_index`).all(),
    deletes: db.prepare(`SELECT action_id FROM page_delete_checkpoint ORDER BY action_id`).all(),
    deleteElements: db.prepare(`SELECT action_id FROM page_delete_checkpoint_element ORDER BY action_id`).all(),
    logCount: db.prepare(`SELECT count(*) value FROM operation_log`).get().value,
  });
}

const db = database();
seed(db, 300);
migrate17(db);
assert.equal(db.prepare(`PRAGMA user_version`).get().user_version, 17);
writeCheckpoint(db, 128);
assert.equal(db.prepare(`SELECT count(*) value FROM history_checkpoint_action`).get().value, 128);
assert.equal(db.prepare(`SELECT min(action_id) value FROM history_checkpoint_action`).get().value, 'action-172');
assert.equal(db.prepare(`SELECT count(*) value FROM operation_log`).get().value, 300, 'sync log is append-only');
assert.deepEqual(db.prepare(`SELECT action_id FROM page_delete_checkpoint`).all().map(row => row.action_id),
  ['action-299']);
assert.equal(db.prepare(`SELECT count(*) value FROM page_delete_checkpoint_element`).get().value, 1);

db.prepare(`INSERT INTO operation_log(note_id,op_id,op_type,payload,client_time,action_id,
  history_effect,coalesce_track,action_time) VALUES ('note','undo-tail',11,X'02',301,'action-299',1,3,300)`).run();
const watermark = db.prepare(`SELECT through_sequence value FROM history_checkpoint`).get().value;
assert.equal(db.prepare(`SELECT count(*) value FROM operation_log WHERE sequence>?`).get(watermark).value, 1);

const beforeFailure = state(db);
assert.throws(() => writeCheckpoint(db, 128, true), /injected/);
assert.equal(state(db), beforeFailure, 'replacement and delete-checkpoint cleanup roll back together');
db.close();

const corrupt = database();
seed(corrupt, 1);
migrate17(corrupt);
writeCheckpoint(corrupt, 1);
corrupt.exec(`UPDATE history_checkpoint SET through_sequence=999`);
const maxSequence = corrupt.prepare(`SELECT max(sequence) value FROM operation_log`).get().value;
const throughSequence = corrupt.prepare(`SELECT through_sequence value FROM history_checkpoint`).get().value;
assert.ok(throughSequence > maxSequence, 'production reader must reject this watermark');
corrupt.close();

console.log('success|v16-v17=preserved|retained=128|tail=1|log=300|delete-checkpoints=1|rollback=1|bad-watermark=1');
