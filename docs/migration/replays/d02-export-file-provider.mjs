// Phase 848 — 1.0.1→1.0.3 文件级增量 + 导出完成追踪
import { readFileSync, readdirSync } from 'node:fs';
import { join, relative } from 'node:path';

const R = 'C:/Users/Cisco He/Desktop/Notability';
const A = `${R}/decompiled_1.0.1/sources/com/gingerlabs/notability`;
const B = `${R}/decompiled_1.0.3/sources/com/gingerlabs/notability`;
const results = [];
const ck = (n, ok) => results.push([n, ok]);
const list = (root) => {
  const out = [];
  const walk = (d) => { for (const f of readdirSync(d, { withFileTypes: true })) { const p = join(d, f.name); if (f.isDirectory()) walk(p); else if (f.name.endsWith('.java')) out.push(relative(root, p).replace(/\\/g, '/')); } };
  walk(root);
  return out.sort();
};
const a = list(A), b = list(B);
const added = b.filter(f => !a.includes(f));
const removed = a.filter(f => !b.includes(f));

ck('差分仅 +2/−0', added.length === 2 && removed.length === 0);
ck('新增=ExportFileProvider+ExportSweepWorker', added.includes('data/library/state/ExportFileProvider.java') && added.includes('data/library/state/ExportSweepWorker.java'));

// 1.0.1 manifest 用通用 FileProvider
const m1 = readFileSync(`${R}/decompiled_1.0.1/resources/AndroidManifest.xml`, 'utf8');
ck('1.0.1 通用 FileProvider', m1.includes('androidx.core.content.FileProvider') && !m1.includes('ExportFileProvider'));

// ExportFileProvider 语义
const src = readFileSync(`${B}/data/library/state/ExportFileProvider.java`, 'utf8');
ck('继承 FileProvider 子类 ye4', src.includes('extends ye4'));
ck('exports/<id> 段提取', src.includes('"exports"') && src.includes('getPathSegments'));
ck('PFD 包装 + OnCloseListener', src.includes('ParcelFileDescriptor.wrap') && src.includes('OnCloseListener'));
ck('h64 引用计数开闭', src.includes('h64.b') && src.includes('h64.a(str2)'));
ck('IOException 回收降级', src.includes('adoptFd'));
ck('日志双通道', src.includes('Could not reclaim export descriptor') && src.includes('Export descriptor close tracking unavailable'));

// Harmony 同步导出模型
const nx = readFileSync('C:/HarmonyProject/NotaHarmony/note/src/main/ets/data/NoteExporter.ets', 'utf8');
ck('Harmony DocumentViewPicker.save', nx.includes('DocumentViewPicker') && nx.includes('.save('));
ck('Harmony finally unlinkSync 清理', nx.includes('unlinkSync(tmpPath)') && nx.includes('finally'));
ck('Harmony 无 FileProvider 等价', !nx.includes('OnCloseListener'));

let pass = 0;
for (const [n, ok] of results) {
  if (ok) { pass++; console.log(`PASS ${n}`); }
  else console.log(`FAIL ${n}`);
}
console.log(`${pass}/${results.length} checks passed`);
process.exit(pass === results.length ? 0 : 1);
