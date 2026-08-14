import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';

function read(relative) {
  return fs.readFileSync(path.join(root, relative), 'utf8');
}

const cleanup = read('note/src/main/ets/data/AssetTemporaryArtifactCleanup.ets');
const database = read('note/src/main/ets/data/DatabaseManager.ets');
const imageStore = read('note/src/main/ets/data/ImageAssetPackageStore.ets');
const recordingStore = read('note/src/main/ets/data/OriginalRecordingPersistence.ets');
const assetRepository = read('note/src/main/ets/data/AssetRepositoryImpl.ets');
const backup = read('note/src/main/ets/notebackupability/NoteBackupAbility.ets');
const originalCleanup = fs.readFileSync(path.join(originalRoot, 'gv2.java'), 'utf8');

const openAndMigrate = database.slice(database.indexOf('private async openAndMigrate('),
  database.indexOf('private async repairAssetNoteReferences('));
const cleanupCall = openAndMigrate.indexOf('cleanupInterruptedAssetArtifacts(this.applicationFilesDir)');
const databaseOpen = openAndMigrate.indexOf('relationalStore.getRdbStore(context, config)');

const checks = [
  ['original startup cleanup removes interrupted recording captures',
    /m18\.m0\("temp_recordings", "AudioCaptures"\)[\s\S]*file2\.delete\(\)/.test(originalCleanup)],
  ['original startup cleanup removes private PDF conversion temporaries',
    /svd\.n0\(name, "temp_"[\s\S]*file\.delete\(\)/.test(originalCleanup) &&
      /_converted\.pdf[\s\S]*file\.delete\(\)/.test(originalCleanup)],
  ['all Harmony asset temporary producers use owned filename namespaces',
    imageStore.includes('`/pending_asset_${Date.now()}_') &&
      recordingStore.includes('`/pending_recording_${Date.now()}_') &&
      assetRepository.includes('`/deleted_asset_${Date.now()}_')],
  ['cleanup accepts only the three owned temporary filename shapes',
    cleanup.includes('/^pending_asset_\\d+_\\d+\\.tmp$/') &&
      cleanup.includes('/^pending_recording_\\d+_\\d+\\.tmp$/') &&
      cleanup.includes('/^deleted_asset_\\d+_\\d+_\\d+\\.tmp$/')],
  ['cleanup scans pending and trash without recursive deletion',
    cleanup.includes("'assets/pending'") && cleanup.includes("'assets/trash'") &&
      cleanup.includes('fileIo.listFileSync(directory, { recursion: false })') &&
      !cleanup.includes('rmdirSync')],
  ['cleanup rejects nested or foreign paths before unlink',
    cleanup.includes('directChildPath(directory, child)') &&
      cleanup.includes("relative.indexOf('/') >= 0") &&
      cleanup.indexOf('directChildPath(directory, child)') < cleanup.indexOf('fileIo.unlinkSync(candidate)')],
  ['cleanup preserves directories even when their names mimic temporary files',
    cleanup.includes('if (!fileIo.statSync(candidate).isFile())')],
  ['startup cleanup runs once before the first RDB open',
    cleanupCall >= 0 && cleanupCall < databaseOpen &&
      openAndMigrate.indexOf('this.applicationFilesDir = context.filesDir') < cleanupCall],
  ['cleanup failures are isolated per directory and per file',
    (cleanup.match(/catch \(error\)/g) ?? []).length >= 2 &&
      cleanup.includes('report.failed++')],
  ['system backup continues to exclude transient asset directories',
    backup.includes("['assets/pending', 'assets/trash', 'glmath']")],
];

for (const [name, ok] of checks) {
  assert.equal(ok, true, `FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}

const pendingAsset = /^pending_asset_\d+_\d+\.tmp$/;
const pendingRecording = /^pending_recording_\d+_\d+\.tmp$/;
const deletedAsset = /^deleted_asset_\d+_\d+_\d+\.tmp$/;

function cleanupModel(filesRoot) {
  let removed = 0;
  for (const [relative, trash] of [['assets/pending', false], ['assets/trash', true]]) {
    const directory = path.join(filesRoot, relative);
    if (!fs.existsSync(directory) || !fs.statSync(directory).isDirectory()) continue;
    for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
      const expected = trash ? deletedAsset.test(entry.name) :
        pendingAsset.test(entry.name) || pendingRecording.test(entry.name);
      if (!entry.isFile() || !expected) continue;
      fs.unlinkSync(path.join(directory, entry.name));
      removed++;
    }
  }
  return removed;
}

const temporaryRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'nota-asset-cleanup-'));
try {
  const pending = path.join(temporaryRoot, 'assets', 'pending');
  const trash = path.join(temporaryRoot, 'assets', 'trash');
  const outside = path.join(temporaryRoot, 'outside');
  fs.mkdirSync(pending, { recursive: true });
  fs.mkdirSync(trash, { recursive: true });
  fs.mkdirSync(outside, { recursive: true });

  fs.writeFileSync(path.join(pending, 'pending_asset_100_2.tmp'), 'image');
  fs.writeFileSync(path.join(pending, 'pending_recording_101_3.tmp'), 'audio');
  fs.writeFileSync(path.join(pending, 'pending_asset_bad.tmp'), 'keep');
  fs.writeFileSync(path.join(pending, 'user-note.txt'), 'keep');
  fs.mkdirSync(path.join(pending, 'pending_recording_102_4.tmp'));
  const nested = path.join(pending, 'nested');
  fs.mkdirSync(nested);
  fs.writeFileSync(path.join(nested, 'pending_asset_103_5.tmp'), 'keep');
  fs.writeFileSync(path.join(trash, 'deleted_asset_104_6_0.tmp'), 'trash');
  fs.writeFileSync(path.join(trash, 'deleted_asset_104_6.tmp'), 'keep');
  fs.writeFileSync(path.join(outside, 'pending_asset_105_7.tmp'), 'keep');

  assert.equal(cleanupModel(temporaryRoot), 3,
    'FAILED: startup cleanup did not remove exactly the owned direct-child files');
  console.log('PASS: runtime model removes image, recording, and detached asset artifacts');
  assert.equal(fs.existsSync(path.join(pending, 'pending_asset_bad.tmp')), true);
  assert.equal(fs.existsSync(path.join(pending, 'user-note.txt')), true);
  assert.equal(fs.statSync(path.join(pending, 'pending_recording_102_4.tmp')).isDirectory(), true);
  assert.equal(fs.existsSync(path.join(nested, 'pending_asset_103_5.tmp')), true);
  assert.equal(fs.existsSync(path.join(trash, 'deleted_asset_104_6.tmp')), true);
  assert.equal(fs.existsSync(path.join(outside, 'pending_asset_105_7.tmp')), true);
  console.log('PASS: runtime model preserves unknown, nested, directory, and outside targets');
  assert.equal(cleanupModel(temporaryRoot), 0,
    'FAILED: startup cleanup is not idempotent after owned artifacts are gone');
  console.log('PASS: runtime model is idempotent');
} finally {
  fs.rmSync(temporaryRoot, { recursive: true, force: true });
}

console.log(`TOTAL=${checks.length + 3} FAILED=0`);
