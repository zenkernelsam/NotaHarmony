import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';

const UINT64_MAX = '18446744073709551615';

function createV19Database() {
  const db = new DatabaseSync(':memory:');
  db.exec(`
    PRAGMA foreign_keys=ON;
    CREATE TABLE note_meta(id TEXT PRIMARY KEY);
    CREATE TABLE operation_log(sequence INTEGER PRIMARY KEY AUTOINCREMENT,note_id TEXT NOT NULL,
      op_timestamp INTEGER NOT NULL,editor_site_id INTEGER NOT NULL,payload BLOB NOT NULL,
      FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE);
    CREATE TABLE note_sync_metadata(note_id TEXT PRIMARY KEY,max_server_time TEXT,
      synced_op_count INTEGER NOT NULL,FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE);
    INSERT INTO note_meta VALUES('note');
    INSERT INTO operation_log(note_id,op_timestamp,editor_site_id,payload) VALUES('note',1,7,X'AA');
    INSERT INTO note_sync_metadata VALUES('note','900',1);
    PRAGMA user_version=19;
  `);
  return db;
}

function migrate20(db, failBeforeCommit = false) {
  db.exec('BEGIN IMMEDIATE');
  try {
    db.exec(`
      CREATE TABLE synced_operation_inbox(
        note_id TEXT NOT NULL,
        op_timestamp INTEGER NOT NULL CHECK(op_timestamp BETWEEN 0 AND 4294967295),
        editor_site_id INTEGER NOT NULL CHECK(editor_site_id BETWEEN 0 AND 65535),
        client_time TEXT NOT NULL CHECK(typeof(client_time)='text'
          AND length(client_time) BETWEEN 1 AND 20 AND client_time NOT GLOB '*[^0-9]*'
          AND (client_time='0' OR substr(client_time,1,1)<>'0')
          AND (length(client_time)<20 OR client_time<='18446744073709551615')),
        server_time TEXT NOT NULL CHECK(typeof(server_time)='text'
          AND length(server_time) BETWEEN 1 AND 20 AND server_time NOT GLOB '*[^0-9]*'
          AND (server_time='0' OR substr(server_time,1,1)<>'0')
          AND (length(server_time)<20 OR server_time<='18446744073709551615')),
        schema_version INTEGER NOT NULL CHECK(schema_version BETWEEN 0 AND 65535),
        payload_type INTEGER NOT NULL CHECK(payload_type BETWEEN 0 AND 255),
        raw_operation BLOB NOT NULL CHECK(length(raw_operation) BETWEEN 1 AND 67108864),
        state INTEGER NOT NULL DEFAULT 0 CHECK(state IN(0,1,2)),
        deferred_reason TEXT,
        received_at INTEGER NOT NULL CHECK(received_at BETWEEN 0 AND 9007199254740991),
        CHECK((state=1 AND deferred_reason IS NOT NULL AND length(deferred_reason)>0)
          OR (state IN(0,2) AND deferred_reason IS NULL)),
        PRIMARY KEY(note_id,op_timestamp,editor_site_id),
        FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE);
      CREATE TABLE deferred_synced_operation_bundle(
        id INTEGER PRIMARY KEY AUTOINCREMENT,note_id TEXT NOT NULL,
        schema_version INTEGER NOT NULL CHECK(schema_version BETWEEN 0 AND 65535),
        table_type TEXT NOT NULL CHECK(length(table_type) BETWEEN 1 AND 64),payload BLOB NOT NULL,
        payload_size INTEGER NOT NULL CHECK(payload_size BETWEEN 1 AND 67108864),
        checksum INTEGER NOT NULL CHECK(checksum BETWEEN -2147483648 AND 2147483647),
        received_at INTEGER NOT NULL CHECK(received_at BETWEEN 0 AND 9007199254740991),
        CHECK(length(payload)=payload_size),
        FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE);
    `);
    if (failBeforeCommit) {
      throw new Error('fault before v20 commit');
    }
    db.exec('PRAGMA user_version=20; COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

function compareDecimal(left, right) {
  return left.length === right.length ? left.localeCompare(right) : left.length - right.length;
}

function validateBatch(noteId, operations) {
  const ids = new Set();
  for (let index = 0; index < operations.length; index++) {
    const op = operations[index];
    assert.equal(op.noteId, noteId);
    const id = `${op.timestamp}:${op.site}`;
    assert.ok(!ids.has(id));
    ids.add(id);
    if (index > 0) {
      const previous = operations[index - 1];
      assert.ok(compareDecimal(previous.serverTime, op.serverTime) <= 0);
    }
  }
}

function receiveBatch(db, noteId, operations, faultAt = -1) {
  validateBatch(noteId, operations);
  db.exec('BEGIN IMMEDIATE');
  let inserted = 0;
  let duplicate = 0;
  try {
    assert.ok(db.prepare('SELECT 1 FROM note_meta WHERE id=?').get(noteId));
    for (let index = 0; index < operations.length; index++) {
      const op = operations[index];
      const existing = db.prepare(`SELECT client_time,server_time,schema_version,payload_type,
        hex(raw_operation) raw FROM synced_operation_inbox
        WHERE note_id=? AND op_timestamp=? AND editor_site_id=?`).get(noteId, op.timestamp, op.site);
      if (existing) {
        assert.deepEqual({ ...existing }, {
          client_time: op.clientTime, server_time: op.serverTime, schema_version: op.schemaVersion,
          payload_type: op.payloadType, raw: op.raw.toString('hex').toUpperCase(),
        });
        duplicate++;
      } else {
        db.prepare(`INSERT INTO synced_operation_inbox(note_id,op_timestamp,editor_site_id,
          client_time,server_time,schema_version,payload_type,raw_operation,received_at)
          VALUES(?,?,?,?,?,?,?,?,?)`).run(noteId, op.timestamp, op.site, op.clientTime,
          op.serverTime, op.schemaVersion, op.payloadType, op.raw, 1000);
        inserted++;
      }
      if (index === faultAt) {
        throw new Error('injected receive fault');
      }
    }
    db.exec('COMMIT');
    return { inserted, duplicate };
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

const db = createV19Database();
migrate20(db);
assert.equal(db.prepare('PRAGMA user_version').get().user_version, 20);

const batch = [
  { noteId: 'note', timestamp: 3, site: 9, clientTime: '9007199254740993',
    serverTime: '9007199254740993', schemaVersion: 1, payloadType: 3, raw: Buffer.from([1, 2]) },
  { noteId: 'note', timestamp: 4, site: 9, clientTime: UINT64_MAX,
    serverTime: UINT64_MAX, schemaVersion: 1, payloadType: 4, raw: Buffer.from([3, 4]) },
];
assert.deepEqual(receiveBatch(db, 'note', batch), { inserted: 2, duplicate: 0 });
assert.deepEqual(receiveBatch(db, 'note', batch), { inserted: 0, duplicate: 2 });
assert.deepEqual(db.prepare(`SELECT server_time FROM synced_operation_inbox
  ORDER BY length(server_time),server_time`).all().map(row => row.server_time),
['9007199254740993', UINT64_MAX]);

const localState = db.prepare(`SELECT
  (SELECT COUNT(*) FROM operation_log) local_count,
  (SELECT synced_op_count FROM note_sync_metadata WHERE note_id='note') synced_count,
  (SELECT max_server_time FROM note_sync_metadata WHERE note_id='note') applied_cursor`).get();
assert.deepEqual({ ...localState }, { local_count: 1, synced_count: 1, applied_cursor: '900' });

const conflictBatch = [
  { noteId: 'note', timestamp: 5, site: 9, clientTime: '5', serverTime: '9007199254740993',
    schemaVersion: 1, payloadType: 3, raw: Buffer.from([5]) },
  { ...batch[0], raw: Buffer.from([9, 9]) },
];
assert.throws(() => receiveBatch(db, 'note', conflictBatch));
assert.equal(db.prepare(`SELECT COUNT(*) count FROM synced_operation_inbox
  WHERE op_timestamp=5`).get().count, 0);

db.prepare(`INSERT INTO deferred_synced_operation_bundle
  (note_id,schema_version,table_type,payload,payload_size,checksum,received_at)
  VALUES('note',1,'OPS',X'010203',3,123,1000)`).run();
assert.throws(() => db.prepare(`INSERT INTO deferred_synced_operation_bundle
  (note_id,schema_version,table_type,payload,payload_size,checksum,received_at)
  VALUES('note',1,'OPS',X'010203',2,123,1000)`).run());
assert.throws(() => db.prepare(`INSERT INTO synced_operation_inbox
  (note_id,op_timestamp,editor_site_id,client_time,server_time,schema_version,payload_type,
   raw_operation,received_at) VALUES('note',6,9,'01','10',1,3,X'01',1000)`).run());

const rollbackDb = createV19Database();
assert.throws(() => migrate20(rollbackDb, true));
assert.equal(rollbackDb.prepare('PRAGMA user_version').get().user_version, 19);
assert.equal(rollbackDb.prepare(`SELECT COUNT(*) count FROM sqlite_master
  WHERE type='table' AND name IN('synced_operation_inbox','deferred_synced_operation_bundle')`).get().count, 0);

db.prepare(`DELETE FROM note_meta WHERE id='note'`).run();
assert.equal(db.prepare('SELECT COUNT(*) count FROM synced_operation_inbox').get().count, 0);
assert.equal(db.prepare('SELECT COUNT(*) count FROM deferred_synced_operation_bundle').get().count, 0);

console.log('success|v19-v20=1|inserted=2|idempotent=2|conflict-rollback=1|isolated=1|deferred=1|cascade=1');
