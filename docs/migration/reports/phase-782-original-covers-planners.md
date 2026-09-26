# Phase 782 — 原版 1.4.2 封面/计划本选择器面登记

日期：2026-09-29
状态：完成（证据 + ADR + Replay；无 Harmony 源码变更）
证据：`docs/migration/evidence/phase-782-original-covers-planners.md`
ADR：`ADR-0726-original-covers-planners.md`
Replay：`d02-original-covers-planners.mjs`（7/7）

## 本阶段做了什么

为 Phase 761/763 登记的资产包补上 UI 面证据——封面预设
与计划本族的选择器字符串、偏好项与配套小增量。

## 发现

- `ui_notecovers__` 十预设键 ↔ covers/ 十份 PDF 一一对应；
  1.0.3 无此族。
- `ui_planners__`：4 封面样式 + "2026–2027 Academic Planner"
  + week-start Monday/Sunday + 入口名；1.0.3 无此族。
- `ui_notedefaults__` 标题兜底 "Note" 随 Phase 780 模板族。
- `feature_note_ruler__` 角度标签 = 已有尺子的小增量。
- Harmony 无封面/计划本面。

## 分类

- 封面选择器/计划本/week-start：版本差·本地候选。
- 尺子角度：小增量版本差。

## 验收

- Replay 7/7 绿；全量套件与双 HAP 随本阶段执行。
- 三项跟踪文档已更新。
