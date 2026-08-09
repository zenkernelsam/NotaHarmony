import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';

const db = new DatabaseSync(':memory:');
db.exec(`
  PRAGMA foreign_keys=ON;
  CREATE TABLE note_meta(id TEXT PRIMARY KEY, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL);
  CREATE TABLE page_info(page_id TEXT PRIMARY KEY, note_id TEXT NOT NULL,
    FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE);
  CREATE TABLE local_editor_identity(singleton INTEGER PRIMARY KEY CHECK(singleton=1),
    editor_id TEXT NOT NULL UNIQUE);
  CREATE TABLE note_sync_metadata(note_id TEXT PRIMARY KEY, legacy_id TEXT,
    editor_site_id INTEGER NOT NULL, editor_id TEXT NOT NULL, creator_id TEXT NOT NULL,
    created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, max_op_timestamp INTEGER NOT NULL,
    uploaded_through_sequence INTEGER NOT NULL, acked_through_sequence INTEGER NOT NULL,
    FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE);
  CREATE TABLE operation_log(sequence INTEGER PRIMARY KEY AUTOINCREMENT, note_id TEXT NOT NULL,
    op_id TEXT NOT NULL, op_timestamp INTEGER NOT NULL, editor_site_id INTEGER NOT NULL,
    UNIQUE(note_id,editor_site_id,op_timestamp),
    FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE);
  INSERT INTO local_editor_identity VALUES(1,'local-editor');
  INSERT INTO note_meta VALUES('source-note',10,20);
  INSERT INTO page_info VALUES('source-page','source-note');
`);

function createImportedNote(targetId, sourceId, pageId) {
  db.exec('BEGIN IMMEDIATE');
  try {
    db.prepare('INSERT INTO note_meta VALUES(?,?,?)').run(targetId, 10, 20);
    db.prepare(`INSERT INTO note_sync_metadata
      SELECT ?,?,0,editor_id,editor_id,10,20,0,0,0
      FROM local_editor_identity WHERE singleton=1`).run(targetId, sourceId === targetId ? null : sourceId);
    db.prepare('INSERT INTO page_info VALUES(?,?)').run(pageId, targetId);
    db.exec('COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

createImportedNote('source-note-import-copy', 'source-note', 'copy-page');
const metadata = db.prepare(`SELECT legacy_id,editor_site_id,editor_id,creator_id,max_op_timestamp
  FROM note_sync_metadata WHERE note_id='source-note-import-copy'`).get();
assert.deepEqual({ ...metadata }, {
  legacy_id: 'source-note', editor_site_id: 0, editor_id: 'local-editor',
  creator_id: 'local-editor', max_op_timestamp: 0,
});
assert.deepEqual(db.prepare('SELECT page_id,note_id FROM page_info ORDER BY note_id').all()
  .map((row) => ({ ...row })), [
  { page_id: 'source-page', note_id: 'source-note' },
  { page_id: 'copy-page', note_id: 'source-note-import-copy' },
]);

const changed = db.prepare(`UPDATE note_sync_metadata SET max_op_timestamp=1
  WHERE note_id=? AND max_op_timestamp=0`).run('source-note-import-copy');
assert.equal(changed.changes, 1);
db.prepare(`INSERT INTO operation_log(note_id,op_id,op_timestamp,editor_site_id)
  VALUES('source-note-import-copy','op:1:0',1,0)`).run();
assert.equal(db.prepare(`SELECT max_op_timestamp FROM note_sync_metadata
  WHERE note_id='source-note-import-copy'`).get().max_op_timestamp, 1);

assert.throws(() => createImportedNote('failed-copy', 'source-note', 'source-page'));
assert.equal(db.prepare(`SELECT COUNT(*) count FROM note_meta WHERE id='failed-copy'`).get().count, 0);
assert.equal(db.prepare(`SELECT COUNT(*) count FROM note_sync_metadata WHERE note_id='failed-copy'`).get().count, 0);
assert.equal(db.prepare(`SELECT COUNT(*) count FROM note_meta WHERE id='source-note'`).get().count, 1);

console.log('success|legacy=source-note|editor=local-editor|pages=isolated|clock=1|rollback=1');
