// Phase 626 — .note 导出把录音音频并入 assets/（yk9 对齐）。
// 原版 yk9 写 {version, manifest.json, noteBundle, assets/<hash>[.<ext>]}；
// CREATE_RECORDING 在 includeRecordings(yk9.O=分享层开关) 时把录音 ua0
// 计入 note.assets；资产文件缺失 → MissingAssetsException 中止导出。
// Recordings/<j0.m(name)>.<ext> 只出现在 x59 的 ZIP 分享格式（deferred）。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const yk9 = fs.readFileSync(`${originalRoot}yk9.java`, 'utf8');
const x59 = fs.readFileSync(`${originalRoot}x59.java`, 'utf8');
const exporter = fs.readFileSync('note/src/main/ets/data/NoteExporter.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const packageStore = fs.readFileSync('note/src/main/ets/data/ImageAssetPackageStore.ets', 'utf8')
  .replaceAll('\r\n', '\n');

// --- 原版 .note 包结构证据（yk9.java） ---
assert.match(yk9, /new ZipEntry\("version"\)/);
assert.match(yk9, /new ZipEntry\("manifest\.json"\)/);
assert.match(yk9, /new ZipEntry\("noteBundle"\)/);
assert.match(yk9, /"assets\/" \+ ug5\.e\(ba6\.e0\(ua0Var\)\)/);
assert.match(yk9, /throw new MissingAssetsException/);
assert.match(yk9, /z \|\| uq9Var\.m\(\) != haa\.CREATE_RECORDING/);
assert.match(yk9, /extensionFromMimeType != null \? "\."\.concat\(extensionFromMimeType\) : ""/);
assert.ok(!yk9.includes('"mp4"'), 'yk9 has no mp4 fallback (that is x59-only)');

// --- x59 是 ZIP 分享格式而非 .note：Recordings/ 只属于它 ---
assert.match(x59, /Recordings\//);
assert.match(x59, /vh2\.o\(str2, "\.zip"\)/);
assert.match(x59, /fileH\.exists\(\)/);

// --- Harmony 实现锚点 ---
assert.match(exporter, /OriginalRecordingStore/);
assert.match(exporter, /listVisible\(noteId\)/);
assert.match(exporter, /this\.addAsset\(assets, \{/);
assert.match(exporter, /assetHashBits: recording\.assetHashBits/);
assert.match(exporter, /mimeType: recording\.assetMimeType/);
assert.match(exporter, /resolveOriginalAsset\(assetRepository, metadata\)/);
assert.match(exporter, /asset === null[\s\S]{0,80}throw new Error/);
assert.match(packageStore, /`assets\/\$\{originalAssetStorageHash/);
assert.ok(!exporter.includes('Recordings/${'), 'no Recordings/ entry writer in .note export');
assert.ok(!exporter.includes('sanitizeOriginalRecordingEntryName'), 'j0.m sanitizer removed');

// --- addAsset 冲突/去重语义模拟 ---
const assets = new Map();
function addAsset(metadata) {
  const path = `assets/${metadata.hash}`;
  const existing = assets.get(path);
  if (existing !== undefined &&
      (existing.fileSize !== metadata.fileSize || existing.mimeType !== metadata.mimeType)) {
    throw new Error(`asset metadata conflicts for ${path}`);
  }
  if (existing === undefined) {
    assets.set(path, metadata);
  }
  return path;
}
const rec = { hash: 'ab12', fileSize: 100, mimeType: 'audio/mp4' };
assert.equal(addAsset(rec), 'assets/ab12');
assert.equal(addAsset(rec), 'assets/ab12');
assert.equal(assets.size, 1);
assert.throws(() => addAsset({ hash: 'ab12', fileSize: 999, mimeType: 'audio/mp4' }));

console.log('D02_ORIGINAL_EXPORT_RECORDINGS_REPLAY_OK TOTAL=25 FAILED=0');
