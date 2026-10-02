// Phase 1455 — 角柄 wtf(Scale) 会话移植校验。
// Original evidence (decompiled_1.4.2/sources/defpackage):
//   ms1.java:295-327 — 命中：对 u64.c(sbe) 四角找最近角，
//     |dx|<f15 ∧ |dy|<f15 轴对齐方框，f15=guf.l(44)/k(zoom)；
//   ms1.java:330-435 — new wtf(getId, mapI 原位置图, jE dragStartPoint=
//     实际触点, jA axis 对角向量, jC4 xAxis, jC5 yAxis, z7
//     locksAspectRatio, j7/j10 fixedCorner 对侧角, jE, msfVar)；
//     axis/xAxis/yAxis 经 kw9.c 按选区旋转 f 旋入旋转系；
//     stf 枚举序 TOP_LEFT/TOP_RIGHT/BOTTOM_LEFT/BOTTOM_RIGHT；
//     z7=false ⟺ msfVar instanceof lsf ∧ 元素 instanceof vvh。
//   wtf.java toString：Scale(stateId, originalPositions, dragStartPoint,
//     axis, xAxis, yAxis, locksAspectRatio, fixedCorner, transientOpId,
//     lastDragPoint, initialSelectionState)——无角度字段。
//   guf.java:67-75 — f(j, wtf)：sx=(xAxis+j)·xAxis/|xAxis|²、
//     sy=(yAxis+j)·yAxis/|yAxis|²（j=cur−dragStart 位移 → 1+Δ·轴/|轴|²）。
//   guf.java:280-354 — h(map, f=sx, f2=sy, j=pivot, z)：逐成员
//     (pos−page−pivot)→逆元旋转→×(sx,sy)→正旋→+pivot+page；
//     jv6 文本字号 16px 下限（fD2/fC2 地板）；z=true 页框钳制 a()。
// Harmony：applySelectionResize 角柄支 = wtf 语义（Δ 投影轴比 +
//   locksAspectRatio 对角统一比 + fixedCorner 枢轴 + 无旋转）。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const ROOT = new URL('../../..', import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1');
const read = (p) => readFileSync(`${ROOT}/${p}`, 'utf8');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const tool = read('note/src/main/ets/rendering/SelectionTool.ets');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- 会话字段（wtf stateId/axis/xAxis/yAxis/locksAspectRatio/fixedCorner） ---
check(canvas.includes('private resizeAxisX: number = 1;') &&
  canvas.includes('private resizeAxisY: number = 1;'),
  'wtf axis extents state (xAxis/yAxis signed magnitudes)');
check(canvas.includes('private resizeFreeScale: boolean = false;'),
  'wtf locksAspectRatio flag (negated: freeScale)');

// --- 命中域：±44vp 轴对齐方框（f15=guf.l/zoom×zoom） ---
const hit = canvas.slice(canvas.indexOf('private selectionResizeCornerAt('),
  canvas.indexOf('private selectionResizeCornerAt(') + 1200);
check(hit.includes('Math.abs(p.x - corners[i].x) < SELECTION_CORNER_HIT_HALF') &&
  hit.includes('Math.abs(p.y - corners[i].y) < SELECTION_CORNER_HIT_HALF') &&
  !hit.includes('dx * dx + dy * dy'),
  'corner hit = 88vp axis-aligned square (ms1 f15 semantics)');
check(canvas.includes('const SELECTION_CORNER_HIT_HALF: number = 44.0;'),
  'corner hit half = 44vp (guf.l=44 screen-px equivalent)');

// --- 会话构造（tryStartSelectionResize 角柄支） ---
const init = canvas.slice(canvas.indexOf('private tryStartSelectionResize('),
  canvas.indexOf('private tryStartSelectionResize(') + 3600);
check(init.includes('corners[(corner + 2) % 4]'),
  'fixedCorner = opposite corner (stf ordinal +2 mod 4)');
check(init.includes('this.resizeAxisX = draggedCv.x - this.resizeAnchor.x') &&
  init.includes('this.resizeAxisY = draggedCv.y - this.resizeAnchor.y'),
  'axis extents = draggedCorner − fixedCorner (xAxis/yAxis vectors)');
