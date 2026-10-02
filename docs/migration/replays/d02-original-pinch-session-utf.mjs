// Phase 1457 — 双指 utf(PinchTransform) 选区变换会话移植校验。
// Original evidence (decompiled_1.4.2/sources/defpackage):
//   utf.java — PinchTransform 会话：a=会话ID、b=originalPositions、
//     c/d/f=打包点、e=transientOpId、g=scale(1.0 起)、h=rotation(0.0 起)、
//     i=initialSelectionState；构造器收 (id, map, j×3=pivot 点, msf)。
//   guf.java y(j)：会话建立门——h==null（无活动变换会话）、当前选区
//     属于活动页、非锁定、非 hsf 进行中手势、非 isf.h 点除模式；
//     第二指点经选区旋转 f 反旋入旋转系后须落在选区界内；
//     mapI=i(msf) 捕获原位置 → new utf(id, mapI, j, j, j, msf)。
//   guf.java v(j, f, f2, …)：更新——utfVar.a(j) 枢轴点、
//     k(f3) 等比缩放、j(twm.d(f2,m)) 90°/5° 吸附旋转；
//     scale≠1∥rot≠0 时 m(h(), f3, fD, i(), false) 预览、
//     结束支 a.c(id, false, null, scale, rot≠0?rot:null, s64(i()))
//     提交——选区保留。
//   guf.java m(map, f, f2, pivot, z)：逐成员等比缩放+绕枢轴旋转，
//     即 T(p)·R(θ)·S(s)·T(−p)·base 复合。
//   twm.d(f, m)：角增量吸附最近 90° 倍数（阈值 fq9.z(5)=5°）。
// Harmony：tryStartSelectionPinch/applySelectionPinch/endSelectionPinchCommit
//   + 视口 PinchGesture/PanGesture 的 pinchSelectSession 门控。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const ROOT = new URL('../../..', import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1');
const read = (p) => readFileSync(`${ROOT}/${p}`, 'utf8');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- 会话字段（utf scale/rotation/pivot/originalPositions 对应） ---
check(canvas.includes('private pinchSelectSession: boolean = false;') &&
  canvas.includes('private pinchStartDist: number = 0;') &&
  canvas.includes('private pinchStartAngle: number = 0;') &&
  canvas.includes('private pinchBaseTransform: TransformMatrix') &&
  canvas.includes('private pinchPivot: Point2D') &&
  canvas.includes('private pinchChanged: boolean = false;'),
  'utf session fields (pinch state / start dist+angle / base transform / pivot)');

// --- 建立门（guf.y）：多点分支内、取消交互之前 ---
const downIdx = canvas.indexOf('private onTouchDown(');
const multiTouch = canvas.slice(downIdx, downIdx + 2000);
const pinchCallIdx = multiTouch.indexOf('this.tryStartSelectionPinch(event)');
const cancelIdx = multiTouch.indexOf('this.cancelActiveInteraction();');
check(pinchCallIdx > 0 && pinchCallIdx < cancelIdx,
  'multi-touch down: utf gate precedes cancelActiveInteraction (guf.y ordering)');

// --- 建立门条件（h==null·非点除·非锁定·界内第二指） ---
const start = canvas.slice(canvas.indexOf('private tryStartSelectionPinch('),
  canvas.indexOf('private tryStartSelectionPinch(') + 1800);
check(start.includes('this.selectionDrag || this.selectionResize || this.vertexDrag') &&
  start.includes('this.pinchSelectSession'),
  'utf gate: no active transform session (h==null equivalent)');
check(start.includes('state.deselectMode'),
  'utf gate: isf.h deselectMode excluded');
check(start.includes('this.selectionPositionLocked') &&
  start.includes('this.selectionDrawing'),
  'utf gate: locked + in-progress hsf selection excluded');
check(start.includes('this.pointInSelectionRect({ x: second.x, y: second.y }, secondCanvas)'),
  'utf gate: second finger inside rotated selection bounds');
check(start.includes('event.touches[event.touches.length - 1]'),
  'utf pivot = second finger touch (utf.i() semantics)');
check(start.includes('this.pinchBaseTransform = state.transform.slice()'),
  'utf captures base transform (utf.b originalPositions equivalent)');
check(start.includes('this.dragBeforeStrokes = this.completedStrokes.slice()') &&
  start.includes('this.dragBeforeShapes = this.shapes.slice()') &&
  start.includes('this.dragBeforeMathBlocks = this.mathBlocks.slice()'),
  'utf undo snapshot pipeline (TRANSFORM_ELEMENTS commit parity)');

