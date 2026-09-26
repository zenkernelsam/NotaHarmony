# 原版 1.4.2 共享数据库表/列增量登记（Phase 767 证据）

> 日期：2026-09-29（Asia/Shanghai）
> 证据源：`decompiled_1.4.2` 与 `decompiled_1.0.3` 全量
>   `CREATE TABLE IF NOT EXISTS` / `ALTER TABLE ... ADD COLUMN` 字面量 diff
> 性质：1.4.2 版本差证据登记（ADR-0708 细化）；无 Harmony 代码变更。

## 一、方法

对两版本 `sources/{defpackage,com}` 全部 Room 生成 DDL 做集合 diff：

- 1.0.3：42 张表、12 条 ALTER ADD COLUMN
- 1.4.2：63 张表、23 条 ALTER ADD COLUMN
- **新增 21 张表，删除 0 张**；ALTER 净增 11 条（WorkSpec 两条为
  WorkManager 库升级，非应用语义）

## 二、新增表（已登记簇之外）

Phase 764-766 已登记：CustomTemplate、PendingTemplateDeletion、
calendar* 四表、PendingLike/PendingFollow。其余 9 个新簇：

### 1. Learn 测验归档（LearnDatabase）

```sql
CREATE TABLE `CompletedQuizSession` (`noteId` BLOB NOT NULL, `id` TEXT NOT NULL,
  `mode` TEXT NOT NULL, `numQuestions` INTEGER NOT NULL, `numAnswered` INTEGER NOT NULL,
  `createdAt` INTEGER NOT NULL, `updatedAt` INTEGER NOT NULL, `completedAt` INTEGER,
  `lastViewedQuestion` TEXT, `questions` TEXT NOT NULL,
  `spacedRepetitionTotal` INTEGER, `numCorrect`/`numIncorrect`/`numSkipped` INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY(`noteId`, `mode`))
```

（DDL 双变体 = 迁移史：评分三列后加。）

### 2. 远端 HWR 记账（识别失败队列）

```sql
CREATE TABLE `FailedInkPage` (`noteId` BLOB NOT NULL, `pageKey` TEXT NOT NULL,
  PRIMARY KEY(`noteId`, `pageKey`))
CREATE TABLE `InkPageRecognizer` (`noteId` BLOB NOT NULL, `pageKey` TEXT NOT NULL,
  `recognizer` TEXT NOT NULL, `language` TEXT NOT NULL,
  `rawContentFailed` INTEGER NOT NULL, PRIMARY KEY(`noteId`, `pageKey`))
```

与 MyScript lite 资源删除互证：1.4.2 识别记账按 (noteId,pageKey,recognizer,
language) 维度留失败队列与识别器配置——远端 HWR 的本地残迹。

### 3. 纸张模板商店记账

```sql
CREATE TABLE `FavoritePaperTemplate` (`pdfAssetPath` TEXT PK, `favoritedAt` INTEGER)
CREATE TABLE `RecentPaperTemplate` (`pdfAssetPath` TEXT PK, `usedAt` INTEGER)
CREATE TABLE `PaperTemplateUsage` (`templateUuid` TEXT PK, `useCount` INTEGER)
CREATE TABLE `TemplatePaperInfo` (`paperLineType` TEXT PK, `pendingSync` INTEGER,
  `paperSize` INTEGER, `paperOrientation` TEXT, `backgroundColor` INTEGER,
  `legacyPaperIndex` INTEGER)
```

收藏/最近/计数为本地记账；`pendingSync` 与 `templateUuid` 表明与模板云同步耦合。

### 4. 画廊模板最近使用

```sql
CREATE TABLE `RecentGalleryTemplate` (`noteId` TEXT PK, `title`, `publisherScreenname`,
  `previewImageUrl`, `likes`, `downloads`, `hasNtb`, `isRemix`, `remixCount`, `usedAt`)
```

画廊后端簇（ADR-0708 fail-closed）。

### 5. 搜索索引同步

```sql
CREATE TABLE `SearchIndexPendingUpload` (`noteId` BLOB, `type` TEXT,
  `attempts` INTEGER, PRIMARY KEY(`noteId`,`type`))
CREATE TABLE `SearchIndexSyncState` (`noteId` BLOB, `type` TEXT,
  `lastSyncedServerTime` INTEGER, `lastSyncedContentHash` INTEGER,
  PRIMARY KEY(`noteId`,`type`))
```

搜索索引上云队列 + 每笔记最后同步服务端时间/内容哈希——同步后端。

### 6. 上传拒绝登记

```sql
CREATE TABLE `UploadRejection` (`noteId` BLOB PK, `firstRejectedAt` INTEGER,
  `reported` INTEGER)
```

同步后端拒绝追踪（首次拒绝时刻 + 已上报标志）。

### 7. Room 迁移临时表（非功能面）

`_new_SummaryEntity`、`ToolStateEntity_new`——Room 重建迁移的中间表，
语义等同于"列增量"（见下）。

## 三、既有表列增量（ALTER ADD COLUMN 净增）

| 表 | 新增列 | 语义 |
|---|---|---|
| `QuizSession` | `numCorrect`/`numIncorrect`/`numSkipped` DEFAULT 0，`spacedRepetitionTotal` | 测验评分 + 间隔重复计数 |
| `CompletedQuizSession` | 同上评分三列 | 迁移补齐 |
| `NoteStateEntity` | `isTextOnly` INTEGER | 笔记"纯文本模式"状态位（1.4.2 新增笔记态） |
| `TemplatePaperInfo` | `pendingSync` INTEGER | 纸张信息待同步标志 |
| `ToolStateEntity` | `googleInkBrushPackId` INTEGER、`penLastStandardColorWellIndex` INTEGER、`shapeKind` TEXT DEFAULT 'RECTANGLE' | 笔刷包 id（Google Ink/.brushpack 对应）、颜色井位、形状工具类型持久化 |
| `SummaryEntity` | `takeaways` TEXT（重建迁移，不回填） | 摘要要点列 |
| `WorkSpec` | `next_schedule_time_override*` | WorkManager 库升级，非应用语义 |

`ToolStateEntity_new` 重建迁移同时带来 `FOREIGN KEY(tray_owner_id)
REFERENCES TrayEntity(tray_id) ON DELETE CASCADE` 与
`selectionIsFreehand`/`eraserIsPartial` 等列——1.4.2 工具状态模型
比 1.0.3 更细。

## 四、分类汇总

| 簇 | 分类 |
|---|---|
| Learn 测验评分/归档 | Learn 簇边界（ADR-0708 后端门控） |
| FailedInkPage/InkPageRecognizer | 远端 HWR 边界（与 MyScript lite 资源删除互证） |
| 纸张模板记账 | 混合：本地记账可移植，模板内容/同步属商店后端 |
| RecentGalleryTemplate | 画廊后端 fail-closed |
| 搜索索引同步/UploadRejection | 同步后端 fail-closed |
| NoteStateEntity.isTextOnly | **值得注意**：纯本地列，1.4.2 新增笔记态 |
| ToolStateEntity 列增量 | 本地可移植语义（笔刷包 id/形状类型/颜色井） |
| 迁移临时表 | 非功能，迁移史证据 |
