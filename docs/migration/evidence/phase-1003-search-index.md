# Phase 1003 证据 — 搜索索引子系统（FTS5 + 双引擎）

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## 表结构（Phase 992 DDL 扩展）

- `IndexedTitle{noteId BLOB PK, title TEXT}`。
- `IndexedNote{noteId BLOB PK}` —— 由
  `INSERT INTO IndexedNote SELECT noteId FROM
  IndexedTitle`（kc6:319）两阶段填充。
- `FailedIndexedNote{noteId PK, errorClass, timestamp,
  indexerVersion}` —— 失败台账，含索引器版本。
- `search_item{id AUTOINCREMENT PK, noteId, type INT,
  subId, pageId?, foldedText, rects BLOB}` +
  UNIQUE(noteId,type,subId)。
- `NoteIndexableChanges{noteId, ids, pageIds,
  newPageInsertLocations, mainBodyText, initialLoad,
  processing, chunkIndex; PK(noteId,processing,
  chunkIndex)}` —— 分块变更队列。

## FTS5 迁移（`dlc.java`，完整 DDL）

```sql
DROP TABLE IF EXISTS search_fts;
CREATE VIRTUAL TABLE search_fts USING fts5(
  foldedText,
  content='search_item',
  content_rowid='rowid',
  tokenize='unicode61 remove_diacritics 2');
CREATE TRIGGER search_item_ai AFTER INSERT ON search_item
  BEGIN INSERT INTO search_fts(rowid, foldedText)
  VALUES (new.rowid, new.foldedText); END;
CREATE TRIGGER search_item_ad AFTER DELETE ... ('delete', old.rowid, old.foldedText)
CREATE TRIGGER search_item_au AFTER UPDATE ... delete + insert
```

- **外部内容表**（external-content FTS）+ 三触发器
  同步 —— 标准 Room FTS5 方案。
- tokenizer `unicode61 remove_diacritics 2` =
  **去变音符**全文索引（折叠文本 foldedText 再经 FTS
  二重折叠）。
- `d6c.b = "room-fts5"` = 引擎标识。

## 查询路径（`d6c.java`）

- `e6c.b(query, ?)` = FTS MATCH 串构造器（转义）。
- FTS 分支：`SELECT DISTINCT si.noteId FROM search_fts
  JOIN search_item si ON si.rowid=search_fts.rowid
  WHERE search_fts MATCH ?`。
- LIKE 兜底：`SELECT DISTINCT noteId FROM search_item
  WHERE foldedText LIKE ? ESCAPE '\'`。
- `jlc`/`f6c`/`tc` = 查询 lambda/行映射。

## 引擎切换（`vmc.java`）

- SharedPreferences `active_engine` 存当前引擎名。
- 变更时：旧引擎 `"room-fts5"` →
  `context.deleteDatabase("SearchIndexDatabase")`；
  `"appsearch"` → 删 `files/appsearch` 目录。
- 记 `yn7.INDEXING` + `ep7` 遥测
  `"Search engine changed; rebuilding index from
  source"`（`xn7` kv: `search.engine=<name>`）。
- `clc` = 引擎枚举；`hmc`/`gmc` = 重建协程。

## 其余 SQL（散于 lambda）

- `sq1`：search_item UPSERT `ON CONFLICT(noteId,type,
  subId) DO UPDATE`。
- `e49`/`j79`：NoteIndexableChanges 按 processing 标志
  + chunkIndex 顺序拉取分块。
- `ya9`：按 noteId IN(...) 批量删除变更行。
- `q55`/`cfc`/`rv2`：清表 lambda。
- `bh4`：`SELECT noteId FROM IndexedNote` / `SELECT *
  FROM IndexedTitle` 导出侧。

## HarmonyOS 决策

- Harmony `relationalStore` **无 FTS5**：等价方案是
  普通 `search_item` 表 + LIKE/前缀查询（已存的
  `foldedText` 列保住语义：大小写/变音符折叠可在
  写入侧完成）。FTS 触发器/虚拟表不可平移——
  记为**功能降级**（性能差异，结果集等价）。
- 折叠文本在写入侧生成 → 查询语义一致。
- appsearch 引擎 Harmony 无对应，fail-closed。

## 产出

- fixture `d02-search-index.mjs`（16 断言）。
- ADR-0947；中文报告。
