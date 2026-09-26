# ADR-0726 — 原版 1.4.2 封面/计划本选择器面登记

日期：2026-09-29
状态：已登记（版本差·本地候选；无 Harmony 源码变更）
证据：`docs/migration/evidence/phase-782-original-covers-planners.md`
Replay：`docs/migration/replays/d02-original-covers-planners.mjs`
上游：ADR-0708（papertemplates 资产）、Phase 763（covers 资产）

## 背景

Phase 761/763 登记了 covers/ 与 papertemplates/ 资产包；
本阶段补其 UI 面：10 个具名封面预设 + 计划本族
（4 封面样式、学年计划本、week-start 开关）+ 标题兜底值 +
尺子角度读数。

## 决策

1. **封面选择器 / 计划本 / week-start**：版本差·本地候选——
   资产驱动 + 偏好开关，无后端依赖。
2. 尺子角度读数：已有尺功能的小增量版本差。
3. 本阶段不实现——Harmony 无对应面。

## 后果

- 资产→UI 面闭环：covers 10 PDF ↔ preset_* 十键一一对应
  已被 Replay 钉住。
- 计划本/封面规格进入 T-042 输入。
