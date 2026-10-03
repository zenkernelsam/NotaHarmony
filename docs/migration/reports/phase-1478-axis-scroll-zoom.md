# Phase 1478 报告 — 指针轴事件：Ctrl+滚轮缩放 / 滚动平移 / 触控板捏合

## 原版行为（decompiled_1.4.2）

指针层链：`bd8.b0` 发布 `uc8(isCtrlKeyDown)` → `ip8` → `hp8` →
`gp8` 过滤 `PointerEventType==6`（Scroll）→ `dx(ctrl, mfc, delta)`。

`dx.java` byte-2（单类 JADX 补齐完整 invokeSuspend）：

- **Ctrl 按住**：`f = 1.0 − Δy·0.2`；锚点 = `mfc.p()/2`
  **视口中心** → `mfc.D(f, center)` 缩放（滚轮向下 → 缩小）。
- **无修饰**：`mfc.a(round(Δx·−50), round(Δy·−50))` →
  `dfc` → `mfc.A(scope, l()−Δ)` → 滚动位置 `pos += 50·Δ`
  （`pos+` = 视图向下，由 `mfc.i()=+0.9·h` 供 PAGE_DOWN 佐证）。

## Harmony 实现

`NoteCanvasView.ets`：

- Canvas 挂 `.onAxisEvent` → `onCanvasAxisEvent`：
  - `BEGIN/UPDATE` 处理增量；`END/CANCEL` →
    `schedulePdfRasterRefresh(0)`（对齐手势结束路径）；
  - 门集对齐 `onCanvasTouch`（loaded/dataLoading/
    photoImportBusy/historyBusy/pinchSelectSession）。
- 捏合轴优先：`getPinchAxisScaleValue()>0 && ≠1` →
  `zoomAt(event.x, event.y, scale)`（光标锚点）。
- Ctrl 支：`getModifierKeyState(['Ctrl'])` →
  `zoomAt(画布中心, 1−Δy·0.2)`。
- 无修饰支：`panBy(−50·Δx, −50·Δy)`（Harmony `scrollY` =
  内容偏移 ≡ −pos）。
- 常量：`ORIGIN_AXIS_ZOOM_PER_SCROLL=0.2`、
  `ORIGIN_AXIS_SCROLL_VP=−50.0`（带原版证据注释）。

## 登记差异

- 轴值幅值为平台报告约定（vp/`scrollStep`），公式按原版逐字
  移植；`clampZoom[0.25,10]` 与 `factor>0` 兜底防异常幅值。
- 触控板捏合轴（API21）承载原版 scale 手势通道语义。

## 验证

- fixture `d02-original-axis-scroll-zoom.mjs`：**21 checks OK**
  （常量钉死、挂载、门集、END 刷新、三分支、pos↔scrollY
  可执行符号模型）。
- `note@default` assembleHap：BUILD SUCCESSFUL（编译期验证
  `AxisEvent/AxisAction/getPinchAxisScaleValue` API 可用）。
- 全量基线与 `note@ohosTest` clean 构建：见提交记录。
