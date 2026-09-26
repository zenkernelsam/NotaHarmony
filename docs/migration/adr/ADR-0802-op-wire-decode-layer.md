# ADR-0802 — FlatBuffer 读取基座 cee 与同步信封解码层登记

## 状态

accepted（文档+fixture，无源改动）

## 原版证据（`decompiled_1.0.3`）

- `cee` 为 FlatBuffer 表读取基座：`d()` vtable 初始化、`c()` 字段偏移、
  `e()` 手写 UTF-8 解码（不经平台 charset）、`b/f/i` 向量辅助；
  67 个 `extends cee` 读取子类。
- `p9` = `AcknowledgeAppendedOpsEvent`（field 4 = `acks` 向量/`vq9` 元素）。
- `mb9` = ops Socket.IO 会话：`receive-ops`（JSON `expectedAckReply` +
  `p9` 二进制体）→ 回发 `acknowledge-appended-ops`；`ud7` 分发
  `change-ack`（JSON `be8`）与二进制 `p9` 两路。
- 证据：`phase-858-op-wire-decode-layer.md`

## Harmony 决策

- `OriginalFlatBufferTableReader` 以同构 vtable 模型实现读取，并叠加
  `requireObjectBytes` 边界门与字节上界（`MAX_INCOMING_OPERATION_COUNT`、
  `MAX_REROOTED_OPERATION_BYTES`、`MAX_ACK_REPLY_BYTES`）— 较原版裸偏移
  更严的 fail-closed 方向。
- `IncomingOperationSyncCoordinator` 还原双形态信封：ops-bundle
  （ops@0 + schemaVersion@1 u16）与 receive-ops-event
  （expectedAckReply@1 required-utf8 + schemaVersion@2 + ops@0），
  缺失 ACK 字段即 throw，对应原版缺失日志门。

## Parity 状态

- 等价：读取模型、信封字段编号、双形态分发逐一对应；解码用于
  历史/回放路径，远端实时同步仍 fail-closed（ADR-0794）。
- 差异登记：原版无显式上界，Harmony 增加三层字节/计数预算（更严，
  不改变合法负载语义）。

## 验证

- `d02-op-wire-decode-layer.mjs`：33/33 通过。
- 全量 Replay 与双 HAP 构建见 Phase 858 报告/提交。
