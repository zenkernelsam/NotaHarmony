import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { DatabaseSync } from 'node:sqlite';

const rootPath = new URL('../../../', import.meta.url);
const storeSource = fs.readFileSync(new URL(
  'note/src/main/ets/data/ImageAssetPackageStore.ets', rootPath), 'utf8');
const digestSource = fs.readFileSync(new URL(
  'note/src/main/ets/data/AssetDigest.ets', rootPath), 'utf8');
const hubSource = fs.readFileSync(new URL(
  'note/src/main/ets/data/AssetAvailabilityHub.ets', rootPath), 'utf8');
const canvasSource = fs.readFileSync(new URL(
  'note/src/main/ets/ui/editor/NoteCanvasView.ets', rootPath), 'utf8');
const librarySource = fs.readFileSync(new URL(
  'note/src/main/ets/ui/library/LibraryPage.ets', rootPath), 'utf8');
const thumbnailSource = fs.readFileSync(new URL(
  'note/src/main/ets/rendering/ThumbnailRenderPolicy.ets', rootPath), 'utf8');
const testSource = fs.readFileSync(new URL(
  'note/src/test/AssetArrival.test.ets', rootPath), 'utf8');

const bytes = Buffer.from('abc', 'utf8');
const digest = crypto.createHash('sha512').update(bytes).digest();
const digestHex = digest.toString('hex');
const expectedHex = 'ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a' +
  '2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f';
assert.equal(digestHex, expectedHex);
const words = [];
for (let offset = 0; offset < digest.length; offset += 8) {
  words.push(digest.readBigUInt64LE(offset).toString());
}
assert.deepEqual(words, [
  '13437159724906033117', '3549153914273350092',
  '11708982488410547730', '11156354486412156426',
  '12160087498514076193', '13685311869319690806',
  '1074174911913938245', '11503403621103016490',
]);
assert(testSource.includes(expectedHex.slice(0, 64)));
assert(testSource.includes(expectedHex.slice(64)));
assert(digestSource.includes("createMd('SHA512')"));
assert(storeSource.includes('digestHex !== storageHash'));
assert(storeSource.includes("'/assets/pending'"));
assert(storeSource.includes('pending_asset_'));
assert(storeSource.includes('fileIo.fsyncSync(file.fd)'));
assert(storeSource.includes('assetMutationMutex.runExclusive'));

const tempRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'nota-image-arrival-'));
const db = new DatabaseSync(':memory:');
db.exec(`CREATE TABLE note_asset(
  asset_hash TEXT PRIMARY KEY,
  status INTEGER NOT NULL,
  note_ids TEXT NOT NULL,
  file_size INTEGER NOT NULL,
  mime_type TEXT NOT NULL,
  local_path TEXT
)`);

function seed(status = 0, noteIds = ['note-a', 'note-b'], mimeType = 'image/png', localPath = null) {
  db.prepare(`INSERT INTO note_asset(asset_hash,status,note_ids,file_size,mime_type,local_path)
    VALUES(?,?,?,?,?,?)`).run(digestHex, status, JSON.stringify(noteIds), bytes.length, mimeType, localPath);
}

function snapshot() {
  return db.prepare('SELECT * FROM note_asset ORDER BY asset_hash').all();
}

function receive(data, expectedSize = data.length, mimeType = 'image/png', failAt = '') {
  if (data.length !== expectedSize) throw new Error('length');
  if (crypto.createHash('sha512').update(data).digest('hex') !== digestHex) throw new Error('hash');
  const finalDirectory = path.join(tempRoot, 'assets', 'final');
  const pendingDirectory = path.join(tempRoot, 'assets', 'pending');
  const finalPath = path.join(finalDirectory, digestHex);
  fs.mkdirSync(finalDirectory, { recursive: true });
  fs.mkdirSync(pendingDirectory, { recursive: true });
  db.exec('BEGIN IMMEDIATE');
  let created = false;
  let temporaryPath = '';
  try {
    const row = db.prepare('SELECT * FROM note_asset WHERE asset_hash=?').get(digestHex);
    if (!row) throw new Error('metadata missing');
    if (row.file_size !== expectedSize || row.mime_type.toLowerCase() !== mimeType.toLowerCase()) {
      throw new Error('metadata conflict');
    }
    if (row.status === 1 || row.status === 2 || row.status === 3) {
      if (!row.local_path || !fs.existsSync(row.local_path) ||
        !fs.readFileSync(row.local_path).equals(data)) throw new Error('local conflict');
      db.exec('COMMIT');
      return { becameAvailable: false, noteIds: JSON.parse(row.note_ids), finalPath: row.local_path };
    }
    if (fs.existsSync(finalPath)) {
      if (!fs.readFileSync(finalPath).equals(data)) throw new Error('orphan conflict');
    } else {
      temporaryPath = path.join(pendingDirectory, `pending_asset_${Date.now()}.tmp`);
      fs.writeFileSync(temporaryPath, data);
      const descriptor = fs.openSync(temporaryPath, 'r+');
      fs.fsyncSync(descriptor);
      fs.closeSync(descriptor);
      if (failAt === 'rename') throw new Error('injected rename');
      fs.renameSync(temporaryPath, finalPath);
      temporaryPath = '';
      created = true;
    }
    if (failAt === 'database') throw new Error('injected database');
    db.prepare('UPDATE note_asset SET status=1,local_path=? WHERE asset_hash=?').run(finalPath, digestHex);
    db.exec('COMMIT');
    return { becameAvailable: true, noteIds: JSON.parse(row.note_ids), finalPath };
  } catch (error) {
    db.exec('ROLLBACK');
    if (temporaryPath && fs.existsSync(temporaryPath)) fs.unlinkSync(temporaryPath);
    if (created && fs.existsSync(finalPath)) fs.unlinkSync(finalPath);
    throw error;
  }
}

