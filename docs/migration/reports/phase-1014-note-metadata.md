# Phase 1014 报告 — 笔记元数据族

## 范围

SyncedNoteMetadata、ClientNoteUpdate、DraftNote、
PermanentlyDeletedNote、NoteAsset、LearnNoteState。
纯审计。

## 原版发现

- `SyncedNoteMetadata` 18 列：titleOpId/thumbnailOpId
  因果引用、deletedAt 墓碑、共享三元组 +
  mostRecentOpTime 游标 + legacyNoteId。
- `ClientNoteUpdate`：PK(id,type) 稀疏更新 +
  idempotencyKey 幂等。
- 标记表：DraftNote（nr1 Flow 监听）、
  PermanentlyDeletedNote。
- `NoteAsset{hash,status,noteIds,fileSize}` 资产台账。

## Harmony 决策

等价平移；共享列保留但 fail-closed。

## 产出

- 证据：`phase-1014-note-metadata.md`
- Fixture：`d02-note-metadata.mjs`（11/11）
- ADR-0958；全量 Replay 见本提交。
