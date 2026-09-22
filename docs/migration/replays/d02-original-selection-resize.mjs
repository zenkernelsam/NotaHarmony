// Phase 596 — 选区角柄自由变换（缩放+旋转，qpi.b/fvb.f 等价）。
// Original evidence (decompiled_1.0.3/sources/defpackage):
//   htc.java — 覆盖层状态接口：e(z, ei3, Float, Float, ei3) 变换入口；
//     a()/d() 产出 cmb 矩形（dl1 以 wtc(cmb,ktc) 携带按下区域）。
//   gtc.java:9-11,66-75 — 组选区持有 cmb 矩形 + Float e/g（旋转角）；
//     e() 调 qpi.b(this.f, this.g, point, scale, rotation, pivot) 重建
//     (matrix, newRect, newRotation)；z=true 提交、z=false 预览。
//   qpi.java:50-68 — b(): pivot=ei3Var2??rect 中心，scale=f2??1，
//     translate=ei3Var??0 → 等比缩放+平移矩阵；旋转 f3 叠加基角。
//   avc.java:689 — 手势产出 f(id,false,null,scale,rot?非0,pivot)。
//   fvb.java:101-107 — f(id,z,point,scale,rotation,pivot) → htc.e。
// Harmony：SelectionOverlay 四角柄（SELECTION_HANDLE_SIZE/HIT_RADIUS）；
//   onTouchDown 角命中 → selectionResize 会话（anchor=对角画布坐标）；
//   move → applySelectionResize（距离比=缩放、绕 anchor 角位移=旋转）
//   → SelectionTool.resizeSelected 重建 R(scaledCenter)·S(anchor)·base；
//   drop 复用 selectionDrag 提交路径（TRANSFORM_ELEMENTS 撤销）。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const ROOT = new URL('../../..', import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1');
const read = (p) => readFileSync(`${ROOT}/${p}`, 'utf8');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const overlay = read('note/src/main/ets/ui/components/SelectionOverlay.ets');
const layout = read('note/src/main/ets/ui/components/SelectionOverlayLayout.ets');
const tool = read('note/src/main/ets/rendering/SelectionTool.ets');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- 覆盖层角柄（装饰性，命中由画布判定） ---
check(layout.includes('SELECTION_HANDLE_SIZE') &&
  layout.includes('SELECTION_HANDLE_HIT_RADIUS'),
  'handle size + hit radius constants exist');
check(overlay.includes('Circle()') &&
  overlay.includes('SELECTION_HANDLE_SIZE'),
  'overlay renders corner handle dots');
// Phase 597 — msc.c selectionHasRotationHandle：顶边上方旋转柄，
// 纯旋转（scale 锁 1，anchor=选区中心；qpi.b f2=null 路径）。
check(layout.includes('SELECTION_ROTATE_HANDLE_OFFSET'),
  'rotate-handle offset constant exists');
const rotateBlock = overlay.slice(
  overlay.indexOf('y: this.selectionRect.top - SELECTION_ROTATE_HANDLE_OFFSET') - 500,
  overlay.indexOf('y: this.selectionRect.top - SELECTION_ROTATE_HANDLE_OFFSET') + 300);
check(rotateBlock.includes('Circle()') &&
  rotateBlock.includes('(this.selectionRect.left + this.selectionRect.right) / 2') &&
  rotateBlock.includes('this.selectionRect.top - SELECTION_ROTATE_HANDLE_OFFSET'),
  'rotate handle hovers above the top-edge midpoint');
const handleBlock = overlay.slice(overlay.indexOf('if (!this.deselectMode && !this.photoImportLeaseActive)'),
  overlay.indexOf('Circle()') + 200);
check(handleBlock.includes('!this.deselectMode') &&
  handleBlock.includes('!this.photoImportLeaseActive'),
  'handles hidden in deselectMode and photo-import lease');

// --- 按下：角柄命中优先于内部拖拽 ---
const down = canvas.slice(canvas.indexOf('private onTouchDown('),
  canvas.indexOf('private onTouchDown(') + 9000);
const cornerIdx = down.indexOf('this.tryStartSelectionResize(');
const dragIdx = down.indexOf('已选中且按下点在选区内');
check(cornerIdx > 0 && dragIdx > cornerIdx,
  'corner-handle hit precedes the inside-rect drag branch');
// Phase 603：会话初始化抽取为 tryStartSelectionResize（SELECTION/TEXT 面共用）。
const cornerBlock = canvas.slice(canvas.indexOf('private tryStartSelectionResize('),
  canvas.indexOf('private tryStartSelectionResize(') + 2600);
check(cornerBlock.includes('this.selectionPositionLocked'),
  'handles gated off when the selection is position-locked');
check(cornerBlock.includes('corners[(corner + 2) % 4]'),
  'resize anchor = the opposite corner (htc.e pivot parity)');
check(cornerBlock.includes('this.resizeBaseTransform = this.selectionTool.getState().transform.slice()'),
  'drag-start matrix snapshot for per-frame rebuild');
check(cornerBlock.includes('this.dragBeforeStrokes = this.completedStrokes.slice()'),
  'resize shares the dragBefore undo snapshots');
