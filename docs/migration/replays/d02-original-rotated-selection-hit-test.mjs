// Phase 619 — 旋转选区命中测试按 yxi.e 反旋转触点（itc 等价）。
// Original evidence (decompiled_1.0.3/sources/defpackage):
//   yxi.java — e(cmb, j, f, j2)：当 f != 0 时先用 y18.c 把测试点绕
//     矩形中心 j2 旋转 -f，再做 cmb.a 轴对齐矩形包含——选区矩形以
//     未旋转矩形 a() + 旋转角 g() 存储，命中需还原真实旋转四边形。
//   htc.java — a()=未旋转选区矩形；g()=选区旋转角（itc 暴露元素
//     rotationRadians 寄存器值）。
//   dl1.java:114/182 — itc/ftc 分派均经 yxi.e(cmb, j, g(), center)
//     判定"点在选区内"——旋转选区的 AABB 四角区原版判为外部。
// Harmony 对齐：selectionRect 是已旋转元素的屏幕 AABB（比真实旋转
//   四边形大），pointInRect 会把 AABB 四角误命中。单旋转元素选区
//   （itc）按同法还原：克隆元素去 rotationRadians 取未旋转
//   bounds→屏幕矩形，触点绕其中心反旋转 -θ 后包含测试；多元素/组
//   选区退回 AABB（ftc 级旋转在 Harmony 模型中无独立寄存器）。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const VIEW = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const read = (p) => readFileSync(p, 'utf8').replace(/\r\n/g, '\n');
const view = read(VIEW);

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- yxi.e 等价结构：未旋转矩形 + 反旋转点测试 ---
const uIdx = view.indexOf('private singleSelectedUnrotatedScreenRect(');
check(uIdx > 0, 'singleSelectedUnrotatedScreenRect present');
const u = view.slice(uIdx, uIdx + 3400);
check(u.includes('selectedGroupIds.length !== 0') && u.includes('!== 1'),
  'scoped to single-element selections (itc) — groups excluded');
check(u.includes('rotationRadians !== 0'),
  'only rotated elements produce an unrotated rect');
check(u.includes('e.type === ElementType.ELLIPSE'),
  'shape branch narrows to ELLIPSE (rotationRadians register carrier)');
check(u.includes('cloneShapeElement(e)') && u.includes('c.rotationRadians = 0') &&
  u.includes('recomputeShapeBounds(c)'),
  'ellipse unrotated bounds via clone + rotationRadians=0 + recomputeShapeBounds');
check(u.includes('cloneTextBlockElement(e)') && u.includes('textBlockWorldBounds(c)'),
  'text-block unrotated bounds via clone + textBlockWorldBounds');
check(u.includes('cloneImageElement(e)') && u.includes('imageBlockWorldBounds(c)'),
  'image unrotated bounds via clone + imageBlockWorldBounds');
check(u.includes('cloneMathElement(e)') && u.includes('mathBlockWorldBounds(c)'),
  'math unrotated bounds via clone + mathBlockWorldBounds');
check(u.includes('this.viewport.canvasToScreen(canvasRect.left, canvasRect.top)') &&
  u.includes('this.viewport.canvasToScreen(canvasRect.right, canvasRect.bottom)'),
  'unrotated canvas bounds converted to screen rect like selectionRect');

// --- 触点反旋转：y18.c(p, -g(), center) 等价 ---
const pIdx = view.indexOf('private pointInSelectionRect(');
check(pIdx > 0, 'pointInSelectionRect present');
const p = view.slice(pIdx, pIdx + 1500);
check(p.includes('Math.cos(-u.radians)') && p.includes('Math.sin(-u.radians)'),
  'point rotated by -rotation (y18.c parity)');
check(p.includes('(u.rect.left + u.rect.right) / 2') &&
  p.includes('(u.rect.top + u.rect.bottom) / 2'),
  'rotation pivot = unrotated-rect center (fi3.b(htc.a()))');
check(p.includes('dx * cos - dy * sin') && p.includes('dx * sin + dy * cos'),
  'standard rotation transform applied to the offset');
check(p.includes('this.pointInRect(touch, this.selectionRect)'),
  'non-rotated / multi selections fall back to the AABB test');

// --- 全部"点在选区内"检查点走旋转感知路径 ---
const insideSites = view.split('pointInSelectionRect({ x: touch.x, y: touch.y })').length - 1;
check(insideSites === 4,
  `all four touch-inside-selection checks use pointInSelectionRect (got ${insideSites})`);
check(!view.includes('this.pointInRect({ x: touch.x, y: touch.y }, this.selectionRect)'),
  'no raw pointInRect(touch, selectionRect) inside-check remains');

// --- 接口承载 yxi.e 的两个参数（htc.a() 矩形 + g() 角） ---
check(view.includes('interface UnrotatedSelectionRect {') &&
  view.includes('rect: Rect2D;') && view.includes('radians: number;'),
  'UnrotatedSelectionRect carries htc.a() rect + g() radians');

console.log(`D02_ORIGINAL_ROTATED_SELECTION_HIT_TEST_OK TOTAL=${n} FAILED=0`);