try {
  seed();
  const arrived = receive(bytes);
  assert.equal(arrived.becameAvailable, true);
  assert.deepEqual(arrived.noteIds, ['note-a', 'note-b']);
  assert.equal(fs.readFileSync(arrived.finalPath).toString(), 'abc');
  assert.equal(db.prepare('SELECT status FROM note_asset').get().status, 1);

  const beforeIdempotent = snapshot();
  const idempotent = receive(bytes);
  assert.equal(idempotent.becameAvailable, false);
  assert.deepEqual(snapshot(), beforeIdempotent);
  assert.throws(() => receive(bytes, bytes.length + 1), /length/);
  assert.deepEqual(snapshot(), beforeIdempotent);
  assert.throws(() => receive(Buffer.from('abd')), /hash/);
  assert.deepEqual(snapshot(), beforeIdempotent);

  db.exec('DELETE FROM note_asset');
  fs.rmSync(path.join(tempRoot, 'assets'), { recursive: true, force: true });
  seed(0, ['note-a'], 'image/jpeg');
  const beforeMime = snapshot();
  assert.throws(() => receive(bytes, bytes.length, 'image/png'), /metadata conflict/);
  assert.deepEqual(snapshot(), beforeMime);
  assert.equal(fs.existsSync(path.join(tempRoot, 'assets', 'final', digestHex)), false);

  db.exec('DELETE FROM note_asset');
  seed();
  const pendingBeforeFailure = snapshot();
  assert.throws(() => receive(bytes, bytes.length, 'image/png', 'rename'), /injected rename/);
  assert.deepEqual(snapshot(), pendingBeforeFailure);
  assert.equal(fs.readdirSync(path.join(tempRoot, 'assets', 'pending')).length, 0);
  assert.equal(fs.existsSync(path.join(tempRoot, 'assets', 'final', digestHex)), false);

  assert.throws(() => receive(bytes, bytes.length, 'image/png', 'database'), /injected database/);
  assert.deepEqual(snapshot(), pendingBeforeFailure);
  assert.equal(fs.existsSync(path.join(tempRoot, 'assets', 'final', digestHex)), false);

  const foreignPath = path.join(tempRoot, 'foreign-local');
  fs.writeFileSync(foreignPath, Buffer.from('wrong'));
  db.exec('DELETE FROM note_asset');
  seed(1, ['note-a'], 'image/png', foreignPath);
  const localConflict = snapshot();
  assert.throws(() => receive(bytes), /local conflict/);
  assert.deepEqual(snapshot(), localConflict);

  fs.writeFileSync(foreignPath, bytes);
  db.exec('DELETE FROM note_asset');
  seed(3, ['note-a'], 'image/png', foreignPath);
  const preserved = receive(bytes);
  assert.equal(preserved.becameAvailable, false);
  assert.equal(preserved.finalPath, foreignPath);
  assert.equal(db.prepare('SELECT status FROM note_asset').get().status, 3);
  assert.equal(fs.existsSync(path.join(tempRoot, 'assets', 'final', digestHex)), false);

  db.exec('DELETE FROM note_asset');
  assert.throws(() => receive(bytes), /metadata missing/);

  assert(hubSource.includes('getNoteGeneration(noteId: string)'));
  assert(hubSource.includes('unsubscribe(listenerId: number)'));
  assert(canvasSource.includes('onImageAssetAvailabilityChanged'));
  assert(canvasSource.includes('assetAvailabilityHub.unsubscribe'));
  assert(canvasSource.includes('this.refreshImageAssets(this.pageLoadGeneration, this.loadedPageId)'));
  assert(librarySource.includes('assetAvailabilityHub.getNoteGeneration(noteId)'));
  assert(librarySource.includes('onAssetAvailabilityChanged'));
  assert(librarySource.includes('assetAvailabilityHub.unsubscribe'));
  assert(thumbnailSource.includes('@asset:${assetGeneration}'));
  assert(storeSource.indexOf('await writeOriginalImageAssetBytes') <
    storeSource.indexOf('assetAvailabilityHub.publish'));
} finally {
  db.close();
  fs.rmSync(tempRoot, { recursive: true, force: true });
}

console.log('d02 image asset arrival replay passed');
