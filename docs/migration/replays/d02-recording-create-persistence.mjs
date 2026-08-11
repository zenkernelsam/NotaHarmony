import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { DatabaseSync } from 'node:sqlite';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalAsset = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/re0.java', 'utf8');
const originalWriter = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/skb.java', 'utf8');
const originalPayload = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/iaj.java', 'utf8');
const digestSource = read('note/src/main/ets/data/AssetDigest.ets');
const encoderSource = read('note/src/main/ets/data/OriginalCreateRecordingPayloadEncoder.ets');
const persistenceSource = read('note/src/main/ets/data/OriginalRecordingPersistence.ets');
const notePageSource = read('note/src/main/ets/ui/editor/NotePage.ets');
const reducerSource = read('note/src/main/ets/data/OriginalRecordingOperation.ets');
const opTypesSource = read('note/src/main/ets/core/model/OpTypes.ets');
const testsSource = read('note/src/test/OriginalCreateRecordingPayloadEncoder.test.ets');

assert.match(originalAsset, /MessageDigest\.getInstance\("SHA-512"\)/);
assert.match(originalAsset, /pending_asset_/);
assert.match(originalWriter, /p29Var\.c\(ttfVar, fileInputStream/);
assert.match(originalWriter, /iaj\.a\(null, name,[\s\S]*new xgb\(0L\)/);
assert.match(originalWriter, /b\(fileB2\)/);
assert.match(originalPayload, /aVarA\.f\(5, tmfVar\.I\)/);
assert.match(originalPayload, /aVarA\.h\(4, iIntValue2\)/);

assert.match(digestSource, /originalAssetHashBitsFromSha512/);
assert.match(digestSource, /byteIndex: number = 7; byteIndex >= 0/);
assert.match(encoderSource, /writeVtable\(bytes, createVtable, 40, \[4, 8, 16, 24, 0, 32\]\)/);
assert.match(encoderSource, /writeUint64Decimal\(bytes, createTable \+ 32, '0'\)/);
assert.match(persistenceSource, /assetMutationMutex\.runExclusive/);
assert.match(persistenceSource, /editorPersistenceMutex\.runExclusive/);
assert.match(persistenceSource, /fileIo\.fsyncSync\(pending\.fd\)/);
assert.match(persistenceSource, /OriginalRecordingOperationApplier\(\)\.applyTable/);
assert.match(persistenceSource, /appendOperation\(store/);
assert.match(persistenceSource, /uploadImmediately: true/);
assert.match(persistenceSource, /await store\.rollBack\(\)/);
assert.match(persistenceSource, /createdFinalFile/);
assert.match(persistenceSource, /unlinkIfPresent\(capture\.temporaryPath\)/);
const persistFunction = persistenceSource.slice(
  persistenceSource.indexOf('export async function persistCapturedOriginalRecording'),
  persistenceSource.indexOf('async function prepareRecordingAsset'));
assert(persistFunction.indexOf('try {') < persistFunction.indexOf('validateCapture(noteId, capture);'));
assert.match(persistenceSource, /captured recording file changed while it was copied/);
assert.match(persistenceSource,
  /unlinkIfPresent\(pendingPath\);\s*throw new Error\(`copying recording asset failed:/);
assert.match(persistenceSource, /let left: fileIo\.File \| null = null/);
assert.match(persistenceSource, /if \(right !== null\)[\s\S]*if \(left !== null\)/);
assert.match(notePageSource, /persistCapturedOriginalRecording\(DatabaseManager\.getInstance\(\), this\.noteId, capture\)/);
assert.match(reducerSource, /ORIGINAL_CREATE_RECORDING_PAYLOAD_TYPE: number = 5/);
assert.match(opTypesSource, /ORIGINAL_CREATE_RECORDING = 61/);
assert.match(testsSource, /round-trips the original local CreateRecording fields/);

const input = Buffer.from('original recording bytes', 'utf8');
const digest = crypto.createHash('sha512').update(input).digest();
const storageHash = digest.toString('hex');
const words = [];
for (let offset = 0; offset < digest.length; offset += 8) {
  words.push(digest.readBigUInt64LE(offset).toString());
}
const rebuilt = Buffer.alloc(64);
words.forEach((word, index) => rebuilt.writeBigUInt64LE(BigInt(word), index * 8));
assert.equal(rebuilt.toString('hex'), storageHash);

const tempRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'nota-recording-create-'));
const db = new DatabaseSync(':memory:');
db.exec(`CREATE TABLE note_asset(
    asset_hash TEXT PRIMARY KEY,status INTEGER,note_ids TEXT,file_size INTEGER,
    mime_type TEXT,local_path TEXT);
  CREATE TABLE recording_state(
    note_id TEXT,recording_id TEXT,asset_hash TEXT,start_time TEXT,end_time TEXT,
    name TEXT,z_index TEXT,PRIMARY KEY(note_id,recording_id));
  CREATE TABLE operation_log(
    op_id TEXT PRIMARY KEY,note_id TEXT,op_type INTEGER,payload TEXT);
  CREATE TABLE sync_clock(note_id TEXT PRIMARY KEY,next_timestamp INTEGER);
  INSERT INTO sync_clock VALUES('note',1);`);

function snapshot() {
  return {
    assets: db.prepare('SELECT * FROM note_asset ORDER BY asset_hash').all(),
    recordings: db.prepare('SELECT * FROM recording_state ORDER BY recording_id').all(),
    operations: db.prepare('SELECT * FROM operation_log ORDER BY op_id').all(),
    clock: db.prepare('SELECT * FROM sync_clock').all(),
  };
}

function persist(sourcePath, failAt = '') {
  const pendingDir = path.join(tempRoot, 'assets', 'pending');
  const finalDir = path.join(tempRoot, 'assets', 'final');
  fs.mkdirSync(pendingDir, { recursive: true });
  fs.mkdirSync(finalDir, { recursive: true });
  const pendingPath = path.join(pendingDir, `pending_recording_${Date.now()}.tmp`);
  const finalPath = path.join(finalDir, storageHash);
  let createdFinal = false;
  let committed = false;
  try {
    const bytes = fs.readFileSync(sourcePath);
    fs.writeFileSync(pendingPath, bytes);
    const fd = fs.openSync(pendingPath, 'r+');
    fs.fsyncSync(fd);
    fs.closeSync(fd);
    assert.equal(crypto.createHash('sha512').update(bytes).digest('hex'), storageHash);
    if (fs.existsSync(finalPath)) {
      assert(fs.readFileSync(finalPath).equals(bytes));
      fs.unlinkSync(pendingPath);
    } else {
      fs.renameSync(pendingPath, finalPath);
      createdFinal = true;
    }
    db.exec('BEGIN IMMEDIATE');
    try {
      const clock = db.prepare('SELECT next_timestamp FROM sync_clock WHERE note_id=?').get('note');
      const id = `op:${clock.next_timestamp}:1`;
      db.prepare('UPDATE sync_clock SET next_timestamp=? WHERE note_id=?')
        .run(clock.next_timestamp + 1, 'note');
      db.prepare('INSERT OR REPLACE INTO note_asset VALUES(?,?,?,?,?,?)')
        .run(storageHash, 1, JSON.stringify(['note']), input.length, 'audio/mp4', finalPath);
      db.prepare('INSERT INTO recording_state VALUES(?,?,?,?,?,?,?)')
        .run('note', id, storageHash, '1000', '2000', path.basename(sourcePath), '0');
      if (failAt === 'journal') throw new Error('injected journal failure');
      db.prepare('INSERT INTO operation_log VALUES(?,?,?,?)')
        .run(id, 'note', 61, JSON.stringify({ words, name: path.basename(sourcePath), zIndex: '0' }));
      db.exec('COMMIT');
      committed = true;
      return { id, finalPath };
    } catch (error) {
      db.exec('ROLLBACK');
      throw error;
    }
  } finally {
    if (fs.existsSync(sourcePath)) fs.unlinkSync(sourcePath);
    if (!committed && createdFinal && fs.existsSync(finalPath)) fs.unlinkSync(finalPath);
    if (fs.existsSync(pendingPath)) fs.unlinkSync(pendingPath);
  }
}

try {
  const successSource = path.join(tempRoot, 'recording_success.m4a');
  fs.writeFileSync(successSource, input);
  const result = persist(successSource);
  assert.equal(fs.existsSync(successSource), false);
  assert(fs.readFileSync(result.finalPath).equals(input));
  assert.equal(db.prepare('SELECT COUNT(*) count FROM note_asset').get().count, 1);
  assert.equal(db.prepare('SELECT COUNT(*) count FROM recording_state').get().count, 1);
  assert.equal(db.prepare('SELECT COUNT(*) count FROM operation_log').get().count, 1);

  fs.unlinkSync(result.finalPath);
  db.exec(`DELETE FROM note_asset; DELETE FROM recording_state; DELETE FROM operation_log;
    UPDATE sync_clock SET next_timestamp=2;`);
  const beforeFailure = snapshot();
  const failureSource = path.join(tempRoot, 'recording_failure.m4a');
  fs.writeFileSync(failureSource, input);
  assert.throws(() => persist(failureSource, 'journal'), /injected journal failure/);
  assert.deepEqual(snapshot(), beforeFailure);
  assert.equal(fs.existsSync(failureSource), false);
  assert.equal(fs.existsSync(path.join(tempRoot, 'assets', 'final', storageHash)), false);
  assert.equal(fs.readdirSync(path.join(tempRoot, 'assets', 'pending')).length, 0);
} finally {
  db.close();
  fs.rmSync(tempRoot, { recursive: true, force: true });
}

console.log('recordingPersist=sha512-atomic-create-reducer-journal-cleanup');
