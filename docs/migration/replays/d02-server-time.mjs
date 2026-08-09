import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';

const UINT64_MAX = '18446744073709551615';

function createV18Database() {
  const db = new DatabaseSync(':memory:');
  db.exec(`
    PRAGMA foreign_keys=ON;
    CREATE TABLE note_meta(id TEXT PRIMARY KEY);
    CREATE TABLE note_sync_metadata(
      note_id TEXT PRIMARY KEY,
      legacy_id TEXT,
      editor_site_id INTEGER NOT NULL CHECK(editor_site_id BETWEEN 0 AND 65535),
      editor_id TEXT NOT NULL,
      creator_id TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      max_server_time INTEGER,
      synced_op_count INTEGER NOT NULL DEFAULT 0 CHECK(synced_op_count>=0),
      max_op_timestamp INTEGER NOT NULL DEFAULT 0 CHECK(max_op_timestamp BETWEEN 0 AND 4294967295),
      schema_version INTEGER NOT NULL DEFAULT 1,
      uploaded_through_sequence INTEGER NOT NULL DEFAULT 0 CHECK(uploaded_through_sequence>=0),
      acked_through_sequence INTEGER NOT NULL DEFAULT 0 CHECK(acked_through_sequence>=0),
      CHECK(acked_through_sequence<=uploaded_through_sequence),
      FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE);
    INSERT INTO note_meta VALUES('legacy'),('empty');
    INSERT INTO note_sync_metadata VALUES
      ('legacy',NULL,0,'editor','editor',1,2,900,3,4,1,5,5),
      ('empty',NULL,0,'editor','editor',1,2,NULL,0,0,1,0,0);
    PRAGMA user_version=18;
  `);
  return db;
}

function migrate19(db, failBeforeRename = false) {
  db.exec('BEGIN IMMEDIATE');
  try {
    db.exec(`
      CREATE TABLE note_sync_metadata_v19(
        note_id TEXT PRIMARY KEY,
        legacy_id TEXT,
        editor_site_id INTEGER NOT NULL CHECK(editor_site_id BETWEEN 0 AND 65535),
        editor_id TEXT NOT NULL,
        creator_id TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        max_server_time TEXT CHECK (max_server_time IS NULL OR (
          typeof(max_server_time)='text' AND length(max_server_time) BETWEEN 1 AND 20
          AND max_server_time NOT GLOB '*[^0-9]*'
          AND (max_server_time='0' OR substr(max_server_time,1,1)<>'0')
          AND (length(max_server_time)<20 OR max_server_time<='18446744073709551615'))),
        synced_op_count INTEGER NOT NULL DEFAULT 0 CHECK(synced_op_count>=0),
        max_op_timestamp INTEGER NOT NULL DEFAULT 0 CHECK(max_op_timestamp BETWEEN 0 AND 4294967295),
        schema_version INTEGER NOT NULL DEFAULT 1,
        uploaded_through_sequence INTEGER NOT NULL DEFAULT 0 CHECK(uploaded_through_sequence>=0),
        acked_through_sequence INTEGER NOT NULL DEFAULT 0 CHECK(acked_through_sequence>=0),
        CHECK(acked_through_sequence<=uploaded_through_sequence),
        FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE);
      INSERT INTO note_sync_metadata_v19
        SELECT note_id,legacy_id,editor_site_id,editor_id,creator_id,created_at,updated_at,
          CASE WHEN max_server_time IS NULL THEN NULL ELSE CAST(max_server_time AS TEXT) END,
          synced_op_count,max_op_timestamp,schema_version,
          uploaded_through_sequence,acked_through_sequence
        FROM note_sync_metadata;
      DROP TABLE note_sync_metadata;
    `);
    if (failBeforeRename) {
      throw new Error('fault before v19 rename');
    }
    db.exec(`
      ALTER TABLE note_sync_metadata_v19 RENAME TO note_sync_metadata;
      PRAGMA user_version=19;
    `);
    db.exec('COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

const db = createV18Database();
migrate19(db);
assert.equal(db.prepare('PRAGMA user_version').get().user_version, 19);
assert.deepEqual({ ...db.prepare(`SELECT max_server_time value,typeof(max_server_time) type
  FROM note_sync_metadata WHERE note_id='legacy'`).get() }, { value: '900', type: 'text' });
assert.equal(db.prepare(`SELECT max_server_time FROM note_sync_metadata
  WHERE note_id='empty'`).get().max_server_time, null);

for (const value of ['9007199254740993', UINT64_MAX]) {
  db.prepare(`UPDATE note_sync_metadata SET max_server_time=? WHERE note_id='legacy'`).run(value);
  assert.deepEqual({ ...db.prepare(`SELECT max_server_time value,typeof(max_server_time) type
    FROM note_sync_metadata WHERE note_id='legacy'`).get() }, { value, type: 'text' });
}

for (const invalid of ['00', '01', '-1', '1x', '18446744073709551616']) {
  assert.throws(() => db.prepare(`UPDATE note_sync_metadata SET max_server_time=?
    WHERE note_id='legacy'`).run(invalid));
  assert.equal(db.prepare(`SELECT max_server_time FROM note_sync_metadata
    WHERE note_id='legacy'`).get().max_server_time, UINT64_MAX);
}

const rollbackDb = createV18Database();
assert.throws(() => migrate19(rollbackDb, true));
assert.equal(rollbackDb.prepare('PRAGMA user_version').get().user_version, 18);
assert.deepEqual({ ...rollbackDb.prepare(`SELECT max_server_time value,typeof(max_server_time) type
  FROM note_sync_metadata WHERE note_id='legacy'`).get() }, { value: 900, type: 'integer' });
assert.equal(rollbackDb.prepare(`SELECT COUNT(*) count FROM sqlite_master
  WHERE type='table' AND name='note_sync_metadata_v19'`).get().count, 0);

console.log('success|v18-v19=900-text|above-safe=1|uint64-max=1|invalid=5|rollback=1');
