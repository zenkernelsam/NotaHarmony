import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources';

function read(relative) {
  return fs.readFileSync(path.join(root, relative), 'utf8');
}

const cleanup = read('note/src/main/ets/data/NoteExportTemporaryArtifactCleanup.ets');
const database = read('note/src/main/ets/data/DatabaseManager.ets');
const exporter = read('note/src/main/ets/data/NoteExporter.ets');
const recordingCleanup = read(
  'note/src/main/ets/core/adaptation/OriginalRecordingCaptureArtifactCleanup.ets');
const backup = read('note/src/main/ets/notebackupability/NoteBackupAbility.ets');
const originalExportRepository = fs.readFileSync(
  path.join(originalRoot, 'defpackage/g64.java'), 'utf8');
const originalExportLifecycle = fs.readFileSync(
  path.join(originalRoot, 'defpackage/f64.java'), 'utf8');
const originalCacheCleanup = fs.readFileSync(
  path.join(originalRoot, 'defpackage/gv2.java'), 'utf8');

const openAndMigrate = database.slice(database.indexOf('private async openAndMigrate('),
  database.indexOf('private async repairAssetNoteReferences('));
const cleanupCall = openAndMigrate.indexOf('cleanupInterruptedNoteExports(context.tempDir)');
const databaseOpen = openAndMigrate.indexOf('relationalStore.getRdbStore(context, config)');

const checks = [
  ['original owns a private cache exports directory',
    originalExportRepository.includes('new File(this.a.getCacheDir(), "exports")')],
  ['original marks export creation and sweeps expired directories',
    originalExportLifecycle.includes('new File(file, ".created").createNewFile()') &&
      originalExportRepository.includes('tf4.u0(file2)') &&
      originalExportRepository.includes('ijg.r0(24, dr3.HOURS)')],
  ['original also clears interrupted cache temp artifacts on owner startup',
    /svd\.n0\(name, "temp_"[\s\S]*file\.delete\(\)/.test(originalCacheCleanup)],
  ['Harmony producer uses an owned export filename namespace',
    exporter.includes('`${context.tempDir}/export_${Date.now()}.note`')],
  ['normal export completion still unlinks its staging file',
    exporter.includes('if (tmpPath.length > 0)') && exporter.includes('fileIo.unlinkSync(tmpPath)')],
  ['cleanup accepts only current Harmony export artifacts',
    cleanup.includes('/^export_\\d+\\.note$/')],
  ['cleanup is non-recursive and never deletes directories',
    cleanup.includes('fileIo.listFileSync(directory, { recursion: false })') &&
      cleanup.includes('if (!fileIo.statSync(candidate).isFile())') &&
      !cleanup.includes('rmdirSync')],
  ['cleanup re-proves direct-child ownership before unlink',
    cleanup.includes('directChildPath(directory, child)') &&
      cleanup.includes("relative.indexOf('/') >= 0") &&
      cleanup.indexOf('directChildPath(directory, child)') <
        cleanup.indexOf('fileIo.unlinkSync(candidate)')],
  ['export cleanup remains separate from recording filename ownership',
    !recordingCleanup.includes('export_') && !cleanup.includes('recording_')],
  ['startup cleanup runs before the first RDB open',
    cleanupCall >= 0 && cleanupCall < databaseOpen],
  ['cleanup failures are isolated per directory and per file',
    (cleanup.match(/catch \(error\)/g) ?? []).length >= 2 && cleanup.includes('report.failed++')],
  ['system backup does not copy tempDir staging artifacts',
    backup.includes("const ROOTS: string[] = [FILES_ROOT, DATABASE_ROOT]") &&
      !backup.includes("const TEMP_ROOT")],
];

for (const [name, ok] of checks) {
  assert.equal(ok, true, `FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}

const exportArtifact = /^export_\d+\.note$/;

function cleanupModel(tempRoot) {
  let removed = 0;
  if (!fs.existsSync(tempRoot) || !fs.statSync(tempRoot).isDirectory()) return removed;
  for (const entry of fs.readdirSync(tempRoot, { withFileTypes: true })) {
    if (!entry.isFile() || !exportArtifact.test(entry.name)) continue;
    fs.unlinkSync(path.join(tempRoot, entry.name));
    removed++;
  }
  return removed;
}

const temporaryRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'nota-export-cleanup-'));
try {
  fs.writeFileSync(path.join(temporaryRoot, 'export_100.note'), 'owned');
  fs.writeFileSync(path.join(temporaryRoot, 'export_bad.note'), 'keep');
  fs.writeFileSync(path.join(temporaryRoot, 'export_101.note.bak'), 'keep');
  fs.writeFileSync(path.join(temporaryRoot, 'user.note'), 'keep');
  fs.mkdirSync(path.join(temporaryRoot, 'export_102.note'));
  const nested = path.join(temporaryRoot, 'nested');
  fs.mkdirSync(nested);
  fs.writeFileSync(path.join(nested, 'export_103.note'), 'keep');

  assert.equal(cleanupModel(temporaryRoot), 1,
    'FAILED: startup cleanup did not remove exactly the owned direct-child export file');
  console.log('PASS: runtime model removes the interrupted direct-child export artifact');
  assert.equal(fs.existsSync(path.join(temporaryRoot, 'export_bad.note')), true);
  assert.equal(fs.existsSync(path.join(temporaryRoot, 'export_101.note.bak')), true);
  assert.equal(fs.existsSync(path.join(temporaryRoot, 'user.note')), true);
  assert.equal(fs.statSync(path.join(temporaryRoot, 'export_102.note')).isDirectory(), true);
  assert.equal(fs.existsSync(path.join(nested, 'export_103.note')), true);
  console.log('PASS: runtime model preserves unknown, nested, and directory targets');
  assert.equal(cleanupModel(temporaryRoot), 0,
    'FAILED: startup cleanup is not idempotent after the owned export is gone');
  console.log('PASS: runtime model is idempotent');
} finally {
  fs.rmSync(temporaryRoot, { recursive: true, force: true });
}

console.log(`TOTAL=${checks.length + 3} FAILED=0`);
