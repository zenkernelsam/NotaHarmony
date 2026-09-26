# Phase 777 — 原版 1.4.2 剩余新表簇 DDL 全登记

日期：2026-09-29
状态：完成（证据 + ADR + Replay；无 Harmony 源码变更）
证据：`docs/migration/evidence/phase-777-original-remaining-table-clusters.md`
ADR：`ADR-0721-original-remaining-table-clusters.md`
Replay：`d02-original-remaining-table-clusters.mjs`（8/8）

## 本阶段做了什么

补完 Phase 767 共享库表清单内未覆盖的 10 张新表 + 1 张迁移重建
表的 DDL 与数据库归属——至此 21 张 1.4.2 新表全部登记完毕。

## 发现

- **归属映射**：LearnDatabase（CompletedQuizSession、
  SummaryEntity 迁移）、SettingsDatabase（PaperTemplateUsage/
  RecentPaperTemplate/FavoritePaperTemplate/RecentGalleryTemplate）、
  SearchDatabase（InkPageRecognizer/FailedInkPage/
  SearchIndexPendingUpload/SearchIndexSyncState）、
  NoteBundleMetadataDatabase（UploadRejection）。
- CompletedQuizSession 带 numCorrect/spacedRepetitionTotal
  计分列，与进行中 QuizSession 并存——Learn 测验功能存续。
  （更正：Phase 781 证明 Learn 聊天键族为键名重组非下线。）
- SummaryEntity 迁移增 takeaways 列、markdown 转可空。
- Harmony 无对应面（grep 验证），全部登记版本差。

## 分类

- 本地候选：模板统计三表。
- 存储可移植/生成后端：CompletedQuizSession、SummaryEntity。
- fail-closed 后端：SearchIndex*、RecentGalleryTemplate、UploadRejection。
- 引擎边界：InkPageRecognizer、FailedInkPage。

## 验收

- Replay 8/8 绿；全量套件与双 HAP 随本阶段执行。
- 三项跟踪文档已更新。
