# ADR-0826 — op 事务层（fsi.s/vt9/bs1/rh8/rgc）

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3`）

- `fsi.s(bs1,bs1,clientTime,λ)` = 事务入口：λ 获 `xq9`
  上下文→逐 op 实例化→`ArrayList<uq9 索引>`→`D(4,n,4)`
  向量→`C(2)` 根 `{ops@0, schemaVersion@1=rgc.a}`→`vt9`。
- `fsi.t` = 预建 wq9 列表变体（`pq1` 包装）。
- `vt9` = `OpsBundle`（toString 实证）；`lv2.U` = uq9 向量
  物化器。
- `rgc.a` = `ar6.K.I` = **当前 schema v15**（ar6 为命名
  特性版本枚举，如 BLOCKS_AND_SHAPES_POSITION_LOCK=7）。
- `bs1` = `{site:short, base:int, AtomicInteger}` op-id
  计数器（tzc.P/Q 会话双实例=瞬态/持久空间）。
- `f8d` = `SharedNodeData`（CRDT 树节点）；`qwc.c` =
  哨兵根 `qo5(0,-1)`。

## Harmony 决策

`OpStoreImpl`/`nextOperationTimestamp` ↔ bs1/rh8.b；
ops 向量+schema 字段 ↔ bundle 编码；SharedNodeData ↔
物化态+winner 寄存器（864/866）。

## Parity 状态

等价（写管线全链实名对齐）。

## 验证

- `d02-op-transaction.mjs`：22/22 通过。
- 全量 Replay 与双 HAP 构建见 Phase 882 提交。
