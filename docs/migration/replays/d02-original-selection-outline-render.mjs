// Phase 1447 — 1.4.2 sen/gsf 选区轮廓渲染对齐。
// Original evidence (decompiled_1.4.2/sources/defpackage):
//   sen.java:513 — selection-dash 相位动画：infiniteRepeatable(600ms,linear)
//     0→1，f12=(9/zoom)*2*phase 馈入虚线相位。
//   sen.java:1045-1052 — 分发：isf → sen.t；hsf → gsf.d(j() 轨迹, open)。
//   gsf.java:d — 轨迹描边：4dp/zoom 宽、9dp/zoom 虚线、相位行进、色
//     a=qxk.e(4282546431)=#FF4278FF；z（闭合）时换 c=a@0.32。
//   gsf.java:g — isf 界：k（轨迹）非空 → 实线 2dp/zoom；k=null → 4dp 虚线
//     相位行进；isf.h（deselectMode）→ 色 c=a@0.32。
//   sen.java:t — isf 轮廓 = gsf.g(a 界) + gsf.d(k 轨迹, close, c 色) ghost。
// Harmony：进行中轨迹画布绘制（蚂蚁线相位 ticker）；完成态 ghost 静态
//   呈现；overlay 界按来源实/虚线 + deselectMode 降透明。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const CANVAS = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const OVERLAY = 'note/src/main/ets/ui/components/SelectionOverlay.ets';
const canvas = readFileSync(CANVAS, 'utf8').replace(/\r\n/g, '\n');
const overlay = readFileSync(OVERLAY, 'utf8').replace(/\r\n/g, '\n');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- 常量与场 ---
check(canvas.includes("SELECTION_OUTLINE_COLOR: string = '#FF4278FF'"),
  'outline color = gsf.a qxk.e(4282546431) = #FF4278FF');
check(canvas.includes('SELECTION_OUTLINE_DIM_ALPHA: number = 0.32'),
  'dim alpha = gsf.c = a@0.32');
check(canvas.includes('SELECTION_DASH_PERIOD_MS: number = 600'),
  'dash phase period = sen:513 600ms');

// --- 进行中轨迹：蚂蚁线虚线（4dp/zoom 描边、9dp/zoom 间隔、相位行进） ---
const trail = canvas.slice(canvas.indexOf('private renderSelectionGestureTrail('),
  canvas.indexOf('private renderSelectionTrailGhost('));
check(trail.includes('this.selectionDrawing') &&
  trail.includes('state.mode === SelectionMode.LASSO'),
  'in-progress trail gated on selectionDrawing, lasso path branch');
check(trail.includes('this.canvasCtx.setLineDash([dash, dash])') &&
  trail.includes('9.0 / zoom') && trail.includes('4.0 / zoom'),
  'trail stroke = 4dp/zoom dashed 9dp/zoom (gsf.d t1h)');
check(trail.includes('this.canvasCtx.lineDashOffset = -this.selectionDashPhase * dash * 2'),
  'trail dash offset = f12 = (9/zoom)*2*phase marching');
check(trail.includes('state.lassoPoints') &&
  trail.includes('state.rect.left'),
  'lasso trail path + rectangle outline branch');

// --- 相位 ticker：手势期 ~30fps 驱动 renderFrame ---
const ticker = canvas.slice(canvas.indexOf('private startSelectionDashTicker('),
  canvas.indexOf('private renderSelectionGestureTrail('));
check(ticker.includes('setInterval') &&
  ticker.includes('SELECTION_DASH_TICK_MS / SELECTION_DASH_PERIOD_MS') &&
  ticker.includes('this.renderFrame()'),
  'dash phase advances at tick cadence driving renderFrame');
check(canvas.indexOf('this.startSelectionDashTicker()') >
  canvas.indexOf('this.selectionDrawing = true') &&
  canvas.indexOf('this.startSelectionDashTicker()') <
  canvas.indexOf('this.selectionTool.beginSelection('),
  'ticker starts when the selection gesture begins');
check((canvas.match(/this\.stopSelectionDashTicker\(\)/g) || []).length >= 4,
  'ticker stops at finalize/below-min/cancel/aboutToDisappear');

// --- 完成态轨迹 ghost：isf.k 闭合虚线 + 32% 透明（sen.t gsf.d close） ---
const ghost = canvas.slice(canvas.indexOf('private renderSelectionTrailGhost('),
  canvas.indexOf('private renderLaserOverlay('));
check(ghost.includes('!this.selectionVisible || this.selectionDrawing'),
  'ghost only on a committed selection');
check(ghost.includes('state.lassoPoints.length < 3') &&
  ghost.includes('closePath()') &&
  ghost.includes('this.canvasCtx.globalAlpha = SELECTION_OUTLINE_DIM_ALPHA'),
  'ghost = closed dashed trail at gsf.c dim alpha');
check(canvas.indexOf('this.renderSelectionTrailGhost()') <
  canvas.indexOf('this.renderSelectionGestureTrail()') &&
  canvas.indexOf('this.renderSelectionGestureTrail()') <
  canvas.indexOf('this.renderZoomWindowOverlay();'),
  'trail renders inside the canvas transform, atop element layers');

// --- overlay 界：实/虚线按来源 + deselectMode 降透明 + 固定色 ---
check(overlay.includes('@Prop selectionDrawn'),
  'overlay carries selectionDrawn prop');
const border = overlay.slice(overlay.indexOf('.border({'),
  overlay.indexOf('.border({') + 400);
check(border.includes('this.selectionDrawn ? 2 : 4') &&
  border.includes('BorderStyle.Solid : BorderStyle.Dashed') &&
  border.includes("'#FF4278FF'"),
  'border: drawn→solid 2dp / programmatic→dashed 4dp, fixed #FF4278FF');
check(overlay.includes('.opacity(this.deselectMode ? 0.32 : 1.0)'),
  'deselectMode dims the outline to gsf.c alpha');
check(canvas.includes('this.selectionDrawnSource = state.drawnRect !== null') &&
  canvas.includes('selectionDrawn: this.selectionDrawnSource'),
  'drawn-source mirror wired from drawnRect to the overlay prop');

console.log(`D02_ORIGINAL_SELECTION_OUTLINE_OK TOTAL=${n} FAILED=0`);
