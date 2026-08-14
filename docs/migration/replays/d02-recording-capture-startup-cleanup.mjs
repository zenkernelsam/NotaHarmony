import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources';

function read(relative) {
  return fs.readFileSync(path.join(root, relative), 'utf8');
}

const cleanup = read(
  'note/src/main/ets/core/adaptation/OriginalRecordingCaptureArtifactCleanup.ets');
const database = read('note/src/main/ets/data/DatabaseManager.ets');
const microphone = read(
  'note/src/main/ets/core/adaptation/OriginalRecordingMicrophoneBackend.ets');
const internalAudio = read(
  'note/src/main/ets/core/adaptation/OriginalRecordingInternalAudioBackend.ets');
const notePage = read('note/src/main/ets/ui/editor/NotePage.ets');
const persistence = read('note/src/main/ets/data/OriginalRecordingPersistence.ets');
const backup = read('note/src/main/ets/notebackupability/NoteBackupAbility.ets');
const originalCleanup = fs.readFileSync(path.join(originalRoot, 'defpackage/gv2.java'), 'utf8');
const originalMicrophone = fs.readFileSync(path.join(originalRoot, 'defpackage/tr8.java'), 'utf8');
const originalCaptureService = fs.readFileSync(path.join(originalRoot,
  'com/gingerlabs/notability/feature/note/toolbox/audio/record/wrapper/audio/' +
  'AudioCaptureService.java'), 'utf8');

const openAndMigrate = database.slice(database.indexOf('private async openAndMigrate('),
  database.indexOf('private async repairAssetNoteReferences('));
const cleanupCall = openAndMigrate.indexOf(
  'cleanupInterruptedOriginalRecordingCaptures(context.tempDir)');
const databaseOpen = openAndMigrate.indexOf('relationalStore.getRdbStore(context, config)');

const checks = [
  ['original recording owner removes both interrupted capture workspaces at startup',
    /m18\.m0\("temp_recordings", "AudioCaptures"\)[\s\S]*file2\.delete\(\)/
      .test(originalCleanup)],
  ['original capture producers own temp_recordings and AudioCaptures',
    /getFilesDir\(\), "temp_recordings"[\s\S]*"recording_"/.test(originalMicrophone) &&
      /getFilesDir\(\), "AudioCaptures"[\s\S]*"Recording-"/.test(originalCaptureService)],
  ['Harmony capture producers write their two owned names directly under context.tempDir',
    notePage.includes('new OriginalRecordingMicrophoneBackend(context.tempDir)') &&
      notePage.includes('new OriginalRecordingInternalAudioBackend(context.tempDir)') &&
      microphone.includes('`${this.temporaryDirectory}/recording_${Date.now()}_${this.sequence}.m4a`') &&
      internalAudio.includes(
        '`${this.temporaryDirectory}/internal_recording_${Date.now()}_${this.sequence}.m4a`')],
  ['cleanup accepts only microphone and internal-audio capture filename shapes',
    cleanup.includes('/^recording_\\d+_\\d+\\.m4a$/') &&
      cleanup.includes('/^internal_recording_\\d+_\\d+\\.m4a$/')],
  ['cleanup scans only direct tempDir children and never recursively removes a directory',
    cleanup.includes('fileIo.listFileSync(directory, { recursion: false })') &&
      !cleanup.includes('rmdirSync')],
  ['cleanup rejects nested or foreign listed paths before unlink',
    cleanup.includes('directChildPath(directory, child)') &&
      cleanup.includes("relative.indexOf('/') >= 0") &&
      cleanup.indexOf('directChildPath(directory, child)') <
        cleanup.indexOf('fileIo.unlinkSync(candidate)')],
  ['cleanup preserves directories even when their names mimic capture files',
    cleanup.includes('if (!fileIo.statSync(candidate).isFile())')],
  ['recording cleanup runs once before the first RDB publication',
    cleanupCall >= 0 && cleanupCall < databaseOpen &&
      openAndMigrate.indexOf('this.applicationFilesDir = context.filesDir') < cleanupCall],
  ['normal stop, abort, and persistence paths still consume their capture file',
    microphone.includes('await this.dispose(true, true)') &&
      internalAudio.includes('await this.dispose(true)') &&
      persistence.includes('unlinkIfPresent(capture.temporaryPath)')],
  ['cleanup failures remain isolated and temp files remain outside system backup roots',
    (cleanup.match(/catch \(error\)/g) ?? []).length >= 2 &&
      cleanup.includes('report.failed++') &&
      backup.includes("const ROOTS: string[] = [FILES_ROOT, DATABASE_ROOT]")],
];

