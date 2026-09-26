# Phase 858 证据 — FlatBuffer 读取基座 cee 与同步信封解码层登记

## 目的

856/857 登记了写入面（u5j 工厂 + ka4 校验）。本阶段登记**读取面**：
`cee` 表读取基座、67 个表读取子类、ops 同步信封（`p9`/`mb9`），
并核对 Harmony `OriginalFlatBufferTableReader` 的等价覆盖。

## 原版证据（`decompiled_1.0.3/sources/defpackage`）

### cee —— FlatBuffer 表读取基座

- `cee.java`：vtable 初始化 `d(i, ByteBuffer)`（`I - getInt(I)` 求 vtable 起点、
  `getShort` 取 vtable 尺寸）、字段偏移 `c(i)`、UTF-8 解码 `e(i)`
  （**手写字节级 UTF-8 解码**，不经平台 charset，`zq6` 为字符集辅助）、
  向量辅助 `b/f/i`。字段 `I/J/K/L` 对应 tablePos/buffer/vtablePos/vtableSize。
- **67 个子类** `extends cee`：全部 `*e8`/`*d8` 操作表读取器 +
  实体/几何/样式子表读取器。

### 同步信封（`p9` / `mb9` / `ud7`）

- `p9.java`：`AcknowledgeAppendedOpsEvent` — `cee` 子类，vtable 字段 4 为
  `acks` 向量（元素 `vq9`），`k()` 返回向量长度；服务端对追加操作的二进制回执。
- `mb9.java`（487 行）：NoteOpsWebSocket 会话 — Socket.IO `receive-ops` 事件
  携带 JSON `expectedAckReply`（缺失时记 `Missing expectedAckReply in
  receive-ops` 网络日志）；二进制体按 `p9` 帧解析；客户端回发
  `acknowledge-appended-ops`。
- `ud7.java`：Socket.IO 事件分发 — `change-ack` 走 JSON（`be8`/`ra4`
  kotlinx 序列化），二进制体走 `jvi.e(ByteBuffer)` → `p9` 根读取。
- 信封协议为**双形态**：JSON 控制字段 + FlatBuffer 二进制操作负载。

## Harmony 侧（`note/src/main/ets/data`）

- `OriginalSyncedOperationFlatBuffer.ets`：`OriginalFlatBufferTableReader`
  — 与 `cee` 同构的 vtable 读取模型（tablePos/vtable/vtableSize/objectSize
  四元组），提供 `readUint8/16/32/64`、`readFloat32`、`readUtf8String`
  （required + 字节上限）、`readTableVectorAsRoots`、`readInlineBytes`，
  每个读取带 `requireObjectBytes` 边界门（超出 `cee.c(i)` 的裸偏移语义，
  但 fail-closed 方向一致且更严）。
- `IncomingOperationSyncCoordinator.ets`：双形态信封完整还原 —
  - `decodeOriginalOpsBundle`：field 0 = ops 表向量，field 1 = schemaVersion u16；
  - `decodeOriginalReceiveOpsEvent`：field 1 = `expectedAckReply` UTF-8
    （required，缺失即 throw ↔ 原版 Missing-expectedAckReply 日志门）、
    field 2 = schemaVersion，field 0 = ops 向量；
  - `parseOriginalSyncedOperationEnvelope`：逐操作信封
    （timestamp/siteId/clientTime/serverTime/audioTime/payloadType）。
- 读取端字节预算 `MAX_INCOMING_OPERATION_COUNT` /
  `MAX_REROOTED_OPERATION_BYTES` / `MAX_ACK_REPLY_BYTES` — 比原版更严的
  fail-closed 上界。

## 结论

FlatBuffer 读取层闭环登记完毕：`cee` 基座 + 67 读取子类 + p9/mb9/ud7
同步信封在 Harmony 侧由 `OriginalFlatBufferTableReader` +
`IncomingOperationSyncCoordinator` 等价覆盖（字段编号逐一对齐），
且解码带显式上界。远端 op-sync 传输仍 fail-closed（ADR-0794），
解码层服务于历史/回放路径。本阶段纯文档+fixture，无源改动。
