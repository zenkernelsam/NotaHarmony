// Replay fixture — Phase 655：独立音频文件导入（原版 cv5 音频分支 →
// MediaMetadataRetriever 时长 → pu5 → izi.M → re0 资产 + iaj.a/yn2
// CREATE_RECORDING + te0 variant 0 单 op、不建页）。
// 静态断言原实现证据 + Harmony NoteImporter 的对齐实现。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';

const cv5 = fs.readFileSync(`${originalRoot}sources/defpackage/cv5.java`, 'utf8');
const pu5 = fs.readFileSync(`${originalRoot}sources/defpackage/pu5.java`, 'utf8');
const yq8 = fs.readFileSync(`${originalRoot}sources/defpackage/yq8.java`, 'utf8');
const izi = fs.readFileSync(`${originalRoot}sources/defpackage/izi.java`, 'utf8');
const yn2 = fs.readFileSync(`${originalRoot}sources/defpackage/yn2.java`, 'utf8');
const zq9 = fs.readFileSync(`${originalRoot}sources/defpackage/zq9.java`, 'utf8');
const nj3 = fs.readFileSync(`${originalRoot}sources/defpackage/nj3.java`, 'utf8');
const i58 = fs.readFileSync(`${originalRoot}sources/defpackage/i58.java`, 'utf8');

const importer = fs.readFileSync('note/src/main/ets/data/NoteImporter.ets', 'utf8')
  .replaceAll('\r\n', '\n');

let total = 0;
function check(condition, label) {
  assert.ok(condition, label);
  total++;
}
function section(source, startMarker, endMarker) {
  const start = source.indexOf(startMarker);
  const end = source.indexOf(endMarker, start);
  assert.ok(start !== -1 && end > start, startMarker);
  return source.slice(start, end);
}

// --- 原版证据：cv5 音频分支 → pu5 → izi.M → yn2 CREATE_RECORDING ---
check(i58.includes('new i58("*/*")'),
  'original i58.c picker type accepts */* (import then sniffs MIME)');
check(nj3.includes('mp3("audio/mpeg")') && nj3.includes('m4a("audio/mp4")') &&
  nj3.includes('wav("audio/wav")') && nj3.includes('aiff("audio/aiff")'),
  'nj3 audio type table: mp3/mp4/aac/wav/aiff/m4a with canonical MIMEs');
check(cv5.includes('extractMetadata(9)') &&
  cv5.includes('new pu5(new o88(ttfVarX, nj3Var, nj3Var, drfVar.a, 0, false), file2, j, str)') &&
  cv5.includes('strI = "audio/*"') && cv5.includes('j = 0'),
  'cv5 audio branch: temp copy → duration metadata (0 on failure) → pu5(file,duration,mime) with 0-page o88');
check(pu5.includes('public final File K') && pu5.includes('public final long L') &&
  pu5.includes('public final String M'),
  'pu5 carries file + duration + mime');
check(yq8.includes('uu5Var instanceof pu5') && yq8.includes('return izi.M'),
  'yq8.f routes pu5 audio payloads to izi.M');
check(izi.includes('new re0(file, str, pu5Var, p29Var, ttfVar, (ef2) null, 0)') &&
  izi.includes('iaj.a(null, lvd.a1(uu5Var2.J.d'),
  'izi.M: re0 builds the recording asset on IO, iaj.a wraps stem+asset+0+duration');
check(izi.includes('Failed to create audio recording asset'),
  'izi.M fail-closes with a logged asset-creation failure');
check(zq9.includes('mx7Var.put(npbVar.b(yn2.class), haa.CREATE_RECORDING)') &&
  yn2.includes('Start time must be before end time'),
  'yn2 journals as haa.CREATE_RECORDING; start<=end invariant upstream');

// --- Harmony 实现对齐：选择器/分发 ---
check(importer.includes("'.mp3'") && importer.includes("'.aiff'") &&
  importer.includes('IMPORTED_AUDIO_SUFFIX_MIME'),
  'picker filters cover the nj3 audio suffixes');
check(importer.includes('isImportedAudioFileName(fileName)') &&
  importer.includes('importAudioFromBytes(bytes, fileName)'),
  'importFromFile dispatches audio suffixes to importAudioFromBytes');
check(importer.includes("'.mp3': 'audio/mpeg'") &&
  importer.includes("'.m4a': 'audio/mp4'") &&
  importer.includes("'.aiff': 'audio/aiff'"),
  'suffix→MIME map mirrors the nj3 audio table');
check(importer.includes("return 'audio/*'"),
  'unknown audio mime falls back to audio/* like the original');

// --- Harmony 实现对齐：时长 + 暂存 + 落库 ---
const dur = section(importer, 'async function extractImportedAudioDuration(',
  '\n}');
check(dur.includes('media.createAVMetadataExtractor()') &&
  dur.includes('extractor.fdSrc = { fd: file.fd, offset: 0, length: size }') &&
  dur.includes('metadata.duration'),
  'duration extracted via AVMetadataExtractor fdSrc (extractMetadata(9) parity)');
check(dur.includes('return 0'),
  'duration extraction failure falls back to 0 like cv5 j=0');
check(dur.includes('await extractor.release()') && dur.includes('fileIo.closeSync(file)'),
  'extractor and file are always released');

const body = section(importer, 'private async importAudioFromBytes(',
  '// 我方格式导入');
check(body.includes('audio_import_') && body.includes('writeFileFully(stagingPath, data)'),
  'audio bytes stage under assets/pending before asset ingest');
check(body.includes('createNoteWithMeta('),
  'imported audio note uses createNoteWithMeta (no stray bootstrap page)');
check(body.includes('persistCapturedOriginalRecording('),
  'recording asset + CREATE_RECORDING op reuse the canonical persist path');
check(body.includes('mediaDurationMs: durationMs') &&
  body.includes('endTime: now + durationMs') &&
  body.includes('durationMs: durationMs'),
  'capture timestamps span [now, now+duration] (original 0L->duration)');
check(body.includes('pageCount: 0'),
  'audio import produces a 0-page note like o88 pages=0');
check(body.includes('removeFailedImport(createdNoteId)'),
  'failed audio import cleans the partially-written note');
check(body.includes('await NoteImporter.importMutex.lock()'),
  'audio import serializes with the shared import mutex');
check(body.includes('fileIo.unlinkSync(stagingPath)'),
  'staging file is unlinked in finally when persist did not consume it');

console.log(`D05_ORIGINAL_AUDIO_FILE_IMPORT_REPLAY_OK TOTAL=${total} FAILED=0`);
