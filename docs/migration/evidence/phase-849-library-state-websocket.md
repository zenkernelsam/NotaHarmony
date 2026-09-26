# Phase 849 — LibraryStateWebSocket 实时同步协议

证据：`decompiled_1.4.2` `defpackage/h69`（Socket 生命周期
宿主）+ `defpackage/yca.n`（socket 工厂）+ `x59`（partial-update
处理器）。

## 一、连接模型

- 工厂：`yca.n("LibraryStateWebSocket", zu2.n(zq.g, ":443"),
  "/metadata", …)`——Socket.IO 客户端，每 URI 一个 `hr9`
  manager，per-path `jmg` socket 缓存于 `R` map；
- 路径 `/metadata`，TLS :443；
- 构造期注册通用事件：`disconnect`（每个连接段收到即发
  `Socket disconnected` IOException 终止等待者）、
  `invalid-credentials`（凭据失效）、
  `lame-duck-server-shutdown`（服务优雅停机信号）。

## 二、LibraryState 业务事件

- 订阅：`connect`（重连恢复）、`connect_error`、
  `change-ack`、`partial-update`（`x59` 协程处理，
  解析失败记 `Failed to parse partial-update` 日志）；
- 发送：`reset-sequence-id`（无参）、`change`（JSONObject）；
- `change` 发出后等待 `change-ack`，超时抛
  `IOException("Timeout waiting for change-ack")`——
  带超时的可靠写回路。

## 三、upsert-note 负载 schema（`h69.e`）

```json
{ "id": "...", "type": "upsert-note",
  "title": "...", "createdAt": int, "updatedAt": int,
  "isFavorited": bool, "lastOpened": long|null,
  "deletedAt": long|null, "subjectId": "...",
  "titleOp": {"timestamp": int, "siteId": int},
  "thumbnailOp": {...}, "linkShareSettings": {...} }
```

`linkShareSettings` 缺失 → `Missing linkShareSettings in
upsert-note` 告警（字段为契约必需项）。

## 四、Harmony 侧

**无 Socket.IO/WebSocket 同步客户端**——`OperationSyncRepository`
本地面存在（840 校验语义），实时推送链整体 fail-closed
（后端依赖）。

## 五、结论

实时同步协议面登记：socket.io 连接管理（manager/socket
复用缓存）+ 4 订阅事件 + 2 发送事件 + ack 超时回路 +
upsert-note 负载契约。Harmony fail-closed。
