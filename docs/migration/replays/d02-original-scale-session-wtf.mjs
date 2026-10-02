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
// Phase 1461：轴幅升级为旋转系向量——resizeAxisVecX/Y=对角向量在框轴
// 上的分解（wtf.xAxis/yAxis），resizeDiagVec=锚→拖拽角对角向量，
// resizeShellRadians=壳旋转角（gsf.c mp4.c()）。
check(canvas.includes('private resizeAxisVecX: Point2D') &&
  canvas.includes('private resizeAxisVecY: Point2D') &&
  canvas.includes('private resizeDiagVec: Point2D'),
  'wtf axis vectors state (xAxis/yAxis rotated-frame vectors + diagonal)');
check(canvas.includes('private resizeShellRadians: number = 0;'),
  'wtf shell rotation radians (gsf.c mp4.c() carrier)');
check(canvas.includes('private resizeFreeScale: boolean = false;'),
  'wtf locksAspectRatio flag (negated: freeScale)');

// --- 命中域：±44vp 轴对齐方框（f15=guf.l/zoom×zoom）；壳旋转时触点
//     先绕框中心反旋 −θ 再在未旋转壳上测（ms1 旋转系方框命中） ---
const hit = canvas.slice(canvas.indexOf('private selectionResizeCornerAt('),
  canvas.indexOf('private selectionResizeCornerAt(') + 1300);
check(hit.includes('Math.abs(q.x - corners[i].x) < SELECTION_CORNER_HIT_HALF') &&
  hit.includes('Math.abs(q.y - corners[i].y) < SELECTION_CORNER_HIT_HALF') &&
  hit.includes('this.unrotateChromePoint(p, g)') &&
  !hit.includes('dx * dx + dy * dy'),
  'corner hit = 88vp square in unrotated shell space (ms1 f15)');
check(canvas.includes('const SELECTION_CORNER_HIT_HALF: number = 44.0;'),
  'corner hit half = 44vp (guf.l=44 screen-px equivalent)');

// --- 会话构造（tryStartSelectionResize 角柄支） ---
const init = canvas.slice(canvas.indexOf('private tryStartSelectionResize('),
  canvas.indexOf('private tryStartSelectionResize(') + 3600);
check(init.includes('corners[(corner + 2) % 4]'),
  'fixedCorner = opposite corner (stf ordinal +2 mod 4)');
check(init.includes('const dAlongEx: number = diagCv.x * ex.x + diagCv.y * ex.y;') &&
  init.includes('this.resizeAxisVecX = { x: ex.x * dAlongEx, y: ex.y * dAlongEx };') &&
  init.includes('this.resizeAxisVecY = { x: ey.x * dAlongEy, y: ey.y * dAlongEy };'),
  'xAxis/yAxis = diagonal decomposed onto frame axes (anchor→dragged)');
check(init.includes('this.resizeShellRadians = this.selectionChromeGeom().radians'),
  'shell rotation captured at session start (mp4.c() carrier)');
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
  canvas.indexOf('private applySelectionResize(') + 5400);
check(apply.includes('1 + (ddx * this.resizeAxisVecX.x + ddy * this.resizeAxisVecX.y) / axLen2') &&
  apply.includes('1 + (ddx * this.resizeAxisVecY.x + ddy * this.resizeAxisVecY.y) / ayLen2'),
  'free scale: s_axis = 1+Δ·axis/|axis|² (guf.f dot projection)');
check(apply.includes('1 + (ddx * this.resizeDiagVec.x + ddy * this.resizeDiagVec.y) / diag2'),
  'locked scale: s = 1+Δ·D/|D|² (diagonal projection uniform)');
check(apply.includes('scaleX = s;') && apply.includes('scaleY = s;'),
  'locked: same scalar to both axes');
check(apply.includes('this.selectionTool.resizeSelectedAxes(scaleX, scaleY, this.resizeAnchor,'),
  'per-frame rebuild about fixedCorner via resizeSelectedAxes');
check(apply.includes('this.resizeBaseTransform, this.resizeShellRadians)'),
  'shell rotation threaded into conjugated scale (R·diag·R⁻¹)');
const wtfSlice = apply.slice(apply.indexOf('// 原版 wtf(Scale)'));
check(!wtfSlice.includes('rotateSelected') &&
  !wtfSlice.includes('resizeSelected(1,'),
  'wtf branch emits zero rotation (no angle field in session)');
check(apply.includes('axLen2 > 0.0001') && apply.includes('ayLen2 > 0.0001'),
  'degenerate axis guards scale=1 (guf.f fC==0 → 1)');

// --- Phase 1459 — jv6 文本 16px 下限（guf.h fD2/fC2 地板钳制） ---
check(apply.includes('16.0 / (baseText.blockWidth * ex)') &&
  apply.includes('16.0 / (baseText.blockHeight * ey)') &&
  apply.includes('if (scaleX < floorX)') && apply.includes('if (scaleY < floorY)'),
  'jv6 text floor: factor ≥ 16/(boxDim·existingScale) per axis (guf.h)');
check(apply.includes('this.dragBeforeTextBlocks.find'),
  'floor uses session-start transform (hv6.b() existing scale)');
check(apply.indexOf('baseText') > apply.indexOf('this.resizeFreeScale'),
  'floor gated to freeScale (lsf single vvh) branch');
