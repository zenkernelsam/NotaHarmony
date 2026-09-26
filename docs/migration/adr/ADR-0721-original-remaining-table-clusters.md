# ADR-0721 — 原版 1.4.2 剩余新表簇处置登记

日期：2026-09-29
状态：已登记（版本差；无 Harmony 源码变更）
证据：`docs/migration/evidence/phase-777-original-remaining-table-clusters.md`
Replay：`docs/migration/replays/d02-original-remaining-table-clusters.mjs`
上游：ADR-0711（共享库表清单）、ADR-0709、ADR-0710、ADR-0712

## 背景

Phase 767 清单内 21 张新表的最后一批：LearnDatabase 的
CompletedQuizSession/SummaryEntity 迁移、SettingsDatabase 的
模板统计四表、SearchDatabase 的识别/索引四表、
NoteBundleMetadataDatabase 的 UploadRejection。

## 决策

1. **模板本地统计**（PaperTemplateUsage/Recent/Favorite）：
   版本差·本地候选——纯本地计数/时间戳，可移植性最高；
   回移与否随模板功能组单独评审。
2. **CompletedQuizSession / SummaryEntity(takeaways)**：
   存储结构可移植，内容为 AI 生成——随 Learn 边界族登记。
3. **SearchIndexPendingUpload / SearchIndexSyncState /
   RecentGalleryTemplate / UploadRejection**：后端同步/审核队列，
   fail-closed，不虚构。
4. **InkPageRecognizer / FailedInkPage**：逐页识别器元数据，
   挂 Phase 768 HWR 引擎边界。
5. 本阶段不实现——Harmony 无对应面，全部版本差登记。

## 后果

- Phase 767 的 21 张新表至此全部完成归属映射与逐表处置。
- Replay 钉住全部 DDL 字面量 + 1.0.3 对照缺席。
