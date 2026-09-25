// Phase 736 — NbApplication 初始化链收口
// 证据：onCreate 逐项分类；wya=ProcessLifecycleOwner；WorkManager 工位；诊断件。
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

const adrP = 'docs/migration/adr/ADR-0684-original-nbapplication-init.md';
const evP = 'docs/migration/evidence/original-nbapplication-init-jadx-2026-09-25.md';
const rpP = 'docs/migration/reports/phase-736-original-nbapplication-init.md';
check('ADR-0684 存在', fs.existsSync(R(adrP)));
check('证据文档存在', fs.existsSync(R(evP)));
check('Phase 736 报告存在', fs.existsSync(R(rpP)));

const adr = read(adrP);
const ev = read(evP);

// —— 原版证据 ——
const app = fs.readFileSync(
  path.join(ORIG, 'com/gingerlabs/notability/app/NbApplication.java'), 'utf8');
check('原版 StrictMode.LAX', app.includes('StrictMode.ThreadPolicy.LAX'));
check('原版 ProcessFreezeDetector', app.includes('ProcessFreezeDetector'));
check('原版 ExportSweepWorker 工位', app.includes('ExportSweepWorker'));
check('原版 NoteAssetDownloadWorker 工位', app.includes('NoteAssetDownloadWorker'));
check('原版 App Launch 事件', app.includes('Process.myPid()'));
const wya = fs.readFileSync(path.join(ORIG, 'defpackage/wya.java'), 'utf8');
check('wya 生命周期注册表', wya.includes('cf7') && wya.includes('getLifecycle'));
const cj = fs.readFileSync(path.join(ORIG, 'defpackage/cj.java'), 'utf8');
check('cj 事件名 App Launch', cj.includes('"App Launch"'));

// —— ADR/证据覆盖 ——
for (const s of ['wya', 'ProcessFreezeDetector', 'App Launch', 'ExportSweepWorker',
  'NoteAssetDownloadWorker', 'StrictMode']) {
  check(`证据覆盖 ${s}`, ev.includes(s));
}
check('ADR 记录生命周期总线', adr.includes('wya') && adr.includes('ProcessLifecycleOwner'));
check('ADR 记录 WorkManager 边界', adr.includes('WorkManager'));
check('ADR 记录消费者后端边界', /后端|边界/.test(adr));
check('ADR 结构性差异声明', adr.includes('结构性差异'));
check('证据含未验证声明', ev.includes('未验证声明'));

// —— Harmony 侧复核 ——
const ability = read('note/src/main/ets/noteability/NoteAbility.ets');
check('onForeground/onBackground 钩子存在',
  ability.includes('onForeground()') && ability.includes('onBackground()'));
const cleanup = read('note/src/main/ets/data/NoteExportTemporaryArtifactCleanup.ets');
check('导出清扫函数在位', cleanup.includes('cleanupInterruptedNoteExports'));

// —— 追踪 ——
check('修复总纲登记 Phase 736', read('docs/migration/audit-2026-08/修复总纲.md').includes('Phase 736'));
check('修复总纲2 登记 Phase 736', read('docs/migration/audit-2026-08/修复总纲2.md').includes('Phase 736'));
check('进展文档登记 Phase 736', read('docs/migration/reports/修复进展-2026-08-09.md').includes('Phase 736'));

console.log(`D02_ORIGINAL_NBAPPLICATION_INIT_REPLAY_OK TOTAL=${total} FAILED=${failed}`);
process.exit(failed ? 1 : 0);
