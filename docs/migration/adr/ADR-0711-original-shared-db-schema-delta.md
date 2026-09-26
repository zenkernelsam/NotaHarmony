# ADR-0711 — 原版 1.4.2 共享数据库表/列增量分类登记

日期：2026-09-29
状态：已登记（版本差分类清单；不引入 Harmony 源码变更）
证据：`docs/migration/evidence/phase-767-original-shared-db-schema-delta.md`
Replay：`docs/migration/replays/d02-original-shared-db-schema-delta.mjs`
上游：ADR-0708（版本差处置范围）、ADR-0709/0710（前序 schema 登记）

## 背景

Phase 764-766 登记了 1.4.2 三个**全新数据库**。本阶段对两版本**全部**
Room 生成 DDL 做集合 diff：1.4.2 共 63 表（+21，删 0）、23 条
ALTER（净增 11），其中 WorkSpec 增量为 WorkManager 库升级。

## 决策

| 增量簇 | 判定 |
|---|---|
| Learn 测验（CompletedQuizSession + QuizSession 评分列 + spacedRepetitionTotal） | Learn 簇后端门控，维持 ADR-0708 边界 |
| FailedInkPage / InkPageRecognizer | HWR 本地记账（`:hwr` 进程隔离 iink 引擎，见 ADR-0712 修正）；与 MyScript lite 资源删除互证，fail-closed |
| Favorite/Recent/Usage/TemplatePaperInfo | 混合：本地记账 schema 可移植，但内容源属模板商店；pendingSync 列示同步耦合，整体随商店边界 |
| RecentGalleryTemplate | 画廊后端 fail-closed |
| SearchIndexPendingUpload/SyncState、UploadRejection | 同步后端 fail-closed |
| NoteStateEntity.isTextOnly | 纯本地列；登记为"版本差·待审"（1.4.2 新增笔记态，回移与否待单独判定） |
| ToolStateEntity 列增量（googleInkBrushPackId、penLastStandardColorWellIndex、shapeKind、tray FK 细化） | 本地语义；登记为工具状态模型版本差，不即时回移 |
| SummaryEntity.takeaways、迁移临时表 | 迁移史证据，非功能项 |

不逐簇承诺回移；若后续 Phase 采纳任一簇，须引用本 ADR 并给出
1.0.3/1.4.2 双侧证据。

## 后果

- `d02-original-shared-db-schema-delta.mjs` 全量重扫两树并钉住
  21 表差集与 6 组 ALTER 增量；上游树变动即红。
- `isTextOnly` 与 ToolState 列增量进入"版本差·待审"队列。
- T-042 输入新增一份完整表级 diff 清单。
