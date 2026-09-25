// D05 原版 Inky 动画吉祥物模式 fail-closed — Phase 708（ADR-0656）
// 原版 ac4.p0（INKY_MODE，序号 31）+ 选项菜单 "Inky" 开关 +
// inky_mode_enabled datastore → h26 以 Rive 运行时渲染
// inky_2026_v32.riv 悬浮层；Harmony 无 Rive 运行时、呈现
// 旗标关闭态（无 Inky 入口/实现），登记 fail-closed。
import { readFileSync, existsSync, statSync } from 'node:fs';
import { join } from 'node:path';
import { strict as assert } from 'node:assert';

const read = (p) => readFileSync(p, 'utf8');
const JADX = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3';
const strings = read(`${JADX}/resources/res/values/strings.xml`);
const ac4 = read(`${JADX}/sources/defpackage/ac4.java`);
const w16 = read(`${JADX}/sources/defpackage/w16.java`);
const l26 = read(`${JADX}/sources/defpackage/l26.java`);
const k26 = read(`${JADX}/sources/defpackage/k26.java`);
const t9f = read(`${JADX}/sources/defpackage/t9f.java`);
const h26 = read(`${JADX}/sources/defpackage/h26.java`);
const z22 = read(`${JADX}/sources/defpackage/z22.java`);

let total = 0;
const check = (cond, name) => {
  total++;
  if (!cond) console.error(`FAILED: ${name}`);
  assert.ok(cond, name);
};

// --- 原版旗标链 ---
check(ac4.includes('"INKY_MODE", 31') && ac4.includes('p0 = ac4Var32'),
  'ac4 INKY_MODE 序号31 → p0');
check(w16.includes('lc4.a(ac4.p0)') && w16.includes('&& !z'),
  'w16 评估 INKY_MODE 旗标 → inkyModeAvailable');
check(t9f.includes('inkyModeAvailable=') && t9f.includes('inkyModeEnabled='),
  't9f 工具栏状态含 inkyModeAvailable/Enabled 字段');
check(l26.includes('inky_mode_enabled') && k26.includes('inkyModeEnabled='),
  'l26/k26 datastore 偏好 inky_mode_enabled 默认关');

// --- 原版 UI 面 ---
check(strings.includes('feature_note__options_menu_inky'),
  'options_menu_inky 字符串存在');
check(z22.includes('options_menu_inky'), 'z22 选项菜单渲染 Inky 开关');

// --- Rive 运行时依赖 ---
check(h26.includes('RiveFileSource') && h26.includes('inky_2026_v32'),
  'h26 经 RiveFileSource 加载 inky_2026_v32');
check(h26.includes('inkyAlpha'), 'h26 inkyAlpha 渐变过渡');
const riv = `${JADX}/resources/res/raw/feature_note_inky__inky_2026_v32.riv`;
check(existsSync(riv) && statSync(riv).size > 100_000,
  '.riv 二进制资产存在于 res/raw（>100KB）');

// --- Harmony 侧：旗标关闭态 ---
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const notePage = read('note/src/main/ets/ui/editor/NotePage.ets');
for (const [src, tag] of [[canvas, 'NoteCanvasView'], [notePage, 'NotePage']]) {
  // 仅豁免既有审计注释（"Inky(sc9.j)" 说明不移植理由）；
  // 实现标识符一律不得出现。
  check(!/inkyMode|inky_mode|RiveFileSource|\.riv\b/i.test(src),
    `${tag} 无 Inky/Rive 实现标识符`);
}
check(notePage.includes('Inky(sc9.j)'),
  'NotePage 注释记录 Inky 不移植理由（既有审计）');
check(!read('note/src/main/resources/base/element/string.json').includes('inky'),
  'Harmony 字符串资源无 inky 条目');

// --- ADR/证据 ---
check(read('docs/migration/adr/ADR-0656-original-inky-mode-failclosed.md')
  .includes('Rive'), 'ADR-0656 声明 Rive 运行时边界');
check(read('docs/migration/evidence/original-inky-mode-jadx-2026-09-25.md')
  .includes('inky_2026_v32'), '证据文档记录 Rive 资产');

console.log(`D05_ORIGINAL_INKY_MODE_FAIL_CLOSED_OK TOTAL=${total} FAILED=0`);
