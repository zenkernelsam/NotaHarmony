#!/usr/bin/env node
// D02 Replay — Phase 733 原版 MainActivity 生命周期方法尾审（ADR-0681）
// 验证：ADR/证据文档齐备、登记分类齐全、无加速度计/Play 更新残留代码引入。
import { readFileSync, existsSync } from 'node:fs';
import { join, resolve } from 'node:path';

const ROOT = resolve(process.cwd());
const read = (p) => readFileSync(join(ROOT, p), 'utf8');
const checks = [];
const t = (name, ok) => checks.push({ name, ok: !!ok });

const adrPath = 'docs/migration/adr/ADR-0681-original-mainactivity-lifecycle.md';
const evPath = 'docs/migration/evidence/original-mainactivity-lifecycle-jadx-2026-09-25.md';
t('ADR-0681 存在', existsSync(join(ROOT, adrPath)));
t('证据文档存在', existsSync(join(ROOT, evPath)));
const adr = read(adrPath);
const ev = read(evPath);

// —— ADR 覆盖项 ——
for (const sym of ['l4d', 'kw2', 'tw2', 'h96', 's3i', 'hd5', 'xod', 'hv7', 'kmi']) {
  t(`ADR 提及 ${sym}`, adr.includes(sym));
}
t('ADR 登记摇晃调试菜单 fail-closed', /摇晃/.test(adr) && /fail-closed/.test(adr));
t('ADR 登记 Play 应用内更新边界', /应用内更新/.test(adr) && /AppUpdateManager|play\.core\.install/.test(adr));
t('ADR 记录 2.7g 阈值', /2\.7\s*g/.test(adr));
t('ADR 记录域名门控', adr.includes('gingerlabs.com') && adr.includes('notability.com'));
t('ADR 引证 tw2 菜单项', adr.includes('FEATURE_FLAGS') && adr.includes('LOG_TAGS'));
t('ADR 交叉引用既有登记', adr.includes('ADR-0671') && adr.includes('ADR-0679') && adr.includes('ADR-0668'));

// —— 证据文档 ——
t('证据记录传感器 type=1', ev.includes('TYPE_ACCELEROMETER') || ev.includes('sensor.getType() == 1'));
t('证据记录 1s 防抖', /1000|1\s*秒防抖|1\s*s/.test(ev));
t('证据记录 Play 渠道门控', ev.includes('y46.PlayStore'));
t('证据记录 identityHashCode 守卫', ev.includes('identityHashCode'));
t('证据含未验证声明', ev.includes('未验证声明'));

// —— Harmony 侧无残留引入 ——
const srcFiles = [
  'note/src/main/ets/noteability/NoteAbility.ets',
  'note/src/main/ets/ui/editor/NotePage.ets',
  'note/src/main/ets/core/adaptation/OriginalRecordingSourceBackend.ets',
];
for (const f of srcFiles) {
  const src = read(f);
  t(`${f} 无加速度计订阅`, !/sensor\.|Sensor|accelerometer|getDefaultSensor/i.test(src));
}
let etsAll = '';
for (const f of [
  'note/src/main/ets/noteability/NoteAbility.ets',
  'note/src/main/ets/ui/library/LibraryPage.ets',
]) {
  etsAll += read(f);
}
t('无摇晃手势实现', !/shake|2\.7|onSensorChanged/i.test(etsAll));
t('无应用内更新调用', !/AppUpdate|appUpdate|InstallState|checkUpdate/i.test(etsAll));

// —— 追踪文档 ——
const plan1 = read('docs/migration/audit-2026-08/修复总纲.md');
const plan2 = read('docs/migration/audit-2026-08/修复总纲2.md');
const prog = read('docs/migration/reports/修复进展-2026-08-09.md');
t('修复总纲登记 Phase 733', plan1.includes('Phase 733'));
t('修复总纲2 登记 Phase 733', plan2.includes('Phase 733'));
t('进展文档登记 Phase 733', prog.includes('Phase 733'));

const report = 'docs/migration/reports/phase-733-original-mainactivity-lifecycle.md';
t('Phase 733 中文报告存在', existsSync(join(ROOT, report)));

let fail = 0;
for (const c of checks) {
  if (!c.ok) { fail++; console.log(`FAIL ${c.name}`); }
}
console.log(`D02_ORIGINAL_MAINACTIVITY_LIFECYCLE_REPLAY_OK TOTAL=${checks.length} FAILED=${fail}`);
process.exit(fail ? 1 : 0);
