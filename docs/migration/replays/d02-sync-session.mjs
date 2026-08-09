import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';

const db = new DatabaseSync(':memory:');
db.exec(`
  PRAGMA foreign_keys=ON;
  CREATE TABLE note_meta(id TEXT PRIMARY KEY);
  CREATE TABLE operation_log(sequence INTEGER PRIMARY KEY AUTOINCREMENT, note_id TEXT NOT NULL,
    op_id TEXT NOT NULL, op_timestamp INTEGER NOT NULL, editor_site_id INTEGER NOT NULL,
    UNIQUE(note_id,op_timestamp,editor_site_id),
    FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE);
  CREATE TABLE note_sync_metadata(note_id TEXT PRIMARY KEY, editor_site_id INTEGER NOT NULL,
    max_op_timestamp INTEGER NOT NULL, synced_op_count INTEGER NOT NULL, max_server_time INTEGER,
    uploaded_through_sequence INTEGER NOT NULL, acked_through_sequence INTEGER NOT NULL,
    CHECK(acked_through_sequence<=uploaded_through_sequence),
    FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE);
  INSERT INTO note_meta VALUES('clean'),('established'),('other');
  INSERT INTO note_sync_metadata VALUES('clean',0,0,0,NULL,0,0);
  INSERT INTO note_sync_metadata VALUES('established',7,1,0,NULL,0,0);
  INSERT INTO note_sync_metadata VALUES('other',3,1,0,NULL,0,0);
  INSERT INTO operation_log(note_id,op_id,op_timestamp,editor_site_id)
    VALUES('established','op:1:7',1,7),('other','op:1:3',1,3);
`);

function resolveSite(noteId, resolvedSiteId) {
  db.exec('BEGIN IMMEDIATE');
  try {
    const metadata = db.prepare(`SELECT editor_site_id site,max_op_timestamp clock,
      synced_op_count count,max_server_time server,uploaded_through_sequence uploaded,
      acked_through_sequence ack FROM note_sync_metadata WHERE note_id=?`).get(noteId);
    if (metadata.site !== resolvedSiteId) {
      const operationCount = db.prepare(
        'SELECT COUNT(*) count FROM operation_log WHERE note_id=?').get(noteId).count;
      if (operationCount !== 0 || metadata.clock !== 0 || metadata.count !== 0 ||
          metadata.server !== null || metadata.uploaded !== 0 || metadata.ack !== 0) {
        throw new Error('identity already established');
      }
      assert.equal(db.prepare(`UPDATE note_sync_metadata SET editor_site_id=?
        WHERE note_id=? AND editor_site_id=?`).run(resolvedSiteId, noteId, metadata.site).changes, 1);
    }
    db.exec('COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

resolveSite('clean', 9);
assert.equal(db.prepare(`SELECT editor_site_id site FROM note_sync_metadata
  WHERE note_id='clean'`).get().site, 9);
assert.throws(() => resolveSite('established', 8));
assert.equal(db.prepare(`SELECT editor_site_id site FROM note_sync_metadata
  WHERE note_id='established'`).get().site, 7);

db.exec(`
  INSERT INTO operation_log(note_id,op_id,op_timestamp,editor_site_id)
    VALUES('clean','op:1:9',1,9),('other','op:2:3',2,3),('clean','op:2:9',2,9);
  UPDATE note_sync_metadata SET max_op_timestamp=2 WHERE note_id='clean';
`);

function pending(noteId) {
  const ack = db.prepare(`SELECT acked_through_sequence ack FROM note_sync_metadata
    WHERE note_id=?`).get(noteId).ack;
  return db.prepare(`SELECT sequence,op_id FROM operation_log WHERE note_id=? AND sequence>?
    ORDER BY sequence`).all(noteId, ack);
}

function persistReply(noteId, sent, replySequence, serverTime, failAck = false) {
  const expected = sent.at(-1).sequence;
  if (replySequence !== expected) {
    throw new Error('missing expected ACK reply');
  }
  db.exec('BEGIN IMMEDIATE');
  try {
    db.prepare(`UPDATE note_sync_metadata SET uploaded_through_sequence=? WHERE note_id=?`)
      .run(expected, noteId);
    db.exec('COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
  db.exec('BEGIN IMMEDIATE');
  try {
    if (failAck) {
      throw new Error('fault before ACK persistence');
    }
    const current = db.prepare(`SELECT acked_through_sequence ack,synced_op_count count
      FROM note_sync_metadata WHERE note_id=?`).get(noteId);
    const delta = db.prepare(`SELECT COUNT(*) count FROM operation_log
      WHERE note_id=? AND sequence>? AND sequence<=?`).get(noteId, current.ack, expected).count;
    db.prepare(`UPDATE note_sync_metadata SET acked_through_sequence=?,synced_op_count=?,
      max_server_time=? WHERE note_id=?`).run(expected, current.count + delta, serverTime, noteId);
    db.exec('COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

const firstBatch = pending('clean');
assert.deepEqual(firstBatch.map(row => row.op_id), ['op:1:9', 'op:2:9']);
assert.throws(() => persistReply('clean', firstBatch, firstBatch[0].sequence, 100));
let watermarks = db.prepare(`SELECT uploaded_through_sequence uploaded,acked_through_sequence ack
  FROM note_sync_metadata WHERE note_id='clean'`).get();
assert.equal(watermarks.uploaded, 0);
assert.equal(watermarks.ack, 0);
assert.throws(() => persistReply('clean', firstBatch, firstBatch.at(-1).sequence, 100, true));
watermarks = db.prepare(`SELECT uploaded_through_sequence uploaded,acked_through_sequence ack
  FROM note_sync_metadata WHERE note_id='clean'`).get();
assert.equal(watermarks.uploaded, firstBatch.at(-1).sequence);
assert.equal(watermarks.ack, 0);
const retryBatch = pending('clean');
assert.deepEqual(retryBatch, firstBatch);
persistReply('clean', retryBatch, retryBatch.at(-1).sequence, 101);
const synced = db.prepare(`SELECT synced_op_count count,max_server_time server
  FROM note_sync_metadata WHERE note_id='clean'`).get();
assert.equal(synced.count, 2);
assert.equal(synced.server, 101);

console.log('success|site=9|established-refused=1|batch=2|wrong-ack=0|retry=2|acked=2');
