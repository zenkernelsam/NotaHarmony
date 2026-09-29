# Phase 1009 报告 — search_item 写入 + 高亮模型

## 范围

sq1 UPSERT 绑定、klc 写 DAO、alc/q1f 高亮、
rects 列实情。纯审计。

## 原版发现

- `sq1`：6 列 UPSERT，`ON CONFLICT DO UPDATE` 回写
  pageId/foldedText/rects；pageId+rects 双可空。
- `klc.b`：逐元素事务写；**实证 rects 恒 null**
  —— 列保留兼容位。
- `alc` = SearchHighlights{List}；`q1f` =
  文档态+查询键的内存高亮缓存。

## Harmony 决策

等价；rects 列恒 null 保留。

## 产出

- 证据：`phase-1009-search-writes-highlights.md`
- Fixture：`d02-search-writes.mjs`（12/12）
- ADR-0953；全量 Replay 见本提交。
