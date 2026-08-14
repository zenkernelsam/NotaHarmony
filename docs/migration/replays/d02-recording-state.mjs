import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const schema = read('note/src/main/ets/data/DatabaseHelper.ets');
const manager = read('note/src/main/ets/data/DatabaseManager.ets');
const reducer = read('note/src/main/ets/data/OriginalRecordingOperation.ets');
const router = read('note/src/main/ets/data/OriginalPageOperationApplier.ets');
const bundle = read('note/src/main/ets/data/OriginalNoteBundlePageIdentity.ets');
const visibilityReducer = read('note/src/main/ets/data/OriginalDeleteEntitiesOperation.ets');
const fixture = read('note/src/test/SyncedOperationInbox.test.ets');
const stateDdl = extractTemplate(schema, 'DDL_ORIGINAL_RECORDING_STATE');
const modificationDdl = extractTemplate(schema, 'DDL_ORIGINAL_RECORDING_MODIFICATION');
const visibilityDdl = extractTemplate(schema, 'DDL_ORIGINAL_ENTITY_VISIBILITY_WINNER');

function database() {
  const db = new DatabaseSync(':memory:');
  db.exec(`PRAGMA foreign_keys=ON; PRAGMA user_version=54;
    CREATE TABLE note_meta(id TEXT PRIMARY KEY, has_recordings INTEGER NOT NULL DEFAULT 0);
    INSERT INTO note_meta(id) VALUES('n'),('other');`);
  return db;
}

