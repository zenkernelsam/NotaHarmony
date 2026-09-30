# Phase 1321 证据 — 持久化历史（op-log→undo/redo）+ u64

来源：`data/{PersistentHistory,UnsignedDecimal}.ets`。

## `PersistentHistory` = op-log 派生 undo/redo

```
reducePersistentHistory(operations):  // 输入按
  operation_log (client_time, sequence) 序
  → {undo: Action[], redo: Action[]}
reducePersistentHistoryTail(...)      // 增量尾部归约
classifyPageMutation / decodePageMutationOp /
replayPageMutation + classifyPageStructureMutation —
  页变更/结构 op 分类→undo/redo 动作
```

→ **持久化撤销** —— undo/redo 栈从持久化 op 日志
归约（非内存栈）—— 跨会话可恢复（对照原版 `nnf`/
`dve`/`ekd` 内存栈，Harmony 为持久化派生）。

## `UnsignedDecimal` = u64 十进制处理

`canonical` 校验+`exhausted` 守卫 —— JS 无 u64，用
十进制字符串处理 timestamp/siteId 大整数（保真
`tmf`/`exc.A0` 的 u64 序）。

## 语义

持久化历史 = **op-log→undo/redo 归约** + u64 十进制
—— 撤销栈可持久化恢复 + 大整数保真。

## Harmony 决策

撤销 = op-log 归约（持久化）vs 原版内存栈 —— 跨会话
撤销恢复；u64 用十进制字符串 —— 语义增强+保真。

## 产出

- fixture `d02-persistent-history.mjs`（10 断言）。
- ADR-1265；中文报告。
