# ADR-1413：指针轴事件——Ctrl+滚轮缩放与无修饰滚动平移

## 状态

已接受（Phase 1478）——原生移植。

## 背景

原版 `bd8` 经 `b0` 状态槽向指针层发布 `uc8(isCtrlKeyDown)`；
`ip8`/`hp8`/`gp8` 过滤 `PointerEventType.Scroll` 后由
`dx(ctrl, mfc, delta)` 分发：

- Ctrl+滚轮：`mfc.D(1−Δy·0.2, 视口中心)` 缩放；
- 无修饰：`mfc.a(−50·Δ)` → `mfc.A(l()−Δ)` → 滚动位置 `pos += 50·Δ`。

Harmony ArkUI `onAxisEvent`（API17）提供同一输入面：
`getVerticalAxisValue()`（正值=滚轮向下，与 `scrollDelta` 同向）、
`getModifierKeyState(['Ctrl'])`、`getPinchAxisScaleValue()`（API21，
触控板捏合轴——原版经 scale 手势通道的等价承载）。

## 决策

在 `NoteCanvasView` Canvas 挂 `.onAxisEvent` → `onCanvasAxisEvent`：

1. **Ctrl+滚轮** → `viewport.zoomAt(画布中心, 1−Δy·0.2)`——
   锚点取视口中心（`mfc.p()/2` 等价），非光标位置。
2. **无修饰轴** → `viewport.panBy(−50·Δx, −50·Δy)`——
   Harmony `scrollY` = 内容偏移 ≡ −pos，与原版 `pos += 50·Δ`
   在视图方向上等价。
3. **捏合轴**（`pinchScale>0 && ≠1`）→ `zoomAt(event.x, event.y,
   pinchScale)`——光标锚点，等价原版捏合手势焦点。
4. `END/CANCEL` → `schedulePdfRasterRefresh(0)`（对齐手势结束
   的立即重栅化）；门集与 `onCanvasTouch` 相同。

## 替代方案与弃用

- **挂 `onMouse`/`MouseEvent.axes`**：`onMouse` 事件对象同带
  `axes`/`ctrlKey`，但 ArkUI 滚轮的规范分发通道是 `onAxisEvent`
  （BEGIN/UPDATE/END 生命周期 + 捏合轴）——选后者。
- **光标锚点缩放 Ctrl+滚轮**：原版明确用视口中心
  （`mfc.p()/2`），不改为光标锚点。
- **捏合轴不实现**：触控板捏合会静默失效，与原生体验相悖——
  纳入但登记通道差异。

## 后果

- 鼠标滚轮/触控板在画布上获得与原版一致的滚动/缩放行为；
- 轴值幅值依赖平台约定（`scrollStep` 配置），公式逐字移植，
  `clampZoom`/`factor>0` 兜底——登记为幅值差异；
- 无新权限/能力需求。
