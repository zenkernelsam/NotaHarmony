// Phase 596 — 选区角柄变换；Phase 1455 升级为 1.4.2 wtf(Scale) 会话。
// Original evidence (decompiled_1.4.2/sources/defpackage):
//   ms1.java:295-327 — 角柄命中：四角 ±f15=guf.l/k=44/zoom 方框（文档系）；
//   ms1.java:330-435 — wtf(stateId, originalPositions, dragStart, axis,
//     xAxis, yAxis, locksAspectRatio, fixedCorner, lastDragPoint, initSel)；
//     stf 序 TOP_LEFT..BOTTOM_RIGHT；z7=false 仅 lsf+vvh 文本块；
//     jA4=对侧角 fixedCorner；轴向量经 kw9.c 旋入选区旋转系。
//   guf.java:67-75 — f(j, wtf)：sx=1+Δ·xAxis/|xAxis|²、sy 同式；
//   guf.java:280-354 — h(map, f=sx, f2=sy, j=fixedCorner, z=页框钳制)
//     逐成员双轴缩放应用（含 jv6 文本 16px 字号下限）；
//   wtf toString 无角度字段 → 角柄不产旋转（终结 1.0.3 htc.e/qpi.b
//     角柄缩放+旋转自由变换语义——版本演进）。
// Harmony：tryStartSelectionResize 捕获带符号轴幅 + freeScale 门；
//   applySelectionResize 角柄支 → Δ 位移投影 → resizeSelectedAxes
//   （T(fixed)·S(sx,sy)·T(−fixed)·base）；旋转柄支保持 vtf 语义。
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
// Phase 597 — msc.c selectionHasRotationHandle 旋转柄（纯旋转，
// scale 锁 1，anchor=选区中心；qpi.b f2=null 路径）。
// Phase 1450 gsf.e 精证：旋转柄锚点=右（RTL 左）边中点 +
// 水平茎 56vp 延出（非顶边上方——早前按 iOS 惯例的锚点已修正）。
check(layout.includes('SELECTION_ROTATE_HANDLE_STEM'),
  'rotate-handle stem constant exists (gsf.e 56dp/zoom stem)');
const rotateStemIdx = overlay.indexOf('.width(SELECTION_ROTATE_HANDLE_STEM)');
check(rotateStemIdx > 0, 'rotate stem drawn (gsf.e 2dp line to endpoint)');
const rotateBlock = overlay.slice(rotateStemIdx - 400, rotateStemIdx + 1600);
check(rotateBlock.includes('this.selectionChromeRect.right') &&
  rotateBlock.includes('(this.selectionChromeRect.top + this.selectionChromeRect.bottom) / 2') &&
  rotateBlock.includes('SELECTION_ROTATE_DOT_OUTER'),
  'rotate handle anchors at right-edge midpoint + 56vp stem endpoint dot (chrome shell space)');
const handleBlock = overlay.slice(overlay.indexOf('if (!this.deselectMode && !this.photoImportLeaseActive'),
  overlay.indexOf('Circle()') + 200);
check(handleBlock.includes('!this.deselectMode') &&
  handleBlock.includes('!this.photoImportLeaseActive') &&
  handleBlock.includes('!this.selectionHandlesHidden'),
  'handles hidden in deselectMode, photo-import lease, and ' +
  'borderless-member cases (Phase 1449 mp4.d/xnm.c gate)');

// --- 按下：角柄命中优先于内部拖拽 ---
const down = canvas.slice(canvas.indexOf('private onTouchDown('),
  canvas.indexOf('private onTouchDown(') + 9000);
const cornerIdx = down.indexOf('this.tryStartSelectionResize(');
const dragIdx = down.indexOf('已选中且按下点在选区内');
check(cornerIdx > 0 && dragIdx > cornerIdx,
  'corner-handle hit precedes the inside-rect drag branch');
