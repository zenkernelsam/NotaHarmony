import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';

const db = new DatabaseSync(':memory:');
db.exec(`
  PRAGMA foreign_keys=ON;
  CREATE TABLE note_meta(id TEXT PRIMARY KEY);
  CREATE TABLE operation_log(sequence INTEGER PRIMARY KEY AUTOINCREMENT, note_id TEXT NOT NULL,
    op_id TEXT NOT NULL, FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE);
  CREATE TABLE history_checkpoint(note_id TEXT PRIMARY KEY, through_sequence INTEGER NOT NULL,
    FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE);
  CREATE TABLE note_sync_metadata(note_id TEXT PRIMARY KEY, synced_op_count INTEGER NOT NULL,
    uploaded_through_sequence INTEGER NOT NULL, acked_through_sequence INTEGER NOT NULL,
    CHECK(acked_through_sequence<=uploaded_through_sequence),
    FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE);
  INSERT INTO note_meta VALUES('a'),('b');
  INSERT INTO note_sync_metadata VALUES('a',0,0,0),('b',0,0,0);
`);
for (let i = 1; i <= 8; i++) {
  db.prepare('INSERT INTO operation_log(note_id,op_id) VALUES(?,?)')
    .run(i === 4 ? 'b' : 'a', `op-${i}`);
}

function acknowledge(noteId, sequence) {
  db.exec('BEGIN IMMEDIATE');
  try {
    const metadata = db.prepare(`SELECT acked_through_sequence ack,synced_op_count count
      FROM note_sync_metadata WHERE note_id=?`).get(noteId);
    const delta = db.prepare(`SELECT COUNT(*) count FROM operation_log
      WHERE note_id=? AND sequence>? AND sequence<=?`).get(noteId, metadata.ack, sequence).count;
    db.prepare(`UPDATE note_sync_metadata SET uploaded_through_sequence=?,acked_through_sequence=?,
      synced_op_count=? WHERE note_id=?`).run(sequence, sequence, metadata.count + delta, noteId);
    compactInTransaction(noteId, sequence);
    db.exec('COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

function compactInTransaction(noteId, ackedThroughSequence) {
  const checkpoint = db.prepare(`SELECT through_sequence history FROM history_checkpoint
    WHERE note_id=?`).get(noteId);
  const boundary = checkpoint === undefined ? 0 : Math.min(ackedThroughSequence, checkpoint.history);
  if (boundary === 0) {
    return { boundary: 0, deleted: 0 };
  }
  assert.equal(db.prepare('SELECT note_id FROM operation_log WHERE sequence=?').get(boundary).note_id, noteId);
  const deleted = db.prepare('DELETE FROM operation_log WHERE note_id=? AND sequence<?').run(noteId, boundary).changes;
  assert.equal(db.prepare('SELECT note_id FROM operation_log WHERE sequence=?').get(boundary).note_id, noteId);
  return { boundary, deleted };
}

function checkpoint(noteId, sequence, failAfterDelete = false) {
  db.exec('BEGIN IMMEDIATE');
  try {
    db.prepare(`INSERT OR REPLACE INTO history_checkpoint VALUES(?,?)`).run(noteId, sequence);
    const ack = db.prepare(`SELECT acked_through_sequence ack FROM note_sync_metadata
      WHERE note_id=?`).get(noteId).ack;
    const result = compactInTransaction(noteId, ack);
    if (failAfterDelete) {
      throw new Error('fault after checkpoint compaction');
    }
    db.exec('COMMIT');
    return result;
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

function compact(noteId) {
  db.exec('BEGIN IMMEDIATE');
  try {
    const ack = db.prepare(`SELECT acked_through_sequence ack FROM note_sync_metadata
      WHERE note_id=?`).get(noteId).ack;
    const result = compactInTransaction(noteId, ack);
    db.exec('COMMIT');
    return result;
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

acknowledge('a', 6);
assert.equal(db.prepare(`SELECT synced_op_count FROM note_sync_metadata WHERE note_id='a'`).get().synced_op_count, 5);
assert.deepEqual(compact('a'), { boundary: 0, deleted: 0 });
assert.throws(() => checkpoint('a', 5, true));
assert.equal(db.prepare(`SELECT COUNT(*) count FROM history_checkpoint WHERE note_id='a'`).get().count, 0);
assert.equal(db.prepare(`SELECT COUNT(*) count FROM operation_log WHERE note_id='a'`).get().count, 7);
assert.deepEqual(checkpoint('a', 5), { boundary: 5, deleted: 3 });
assert.deepEqual(compact('a'), { boundary: 5, deleted: 0 });
assert.equal(db.prepare(`SELECT COUNT(*) count FROM operation_log WHERE note_id='b'`).get().count, 1);
acknowledge('a', 8);
assert.equal(db.prepare(`SELECT synced_op_count FROM note_sync_metadata WHERE note_id='a'`).get().synced_op_count, 7);
assert.equal(db.prepare(`SELECT MIN(sequence) first FROM operation_log WHERE note_id='a'`).get().first, 5);
assert.deepEqual(checkpoint('a', 8), { boundary: 8, deleted: 3 });
assert.equal(db.prepare(`SELECT MIN(sequence) first FROM operation_log WHERE note_id='a'`).get().first, 8);

console.log('success|both-orders=1|boundary=8|deleted=6|idempotent=1|count=7|rollback=1');
