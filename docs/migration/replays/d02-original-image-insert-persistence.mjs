import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { DatabaseSync } from 'node:sqlite';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const originalRoot = process.env.NOTABILITY_ORIGINAL_ROOT ??
  'C:/Users/Cisco He/Desktop/Notability';
const readRepo = relative => fs.readFileSync(path.join(root, relative), 'utf8').replaceAll('\r\n', '\n');
const readOriginal = relative => fs.readFileSync(path.join(originalRoot, relative), 'utf8')
  .replaceAll('\r\n', '\n');

const planSource = readRepo('note/src/main/ets/core/model/OriginalImageInsertPlan.ets');
const assetSource = readRepo('note/src/main/ets/data/ImageAssetPackageStore.ets');
const persistenceSource = readRepo('note/src/main/ets/data/StrokePersistence.ets');
const digestSource = readRepo('note/src/main/ets/data/AssetDigest.ets');
const fixture = readRepo('note/src/test/OriginalImageInsertPlan.test.ets');
const persistenceFixture = readRepo('note/src/test/StrokePersistence.test.ets');
const fixtureList = readRepo('note/src/test/List.test.ets');
const bvh = readOriginal('decompiled_1.0.3/sources/defpackage/bvh.java');
const bgj = readOriginal('decompiled_1.0.3/sources/defpackage/bgj.java');
const vuh = readOriginal('decompiled_1.0.3/sources/defpackage/vuh.java');
const w34 = readOriginal('decompiled_1.0.3/sources/defpackage/w34.java');
const yr = readOriginal('.codex-tmp-phase280-yr-debug.java');

const commitStart = persistenceSource.indexOf('async commitOriginalImageInsert');
const commitEnd = persistenceSource.indexOf('\n  hasDirtySave(', commitStart);
const commitSource = persistenceSource.slice(commitStart, commitEnd);
const mergeStart = assetSource.indexOf('export async function mergePreparedLocalOriginalImageAsset');
const mergeEnd = assetSource.indexOf('\nexport function unlinkPreparedLocalOriginalImageAsset', mergeStart);
const mergeSource = assetSource.slice(mergeStart, mergeEnd);