// Phase 603：会话初始化抽取为 tryStartSelectionResize（SELECTION/TEXT 面共用）。
const cornerBlock = canvas.slice(canvas.indexOf('private tryStartSelectionResize('),
  canvas.indexOf('private tryStartSelectionResize(') + 4000);
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

// --- 移动：旋转柄=vtf 纯旋转；角柄=wtf 对侧角枢轴双轴缩放（P1455） ---
// 1.4.2 会话分工：wtf toString 无角度字段 → 角柄拖拽不产旋转；
// guf.f 产 (sx,sy)=位移投影轴比；guf.h 双轴应用+fixedCorner 枢轴。
const resize = canvas.slice(canvas.indexOf('private applySelectionResize('),
  canvas.indexOf('private applySelectionResize(') + 5400);
check(resize.includes('if (this.resizeIsRotate) {'),
  'rotate-handle branch split from corner scale');
check(resize.includes('this.selectionTool.resizeSelected(1, radians, this.resizeAnchor'),
  'rotate session locks scale=1 (vtf)');
check(resize.includes('Math.atan2(dy, dx)') &&
  resize.includes('curRadians - Math.atan2(startDy, startDx)'),
  'rotation = angular displacement about the center (vtf.e); ' +
  'P1453: absolute angle snap (guf.e) on the rotate-handle branch');
check(resize.includes('1 + (ddx * this.resizeAxisVecX.x + ddy * this.resizeAxisVecX.y) / axLen2') &&
  resize.includes('1 + (ddx * this.resizeAxisVecY.x + ddy * this.resizeAxisVecY.y) / ayLen2'),
  'free per-axis scale = 1+Δ·axis/|axis|² (guf.f dot projections, wtf xAxis/yAxis vectors)');
check(resize.includes('(ddx * this.resizeDiagVec.x + ddy * this.resizeDiagVec.y) / diag2'),
  'locked scale = diagonal-vector projection (wtf axis field)');
check(resize.includes('this.selectionTool.resizeSelectedAxes(scaleX, scaleY, this.resizeAnchor'),
  'corner transform applies both axes about the fixed corner');
check(!resize.includes('Math.atan2(ddy, ddx)') &&
  resize.indexOf('this.selectionTool.resizeSelectedAxes') >
  resize.indexOf('resizeIsRotate'),
  'corner session produces no rotation (wtf has no angle field)');
check(resize.includes('this.applySelectionTransform(false, false)'),
  'mid-gesture transform applies without pushing undo');

// --- 角柄会话轴幅/锁纵横比初始化（ms1:330-435 wtf 构造） ---
// P1461：轴幅=对角向量 D=拖拽角−fixedCorner 在框轴单位向量上的分解
//（旋转系 xAxis/yAxis；AABB 下退化 (±w,0)/(0,±h)）。
check(cornerBlock.includes('this.resizeDiagVec = diagCv') &&
  cornerBlock.includes('dAlongEx: number = diagCv.x * ex.x + diagCv.y * ex.y') &&
  cornerBlock.includes('this.resizeAxisVecX = { x: ex.x * dAlongEx') &&
  cornerBlock.includes('this.resizeAxisVecY = { x: ey.x * dAlongEy'),
  'axis vectors = diagonal decomposed on frame axes (wtf axis/xAxis/yAxis)');
check(cornerBlock.includes('rs.selectedTextBlockIds.length === 1') &&
  cornerBlock.includes('this.resizeFreeScale'),
  'locksAspectRatio=false only for lsf single text block (ms1 z7)');

// --- 角柄命中域：原版 ±f15=44/zoom 文档方框（ms1:295-327） ---
const hitBlock = canvas.slice(canvas.indexOf('private selectionResizeCornerAt('),
  canvas.indexOf('private selectionResizeCornerAt(') + 1300);
