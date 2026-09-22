// Phase 590 — selection-tool outside-press TapToSelect / ClearSelection
// (原版 vtc / rtc parity)，并修正 Phase 589 对 stc/ej9 case18 的误读。
// Original evidence (decompiled_1.0.3/sources/defpackage):
//   dl1.java:208-230 — ftc.h=false（常态，非 deselectMode）pointer-down：
//     yxi.e(cmb,…) 覆盖层内 → wtc → e39 整体拖拽；
//     覆盖层外 → xtc.a(jE,null) 命中 → vtc TapToSelect；未命中 →
//     rtc → ct0 ClearSelection。
//   ftc.java:181-188 — ftc.h = deselectMode、ftc.i = deselectedIds；
//     stc/ej9 case18 是 deselect 模式的点按移除语义（dhb case20 由菜单
//     动作置位），不是"抓取移动"——Phase 589 的 movingIds 语义错误，
//     已回退。
//   uw2.java case3 — TapToSelect：ntc/cqc 组命中 → gtc Group 选择态；
//     otc 元素命中 → fvb.d(id) 选中该元素。
// Harmony：选区内按下 → 整体拖拽（wtc/e39 等价）；选区外按下 →
//   命中元素经 resolveOriginalGroupSelection 展开组后 selectElementIds
//   （TapToSelect），未命中 → clearSelectionWithRegisterReset。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const TOOL = 'note/src/main/ets/rendering/SelectionTool.ets';
const CANVAS = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const GEO = 'note/src/main/ets/core/model/ShapeGeometry.ets';

const tool = readFileSync(TOOL, 'utf8');
const canvas = readFileSync(CANVAS, 'utf8');
const geo = readFileSync(GEO, 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- Phase 589 误读回退：movingIds 机制不复存在 ---
check(!tool.includes('movingIds'), 'movingIds removed from SelectionState');
check(!tool.includes('grabElements') && !tool.includes('movingSubsetOf'),
  'grab/moving-subset machinery removed');
check(!canvas.includes('grabElements') && !canvas.includes('movingSubsetOf') &&
  !canvas.includes('hitTestSelectedElementIds'), 'canvas grab machinery removed');
const applyT = tool.slice(tool.indexOf('applyTransform(strokes: StrokeElementData[])'),
  tool.indexOf('applyTransform(strokes: StrokeElementData[])') + 300);
check(applyT.includes('this.state.selectedStrokeIds.indexOf(s.id)'),
  'applyTransform back to full selected set');

// --- 常态选区内按下 → 整体拖拽（wtc/e39 等价） ---
const branch = canvas.slice(canvas.indexOf('isSelectionActive()'),
  canvas.indexOf('isSelectionActive()') + 3200);
check(branch.includes('pointInRect({ x: touch.x, y: touch.y }, this.selectionRect)') &&
  branch.includes('this.selectionDrag = true'),
  'inside-rect press drags the whole selection');
check(branch.indexOf('pointInRect({ x: touch.x, y: touch.y }, this.selectionRect)') <
  branch.indexOf('topmostPageElementIdAt'),
  'inside-rect drag precedes the outside-press probe');

// --- 选区外按下 → vtc TapToSelect / rtc ClearSelection ---
check(branch.includes('topmostPageElementIdAt(canvasP)'),
  'outside-press probes the topmost element');
check(branch.includes('resolveOriginalGroupSelection(') &&
  branch.includes('this.allPageEntityIds()'),
  'hit element expanded through Original groups (cqc → gtc parity)');
check(branch.includes('this.selectionTool.selectElementIds('),
  'TapToSelect selects the hit element/group');
check(branch.includes('this.clearSelectionWithRegisterReset()'),
  'miss → ClearSelection');
check(branch.indexOf('topmostPageElementIdAt') < branch.indexOf('beginSelection('),
  'TapToSelect/ClearSelection precede lasso begin (only with selection visible)');
check(branch.includes('this.updateSelectionOverlay()'),
  'tap selection refreshes the overlay');

// --- topmostPageElementIdAt：统一 z 序最上层逐类命中 ---
const hitTest = canvas.slice(canvas.indexOf('topmostPageElementIdAt(point: Point2D)'),
  canvas.indexOf('topmostPageElementIdAt(point: Point2D)') + 2200);
check(hitTest.includes('materializePageElements(') && hitTest.includes('i >= 0; i--'),
  'topmost-first iteration over the unified z-order');
check(hitTest.includes('hitStrokeAtPoint(point, element.data)'),
  'strokes use exact coverage');
check(hitTest.includes('pointHitsShape(point, element.data)'),
  'shapes use exact coverage');
check(hitTest.includes('textBlockLocalBounds(element.data)') &&
  hitTest.includes('imageBlockLocalBounds(element.data)') &&
  hitTest.includes('mathBlockLocalBounds(element.data)') &&
  hitTest.includes('pointHitsAffineBlock('),
  'block kinds use inverse-affine local-rect hits');

// --- 无选区时仍是套索/矩形新手势 ---
check(branch.includes('this.selectionTool.beginSelection(') &&
  branch.includes('SelectionMode.LASSO'),
  'no selection → lasso/rectangle gesture unchanged');

// --- 通用形状点命中导出保留 ---
check(geo.includes('export function pointHitsShape(point: Point2D, shape: ShapeElement)'),
  'pointHitsShape exported');

console.log(`D02_ORIGINAL_SELECTION_TAP_CLEAR_OK TOTAL=${n} FAILED=0`);