check(cornerBlock.includes('this.selectionRotateHandleAt(') &&
  cornerBlock.includes('this.resizeIsRotate = true;') &&
  cornerBlock.includes('this.resizeAnchor = this.resizeBaseCenter;'),
  'rotate-handle hit anchors at the selection center');

// --- 移动：距离比=缩放，绕 anchor 角位移=旋转 ---
const resize = canvas.slice(canvas.indexOf('private applySelectionResize('),
  canvas.indexOf('private applySelectionResize(') + 2400);
check(resize.includes('this.resizeIsRotate ? 1 :'),
  'rotate session locks scale=1 (qpi.b f2=null → default 1.0f)');
check(resize.includes('const scale: number = dist / startDist;') ||
  resize.includes('Math.sqrt(dx * dx + dy * dy) / startDist'),
  'uniform scale = pointer/anchor distance ratio (qpi.b f2)');
check(resize.includes('Math.atan2(dy, dx) - Math.atan2(startDy, startDx)'),
  'rotation = angular displacement about the anchor (qpi.b f3)');
check(resize.includes('scale * (this.resizeBaseCenter.x - this.resizeAnchor.x)'),
  'rotation center = scaled rect center (qpi.f about fi3.b(cmb))');
check(resize.includes('this.selectionTool.resizeSelected(scale, radians, this.resizeAnchor'),
  'per-frame transform rebuild through the tool');
check(resize.includes('this.applySelectionTransform(false, false)'),
  'mid-gesture transform applies without pushing undo');

// --- SelectionTool.resizeSelected = R(scaledCenter)·S(anchor)·base ---
const toolBody = tool.slice(tool.indexOf('resizeSelected('),
  tool.indexOf('resizeSelected(') + 2000);
check(toolBody.includes('anchor.x * (1 - scale)') &&
  toolBody.includes('scaledCenter.x * (1 - cos) + scaledCenter.y * sin'),
  'resizeSelected = scale-about-anchor then rotate-about-scaled-center');
check(toolBody.includes('this.multiply(r, this.multiply(s, base))'),
  'transform rebuilds on the base matrix (not incremental)');

// --- 提交/取消复用 selectionDrag 通道 ---
check(canvas.includes('} else if (this.selectionDrag || this.selectionResize) {'),
  'drop commit shared with the move-drag path (single undo push)');
const cancel = canvas.slice(canvas.indexOf('private cancelActiveInteraction('),
  canvas.indexOf('private cancelActiveInteraction(') + 4000);
check(cancel.includes('this.selectionDrag || this.selectionResize'),
  'cancel restores dragBefore snapshots for resize too');
check(cancel.includes('this.selectionResize = false;'),
  'cancel clears the resize session');

// --- onTouchMove/onTouchUp 分派 ---
const move = canvas.slice(canvas.indexOf('private onTouchMove('),
  canvas.indexOf('private onTouchMove(') + 3000);
check(move.indexOf('if (this.selectionResize)') > 0 &&
  move.indexOf('if (this.selectionResize)') < move.indexOf('if (this.selectionDrag)'),
  'resize dispatch precedes the move-drag branch');
const up = canvas.slice(canvas.indexOf('private onTouchUp('),
  canvas.indexOf('private onTouchUp(') + 4200);
check(up.includes('} else if (this.selectionResize) {') &&
  up.includes('this.applySelectionResize(p);'),
  'final touch-up applies the resize before commit');

// --- 可执行模型：角柄拖拽数学 ---
// anchor=(0,0)，start=(2,0)，pointer 拖到 (0,2)：dist 2→2 scale=1，
// 角位移 atan2(2,0)-atan2(0,2)= π/2 → 纯旋转 90°。
const anchor = { x: 0, y: 0 };
const start = { x: 2, y: 0 };
const pointer = { x: 0, y: 2 };
const d0 = Math.hypot(start.x - anchor.x, start.y - anchor.y);
const d1 = Math.hypot(pointer.x - anchor.x, pointer.y - anchor.y);
assert(Math.abs(d1 / d0 - 1) < 1e-9, 'scale=1 for equal distances');
const theta = Math.atan2(pointer.y - anchor.y, pointer.x - anchor.x) -
  Math.atan2(start.y - anchor.y, start.x - anchor.x);
assert(Math.abs(theta - Math.PI / 2) < 1e-9, 'quarter-orbit → +90° rotation');
// pointer 拖到 (4,0)：scale=2，无旋转。
const p2 = { x: 4, y: 0 };
const scale2 = Math.hypot(p2.x - anchor.x, p2.y - anchor.y) / d0;
assert(Math.abs(scale2 - 2) < 1e-9, 'doubled distance → scale=2');
const theta2 = Math.atan2(p2.y - anchor.y, p2.x - anchor.x) -
  Math.atan2(start.y - anchor.y, start.x - anchor.x);
assert(Math.abs(theta2) < 1e-9, 'same ray → no rotation');
n += 4;

console.log(`D02_ORIGINAL_SELECTION_RESIZE_OK TOTAL=${n} FAILED=0`);
