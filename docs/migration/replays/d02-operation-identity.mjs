import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';

function v17Database() {
  const db = new DatabaseSync(':memory:');
  db.exec(`
    PRAGMA foreign_keys=ON;
    CREATE TABLE note_meta(id TEXT PRIMARY KEY, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL);
    CREATE TABLE operation_log(sequence INTEGER PRIMARY KEY AUTOINCREMENT, note_id TEXT NOT NULL,
      op_id TEXT NOT NULL, op_type INTEGER NOT NULL, payload BLOB NOT NULL, client_time INTEGER NOT NULL,
      action_id TEXT, history_effect INTEGER, coalesce_track INTEGER, action_time INTEGER,
      UNIQUE(note_id,op_id), FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE);
    INSERT INTO note_meta VALUES ('a',10,20),('b',30,40);
    INSERT INTO operation_log(note_id,op_id,op_type,payload,client_time) VALUES
      ('a','legacy-a1',10,X'01',100),('b','legacy-b1',10,X'02',100),('a','legacy-a2',11,X'03',101);
    PRAGMA user_version=17;
  `);
  return db;
}

function migrate18(db) {
  db.exec('BEGIN IMMEDIATE');
  try {
    db.exec(`
      CREATE TABLE local_editor_identity(singleton INTEGER PRIMARY KEY CHECK(singleton=1),
        editor_id TEXT NOT NULL UNIQUE);
      INSERT INTO local_editor_identity VALUES(1,'local-editor');
      CREATE TABLE note_sync_metadata(note_id TEXT PRIMARY KEY, legacy_id TEXT,
        editor_site_id INTEGER NOT NULL CHECK(editor_site_id BETWEEN 0 AND 65535),
        editor_id TEXT NOT NULL, creator_id TEXT NOT NULL, created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL, max_server_time INTEGER, synced_op_count INTEGER NOT NULL DEFAULT 0,
        max_op_timestamp INTEGER NOT NULL CHECK(max_op_timestamp BETWEEN 0 AND 4294967295),
        schema_version INTEGER NOT NULL, uploaded_through_sequence INTEGER NOT NULL DEFAULT 0,
        acked_through_sequence INTEGER NOT NULL DEFAULT 0,
        CHECK(acked_through_sequence<=uploaded_through_sequence),
        FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE);
      INSERT INTO note_sync_metadata(note_id,editor_site_id,editor_id,creator_id,created_at,updated_at,
        synced_op_count,max_op_timestamp,schema_version,uploaded_through_sequence,acked_through_sequence)
        SELECT note.id,0,'local-editor','local-editor',note.created_at,note.updated_at,0,
          COALESCE(MAX(log.sequence),0),1,0,0 FROM note_meta note
          LEFT JOIN operation_log log ON log.note_id=note.id GROUP BY note.id;
      CREATE TABLE operation_log_v18(sequence INTEGER PRIMARY KEY AUTOINCREMENT, note_id TEXT NOT NULL,
        op_id TEXT NOT NULL, op_type INTEGER NOT NULL, payload BLOB NOT NULL, client_time INTEGER NOT NULL,
        op_timestamp INTEGER NOT NULL CHECK(op_timestamp BETWEEN 0 AND 4294967295),
        editor_site_id INTEGER NOT NULL CHECK(editor_site_id BETWEEN 0 AND 65535),
        upload_immediately INTEGER NOT NULL DEFAULT 0 CHECK(upload_immediately IN(0,1)),
        action_id TEXT, history_effect INTEGER, coalesce_track INTEGER, action_time INTEGER,
        UNIQUE(note_id,op_id), UNIQUE(note_id,editor_site_id,op_timestamp),
        FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE);
      INSERT INTO operation_log_v18 SELECT sequence,note_id,op_id,op_type,payload,client_time,
        sequence,0,0,action_id,history_effect,coalesce_track,action_time FROM operation_log ORDER BY sequence;
      DROP TABLE operation_log;
      ALTER TABLE operation_log_v18 RENAME TO operation_log;
      PRAGMA user_version=18;
    `);
    db.exec('COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

function allocate(db, noteId, clientTime) {
  db.exec('BEGIN IMMEDIATE');
  try {
    const metadata = db.prepare(`SELECT editor_site_id site,max_op_timestamp timestamp
      FROM note_sync_metadata WHERE note_id=?`).get(noteId);
    assert.ok(metadata.timestamp < 0xffffffff);
    const timestamp = metadata.timestamp + 1;
    const changed = db.prepare(`UPDATE note_sync_metadata SET max_op_timestamp=?,updated_at=?
      WHERE note_id=? AND max_op_timestamp=?`).run(timestamp, clientTime, noteId, metadata.timestamp);
    assert.equal(changed.changes, 1);
    const opId = `op:${timestamp.toString(16)}:${metadata.site.toString(16)}`;
    const sequence = db.prepare(`INSERT INTO operation_log(note_id,op_id,op_type,payload,client_time,
      op_timestamp,editor_site_id,upload_immediately) VALUES(?,?,10,X'04',?,?,?,0)`)
      .run(noteId, opId, clientTime, timestamp, metadata.site).lastInsertRowid;
    db.exec('COMMIT');
    return { sequence: Number(sequence), timestamp, site: metadata.site, opId };
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

const db = v17Database();
migrate18(db);
assert.equal(db.prepare('PRAGMA user_version').get().user_version, 18);
assert.deepEqual(db.prepare(`SELECT op_id,op_timestamp,editor_site_id FROM operation_log ORDER BY sequence`).all()
  .map((row) => ({ ...row })), [
  { op_id: 'legacy-a1', op_timestamp: 1, editor_site_id: 0 },
  { op_id: 'legacy-b1', op_timestamp: 2, editor_site_id: 0 },
  { op_id: 'legacy-a2', op_timestamp: 3, editor_site_id: 0 },
]);
assert.deepEqual(db.prepare(`SELECT note_id,max_op_timestamp FROM note_sync_metadata ORDER BY note_id`).all()
  .map((row) => ({ ...row })), [
  { note_id: 'a', max_op_timestamp: 3 }, { note_id: 'b', max_op_timestamp: 2 },
]);

const a = allocate(db, 'a', 102);
assert.deepEqual(a, { sequence: 4, timestamp: 4, site: 0, opId: 'op:4:0' });
db.prepare(`UPDATE note_sync_metadata SET editor_site_id=7 WHERE note_id='b'`).run();
const b = allocate(db, 'b', 103);
assert.deepEqual(b, { sequence: 5, timestamp: 3, site: 7, opId: 'op:3:7' });

db.prepare(`UPDATE note_sync_metadata SET uploaded_through_sequence=? WHERE note_id='a'`).run(a.sequence);
db.prepare(`UPDATE note_sync_metadata SET acked_through_sequence=?,max_server_time=900
  WHERE note_id='a' AND uploaded_through_sequence>=?`).run(a.sequence, a.sequence);
assert.equal(db.prepare(`SELECT count(*) count FROM operation_log log JOIN note_sync_metadata metadata
  ON metadata.note_id=log.note_id WHERE log.note_id='a' AND log.sequence>metadata.acked_through_sequence`).get().count, 0);
assert.throws(() => db.prepare(`UPDATE note_sync_metadata SET acked_through_sequence=5 WHERE note_id='b'`).run());
assert.equal(db.prepare(`SELECT acked_through_sequence FROM note_sync_metadata WHERE note_id='b'`).get().acked_through_sequence, 0);

console.log('success|v17-v18=preserved|legacy-mapped=3|clock=a4,b3@7|ack=a4|rollback=1');
