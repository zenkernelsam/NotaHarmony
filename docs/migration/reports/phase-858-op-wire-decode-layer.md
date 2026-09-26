# Phase 858 报告 — FlatBuffer 读取基座与同步信封解码层登记

## 范围

继 856（写入面）/857（工厂+校验）后，登记读取面：`cee` 表读取基座、
67 个读取子类、ops 同步信封（p9/mb9/ud7），核对 Harmony 解码层等价。
纯审计阶段，无源改动。

## 原版发现

- `cee`：vtable 初始化/字段偏移/手写 UTF-8 解码/向量辅助，
  67 个 `extends cee` 子类构成全表读取层。
- `p9` = `AcknowledgeAppendedOpsEvent`（acks@4/vq9）。
- `mb9` ops 会话：`receive-ops`（JSON expectedAckReply + p9 二进制）
  → `acknowledge-appended-ops` 回执；`ud7` 双形态分发
  （change-ack JSON / 二进制 p9）。

## Harmony 核对

- `OriginalFlatBufferTableReader` 同构 vtable 模型 + `requireObjectBytes`
  边界门；`IncomingOperationSyncCoordinator` 还原 ops-bundle /
  receive-ops-event 双信封，字段编号逐一对齐，缺失 ACK 即 throw。
- 三层解码上界（操作数/重根字节/ACK 字节）为有意加严，合法负载语义不变。

## 产出

- 证据：`phase-858-op-wire-decode-layer.md`
- Fixture：`d02-op-wire-decode-layer.mjs`（33/33）
- ADR-0802；全量 Replay 与双 HAP 结果记录于提交。
