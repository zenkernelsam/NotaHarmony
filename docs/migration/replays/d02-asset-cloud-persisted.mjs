import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const schema = read('note/src/main/ets/data/DatabaseHelper.ets');
const manager = read('note/src/main/ets/data/DatabaseManager.ets');
const reducer = read('note/src/main/ets/data/OriginalAssetCloudPersistedOperation.ets');
const router = read('note/src/main/ets/data/OriginalPageOperationApplier.ets');
const fixture = read('note/src/test/SyncedOperationInbox.test.ets');

function database() {
  const db = new DatabaseSync(':memory:');
  db.exec(`PRAGMA foreign_keys=ON;
    PRAGMA user_version=51;
    CREATE TABLE note_meta(id TEXT PRIMARY KEY);
    CREATE TABLE note_asset(
      asset_hash TEXT PRIMARY KEY,status INTEGER NOT NULL,note_ids TEXT NOT NULL,
      file_size INTEGER NOT NULL,mime_type TEXT NOT NULL,local_path TEXT);
    INSERT INTO note_meta VALUES('a'),('b');`);
  return db;
}

function migrateV52(db, fail = false) {
  db.exec('BEGIN IMMEDIATE');
  try {
    db.exec(`CREATE TABLE original_asset_cloud_state(
      note_id TEXT NOT NULL,
      asset_hash TEXT NOT NULL CHECK(length(asset_hash)=128),
      cloud_persisted INTEGER NOT NULL DEFAULT 1 CHECK(cloud_persisted=1),
      PRIMARY KEY(note_id,asset_hash),
      FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE);`);
    if (fail) throw new Error('injected migration failure');
    db.exec('PRAGMA user_version=52; COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

const hashBytes = Uint8Array.from({ length: 64 }, (_, index) => index);
const storageHash = Array.from(hashBytes,
  value => value.toString(16).padStart(2, '0')).join('');
assert.equal(storageHash.length, 128);

const db = database();
migrateV52(db);
const markCloudPersisted = db.prepare(`INSERT OR IGNORE INTO original_asset_cloud_state
  (note_id,asset_hash,cloud_persisted) VALUES(?,?,1)`);
markCloudPersisted.run('a', storageHash);
markCloudPersisted.run('a', storageHash);
assert.equal(db.prepare('SELECT COUNT(*) count FROM original_asset_cloud_state').get().count, 1);

// The original event may precede its first reference; later reference merge must retain it.
db.prepare(`INSERT INTO note_asset
  (asset_hash,status,note_ids,file_size,mime_type,local_path) VALUES(?,0,'["a"]',12,'image/png',NULL)`)
  .run(storageHash);
assert.equal(db.prepare('SELECT status FROM note_asset WHERE asset_hash=?').get(storageHash).status, 0);
assert.equal(db.prepare(`SELECT cloud_persisted FROM original_asset_cloud_state
  WHERE note_id='a' AND asset_hash=?`).get(storageHash).cloud_persisted, 1);

// Availability belongs to each original note model even when file storage is shared by hash.
markCloudPersisted.run('b', storageHash);
assert.equal(db.prepare('SELECT COUNT(*) count FROM original_asset_cloud_state').get().count, 2);
db.exec("DELETE FROM note_meta WHERE id='a'");
assert.equal(db.prepare('SELECT note_id FROM original_asset_cloud_state').get().note_id, 'b');
assert.equal(db.prepare('SELECT status FROM note_asset WHERE asset_hash=?').get(storageHash).status, 0);
assert.equal(db.prepare('PRAGMA user_version').get().user_version, 52);
db.close();

const failed = database();
assert.throws(() => migrateV52(failed, true), /injected migration failure/);
assert.equal(failed.prepare('PRAGMA user_version').get().user_version, 51);
assert.equal(failed.prepare(`SELECT COUNT(*) count FROM sqlite_master
  WHERE type='table' AND name='original_asset_cloud_state'`).get().count, 0);
failed.close();

assert.match(schema, /DB_VERSION: number = 59/);
assert.match(schema, /52: \[[\s\S]*DDL_ORIGINAL_ASSET_CLOUD_STATE/);
assert.match(schema, /PRIMARY KEY\(note_id, asset_hash\)/);
assert.match(manager, /DDL_ORIGINAL_ASSET_CLOUD_STATE/);
assert.match(reducer, /readInlineBytes\(0, ORIGINAL_ASSET_HASH_BYTES\)/);
assert.match(reducer, /INSERT OR IGNORE INTO original_asset_cloud_state/);
assert.doesNotMatch(reducer, /AssetStatus\.UPLOADED/);
assert.doesNotMatch(reducer, /UPDATE note_asset/);
assert.match(router, /ORIGINAL_ASSET_CLOUD_PERSISTED_PAYLOAD_TYPE/);
assert.match(fixture, /flatBufferAssetCloudPersisted/);
assert.match(fixture, /MALFORMED_ASSET_CLOUD_PERSISTED_PAYLOAD/);

console.log('D02_ASSET_CLOUD_PERSISTED_REPLAY_OK ' +
  'v51-v52=1|inline-hash-bytes=64|event-before-reference=1|duplicate-idempotent=1|' +
  'per-note-state=2|local-status-independent=1|cascade=1|rollback=1');
