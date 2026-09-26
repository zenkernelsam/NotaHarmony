# ADR-0793 — LibraryStateWebSocket 实时同步协议归档

- 状态：已接受（整链 fail-closed）
- 证据：`docs/migration/evidence/phase-849-library-state-websocket.md`
- 回放：`docs/migration/replays/d02-library-state-websocket.mjs`（23/23）

## 决定

1. 实时同步协议面登记：Socket.IO 客户端（`hr9` manager /
   `jmg` socket 按 URI+path 复用缓存），端点
   `wss://<host>:443/metadata`。
2. 事件契约归档：构造期 `disconnect`/`invalid-credentials`/
   `lame-duck-server-shutdown`；业务订阅 `connect`/
   `connect_error`/`change-ack`/`partial-update`；发送
   `reset-sequence-id`/`change`；`change`→`change-ack`
   超时回路为可靠写通道。
3. `upsert-note` 负载 schema 封存（含 `linkShareSettings`
   必需字段告警）。
4. Harmony 无 WebSocket 同步客户端——实时推送链 fail-closed；
   `OperationSyncRepository` 仅承载本地上传/校验语义（840）。

## 后果

`defpackage` 混淆层首个高价值协议面（h69/yca/x59）恢复
登记；实时同步契约可备未来后端对接参考。
