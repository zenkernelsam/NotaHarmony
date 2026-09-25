# ADR-0698：原版 Zoom 源窗口覆盖层（gfg/dfg/bfg）+ vp2px 坐标修复

- 状态：Accepted
- 日期：2026-09-25
- 关联：ADR-0695/ADR-0696/ADR-0697（Zoom View 系列）、
  `phase-750-zoom-source-window-overlay.md`

## 背景

Phase 747–749 移植了放大书写面板与控制条，但原版 `gfg` 还在**页面画布上**
渲染一个可交互的源窗口覆盖层：窗口外 8% 暗化遮罩（`iu1.b(0.08f)`）、
圆角描边框（`zoom_outline`，左下缺口）、左下角白色圆形把手 chip
（`zoom_fill`/`zoom_overlay`/`zoom_highlight`/`zoom_shadow` 五张向量图合成）。
`efg`→`dfg` 协程状态机驱动手势：窗内拖动 → `ahg.setSourceRect(Rect)`；
把手拖动 → `ahg.resizeSourceRect(Rect, float)`——矩形与 magnification
**同帧联动**（`ahg.i` mask=51 同写两值）。

## 决定

### 移植项

1. **覆盖层渲染**：`renderZoomWindowOverlay()` 在 `renderFrame` 尾部
   （restore 后的屏幕 vp 空间）绘制——8% 遮罩（四条拼接留窗）、
   2vp 圆角 1.5vp 黑描边框、左下角 24vp 白底 chip（内圆环 + 投影）。
   面板卸载（`onDisAppear`）时重绘清除。
2. **触摸路由**：`onCanvasTouch` 顶层（eyedropper 门旁）把 ZOOM 激活
   期间的全部页面触摸路由给 `onZoomWindowTouch`——与原版 pointerInput
   包裹整页、覆盖层消费全部页面触摸的语义一致。
3. **MOVE**：窗内拖动按 `screenDelta / viewport.zoom` 平移 sourceRect
   （`setSourceRect` 等价）；窗外点按窗口中心跳到触点并继续跟随拖动
   （近似：原版窗外触摸的精确策略随 `dfg` 方法体丢失）。
4. **RESIZE**：左下把手拖动——右上缘锚定，
   `mag = clamp(min(surfaceW/candW, surfaceH/candH), 1, 10)`，
   矩形尺寸随倍率联动反解（`resizeSourceRect(rect, f)` 等价）。
   倍率域 [1,10] 按视口缩放域近似（原版界值随 `dfg` 丢失）。

### 缺陷修复（Phase 747 移植 bug）

`CanvasRenderingContext2D` 默认 `LengthMetricsUnit.DEFAULT` = **vp**
绘制空间（触摸坐标/`ctx.width`/scroll 全部 vp 自洽）。Phase 747 误按
px 假设加入 `vp2px()`：面板笔画落点、源窗尺寸、前进区宽度全部放大约
2.75×（density 2.75 设备）。本 Phase 全部改回 vp 直值，并把源窗宽从
`overlayWidth`（主画布宽）修正为 `overlayWidth − 16`（面板 margin 8×2）。

### 未移植 / 近似登记

- `dfg`/`ffg`/`hhf` 的 `invokeSuspend` 均未反编译（JadxOverflow）——
  拖拽命中域、fling 阈值、精确缩放数学不可恢复，全部按文档化近似实现。
- `hhf` a=0 分支为面板拖拽柄的速度 fling 停靠（**非**旋转手势——
  早前推测已修正）；Harmony 停靠沿用 Phase 747 落点判定近似。
- `zoom_highlight`/`zoom_shadow` 高光与投影细节以简化 chip 阴影近似。

## 后果

- ZOOM 激活时页面出现可交互源窗口，移动/缩放实时联动放大面板；
  面板笔画落点恢复正确（vp 空间自洽）。
- ~~新增观察项：`sampleEyedropper` 的 `getImageData` 坐标亦乘
  density——vp 模式下 ImageData 坐标单位为 vp，该取样路径存在
  同类偏移，登记留待后续 Phase 处理。~~ **已闭环**：Phase 753
  （ADR-0701）修复——getImageData 直取 vp、物理 px 行距、24px
  邻域保持。
- 无新依赖；Replay 夹具扩展 pins 验证结构与修复并存。
