# Phase 767 — 原版 1.4.2 共享数据库表/列增量登记

日期：2026-09-29
状态：完成（证据 + ADR + Replay；无 Harmony 源码变更）
证据：`docs/migration/evidence/phase-767-original-shared-db-schema-delta.md`
ADR：`ADR-0711-original-shared-db-schema-delta.md`
Replay：`d02-original-shared-db-schema-delta.mjs`（9/9）

## 本阶段做了什么

Phase 764-766 覆盖 1.4.2 三个全新数据库；本阶段对两版本**全部** Room
生成 DDL 做集合 diff（`CREATE TABLE` 与 `ALTER TABLE ADD COLUMN`
字面量），补齐共享 11 库内部的表级/列级增量。

## 结果

- 1.0.3：42 表、12 ALTER；1.4.2：63 表、23 ALTER。
- **+21 表、删 0 表**：除已登记 8 表外，新增 Learn 测验归档
  （CompletedQuizSession）、远端 HWR 记账（FailedInkPage/
  InkPageRecognizer）、纸张模板商店记账四表、画廊模板最近使用、
  搜索索引同步双表、UploadRejection，及 2 张 Room 迁移临时表。
- **列增量**：QuizSession/CompletedQuizSession +评分三列与
  spacedRepetitionTotal；NoteStateEntity +isTextOnly；
  ToolStateEntity +googleInkBrushPackId/penLastStandardColorWellIndex/
  shapeKind（含 TrayEntity 外键级联）；TemplatePaperInfo +pendingSync；
  SummaryEntity +takeaways（重建迁移）。
- WorkSpec 两列属 WorkManager 库升级，非应用语义。

## 分类

ADR-0711：后端/同步簇维持 fail-closed；`isTextOnly` 与 ToolState 列
增量登记为"版本差·待审"；迁移临时表为迁移史证据。fixture 以全量
重扫方式钉住差集（树变动即红）。

## 验收

- Replay 9/9 绿；全量套件与双 HAP 随本阶段执行。
- 三项跟踪文档已更新。
