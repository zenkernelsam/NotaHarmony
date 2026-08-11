import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalEnvelope = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/zq9.java', 'utf8');
const originalMetadata = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/wq9.java', 'utf8');
const originalTransientEnd = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/oqi.java', 'utf8');
const originalInkSession = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/kt1.java', 'utf8');
const originalCreateCoroutine = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/bt1.java', 'utf8');
const envelopeEncoder = read('note/src/main/ets/data/OriginalOperationEnvelopeEncoder.ets');
const envelopeDecoder = read('note/src/main/ets/data/OriginalSyncedOperationFlatBuffer.ets');
const appendEncoder = read('note/src/main/ets/data/OriginalAddPathElementsPayloadEncoder.ets');
const pathEncoder = read('note/src/main/ets/data/OriginalInkPathEncoder.ets');
const transientEncoder = read('note/src/main/ets/data/OriginalTransientInteractionPayloadEncoder.ets');
const repair = read('note/src/main/ets/data/OriginalOutboundOperationRepair.ets');
const database = read('note/src/main/ets/data/DatabaseManager.ets');
const pagePersistence = read('note/src/main/ets/data/OriginalPagePersistence.ets');
const strokePersistence = read('note/src/main/ets/data/StrokePersistence.ets');
const recordingPersistence = read('note/src/main/ets/data/OriginalRecordingPersistence.ets');
const recordingStore = read('note/src/main/ets/data/OriginalRecordingStore.ets');
const tests = read('note/src/test/OriginalCreateInkPayloadEncoder.test.ets');

assert.match(originalEnvelope, /aVar\.C\(7\)/);
assert.match(originalEnvelope, /aVar\.j\(0, rh8\.O\(qo5Var, aVar\)\)/);
assert.match(originalEnvelope, /aVar\.f\(1, j\)/);
assert.match(originalEnvelope, /if \(tmfVar != null\)[\s\S]*aVar\.f\(2, tmfVar\.I\)/);
assert.match(originalEnvelope, /aVar\.c\(4, b\(ceeVar\)\.I, 0\)/);
assert.match(originalEnvelope, /aVar\.h\(5, iA\)/);
assert.match(originalEnvelope,
  /e\(aVarA, qo5Var, ceeVar, j, null, xgbVar != null \? new tmf\(xgbVar\.I\) : null, null\)/);
assert.match(originalMetadata, /case 26:[\s\S]*case[^:]*29[^:]*:[\s\S]*z2 = true/);
assert.match(originalMetadata, /this\.f = qo5VarJ/);
assert.match(originalTransientEnd, /aVarA\.C\(2\)/);
assert.match(originalTransientEnd, /aVarA\.j\(0, rh8\.O\(qo5Var, aVarA\)\)/);
assert.match(originalInkSession, /u5j\.a\(a\(\), qo5Var, arrayList, arrayList2\)/);
assert.match(originalCreateCoroutine,
  /new wq9\(\(dm2\) obj6, null, true, \(xgb\) obj5, 10\)/);

