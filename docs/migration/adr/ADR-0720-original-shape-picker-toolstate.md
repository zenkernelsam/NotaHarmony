# ADR-0720 — 原版 1.4.2 显式形状选择器与工具状态列登记

日期：2026-09-29
状态：已登记（版本差·本地候选；无 Harmony 源码变更）
证据：`docs/migration/evidence/phase-776-original-shape-picker-toolstate.md`
Replay：`docs/migration/replays/d02-original-shape-picker-toolstate.mjs`
上游：ADR-0708、ADR-0711（ToolStateEntity 列增量）、Phase 762（brushpack）

## 背景

1.4.2 为形状工具新增**显式六选选择器**
（rectangle/ellipse/triangle/diamond/line/arrow），并将
`shapeKind`（默认 RECTANGLE）持久化进 `ToolStateEntity`；
同迁移还带来 `googleInkBrushPackId`、`penLastStandardColorWellIndex`
与 `tray_owner_id→TrayEntity` 外键级联。1.0.3 仅
hold-to-detect——`CreateShape` 内部已带 shapeKind 参数但无选择 UI。

## 决策

1. **显式形状选择器 + shapeKind 持久化**：版本差·本地候选——
   纯本地 UX+持久化，可移植；是否回移由独立 Phase 判定
   （1.0.3 基线不含此功能）。
2. `googleInkBrushPackId` 随 .brushpack 引擎簇处置；
   `penLastStandardColorWellIndex` 为本地可移植色井记忆。
3. 本阶段不实现——Harmony 保持 hold-to-detect（1.0.3 对齐）。

## 后果

- Replay 钉住六键族、1.0.3 缺席证明与三列 DDL。
- 形状工具的"先选后画"规格进入 T-042 输入。
