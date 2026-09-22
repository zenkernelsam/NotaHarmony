// Phase 598 — 套索/矩形完成的最小尺寸门（uw2 case1，20dp/zoom）。
// Original evidence (decompiled_1.0.3/sources/defpackage):
//   uw2.java case1 — 选区手势完成：
//     float fK = i3a.k();                     // zoom
//     float f3 = 20.0f / fK;                  // 最小边长（画布单位）
//     if (Float.compare(cmb.c - cmb.a, f3) <= 0 ||
//         Float.compare(cmb.d - cmb.b, f3) <= 0) {
//       fvbVar.a();                            // 任一边过小 → 取消
//     } else if (z) {
//       fvbVar.b(cmbVarA);                     // 套索提交
//     } else {
//       ... fu1.b 矩形命中 → new ftc(...)      // 矩形提交
//     }
//   —— 20dp/zoom 判定先于 lasso/rect 分支，两种模式同约束；
//      微拖动（约等于点按）不产生选区。
// Harmony：selectionDrawing 收尾分支在 finalizeSelection 之前以
//   SelectionTool.drawnBounds()（矩形=rect、套索=路径 bbox）做
//   任一边 ≤ 20/zoom → deselect() 取消；deselect() 一并清空
//   lassoPoints/rect 绘制残留。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const ROOT = new URL('../../..', import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1');
const read = (p) => readFileSync(`${ROOT}/${p}`, 'utf8');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const tool = read('note/src/main/ets/rendering/SelectionTool.ets');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- 完成分支：最小尺寸门先于 finalizeSelection ---
const finalizeIdx = canvas.indexOf('const ids: string[] = this.selectionTool.finalizeSelection(');
const finish = canvas.slice(canvas.lastIndexOf('} else if (this.selectionDrawing) {', finalizeIdx),
  finalizeIdx + 1400);
check(finish.includes('this.selectionTool.drawnBounds()'),
  'finish probes the drawn bounds before finalize');
check(finish.includes('20.0 / this.viewport.zoom'),
  'minimum size = 20dp/zoom in canvas units (f3 = 20.0f/fK)');
check(finish.indexOf('drawnBounds()') < finish.indexOf('finalizeSelection('),
  'minimum-size gate precedes finalizeSelection');
check(finish.includes('drawnBounds.right - drawnBounds.left <= minSelectionSize') &&
  finish.includes('drawnBounds.bottom - drawnBounds.top <= minSelectionSize'),
  'either dimension below the floor cancels (Float.compare <= 0 parity)');
const cancelBlock = finish.slice(finish.indexOf('minSelectionSize'));
check(cancelBlock.includes('this.selectionTool.deselect();') &&
  cancelBlock.indexOf('this.selectionTool.deselect();') < 400,
  'cancel = deselect (fvbVar.a parity, no selection produced)');
check(cancelBlock.includes('this.selectionVisible = false;'),
  'cancel hides the overlay');

// --- drawnBounds：矩形=rect、套索=路径 bbox（oo3Var.a 等价） ---
const bounds = tool.slice(tool.indexOf('drawnBounds(): Rect2D | null'),
  tool.indexOf('drawnBounds(): Rect2D | null') + 1400);
check(bounds.includes('SelectionMode.RECTANGLE') &&
  bounds.includes('return this.state.rect;'),
  'rectangle mode returns the drawn rect');
check(bounds.includes('this.state.lassoPoints.length === 0') &&
  bounds.includes('return null;'),
  'empty lasso → null bounds');
check(bounds.includes('Math.min(minX, p.x)') && bounds.includes('Math.max(maxX, p.x)') &&
  bounds.includes('Math.min(minY, p.y)') && bounds.includes('Math.max(maxY, p.y)'),
  'lasso bounds = path bbox');

// --- deselect() 清空绘制残留 ---
const deselect = tool.slice(tool.indexOf('deselect(): void'),
  tool.indexOf('deselect(): void') + 700);
check(deselect.includes('this.state.lassoPoints = [];') &&
  deselect.includes('this.state.rect = null;'),
  'deselect clears in-progress draw state');

// --- 可执行模型：尺寸门边界 ---
const zoom = 2;
const minSize = 20.0 / zoom;   // =10 画布单位
const rectOk = { left: 0, top: 0, right: 11, bottom: 11 };
const rectThin = { left: 0, top: 0, right: 11, bottom: 9 };
const tooSmall = (r) =>
  r.right - r.left <= minSize || r.bottom - r.top <= minSize;
assert(!tooSmall(rectOk), 'both dims > floor → proceeds to finalize');
assert(tooSmall(rectThin), 'height 9 ≤ 10 → cancelled');
assert(tooSmall({ left: 0, top: 0, right: 10, bottom: 30 }),
  'width exactly at the floor → cancelled (<= 0)');
n += 3;

console.log(`D02_ORIGINAL_SELECTION_MIN_SIZE_OK TOTAL=${n} FAILED=0`);
