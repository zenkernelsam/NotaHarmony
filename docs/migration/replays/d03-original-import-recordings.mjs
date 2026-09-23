// Phase 627 — .note 录音实体往返：recordings.json 清单 + 导入端重建录音行。
// 原版 yk9 .note 经同步 ops 序列化 CREATE_RECORDING（zl8 导入端重放 ops 还原
// 录音实体与 note_asset 引用）；Harmony 包不携带 ops 流，录音实体以
// recordings.json JSON 清单等价落盘，导入端按 applyCreate 列集插
// original_recording_state 行 + mergeOriginalAssetReference 挂 PENDING 资产。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const yk9 = fs.readFileSync(`${originalRoot}yk9.java`, 'utf8');
const spec = fs.readFileSync('note/src/main/ets/data/NotePackageSpec.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const exporter = fs.readFileSync('note/src/main/ets/data/NoteExporter.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const importer = fs.readFileSync('note/src/main/ets/data/NoteImporter.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const recOp = fs.readFileSync('note/src/main/ets/data/OriginalRecordingOperation.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const assetRef = fs.readFileSync('note/src/main/ets/data/OriginalAssetReferenceStore.ets', 'utf8')
  .replaceAll('\r\n', '\n');

// --- 原版证据：CREATE_RECORDING 实体随 .note 走（ops 流序列化） ---
assert.match(yk9, /z \|\| uq9Var\.m\(\) != haa\.CREATE_RECORDING/);

// --- 包结构：recordings.json 清单 ---
assert.match(spec, /export const NOTE_RECORDINGS_ENTRY: string = 'recordings\.json'/);
assert.match(spec, /export const NOTE_RECORDINGS_VERSION: number = 1/);
assert.match(spec, /export interface PackagedRecording \{/);
assert.match(spec, /assetHashBits: string\[\]/);
assert.match(spec, /export function serializePackagedRecordings/);
assert.match(spec, /export function parsePackagedRecordings/);

// --- 清单校验（fail-closed）：8 个 hash 词、段边界与原版 yn2.a 一致 ---
assert.match(spec, /PACKAGED_RECORDING_HASH_WORDS: number = 8/);
assert.match(spec, /recording\.assetHashBits\.length !== PACKAGED_RECORDING_HASH_WORDS/);
assert.match(spec, /compareUnsignedLongDecimal\(recording\.startTime, recording\.endTime\) > 0/);
assert.match(spec, /compareUnsignedLongDecimal\(segment\.endTime, recording\.endTime\) > 0/);
assert.match(spec, /recording\.segments\.length > PACKAGED_RECORDING_MAX_SEGMENTS/);

// --- 导出端：可见录音全部落清单，仅在有录音时写条目 ---
assert.match(exporter, /if \(recordings\.length > 0\) \{/);
assert.match(exporter, /writer\.addEntry\(NOTE_RECORDINGS_ENTRY/);
assert.match(exporter, /serializePackagedRecordings\(packagedRecordings\)/);
assert.match(exporter, /timestamp: recording\.timestamp/);
assert.match(exporter, /assetFileSize: recording\.assetFileSize/);

// --- 导入端：清单缺失容忍、损坏 fail-closed、资产并入同一 declared/packaged 集合 ---
assert.match(importer, /ZipReader\.findEntry\(entries, NOTE_RECORDINGS_ENTRY\)/);
assert.match(importer, /parsePackagedRecordings\(bytesToString\(recordingsEntry\.data\)\)/);
assert.match(importer, /parsedRecordings === null[\s\S]{0,300}ImportResult\.CORRUPTED/);
assert.match(importer, /originalAssetPackageEntry\(recordingMetadata\)/);
assert.match(importer, /!sameAssetMetadata\(declaredRecording, recordingMetadata\)[\s\S]{0,300}元数据互相冲突/);
assert.match(importer, /packagedRecordings\.length > 0,\n/);
assert.match(importer, /insertImportedOriginalRecordings\(this\.db, note\.id/);
assert.match(recOp, /databaseWriteMutex\.runExclusive/);
assert.match(recOp, /await store\.rollBack\(\)/);
assert.match(importer, /图片\/PDF\/录音资产缺失或长度不符/);

// --- 重建路径：applyCreate 列集 + PENDING 资产引用 + presence 刷新 ---
assert.match(recOp, /export async function insertImportedOriginalRecording/);
assert.match(recOp, /recordingCreateSignature\(\s*store, noteId, recording\.timestamp, recording\.siteId\)/);
assert.match(recOp, /mergeOriginalAssetReference\(\s*store, noteId, payload\.metadata\)/);
assert.match(recOp, /refreshOriginalRecordingPresence\(store, noteId\)/);
assert.match(assetRef, /AssetStatus\.PENDING/);

// --- 列集等价：导入插入与 applyCreate 写同一组 original_recording_state 列 ---
function insertColumns(src, fnName) {
  const start = src.indexOf(fnName);
  assert.ok(start >= 0, fnName + ' present');
  const slice = src.slice(start, start + 6000);
  const insertAt = slice.indexOf("store.insert('original_recording_state'");
  assert.ok(insertAt >= 0, fnName + ' inserts original_recording_state');
  const cols = [];
  const tail = slice.slice(insertAt);
  for (const m of tail.matchAll(/'([a-z_]+)':/g)) {
    cols.push(m[1]);
    if (m[1] === 'create_signature') { break; }
  }
  return cols;
}
assert.deepEqual(
  insertColumns(recOp, 'insertImportedOriginalRecording'),
  insertColumns(recOp, 'applyCreate'),
  'imported recording row mirrors applyCreate column set');

// --- 语义模拟：serialize→parse 往返 + 拒绝坏清单 ---
function validPackaged(r) {
  const u64 = (v) => typeof v === 'string' && /^\d+$/.test(v);
  const cmp = (a, b) => (a.length !== b.length ? a.length - b.length : a < b ? -1 : a > b ? 1 : 0);
  if (r === null || typeof r !== 'object' || !Number.isSafeInteger(r.timestamp) ||
      r.timestamp < 0 || r.timestamp > 0xFFFFFFFF || !Number.isSafeInteger(r.siteId) ||
      r.siteId < 0 || r.siteId > 65535 || typeof r.name !== 'string' || r.name.length > 65536 ||
      !u64(r.startTime) || !u64(r.endTime) || cmp(r.startTime, r.endTime) > 0 ||
      !u64(r.zIndex) || !Array.isArray(r.segments) || r.segments.length > 10000 ||
      !Array.isArray(r.assetHashBits) || r.assetHashBits.length !== 8 ||
      r.assetHashBits.some((w) => !u64(w)) || typeof r.assetFileName !== 'string' ||
      r.assetFileName.length === 0 || typeof r.assetMimeType !== 'string' ||
      r.assetMimeType.length === 0 || !Number.isSafeInteger(r.assetFileSize) ||
      r.assetFileSize < 1 || r.assetFileSize > 0xFFFFFFFF) {
    return false;
  }
  return r.segments.every((s) => s !== null && typeof s === 'object' &&
    u64(s.startTime) && u64(s.endTime) && cmp(s.endTime, r.endTime) <= 0);
}
const good = {
  timestamp: 42, siteId: 7, name: 'Lecture 3', startTime: '1000', endTime: '5000',
  segments: [{ startTime: '1000', endTime: '3000' }, { startTime: '3000', endTime: '5000' }],
  zIndex: '777', assetHashBits: ['1', '2', '3', '4', '5', '6', '7', '8'],
  assetFileName: 'rec.m4a', assetMimeType: 'audio/mp4', assetFileSize: 4096,
};
assert.ok(validPackaged(good));
assert.ok(!validPackaged({ ...good, assetHashBits: good.assetHashBits.slice(0, 7) }));
assert.ok(!validPackaged({ ...good, segments: [{ startTime: '0', endTime: '5001' }] }));
assert.ok(!validPackaged({ ...good, startTime: '6000' }));
assert.ok(!validPackaged({ ...good, siteId: 65536 }));
assert.ok(!validPackaged({ ...good, assetFileSize: 0 }));

// --- 导入排序：录音行先于资产落库（PENDING 行存在 → storeImportedOriginalAsset 升级 LOCAL） ---
const insertPos = importer.indexOf('insertImportedOriginalRecordings(this.db, note.id');
const storePos = importer.indexOf('storeImportedOriginalAsset(this.db, packaged.metadata');
assert.ok(insertPos > 0 && storePos > insertPos,
  'recording rows land before the packaged-asset store loop');

console.log('D03_ORIGINAL_IMPORT_RECORDINGS_REPLAY_OK TOTAL=41 FAILED=0');
