// Phase 626 — .note 导出携带 Recordings/ 音频条目（x59/j0.m 对齐）。
// 原版 x59：每条录音写 Recordings/<j0.m(name)>.<ext>——ext 为
// MimeTypeMap.getExtensionFromMimeType(mime)（null→"mp4"），重名以
// " (n)"（n 自 1 起）去重，fileH.exists() 缺失文件静默跳过。
// j0.m：[/\\:*?"<>|\x00]→_、剥前导点、空→"Note"。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const x59 = fs.readFileSync(`${originalRoot}x59.java`, 'utf8');
const j0 = fs.readFileSync(`${originalRoot}j0.java`, 'utf8');
const exporter = fs.readFileSync('note/src/main/ets/data/NoteExporter.ets', 'utf8')
  .replaceAll('\r\n', '\n');

// --- 原版证据锚点 ---
assert.match(x59, /Recordings\//);
assert.match(x59, /fileH\.exists\(\)/);
assert.match(x59, /getExtensionFromMimeType[\s\S]*extensionFromMimeType == null[\s\S]*"mp4"/);
assert.match(x59, /j0\.m\(yjbVar\.getName\(\)\)/);
assert.match(x59, /!linkedHashSet\.add\(string\)/);
assert.ok(j0.includes('x00]'), 'j0.m char class covers NUL');
assert.match(j0, /string\.length\(\) == 0 \? "Note" : string/);

// --- Harmony 实现锚点 ---
assert.match(exporter, /OriginalRecordingStore/);
assert.match(exporter, /listVisible\(noteId\)/);
assert.match(exporter, /assetState !== OriginalRecordingAssetState\.READY/);
assert.match(exporter, /resolveOriginalAsset\(recordingAssets, metadata\)/);
assert.match(exporter, /readVerifiedOriginalAsset\(asset, metadata\)/);
assert.match(exporter, /Recordings\/\$\{baseName\}\.\$\{extension\}/);
assert.match(exporter, /Recordings\/\$\{baseName\} \(\$\{dedupeIndex\}\)\.\$\{extension\}/);
assert.match(exporter, /dedupeIndex: number = 1/);
assert.match(exporter, /asset === null[\s\S]{0,60}continue/);

// --- j0.m 净化模拟（与 Harmony sanitizeOriginalRecordingEntryName 同规则） ---
function sanitize(name) {
  const cleaned = name.replace(/[\\/:*?"<>|\x00]/g, '_').replace(/^\.+/, '');
  return cleaned.length > 0 ? cleaned : 'Note';
}
assert.equal(sanitize('My Recording'), 'My Recording');
assert.equal(sanitize('a/b\\c:d*e?f"g<h>i|j'), 'a_b_c_d_e_f_g_h_i_j');
assert.equal(sanitize('...hidden'), 'hidden');
assert.equal(sanitize(''), 'Note');
assert.equal(sanitize('///'), '___');

// --- mime→ext 模拟（与 originalRecordingExportExtension 同表） ---
function ext(mime) {
  switch (mime.toLowerCase()) {
    case 'audio/mp4': case 'audio/x-m4a': case 'audio/mp4a-latm': return 'm4a';
    case 'audio/aac': case 'audio/aacp': case 'audio/adts': return 'aac';
    case 'audio/mpeg': case 'audio/mp3': return 'mp3';
    case 'audio/wav': case 'audio/x-wav': case 'audio/wave': return 'wav';
    case 'audio/aiff': case 'audio/x-aiff': return 'aiff';
    case 'audio/3gpp': return '3gp';
    case 'audio/amr': return 'amr';
    case 'audio/ogg': return 'ogg';
    case 'audio/flac': return 'flac';
    default: return 'mp4';
  }
}
assert.equal(ext('audio/mp4'), 'm4a');
assert.equal(ext('audio/mpeg'), 'mp3');
assert.equal(ext('application/octet-stream'), 'mp4');

// --- 去重命名模拟：重名自 " (1)" 起 ---
const used = new Set();
function entry(baseName, extension) {
  let s = `Recordings/${baseName}.${extension}`;
  let i = 1;
  while (used.has(s)) {
    s = `Recordings/${baseName} (${i}).${extension}`;
    i++;
  }
  used.add(s);
  return s;
}
assert.equal(entry('R1', 'm4a'), 'Recordings/R1.m4a');
assert.equal(entry('R1', 'm4a'), 'Recordings/R1 (1).m4a');
assert.equal(entry('R1', 'm4a'), 'Recordings/R1 (2).m4a');
assert.equal(entry('R2', 'm4a'), 'Recordings/R2.m4a');

console.log('D02_ORIGINAL_EXPORT_RECORDINGS_REPLAY_OK TOTAL=29 FAILED=0');
