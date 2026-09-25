// Phase 741 — cd_* 无障碍尾项：cd_delete_recording 插值录音名 +
// 其余 17 键覆盖/边界登记
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

const adrP = 'docs/migration/adr/ADR-0689-original-cd-a11y-tail.md';
const evP = 'docs/migration/evidence/original-cd-a11y-tail-jadx-2026-09-25.md';
const rpP = 'docs/migration/reports/phase-741-original-cd-a11y-tail.md';
check('ADR-0689 存在', fs.existsSync(R(adrP)));
check('证据文档存在', fs.existsSync(R(evP)));
check('Phase 741 报告存在', fs.existsSync(R(rpP)));

const adr = read(adrP);
const ev = read(evP);

// —— 原版 JADX 证据 ——
const strings = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/resources/res/values/strings.xml', 'utf8');
check('原版 cd_delete_recording = "Delete %1$s"',
  strings.includes('cd_delete_recording">Delete %1$s'));
check('原版 user_facing_name = "Recording %1$s"',
  strings.includes('record_recording_user_facing_name">Recording %1$s'));
check('原版 cd_open_note_action 存在',
  strings.includes('cd_open_note_action">Open note'));

const m8 = fs.readFileSync(path.join(ORIG, 'defpackage/m8.java'), 'utf8');
check('m8 删除钮 cd_delete_recording 插值 str',
  m8.includes('cd_delete_recording') && m8.includes('new Object[]{str}'));
const n05 = fs.readFileSync(path.join(ORIG, 'defpackage/n05.java'), 'utf8');
check('n05 strT = user_facing_name',
  n05.includes('record_recording_user_facing_name'));
const e5j = fs.readFileSync(path.join(ORIG, 'defpackage/e5j.java'), 'utf8');
check('e5j cd_open_note_action click-label',
  e5j.includes('cd_open_note_action'));
const d32 = fs.readFileSync(path.join(ORIG, 'defpackage/d32.java'), 'utf8');
check('d32 ±10s a11y 双键',
  d32.includes('cd_rewind_10_seconds') && d32.includes('cd_forward_10_seconds'));

// —— Harmony 实现 ——
const panel = read('note/src/main/ets/ui/editor/RecordingPanel.ets');
check('删除钮 a11y = cd_delete_recording 插值',
  panel.includes("accessibilityText($r('app.string.cd_delete_recording', index + 1))"));
check('静态 delete_recording 不再绑删除钮',
  !panel.includes("accessibilityText($r('app.string.delete_recording'))"));
check('行标题仍为 user_facing_name 同名源',
  panel.includes("recording_user_facing_name', index + 1"));

const en = read('note/src/main/resources/base/element/string.json');
const zh = read('note/src/main/resources/zh_CN/element/string.json');
check('en cd_delete_recording', en.includes('"cd_delete_recording", "value": "Delete Recording %d"'));
check('zh cd_delete_recording', zh.includes('"cd_delete_recording", "value": "删除录音 %d"'));
check('delete_recording 键保留', en.includes('"delete_recording"'));

// —— 文档钉 ——
check('ADR 引证 cd_delete_recording', adr.includes('cd_delete_recording'));
check('ADR 引证 m8/n05', adr.includes('m8') && adr.includes('n05'));
check('ADR 登记 open_note_action 等价', adr.includes('cd_open_note_action'));
check('ADR 登记 quick_tool 边界', adr.includes('cd_quick_tool'));
check('证据含 17 键清单', ev.includes('cd_add_note') && ev.includes('cd_folder_name'));
check('证据引证 n05:364', ev.includes('n05:364') || ev.includes('n05.java:364'));

check('修复总纲登记 Phase 741', read('docs/migration/audit-2026-08/修复总纲.md').includes('Phase 741'));
check('修复总纲2 登记 Phase 741', read('docs/migration/audit-2026-08/修复总纲2.md').includes('Phase 741'));
check('进展文档登记 Phase 741', read('docs/migration/reports/修复进展-2026-08-09.md').includes('Phase 741'));

console.log(`D02_ORIGINAL_CD_A11Y_TAIL_REPLAY_OK TOTAL=${total} FAILED=${failed}`);
process.exit(failed === 0 ? 0 : 1);
