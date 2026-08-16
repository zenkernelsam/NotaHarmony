# ADR-0233：Tape pattern 使用原版 viewport zoom raster bucket

## 状态

Accepted - Phase 255（2026-08-16）

## 背景

Phase 155 已证明 Tape pattern 的 `scaleBucket` 来自 viewport zoom，而非 Tape 笔宽；当时
`StrokeRenderer` 没有可靠 zoom 上下文，因此保留了固定 8× tile。Phase 236 之后，主画布与缩略图已有明确的
viewport/page-to-output scale 来源，可以结束该 deferred 状态。

固定 8× 虽能避免高倍 pattern source 过早模糊，但在常见 1×～2× 下持续创建远大于原版的 cell bitmap，
同一个 32 项 LRU 也无法表达原版按 zoom bucket 隔离的缓存身份。

## 决策

- 新增 `originalTapePatternScaleBucket(viewportZoom)`：先收窄为 Float32，再计算
  `round(clamp(zoom, 1, 8) × 2)`；无效平台输入安全回退 bucket 2（1×）。
- 新增 `originalTapePatternPixelSize(logicalSize, bucket)`，按 Float32 乘法和正数 round 生成 cell 像素尺寸。
- cache key 改为 `pattern:overlayColor:effectiveTapeColor:scaleBucket`；只有 FLOWERS 使用 Tape 本色。
- `StrokeCanvasPainter` 显式接收 viewport zoom，并传给 Tape renderer；不读取 brushWidth，不引入隐藏全局状态。
- `StrokeLayerManager` 的 commit、current、full composite、普通 composite 和 rebuild 路径统一透传 zoom。
- `NoteCanvasView` 的直接、有序、AudioLinked、完成层重建路径统一使用 `this.viewport.zoom`。
- `ThumbnailRenderer` 使用 `pageTransform.scale`；缩略图输出坐标已经表达目标像素缩放，不叠加当前显示 Density。
- tile 的逻辑宽高保持原版固定周期；bucket 只改变 bitmap 的像素密度。
- 保留原版同容量的 32 项 LRU 和既有 ImageBitmap eviction/dispose。

## 后果

- 1× 时 pattern cell 不再无条件按 8× 分配，缩放跨越 1.25、1.75 等阈值时才切换缓存条目。
- 主画布、临时笔迹、AudioLinked 重放、partial eraser ordered redraw 与缩略图使用一致的分桶规则。
- 完成层本身仍是页面尺寸 bitmap；高倍 zoom 下所有完成内容的最终清晰度仍受现有整页缓存架构约束。
  这一限制属于 M2-R-03/M2-R-04 的 tile renderer/设备验收边界，不在本阶段伪装为已解决。
- Phase 155 的 deferred 决策由本 ADR 收口；历史取证纠正仍保留。
