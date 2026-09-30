# Phase 1291 证据 — data/search 双搜索后端

来源：`data/search/{SearchResult,C$$__AppSearch__SearchResult}.java`
+ `database/SearchDatabase` + `engine/room/SearchIndexDatabase`。

## `SearchResult{id,text,score,...}` = 统一命中记录

`{int a=id, String b=text, c=score, d/e}` +
`toString("SearchResult(id=.., text=.., score=..")` —
— 统一搜索结果载体（笔记内文本/标题/手写体命中）。

## `SearchIndexDatabase`（engine/room）= Room FTS 索引

表 `search`/`search_item` —— **Room 全文索引**（FTS4
虚表存笔记文本/标题/转写 —— 本地搜索索引）。

## `C$$__AppSearch__SearchResult` = **AndroidX AppSearch**
codegen 类

`$$__AppSearch__` 前缀 = AppSearch 注解处理器生成 —
— 双后端之一（AppSearch schema/index）。

## `SearchDatabase` = 搜索状态 DB（历史/建议？）。

## 语义

**双搜索引擎** —— Room FTS（`search`/`search_item`
全文索引）+ AndroidX AppSearch（`$$__AppSearch__`
生成）—— 笔记全文搜索（文本+手写识别结果+转写）。

## Harmony 决策

Room FTS → `relationalStore` FTS/`fulltext`；
AppSearch → Harmony 无对应 → 统一用
relationalStore FTS —— 搜索语义保真，后端合并。

## 产出

- fixture `d02-search.mjs`（10 断言）。
- ADR-1235；中文报告。
