# Phase 992 — 完整 Room DDL 清单（`e47` 39 条 CREATE TABLE）

来源：`decompiled_1.0.3/sources/defpackage/e47.java`（Room
_Impl 生成的全部 DDL）+ `NoteBundleMetadataDatabase_Impl`。

## 1. 应用表总清单（33 张；另有 WorkManager 库表 6 张）

### 同步/ops 域（NoteBundleMetadataDatabase 5 表）
- `SyncedOpMetadata` PK(id)：17 列含 fingerprintFileLengths
  BLOB + opsChecksum + offsetsChecksum
- `ClientOp` **PK(noteId, opId)**：op BLOB=ree.b 字节
- `DeferredSyncedOps` PK(id AUTOINC)：`{noteId BLOB,
  schemaVersion INT, tableType TEXT(x63 名), fileSize,
  checksum}` ↔ u63 实体
- `DraftNote` PK(noteId)：草稿标记
- `NoteIndexableChanges` PK(noteId,processing,chunkIndex)：
  搜索索引脏块（ids/pageIds/newPageInsertLocations BLOB）

### 笔记元数据/文件夹域
- `SyncedNoteMetadata` PK(id)：linkAccessLevel/
  linkPermissionScope/userAccessLevel 共享三列
- `ClientNoteUpdate` PK(id,type)：幂等 idempotencyKey BLOB
- `PermanentlyDeletedNote`、`SyncedFolderMetadata`、
  `ClientFolderEdit`（uploaded DEFAULT false）、
  `ClientFolderDelete`（childrenHash）

### 笔记 UI 态/纸张域
- `NoteStateEntity` PK(id)：zoom/scrollOffset/
  lastCodeBlockLanguage/zoomViewSourceRect/zoomViewShown
- `PaperBackground` PK(id AUTOINC nullif)、
  `BackgroundInfo` PK(paperLineType)

### 搜索索引域
- `IndexedTitle`/`IndexedNote`/`FailedIndexedNote`
  （errorClass+indexerVersion 索引失败日志）
- `search_item` PK(id AUTOINC)：noteId/type/subId/pageId/
  foldedText/rects BLOB——FTS 条目

### 学习/测验/转写域
- `QuizSession` PK(noteId,mode)、`QuizOp` PK(opId AUTOINC)
  （sessionId/questionIndex/三类作答列）
- `LearnJob`/`LearnNoteState`/`StudyItemsInfo`/
  `SummaryEntity`（markdown）
- `transcriptions` PK(id)：`sha512Hash`/status/
  processorVersion/serverCompletedAt；
  `transcription_segments` FK→transcriptions CASCADE
  （text+start/endTime+confidence）

### 工具箱 UI 态域
- `ToolboxEntity` PK(toolbox_id)、`TrayEntity` PK(tray_id)
  FK→ToolboxEntity CASCADE、`ToolStateEntity` PK AUTOINC
  FK→TrayEntity CASCADE：toolType/trayIndex/color/
  widthSize/style/**tapePattern**/selectionIsFreehand/
  eraserIsPartial/selectedColorWell/WidthSizeWell 索引
- `FavoriteColorWellEntity`/`WidthSizeWellEntity`/
  `RecentColorWellEntity`：色板/线宽收藏

### 其他
- `Preference` PK(key)：`long_value` KV 存储
- `NoteAsset` PK(assetHash)：status/noteIds TEXT/fileSize

## 2. 关键修正（补 Phase 982）

Phase 982 只枚举了 4 个 DAO 的 18 表；`e47` 揭示完整
33 应用表 + `tableType TEXT`（x63 名存列）+
`ClientOp` 复合主键 (noteId,opId)。

## 3. Harmony 对齐

等价：全 schema 名录即 RDB 迁移对照表；外键 CASCADE
链（Tray→ToolState、transcriptions→segments）保留。

## 4. 验证

`d02-full-room-ddl.mjs` 静态断言。
