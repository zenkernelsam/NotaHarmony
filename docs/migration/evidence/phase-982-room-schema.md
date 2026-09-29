# Phase 982 — 完整 Room/SQLite schema 枚举（18 张应用表）

来源：`decompiled_1.0.3/sources/defpackage/{wp1,iq1,y93,ip1,na4}.java`
（`ba8/ukc` = androidx WorkManager 库表，非应用语义）

## 1. wp1/iq1 — 同步存储 DAO（7 表）

| 表 | 列（节选） |
|----|-----------|
| ClientOp | noteId, **op(blob=ree.b 字节)**, uploadImmediately, hasTitle, title, opId(gk4.v), clientTime |
| ClientNoteUpdate | id, type, createdAt, favorite, lastOpened, deletedAt, folderId, **idempotencyKey** |
| NoteAsset | assetHash, status, noteIds, fileSize |
| PermanentlyDeletedNote | noteId |
| SyncedFolderMetadata | id,parentId,updatedAt,title,color,siblingOrder,emoji |
| SyncedNoteMetadata | id,title,createdAt,updatedAt,favorite,lastOpened,deletedAt,folderId,titleOpId,thumbnailUrl,thumbnailOpId,legacyNoteId,mostRecentOpTime,shared,hasRecordings,**linkAccessLevel,linkPermissionScope,userAccessLevel** |
| SyncedOpMetadata | id,legacyId,editorSiteId,editorId,createdAt,creatorId,updatedAt,maxServerTime,title,titleOpId,**opCount,opFileSize,maxTimestamp,schemaVersion,fingerprintFileLengths,opsChecksum,offsetsChecksum** |

## 2. y93 — 学习/AI DAO（4 表）

| 表 | 列 |
|----|-----|
| LearnJob | noteId,batchId,language,creationDate,asrHashes |
| LearnNoteState | noteId,lastOpenedMode |
| StudyItemsInfo | noteId,fetchTime,textLength,handwrittenTextLength,audioHashes |
| SummaryEntity | noteId,markdown |

## 3. ip1 — 文件夹客户端 DAO（2 表）

| 表 | 列 |
|----|-----|
| ClientFolderDelete | id,deletedAt,childrenHash,uploaded,idempotencyKey |
| ClientFolderEdit | id,parentId,title,color,siblingOrder,createdAt,updatedAt,uploaded,idempotencyKey,emoji |

## 4. na4 — 笔记状态/纸张 DAO（5 表）

| 表 | 列 |
|----|-----|
| BackgroundInfo | paperLineType,spacing,hasOptions |
| IndexedTitle | noteId,title |
| NoteStateEntity | id,zoom,scrollOffset,**lastCodeBlockLanguage**,zoomViewSourceRect,zoomViewShown |
| PaperBackground | id(nullif(?,0)),paperSize,paperOrientation,backgroundColor,legacyPaperIndex,paperLineType,spacing,hasOptions |
| QuizSession | noteId,id,mode,numQuestions,numAnswered,createdAt,updatedAt,completedAt,lastViewedQuestion,questions |

## 5. 语义摘要

- 同步侧：`ClientOp`（待发 op 队列）+ `Synced*Metadata`
  （已同步基线，含 checksum 指纹）双轨。
- `idempotencyKey` 遍布 client 表——写队列幂等键。
- `NoteStateEntity` = 每笔记 UI 态（zoom/scrollOffset/
  zoomViewShown/lastCodeBlockLanguage）——Harmony 侧
  对应 note-state 存储已存在。
- `PaperBackground`/`BackgroundInfo` = 本地纸张偏好
  （与 nz9/k3a 线型 paper 解耦的本地覆盖）。

## 6. Harmony 对齐

Harmony RDB/Preferences 语义等价；schema 名录即迁移
对照表（op 字节列、blob 打包键、幂等键）。

## 7. 验证

`d02-room-schema.mjs` 静态断言。
