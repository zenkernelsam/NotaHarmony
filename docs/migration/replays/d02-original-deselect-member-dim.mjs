// Phase 1448 — 1.4.2 hak/oo7 deselectMode 点除成员灰显对齐。
// Original evidence (decompiled_1.4.2/sources/defpackage):
//   kgi.java:101-116 — 页面渲染协程构造 hak 时，
//     set6 = (msfVar instanceof isf && isfVar.h) ? isfVar.i : ∅ → hak.o0。
//   hak.java:572 — set = o0（点除集）；629 — linkedHashSetF0 =
//     y2g.f0(n0, set)（n0 ∪ 点除集）。
//   hak.java:666 — oo7.c(oo7, set9, linkedHashSetF0, ...) → ho7.P。
//   ho7.java:93/179 — x1h/u1h 笔画描述符布尔位 = set.contains(getId())。
//   x1h.java:17/138 — 字段 i；o() 返回 i。
//   oo7.java:201 — x1h 绘制：f6 = o() ? 0.2f : 1.0f → 描边透明度 ×0.2。
//   oo7.java:632-638 — x(paint,...,z,...)：z=true → paint.alpha *= 0.2。
//   jo7.java:110/128/164/179 — 形状（f5g）同构：zContains/zContains2 →
//     v1h/oo7.b 灰显标志。
// Harmony：AlphaScaledDrawingContext 委托 setGlobalAlpha(a*0.2)（等效原版
//   paint alpha 乘法），renderOrderedElements 对 deselectedIds 命中元素换用。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const CANVAS = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const CTX = 'note/src/main/ets/core/adaptation/Canvas2DStrokeRenderer.ets';
const canvas = readFileSync(CANVAS, 'utf8').replace(/\r\n/g, '\n');
const ctx = readFileSync(CTX, 'utf8').replace(/\r\n/g, '\n');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- 委托上下文：setGlobalAlpha 缩放、其余直通 ---
check(ctx.includes('export class AlphaScaledDrawingContext implements Canvas2DDrawingContext'),
  'AlphaScaledDrawingContext implements Canvas2DDrawingContext');
const cls = ctx.slice(ctx.indexOf('export class AlphaScaledDrawingContext'),
  ctx.indexOf('export class Canvas2DStrokeRenderer'));
check(cls.includes('this.inner.setGlobalAlpha(alpha * this.factor)'),
  'setGlobalAlpha multiplies by factor (paint.alpha *= 0.2 parity)');
check((cls.match(/this\.inner\./g) || []).length >= 30,
  'all other Canvas2DDrawingContext methods delegate to inner');
check((cls.match(/setGlobalAlpha/g) || []).length === 2,
  'single setGlobalAlpha: declaration + inner delegate only');

// --- 常量 = 原版 0.2f ---
check(canvas.includes('const DESELECT_MEMBER_ALPHA: number = 0.2'),
  'dim factor = original 0.2f (oo7.x / x1h.o())');

// --- renderOrderedElements 消费 deselectedIds ---
const fn = canvas.slice(canvas.indexOf('private renderOrderedElements('),
  canvas.indexOf('private renderTextOnlyFlow('));
check(fn.includes('this.selectionTool.getState().deselectedIds'),
  'deselectedIds consumed in element render path');
check(fn.includes('deselected.has(element.elementId)'),
  'per-element membership check via elementId');
check(fn.includes('new AlphaScaledDrawingContext(renderContext, DESELECT_MEMBER_ALPHA)'),
  'deselected element rendered through scaled context');
check(fn.includes('dimContext === null') && fn.includes('let dimContext'),
  'dim context lazily allocated once per pass');

// --- 覆盖全部五类元素（原版 isf.i 为叶子 id 集，跨种类一致灰显） ---
check(fn.indexOf('let rc: Canvas2DDrawingContext = renderContext') <
  fn.indexOf('PageElementKind.STROKE'),
  'dimmed context selected before kind dispatch');
for (const kind of ['renderStroke(', 'renderText(', 'renderShape(',
  'renderImage(', 'renderMath(', 'renderAudioLinkedStroke(']) {
  check(fn.includes(kind), `dispatch covers ${kind}`);
}
check(fn.match(/, rc[,\)]/g).length >= 5,
  'all five renderers receive the (possibly dimmed) context');

// --- 生命周期：确认/取消/退出后 deselectedIds 清空 → 灰显解除 ---
const selTool = readFileSync('note/src/main/ets/rendering/SelectionTool.ets', 'utf8')
  .replace(/\r\n/g, '\n');
check((selTool.match(/this\.state\.deselectedIds = \[\]/g) || []).length >= 5,
  'deselectedIds cleared on all lifecycle exits (confirm/cancel/deselect/reset)');

// --- 重绘链：deselectElements 后 renderFrame 触发灰显呈现 ---
check(canvas.indexOf('this.selectionTool.deselectElements(') > 0 &&
  canvas.indexOf('this.renderFrame()', canvas.indexOf('this.selectionTool.deselectElements(')) > 0,
  'renderFrame follows deselectElements in tap dispatch');

console.log(`D02_ORIGINAL_DESELECT_MEMBER_DIM_OK TOTAL=${n} FAILED=0`);
