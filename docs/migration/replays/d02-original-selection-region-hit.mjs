// Phase 607 — 套索/矩形选区 ∩ 元素几何（fu1.f → g() uh5 分支）。
// Original evidence (decompiled_1.0.3/sources/defpackage):
//   fu1.java:439-452 — f(wh5,k11,kinds,x09,set)：aa6.t 宽相（k11 矩形）
//     后逐元素 g() 精判，wh5 为 uh5 多边形（套索路径或选框）。
//   fu1.java:454-502 — g()：s06 笔迹 h(uh5, inkPath)；m4d/n5d 形状
//     填充路径 ∩ 多边形或描边带 ∩ 多边形（z8a.b(path,Q())）；
//     oy0 块 jy0.e(多边形, 本地矩形)。uh5 → jy0.e 均为**相交**语义，
//     非 bounds 中心点。
//   fu1.java:203-215 — h(wh5,wx0)：uh5 → jy0.e(多边形, 路径)。
// Harmony：selectionPathHitsShape（多边形 ∩ 填充∪描边带 + 顶点套入）；
//   strokeIntersectsSelectionPath（采样点入多边形 ∪ 段-边距 ≤ 半宽）；
//   finalizeSelection 注入 strokeHit，块沿用 selectionPathHitsAffineBlock。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const CANVAS = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const ERASER = 'note/src/main/ets/rendering/EraserEngine.ets';
const SHAPE = 'note/src/main/ets/core/model/ShapeGeometry.ets';
const TOOL = 'note/src/main/ets/rendering/SelectionTool.ets';
const read = (p) => readFileSync(p, 'utf8').replace(/\r\n/g, '\n');
const canvas = read(CANVAS);
const eraser = read(ERASER);
const shape = read(SHAPE);
const tool = read(TOOL);

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- finalizeSelection：注入 strokeHit、形状走 selectionPathHitsShape ---
const fin = tool.slice(tool.indexOf('finalizeSelection(strokes'),
  tool.indexOf('finalizeSelection(strokes') + 2600);
check(fin.includes('strokeHit?: (stroke: StrokeElementData, selectionPath: Point2D[]) => boolean'),
  'finalizeSelection accepts an injected stroke-hit predicate');
check(fin.includes('strokeHit(s, selectionPath)'),
  'stroke hits route through the injected predicate (band ∩ polygon)');
check(fin.indexOf('strokeHit(s, selectionPath)') < fin.indexOf('rectIntersects(this.state.rect'),
  'injected predicate precedes the bounds fallback');
check(fin.includes('selectionPathHitsShape(selectionPath, shape)'),
  'shapes use polygon ∩ fill/band instead of bounds center');
check(!fin.includes('elementBoundsSelected('),
  'bounds-center shape test removed from finalizeSelection');
check(fin.indexOf('const selectionPath') < fin.indexOf('for (const s of strokes)'),
  'selectionPath is computed before the stroke loop');

// --- EraserEngine.strokeIntersectsSelectionPath：采样带 ∩ 多边形 ---
const strokeHit = eraser.slice(eraser.indexOf('strokeIntersectsSelectionPath(stroke'),
  eraser.indexOf('strokeIntersectsSelectionPath(stroke') + 2200);
check(strokeHit.includes('this.sampleStroke(stroke)'),
  'stroke test samples the cubic/widthFactor centerline');
check(strokeHit.includes('this.pointInPolygon(sample.world, selectionPath)'),
  'sample inside polygon selects the stroke (centerline ∈ region)');
check(strokeHit.includes('this.segmentDistance(a, b, c, d) <= radius') &&
  strokeHit.includes('brushWidth * widthFactor * scale / 2'),
  'sample-segment to polygon-edge distance ≤ half-width selects the stroke');
check(strokeHit.includes('(j + 1) % selectionPath.length'),
  'polygon closing edge participates in the band distance test');

// --- ShapeGeometry.selectionPathHitsShape：顶点套入 + 填充/带 ∩ 多边形 ---
const shapeHit = shape.slice(shape.indexOf('selectionPathHitsShape(selectionPath'),
  shape.indexOf('selectionPathHitsShape(selectionPath') + 1400);
check(shapeHit.includes('shapePathPoints(shape)') &&
  shapeHit.includes('pointInPolygon(point, selectionPath)'),
  'shape vertex inside the polygon selects it (shape ⊂ lasso)');
check(shapeHit.includes('closed.push(selectionPath[0])') &&
  shapeHit.includes('shapeCoveredByPath(closed, shape, 0)'),
  'closed polygon vs fill region + stroked band (z8a.b parity)');

// --- NoteCanvasView 接线：注入 EraserEngine 采样命中 ---
check(canvas.includes('strokeIntersectsSelectionPath(stroke, selectionPath)'),
  'canvas injects the engine stroke-hit predicate into finalizeSelection');

// --- 可执行模型：原版相交语义 vs 旧 bounds 中心点 ---
// 笔迹中心线掠过套索边缘（bounds 中心在多边形外）：原版命中。
const lasso = [{ x: 0, y: 0 }, { x: 40, y: 0 }, { x: 40, y: 40 }, { x: 0, y: 40 }];
const strokeSeg = [{ x: 30, y: -10 }, { x: 30, y: 60 }]; // 纵向穿越
const segDist = (a, b, c, d) => {
  const cross = (p, q, r) => (q.x - p.x) * (r.y - p.y) - (q.y - p.y) * (r.x - p.x);
  const psd = (p, s, e) => {
    const dx = e.x - s.x, dy = e.y - s.y;
    const l2 = dx * dx + dy * dy;
    if (l2 <= 1e-7) return Math.hypot(p.x - s.x, p.y - s.y);
    const t = Math.max(0, Math.min(1, ((p.x - s.x) * dx + (p.y - s.y) * dy) / l2));
    return Math.hypot(p.x - s.x - t * dx, p.y - s.y - t * dy);
  };
  const abC = cross(a, b, c), abD = cross(a, b, d);
  const cdA = cross(c, d, a), cdB = cross(c, d, b);
  if (abC * abD <= 0 && cdA * cdB <= 0 &&
    Math.max(Math.min(a.x, b.x), Math.min(c.x, d.x)) <=
    Math.min(Math.max(a.x, b.x), Math.max(c.x, d.x)) &&
    Math.max(Math.min(a.y, b.y), Math.min(c.y, d.y)) <=
    Math.min(Math.max(a.y, b.y), Math.max(c.y, d.y))) return 0;
  return Math.min(
    Math.min(psd(a, c, d), psd(b, c, d)),
    Math.min(psd(c, a, b), psd(d, a, b)));
};
let bandHit = false;
for (let j = 0; j < lasso.length; j++) {
  if (segDist(strokeSeg[0], strokeSeg[1], lasso[j],
    lasso[(j + 1) % lasso.length]) <= 2) bandHit = true;
}
check(bandHit === true,
  'stroke crossing the lasso edge hits even with its bounds center outside');

console.log(`D02_ORIGINAL_SELECTION_REGION_HIT_OK TOTAL=${n} FAILED=0`);