check(hitBlock.includes('Math.abs(q.x - corners[i].x) < SELECTION_CORNER_HIT_HALF') &&
  hitBlock.includes('Math.abs(q.y - corners[i].y) < SELECTION_CORNER_HIT_HALF'),
  'corner hit = axis-aligned square in unrotated shell space (not a circle)');
check(canvas.includes('const SELECTION_CORNER_HIT_HALF: number = 44.0;'),
  'corner hit half-extent = 44vp screen (f15·zoom)');

// --- SelectionTool.resizeSelected = R(scaledCenter)·S(anchor)·base ---
const toolBody = tool.slice(tool.indexOf('resizeSelected('),
  tool.indexOf('resizeSelected(') + 2000);
check(toolBody.includes('anchor.x * (1 - scale)') &&
  toolBody.includes('scaledCenter.x * (1 - cos) + scaledCenter.y * sin'),
  'resizeSelected = scale-about-anchor then rotate-about-scaled-center');
check(toolBody.includes('this.multiply(r, this.multiply(s, base))'),
  'transform rebuilds on the base matrix (not incremental)');
const axesBody = tool.slice(tool.indexOf('resizeSelectedAxes('),
  tool.indexOf('resizeSelectedAxes(') + 1600);
check(axesBody.includes('scaleX, 0, anchor.x * (1 - scaleX)') &&
  axesBody.includes('0, scaleY, anchor.y * (1 - scaleY)') &&
  axesBody.includes('this.multiply(s, base)'),
  'resizeSelectedAxes = per-axis scale about fixedCorner (guf.h)');

// --- 提交/取消复用 selectionDrag 通道 ---
check(canvas.includes('} else if (this.selectionDrag || this.selectionResize || this.vertexDrag) {'),
  'drop commit shared with the move-drag path (single undo push)');
const cancel = canvas.slice(canvas.indexOf('private cancelActiveInteraction('),
  canvas.indexOf('private cancelActiveInteraction(') + 4000);
check(cancel.includes('this.selectionDrag || this.selectionResize || this.vertexDrag'),
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

// --- 可执行模型：wtf 角柄拖拽数学 ---
// 选区 AABB (0,0)-(4,2)，拖 BR 角（fixed=TL anchor=(0,0)）：
// axisX=4, axisY=2；Δ=(2,1)（沿对角半程）→ 等比 s=1+(2·4+1·2)/20=1.5。
const anchor = { x: 0, y: 0 };
const start = { x: 4, y: 2 };
const axisX = start.x - anchor.x;
const axisY = start.y - anchor.y;
const delta = { x: 2, y: 1 };
const diag2 = axisX * axisX + axisY * axisY;
const sLocked = 1 + (delta.x * axisX + delta.y * axisY) / diag2;
assert(Math.abs(sLocked - 1.5) < 1e-9,
  'locked diagonal projection: Δ along diagonal → s=1.5');
// 纯 x 位移 Δ=(4,0)：等比 s=1+16/20=1.8；自由拉伸 sx=2, sy=1。
const d2 = { x: 4, y: 0 };
const s2 = 1 + (d2.x * axisX + d2.y * axisY) / diag2;
assert(Math.abs(s2 - 1.8) < 1e-9, 'locked: x-only drag still scales both');
const sxFree = 1 + d2.x / axisX;
const syFree = 1 + d2.y / axisY;
assert(Math.abs(sxFree - 2) < 1e-9 && Math.abs(syFree - 1) < 1e-9,
  'free (lsf text): per-axis sx=2, sy=1');
// 拖过 fixedCorner（Δ=(-8,-4)）→ s=−1 翻转——原版 h() 无符号钳制。
const d3 = { x: -8, y: -4 };
const s3 = 1 + (d3.x * axisX + d3.y * axisY) / diag2;
assert(Math.abs(s3 - (-1)) < 1e-9, 'crossing fixedCorner flips (no sign clamp)');
n += 4;

console.log(`D02_ORIGINAL_SELECTION_RESIZE_OK TOTAL=${n} FAILED=0`);
