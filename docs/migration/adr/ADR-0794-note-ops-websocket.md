# ADR-0794 — NoteOpsWebSocket 通道归档

- 状态：已接受（ack 契约移植 / 传输 fail-closed）
- 证据：`docs/migration/evidence/phase-850-note-ops-websocket.md`
- 回放：`docs/migration/replays/d02-note-ops-websocket.mjs`（12/12）

## 决定

1. ops 实时通道登记：`/open-note/<noteId>` 每笔记一 socket；
   订阅 `peer-event`/`receive-ops`/`acknowledge-appended-ops`/
   `connect`/`connect_error`/`message`；重建前反注册三事件；
   receive-ops 的 expectedAckReply 回执（缺失时记日志）。
2. **ack 契约已移植**：Harmony `IncomingOperationSyncCoordinator`
   实现 `acknowledge(expectedAckReply)` + 契约一致性校验——
   协议形状本地保留。
3. socket 传输层 fail-closed（后端依赖）；与 849
   `/metadata` 构成双通道全貌。

## 后果

实时同步面完整闭合（元数据广播 + ops 通道）；
ack 协议形状保留使未来后端对接仅需补传输层。
