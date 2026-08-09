import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';

function crc32Signed(bytes) {
  let crc = 0xFFFFFFFF;
  for (const byte of bytes) {
    crc ^= byte;
    for (let bit = 0; bit < 8; bit++) {
      crc = (crc >>> 1) ^ ((crc & 1) === 0 ? 0 : 0xEDB88320);
    }
  }
  return (crc ^ 0xFFFFFFFF) | 0;
}

function writeU16(bytes, offset, value) {
  bytes.writeUInt16LE(value, offset);
}

function op(timestamp, site, clientTime, serverTime, payloadType) {
  const bytes = Buffer.alloc(68);
  bytes.writeUInt32LE(24, 0);
  writeU16(bytes, 4, 18);
  writeU16(bytes, 6, 36);
  for (const [entry, value] of [[8, 4], [10, 12], [12, 20], [16, 28], [18, 32]]) {
    writeU16(bytes, entry, value);
  }
  bytes.writeInt32LE(20, 24);
  writeU16(bytes, 28, site);
  bytes.writeUInt32LE(timestamp, 32);
  bytes.writeBigUInt64LE(BigInt(clientTime), 36);
  bytes.writeBigUInt64LE(BigInt(serverTime), 44);
  bytes[52] = payloadType;
  bytes.writeUInt32LE(8, 56);
  writeU16(bytes, 60, 4);
  writeU16(bytes, 62, 4);
  bytes.writeInt32LE(4, 64);
  return bytes;
}

function parseEnvelope(bytes) {
  bytes = Buffer.from(bytes);
  assert.ok(bytes.length >= 8);
  const table = bytes.readUInt32LE(0);
  assert.ok(table >= 4 && table <= bytes.length - 4);
  const vtable = table - bytes.readInt32LE(table);
  const vtableSize = bytes.readUInt16LE(vtable);
  const objectSize = bytes.readUInt16LE(vtable + 2);
  assert.ok(vtableSize >= 4 && (vtableSize & 1) === 0 && table + objectSize <= bytes.length);
  const field = index => vtable + 6 + index * 2 <= vtable + vtableSize
    ? bytes.readUInt16LE(vtable + 4 + index * 2) : 0;
  const id = field(0);
  const client = field(1);
  const server = field(2);
  const type = field(4);
  const payload = field(5);
  assert.ok(id >= 4 && id + 8 <= objectSize && server >= 4 && server + 8 <= objectSize);
  const payloadType = type === 0 ? 0 : bytes[table + type];
  if (payloadType !== 0) {
    assert.ok(payload >= 4 && payload + 4 <= objectSize);
    const pointer = table + payload;
    const target = pointer + bytes.readUInt32LE(pointer);
    assert.ok(target <= bytes.length - 4 && bytes.readInt32LE(target) > 0);
  }
  return {
    timestamp: bytes.readUInt32LE(table + id + 4),
    site: bytes.readUInt16LE(table + id),
    clientTime: client === 0 ? '0' : bytes.readBigUInt64LE(table + client).toString(),
    serverTime: bytes.readBigUInt64LE(table + server).toString(),
    payloadType,
  };
}

function migrate21(db) {
  db.exec(`BEGIN IMMEDIATE;
    DELETE FROM deferred_synced_operation_bundle
      WHERE table_type NOT IN ('NOTE_BUNDLE','OPS_BUNDLE','RECEIVE_OPS_EVENT');
    CREATE TABLE deferred_synced_operation_bundle_v21(
      id INTEGER PRIMARY KEY AUTOINCREMENT,note_id TEXT NOT NULL,
      schema_version INTEGER NOT NULL CHECK(schema_version BETWEEN 0 AND 65535),
      table_type TEXT NOT NULL CHECK(table_type IN('NOTE_BUNDLE','OPS_BUNDLE','RECEIVE_OPS_EVENT')),
      payload BLOB NOT NULL,payload_size INTEGER NOT NULL CHECK(payload_size BETWEEN 1 AND 67108864),
      checksum INTEGER NOT NULL CHECK(checksum BETWEEN -2147483648 AND 2147483647),
      received_at INTEGER NOT NULL,CHECK(length(payload)=payload_size),
      FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE);
    INSERT INTO deferred_synced_operation_bundle_v21 SELECT * FROM deferred_synced_operation_bundle;
    DROP TABLE deferred_synced_operation_bundle;
    ALTER TABLE deferred_synced_operation_bundle_v21 RENAME TO deferred_synced_operation_bundle;
    PRAGMA user_version=21; COMMIT;`);
}

