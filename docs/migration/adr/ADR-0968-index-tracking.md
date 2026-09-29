# ADR-0968 — 索引追踪三元组

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `IndexedTitle{noteId,title}` → `IndexedNote{noteId}`
  两阶段（`INSERT...SELECT noteId FROM IndexedTitle`）
  + `FailedIndexedNote{errorClass,timestamp,
  indexerVersion=2}` 失败账本。
- `l79`/`i79`/`e49` = NoteIndexableChanges chunkIndex
  DAO。

## Harmony 决策

三表平移；两阶段 INSERT-SELECT + indexerVersion=2
保留。

## Parity 状态

等价。

## 验证

- `d02-index-tracking.mjs`：11/11 通过。
