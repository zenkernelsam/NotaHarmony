# Phase 751：原版 Zoom 窗口边缘自动滚动（bfg）

> 日期：2026-09-25
> 证据：`docs/migration/evidence/phase-751-zoom-window-edge-autoscroll.md`
> ADR：`docs/migration/adr/ADR-0699-original-zoom-window-edge-autoscroll.md`
> Replay：`docs/migration/replays/d02-original-zoom-view.mjs`（112 pins，全绿）

## 背景

Phase 750 移植源窗口覆盖层时发现 `gfg` 还挂载 `bfg`——一个
withFrameNanos 帧循环协程（**可完整反编译**）：窗口手势按压期间，
指针进入画布左右 30dp 边缘带即触发视口自动平移，源窗口同步平移
保持吸附在指针下（"拖到页面边缘继续推，纸面让路"）。本 Phase 补齐。

## 原版证据（decompiled_1.0.3）

`bfg.java` `invokeSuspend` 逐帧逻辑（`afg.invoke(frameNanos)`）：

- 阈值：`30dp` 边缘带、`100dp/s` 慢速、`500dp/s` 快速（r93.j0 dp→px）；
- 判定：`fH = a76.d − pointer`（右缘距离）/`f9 = −a76.b`（左缘镜像）；
  带内 100dp/s，指针越过边缘（dist ≥ 30dp）500dp/s；
- 动作：`sh1.l(w66(−iY0))` 视口消费滚动 + `ix4.invoke(rect.k(+iY0/fK))`
  → `setSourceRect` 窗口 doc 平移（scroll/zoom 吸附）；
- 门控：覆盖层按压态（gl8 Boolean + vj8 InteractionSource）；
  `i3a.k()` 缩放系数 >0 才工作；仅横向（a76.b/.d）。

## 移植内容

| 模块 | 变更 |
|------|------|
| `NoteCanvasView.ets` | `ZOOM_EDGE_SCROLL_*` 常量组；`updateZoomWindowEdgeScroll`（Move 事件逐次评估带内外）+ `zoomWindowEdgeScrollTick`（16ms setInterval 帧循环：`panBy(-dx)` + `sourceX += dx/zoom`）+ `stopZoomWindowEdgeScroll`（手势结束/取消/换工具收尾） |

## 近似登记

- 两档速度判定映射"带内 100vp/s、越界 500vp/s"（`a76` 矩形参照系
  在反编译体内有歧义，按经典按压越界加速交互近似）；
- 16ms 定时器近似 withFrameNanos vsync 对齐；
- 视口平移沿用既有不钳制约定。

## 验证

- 专项 Replay：`D02_ORIGINAL_ZOOM_VIEW_OK pins=112`（+9 pins：常量、
  双侧边缘带、帧循环、panBy+窗口跟随、tick 门控、收尾停表、Move 接线）
- 全量 Desktop Replay：**PASS=631 FAIL=0**
- `note@ohosTest` / `note@default` HAP 构建：BUILD SUCCESSFUL
- 警告：仅既有弃用告警，无新增错误