function processHead(db, noteId, injectFault = false) {
  db.exec('BEGIN IMMEDIATE');
  try {
    const row = db.prepare(`SELECT * FROM synced_operation_inbox WHERE note_id=? AND state<>2
      ORDER BY length(server_time),server_time,length(client_time),client_time LIMIT 1`).get(noteId);
    if (!row) {
      db.exec('COMMIT');
      return 'empty';
    }
    if (row.state === 1) {
      db.exec('COMMIT');
      return 'blocked';
    }
    const envelope = parseEnvelope(row.raw_operation);
    assert.deepEqual({ timestamp: envelope.timestamp, site: envelope.site,
      clientTime: envelope.clientTime, serverTime: envelope.serverTime,
      payloadType: envelope.payloadType }, {
      timestamp: row.op_timestamp, site: row.editor_site_id, clientTime: row.client_time,
      serverTime: row.server_time, payloadType: row.payload_type,
    });
    if (envelope.payloadType < 1 || envelope.payloadType > 31) {
      db.prepare(`UPDATE synced_operation_inbox SET state=1,
        deferred_reason='UNKNOWN_ORIGINAL_PAYLOAD_TYPE' WHERE note_id=? AND op_timestamp=?`)
        .run(noteId, row.op_timestamp);
      db.exec('COMMIT');
      return 'deferred';
    }
    db.prepare('INSERT INTO applied_effect VALUES(?,?)').run(noteId, row.op_timestamp);
    if (injectFault) throw new Error('fault after payload apply');
    db.prepare(`UPDATE note_sync_metadata SET max_server_time=?,synced_op_count=synced_op_count+1
      WHERE note_id=?`).run(row.server_time, noteId);
    db.prepare(`UPDATE synced_operation_inbox SET state=2,deferred_reason=NULL
      WHERE note_id=? AND op_timestamp=? AND state=0`).run(noteId, row.op_timestamp);
    db.exec('COMMIT');
    return 'applied';
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

const db = new DatabaseSync(':memory:');
db.exec(`PRAGMA foreign_keys=ON;
  CREATE TABLE note_meta(id TEXT PRIMARY KEY);
  INSERT INTO note_meta VALUES('note');
  CREATE TABLE note_sync_metadata(note_id TEXT PRIMARY KEY,max_server_time TEXT,synced_op_count INTEGER);
  INSERT INTO note_sync_metadata VALUES('note',NULL,0);
  CREATE TABLE synced_operation_inbox(note_id TEXT,op_timestamp INTEGER,editor_site_id INTEGER,
    client_time TEXT,server_time TEXT,schema_version INTEGER,payload_type INTEGER,raw_operation BLOB,
    state INTEGER DEFAULT 0,deferred_reason TEXT,received_at INTEGER,
    PRIMARY KEY(note_id,op_timestamp,editor_site_id));
  CREATE TABLE deferred_synced_operation_bundle(id INTEGER PRIMARY KEY AUTOINCREMENT,note_id TEXT,
    schema_version INTEGER,table_type TEXT,payload BLOB,payload_size INTEGER,checksum INTEGER,received_at INTEGER);
  CREATE TABLE applied_effect(note_id TEXT,op_timestamp INTEGER);
  PRAGMA user_version=20;`);

const known = op(1, 7, '9007199254740993', '18446744073709551614', 31);
const unknown = op(2, 7, '18446744073709551614', '18446744073709551615', 99);
assert.equal(crc32Signed(Buffer.from('123456789')), -873187034);
db.prepare(`INSERT INTO deferred_synced_operation_bundle(note_id,schema_version,table_type,payload,
  payload_size,checksum,received_at) VALUES('note',1,?,?,?,?,1000)`).run('OPS_BUNDLE', known,
  known.length, crc32Signed(known));
db.prepare(`INSERT INTO deferred_synced_operation_bundle(note_id,schema_version,table_type,payload,
  payload_size,checksum,received_at) VALUES('note',1,'OPS',X'01',1,0,1000)`).run();
migrate21(db);
assert.equal(db.prepare('PRAGMA user_version').get().user_version, 21);
assert.equal(db.prepare('SELECT COUNT(*) count FROM deferred_synced_operation_bundle').get().count, 1);
assert.throws(() => db.prepare(`INSERT INTO deferred_synced_operation_bundle(note_id,schema_version,
  table_type,payload,payload_size,checksum,received_at) VALUES('note',1,'OPS',X'01',1,0,1)`).run());

db.prepare(`INSERT INTO synced_operation_inbox VALUES('note',1,7,?,?,?,?,?,0,NULL,1000)`).run(
  '9007199254740993', '18446744073709551614', 1, 31, known);
assert.throws(() => processHead(db, 'note', true));
assert.equal(db.prepare('SELECT COUNT(*) count FROM applied_effect').get().count, 0);
assert.deepEqual({ ...db.prepare('SELECT max_server_time,synced_op_count FROM note_sync_metadata').get() },
  { max_server_time: null, synced_op_count: 0 });
assert.equal(processHead(db, 'note'), 'applied');

db.prepare(`INSERT INTO synced_operation_inbox VALUES('note',2,7,?,?,?,?,?,0,NULL,1000)`).run(
  '18446744073709551614', '18446744073709551615', 1, 99, unknown);
db.prepare(`INSERT INTO synced_operation_inbox VALUES('note',3,7,?,?,?,?,?,0,NULL,1000)`).run(
  '18446744073709551615', '18446744073709551615', 1, 31,
  op(3, 7, '18446744073709551615', '18446744073709551615', 31));
assert.equal(processHead(db, 'note'), 'deferred');
assert.equal(processHead(db, 'note'), 'blocked');
assert.deepEqual({ ...db.prepare('SELECT max_server_time,synced_op_count FROM note_sync_metadata').get() },
  { max_server_time: '18446744073709551614', synced_op_count: 1 });
assert.equal(db.prepare('SELECT state FROM synced_operation_inbox WHERE op_timestamp=3').get().state, 0);

const bundle = db.prepare('SELECT payload,payload_size,checksum FROM deferred_synced_operation_bundle').get();
assert.equal(bundle.payload.length, bundle.payload_size);
assert.equal(crc32Signed(bundle.payload), bundle.checksum);

console.log('success|v20-v21=1|crc32=signed|flatbuffer=uq9|rollback=1|applied=1|unknown-deferred=1|gap-blocked=1');
