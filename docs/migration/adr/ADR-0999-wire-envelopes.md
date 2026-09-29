# ADR-0999 — 线级信封三层

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `uq9` Op{id,clientTime,serverTime,audioTime,payload,
  transientInteraction}。
- `vt9` OpsBundle{ops[],schemaVersion}；`r29` NoteBundle{
  noteId,legacyNoteId,editorSite,editorUserId,createdAt,
  creatorUserId,ops,schemaVersion}——双 noteId 迁移桥。
- `sdf` TransientInteraction{interactionId 必填,
  timeout 已弃}。

## Harmony 决策

三层信封字段保留；legacyNoteId 迁移桥保留；瞬态
interactionId 必填校验保留。

## Parity 状态

等价。

## 验证

- `d02-wire-envelopes.mjs`：12/12 通过。
