// Phase 735 — 导出暂存启动清扫覆盖面补全
// 证据：g64 全区清扫 + gv2 启动 temp_ 清扫；Harmony 正则扩至五前缀。
import fs from 'node:fs';
import path from 'node:path';

const REPO = path.resolve(process.cwd());
const ORIG = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources';
const R = (p) => path.join(REPO, p);
const read = (p) => fs.readFileSync(R(p), 'utf8');

let total = 0, failed = 0;
const check = (name, cond) => {
  total++;
  if (!cond) { failed++; console.log('FAIL', name); }
};

const adrP = 'docs/migration/adr/ADR-0683-original-export-sweep-coverage.md';
const evP = 'docs/migration/evidence/original-export-sweep-jadx-2026-09-25.md';
const rpP = 'docs/migration/reports/phase-735-original-export-sweep.md';
check('ADR-0683 存在', fs.existsSync(R(adrP)));
check('证据文档存在', fs.existsSync(R(evP)));
check('Phase 735 报告存在', fs.existsSync(R(rpP)));

const adr = read(adrP);
const ev = read(evP);

// —— 原版证据 ——
const g64 = fs.readFileSync(path.join(ORIG, 'defpackage/g64.java'), 'utf8');
check('g64 24h TTL', g64.includes('ijg.r0(24, dr3.HOURS)'));
check('g64 15min 周期', g64.includes('ijg.r0(15, dr3.MINUTES)'));
check('g64 500MB LRU 上限', g64.includes('524288000'));
check('g64 .created 标记判定', g64.includes('".created"'));
check('g64 递归删除', g64.includes('tf4.u0(file2)') || g64.includes('tf4.u0(file3)'));
const f64 = fs.readFileSync(path.join(ORIG, 'defpackage/f64.java'), 'utf8');
check('f64 .created 打点写入侧', f64.includes('new File(file, ".created").createNewFile()'));
check('证据记录三参数', ev.includes('dr3.HOURS') && ev.includes('dr3.MINUTES') && ev.includes('524288000'));

// —— Harmony 实现 ——
const cleanup = read('note/src/main/ets/data/NoteExportTemporaryArtifactCleanup.ets');
check('正则覆盖 .note', cleanup.includes('export_\\d+\\.note'));
check('正则覆盖 pdf + enc 变体', cleanup.includes('note_export_(?:enc_)?\\d+\\.pdf'));
check('正则覆盖图像/zip', cleanup.includes('pages?_export_\\d+\\.(?:png|jpe?g|zip)'));
check('保持非递归', cleanup.includes('recursion: false'));
check('保持仅删文件', cleanup.includes('statSync(candidate).isFile()'));
check('保持直接子路径复核', cleanup.includes('directChildPath(directory, child)'));
check('无 rmdir 引入', !cleanup.includes('rmdirSync'));

// —— producer 命名逐一对应 ——
const noteExp = read('note/src/main/ets/data/NoteExporter.ets');
const pdfExp = read('note/src/main/ets/data/PagePdfExporter.ets');
const imgExp = read('note/src/main/ets/data/PageImageExporter.ets');
check('NoteExporter 暂存名', noteExp.includes('export_${Date.now()}.note'));
check('PagePdfExporter 暂存名', pdfExp.includes('note_export_${Date.now()}.pdf'));
check('PagePdfExporter 加密暂存名', pdfExp.includes('note_export_enc_${Date.now()}.pdf'));
check('PageImageExporter 单页名', imgExp.includes('page_export_${Date.now()}${suffix}'));
check('PageImageExporter zip 名', imgExp.includes('pages_export_${Date.now()}.zip'));

// —— 正则行为模型 ——
const re = /^(?:export_\d+\.note|note_export_(?:enc_)?\d+\.pdf|pages?_export_\d+\.(?:png|jpe?g|zip))$/;
for (const ok of ['export_1.note', 'note_export_2.pdf', 'note_export_enc_3.pdf',
  'page_export_4.png', 'page_export_5.jpg', 'pages_export_6.zip']) {
  check(`正则接受 ${ok}`, re.test(ok));
}
for (const bad of ['export_x.note', 'note_export_2.txt', 'user.note',
  'page_export_3.pdf', 'note_export_enc_4.png', 'pages_export_5.zip.bak',
  'recording_6.m4a']) {
  check(`正则拒绝 ${bad}`, !re.test(bad));
}

// —— 追踪 ——
check('ADR 记录结构性不移植项', adr.includes('24h') || adr.includes('TTL'));
check('证据含未验证声明', ev.includes('未验证声明'));
check('修复总纲登记 Phase 735', read('docs/migration/audit-2026-08/修复总纲.md').includes('Phase 735'));
check('修复总纲2 登记 Phase 735', read('docs/migration/audit-2026-08/修复总纲2.md').includes('Phase 735'));
check('进展文档登记 Phase 735', read('docs/migration/reports/修复进展-2026-08-09.md').includes('Phase 735'));

console.log(`D02_ORIGINAL_EXPORT_SWEEP_REPLAY_OK TOTAL=${total} FAILED=${failed}`);
process.exit(failed ? 1 : 0);
