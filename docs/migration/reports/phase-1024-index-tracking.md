# Phase 1024 报告 — 索引追踪三元组

## 范围

IndexedTitle/IndexedNote/FailedIndexedNote + chunkIndex
DAO 细节。纯审计。

## 原版发现

- `IndexedTitle`(noteId,title) 暂存 → `IndexedNote`
  标记（`INSERT...SELECT`）两阶段模式。
- `FailedIndexedNote`(errorClass,timestamp,
  indexerVersion=2) 失败账本。
- `l79`/`i79`/`e49` = NoteIndexableChanges chunkIndex
  DAO；`chunkIndex`/`processing` 队列字段。

## Harmony 决策

等价平移；indexerVersion=2 移植。

## 产出

- 证据：`phase-1024-index-tracking.md`
- Fixture：`d02-index-tracking.mjs`（11/11）
- ADR-0968；全量 Replay 见本提交。