check(init.includes('this.resizeStart = this.viewport.screenToCanvas(screenP.x, screenP.y)'),
  'dragStartPoint = actual touch point (wtf.c=jE, not the corner)');
check(init.includes('this.resizeFreeScale = !rs.supportsDeselectMode') &&
  init.includes('rs.selectedTextBlockIds.length === 1') &&
  init.includes('rs.selectedGroupIds.length === 0'),
  'locksAspectRatio=false ⟺ lsf single vvh text block (ms1 z7)');
check(init.indexOf('resizeFreeScale') > init.indexOf('this.resizeIsRotate = false'),
  'freeScale resolved inside the corner branch (not rotate)');

// --- 每帧缩放（guf.f 投影 + locksAspectRatio 收敛） ---
const apply = canvas.slice(canvas.indexOf('private applySelectionResize('),
  canvas.indexOf('private applySelectionResize(') + 3400);
check(apply.includes('1 + ddx / this.resizeAxisX') &&
  apply.includes('1 + ddy / this.resizeAxisY'),
  'free scale: s_axis = 1+Δ/axisExtent (guf.f normalized projection)');
check(apply.includes('1 + (ddx * this.resizeAxisX + ddy * this.resizeAxisY) / diag2'),
  'locked scale: s = 1+Δ·axis/|axis|² (diagonal projection uniform)');
check(apply.includes('scaleX = s;') && apply.includes('scaleY = s;'),
  'locked: same scalar to both axes');
check(apply.includes('this.selectionTool.resizeSelectedAxes(scaleX, scaleY, this.resizeAnchor,'),
  'per-frame rebuild about fixedCorner via resizeSelectedAxes');
check(!apply.slice(apply.indexOf('// 原版 wtf(Scale)')).includes('radians'),
  'wtf branch emits zero rotation (no angle field in session)');
check(apply.includes('Math.abs(this.resizeAxisX) > 0.0001'),
  'degenerate axis guards scale=1 (guf.f fC==0 → 1)');

// --- 应用矩阵：T(fixed)·S(sx,sy)·T(−fixed)·base ---
const axes = tool.slice(tool.indexOf('resizeSelectedAxes('),
  tool.indexOf('resizeSelectedAxes(') + 1600);
check(axes.includes('scaleX, 0, anchor.x * (1 - scaleX)') &&
  axes.includes('0, scaleY, anchor.y * (1 - scaleY)') &&
  axes.includes('this.multiply(s, base)'),
  'resizeSelectedAxes = per-axis S about anchor over base matrix');

// --- 提交/撤销路径与 drag/resize 复用 ---
check(canvas.includes('this.selectionDrag || this.selectionResize || this.vertexDrag'),
  'wtf commit shares the drag/resize undo channel');

// --- 可执行数学模型：guf.f 位移投影语义 ---
// 选区 (0,0)-(6,3)，拖 BR（axisX=6, axisY=3，fixed=TL）。
const axisX = 6, axisY = 3, diag2 = axisX * axisX + axisY * axisY;
const proj = (dx, dy) => 1 + (dx * axisX + dy * axisY) / diag2;
// 沿角平分线拉到 1.5 倍：Δ=(3,1.5) → s=1+(18+4.5)/45=1.5
assert(Math.abs(proj(3, 1.5) - 1.5) < 1e-9, 'diagonal half-step → s=1.5');
// 拖回 fixedCorner：Δ=(-6,-3) → s=0（压扁到枢轴点）
assert(Math.abs(proj(-6, -3)) < 1e-9, 'drag to fixedCorner → s=0');
// 垂直对角方向位移不产生缩放：Δ⊥=(−3,6) → Δ·axis=−18+18=0
assert(Math.abs(proj(-3, 6) - 1) < 1e-9, 'perpendicular drag → s=1 (no rotation)');
n += 3;

console.log(`D02_ORIGINAL_WTF_SCALE_OK TOTAL=${n} FAILED=0`);