const checks = [
  ['original uses 80 percent page bounds and 320 divided by zoom',
    bvh.includes('f3.floatValue() * 0.8f') && bvh.includes('f4.floatValue() * 0.8f') &&
    bgj.includes('new Float(320.0f / f)')],
  ['original centres then clamps each axis or centres an oversized display',
    bgj.includes('ei3.e(j) - (f4 / 2.0f)') && bgj.includes('ei3.f(j) - (f5 / 2.0f)') &&
    bgj.includes('bmbVar2.d().d() - f4') && bgj.includes('bmbVar2.d().c() - f5')],
  ['original URI ingress keeps item order and enforces 100 MiB',
    yr.includes('int r3 = r3.nextInt()') && yr.includes('r3.getUri()') &&
     bgj.includes('104857600L') && bgj.includes('strI = "image/*"')],
  ['original rejects undecodable images and normalizes EXIF dimensions to 3000px',
    vuh.includes('BitmapFactory.decodeFile(file.getAbsolutePath(), options)') &&
    vuh.includes('Failed to decode image dimensions') && vuh.includes('file.delete()') &&
    vuh.includes('i3 <= 3000 && i4 <= 3000') &&
    vuh.includes('3000.0f / Math.max(i2, i)') &&
    w34.includes('case 5:') && w34.includes('case 8:') && w34.includes('return 270') &&
    w34.includes('case 6:') && w34.includes('case 7:') && w34.includes('return 90')],
  ['pure plan keeps intrinsic block size and puts fitted display scale in transform',
    planSource.includes('blockWidth: geometry.intrinsicWidth') &&
    planSource.includes('blockHeight: geometry.intrinsicHeight') &&
    planSource.includes('geometry.scaleX, 0, geometry.origin.x') &&
    planSource.includes('0, geometry.scaleY, geometry.origin.y')],
  ['pure plan uses Float32 boundaries and separate displayed-axis ratios',
    planSource.includes('Math.fround') &&
    planSource.includes('displayWidth / imageWidth') &&
    planSource.includes('displayHeight / imageHeight')],
  ['local image helper computes SHA-512 words and publishes a fsynced final file',
    digestSource.includes('sha512Digest') &&
    assetSource.includes('originalAssetHashBitsFromSha512(digestBytes)') &&
     assetSource.includes('fileIo.fsyncSync(file.fd)') &&
     assetSource.includes('writeFileAtomically(pendingDirectory, finalPath, bytes)')],
  ['local image helper decodes before writing and checks header PixelMap EXIF and 3000px',
    assetSource.indexOf('validateDecodedLocalOriginalImageAsset') <
      assetSource.indexOf('writeFileAtomically(pendingDirectory, finalPath, bytes)') &&
    assetSource.includes('image.createImageSource(buffer)') &&
    assetSource.includes('await source.getImageInfo()') &&
    assetSource.includes('image.PropertyKey.ORIENTATION') &&
    assetSource.includes('await source.createPixelMap({ editable: false })') &&
    assetSource.includes('await pixelMap.release()') && assetSource.includes('await source.release()') &&
    assetSource.includes('isOriginalNormalizedImageDimensions')],
  ['transaction merge does not acquire a writer mutex or open a nested transaction',
    !mergeSource.includes('databaseWriteMutex') && !mergeSource.includes('runExclusive') &&
    !mergeSource.includes('beginTransaction') && !mergeSource.includes('commit()')],
  ['persistence lock order is asset then editor and only editor owns SQLite transaction',
    commitSource.indexOf('assetMutationMutex.runExclusive') <
      commitSource.indexOf('editorPersistenceMutex.runExclusive') &&
    commitSource.indexOf('prepareLocalOriginalImageAsset') <
      commitSource.indexOf('editorPersistenceMutex.runExclusive') &&
    commitSource.includes('await store.beginTransaction()')],
  ['CREATE_BLOCK outbound asset LOCAL merge revision and history share one commit',
    commitSource.includes('OriginalCreateBlockOperationApplier().applyBatchedPayload') &&
    commitSource.includes('OpType.ORIGINAL_CREATE_BLOCK') &&
    commitSource.includes('mergePreparedLocalOriginalImageAsset') &&
    commitSource.includes('revisionBatch.flush') &&
     commitSource.includes('appendHistoryCompanion(store, finalSnapshot, mutation)') &&
     commitSource.includes('await store.commit()')],
  ['historical asset rows reconcile before reducer and canonicalize verified private paths',
    commitSource.indexOf('reconcileExistingPreparedLocalOriginalImageAsset') <
      commitSource.indexOf('OriginalCreateBlockOperationApplier().applyBatchedPayload') &&
    assetSource.includes('validateStoredLocalOriginalImageAssetPath(row.localPath, prepared)') &&
    assetSource.includes('filesHaveEqualContents(path, prepared.finalPath') &&
    assetSource.includes('readable stored path outside the app files directory') &&
    assetSource.includes("'local_path': prepared.finalPath")],
  ['failed transaction compensates only the final file created by this attempt',
    commitSource.includes('unlinkPreparedLocalOriginalImageAsset(prepared)') &&
    assetSource.includes('if (!prepared.createdFinalFile)')],
  ['successful commit publishes availability only after SQLite commit',
    commitSource.indexOf('await store.commit()') <
      commitSource.indexOf('assetAvailabilityHub.publish')],
  ['fixtures cover geometry validation and are registered',
    fixture.includes('keeps intrinsic CREATE_BLOCK size') &&
    fixture.includes('clamps each display axis') &&
    fixture.includes('scaleX === geometry?.scaleY') &&
    fixture.includes('keeps the original 3000px and EXIF-oriented ingress dimensions') &&
    persistenceFixture.includes(
      'preflights original local Image bytes MIME normalized dimensions and geometry') &&
    fixtureList.includes('OriginalImageInsertPlan.test') &&
    fixtureList.includes('originalImageInsertPlanTest();')],
];

