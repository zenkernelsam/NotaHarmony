# Phase 1014 证据 — 笔记元数据族（SyncedNoteMetadata 18 列 + ClientNoteUpdate + 标记表）

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `SyncedNoteMetadata`（18 列全表）

```sql
id BLOB PK, title TEXT?, createdAt INT, updatedAt INT,
favorite INT, lastOpened INT?, deletedAt INT?,   -- 墓碑
folderId BLOB NOT NULL,
titleOpId INT?,      -- 置标题的 op（因果引用）
thumbnailUrl TEXT?, thumbnailOpId INT?,
legacyNoteId BLOB?,  -- 迁移链
mostRecentOpTime INT?,
shared INT NOT NULL,
hasRecordings INT?,
linkAccessLevel TEXT NOT NULL,
linkPermissionScope TEXT NOT NULL,
userAccessLevel TEXT?
```

- `deletedAt` = 软删墓碑；`favorite`/`lastOpened`。
- **titleOpId/thumbnailOpId** = 最后设置者的 opId —
  因果追踪（避免旧 op 覆盖新值）。
- 共享三列：linkAccessLevel/linkPermissionScope/
  userAccessLevel（文本枚举）+ shared 标志。
- `mostRecentOpTime` = 同步游标。

## `ClientNoteUpdate`（稀疏更新）

```sql
id BLOB, type TEXT, createdAt?, favorite?,
lastOpened?, deletedAt?, folderId?,
idempotencyKey BLOB NOT NULL,
PRIMARY KEY(id, type)          -- 复合键
```

- `type` 区分更新种类（rename/favorite/move/delete…），
  每类一行幂等。

## 标记/资产表

- `DraftNote{noteId PK}` —— 草稿标记（nr1.k Flow
  监听对象之一）。
- `PermanentlyDeletedNote{noteId PK}` —— 硬删墓碑。
- `NoteAsset{assetHash BLOB PK, status TEXT,
  noteIds TEXT, fileSize INT}` —— 资产状态 +
  noteId 列表（JSON/逗号串？TEXT）。
- `LearnNoteState{noteId, lastOpenedMode TEXT}`。

## HarmonyOS 决策

- 全表平移 relationalStore；因果 opId 引用、
  sparse type 键、幂等键全部保留。
- 共享/链接列保留但云同步 fail-closed。

## 产出

- fixture `d02-note-metadata.mjs`（12 断言）。
- ADR-0958；中文报告。
