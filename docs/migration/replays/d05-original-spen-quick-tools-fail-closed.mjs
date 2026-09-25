// D05 原版 SPen Quick Tools fail-closed — Phase 709（ADR-0657）
// 原版 ac4.T（SPEN_QUICK_TOOLS，序号 8）+ te3.a() 三星厂商门 +
// e31/r5f SPen 远程事件源 → u7b 快捷工具弹出；Harmony 手写笔栈
// 无 SPen 远程协议、厂商门恒假，呈现旗标关闭态。
import { readFileSync } from 'node:fs';
import { strict as assert } from 'node:assert';

const read = (p) => readFileSync(p, 'utf8');
const JADX = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3';
const strings = read(`${JADX}/resources/res/values/strings.xml`);
const ac4 = read(`${JADX}/sources/defpackage/ac4.java`);
const xod = read(`${JADX}/sources/defpackage/xod.java`);
const te3 = read(`${JADX}/sources/defpackage/te3.java`);
const ra = read(`${JADX}/sources/defpackage/ra.java`);
const bq1 = read(`${JADX}/sources/defpackage/bq1.java`);
const a8b = read(`${JADX}/sources/defpackage/a8b.java`);

let total = 0;
const check = (cond, name) => {
  total++;
  if (!cond) console.error(`FAILED: ${name}`);
  assert.ok(cond, name);
};

// --- 原版旗标链 ---
check(ac4.includes('"SPEN_QUICK_TOOLS", 8') && ac4.includes('T = ac4Var9'),
  'ac4 SPEN_QUICK_TOOLS 序号8 → T');
check(xod.includes('te3.a()') && xod.includes('lc4.a(ac4.T)'),
  'xod 可用性 = 三星门 && 旗标');
check(te3.includes('public static final boolean a()'),
  'te3.a() 设备检查存在');
check(ra.includes('Build.MANUFACTURER') && ra.includes('"samsung"'),
  'ra case23 Build.MANUFACTURER 三星厂商门');
check(bq1.includes('w7b.b().contains(r5fVar.g())') &&
  bq1.includes('new u7b('), 'bq1 配对笔+远程事件源 → u7b 弹出状态');
check(a8b.includes('xod'), 'a8b 工具栏 ViewModel 注入 xod');

// --- 原版字符串面 ---
for (const s of ['cd_quick_tool_color', 'cd_quick_tool_eraser',
  'cd_quick_tool_highlighter', 'cd_quick_tool_pen', 'cd_quick_tool_pencil']) {
  check(strings.includes(`feature_note__${s}`), `strings ${s}`);
}

// --- Harmony 侧：旗标关闭态 ---
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const toolbar = read('note/src/main/ets/ui/editor/EditorToolbar.ets');
const notePage = read('note/src/main/ets/ui/editor/NotePage.ets');
for (const [src, tag] of [[canvas, 'NoteCanvasView'], [toolbar, 'EditorToolbar'],
  [notePage, 'NotePage']]) {
  check(!/\bspen\b|quickTool|penRemote|airCommand/i.test(src),
    `${tag} 无 SPen 快捷工具实现`);
}
check(!read('note/src/main/resources/base/element/string.json')
  .includes('quick_tool_pen'), 'Harmony 无快捷工具面板字符串');

// --- ADR/证据 ---
check(read('docs/migration/adr/ADR-0657-original-spen-quick-tools-failclosed.md')
  .includes('SPen'), 'ADR-0657 声明 SPen 远程 SDK 边界');
check(read('docs/migration/evidence/original-spen-quick-tools-jadx-2026-09-25.md')
  .includes('samsung'), '证据文档记录三星厂商门');

console.log(`D05_ORIGINAL_SPEN_QUICK_TOOLS_FAIL_CLOSED_OK TOTAL=${total} FAILED=0`);
