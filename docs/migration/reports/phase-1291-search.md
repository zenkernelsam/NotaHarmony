# Phase 1291 报告 — data/search 双搜索后端

## 完成内容

- `SearchIndexDatabase`（engine/room：`search`/
  `search_item` Room FTS 全文索引）+ `C$$__AppSearch__
  SearchResult`（AndroidX AppSearch codegen）——
  **双搜索后端**（Room FTS + AppSearch）；
  `SearchResult{id,text,score}` 统一命中；`SearchDatabase`
  状态 DB —— 笔记全文搜索（文本+手写+转写）。

## 产出

- evidence `phase-1291-search.md`
- fixture `d02-search.mjs`（10/10）
- ADR-1235