// 可执行模型：框宽 200·ex=1 → floorX=0.08；请求 0.05 缩到地板。
const floorX = 16.0 / (200 * 1.0);
assert(Math.abs(floorX - 0.08) < 1e-9, 'floor = 16/(200·1) = 0.08');
n += 1;

// --- 应用矩阵：θ=0 → T(fixed)·S(sx,sy)·T(−fixed)·base；
//     θ≠0 → T·R(θ)·diag·R(−θ)·T⁻¹ 共轭缩放（旋转系轴） ---
const axes = tool.slice(tool.indexOf('resizeSelectedAxes('),
  tool.indexOf('resizeSelectedAxes(') + 1600);
check(axes.includes('scaleX, 0, anchor.x * (1 - scaleX)') &&
  axes.includes('0, scaleY, anchor.y * (1 - scaleY)') &&
  axes.includes('this.multiply(s, base)'),
  'resizeSelectedAxes = per-axis S about anchor over base matrix');
check(axes.includes('scaleX * c * c + scaleY * sn * sn') &&
  axes.includes('sn * c * (scaleX - scaleY)') &&
  axes.includes('scaleX * sn * sn + scaleY * c * c') &&
  axes.includes('anchor.x - (a * anchor.x + b * anchor.y)'),
  'shell rotation: R(θ)·diag(sx,sy)·R(−θ) conjugated about anchor');

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

// --- 可执行模型：θ=90° 旋转壳的轴分解（Phase 1461 gsf.c/wtf 旋转系） ---
// 未旋转壳 (0,0)-(6,3)，绕中心 (3,1.5) 旋 +90° → 屏角（角序按壳系
// TL/TR/BR/BL 不变）TL'(4.5,-1.5) TR'(4.5,4.5) BR'(1.5,4.5) BL'(1.5,-1.5)。
const rotP = (p, cx, cy) => ({ x: cx - (p.y - cy), y: cy + (p.x - cx) });
const rc = [rotP({ x: 0, y: 0 }, 3, 1.5), rotP({ x: 6, y: 0 }, 3, 1.5),
  rotP({ x: 6, y: 3 }, 3, 1.5), rotP({ x: 0, y: 3 }, 3, 1.5)];
// 拖 TR'（idx1），anchor=对侧 BL'（idx3）；对角 D=TR'−BL'=(3,6)。
const diagV = { x: rc[1].x - rc[3].x, y: rc[1].y - rc[3].y };
const exR = { x: rc[1].x - rc[0].x, y: rc[1].y - rc[0].y };
const eyR = { x: rc[3].x - rc[0].x, y: rc[3].y - rc[0].y };
const exN = { x: exR.x / Math.hypot(exR.x, exR.y), y: exR.y / Math.hypot(exR.x, exR.y) };
const eyN = { x: eyR.x / Math.hypot(eyR.x, eyR.y), y: eyR.y / Math.hypot(eyR.x, eyR.y) };
const dAlongEx = diagV.x * exN.x + diagV.y * exN.y;
const dAlongEy = diagV.x * eyN.x + diagV.y * eyN.y;
const Xv = { x: exN.x * dAlongEx, y: exN.y * dAlongEx };
const Yv = { x: eyN.x * dAlongEy, y: eyN.y * dAlongEy };
// |Xv|=6=框宽轴幅、|Yv|=3=框高轴幅（旋转不改变轴长）。
assert(Math.abs(Math.hypot(Xv.x, Xv.y) - 6) < 1e-9, 'rotated |xAxis| = frame width');
assert(Math.abs(Math.hypot(Yv.x, Yv.y) - 3) < 1e-9, 'rotated |yAxis| = frame height');
// θ=90°：框 x 轴对屏 +y 轴、框 −y 轴对屏 +x 轴——屏 +x 拖拽只投影
// 到 y 轴向量上：Δ=(1,0) → sx=1+Δ·Xv/36=1；
// sy=1+Δ·Yv/9=1+3/9=4/3（Yv=(3,0) 屏 +x 向=远离锚侧 BL'→增宽）。
const sxR = 1 + (1 * Xv.x + 0 * Xv.y) / (Xv.x * Xv.x + Xv.y * Xv.y);
const syR = 1 + (1 * Yv.x + 0 * Yv.y) / (Yv.x * Yv.x + Yv.y * Yv.y);
assert(Math.abs(sxR - 1) < 1e-9, 'screen +x drag does not change frame-x scale');
assert(Math.abs(syR - 4 / 3) < 1e-9, 'screen +x drag = +ey 方向 → sy=4/3');
// 共轭缩放矩阵 R(θ)·diag·R(−θ)：θ=90°、sx=1/sy=4/3 → M=diag(4/3,1)
// 画布系——a=sx·c²+sy·s²=4/3、d=sx·s²+sy·c²=1、b=0。
const thC = 0, thS = 1;
const mA = 1 * thC * thC + (4 / 3) * thS * thS;
const mD = 1 * thS * thS + (4 / 3) * thC * thC;
assert(Math.abs(mA - 4 / 3) < 1e-9 && Math.abs(mD - 1) < 1e-9,
  'conjugated scale matrix R·diag·R⁻¹ maps frame axes to canvas');
n += 1;

console.log(`D02_ORIGINAL_WTF_SCALE_OK TOTAL=${n} FAILED=0`);
