import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const schema = read('note/src/main/ets/data/DatabaseHelper.ets');
const envelope = read('note/src/main/ets/data/OriginalSyncedOperationFlatBuffer.ets');
const incoming = read('note/src/main/ets/data/IncomingOperationSyncCoordinator.ets');
const inbox = read('note/src/main/ets/data/SyncedOperationInbox.ets');
const timingStore = read('note/src/main/ets/data/OriginalOperationAudioTimeStore.ets');
const noteBundle = read('note/src/main/ets/data/OriginalNoteBundlePageIdentity.ets');
const fixture = read('note/src/test/SyncedOperationInbox.test.ets');
const timingDdl = extractTemplate(schema, 'DDL_ORIGINAL_APPLIED_OPERATION_TIME');

const db = new DatabaseSync(':memory:');
db.exec(`PRAGMA foreign_keys=ON; PRAGMA user_version=57;
  CREATE TABLE note_meta(id TEXT PRIMARY KEY);
  INSERT INTO note_meta(id) VALUES('n'),('other');`);

db.exec('BEGIN IMMEDIATE');
db.exec(timingDdl);
db.exec('PRAGMA user_version=58');
db.exec('COMMIT');
assert.equal(db.prepare('PRAGMA user_version').get().user_version, 58);

const insert = db.prepare(`INSERT INTO original_applied_operation_time
  (note_id,op_timestamp,op_site_id,client_time,audio_time,payload_type)
  VALUES(?,?,?,?,?,?)`);
insert.run('n', 1, 7, '9007199254740993', '18446744073709551615', 15);
insert.run('n', 2, 7, '20', null, 16);
let rows = db.prepare(`SELECT op_timestamp,client_time,audio_time,
  COALESCE(audio_time,client_time) effective_time
  FROM original_applied_operation_time WHERE note_id='n'
  ORDER BY length(COALESCE(audio_time,client_time)),COALESCE(audio_time,client_time)`).all();
assert.deepEqual(rows.map(row => row.op_timestamp), [2, 1]);
assert.equal(rows[0].effective_time, '20');
assert.equal(rows[1].audio_time, '18446744073709551615');

assert.throws(() => insert.run('n', 1, 7, '1', '2', 15), /UNIQUE constraint failed/);
assert.throws(() => insert.run('n', 3, 7, '01', null, 15), /CHECK constraint failed/);
assert.throws(() => insert.run('n', 3, 7, '21', '18446744073709551616', 15),
  /CHECK constraint failed/);

db.exec('BEGIN IMMEDIATE');
insert.run('other', 9, 1, '9', '8', 15);
db.exec('ROLLBACK');
assert.equal(db.prepare(`SELECT COUNT(*) count FROM original_applied_operation_time
  WHERE note_id='other'`).get().count, 0);
db.exec("DELETE FROM note_meta WHERE id='n'");
assert.equal(db.prepare('SELECT COUNT(*) count FROM original_applied_operation_time').get().count, 0);
db.close();

const failed = new DatabaseSync(':memory:');
failed.exec(`PRAGMA foreign_keys=ON; PRAGMA user_version=57;
  CREATE TABLE note_meta(id TEXT PRIMARY KEY);`);
assert.throws(() => {
  failed.exec('BEGIN IMMEDIATE');
  try {
    failed.exec(timingDdl);
    throw new Error('injected v58 failure');
  } catch (error) {
    failed.exec('ROLLBACK');
    throw error;
  }
}, /injected v58 failure/);
assert.equal(failed.prepare('PRAGMA user_version').get().user_version, 57);
assert.equal(failed.prepare(`SELECT COUNT(*) count FROM sqlite_master
  WHERE type='table' AND name='original_applied_operation_time'`).get().count, 0);
failed.close();

assert.match(schema, /DB_VERSION: number = 58/);
assert.match(schema, /58: \[\s*DDL_ORIGINAL_APPLIED_OPERATION_TIME/);
assert.match(envelope, /audioTime: string \| null/);
assert.match(envelope, /fieldOffset\(bytes, root, 3\)/);
assert.match(envelope, /audioOffset === 0 \? null/);
assert.match(incoming, /audioTime: envelope\.audioTime/);
assert.match(inbox, /persistOriginalAppliedOperationTime\(this\.store/);
assert.match(timingStore, /WHERE inbox\.state = 2 AND timing\.note_id IS NULL/);
assert.match(timingStore, /effectiveAudioTime: audioTime === null \? clientTime : audioTime/);
assert.match(noteBundle, /audioTime: table\.readUint64Decimal\(3, null\)/);
assert.match(noteBundle, /transient: table\.hasField\(6\)/);
assert.doesNotMatch(noteBundle, /transient: table\.readUint8\(3/);
assert.match(noteBundle, /persistOriginalAppliedOperationTime\(store/);
assert.match(fixture, /expect\(bundle\.operations\[1\]\.audioTime\)\.assertEqual\('19'\)/);

console.log('D02_OPERATION_AUDIO_TIME_REPLAY_OK ' +
  'uq9-field3=1|uint64-exact=1|null-fallback-client=1|applied-only=1|' +
  'inbox-backfill=1|note-bundle-field6-transient=1|note-bundle-persist=1|' +
  'idempotent-conflict=1|v57-v58=1|rollback=2|cascade=1');

function extractTemplate(source, name) {
  const match = source.match(new RegExp('(?:export )?const ' + name +
    ': string = `([\\s\\S]*?)`;'));
  assert(match, `${name} missing`);
  return match[1];
}
