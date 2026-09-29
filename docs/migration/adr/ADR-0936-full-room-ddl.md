# ADR-0936 — 完整 Room DDL（33 应用表）

## 状态

accepted（文档+fixture，无源改动；修正 Phase 982 枚举）

## 原版契约（`decompiled_1.0.3` `e47.java` 实证）

- Room _Impl 共 39 条 CREATE TABLE：33 应用表 +
  WorkManager 6 库表。
- 新增关键表（Phase 982 未枚举）：
  `DeferredSyncedOps`（u63 行：noteId+schemaVersion+
  tableType TEXT(x63名)+fileSize+checksum）、
  `DraftNote`、`NoteIndexableChanges`（3 段 PK）、
  `IndexedNote`/`FailedIndexedNote`/`search_item`（FTS）、
  `QuizOp`（测验作答日志）、`transcriptions`+
  `transcription_segments`（CASCADE FK）、
  工具箱五表（Tray FK CASCADE→ToolState；
  tapePattern/eraserIsPartial 等列）、
  `Preference` KV。
- `ClientOp` 复合 PK = (noteId, opId)；
  `ClientFolderEdit/Delete.uploaded DEFAULT false`。

## Harmony 决策

等价：33 表名录+PK/FK/默认值即 Harmony RDB schema
迁移对照表。

## Parity 状态

等价（schema 级）。

## 验证

- `d02-full-room-ddl.mjs`：45/45 通过。
