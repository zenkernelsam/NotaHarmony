# Phase 1003 报告 — 搜索索引子系统

## 范围

FTS5 迁移（dlc）、查询 DAO（d6c）、引擎切换器
（vmc）、索引表族。纯审计。

## 原版发现

- `dlc`：`search_fts` FTS5 外部内容表（foldedText,
  unicode61 remove_diacritics 2）+ ai/ad/au 触发器
  —— 去变音符全文索引。
- `d6c`：MATCH JOIN 查询 + `e6c.b` 串构造 +
  `foldedText LIKE ? ESCAPE '\'` 兜底。
- `vmc`：双引擎（room-fts5/appsearch），切换时删
  SearchIndexDatabase/appsearch 目录 + INDEXING 遥测。
- 两阶段索引：IndexedTitle→IndexedNote；
  NoteIndexableChanges 分块队列（processing 标志 +
  chunkIndex）；FailedIndexedNote 台账含
  indexerVersion。
- `sq1`：search_item UPSERT。

## Harmony 决策

无 FTS5 → 折叠文本写入侧化 + LIKE 查询（结果等价，
性能降级）；appsearch fail-closed。

## 产出

- 证据：`phase-1003-search-index.md`
- Fixture：`d02-search-index.mjs`（15/15）
- ADR-0947；全量 Replay 见本提交。
