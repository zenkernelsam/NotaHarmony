# Phase 776 — 原版 1.4.2 显式形状选择器与工具状态列登记

日期：2026-09-29
状态：完成（证据 + ADR + Replay；无 Harmony 源码变更）
证据：`docs/migration/evidence/phase-776-original-shape-picker-toolstate.md`
ADR：`ADR-0720-original-shape-picker-toolstate.md`
Replay：`d02-original-shape-picker-toolstate.mjs`（6/6）

## 本阶段做了什么

细化 Phase 767 的 ToolStateEntity 列增量语义：查明
`shapeKind`/`googleInkBrushPackId`/`penLastStandardColorWellIndex`
对应的产品功能与 UI 面。

## 发现

- 1.4.2 新增**显式形状选择器**：`ui_tools__shape_{rectangle,
  ellipse,triangle,diamond,line,arrow}` 六键——先选形状再画，
  `shapeKind` 默认 RECTANGLE 持久化于 ToolStateEntity。
- 1.0.3 无此族键、`CreateShape` 已内部携带 shapeKind 参数——
  识别管线同构，差异在选择 UI 与持久化。
- `googleInkBrushPackId` 绑定 .brushpack 引擎（Phase 762）；
  `penLastStandardColorWellIndex` 为每笔色井记忆；
  迁移附加 `tray_owner_id→TrayEntity` 级联 +
  selectionIsFreehand/eraserIsPartial/tapePattern 列。

## 分类

- 显式选择器 + shapeKind：版本差·本地候选（回移待判定）。
- Harmony 保持 hold-to-detect（1.0.3 对齐），本阶段不实现。

## 验收

- Replay 6/6 绿；全量套件与双 HAP 随本阶段执行。
- 三项跟踪文档已更新。
