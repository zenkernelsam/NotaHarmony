# Phase 1010 报告 — FTS5 引擎实现

## 范围

d6c 九方法实现、b50 AppSearch 对照。纯审计。

## 原版发现

- `d6c`：a=`DELETE FROM search_item` 全清；
  b=wkc→glc 写时折叠+klc UPSERT；c=批量删；
  d=noteId 限定 LIKE；g=FTS5 MATCH；h=COUNT(*)。
- `b50`：appsearch 引擎（getName 实证）。

## Harmony 决策

d6c 平移 relationalStore；b50 fail-closed。

## 产出

- 证据：`phase-1010-fts5-engine-impl.md`
- Fixture：`d02-fts5-engine.mjs`（12/12）
- ADR-0954；全量 Replay 见本提交。
