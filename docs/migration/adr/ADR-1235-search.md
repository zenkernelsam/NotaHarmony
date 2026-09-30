# ADR-1235：双搜索后端

## 状态

已接受（Phase 1291）。

## 决策

Room FTS → `relationalStore` FTS；AppSearch → Harmony
无对应 → 统一用 relationalStore 全文索引。

## 理由

`SearchIndexDatabase`（Room `search`/`search_item`
FTS 索引）+ `C$$__AppSearch__SearchResult`（AndroidX
AppSearch codegen）—— 双搜索引擎；`SearchResult
{id,text,score}` 统一命中。

## 后果

Harmony 搜索 = relationalStore FTS 统一 —— 全文索引
语义保真，AppSearch 后端合并。