// --- 更新（guf.v）：等比缩放 + twm.d 吸附 + 枢轴 ---
const apply = canvas.slice(canvas.indexOf('private applySelectionPinch('),
  canvas.indexOf('private applySelectionPinch(') + 2200);
check(apply.includes('const scale: number = dist / this.pinchStartDist;'),
  'utf scale = finger-distance ratio (equal scaling, guf.v f)');
check(apply.includes('const delta: number = angle - this.pinchStartAngle;') &&
  apply.includes('this.snapSelectionRotateDelta(delta)'),
  'utf rotation = line-angle delta via twm.d snap');
check(apply.includes('this.selectionTool.resizeSelected(scale, snapped, this.pinchPivot,') &&
  apply.includes('this.pinchPivot, this.pinchBaseTransform)'),
  'utf apply = T(p)·R·S·T(−p)·base (guf.m; pivot shared by R and S)');
check(apply.includes('this.applySelectionTransform(false, false)'),
  'utf mid-gesture preview without undo push');

// --- twm.d 吸附实现 ---
const snap = canvas.slice(canvas.indexOf('private snapSelectionRotateDelta('),
  canvas.indexOf('private snapSelectionRotateDelta(') + 600);
check(snap.includes('Math.round(delta / SELECTION_ROTATE_SNAP_STEP)') &&
  snap.includes('Math.abs(delta - snapped) < SELECTION_ROTATE_SNAP_RAD'),
  'twm.d: snap to nearest 90° multiple within 5° threshold');
check(canvas.includes('const SELECTION_ROTATE_SNAP_STEP: number = Math.PI / 2.0;') &&
  canvas.includes('const SELECTION_ROTATE_SNAP_RAD: number = Math.PI * 5.0 / 180.0;'),
  'snap constants: 90° step (guf.n set) + 5° threshold (fq9.z)');

// --- onTouchMove 分发 ---
const moveIdx = canvas.indexOf('private onTouchMove(');
const moveBlock = canvas.slice(moveIdx, moveIdx + 900);
const pinchMoveIdx = moveBlock.indexOf('this.pinchSelectSession');
const genericCancelIdx = moveBlock.indexOf('this.cancelActiveInteraction();');
check(pinchMoveIdx > 0 && pinchMoveIdx < genericCancelIdx &&
  moveBlock.includes('this.applySelectionPinch(event)'),
  'touchMove: utf session consumes two-finger move before generic cancel');

// --- 结束提交（guf.v 完成支 → a.c） ---
check(canvas.includes('private endSelectionPinchCommit(') &&
  canvas.includes('UndoableActionType.TRANSFORM_ELEMENTS'),
  'utf commit = single TRANSFORM_ELEMENTS undo record');
const upIdx = canvas.indexOf('private onTouchUp(');
const upBlock = canvas.slice(upIdx, upIdx + 1600);
check(upBlock.includes('this.pinchSelectSession && event.touches.length < 2') &&
  upBlock.includes('this.endSelectionPinchCommit()'),
  'touchUp: finger lift during utf commits (guf.v end branch, selection kept)');
const commit = canvas.slice(canvas.indexOf('private endSelectionPinchCommit('),
  canvas.indexOf('private endSelectionPinchCommit(') + 2800);
check(commit.includes('this.selectionTool.selectElementIds(') &&
  commit.includes('this.updateSelectionOverlay()'),
  'utf commit preserves selection + refreshes overlay');

// --- 取消路径 ---
const cancel = canvas.slice(canvas.indexOf('private cancelActiveInteraction('),
  canvas.indexOf('private cancelActiveInteraction(') + 4200);
check(cancel.includes('this.pinchSelectSession') &&
  cancel.includes('this.pinchSelectSession = false') &&
  cancel.includes('this.pinchChanged = false'),
  'cancel: utf session restores dragBefore + clears flags');

// --- 视口手势门控 ---
const pinchGesture = canvas.slice(canvas.indexOf('PinchGesture({ fingers: 2 })'),
  canvas.indexOf('PinchGesture({ fingers: 2 })') + 700);
check(pinchGesture.includes('if (this.pinchSelectSession)') &&
  pinchGesture.includes('return;'),
  'viewport PinchGesture suppressed during utf session');
const panGesture = canvas.slice(canvas.indexOf('PanGesture({ fingers: 2 })'),
  canvas.indexOf('PanGesture({ fingers: 2 })') + 400);
check(panGesture.includes('if (this.pinchSelectSession)'),
  'viewport PanGesture suppressed during utf session');

console.log(`D02_ORIGINAL_PINCH_UTF_OK TOTAL=${n} FAILED=0`);
