// Phase 621 — itc 单元素选区的"按下点在选区内"判定改为元素命中
// 测试（dl1:317+ 的 xtc.a 路径），修正 Phase 619 误把 yxi.e 用于
// itc 的作用域。
// Original evidence (decompiled_1.0.3/sources/defpackage):
//   itc.java — implements ktc 而非 htc：单元素选区壳没有 a()/g()
//     矩形+旋转寄存器。
//   dl1.java:317+ — itc 分支：ptcVarA4 = xtcVar.a(jE, null) 直接对
//     全部元素做命中测试；结果分派——
//       null            → rtc（清除选区）
//       ntc（组成员）   → vtc（改选组）
//       otc 异 id        → vtc（改选他元素）
//       otc 同 id + 文本 → ttc（进入文本编辑）
//       otc 同 id + 其他 → wtc（拖拽）
//     即"内部"≡命中所选元素几何本身，不含任何选区矩形测试——
//     元素 AABB 内但几何外（椭圆角、旋转形状）原版判为外部。
//   dl1.java:114/182 — ftc/gtc（htc 实现）才走 yxi.e 旋转矩形测试。
// Harmony 对齐：单元素选区的 inside-check = topmostPageElementIdAt
//   (canvasP) === 所选 id——topmostPageElementIdAt 即 fu1.e/vnd 等
//   价服务（两程精确+5 容差，pointHitsShape/pointHitsAffineBlock
//   真实几何含旋转）；命中他元素/空由既有外侧探针路径完成 vtc/rtc。
//   多元素/组选区保持 yxi.e 等价（Phase 619 的 uniform-rotation 路径）。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const VIEW = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const read = (p) => readFileSync(p, 'utf8').replace(/\r\n/g, '\n');
const view = read(VIEW);

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- itc 分支：单元素选区 = 元素命中测试（xtc.a + ba6.o 等价） ---
const pIdx = view.indexOf('private pointInSelectionRect(');
check(pIdx > 0, 'pointInSelectionRect present');
const p = view.slice(pIdx, pIdx + 3400);
check(p.includes('canvasP: Point2D'),
  'pointInSelectionRect takes the canvas-space point for element hit testing');
check(p.includes('state.selectedGroupIds.length === 0 && total === 1'),
  'itc scope: single element, no selected groups (gtc is htc → rect path)');
check(p.includes('this.topmostPageElementIdAt(canvasP) === id'),
  'inside ≡ topmostPageElementIdAt hits the selected element id ' +
  '(xtc.a(jE,null) + ba6.o(itcVar.a, hit) parity)');
check(p.indexOf('topmostPageElementIdAt(canvasP) === id') <
  p.indexOf('uniformRotationUnrotatedScreenRect()'),
  'itc element-hit branch precedes the ftc/gtc yxi.e path');

// --- 单元素 id 解析覆盖全部元素种类（itc 可持有任意单元素） ---
check(p.includes('state.selectedStrokeIds.length === 1 ? state.selectedStrokeIds[0]'),
  'single-stroke selection resolves its id (strokes hit via eraserEngine)');
check(p.includes('state.selectedShapeIds.length === 1 ? state.selectedShapeIds[0]'),
  'single-shape selection resolves its id');
check(p.includes('state.selectedTextBlockIds.length === 1 ? state.selectedTextBlockIds[0]'),
  'single-text selection resolves its id');
check(p.includes('state.selectedImageIds.length === 1 ? state.selectedImageIds[0]'),
  'single-image selection resolves its id');
check(p.includes('state.selectedMathIds[0]'),
  'single-math selection resolves its id');

// --- ftc/gtc 分支保持 yxi.e 等价（Phase 619 结构不变） ---
check(p.includes('const u: UnrotatedSelectionRect | null = this.uniformRotationUnrotatedScreenRect()'),
  'multi/group selections still use the uniform-rotation unrotated-union path');
check(p.includes('this.pointInRect(touch, this.selectionRect)'),
  'AABB fallback for unrotated/mixed selections (g()==null parity)');

// --- 命中服务是真实几何（vnd/fu1.e 等价，含旋转形状） ---
const hIdx = view.indexOf('private topmostPageElementIdAt(');
check(hIdx > 0, 'topmostPageElementIdAt present');
const h = view.slice(hIdx, hIdx + 2600);
check(h.includes('pointHitsShape(point, element.data, worldTolerance)'),
  'shape hit test uses real geometry (pointHitsShape — rotation-aware)');
check(h.includes('hitOrderedElementIdAt(ordered, point, 0, whitelist)') &&
  h.includes('hitOrderedElementIdAt(ordered, point, 5, whitelist)'),
  'two-pass exact + 5-tolerance hit (fu1.e parity)');

// --- 全部四个"点在选区内"检查点携带 canvasP ---
const insideSites =
  view.split('pointInSelectionRect({ x: touch.x, y: touch.y }, canvasP)').length - 1;
check(insideSites === 4,
  `all four inside-checks pass canvasP (got ${insideSites})`);
check(!view.includes('pointInSelectionRect({ x: touch.x, y: touch.y })'),
  'no call site omits canvasP');

console.log(`D02_ORIGINAL_ITC_ELEMENT_HIT_DISPATCH_OK TOTAL=${n} FAILED=0`);
