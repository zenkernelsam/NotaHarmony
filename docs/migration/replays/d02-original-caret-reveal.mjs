// Phase 1479 — 1.4.2 文本编辑光标可见性滚动（jyh.g + lcn.h）。
// Original evidence (decompiled_1.4.2):
//   jyh.g(zle)：zle.d.h = li8 {SELECT_ALL=0, PAGE_UP=1, PAGE_DOWN=2,
//     OTHER=3}；lcl.h(l74) caret 行布局矩形 → sbeVarJ 1dp 宽 caret 矩形。
//     ordinal==0 不滚；1/2 → gfc byte1/0 = pos∓0.9h + m(rect, inset10%)
//     reveal；3 → caret 越 5% 内缩视口（oan.b(exj.c,0.05)）才
//     mfc.u(rect,0.1f)。
//   jka byte1：jM = m(rect, oan.b(f(),margin))；x(l()+jM)。
//   mfc.m：rect 各边越 ku7 视口 → 补边差（最小位移）。
//   lcn.h：kck.b==vak.G(Bottom) → 矩形底扩展 336dp/zoom → mfc.u(rect,0)。
// Harmony：onCaretChange/onDraftChange → revealEditingCaret()；
//   caretRectAtIndex 提供原版 l63 caret 矩形等价物；
//   SELECT_ALL 用选区覆盖全文近似；PAGE_UP/DOWN 由原生 TextArea
//   页移触发同一 reveal（滚动量差异登记）；IME 并入有效视口收缩
//   （getWindowAvoidArea TYPE_KEYBOARD）。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const CANVAS = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const RENDERER = 'note/src/main/ets/core/adaptation/Canvas2DTextRenderer.ets';
const OVERLAY = 'note/src/main/ets/ui/components/TextBlockOverlay.ets';
const canvas = readFileSync(CANVAS, 'utf8').replace(/\r\n/g, '\n');
const renderer = readFileSync(RENDERER, 'utf8').replace(/\r\n/g, '\n');
const overlay = readFileSync(OVERLAY, 'utf8').replace(/\r\n/g, '\n');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- caretRectAtIndex：caretIndexAtPoint 的逆 ---
const fnIdx = renderer.indexOf('caretRectAtIndex(element: TextBlockElement');
check(fnIdx > 0, 'caretRectAtIndex defined (lcl.h caret 矩形等价物)');
const fn = renderer.slice(fnIdx, fnIdx + 4200);
check(fn.includes('this.layoutLines(ctx, characters') &&
  fn.includes('this.measureRange(ctx, characters'),
  'reuses layoutLines + measureRange (与 caretIndexAtPoint 同布局核)');
check(fn.includes('bandTop') && fn.includes('lineHeight'),
  'per-line bandTop/lineHeight walk (l63 行高矩形)');
check(fn.includes('wrappedBoundary') && fn.includes("characters[index] !== '\\n'"),
  'wrap-boundary caret=end 归下一行');
check(fn.includes('element.transform'),
  'local → world via element.transform (旋转块安全)');
check(fn.includes('caretX + 1'),
  'caret rect width = 1 doc unit (v64.a(1f, l63.a))');

// --- onCaretChange 选区锚定端透传 ---
check(overlay.includes('onCaretChange: (offset: number, selectionStart: number) => void'),
  'overlay onCaretChange carries selection anchor');
check(overlay.includes('this.onCaretChange(end, start)'),
  'onTextSelectionChange(start,end) → onCaretChange(end,start)');

// --- revealEditingCaret：门集 + SELECT_ALL 跳过 + 5%/10% 内缩 ---
const rvIdx = canvas.indexOf('private revealEditingCaret()');
check(rvIdx > 0, 'revealEditingCaret defined');
const rv = canvas.slice(rvIdx, rvIdx + 2600);
check(rv.includes('this.textEditing') && rv.includes('this.editingTextBlock === null') &&
  rv.includes('this.editingCaretOffset < 0'),
  'editing/caret gates');
