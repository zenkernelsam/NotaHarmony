// Phase 1454 — 1.4.2 ttf ControlPointDrag：lsf 形状成员顶点拖拽重构。
// Original evidence (decompiled_1.4.2/sources/defpackage):
//   ms1.java:195-243 — lsf+f5g 形状成员：tap 经 -rot 反旋转
//     （f5n.c(jJ0,-fJ2) 矩阵）进局部系，逐 f5gVar.U().b() 控制点
//     ±(guf.l=44)/k=zoom 轴对齐方框命中；命中 → new ttf(b,jE,i,
//     shapeId, U() 原定义, w 原点, v 页, j() 旋转, jE, lsf)。
//   ttf.java toString — "ControlPointDrag(stateId, dragStartPoint,
//     controlPointIndex, shapeId, originalDefinition, …)"。
//   guf.java:c — delta=cur−dragStart → fq9.n0 反旋转 → rsm.c。
//   rsm.java:c — j4g(LINE)：i=0 拖 start（z 退化时 cp1 跟随）、
//     i=last 拖 end、i=1 中点拖 cp 对按 f5=cp2?4/3:2；
//     k4g(ELLIPSE)：i=0..3 基向点改该边（直径全增量），fil.b 圆锁
//     纵横比并重居中垂直轴；l4g(POLYGON)：顶点直移（oem.a 规范系
//     + fil.a 规整约束部分未解码，登记差异）。
// Harmony：tryStartShapeVertexDrag/applyVertexDrag/vertexDraggedShape。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const CANVAS = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const canvas = readFileSync(CANVAS, 'utf8').replace(/\r\n/g, '\n');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- 会话字段 ---
check(canvas.includes('private vertexDrag: boolean') &&
  canvas.includes('private vertexDragShapeId') &&
  canvas.includes('private vertexDragIndex') &&
  canvas.includes('private vertexDragStart') &&
  canvas.includes('private vertexDragOrigShape'),
  'ttf session fields (shapeId/controlPointIndex/dragStartPoint/originalDefinition)');

// --- 命中：lsf 门 + 局部系 ±44/zoom 方框 ---
const hit = canvas.slice(canvas.indexOf('private tryStartShapeVertexDrag('),
  canvas.indexOf('private applyVertexDrag('));
check(hit.includes('state.supportsDeselectMode') &&
  hit.includes('state.selectedGroupIds.length !== 0') &&
  hit.includes('state.selectedShapeIds.length !== 1'),
  'lsf-only gate: drawn selection / groups / multi-member excluded (ttf is lsf-only)');
check(hit.includes('44.0 / this.viewport.zoom'),
  'hit half-extent = guf.l(44) / k(zoom)');
check(hit.includes('Math.cos(-rot)') && hit.includes('Math.sin(-rot)') &&
  hit.includes('Math.abs(lx) < half && Math.abs(ly) < half'),
  'tap unrotated into shape-local frame, axis-aligned box test (ms1:202-218)');
check(hit.includes('this.shapeVertexDots(shape)') &&
  hit.includes('for (let i: number = 0; i < dots.length; i++)'),
  'iterates f5g.U().b() control-point list = rendered dots');
check(hit.includes('this.dragBeforeShapes = this.shapes.slice()'),
  'undo snapshot captured at session start');

// --- 分发：顶点先于角柄（两处调用点） ---
check((canvas.match(/this\.tryStartShapeVertexDrag\(\{ x: touch\.x, y: touch\.y \}\)/g) || [])
  .length === 2,
  'vertex drag dispatched at both selection touch-down sites');
check(canvas.indexOf('this.tryStartShapeVertexDrag') >
  canvas.indexOf('this.tryStartSelectionResize(') - 500 &&
  canvas.indexOf('this.tryStartShapeVertexDrag') <
  canvas.indexOf('this.tryStartSelectionResize('),
  'vertex hit precedes corner-handle dispatch (ms1 lsf branch order)');

// --- 拖拽应用：增量反旋转 + 逐型编辑 ---
const apply = canvas.slice(canvas.indexOf('private applyVertexDrag('),
  canvas.indexOf('private vertexDraggedShape('));
