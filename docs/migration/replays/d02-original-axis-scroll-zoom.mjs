// Phase 1478 — 1.4.2 指针轴事件（鼠标滚轮 / 触控板）通道。
// Original evidence (decompiled_1.4.2):
//   bd8.java — b0 = ptg 状态通道发布 uc8(isCtrlKeyDown)；
//   uc8.java — UiState(isCtrlKeyDown=...) 字符串形式坐实字段语义；
//   ip8.java — 组合 Ctrl 状态 + mfc 视口控制器，启动 hp8；
//   hp8/gp8.java — 收集指针事件，过滤 type==6(PointerEventType.Scroll)，
//     提取打包 scrollDelta 后启动 dx(ctrl, mfc, delta) 协程；
//   dx.java byte-2（单类 JADX 反编译）：
//     Ctrl 支：f = 1.0f − verticalDelta*0.2f；
//       锚点 = (mfc.p().width/2, mfc.p().height/2) 视口中心 → mfc.D(f, center)。
//     无 Ctrl 支：mfc.a(pack(round(h*−50), round(v*−50)))。
//   mfc.a→dfc byte-0 → mfc.A(scope, xxb.f(l(), Δ)) = 滚动至 pos−Δ，
//     即净位移 pos += 50·Δ；mfc.i()=+0.9·h 供 PAGE_DOWN 佐证 pos+=向下。
// Harmony 通道：onAxisEvent(AxisEvent)；getVerticalAxisValue 正值=滚轮向下
//   （OpenHarmony 轴约定，与 scrollDelta 同向）；getModifierKeyState(['Ctrl'])
//   替代 uc8 状态流；getPinchAxisScaleValue(API21) = 触控板捏合轴，
//   原版经 scale 手势通道的等价承载，锚点 = 光标位置。
//   scrollY = 内容偏移 ≡ −pos → 等价 panBy(−50·Δ)。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const CANVAS = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const canvas = readFileSync(CANVAS, 'utf8').replace(/\r\n/g, '\n');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- 常量：0.2 缩放系数 + −50 平移系数（含原版证据注释）---
check(canvas.includes('ORIGIN_AXIS_ZOOM_PER_SCROLL: number = 0.2'),
  'zoom per delta = 0.2 pinned (dx byte-2: 1−Δy*0.2f)');
check(canvas.includes('ORIGIN_AXIS_SCROLL_VP: number = -50.0'),
  'scroll factor = −50 pinned (dx: mfc.a(round(Δ*−50)))');
check(canvas.includes('mfc.A(l()−Δ)') || canvas.includes('pos += 50·Δ'),
  'constant carries mfc.A(l()−Δ)→pos+=50·Δ sign-chain evidence');

// --- Canvas 挂载 onAxisEvent ---
const mountIdx = canvas.indexOf('.onAxisEvent((event: AxisEvent)');
check(mountIdx > 0, 'Canvas mounts .onAxisEvent');
const mountBlock = canvas.slice(mountIdx, mountIdx + 300);
check(mountBlock.includes('this.onCanvasAxisEvent(event)'),
  'axis event routed to onCanvasAxisEvent');

// --- onCanvasAxisEvent 本体 ---
const fnStart = canvas.indexOf('private onCanvasAxisEvent(event: AxisEvent)');
check(fnStart > 0, 'onCanvasAxisEvent defined');
const fn = canvas.slice(fnStart, fnStart + 2400);
check(fn.includes('!this.loaded') && fn.includes('this.photoImportBusy') &&
  fn.includes('this.pinchSelectSession'),
  'busy/loaded/pinch-session gates (对齐 onCanvasTouch 门集)');
check(fn.includes('AxisAction.END') && fn.includes('AxisAction.CANCEL') &&
  fn.includes('schedulePdfRasterRefresh(0)'),
  'END/CANCEL → immediate PDF raster refresh (对齐 gesture onActionEnd)');
check(fn.includes('AxisAction.BEGIN') && fn.includes('AxisAction.UPDATE'),
  'only BEGIN/UPDATE carry deltas');
check(fn.includes("getModifierKeyState(['Ctrl'])"),
  'Ctrl 状态经 getModifierKeyState([\'Ctrl\'])（uc8 状态流等价）');

// --- 触控板捏合轴（API21）→ 光标锚点缩放 ---
check(fn.includes('getPinchAxisScaleValue') &&
  fn.includes('this.viewport.zoomAt(event.x, event.y, pinchScale)'),
  'pinch axis → zoomAt(cursor, pinchScale)（原版 scale 手势焦点等价）');

// --- Ctrl+滚轮 → 视口中心缩放 ---
const ctrlIdx = fn.indexOf('if (ctrlDown)');
check(ctrlIdx > 0, 'ctrl branch present');
const ctrlBlock = fn.slice(ctrlIdx, ctrlIdx + 400);
check(ctrlBlock.includes('this.canvasCtx.width / 2') &&
  ctrlBlock.includes('this.canvasCtx.height / 2'),
  'Ctrl+wheel anchor = viewport center (mfc.p()/2)');
check(ctrlBlock.includes('1.0 - vertical * ORIGIN_AXIS_ZOOM_PER_SCROLL'),
  'Ctrl+wheel factor = 1−Δy·0.2');

// --- 无修饰滚动 → 平移 ---
check(fn.includes('this.viewport.panBy(horizontal * ORIGIN_AXIS_SCROLL_VP') &&
  fn.includes('vertical * ORIGIN_AXIS_SCROLL_VP'),
  'no-Ctrl → panBy(−50·Δx, −50·Δy)');

// --- 可执行语义模型：原版 pos 约定 vs Harmony scrollY 约定 ---
const model = {
  // 原版：pos' = pos − deltaPacked，deltaPacked = axis·(−50)
  origPos: (pos, axisV) => pos - (axisV * -50),
  // Harmony：scrollY' = scrollY + axis·(−50)（panBy 加性）
  harScroll: (scrollY, axisV) => scrollY + axisV * -50,
  // pos ≡ −scrollY（Harmony 内容偏移约定）
};
let pos = 0, scr = 0;
// 滚轮向下（axisV=+1）×3 格
for (let i = 0; i < 3; i++) { pos = model.origPos(pos, 1); scr = model.harScroll(scr, 1); }
check(pos === 150 && scr === -150,
  'wheel down ×3: orig pos=+150 (view down), Harmony scrollY=−150 (≡−pos)');
check(-scr === pos, 'Harmony scrollY = −pos invariant holds');
// 滚轮向上 + 水平轴
pos = model.origPos(pos, -1); scr = model.harScroll(scr, -1);
check(pos === 100 && scr === -100, 'wheel up: view up (pos−50)');
const hDelta = model.harScroll(0, 0) + (0.5 * -50);
check(hDelta === -25, 'horizontal axis Δ=0.5 → content −25 (view right 25)');
// Ctrl+滚轮缩放因子
const factor = (v) => 1.0 - v * 0.2;
check(factor(1) === 0.8 && factor(-1) === 1.2,
  'Ctrl+wheel: down→zoomOut(×0.8), up→zoomIn(×1.2)');
check(Math.abs(factor(0.1) - 0.98) < 1e-9, 'fine-grained trackpad delta scales smoothly');

console.log(`d02-original-axis-scroll-zoom: ${n} checks OK`);
