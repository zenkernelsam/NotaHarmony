# ADR-0949 — 索引变更队列（l79/c79）

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `c79` = NoteIndexableChanges 实体 8 字段
  `{noteId, ids, pageIds, newPageInsertLocations,
  mainBodyText, initialLoad, processing, chunkIndex}`。
- `l79` = DAO：wp1 `INSERT OR ABORT` 8 列；`b()` 两阶段
  出队（DISTINCT noteId 按 processing FALSE/TRUE）；
  逐块 `ORDER BY chunkIndex`。
- `la4` = FailedIndexedNote + `indexerVersion=2` 常量。
- `ya9` = `noteId IN(...)` 批量删。

## Harmony 决策

队列表平移；认领→处理→删除协议与分块序保留。

## Parity 状态

等价。

## 验证

- `d02-index-changes-queue.mjs`：14/14 通过。
