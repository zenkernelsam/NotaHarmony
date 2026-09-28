# ADR-0912 — 尾部写器解剖（OpsBundle/OpAck）

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `x6j.b` = vt9 OpsBundle 写器：与 q4j 同一
  ree.a+CAS 双缓冲 ops-vector 模式（第三次实证，
  为全局嵌套写规范）。
- `w6j.c` = vq9 OpAck 写器：`{opId:qo5@0 必需,
  op:uq9@1 可选内嵌（经 zq9.d 完整序列化回显）,
  errorMessage@2, acknowledged:bool@3 三态}`。
  **ack 携带 op 回显 + 错误消息**——服务端回执协议。

## Harmony 决策

OpAck 的 op 回显属服务端同步协议——Harmony 本地
ack 已 fail-closed 记录；线型语义存档。

## Parity 状态

等价（文档化差异）。

## 验证

- `d02-tail-writers.mjs`：24/24 通过。