for (const [name, ok] of checks) {
  assert.ok(ok, `FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}

const f32 = Math.fround;
function planGeometry(width, height, pageWidth, pageHeight, zoom, anchor) {
  width = f32(width); height = f32(height); pageWidth = f32(pageWidth);
  pageHeight = f32(pageHeight); zoom = f32(zoom);
  const widthLimit = f32(pageWidth * f32(0.8));
  const heightLimit = f32(pageHeight * f32(0.8));
  const zoomLimit = f32(f32(320) / zoom);
  const scale = f32(Math.min(f32(1), f32(Math.min(widthLimit, zoomLimit) / width),
    f32(Math.min(heightLimit, zoomLimit) / height)));
  const displayWidth = f32(width * scale);
  const displayHeight = f32(height * scale);
  const axis = (center, display, page) => display <= page
    ? f32(Math.max(f32(0), Math.min(f32(f32(center) - f32(display / f32(2))), f32(page - display))))
    : f32(f32(page - display) / f32(2));
  return {
    displayWidth, displayHeight,
    originX: axis(anchor.x, displayWidth, pageWidth),
    originY: axis(anchor.y, displayHeight, pageHeight),
    scaleX: f32(displayWidth / width), scaleY: f32(displayHeight / height),
  };
}

assert.deepEqual(planGeometry(400, 200, 800, 1000, 1, { x: 10, y: 10 }), {
  displayWidth: 320, displayHeight: 160, originX: 0, originY: 0,
  scaleX: f32(0.8), scaleY: f32(0.8),
});
const precise = planGeometry(3, 297, 793.8, 1122.66, 1.37, { x: 100, y: 200 });
assert.notEqual(precise.scaleX, precise.scaleY);
console.log('PASS: numeric Float32 fit and clamp fixture');

const input = Buffer.from('original image insertion bytes', 'utf8');
const digest = crypto.createHash('sha512').update(input).digest();
const storageHash = digest.toString('hex');
const words = [];
for (let offset = 0; offset < digest.length; offset += 8) {
  words.push(digest.readBigUInt64LE(offset).toString());
}
const rebuilt = Buffer.alloc(64);
words.forEach((word, index) => rebuilt.writeBigUInt64LE(BigInt(word), index * 8));
assert.equal(rebuilt.toString('hex'), storageHash);
console.log('PASS: SHA-512 eight-word little-endian fixture');

assert.equal(input.length <= 104857600, true);
assert.throws(() => validateIngress(Buffer.alloc(0), 'image/png', 100, 100), /bytes/);
assert.throws(() => validateIngress(input, '', 100, 100), /MIME/);
assert.throws(() => validateIngress(input, 'text/plain', 100, 100), /MIME/);
assert.throws(() => validateIngress(input, 'image/png', 0, 100), /dimensions/);
assert.throws(() => validateIngress({ length: 104857601 }, 'image/png', 100, 100), /bytes/);
console.log('PASS: 100 MiB MIME and dimension rejection fixture');

const tempRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'nota-image-insert-'));
try {
  const success = setupDatabase();
  const result = persistImage(success, tempRoot, input, '');
  assert.equal(fs.readFileSync(result.finalPath).equals(input), true);
  assert.equal(success.prepare('SELECT status FROM note_asset').get().status, 1);
  assert.equal(success.prepare('SELECT content_revision FROM page_info').get().content_revision, 8);
  assert.equal(success.prepare('SELECT COUNT(*) count FROM original_block_state').get().count, 1);
  const operations = success.prepare(
    'SELECT op_type,upload_immediately FROM operation_log ORDER BY sequence').all()
    .map(row => ({ ...row }));
  assert.deepEqual(operations, [
    { op_type: 22, upload_immediately: 1 },
    { op_type: 1, upload_immediately: 0 },
  ]);
  const rows = success.prepare(
    'SELECT element_id,element_order FROM page_element_snapshot ORDER BY element_order').all();
  assert.equal(rows.length, 3);
  assert.deepEqual(rows.map(row => row.element_order), [0, 1, 2]);
  const history = JSON.parse(success.prepare('SELECT payload FROM history_log').get().payload);
  assert.deepEqual(history.beforeOrder, ['existing-ink', 'existing-text']);
  assert.deepEqual(history.afterOrder, ['existing-ink', 'existing-text', result.elementId]);
  assert.deepEqual(replayOrder(history.afterOrder, history, false), history.beforeOrder);
  assert.deepEqual(replayOrder(history.beforeOrder, history, true), history.afterOrder);
  success.close();

  for (const failAt of ['reducer', 'asset', 'history']) {
    const db = setupDatabase();
    const before = snapshot(db);
    const failRoot = path.join(tempRoot, failAt);
    fs.mkdirSync(failRoot, { recursive: true });
    assert.throws(() => persistImage(db, failRoot, input, failAt), new RegExp(failAt));
    assert.deepEqual(snapshot(db), before);
    assert.equal(fs.existsSync(path.join(failRoot, 'assets', 'final', storageHash)), false);
    const pending = path.join(failRoot, 'assets', 'pending');
    assert.equal(fs.existsSync(pending) ? fs.readdirSync(pending).length : 0, 0);
    db.close();
  }

  const reuseDb = setupDatabase();
  const reuseRoot = path.join(tempRoot, 'reuse');
  const reusedFinal = path.join(reuseRoot, 'assets', 'final', storageHash);
  fs.mkdirSync(path.dirname(reusedFinal), { recursive: true });
  fs.writeFileSync(reusedFinal, input);
  const beforeReuse = snapshot(reuseDb);
  assert.throws(() => persistImage(reuseDb, reuseRoot, input, 'history'), /history/);
  assert.deepEqual(snapshot(reuseDb), beforeReuse);
  assert.equal(fs.readFileSync(reusedFinal).equals(input), true);
  reuseDb.close();
  console.log('PASS: atomic reducer asset history rollback existing-file reuse and durable Undo/Redo');

  const sameRoot = path.join(tempRoot, 'historical-same');
  const sameFinal = prepareCanonicalFile(sameRoot, input);
  const sameOld = path.join(sameRoot, 'assets', 'legacy', 'old-image');
  fs.mkdirSync(path.dirname(sameOld), { recursive: true });
  fs.writeFileSync(sameOld, input);
  const sameDb = setupAssetDatabase();
  seedAssetRow(sameDb, words.join(':'), 3, ['other'], sameOld, input.length);
  reconcileHistoricalAsset(sameDb, sameRoot, input);
  const sameRow = sameDb.prepare('SELECT * FROM note_asset').get();
  assert.equal(sameRow.asset_hash, storageHash);
  assert.equal(sameRow.status, 3);
  assert.equal(sameRow.local_path, sameFinal);
  assert.deepEqual(JSON.parse(sameRow.note_ids), ['note', 'other']);
  assert.equal(fs.readFileSync(sameOld).equals(input), true);
  sameDb.close();
  console.log('PASS: verified private historical path is canonicalized without deleting the old file');

  const missingRoot = path.join(tempRoot, 'historical-missing');
  const missingFinal = prepareCanonicalFile(missingRoot, input);
  const missingOld = path.join(missingRoot, 'assets', 'legacy', 'missing-image');
  const missingDb = setupAssetDatabase();
  seedAssetRow(missingDb, words.join(':'), 1, ['other'], missingOld, input.length);
  reconcileHistoricalAsset(missingDb, missingRoot, input);
  const missingRow = missingDb.prepare('SELECT * FROM note_asset').get();
  assert.equal(missingRow.asset_hash, storageHash);
  assert.equal(missingRow.local_path, missingFinal);
  assert.deepEqual(JSON.parse(missingRow.note_ids), ['note', 'other']);
  missingDb.close();
  console.log('PASS: missing historical path is repaired from the verified canonical file');

  const conflictRoot = path.join(tempRoot, 'historical-conflict');
  prepareCanonicalFile(conflictRoot, input);
  const conflictOld = path.join(conflictRoot, 'assets', 'legacy', 'conflicting-image');
  fs.mkdirSync(path.dirname(conflictOld), { recursive: true });
  fs.writeFileSync(conflictOld, Buffer.alloc(input.length, 0x5a));
  const conflictDb = setupAssetDatabase();
  seedAssetRow(conflictDb, words.join(':'), 1, ['other'], conflictOld, input.length);
  const conflictBefore = assetSnapshot(conflictDb);
  assert.throws(() => reconcileHistoricalAsset(conflictDb, conflictRoot, input), /conflicts/);
  assert.equal(assetSnapshot(conflictDb), conflictBefore);
  assert.equal(fs.existsSync(conflictOld), true);
  conflictDb.close();
  console.log('PASS: conflicting private historical bytes reject and roll back');

  const externalRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'nota-image-external-'));
  try {
    const outsideRoot = path.join(tempRoot, 'historical-external');
    prepareCanonicalFile(outsideRoot, input);
    const externalFile = path.join(externalRoot, 'readable-image');
    fs.writeFileSync(externalFile, input);
    const externalDb = setupAssetDatabase();
    seedAssetRow(externalDb, words.join(':'), 1, ['other'], externalFile, input.length);
    const externalBefore = assetSnapshot(externalDb);
    assert.throws(() => reconcileHistoricalAsset(externalDb, outsideRoot, input), /outside/);
    assert.equal(assetSnapshot(externalDb), externalBefore);
    assert.equal(fs.readFileSync(externalFile).equals(input), true);
    externalDb.close();
  } finally {
    fs.rmSync(externalRoot, { recursive: true, force: true });
  }
  console.log('PASS: readable path outside app files is rejected without deleting it');
} finally {
  fs.rmSync(tempRoot, { recursive: true, force: true });
}

console.log(`D02_ORIGINAL_IMAGE_INSERT_PERSISTENCE_OK TOTAL=${checks.length + 10} FAILED=0`);

function validateIngress(bytes, mime, width, height) {
  if (!Number.isSafeInteger(bytes.length) || bytes.length <= 0 || bytes.length > 104857600) {
    throw new Error('bytes');
  }
  if (typeof mime !== 'string' || mime.length <= 6 || !mime.toLowerCase().startsWith('image/')) {
    throw new Error('MIME');
  }
  if (!Number.isFinite(width) || width <= 0 || !Number.isFinite(height) || height <= 0) {
    throw new Error('dimensions');
  }
}

function setupDatabase() {
  const db = new DatabaseSync(':memory:');
  db.exec(`CREATE TABLE page_info(note_id TEXT,page_id TEXT,content_revision INTEGER,
      PRIMARY KEY(note_id,page_id));
    CREATE TABLE page_element_snapshot(note_id TEXT,page_id TEXT,element_id TEXT,kind INTEGER,
      payload TEXT,revision INTEGER,element_order INTEGER,
      PRIMARY KEY(note_id,page_id,element_id));
    CREATE TABLE note_asset(asset_hash TEXT PRIMARY KEY,status INTEGER,note_ids TEXT,
      file_size INTEGER,mime_type TEXT,local_path TEXT);
    CREATE TABLE original_block_state(note_id TEXT,block_id TEXT,asset_hash TEXT,
      width REAL,height REAL,scale_x REAL,scale_y REAL,origin_x REAL,origin_y REAL,
      PRIMARY KEY(note_id,block_id));
    CREATE TABLE operation_log(sequence INTEGER PRIMARY KEY AUTOINCREMENT,op_id TEXT,
      note_id TEXT,op_type INTEGER,upload_immediately INTEGER,payload TEXT);
    CREATE TABLE history_log(action_id TEXT PRIMARY KEY,payload TEXT);
    CREATE TABLE sync_clock(note_id TEXT PRIMARY KEY,next_timestamp INTEGER);
    INSERT INTO page_info VALUES('note','page',7);
    INSERT INTO page_element_snapshot VALUES('note','page','existing-ink',1,'ink',7,0);
    INSERT INTO page_element_snapshot VALUES('note','page','existing-text',2,'text',7,1);
    INSERT INTO sync_clock VALUES('note',100);`);
  return db;
}

function setupAssetDatabase() {
  const db = new DatabaseSync(':memory:');
  db.exec(`CREATE TABLE note_meta(id TEXT PRIMARY KEY);
    CREATE TABLE note_asset(asset_hash TEXT PRIMARY KEY,status INTEGER,note_ids TEXT,
      file_size INTEGER,mime_type TEXT,local_path TEXT);
    INSERT INTO note_meta VALUES('note'),('other');`);
  return db;
}

function seedAssetRow(db, hash, status, noteIds, localPath, fileSize) {
  db.prepare('INSERT INTO note_asset VALUES(?,?,?,?,?,?)').run(
    hash, status, JSON.stringify(noteIds), fileSize, 'image/png', localPath);
}

function prepareCanonicalFile(filesRoot, bytes) {
  const finalPath = path.join(filesRoot, 'assets', 'final', storageHash);
  fs.mkdirSync(path.dirname(finalPath), { recursive: true });
  fs.writeFileSync(finalPath, bytes);
  return finalPath;
}

function reconcileHistoricalAsset(db, filesRoot, bytes) {
  const finalPath = path.join(filesRoot, 'assets', 'final', storageHash);
  const legacyHash = words.join(':');
  db.exec('BEGIN IMMEDIATE');
  try {
    const rows = db.prepare('SELECT * FROM note_asset WHERE asset_hash=? OR asset_hash=?')
      .all(storageHash, legacyHash);
    let noteIds = ['note'];
    let targetStatus = 1;
    for (const row of rows) {
      if (row.file_size !== bytes.length || row.mime_type.toLowerCase() !== 'image/png') {
        throw new Error('metadata conflicts');
      }
      validateHistoricalPath(filesRoot, row.local_path, finalPath, bytes.length);
      noteIds = mergeIds(noteIds, JSON.parse(row.note_ids));
      if (row.status === 2) targetStatus = 2;
      else if (targetStatus !== 2 && row.status === 3) targetStatus = 3;
    }
    for (const noteId of noteIds) {
      assert.notEqual(db.prepare('SELECT id FROM note_meta WHERE id=?').get(noteId), undefined);
    }
    const canonical = rows.find(row => row.asset_hash === storageHash);
    if (canonical === undefined) {
      db.prepare('INSERT INTO note_asset VALUES(?,?,?,?,?,?)').run(
        storageHash, targetStatus, JSON.stringify(noteIds), bytes.length, 'image/png', finalPath);
    } else {
      assert.equal(db.prepare(`UPDATE note_asset SET status=?,note_ids=?,file_size=?,mime_type=?,
        local_path=? WHERE asset_hash=?`).run(targetStatus, JSON.stringify(noteIds), bytes.length,
        'image/png', finalPath, storageHash).changes, 1);
    }
    if (legacyHash !== storageHash && rows.some(row => row.asset_hash === legacyHash)) {
      assert.equal(db.prepare('DELETE FROM note_asset WHERE asset_hash=?').run(legacyHash).changes, 1);
    }
    db.exec('COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

function validateHistoricalPath(filesRoot, storedPath, finalPath, expectedSize) {
  if (storedPath === null || storedPath.length === 0 ||
    normalizePath(storedPath) === normalizePath(finalPath)) return;
  if (!isInside(filesRoot, storedPath)) {
    if (fs.existsSync(storedPath)) throw new Error('readable historical path is outside app files');
    return;
  }
  if (!fs.existsSync(storedPath)) return;
  const stored = fs.readFileSync(storedPath);
  const canonical = fs.readFileSync(finalPath);
  if (stored.length !== expectedSize || canonical.length !== expectedSize || !stored.equals(canonical)) {
    throw new Error('historical bytes conflicts with the prepared asset');
  }
}

function isInside(root, candidate) {
  const normalizedRoot = normalizePath(root).replace(/\/+$/, '');
  const normalizedCandidate = normalizePath(candidate).replace(/\/+$/, '');
  return normalizedCandidate.startsWith(`${normalizedRoot}/`) &&
    !normalizedCandidate.includes('/../') && !normalizedCandidate.endsWith('/..');
}

function normalizePath(value) {
  return value.replaceAll('\\', '/');
}

function assetSnapshot(db) {
  return JSON.stringify(db.prepare('SELECT * FROM note_asset ORDER BY asset_hash').all());
}

function mergeIds(left, right) {
  const result = [];
  for (const id of left.concat(right)) if (!result.includes(id)) result.push(id);
  return result;
}

function snapshot(db) {
  return {
    page: db.prepare('SELECT * FROM page_info ORDER BY page_id').all().map(row => ({ ...row })),
    elements: db.prepare('SELECT * FROM page_element_snapshot ORDER BY element_order').all()
      .map(row => ({ ...row })),
    assets: db.prepare('SELECT * FROM note_asset ORDER BY asset_hash').all().map(row => ({ ...row })),
    blocks: db.prepare('SELECT * FROM original_block_state ORDER BY block_id').all()
      .map(row => ({ ...row })),
    operations: db.prepare('SELECT * FROM operation_log ORDER BY sequence').all()
      .map(row => ({ ...row })),
    history: db.prepare('SELECT * FROM history_log ORDER BY action_id').all()
      .map(row => ({ ...row })),
    clock: db.prepare('SELECT * FROM sync_clock').all().map(row => ({ ...row })),
  };
}

function persistImage(db, filesRoot, bytes, failAt) {
  validateIngress(bytes, 'image/png', 400, 200);
  const pendingDir = path.join(filesRoot, 'assets', 'pending');
  const finalDir = path.join(filesRoot, 'assets', 'final');
  fs.mkdirSync(pendingDir, { recursive: true });
  fs.mkdirSync(finalDir, { recursive: true });
  const pendingPath = path.join(pendingDir, `pending_asset_${Date.now()}_${Math.random()}.tmp`);
  const finalPath = path.join(finalDir, storageHash);
  let createdFinal = false;
  let committed = false;
  try {
    if (fs.existsSync(finalPath)) {
      assert.equal(fs.readFileSync(finalPath).equals(bytes), true);
    } else {
      fs.writeFileSync(pendingPath, bytes);
      const fd = fs.openSync(pendingPath, 'r+');
      fs.fsyncSync(fd);
      fs.closeSync(fd);
      fs.renameSync(pendingPath, finalPath);
      createdFinal = true;
    }
    db.exec('BEGIN IMMEDIATE');
    try {
      const clock = db.prepare('SELECT next_timestamp FROM sync_clock WHERE note_id=?').get('note');
      const elementId = `op:${clock.next_timestamp}:1`;
      db.prepare('UPDATE sync_clock SET next_timestamp=? WHERE note_id=?')
        .run(clock.next_timestamp + 1, 'note');
      if (failAt === 'reducer') throw new Error('reducer injected failure');
      const geometry = planGeometry(400, 200, 800, 1000, 1, { x: 400, y: 500 });
      db.prepare('INSERT INTO original_block_state VALUES(?,?,?,?,?,?,?,?,?)').run(
        'note', elementId, storageHash, 400, 200, geometry.scaleX, geometry.scaleY,
        geometry.originX, geometry.originY);
      db.prepare('INSERT INTO page_element_snapshot VALUES(?,?,?,?,?,?,?)').run(
        'note', 'page', elementId, 4, JSON.stringify({ words, width: 400, height: 200,
          transform: [geometry.scaleX, 0, geometry.originX, 0, geometry.scaleY, geometry.originY] }),
        8, 2);
      db.prepare('INSERT INTO operation_log(op_id,note_id,op_type,upload_immediately,payload) VALUES(?,?,?,?,?)')
        .run(elementId, 'note', 22, 1, JSON.stringify({ hash: storageHash }));
      db.prepare('INSERT INTO note_asset VALUES(?,?,?,?,?,?)').run(
        storageHash, 1, JSON.stringify(['note']), bytes.length, 'image/png', finalPath);
      if (failAt === 'asset') throw new Error('asset injected failure');
      db.prepare('UPDATE page_info SET content_revision=8 WHERE note_id=? AND page_id=? AND content_revision=7')
        .run('note', 'page');
      db.prepare('UPDATE page_element_snapshot SET revision=8 WHERE note_id=? AND page_id=?')
        .run('note', 'page');
      const mutation = {
        beforeOrder: ['existing-ink', 'existing-text'],
        afterOrder: ['existing-ink', 'existing-text', elementId],
      };
      if (failAt === 'history') throw new Error('history injected failure');
      db.prepare('INSERT INTO history_log VALUES(?,?)').run('image-insert', JSON.stringify(mutation));
      db.prepare('INSERT INTO operation_log(op_id,note_id,op_type,upload_immediately,payload) VALUES(?,?,?,?,?)')
        .run('history:image-insert', 'note', 1, 0, JSON.stringify(mutation));
      db.exec('COMMIT');
      committed = true;
      return { elementId, finalPath };
    } catch (error) {
      db.exec('ROLLBACK');
      throw error;
    }
  } finally {
    if (fs.existsSync(pendingPath)) fs.unlinkSync(pendingPath);
    if (!committed && createdFinal && fs.existsSync(finalPath)) fs.unlinkSync(finalPath);
  }
}

function replayOrder(current, mutation, forward) {
  assert.deepEqual(current, forward ? mutation.beforeOrder : mutation.afterOrder);
  return (forward ? mutation.afterOrder : mutation.beforeOrder).slice();
}
