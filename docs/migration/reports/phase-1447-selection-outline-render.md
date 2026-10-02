# Phase 1447 报告 — 选区轮廓渲染（sen/gsf 蚂蚁线 + 来源界式样 + 降色）

## 目标

按 1.4.2 `sen`/`gsf` 渲染证据对齐 Harmony 选区轮廓视觉：进行中轨迹蚂蚁线、完成态界式样（实/虚线按来源）、deselectMode 降色、轨迹 ghost。

## 原版取证

- `sen:513`：`selection-dash` 无限循环 600ms 线性相位 0→1；`f12=(9/zoom)*2*phase` 为全部选区虚线的相位偏移。
- `sen:1045-1052`：渲染分发仅 `isf→sen.t`、`hsf→gsf.d` 两支。
- `gsf.d`：轨迹 path、4dp/zoom 描边、9dp/zoom 虚线、相位行进、色 `a=#FF4278FF`（`z`→`c`=a@0.32）。
- `sen.t`+`gsf.g`：isf 界——`k` 非空（绘制型）实线 2dp；`k=null`（程序化）4dp 蚂蚁线；`h`（deselectMode）界色降 32%；另叠加 `gsf.d(k,close)` 32% 闭合轨迹 ghost。
- `lr` case13/`z6c` case6：`hsf.a` 指针轨迹 → `isf.k/l`。

## 缺口与修复

| 缺口 | 修复 |
|---|---|
| 进行中手势零渲染 | `renderSelectionGestureTrail`：lasso 轨迹 / rect 轮廓，4dp/zoom+9dp 虚线+相位 offset，#FF4278FF |
| 无相位动画 | `startSelectionDashTicker`：33ms tick、`phase+=tick/600`、`renderFrame()`；手势四处终止点 + `aboutToDisappear` 停止 |
| 界不分来源恒虚线 | `selectionDrawn` prop：`drawnRect!=null`→实线 2px；否则虚线 4px；固定 `#FF4278FF` |
| deselectMode 无降色 | overlay `.opacity(deselectMode?0.32:1)`（gsf.c） |
| 无轨迹 ghost | `renderSelectionTrailGhost`：闭合虚线 `globalAlpha=0.32`（lassoPoints≥3） |

## 适配登记

提交态轮廓相位不动画化（`BorderStyle` 无相位参数 + 常驻空转重绘代价）；矩形进行中呈现为矩形轮廓（原版画对角轨迹段，语义等价）。

## 验证

- 新 fixture `d02-original-selection-outline-render.mjs` 17/17。
- 全量基线与双 HAP 构建见提交注记。