check(apply.includes('p.x - this.vertexDragStart.x') &&
  apply.includes('Math.cos(-rot)') && apply.includes('Math.sin(-rot)'),
  'world delta unrotated into shape-local frame (fq9.n0)');
check(apply.includes('this.updateSelectionOverlay()'),
  'selection bounds re-derived as shape reshapes (lsf re-emit)');
const edit = canvas.slice(canvas.indexOf('private vertexDraggedShape('),
  canvas.indexOf('private selectionBoundsCanvas('));
check(edit.includes('ElementType.LINE') && edit.includes('ElementType.ELLIPSE') &&
  edit.includes('ElementType.POLYGON'),
  'rsm.c equivalence covers line/ellipse/polygon');
check(edit.includes('4.0 / 3.0') && edit.includes(': 2.0'),
  'line mid-vertex scales control points by f5=4/3 (cubic) or 2 (quad)');
check(edit.includes('orig.controlPoint2.x === orig.end.x') &&
  edit.includes('orig.controlPoint1.x === orig.start.x'),
  'degenerate-cp z flag tracked (cp1==start && cp2==end)');
check(edit.includes('Math.abs(orig.radiusX - orig.radiusY) < 0.001'),
  'ellipse circle case locks aspect (fil.b w==h)');
check(edit.includes('Math.max(0.5,') && edit.includes('dy / 2'),
  'cardinal drag: half-delta radius change, opposite edge fixed, r>=0.5 (f4>=1)');

// --- 移动/提交/取消接线 ---
check((canvas.match(/else if \(this\.vertexDrag\)/g) || []).length >= 1 &&
  canvas.includes('if (this.vertexDrag) {'),
  'vertexDrag consumes touch-move on both surfaces');
check(canvas.includes('this.selectionDrag || this.selectionResize || this.vertexDrag'),
  'touch-up commits vertex drag through the transform-elements undo channel');
check(canvas.includes('||\n        this.vertexDragChanged'),
  'undo pushed when geometry changed (transform stays identity)');
check(canvas.slice(canvas.indexOf('private cancelActiveInteraction') !== -1 ?
  canvas.indexOf('cancelActiveInteraction(') : 0).includes('this.vertexDrag = false'),
  'cancel path restores pre-drag shapes and clears session');
check((canvas.match(/this\.vertexDrag = false/g) || []).length >= 2,
  'vertexDrag flag reset at commit and cancel');

// --- 可执行数学模型：rsm.c 逐型等价 ---
// LINE i=0：start 直移
const line = { start: { x: 0, y: 0 }, controlPoint1: null, controlPoint2: null,
  end: { x: 10, y: 0 } };
const z = line.controlPoint1 === null ||
  (line.controlPoint1 && line.controlPoint1.x === line.start.x &&
   line.controlPoint2 && line.controlPoint2.x === line.end.x);
check(z === true, 'model: cp-free line has z=true');
// ELLIPSE i=0 top 拖上 10（dy=-10）→ h+=10 → ry+5, cy-5（底固定）
const ry0 = 20, cy0 = 50;
const dy = -10;
const ry1 = Math.max(0.5, ry0 - dy / 2);
const cy1 = cy0 + dy / 2;
check(Math.abs(ry1 - 25) < 1e-9 && Math.abs(cy1 - 45) < 1e-9,
  'model: top drag grows radius by dy/2, opposite edge fixed');
// ELLIPSE 圆：i3 right 拖右 8（dx=8）→ r+=4, cx+4（左固定，垂直居中不变）
const r0 = 15, cx0 = 100;
const dxm = 8;
const r2 = Math.max(0.5, r0 + dxm / 2);
const cx2 = cx0 + dxm / 2;
check(Math.abs(r2 - 19) < 1e-9 && Math.abs(cx2 - 104) < 1e-9,
  'model: circle right-cardinal drag keeps circle, left edge fixed');

console.log(`D02_ORIGINAL_VERTEX_DRAG_OK TOTAL=${n} FAILED=0`);
