// Phase 1473 — 1.4.2 Alt 井选择键（f2:264-276 → hxi.a → qxi case0：
// bxi 色井 / dxi 宽度井 / exi 色井步进）。
// Original evidence (decompiled_1.4.2):
//   bd8.java:44 — i0 = oag.y2(pa8.k..s) = ofk.e(8..16) = KEYCODE_1..9。
//   pa8.java:161-162 — X = ofk.e(71) = LEFT_BRACKET、
//     Y = ofk.e(72) = RIGHT_BRACKET。
//   f2.java:264-276（!rsi 门内、!pa8.W 块内、PAGE_DOWN 支后、
//     媒体支前）：
//     `q && !r && !s && i0.contains(n)` → UP 推 bxi(indexOf)；
//     `q && !r && s && i0.contains(n)` → UP 推 dxi(indexOf)；
//     `q && !r && pa8.a(n,X)` → UP 推 exi(-1)（shift 不判）；
//     `q && !r && pa8.a(n,Y)` → UP 推 exi(+1)；
//     三支内无 b2=0 → DOWN/命中即消费。
//   qxi.java case0 —— bxi：e52.s3(index, jyi.B()) → jyi.A(x25)；
//     jyi.B() = x25 列表按 a6n.c(type) 过滤 + ttb 排序；
//     dxi：s2k 列表同型过滤排序 → k31.Y(wsi, r2k(d,c)) → jyi.F；
//     exi：i2 = indexOf(x25.d == 当前 g92.b)，缺失 0 基，
//     (i2+delta) floorMod size 回卷 → jyi.A。
// Harmony：onCanvasKeyEvent !textEditing 块内（PAGE_DOWN 支后、
//   媒体支前——对齐 f2 链序）；NotePage →
//   viewModel.selectFavoriteColor/selectWidthWell/stepFavoriteColor
//   （favoriteColors/widthWells 已按 activeToolType 载入 = jyi.B()/
//   s2k 过滤等价）。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const CANVAS = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const CHORDS = 'note/src/main/ets/data/OriginalKeyboardChords.ets';
const PAGE = 'note/src/main/ets/ui/editor/NotePage.ets';
const VM = 'note/src/main/ets/ui/editor/EditorViewModel.ets';
const canvas = readFileSync(CANVAS, 'utf8').replace(/\r\n/g, '\n');
const chords = readFileSync(CHORDS, 'utf8').replace(/\r\n/g, '\n');
const page = readFileSync(PAGE, 'utf8').replace(/\r\n/g, '\n');
const vm = readFileSync(VM, 'utf8').replace(/\r\n/g, '\n');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- 常量：方括号键码 + Alt digit helper ---
check(chords.includes('ORIGIN_KEYCODE_LEFT_BRACKET: number = 2059') &&
  chords.includes('ORIGIN_KEYCODE_RIGHT_BRACKET: number = 2060'),
  'Harmony keycodes 2059/2060 pinned (pa8.X=71 / pa8.Y=72)');
check(chords.includes('pa8.X = ofk.e(71)') && chords.includes('bxi') &&
  chords.includes('dxi') && chords.includes('exi'),
  'constants carry bxi/dxi/exi evidence comments');
const helperIdx = chords.indexOf('export function altWellDigitIndex');
check(helperIdx > 0, 'altWellDigitIndex helper present');
const helper = chords.slice(helperIdx, helperIdx + 400);
check(helper.includes('!keyChordAlt(event) || keyChordCtrl(event)'),
  'alt&&!ctrl gate (f2: q&&!r 两支共核)');
check(helper.includes('ORIGIN_TOOL_SELECT_DIGIT_BASE'),
  'digit index shares bd8.i0 base (pa8.k..s = 1..9)');

// --- 分发支：位置 + 门控 + 回调 ---
// 锚定分发代码本身（prop 注释块亦含 'f2:264-276' 字样）。
const altAnchor = 'const altDigit: number = altWellDigitIndex(event)';
const altStart = canvas.indexOf(altAnchor);
check(altStart > 0, 'alt digit dispatch branch present');
check(canvas.slice(Math.max(0, altStart - 400), altStart)
    .includes('f2:264-276 兜底链 Alt 支'),
  'alt branch block annotated with f2 evidence');
const altBlock = canvas.slice(altStart, altStart + 1400);
check(altBlock.includes('const altDigit: number = altWellDigitIndex(event)') &&
  altBlock.includes('if (altDigit >= 0)'),
  'alt digit branch uses shared helper');
check(altBlock.includes('this.onKeySelectWidthWell(altDigit)') &&
  altBlock.includes('this.onKeySelectColorWell(altDigit)'),
  'shift split: dxi width-well vs bxi color-well (f2 q&&!r&&s / q&&!r&&!s)');
