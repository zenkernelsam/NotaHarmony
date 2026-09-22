// Phase 619（经 Phase 621 修正作用域）— 旋转选区命中测试按 yxi.e
// 反旋转触点（ftc/gtc 等价）。
// Original evidence (decompiled_1.0.3/sources/defpackage):
//   yxi.java — e(cmb, j, f, j2)：当 f != 0 时先用 y18.c 把测试点绕
//     矩形中心 j2 旋转 -f，再做 cmb.a 轴对齐矩形包含——选区矩形以
//     未旋转矩形 a() + 旋转角 g() 存储，命中需还原真实旋转四边形。
//   htc.java — a()=未旋转选区矩形；g()=选区旋转角。
//   dl1.java:114/182 — ftc/gtc（htc 实现）分派经 yxi.e(cmb, j, g(),
//     center) 判定"点在选区内"——旋转选区的 AABB 四角区原版判为外部。
//   Phase 621 修正：itc 非 htc——单元素选区不走 yxi.e，dl1:317+
//     用 xtc.a 元素命中测试（本 fixture 只钉 ftc/gtc 的 yxi.e 部分）。
// Harmony 对齐：selectionRect 是已旋转元素的屏幕 AABB（比真实旋转
//   四边形大），pointInRect 会把 AABB 四角误命中。多元素/组选区若
//   全部非笔迹元素共享同一非零 rotationRadians（≈选区壳旋转），
//   逐元素克隆去旋转求未旋转并集→屏幕矩形，触点绕并集中心反旋转
//   -θ 后包含测试；笔迹/旋转不一致退回 AABB。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const VIEW = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const read = (p) => readFileSync(p, 'utf8').replace(/\r\n/g, '\n');
const view = read(VIEW);

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- yxi.e 等价结构：未旋转并集矩形 + 反旋转点测试 ---
const uIdx = view.indexOf('private uniformRotationUnrotatedScreenRect(');
check(uIdx > 0, 'uniformRotationUnrotatedScreenRect present');
const u = view.slice(uIdx, uIdx + 5200);
check(u.includes('selectedStrokeIds.length !== 0'),
  'strokes excluded — rotation baked into points, unrecoverable (conservative AABB)');
check(u.includes('new Set<number>()') && u.includes('radians.size !== 1'),
  'uniform-rotation detection: all carriers must share one rotation value');
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
check(u.includes('Math.min(canvasRect.left, r.left)') &&
  u.includes('Math.max(canvasRect.right, r.right)'),
  'per-element unrotated bounds unioned (fi3.j / ftc.a parity)');
check(u.includes('this.viewport.canvasToScreen(canvasRect.left, canvasRect.top)') &&
  u.includes('this.viewport.canvasToScreen(canvasRect.right, canvasRect.bottom)'),
  'unrotated canvas union converted to screen rect like selectionRect');

// --- 触点反旋转：y18.c(p, -g(), center) 等价 ---
const pIdx = view.indexOf('private pointInSelectionRect(');
check(pIdx > 0, 'pointInSelectionRect present');
const p = view.slice(pIdx, pIdx + 3400);
check(p.includes('Math.cos(-u.radians)') && p.includes('Math.sin(-u.radians)'),
  'point rotated by -rotation (y18.c parity)');
check(p.includes('(u.rect.left + u.rect.right) / 2') &&
  p.includes('(u.rect.top + u.rect.bottom) / 2'),
  'rotation pivot = unrotated-union center (fi3.b(htc.a()))');
check(p.includes('dx * cos - dy * sin') && p.includes('dx * sin + dy * cos'),
  'standard rotation transform applied to the offset');
check(p.includes('this.pointInRect(touch, this.selectionRect)'),
  'non-rotated / mixed-rotation selections fall back to the AABB test');

// --- 全部"点在选区内"检查点走旋转感知路径 ---
const insideSites = view.split('pointInSelectionRect({ x: touch.x, y: touch.y }, canvasP)').length - 1;
check(insideSites === 4,
  `all four touch-inside-selection checks use pointInSelectionRect (got ${insideSites})`);
check(!view.includes('this.pointInRect({ x: touch.x, y: touch.y }, this.selectionRect)'),
  'no raw pointInRect(touch, selectionRect) inside-check remains');

// --- 接口承载 yxi.e 的两个参数（htc.a() 矩形 + g() 角） ---
check(view.includes('interface UnrotatedSelectionRect {') &&
  view.includes('rect: Rect2D;') && view.includes('radians: number;'),
  'UnrotatedSelectionRect carries htc.a() rect + g() radians');

console.log(`D02_ORIGINAL_ROTATED_SELECTION_HIT_TEST_OK TOTAL=${n} FAILED=0`);
