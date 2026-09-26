# Phase 850 — NoteOpsWebSocket 笔记 ops 实时通道

## 范围

`xgb` ops socket 宿主恢复（`yca.n` 工厂的第二个 socket 通道）。

## 原版发现

### 通道模型

- `/open-note/<noteId>`——**每笔记一条 socket**；
- 重建前反注册 peer-event/receive-ops/acknowledge-appended-ops；
- 100ms 间隔协程心跳/重连管线。

### 事件契约

订阅：`connect`/`connect_error`/`peer-event`/`receive-ops`/
`acknowledge-appended-ops`/`message`；
发送：ack 名经 `g5eVar.k()` 动态取（expectedAckReply，
缺失记 `Missing expectedAckReply in receive-ops`）。

### 双通道全貌（849+850）

- `/metadata`：库级元数据广播（upsert-note）；
- `/open-note/<id>`：笔记内 ops 实时收发 + 双向确认。

## Harmony 侧

**ack 契约形状已移植**：`IncomingOperationSyncCoordinator`
承载 `acknowledge(expectedAckReply)` + 契约校验；socket
传输层缺位 fail-closed。

## 验证

- Replay `d02-note-ops-websocket.mjs`：**12/12**。
- ADR-0794。**实时同步面完整闭合。**
