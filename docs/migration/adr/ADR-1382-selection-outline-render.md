# ADR-1382: 选区轮廓渲染（sen/gsf 蚂蚁线、来源界式样、deselectMode 降色）

## 状态

已接受（2026-08，Phase 1447）

## 背景

1.4.2 选区轮廓经 `sen` 分发 + `gsf` 绘制，由 `selection-dash-phase`
600ms 无限相位动画驱动蚂蚁线：

- 进行中 `hsf`：`gsf.d(hsf.a)` —— 指针轨迹蚂蚁线虚线（4dp/zoom 描边、
  9dp/zoom 间隔、相位行进、#FF4278FF）。Harmony 此前进行中手势
  **无任何渲染反馈**——套索拖行时用户看不到已画范围。
- 完成态 `isf`：`sen.t` —— `gsf.g` 界（`k` 轨迹非空绘制型 → 实线 2dp；
  `k=null` 程序化集合 → 4dp 蚂蚁线）+ `gsf.d(k, close)` 32% 透明轨迹
  ghost；deselectMode（`h`）→ 界色降为 `c`=a@0.32。
- Harmony 覆盖层此前恒 `BorderStyle.Dashed` 1.5 accent——无来源区分、
  无降色、无轨迹 ghost。

## 决策

1. **进行中轨迹**：`renderSelectionGestureTrail` 在画布变换块内元素层
   之上绘制——lasso → `lassoPoints` 开放 path；rect → `state.rect` 轮廓；
   `4dp/zoom` 描边、`9dp/zoom` 虚线、`lineDashOffset=-phase*2*dash`、
   色 `#FF4278FF`。
2. **相位 ticker**：`startSelectionDashTicker`（33ms tick、相位按
   600ms 周期推进、每 tick `renderFrame()`）；仅 `selectionDrawing`
   期间存活——finalize/微尺寸取消/手势复位/`aboutToDisappear` 四处停。
3. **完成态 ghost**：`renderSelectionTrailGhost` 静态闭合虚线
   `globalAlpha=0.32`（lasso 且轨迹 ≥3 点）。
4. **overlay 界**：`selectionDrawn` prop（`drawnRect !== null` 镜像）→
   绘制型实线 2px / 程序化虚线 4px；固定色 `#FF4278FF`；deselectMode
   → `.opacity(0.32)`（gsf.c 等价）。

## 适配差异登记

- **提交态轮廓相位不动画化**：`BorderStyle.Dashed` 无相位参数；常驻
  选区挂 30fps 空转重绘代价过大。进行中段已动画（核心视觉信号保留）；
  提交态虚线/ghost 静态呈现。
- **矩形进行中轨迹呈现为矩形轮廓**：原版同画 `hsf.a` 指针轨迹（矩形
  手势轨迹即对角线段）；矩形轮廓表达同一"蚂蚁线勾勒选区范围"语义。
- **jsf/lsf 轮廓管线**（`gsf.h`/`gsf.b`/`gsf.c`/`mp4` 角柄渲染）留待
  后续 Phase。

## 验证

`d02-original-selection-outline-render.mjs` 17/17。
