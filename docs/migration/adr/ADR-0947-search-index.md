# ADR-0947 — 搜索索引子系统（FTS5 外部内容 + 双引擎）

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- 两阶段索引：`IndexedTitle{noteId,title}` →
  `IndexedNote{noteId}`（INSERT...SELECT）。
- `search_item` 六项 + UNIQUE(noteId,type,subId) +
  UPSERT 写。
- `search_fts` = FTS5 外部内容表（content=
  search_item, foldedText; unicode61
  remove_diacritics 2）+ ai/ad/au 三触发器。
- `NoteIndexableChanges` 分块队列
  （noteId+processing+chunkIndex PK）。
- `FailedIndexedNote` 失败台账（errorClass/
  timestamp/indexerVersion）。
- `d6c`：FTS MATCH 查询 + `foldedText LIKE` 兜底；
  `e6c.b` = MATCH 串构造。
- `vmc` = 双引擎切换（room-fts5/appsearch），
  变更→删库重建+INDEXING 遥测。

## Harmony 决策

- relationalStore 无 FTS5：**写入侧折叠文本 +
  LIKE 查询**保结果集等价（性能降级）。
- appsearch 引擎 fail-closed。
- 索引台账/分块队列语义保留。

## Parity 状态

功能降级（FTS→LIKE）；数据语义等价。

## 验证

- `d02-search-index.mjs`：15/15 通过。
