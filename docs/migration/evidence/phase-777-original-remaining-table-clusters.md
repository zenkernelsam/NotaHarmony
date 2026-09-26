# Phase 776→777 证据：原版 1.4.2 剩余新表簇 DDL 全登记

日期：2026-09-29
性质：证据登记（补完 Phase 767 清单内未覆盖的 10 张新表 + 1 张迁移重建表；无 Harmony 源码变更）
证据源：`decompiled_1.4.2` 各 `*_Impl.java` + `defpackage/{ca3,r4a,zmb}.java` DDL 字面量；`decompiled_1.0.3` 对照（11 表中 10 张 1.0.3 缺席）。
Replay：`docs/migration/replays/d02-original-remaining-table-clusters.mjs`
ADR：`ADR-0721-original-remaining-table-clusters.md`

## 数据库归属映射（经 *_Impl 反查确认）

| 数据库 | 新增/变更表 | 边界 |
|---|---|---|
| LearnDatabase | `CompletedQuizSession`（新）、`SummaryEntity`（迁移重建） | AI 生成为后端边界；本地存储可移植 |
| SettingsDatabase | `PaperTemplateUsage`、`RecentPaperTemplate`、`FavoritePaperTemplate`、`RecentGalleryTemplate` | 前三者纯本地统计；Gallery 变体缓存服务端数据 |
| SearchDatabase | `InkPageRecognizer`、`FailedInkPage`、`SearchIndexPendingUpload`、`SearchIndexSyncState` | 识别器元数据挂 HWR 边界；索引上传为后端队列 |
| NoteBundleMetadataDatabase | `UploadRejection` | 审核拒绝跟踪（后端） |

## 关键 DDL

```sql
-- LearnDatabase：完成的测验档案（1.0.3 仅有进行中的 QuizSession，两表并存）
CREATE TABLE CompletedQuizSession(noteId BLOB, id TEXT, mode TEXT,
  numQuestions INT, numAnswered INT, createdAt INT, updatedAt INT,
  completedAt INT, lastViewedQuestion TEXT, questions TEXT,
  spacedRepetitionTotal INT, numCorrect INT DEFAULT 0,
  PRIMARY KEY(noteId, mode));
-- SummaryEntity 迁移：1.0.3 markdown NOT NULL → 1.4.2 增 takeaways 列、markdown 转可空
CREATE TABLE SummaryEntity(noteId BLOB PK, markdown TEXT, takeaways TEXT);

-- SettingsDatabase：模板本地统计族
CREATE TABLE PaperTemplateUsage(templateUuid TEXT PK, useCount INT);
CREATE TABLE RecentPaperTemplate(pdfAssetPath TEXT PK, usedAt INT);
CREATE TABLE FavoritePaperTemplate(pdfAssetPath TEXT PK, favoritedAt INT);
CREATE TABLE RecentGalleryTemplate(noteId TEXT PK, title TEXT,
  publisherScreenname TEXT, previewImageUrl TEXT, likes INT,
  downloads INT, hasNtb INT, isRemix INT, remixCount INT, usedAt INT);

-- SearchDatabase：识别/索引队列族
CREATE TABLE InkPageRecognizer(noteId BLOB, pageKey TEXT, recognizer TEXT,
  language TEXT, rawContentFailed INT, PRIMARY KEY(noteId, pageKey));
CREATE TABLE FailedInkPage(noteId BLOB, pageKey TEXT, PRIMARY KEY(noteId,pageKey));
CREATE TABLE SearchIndexPendingUpload(noteId BLOB, type TEXT, attempts INT,
  PRIMARY KEY(noteId, type));
CREATE TABLE SearchIndexSyncState(noteId BLOB, type TEXT,
  lastSyncedServerTime INT, lastSyncedContentHash INT,
  PRIMARY KEY(noteId, type));

-- NoteBundleMetadataDatabase：上传拒绝跟踪
CREATE TABLE UploadRejection(noteId BLOB PK, firstRejectedAt INT, reported INT);
```

## 语义推断

- `CompletedQuizSession` 相对 1.0.3 `QuizSession` 新增 `numCorrect`/
  `spacedRepetitionTotal`——间隔重复计分档案，证明 1.4.2 Learn
  保留测验而非整体下线（下线的是 AI 聊天键族，见 Phase 760）。
- `InkPageRecognizer.recognizer`/`language` + `FailedInkPage` =
  逐页识别器选择与失败标记，配合 Phase 768 的 `:hwr` 服务。
- `SearchIndex{PendingUpload,SyncState}` = 服务端全文索引上传队列
  （重试计数 + 内容哈希去重）——跨设备搜索依赖后端。
- `UploadRejection` = 社区发布审核拒绝（配合 Phase 774 队列）。

## 分类结论

- 纯本地候选：PaperTemplateUsage/RecentPaperTemplate/
  FavoritePaperTemplate（模板使用统计，本地可移植）。
- 存储可移植/生成后端：CompletedQuizSession、SummaryEntity。
- 后端边界：SearchIndex*、RecentGalleryTemplate、UploadRejection。
- 引擎边界挂接：InkPageRecognizer、FailedInkPage。
- Harmony 现状：无对应面（grep 验证）；全部登记版本差，不实现。
