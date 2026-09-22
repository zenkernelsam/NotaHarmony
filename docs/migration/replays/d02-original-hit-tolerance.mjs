// Phase 606 — 元素命中两程 ±5 容差（fu1.e → xtc.a 点按探测）。
// Original evidence (decompiled_1.0.3/sources/defpackage):
//   fu1.java:270-295 — e(j,x09,set)：先 f(vh5(j), k11(点)) 精确命中；
//     落空则 k11(j±5) 区域 + vh5(j,5) 半径圆复测，o1 取 z 序最上。
//   fu1.java:454-505 — g(vnd,wh5,x09)：oy0 块按本地半长 +fB 扩张；
//     m4d 形状走 z8a.b(path,Q()) 描边带 + 圆交；笔迹/形状以查询
//     圆距路径 ≤5 命中。
//   fu1.java:244 — j() 将查询半径按元素缩放归一（b()/max(d,c)）：
//     ±5 为世界/page 单位，元素本地容差 = 5/scale。
//   xtc.java:39-74 — b(j) 经 a(j,null) 门控（顶层命中须为 tape/I.k()），
//     收集 fu1.f(vh5(j) 精确)；setX1 空 → 回退 otcVar 顶层 id 单例。
// Harmony：topmostPageElementIdAt 两程（exact→tol5）；tapeIdsAtPoint
//   精确收集空 → 回退两程顶层 tape 单例。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const CANVAS = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const ERASER = 'note/src/main/ets/rendering/EraserEngine.ets';
const SHAPE = 'note/src/main/ets/core/model/ShapeGeometry.ets';
const read = (p) => readFileSync(p, 'utf8').replace(/\r\n/g, '\n');
const canvas = read(CANVAS);
const eraser = read(ERASER);
const shape = read(SHAPE);

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- topmostPageElementIdAt：exact → ±5 两程 ---
const topmost = canvas.slice(canvas.indexOf('private topmostPageElementIdAt('),
  canvas.indexOf('private topmostPageElementIdAt(') + 2600);
check(topmost.includes('hitOrderedElementIdAt(ordered, point, 0)') &&
  topmost.includes('hitOrderedElementIdAt(ordered, point, 5)'),
  'two-phase exact-then-5 tolerance dispatch (fu1.e parity)');
check(topmost.indexOf('hitOrderedElementIdAt(ordered, point, 0)') <
  topmost.indexOf('hitOrderedElementIdAt(ordered, point, 5)'),
  'exact pass precedes the tolerance pass');
check(topmost.includes('hitStrokeAtPoint(point, element.data, worldTolerance)'),
  'stroke hit carries the tolerance through');
check(topmost.includes('pointHitsShape(point, element.data, worldTolerance)'),
  'shape hit carries the tolerance through');
check(topmost.includes('this.expandLocalBounds(textBlockLocalBounds(element.data),\n            worldTolerance, element.data.transform)') &&
  topmost.includes('this.expandLocalBounds(imageBlockLocalBounds(element.data),\n            worldTolerance, element.data.transform)') &&
  topmost.includes('this.expandLocalBounds(mathBlockLocalBounds(element.data),\n            worldTolerance, element.data.transform)'),
  'all three block kinds expand local bounds by the tolerance');
const expand = canvas.slice(canvas.indexOf('private expandLocalBounds('),
  canvas.indexOf('private expandLocalBounds(') + 700);
check(expand.includes('worldTolerance / scale'),
  'block expansion normalizes world tolerance by element scale (j() b()/maxScale parity)');
check(expand.includes('bounds.left - local') &&
  expand.includes('bounds.right + local') &&
  expand.includes('bounds.bottom + local'),
  'local bounds inflate on all four sides (gi3+fB parity)');

// --- 各类命中函数的世界单位容差（fu1.j: b()/maxScale 归一） ---
const strokeHit = eraser.slice(eraser.indexOf('hitStrokeAtPoint('),
  eraser.indexOf('hitStrokeAtPoint(') + 1400);
check(strokeHit.includes('worldTolerance: number = 0') &&
  strokeHit.includes('stroke.renderSpec.brushWidth * widthFactor * scale / 2 +\n        worldTolerance'),
  'stroke radius adds world tolerance after the transform scale');
const shapeHit = shape.slice(shape.indexOf('pointHitsShape('),
  shape.indexOf('pointHitsShape(') + 200);
check(shapeHit.includes('worldTolerance: number = 0'),
  'pointHitsShape exposes the tolerance parameter');
check(shape.includes('shape.strokeWidth * scale / 2 +\n    worldTolerance'),
  'shape radius adds world tolerance after the transform scale');

// --- tapeIdsAtPoint：精确收集 → 回退顶层 tape 单例 ---
const tape = canvas.slice(canvas.indexOf('private tapeIdsAtPoint('),
  canvas.indexOf('private tapeIdsAtPoint(') + 2200);
check(tape.indexOf('hitStrokeAtPoint(point, stroke)') > 0 &&
  tape.indexOf('hitStrokeAtPoint(point, stroke)') < tape.indexOf('topmostPageElementIdAt'),
  'exact tape collection precedes the tolerance fallback');
check(tape.includes('this.isTapeElementId(topId)'),
  'fallback keeps only when the two-phase topmost is tape (I.k gate)');
check(canvas.indexOf('private isTapeElementId(') > 0,
  'isTapeElementId helper for the gate fallback');

console.log(`D02_ORIGINAL_HIT_TOLERANCE_OK TOTAL=${n} FAILED=0`);