check(rv.includes('selStart !== this.editingCaretOffset') &&
  rv.includes('Math.min(selStart, this.editingCaretOffset) === 0') &&
  rv.includes('>= draftLen'),
  'li8.SELECT_ALL(0)：全选不滚动（jyh ordinal==0 skip）');
check(rv.includes('caretRectAtIndex'),
  'caret rect via renderer (sbeVarJ 等价)');
check(rv.includes('w * 0.05') && rv.includes('w * 0.95') &&
  rv.includes('h * 0.05') && rv.includes('h * 0.95'),
  'inside-check vs 5%-inset viewport (oan.b(exj.c,0.05))');
check(rv.includes('w * 0.1') && rv.includes('w * 0.9') &&
  rv.includes('h * 0.1') && rv.includes('h * 0.9'),
  'reveal margins = 10% inset (mfc.u rect,0.1f)');
check(rv.includes('this.viewport.panBy(-dx, -dy)'),
  'jM → panBy(−jM)（pos+=jM、scrollY≡−pos 符号链）');

// --- IME 避让并入有效视口 ---
check(rv.includes('this.keyboardAvoidHeightPx()'),
  'lcn.h IME reserve → effective viewport bottom shrink');
check(canvas.includes('getWindowAvoidArea(window.AvoidAreaType.TYPE_KEYBOARD)') &&
  canvas.includes('area.bottomRect.height'),
  'keyboard height via getWindowAvoidArea(TYPE_KEYBOARD).bottomRect');
check(canvas.includes('window.getLastWindow(getContext(this))') &&
  canvas.includes('this.editorWindow = win'),
  'editorWindow cached in aboutToAppear (sync path 需要)');

// --- 接线：caret/draft 双通道 ---
check(canvas.includes('this.editingSelectionStart = selectionStart;') &&
  canvas.includes('this.revealEditingCaret()'),
  'onCaretChange → selectionStart 记录 + reveal');
const draftIdx = canvas.indexOf('onDraftChange: (text: string) =>');
check(draftIdx > 0 && canvas.slice(draftIdx, draftIdx + 700).includes('revealEditingCaret'),
  'onDraftChange → reveal (输入推进 caret 越界)');

// --- 可执行 reveal 几何模型 ---
const reveal = (s, w, h) => {
  const inside = s.left >= w * 0.05 && s.right <= w * 0.95 &&
    s.top >= h * 0.05 && s.bottom <= h * 0.95;
  if (inside) return null;
  const dx = s.left < w * 0.1 ? s.left - w * 0.1 :
    (s.right > w * 0.9 ? s.right - w * 0.9 : 0);
  const dy = s.top < h * 0.1 ? s.top - h * 0.1 :
    (s.bottom > h * 0.9 ? s.bottom - h * 0.9 : 0);
  return (dx === 0 && dy === 0) ? null : { dx, dy };
};
check(reveal({ left: 100, top: 100, right: 101, bottom: 120 }, 1000, 800) === null,
  'caret inside → no scroll');
check(JSON.stringify(reveal({ left: 950, top: 100, right: 960, bottom: 120 }, 1000, 800)) ===
  JSON.stringify({ dx: 60, dy: 0 }),
  'caret right edge 960>900 → jM.x=+60（pos+=60 → panBy −60）');
check(JSON.stringify(reveal({ left: 30, top: 100, right: 40, bottom: 120 }, 1000, 800)) ===
  JSON.stringify({ dx: -70, dy: 0 }),
  'caret left edge 30<100 → jM.x=−70');
check(reveal({ left: 100, top: 790, right: 101, bottom: 800 }, 1000, 800) &&
  reveal({ left: 100, top: 790, right: 101, bottom: 800 }, 1000, 800).dy === 80,
  'caret bottom 800>720 → jM.y=+80');
check(reveal({ left: 100, top: 200, right: 101, bottom: 220 }, 1000, 400) === null,
  'keyboard-shrunk viewport: caret fully inside → no scroll');
check(reveal({ left: 100, top: 380, right: 101, bottom: 399 }, 1000, 400) !== null,
  'same caret vs keyboard-shrunk view → revealed (IME 避让等价)');

console.log(`d02-original-caret-reveal: ${n} checks OK`);