check(altBlock.includes('keyChordAlt(event) && !ctrl') &&
  altBlock.includes('ORIGIN_KEYCODE_LEFT_BRACKET') &&
  altBlock.includes('ORIGIN_KEYCODE_RIGHT_BRACKET'),
  'alt+bracket branch (exi): alt&&!ctrl, shift not excluded');
check(altBlock.includes('ORIGIN_KEYCODE_LEFT_BRACKET ? -1 : 1'),
  'exi direction: [ → -1, ] → +1 (f2:271/275)');
check(altBlock.split('return true').length >= 3,
  'both alt branches consume unconditionally (支内无 b2=0)');
// 位置：PAGE_DOWN 支之后、媒体支之前（f2 链序 264→277）。
const pageDnIdx = canvas.indexOf('ORIGIN_KEYCODE_PAGE_UP ||');
const mediaIdx = canvas.indexOf('q5d.k.i()/h()');
check(pageDnIdx > 0 && altStart > pageDnIdx && mediaIdx > altStart,
  'alt branches between PAGE_DOWN and media branches (f2 chain order)');
const textEditGate = canvas.indexOf('if (!this.textEditing) {');
check(textEditGate > 0 && textEditGate < altStart,
  'alt branches inside !textEditing block (!rsi gate)');

// --- NotePage 接线 ---
check(page.includes('onKeySelectColorWell: (index: number): void') &&
  page.includes('this.viewModel.selectFavoriteColor(index)'),
  'bxi → selectFavoriteColor(index) (e52.s3 + jyi.A)');
check(page.includes('onKeySelectWidthWell: (index: number): void') &&
  page.includes('this.viewModel.selectWidthWell(index)'),
  'dxi → selectWidthWell(index) (s2k 列表 → jyi.F)');
check(page.includes('onKeyStepColorWell: (delta: number): void') &&
  page.includes('this.viewModel.stepFavoriteColor(delta)'),
  'exi → stepFavoriteColor(delta)');

// --- VM 语义 pin ---
check(vm.includes('async selectFavoriteColor(index: number)') &&
  vm.includes('this.favoriteColors[index]'),
  'selectFavoriteColor = index 直取 favoriteColors（jyi.B() 等价）');
check(vm.includes('async selectWidthWell(index: number)') &&
  vm.includes('this.widthWells[index]'),
  'selectWidthWell = index 直取 widthWells（s2k 过滤列表等价）');
const stepIdx = vm.indexOf('async stepFavoriteColor');
check(stepIdx > 0, 'stepFavoriteColor present');
const step = vm.slice(stepIdx, stepIdx + 700);
check(step.includes('wells.indexOf(this.brushColor)'),
  'step locates current well by color value (x25.d == g92.b, 非存序)');
check(step.includes('idx >= 0 ? idx : 0'),
  'missing current color → base 0 (qxi: i2>=0?i2:0)');
check(step.includes('((base + delta) % size + size) % size'),
  'floorMod wrap (qxi: i4%size 负数校正)');
check(step.includes('wells.length === 0'),
  'empty list → no-op (qxi: listB.isEmpty() return)');

// --- 可执行模型：f2 门控 ---
function altDigit(alt, ctrl, shift, isDigit, action) {
  // f2:264-268 —— q&&!r 且 digit 才命中；shift 分流 bxi/dxi；UP 动作。
  if (!alt || ctrl || !isDigit) return 'pass-through';
  if (action !== 'UP') return 'consumed-noop';
  return shift ? 'width-well' : 'color-well';
}
check(altDigit(true, false, false, true, 'UP') === 'color-well',
  'model: Alt+digit UP → bxi color well');
check(altDigit(true, false, true, true, 'UP') === 'width-well',
  'model: Alt+Shift+digit UP → dxi width well');
check(altDigit(true, false, false, true, 'DOWN') === 'consumed-noop',
  'model: DOWN consumed, no action');
check(altDigit(true, true, false, true, 'UP') === 'pass-through',
  'model: Ctrl+Alt+digit → branch not entered (!db8.r)');
check(altDigit(false, false, false, true, 'UP') === 'pass-through',
  'model: bare digit → not this branch');
function stepColor(colors, current, delta) {
  if (colors.length === 0) return null;
  const idx = colors.indexOf(current);
  const base = idx >= 0 ? idx : 0;
  return colors[((base + delta) % colors.length + colors.length) % colors.length];
}
check(stepColor([0xFF0000, 0x00FF00, 0x0000FF], 0xFF0000, 1) === 0x00FF00,
  'model: exi(+1) steps to next color well');
check(stepColor([0xFF0000, 0x00FF00, 0x0000FF], 0xFF0000, -1) === 0x0000FF,
  'model: exi(-1) wraps to last color well');
check(stepColor([0xFF0000, 0x00FF00, 0x0000FF], 0xFFFFFF, 1) === 0x00FF00,
  'model: current color absent → base 0 then step');
check(stepColor([], 0xFF0000, 1) === null,
  'model: empty wells → no-op');

console.log(`d02-original-alt-well-keys: ${n} checks OK`);
