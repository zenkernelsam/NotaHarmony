# ADR-0958 — 笔记元数据族

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `SyncedNoteMetadata` 18 列：墓碑 deletedAt、
  titleOpId/thumbnailOpId 因果引用、legacyNoteId
  迁移链、mostRecentOpTime 游标、共享三元组
  （linkAccessLevel/linkPermissionScope/
  userAccessLevel）+ shared/hasRecordings 标志。
- `ClientNoteUpdate`：PK(id,type) 稀疏类型化更新 +
  idempotencyKey。
- `DraftNote`/`PermanentlyDeletedNote` 标记表；
  `NoteAsset`{hash,status,noteIds,fileSize}；
  `LearnNoteState`。

## Harmony 决策

全表平移；因果/幂等/墓碑语义保留；
共享功能 fail-closed。

## Parity 状态

等价（本地语义）；共享 fail-closed。

## 验证

- `d02-note-metadata.mjs`：11/11 通过。
