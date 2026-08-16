# ADR-0132：按原版 scale bucket 缓存并生成 Tape pattern

## 状态

取证纠正 / Deferred - Phase 155（2026-08-12）

2026-08-16 后续状态：Phase 255 已由 ADR-0233 收口 viewport zoom 透传、Float32 半档分桶、
四字段缓存键和主画布/缩略图 consumer；本 ADR 保留为当时拒绝 brushWidth 误接的历史记录。

## 背景

原版 1.0.3 `qfe.a()` 使用 `round(clamp(viewportZoom, 1..8) * 2)` 生成 pattern cell 的
`scaleBucket`，并将 `pattern、overlayColor、FLOWERS 时的 tapeColor、scaleBucket`
组成 `mfe.PatternCellKey`。bitmap 的像素尺寸随 bucket 变化；Phase 255 复核 `qfe.java:554` 后确认
shader 会映射回固定逻辑 cell，逻辑重复周期不随 bucket 变化。

Harmony 旧实现只有固定密度 tile。进一步核对后确认原版的 bucket 来源是渲染 `zoom`，
不是 Tape 笔宽；而 Harmony 当前 `StrokeRenderer` 契约没有 zoom 参数，不能把 brushWidth
冒充 zoom 接入。

## 决策

- 撤销错误的 brushWidth bucket 实现，保持当前 tile 颜色 key 不变。
- 后续应在不破坏冻结接口的前提下，把 viewport zoom 作为渲染上下文的明确只读属性，
  再按 `round(clamp(zoom, 1..8) * 2)` 扩展 bitmap key 和像素尺寸。
- 在 zoom 进入渲染链前，不宣称 Tape scale bucket 已闭环。

## 后果

当前仍使用固定密度 tile；这不再被误写成 Tape 宽度语义。zoom 传递和设备像素验收保留为
M2-R-04/M2-R-05 后续边界。
