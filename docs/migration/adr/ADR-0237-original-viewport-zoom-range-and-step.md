# ADR-0237：恢复原版 Viewport 范围并分离按钮步进语义

## 状态

Accepted - Phase 259（2026-08-17）

## 背景

M2-R-05 的页面坐标、1000 点往返、缩放锚点和累计 pinch/pan 差分早已实现，但重放原版 1.0.3 后发现两个
仍会影响用户体验的差异：

1. Harmony 沿用早期 T-034 自定的 `[0.25,4]` viewport 范围；原版 `t0g/h3a/v0g` 明确使用
   `[0.25,10]`。
2. T-034 工具栏声明 `+/-` 每次移动 0.25，旧 `zoomStep(delta)` 却调用 `zoomAt(..., 1 + delta)`，
   使连续点击得到 `100%→125%→156%→195%`，而不是 `100%→125%→150%→175%`。

同时，repository 只校验坐标模型版本，理论上仍可把 NaN/Infinity 或范围外 zoom 写入 `note_state`。原版
`x0f` 明确拒绝持久化非有限 viewport。

## 决策

- 在 `NoteTypes.ets` 建立唯一常量 `ORIGINAL_VIEWPORT_MIN_ZOOM=0.25`、
  `ORIGINAL_VIEWPORT_MAX_ZOOM=10`，以及 zoom/scroll validator。
- `CanvasViewport.setZoomRaw()`、`zoomAt()`、`visibleCanvasRect()`、`clamp()` 与适宽入口统一复用该范围。
- `zoomAt(anchor, factor)` 保持倍率语义；按 clamp 后的实际倍率修正 scroll，继续保证屏幕锚点下页面点不动。
- 新增 `stepZoomAt(anchor, delta)` 专供 T-034 工具栏：目标值为 `oldZoom + delta`，随后换算成实际倍率并
  复用 `zoomAt()`。pinch 不调用该方法。
- `NoteRepositoryImpl.saveViewState()` 在进入全局数据库写锁前拒绝范围外/非有限 zoom，以及任一非有限 scroll。
- 恢复仍分别调用 `setZoomRaw()` 与 `setScroll()`，保持原版的字段级容错；不把坏 zoom 和合法 scroll 一起丢弃。
- 不修改 Tape 8×、Math 4× 和 PDF hard cap。它们是原版或 Harmony 资源预算中的 consumer-specific 上限，
  不是 viewport 上限。

## 后果

- pinch、恢复、适宽和工具栏都能进入原版 10× viewport，但共享同一边界，不会出现 UI 显示 1000% 而
  repository 拒绝保存的分叉。
- `+/-` 连续点击符合 T-034 的固定百分点规格，并继续使用视口中心锚点。
- 损坏状态不能从 repository 写入；历史数据库里的坏 zoom/scroll 仍在 UI 恢复时分别拒绝。
- 10×下 screen/page 数学已由 fixture 覆盖，但不代表所有 raster consumer 已在 1000% 达到原版像素质量。

## 验证契约

- `CanvasViewport.test.ets`：1000 个随机点覆盖 0.25×～10×；1000 个锚点误差 `<0.5px`；按钮序列、上下
  clamp、NaN/Infinity 与损坏 visible rect 均有断言。
- `PageCoordinateSpace.test.ets`：25/100/400/1000% 往返和 0.25×→10×锚点。
- `DatabaseHelper.test.ets`：zoom/scroll validator 的闭区间和非有限值。
- `d02-original-viewport-zoom-range.mjs`：固定原版 `t0g/h3a/v0g/x0f/d2` 证据、Harmony 接线和数值模型。
- 全量 replay、clean 后 `note@ohosTest` 与 `note@default` 必须通过；不启动设备、模拟器、虚拟机、真机或
  Hypium。

## 仍需设备验收

- 25/100/400/1000% 下真实 pinch、双指平移、按钮、适宽和恢复手感；
- 1000% 下完成层、PDF 边缘、Tape 8× bucket、Math 4× bucket、文字/形状/图片清晰度与缓存峰值；
- 快速跨上下限时的百分比显示、PDF debounce、缓存切换和 native 内存。