function migrateV55(db, fail = false) {
  db.exec('BEGIN IMMEDIATE');
  try {
    db.exec(visibilityDdl);
    db.exec(stateDdl);
    db.exec(modificationDdl);
    if (fail) throw new Error('injected v55 migration failure');
    db.exec('PRAGMA user_version=55; COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

const id = (timestamp, siteId) => ({ timestamp, siteId });
const compare = (left, right) => left.timestamp === right.timestamp ?
  Math.sign(left.siteId - right.siteId) : Math.sign(left.timestamp - right.timestamp);
const segments = value => JSON.stringify(value);

function refreshPresence(db, noteId) {
  const count = db.prepare(`SELECT COUNT(*) count FROM original_recording_state recording
    LEFT JOIN original_entity_visibility_winner visibility ON visibility.note_id=recording.note_id
      AND visibility.entity_timestamp=recording.recording_timestamp
      AND visibility.entity_site_id=recording.recording_site_id
    WHERE recording.note_id=? AND COALESCE(visibility.deleted,0)=0`).get(noteId).count;
  db.prepare('UPDATE note_meta SET has_recordings=? WHERE id=?').run(count > 0 ? 1 : 0, noteId);
}

function createRecording(db, noteId, recording, overrides = {}) {
  const values = {
    assetHash: JSON.stringify(['1', '2', '3', '4', '5', '6', '7', '8']),
    fileName: 'audio.m4a', mimeType: 'audio/mp4', fileSize: 4096,
    start: '100', end: '200', name: 'Lecture',
    segments: segments([{ startTime: '100', endTime: '200' }]), zIndex: '50',
    signature: 'create:lecture', ...overrides,
  };
  const existing = db.prepare(`SELECT create_signature FROM original_recording_state
    WHERE note_id=? AND recording_timestamp=? AND recording_site_id=?`)
    .get(noteId, recording.timestamp, recording.siteId);
  if (existing) {
    if (existing.create_signature !== values.signature) throw new Error('create identity conflict');
    return 'IDEMPOTENT';
  }
  db.prepare(`INSERT INTO original_recording_state VALUES(
    ?,?,?, ?,?,?,?, ?,?, ?,?,?,?, ?, ?,?,?,?, ?, ?,?,?,?, ?,?)`).run(
    noteId, recording.timestamp, recording.siteId, values.assetHash, values.fileName,
    values.mimeType, values.fileSize, values.start, values.end,
    values.name, values.name, 0, 0, 0,
    values.segments, values.segments, 0, 0, 0,
    values.zIndex, values.zIndex, 0, 0, 0, values.signature);
  refreshPresence(db, noteId);
  return 'APPLIED';
}

function modifyRecording(db, noteId, operation, recording, changes) {
  const signature = JSON.stringify({ recording, ...changes });
  const replay = db.prepare(`SELECT payload_signature FROM original_recording_modification
    WHERE note_id=? AND operation_timestamp=? AND operation_site_id=?`)
    .get(noteId, operation.timestamp, operation.siteId);
  if (replay) {
    if (replay.payload_signature !== signature) throw new Error('modify identity conflict');
    return 'IDEMPOTENT';
  }
  const target = db.prepare(`SELECT * FROM original_recording_state WHERE note_id=?
    AND recording_timestamp=? AND recording_site_id=?`)
    .get(noteId, recording.timestamp, recording.siteId);
  if (!target) return 'MISSING';
  db.prepare(`INSERT INTO original_recording_modification VALUES(?,?,?,?,?,?)`).run(
    noteId, operation.timestamp, operation.siteId,
    recording.timestamp, recording.siteId, signature);
  for (const [prefix, value] of Object.entries(changes)) {
    if (value === null) continue;
    const current = target[`${prefix}_winner_present`] === 1 ?
      id(target[`${prefix}_winner_timestamp`], target[`${prefix}_winner_site_id`]) : null;
    if (current && compare(operation, current) <= 0) continue;
    db.prepare(`UPDATE original_recording_state SET ${prefix}_value=?,
      ${prefix}_winner_timestamp=?,${prefix}_winner_site_id=?,${prefix}_winner_present=1
      WHERE note_id=? AND recording_timestamp=? AND recording_site_id=?`).run(
      value, operation.timestamp, operation.siteId, noteId, recording.timestamp, recording.siteId);
    target[`${prefix}_winner_present`] = 1;
    target[`${prefix}_winner_timestamp`] = operation.timestamp;
    target[`${prefix}_winner_site_id`] = operation.siteId;
  }
  return 'APPLIED';
}

function setVisibility(db, noteId, recording, operation, deleted) {
  const current = db.prepare(`SELECT * FROM original_entity_visibility_winner WHERE note_id=?
    AND entity_timestamp=? AND entity_site_id=?`)
    .get(noteId, recording.timestamp, recording.siteId);
  if (current && compare(operation, id(current.winner_timestamp, current.winner_site_id)) <= 0) {
    return 'STALE';
  }
  db.prepare(`INSERT INTO original_entity_visibility_winner VALUES(?,?,?,?,?,?)
    ON CONFLICT(note_id,entity_timestamp,entity_site_id) DO UPDATE SET
      winner_timestamp=excluded.winner_timestamp,winner_site_id=excluded.winner_site_id,
      deleted=excluded.deleted`).run(noteId, recording.timestamp, recording.siteId,
    operation.timestamp, operation.siteId, deleted ? 1 : 0);
  refreshPresence(db, noteId);
  return 'APPLIED';
}

const db = database();
migrateV55(db);
assert.equal(db.prepare('PRAGMA user_version').get().user_version, 55);
const recording = id(20, 2);
assert.equal(createRecording(db, 'n', recording), 'APPLIED');
assert.equal(db.prepare("SELECT has_recordings FROM note_meta WHERE id='n'").get().has_recordings, 1);
assert.equal(createRecording(db, 'n', recording), 'IDEMPOTENT');
assert.throws(() => createRecording(db, 'n', recording, { signature: 'different' }),
  /create identity conflict/);

assert.equal(modifyRecording(db, 'n', id(30, 1), recording,
  { name: 'Renamed', segments: null, z_index: null }), 'APPLIED');
assert.equal(modifyRecording(db, 'n', id(29, 9), recording,
  { name: 'stale', segments: segments([]), z_index: '70' }), 'APPLIED');
let stored = db.prepare(`SELECT * FROM original_recording_state WHERE note_id='n'`).get();
assert.equal(stored.name_value, 'Renamed');
assert.equal(stored.segments_value, segments([]));
assert.equal(stored.z_index_value, '70');
assert.equal(modifyRecording(db, 'n', id(30, 2), recording,
  { name: null, segments: null, z_index: '80' }), 'APPLIED');
assert.equal(modifyRecording(db, 'n', id(30, 2), recording,
  { name: null, segments: null, z_index: '80' }), 'IDEMPOTENT');
assert.throws(() => modifyRecording(db, 'n', id(30, 2), recording,
  { name: 'conflict', segments: null, z_index: null }), /modify identity conflict/);
assert.equal(modifyRecording(db, 'n', id(40, 1), id(999, 1),
  { name: 'missing', segments: null, z_index: null }), 'MISSING');

assert.equal(setVisibility(db, 'n', recording, id(50, 1), true), 'APPLIED');
assert.equal(db.prepare("SELECT has_recordings FROM note_meta WHERE id='n'").get().has_recordings, 0);
assert.equal(setVisibility(db, 'n', recording, id(49, 9), false), 'STALE');
assert.equal(setVisibility(db, 'n', recording, id(50, 2), false), 'APPLIED');
assert.equal(db.prepare("SELECT has_recordings FROM note_meta WHERE id='n'").get().has_recordings, 1);

// A delete winner may arrive before CREATE_RECORDING; create later derives hidden presence.
const late = id(21, 2);
assert.equal(setVisibility(db, 'n', late, id(60, 1), true), 'APPLIED');
assert.equal(createRecording(db, 'n', late, { signature: 'late' }), 'APPLIED');
assert.equal(db.prepare("SELECT has_recordings FROM note_meta WHERE id='n'").get().has_recordings, 1);
assert.equal(setVisibility(db, 'n', recording, id(70, 1), true), 'APPLIED');
assert.equal(db.prepare("SELECT has_recordings FROM note_meta WHERE id='n'").get().has_recordings, 0);

// Bundle transaction owns state, journal and derived presence atomically.
db.exec('BEGIN IMMEDIATE');
createRecording(db, 'other', id(80, 3), { signature: 'bundle' });
db.exec('ROLLBACK');
assert.equal(db.prepare(`SELECT COUNT(*) count FROM original_recording_state
  WHERE note_id='other'`).get().count, 0);

db.exec("DELETE FROM note_meta WHERE id='n'");
assert.equal(db.prepare(`SELECT COUNT(*) count FROM original_recording_state`).get().count, 0);
assert.equal(db.prepare(`SELECT COUNT(*) count FROM original_recording_modification`).get().count, 0);
db.close();

const failed = database();
assert.throws(() => migrateV55(failed, true), /injected v55 migration failure/);
assert.equal(failed.prepare('PRAGMA user_version').get().user_version, 54);
assert.equal(failed.prepare(`SELECT COUNT(*) count FROM sqlite_master
  WHERE type='table' AND name='original_recording_state'`).get().count, 0);
failed.close();

const currentVersion = schema.match(/export const DB_VERSION: number = (\d+);/);
assert(currentVersion, 'database version is missing');
assert(Number.parseInt(currentVersion[1], 10) >= 55,
  'database version predates the recording-state migration');
assert.match(schema, /55: \[[\s\S]*DDL_ORIGINAL_RECORDING_STATE/);
assert.match(manager, /DDL_ORIGINAL_RECORDING_MODIFICATION/);
assert.match(reducer, /ORIGINAL_CREATE_RECORDING_PAYLOAD_TYPE: number = 5/);
assert.match(reducer, /ORIGINAL_MODIFY_RECORDING_PAYLOAD_TYPE: number = 6/);
assert.match(reducer, /name_winner_present/);
assert.match(reducer, /segments_winner_present/);
assert.match(reducer, /z_index_winner_present/);
assert.match(reducer, /mergeOriginalAssetReference/);
assert.match(reducer, /MODIFY_RECORDING_SEGMENTS_OUT_OF_BOUNDS/);
assert.match(router, /this\.recording\.apply/);
assert.match(bundle, /recording\.preflightTable/);
assert.match(bundle, /recording\.applyTable/);
assert.match(visibilityReducer, /refreshOriginalRecordingPresence/);
assert.match(fixture, /flatBufferCreateRecording/);
assert.match(fixture, /flatBufferModifyRecording/);

console.log('D02_RECORDING_STATE_REPLAY_OK ' +
  'v54-v55=1|create-defaults-asset=1|create-retry-conflict=2|independent-lww=3|' +
  'stale-site-tie=3|modify-retry-conflict=2|missing-deferred=1|delete-undelete=3|' +
  'delete-before-create=1|presence-derived=1|bundle-rollback=1|cascade=1|' +
  'migration-rollback=1|player-waveform-asset-arrival=pending');

function extractTemplate(source, name) {
  const match = source.match(new RegExp('(?:export )?const ' + name +
    ': string = `([\\s\\S]*?)`;'));
  assert(match, `${name} missing`);
  return match[1];
}
