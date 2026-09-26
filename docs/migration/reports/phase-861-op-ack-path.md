# Phase 861 报告 — 操作回执路径登记

## 范围

补全 op 同步回执路径：`vq9` OpAck、`be8`/`ra4` JSON change-ack、
`mb9` 回显令牌契约；核对 Harmony acknowledger 等价。纯审计。

## 原版发现

- `vq9` OpAck：id@0 + timestampedOp@1(uq9) + nakError@2 +
  duplicate@3 —— 服务端逐 Op 回执（成功/拒绝原因/幂等去重）。
- `be8` ModifyMetadataAck：successful/failedMutations 的 ra4 对列表，
  kotlinx JSON；`change-ack` 事件分发带 fail-closed 解析门。
- `expectedAckReply` 为原样回显令牌：处理后 emit
  `acknowledge-appended-ops`。

## Harmony 核对

- 回显令牌签名、配对不变式 throw 门、先应用后回执次序全部保留。
- 服务端方向解析 fail-closed 留档（无活跃 socket）。

## 产出

- 证据：`phase-861-op-ack-path.md`
- Fixture：`d02-op-ack-path.mjs`（19/19）
- ADR-0805；全量 Replay 与双 HAP 结果记录于提交。
