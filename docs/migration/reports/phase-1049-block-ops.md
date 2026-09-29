# Phase 1049 报告 — 块/位置/删除操作载荷

## 范围

`rl2`/`td8` 块操作、`je8` 位置、`s83` 删除、`cz0`/`ty0`/
`ive` 枚举。纯审计。

## 原版发现

- CreateBlock 21 字段：type/corner/page/origin/rotation/
  scale/size/textWrap/enableCaption/zIndex/image/cropRect/
  webUrl/mathLatex/mathColor/paper/双向翻转/
  resizesWidthToFitText/margins/positionLocked。
- ModifyBlock 16 字段（blocks 列表+同上子集），blocks>0。
- ModifyPositions modifications>0（"Inks/Shapes/Blocks"）。
- DeleteEntities = 软删除/恢复四列表（entity/page ×
  delete/undelete）。
- 枚举：块类型 TEXT/IMAGE/MATH、圆角 SQUARE/ROUND、
  环绕 PIXEL_ALIGN/NO_WRAP。

## Harmony 决策

字段/校验/枚举逐条保留；删除-恢复模型对齐。

## 产出

- 证据：`phase-1049-block-ops.md`
- Fixture：`d02-block-ops.mjs`（12/12）
- ADR-0993；全量 Replay 见本提交。
