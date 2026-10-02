// Phase 1476 — 1.4.2 Ctrl+Shift+T 视口中心矩形选区（f2:230-238 →
// ome.a() 清选 + ome.g.l(null, u64(sbe)) 矩形选区请求）。
// Original evidence (decompiled_1.4.2):
//   pa8.java — G = ofk.e(48) = KEYCODE_T。
//   f2.java:230-238（!rsi 门内、!pa8.W 块内、Ctrl+D 支后、M/I 支前）：
//     `db8.r && db8.s && pa8.a(n, pa8.G)` + UP + u7b.g +
//     `!bd8.U.r`（c5i isEffectivelyEnabled）→
//     `jC = ((exj) jxjVar.e.F.getValue()).c()` 视口中心 →
//     `sbe(cx-120, cy-60, cx+120, cy+60)` → `ome.a()` 清选 →
//     `ome.g.l(null, new u64(sbe))`。
//   ch1.java:55-68 ——拖拽矩形完成 z3 支同走 `ome.g.l(null,u64)`；
//   r3b.java:27 `c(sbe, msf)` → p3b 协程 = 消费端矩形相交命中。
//   消费规则（链内无 b2=0）→ DOWN 亦吞键。
// Harmony：onCanvasKeyEvent !textEditing 块内（Ctrl+Shift+M/I 支前）
//   → applyKeyboardRectSelection()：viewport.screenToCanvas(画布中心)
//   + beginSelection(RECTANGLE)/updateSelection/finalizeSelection
//   复用拖矩形完成同一核（rectIntersects/selectionPath 命中）。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const CANVAS = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const CHORDS = 'note/src/main/ets/data/OriginalKeyboardChords.ets';
const canvas = readFileSync(CANVAS, 'utf8').replace(/\r\n/g, '\n');
const chords = readFileSync(CHORDS, 'utf8').replace(/\r\n/g, '\n');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- 常量：T 键码 + 证据注释 ---
check(chords.includes('ORIGIN_KEYCODE_T: number = 2036'),
  'Harmony keycode 2036 pinned (pa8.G=48=T)');
check(chords.includes('pa8.G = ofk.e(48)') && chords.includes('u64(sbe)'),
  'constant carries pa8.G → u64(sbe) rect-request evidence comment');

// --- 分发支：ctrl+shift 门 + T + UP + 方法调用 + 消费 ---
const tAnchor = 'Ctrl+Shift+pa8.G(48=T)';
const tStart = canvas.indexOf(tAnchor);
check(tStart > 0, 'T branch annotated with f2 pa8.G evidence');
const tBlock = canvas.slice(tStart, tStart + 800);
check(tBlock.includes('ctrl && shift') &&
  tBlock.includes('ORIGIN_KEYCODE_T'), 'branch = ctrl&&shift && T');
check(tBlock.includes('this.applyKeyboardRectSelection()'),
  'Ctrl+Shift+T UP → applyKeyboardRectSelection()');
check(tBlock.includes('return true'), 'consumes DOWN too (无 b2=0)');
// 链序：T 支在 M/I 支前（f2:230→240→244）。
const miIdx = canvas.indexOf('Ctrl+Shift+pa8.D(41=M)/pa8.C(37=I)');
check(miIdx > 0 && tStart < miIdx,
  'T branch precedes M/I branch (f2 chain order 230→240)');
const textEditGate = canvas.indexOf('if (!this.textEditing) {');
check(textEditGate > 0 && textEditGate < tStart,
  'T branch inside !textEditing block (!rsi gate)');

// --- applyKeyboardRectSelection 本体 ---
const fnStart = canvas.indexOf('private applyKeyboardRectSelection()');
check(fnStart > 0, 'applyKeyboardRectSelection defined');
const fn = canvas.slice(fnStart, fnStart + 1600);
check(fn.includes('this.viewport.screenToCanvas(') &&
  fn.includes('this.canvasCtx.width / 2'),
  'viewport center via screenToCanvas (exj.c() equivalent)');
check(fn.includes('c.x - 120') && fn.includes('c.y - 60') &&
  fn.includes('c.x + 120') && fn.includes('c.y + 60'),
  '240×120 rect centered (sbe ±120/±60)');
check(fn.includes('beginSelection(SelectionMode.RECTANGLE'),
  'beginSelection(RECTANGLE) = ome.a() 清选等价（重置 id 集）');
check(fn.includes('this.selectionTool.updateSelection('),
  'updateSelection expands rect to对角点');
check(fn.includes('this.selectionTool.finalizeSelection(') &&
  fn.includes('strokeIntersectsSelectionPath'),
  'finalizeSelection + strokeHit lambda = r3b.c/p3b 同核');
check(fn.includes('this.selectionTool.deselect()') &&
  fn.includes('this.selectionVisible = false'),
  'empty result → deselect + hide overlay');

// --- 可执行模型：f2 门控 + 矩形几何 ---
function tKey(ctrl, shift, code, action, u7b, c5i) {
  // f2:230: r&&s && pa8.G && UP && u7b.g && !U.r
  if (!ctrl || !shift || code !== 'T') return 'pass-through';
  if (action !== 'UP') return 'consumed-noop';
  if (!u7b || c5i) return 'consumed-noop';
  return 'rect-select';
}
check(tKey(true, true, 'T', 'UP', true, false) === 'rect-select',
  'model: Ctrl+Shift+T UP fires rect-select');
check(tKey(true, true, 'T', 'UP', true, true) === 'consumed-noop',
  'model: U.r enabled → gated off (!U.r)');
check(tKey(true, true, 'T', 'DOWN', true, false) === 'consumed-noop',
  'model: DOWN consumed, no action');
check(tKey(true, false, 'T', 'UP', true, false) === 'pass-through',
  'model: Ctrl+T no shift → not this branch');
// 矩形几何：cx±120/cy±60 → 240×120。
function rectGeom(cx, cy) {
  return { left: cx - 120, top: cy - 60, right: cx + 120, bottom: cy + 60 };
}
const r = rectGeom(500, 300);
check(r.left === 380 && r.top === 240 && r.right === 620 && r.bottom === 360,
  'model: viewport-center 500,300 → rect 380,240-620,360');
check(r.right - r.left === 240 && r.bottom - r.top === 120,
  'model: 240×120 canvas units');

console.log(`d02-original-rect-select-key: ${n} checks OK`);