for (const [name, ok] of checks) {
  assert.equal(ok, true, `FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}

const microphoneCapture = /^recording_\d+_\d+\.m4a$/;
const internalAudioCapture = /^internal_recording_\d+_\d+\.m4a$/;

function cleanupModel(tempRoot) {
  let removed = 0;
  if (!fs.existsSync(tempRoot) || !fs.statSync(tempRoot).isDirectory()) return removed;
  for (const entry of fs.readdirSync(tempRoot, { withFileTypes: true })) {
    const expected = microphoneCapture.test(entry.name) || internalAudioCapture.test(entry.name);
    if (!entry.isFile() || !expected) continue;
    fs.unlinkSync(path.join(tempRoot, entry.name));
    removed++;
  }
  return removed;
}

const temporaryRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'nota-recording-cleanup-'));
try {
  const outside = fs.mkdtempSync(path.join(os.tmpdir(), 'nota-recording-outside-'));
  try {
    fs.writeFileSync(path.join(temporaryRoot, 'recording_100_1.m4a'), 'microphone');
    fs.writeFileSync(path.join(temporaryRoot, 'internal_recording_101_2.m4a'), 'device');
    fs.writeFileSync(path.join(temporaryRoot, 'recording_bad_3.m4a'), 'keep');
    fs.writeFileSync(path.join(temporaryRoot, 'internal_recording_102_4.m4a.bak'), 'keep');
    fs.writeFileSync(path.join(temporaryRoot, 'export_103.note'), 'keep');
    fs.mkdirSync(path.join(temporaryRoot, 'recording_104_5.m4a'));
    const nested = path.join(temporaryRoot, 'nested');
    fs.mkdirSync(nested);
    fs.writeFileSync(path.join(nested, 'internal_recording_105_6.m4a'), 'keep');
    fs.writeFileSync(path.join(outside, 'recording_106_7.m4a'), 'keep');

    assert.equal(cleanupModel(temporaryRoot), 2,
      'FAILED: startup cleanup did not remove exactly the two owned direct-child captures');
    console.log('PASS: runtime model removes microphone and internal-audio capture artifacts');
    assert.equal(fs.existsSync(path.join(temporaryRoot, 'recording_bad_3.m4a')), true);
    assert.equal(fs.existsSync(
      path.join(temporaryRoot, 'internal_recording_102_4.m4a.bak')), true);
    assert.equal(fs.existsSync(path.join(temporaryRoot, 'export_103.note')), true);
    assert.equal(fs.statSync(path.join(temporaryRoot, 'recording_104_5.m4a')).isDirectory(), true);
    assert.equal(fs.existsSync(path.join(nested, 'internal_recording_105_6.m4a')), true);
    assert.equal(fs.existsSync(path.join(outside, 'recording_106_7.m4a')), true);
    console.log('PASS: runtime model preserves unknown, nested, directory, and outside targets');
    assert.equal(cleanupModel(temporaryRoot), 0,
      'FAILED: startup cleanup is not idempotent after owned captures are gone');
    console.log('PASS: runtime model is idempotent');
  } finally {
    fs.rmSync(outside, { recursive: true, force: true });
  }
} finally {
  fs.rmSync(temporaryRoot, { recursive: true, force: true });
}

console.log(`TOTAL=${checks.length + 3} FAILED=0`);
