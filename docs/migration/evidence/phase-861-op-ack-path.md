# Phase 861 证据 — 操作回执（ack）路径登记

## 目的

858 登记了 `p9` AcknowledgeAppendedOpsEvent 的容器面；本阶段补全回执
路径的全部成员：`vq9` OpAck 元素、`be8`/`ra4` JSON change-ack、
`mb9` 回发契约，并核对 Harmony acknowledger 等价。

## 原版证据（`decompiled_1.0.3/sources/defpackage`）

### `vq9` — OpAck（cee 表，4 字段）

`toString`：`OpAck(id=, timestampedOp=, nakError=, duplicate=)`

| 字段 | 访问器 | 类型 |
|------|--------|------|
| 0 | `k()` | id（c(4)） |
| 1 | `m()`/`n()` | `uq9` 表 — timestampedOp（回执附原始 Op） |
| 2 | `l()` | string — nakError（拒绝原因，可空） |
| 3 | `j()` | bool — duplicate（幂等去重标记） |

`p9` 的 `acks` 向量（field 4）元素即 `vq9`：服务端对每个追加 Op
逐一回执（成功/拒绝+原因/重复）。

### `be8`/`ra4` — JSON change-ack

- `be8` = `ModifyMetadataAck`：kotlinx 序列化（`zd8.a` descriptor），
  字段 `successfulMutations` + `failedMutations`（`List<ra4>`，
  `cx6` 序列化器对）。
- `ra4` = 二元组 `{a, b}`（mutationId 对），`pa4.a` descriptor，
  `aa6.T` 双字符串写出。
- `ud7` case 0：`change-ack` 事件 → JSON → `be8` → 按
  `au1.X1/A1` 匹配本地 pending 队列（`n02.N` 完成/失败通知）。

### `mb9` 回发侧

`receive-ops` 携带 `expectedAckReply`（JSON 字段，缺失记网络日志），
客户端处理完后 `emit("acknowledge-appended-ops", expectedAckReply)`
— **回执 = 原样回显令牌**。

## Harmony 侧（`IncomingOperationSyncCoordinator.ets`）

- `IncomingOperationAcknowledger.acknowledge(expectedAckReply)` —
  回显令牌契约完整保留。
- **配对不变式门**：`(expectedAckReply===null) !== (acknowledger===null)`
  → throw — 有令牌必有回执通道、无令牌不得配回执器，对应原版
  mb9 的字段存在性契约。
- 应用成功后 `acknowledge(bundle.expectedAckReply)` — 与原版
  「处理完再回发」的次序一致。

## Parity 状态

- 等价：回显令牌 + 配对不变式 + 次序语义完整保留。
- fail-closed：`vq9` OpAck 二进制解析与 `be8` JSON change-ack 属
  服务端→客户端方向，Harmony 无活跃 socket（ADR-0794），
  登记为不移植 — 契约已在本文件留档，若日后接入需按此实现。
- `duplicate`/`nakError` 语义登记：服务端幂等去重 + 拒绝原因串。

## 结论

回执路径闭卷：OpAck 四字段、ModifyMetadataAck JSON、回显令牌契约
全部登记；Harmony 保客户端方向完整、服务端方向 fail-closed 留档。
本阶段纯文档+fixture，无源改动。