assert.match(envelopeEncoder, /writeVtable\(bytes, 4, 48/);
assert.match(envelopeEncoder, /metadata\.serverTime === null \? 0 : 20/);
assert.match(envelopeEncoder, /childStart \+ childTableOffset - \(rootTable \+ 40\)/);
assert.match(envelopeDecoder, /parseOriginalOperationEnvelope/);
assert.match(envelopeDecoder, /synced FlatBuffer operation has no serverTime/);
assert.match(appendEncoder, /local ADD_PATH_ELEMENTS requires actual or estimated path/);
assert.match(pathEncoder, /an append must never contain a MOVE element/);
assert.match(pathEncoder, /bytes\[0\] = 1/);
assert.match(transientEncoder, /encodeOriginalTransientInteractionEndedPayload/);
assert.match(repair, /parseOriginalOperationEnvelope/);
assert.match(repair, /decodeOriginalCreateRecordingTable/);
assert.match(repair, /operation\.op_type = \?/);
assert.match(repair, /stored original outbound envelope disagrees with its operation row/);
assert.ok(database.indexOf('repairLegacyOriginalOutboundEnvelopes(store)') <
  database.indexOf('backfillOriginalAppliedOperationTimes(store)'));
for (const producer of [pagePersistence, strokePersistence, recordingPersistence, recordingStore]) {
  assert.match(producer, /encodeOriginalOperationEnvelope/);
  assert.match(producer, /payload: (operation\.rawOperation|rawOperation)/);
}
assert.match(tests, /round-trips ADD_PATH_ELEMENTS actual and estimated attributed appends/);
assert.match(tests, /round-trips transient interaction end replacement metadata/);

function writeU16(bytes, offset, value) {
  bytes[offset] = value & 0xff;
  bytes[offset + 1] = value >>> 8 & 0xff;
}

function writeU32(bytes, offset, value) {
  bytes[offset] = value & 0xff;
  bytes[offset + 1] = value >>> 8 & 0xff;
  bytes[offset + 2] = value >>> 16 & 0xff;
  bytes[offset + 3] = value >>> 24 & 0xff;
}

function readU16(bytes, offset) {
  return bytes[offset] + bytes[offset + 1] * 0x100;
}

function readU32(bytes, offset) {
  return (bytes[offset] + bytes[offset + 1] * 0x100 + bytes[offset + 2] * 0x10000 +
    bytes[offset + 3] * 0x1000000) >>> 0;
}

function writeU64(bytes, offset, value) {
  let remaining = BigInt(value);
  for (let index = 0; index < 8; index++) {
    bytes[offset + index] = Number(remaining & 0xffn);
    remaining >>= 8n;
  }
  assert.equal(remaining, 0n);
}

function readU64(bytes, offset) {
  let result = 0n;
  for (let index = 7; index >= 0; index--) result = result << 8n | BigInt(bytes[offset + index]);
  return result.toString();
}

function writeVtable(bytes, offset, objectSize, fields) {
  writeU16(bytes, offset, 4 + fields.length * 2);
  writeU16(bytes, offset + 2, objectSize);
  fields.forEach((field, index) => writeU16(bytes, offset + 4 + index * 2, field));
}

function childPayload(marker) {
  const bytes = new Uint8Array(20);
  writeU32(bytes, 0, 12);
  writeVtable(bytes, 4, 8, [4]);
  writeU32(bytes, 12, 8);
  bytes[16] = marker;
  return bytes;
}

function encodeEnvelope({ timestamp, siteId, clientTime, audioTime, payloadType }, payload) {
  const rootTable = 24;
  const childStart = 72;
  const childTable = readU32(payload, 0);
  const bytes = new Uint8Array(childStart + payload.length);
  writeU32(bytes, 0, rootTable);
  writeVtable(bytes, 4, 48, [4, 12, 0, audioTime === null ? 0 : 28, 36, 40, 0]);
  writeU32(bytes, rootTable, 20);
  writeU16(bytes, rootTable + 4, siteId);
  writeU32(bytes, rootTable + 8, timestamp);
  writeU64(bytes, rootTable + 12, clientTime);
  if (audioTime !== null) writeU64(bytes, rootTable + 28, audioTime);
  bytes[rootTable + 36] = payloadType;
  writeU32(bytes, rootTable + 40, childStart + childTable - (rootTable + 40));
  bytes.set(payload, childStart);
  return bytes;
}

function table(bytes, position = readU32(bytes, 0)) {
  const vtable = position - readU32(bytes, position);
  const size = readU16(bytes, vtable);
  assert.ok(vtable >= 4 && size >= 4 && vtable + size <= position);
  return { position, vtable, size };
}

function field(bytes, parsed, index) {
  const entry = parsed.vtable + 4 + index * 2;
  return entry + 2 <= parsed.vtable + parsed.size ? readU16(bytes, entry) : 0;
}

function parseEnvelope(bytes) {
  const rootTable = table(bytes);
  const id = field(bytes, rootTable, 0);
  const client = field(bytes, rootTable, 1);
  const server = field(bytes, rootTable, 2);
  const audio = field(bytes, rootTable, 3);
  const type = field(bytes, rootTable, 4);
  const payload = field(bytes, rootTable, 5);
  assert.notEqual(id, 0);
  assert.notEqual(payload, 0);
  const pointer = rootTable.position + payload;
  const child = table(bytes, pointer + readU32(bytes, pointer));
  return {
    timestamp: readU32(bytes, rootTable.position + id + 4),
    siteId: readU16(bytes, rootTable.position + id),
    clientTime: client === 0 ? '0' : readU64(bytes, rootTable.position + client),
    serverTime: server === 0 ? null : readU64(bytes, rootTable.position + server),
    audioTime: audio === 0 ? null : readU64(bytes, rootTable.position + audio),
    payloadType: type === 0 ? 0 : bytes[rootTable.position + type],
    marker: bytes[child.position + 4],
  };
}

const child = childPayload(0x5a);
const full = encodeEnvelope({ timestamp: 9, siteId: 7, clientTime: '1234', audioTime: '88',
  payloadType: 5 }, child);
assert.deepEqual(parseEnvelope(full), { timestamp: 9, siteId: 7, clientTime: '1234',
  serverTime: null, audioTime: '88', payloadType: 5, marker: 0x5a });

const db = new DatabaseSync(':memory:');
db.exec(`CREATE TABLE operation_log(sequence INTEGER PRIMARY KEY,op_timestamp INTEGER,
  editor_site_id INTEGER,client_time TEXT,payload_type INTEGER,payload BLOB);
  CREATE TABLE timing(sequence INTEGER PRIMARY KEY,audio_time TEXT);`);
db.prepare('INSERT INTO operation_log VALUES(1,9,7,\'1234\',5,?)').run(Buffer.from(child));
db.prepare('INSERT INTO timing VALUES(1,\'88\')').run();
db.prepare('INSERT INTO operation_log VALUES(2,10,7,\'1235\',3,?)').run(Buffer.from(
  encodeEnvelope({ timestamp: 10, siteId: 7, clientTime: '1235', audioTime: null,
    payloadType: 3 }, childPayload(0x33))));

function repairRows() {
  const rows = db.prepare(`SELECT operation_log.*,timing.audio_time FROM operation_log
    LEFT JOIN timing USING(sequence) ORDER BY sequence`).all();
  let repaired = 0;
  for (const row of rows) {
    const bytes = new Uint8Array(row.payload);
    let envelope = null;
    try { envelope = parseEnvelope(bytes); } catch { /* legacy payload child */ }
    if (envelope !== null) {
      if (envelope.timestamp !== row.op_timestamp || envelope.siteId !== row.editor_site_id ||
        envelope.clientTime !== row.client_time || envelope.payloadType !== row.payload_type ||
        envelope.audioTime !== row.audio_time) throw new Error('metadata conflict');
      continue;
    }
    const wrapped = encodeEnvelope({ timestamp: row.op_timestamp, siteId: row.editor_site_id,
      clientTime: row.client_time, audioTime: row.audio_time, payloadType: row.payload_type }, bytes);
    db.prepare('UPDATE operation_log SET payload=? WHERE sequence=?').run(Buffer.from(wrapped), row.sequence);
    repaired++;
  }
  return repaired;
}

assert.equal(repairRows(), 1);
assert.equal(repairRows(), 0);
assert.equal(parseEnvelope(new Uint8Array(
  db.prepare('SELECT payload FROM operation_log WHERE sequence=1').get().payload)).audioTime, '88');
db.prepare('UPDATE operation_log SET client_time=\'9999\' WHERE sequence=2').run();
assert.throws(repairRows, /metadata conflict/);
db.close();

console.log('localOperationEnvelope=uq9-original-null-server-child-repair-add-path-transient-end');
