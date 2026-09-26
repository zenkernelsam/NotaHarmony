# ADR-0805 — 操作回执（ack）路径登记

## 状态

accepted（文档+fixture，无源改动）

## 原版证据（`decompiled_1.0.3`）

- `vq9` OpAck（cee 4 字段）：id@0、timestampedOp@1（uq9 回执附原
  Op）、nakError@2 可空串、duplicate@3 bool；`p9` acks 向量元素。
- `be8` ModifyMetadataAck JSON：successfulMutations/failedMutations
  （`ra4` 双串对列表）；`ud7` case 0 `change-ack` 分发 + fail-closed
  解析门。
- `mb9`：`receive-ops` 带 `expectedAckReply` → 处理后 emit
  `acknowledge-appended-ops` 原样回显。

## Harmony 决策

- `IncomingOperationAcknowledger.acknowledge(expectedAckReply)` 保留
  回显令牌契约；配对不变式（令牌↔回执器共存）+ 先应用后回执次序
  均与原版本一致。
- 服务端→客户端方向（`p9`/`vq9`/`be8` 解析）不移植：无活跃 socket
  （ADR-0794），契约在 `phase-861-op-ack-path.md` 留档备将来接入。

## Parity 状态

- 等价（客户端方向）；服务端方向 fail-closed 已留档。

## 验证

- `d02-op-ack-path.mjs`：19/19 通过。
- 全量 Replay 与双 HAP 构建见 Phase 861 报告/提交。
