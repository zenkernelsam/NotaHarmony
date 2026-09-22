// Phase 624 — 区域选择（套索/矩形）完成后的 inside 判定改用"绘制
// 矩形"（ftc.a），而非成员元素 union。
// Original evidence (decompiled_1.0.3/sources/defpackage):
//   uw2.java case1 — 矩形/套索完成时
//     ne9Var.d(new ftc(cmbVar, cmbVar, cmbVar, null, null, false,
//       setX1, null, null, set2, set2, 896))：三个矩形字段全部 =
//     绘制区域 bounds（cmbVar = oo3 的 drawnBounds），不是命中元素
//     的 union。
//   ftc.java:83 — a() 返回 this.a（第一个矩形字段 = 绘制矩形）；
//     ftc.e()（htc.e 变换提交）以 qpi.b(this.b,…) 把绘制矩形随
//     内容一起变换再写回 a/b——壳层矩形随选区变换演化。
//   dl1.java:212 — ftc/gtc 的 inside 判定：
//     yxi.e(ftcVar.a / htcVar.a(), jE, ftcVar.d / htcVar.g(),
//       fi3.b(ftcVar.a))——测的是绘制矩形（绕其中心反旋转）。
//   语义：绘制区覆盖成员间空隙时，空隙内的按下仍判定为 inside
//   → wtc 拖拽选区；union 语义会误判 outside → 取消选区。
//   单元素命中探针（xtc.a 限定 id 集）仍先于此判定（dl1:103-120
//   同 id → stc/utc），不受本项影响。
// Harmony 对齐：SelectionState.drawnRect 在 finalizeSelection 时存
//   绘制 bounds（画布坐标，含套索路径 bounds）；inside 判定取
//   drawnRectTransformed()（state.transform 演化 = htc.e/qpi.b），
//   投影到屏幕后按 uniformSelectionCarrierRadians() 的反旋转做
//   yxi.e 等价测试；非区域选择（点选/全选/粘贴/单元素 itc）
//   drawnRect=null → 沿用元素命中/union 路径。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const TOOL = 'note/src/main/ets/rendering/SelectionTool.ets';
const VIEW = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const read = (p) => readFileSync(p, 'utf8').replace(/\r\n/g, '\n');
const tool = read(TOOL);
const view = read(VIEW);

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- SelectionState.drawnRect 字段与生命周期 ---
check(tool.includes('drawnRect: Rect2D | null;'),
  'SelectionState carries drawnRect (ftc.a parity field)');
const finIdx = tool.indexOf('finalizeSelection(');
check(finIdx > 0, 'finalizeSelection present');
const fin = tool.slice(finIdx, finIdx + 6000);
check(fin.includes('this.state.drawnRect = drawn !== null ?'),
  'finalizeSelection stores drawnBounds() into drawnRect on commit ' +
  '(uw2 case1 new ftc(cmbVar,…) parity)');
check(fin.indexOf('drawnBounds()') > 0,
  'drawn bounds = lasso-path bounds or rect bounds (oo3Var.a())');
check(tool.includes('drawnRectTransformed(): Rect2D | null'),
  'drawnRectTransformed() exposes the transform-evolved drawn rect ' +
  '(htc.e / qpi.b commit parity)');
const drtIdx = tool.indexOf('drawnRectTransformed(): Rect2D | null');
const drt = tool.slice(drtIdx, drtIdx + 500);
check(drt.includes('transformBounds(this.state.drawnRect, this.state.transform)'),
  'drawnRect transforms by the accumulated shell matrix ' +
  '(ftc.e writes a = qpi.b(b, transform))');

// --- 生命周期清理：非区域选择与选区消亡时置 null ---
check(/selectElementIds\(strokeIds[\s\S]*?this\.state\.drawnRect = null;/.test(tool),
  'selectElementIds clears drawnRect (tap/select-all/paste → union semantics)');
check(/deselect\(\): void \{[\s\S]*?this\.state\.drawnRect = null;/.test(tool),
  'deselect clears drawnRect');
check(/beginSelection\(mode[\s\S]*?this\.state\.drawnRect = null;/.test(tool),
  'beginSelection resets drawnRect');

// --- 视图侧 inside 判定：绘制矩形分支在单元素元素命中之前 ---
const pIdx = view.indexOf('private pointInSelectionRect(');
check(pIdx > 0, 'pointInSelectionRect present');
const p = view.slice(pIdx, pIdx + 3400);
check(p.includes('this.selectionTool.drawnRectTransformed()'),
  'inside-check reads the transform-evolved drawn rect (ftc.a)');
check(p.indexOf('drawnRectTransformed()') <
  p.indexOf('state.selectedGroupIds.length === 0 && total === 1'),
  'drawn-rect branch precedes the itc single-element hit-test ' +
  '(marquee-of-1 still produces ftc in uw2 case1)');
check(p.includes('uniformSelectionCarrierRadians()'),
  'drawn-rect test applies the carrier-rotation unrotate ' +
  '(yxi.e point-rotation by -d about fi3.b(a))');
check(p.includes('this.pointInRect(touch, drawnScreen)'),
  'no shell rotation → plain drawn-rect containment (yxi.e g()==null path)');
const carrierIdx = view.indexOf('private uniformSelectionCarrierRadians()');
check(carrierIdx > 0, 'uniformSelectionCarrierRadians() present');
const carrier = view.slice(carrierIdx, carrierIdx + 2600);
check(carrier.includes('e.type === ElementType.ELLIPSE ? e.rotationRadians : 0'),
  'shape carriers: only ellipse reports rotationRadians ' +
  '(polygon/line rotation baked into points)');
check(carrier.includes('this.textBlocks.find') &&
  carrier.includes('this.imageBlocks.find') &&
  carrier.includes('this.mathBlocks.find'),
  'text/image/math members contribute rotationRadians to θ detection');
check(!/selectedStrokeIds[\s\S]{0,200}radians\.add/.test(carrier) ||
  carrier.indexOf('selectedStrokeIds') < 0,
  'strokes excluded from carrier detection (baked rotation; θ via carriers)');

// --- itc/union 路径保留：drawnRect=null 时语义不变 ---
check(p.includes('this.topmostPageElementIdAt(canvasP) === id'),
  'itc element-hit branch preserved for non-marquee single selections');
check(p.includes('this.uniformRotationUnrotatedScreenRect()'),
  'union fallback preserved for non-marquee multi selections');

console.log(`D02_ORIGINAL_DRAWN_RECT_INSIDE_CHECK_OK TOTAL=${n} FAILED=0`);
