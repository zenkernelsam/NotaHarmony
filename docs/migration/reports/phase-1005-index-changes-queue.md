# Phase 1005 报告 — 索引变更队列

## 范围

c79 实体、l79 DAO、两阶段出队、失败台账、批量
清理。纯审计。

## 原版发现

- `c79` 8 字段实体；`l79.f` 事务入队；`b()` 双路
  DISTINCT（FALSE 待认领/TRUE 处理中）；块级消费
  `ORDER BY chunkIndex`。
- `la4` = FailedIndexedNote，`indexerVersion=2`。
- `ya9` 批量删；`nr1` 直接引用 `l79`。

## Harmony 决策

等价平移 relationalStore；协议语义保留。

## 产出

- 证据：`phase-1005-index-changes-queue.md`
- Fixture：`d02-index-changes-queue.mjs`（14/14）
- ADR-0949；全量 Replay 见本提交。
