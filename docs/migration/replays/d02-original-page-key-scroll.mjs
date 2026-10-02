// Phase 1470 — 1.4.2 PageUp/PageDown 视口翻页滚动（f2 兜底链 → mfc.s/ad8）。
// Original evidence (decompiled_1.4.2):
//   f2.java:40-60 — pa8.a0 = ofk.e(92) = KEYCODE_PAGE_UP；
//     pa8.b0 = ofk.e(93) = KEYCODE_PAGE_DOWN。
//   f2.java:253-262 — !rsi 门内兜底链：pa8.a(n,a0)/pa8.a(n,b0) 支——
//     无修饰键门；lxm.a(o,1)=UP → mfc.s(mfc.j()) / mfc.s(mfc.i())；
//     DOWN 同样消费（支内无 b2=0 落点）。
//   mfc.java:347-353 — i()=ndf(0,+(int)(g()&0xFFFFFFFF)*0.9f)、
//     j()=ndf(0,−…*0.9f)；g()=p()−insets 视口内容尺寸——
//     滚动量 = ±90% 视口高（x 分量恒 0）。
//   mfc.s → ad8(byte1) 协程：mfc.x(l()+j) 目标位滚动（动画路径）。
// Harmony：onCanvasKeyEvent !textEditing 块内增 PAGE_UP/DOWN 支，
//   UP → setScroll(scrollY∓0.9×canvasHeight) + onViewportChanged；
//   DOWN 消费不动作（return true）。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const CANVAS = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const CHORDS = 'note/src/main/ets/data/OriginalKeyboardChords.ets';
const canvas = readFileSync(CANVAS, 'utf8').replace(/\r\n/g, '\n');
const chords = readFileSync(CHORDS, 'utf8').replace(/\r\n/g, '\n');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- 常量：PAGE_UP/DOWN 键码 + 0.9 翻页比 ---
check(chords.includes('ORIGIN_KEYCODE_PAGE_UP: number = 2068') &&
  chords.includes('ORIGIN_KEYCODE_PAGE_DOWN: number = 2069'),
  'Harmony keycodes 2068/2069 pinned (pa8.a0=92 / pa8.b0=93)');
check(chords.includes('ORIGIN_KEY_PAGE_SCROLL_FRACTION: number = 0.9'),
  'mfc.i()/j() = ±0.9f×视口高 fraction pinned');
check(chords.includes('pa8.a0 = ofk.e(92)') && chords.includes('pa8.b0 = ofk.e(93)'),
  'constants carry original ofk.e evidence comment');

// --- 分发支：键码匹配 + UP 动作门 + 双向滚动 ---
const anchor = 'pa8.a0(92=PAGE_UP)/pa8.b0(93=PAGE_DOWN)';
const start = canvas.indexOf(anchor);
check(start > 0, 'dispatch branch annotated with f2 pa8.a0/b0 evidence');
const block = canvas.slice(start, start + 1100);
check(block.includes('event.keyCode === ORIGIN_KEYCODE_PAGE_UP') &&
  block.includes('event.keyCode === ORIGIN_KEYCODE_PAGE_DOWN'),
  'PAGE_UP and PAGE_DOWN both intercepted');
check(block.includes('if (isUp)'),
  'action gated to UP (lxm.a(o,1) 等价)');
check(block.includes('ORIGIN_KEY_PAGE_SCROLL_FRACTION') &&
  block.includes('this.canvasCtx.height'),
  'step = 0.9 × viewport height (mfc.g() 视口尺寸等价)');
check(block.includes('this.viewport.setScroll(this.viewport.scrollX'),
  'scroll preserves x, only y moves (ndf(0,±…) x 分量恒 0)');
check(block.includes("ORIGIN_KEYCODE_PAGE_UP ? -pageStep : pageStep"),
  'PAGE_UP → −0.9h (mfc.j()) / PAGE_DOWN → +0.9h (mfc.i())');
check(block.includes('this.onViewportChanged()'),
  'viewport change notified after scroll (mfc.x 渲染等价)');
check(block.includes('return true'),
  'DOWN also consumed (f2 支内无 b2=0 落点)');
// 无修饰键门
const cond = block.slice(block.indexOf('if (event.keyCode'),
  block.indexOf('if (event.keyCode') + 200);
check(!cond.includes('ctrl') && !cond.includes('shift') &&
  !cond.includes('keyChordAlt'),
  'no modifier gate on page scroll keys (f2 支无 db8.r/s)');

// --- 位置：!textEditing 门内、DEL 支之后 ---
const delIdx = canvas.indexOf('pa8.O(67=DEL)');
check(delIdx > 0 && start > delIdx,
  'page-scroll branch follows DEL branch (f2 链序 a0/b0 在 O/P 后)');
const textEditGate = canvas.indexOf('if (!this.textEditing) {');
check(textEditGate > 0 && textEditGate < start,
  'page-scroll branch inside !textEditing block (!rsi 门)');

// --- 可执行模型：mfc.j()/i() 语义 ---
function pageScroll(scrollY, viewportH, key) {
  // mfc.j()=ndf(0,−0.9h) → PAGE_UP；mfc.i()=ndf(0,+0.9h) → PAGE_DOWN
  const delta = key === 'PAGE_UP' ? -0.9 * viewportH : 0.9 * viewportH;
  return scrollY + delta;
}
check(pageScroll(1000, 800, 'PAGE_UP') === 1000 - 720,
  'model: PAGE_UP scrolls up 0.9×viewportH');
check(pageScroll(1000, 800, 'PAGE_DOWN') === 1000 + 720,
  'model: PAGE_DOWN scrolls down 0.9×viewportH');
check(pageScroll(500, 0, 'PAGE_DOWN') === 500,
  'model: zero-height viewport → no-op (g()=0 边界)');

console.log(`d02-original-page-key-scroll: ${n} checks OK`);
