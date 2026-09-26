# Phase 849 — LibraryStateWebSocket 实时同步协议

## 范围

混淆层恢复：`h69`（socket 生命周期）+ `yca.n`（socket
工厂）+ `x59`（partial-update 处理器）。

## 原版发现

### 连接模型

Socket.IO：`yca.n("LibraryStateWebSocket", host:443,
"/metadata", …)`；`hr9` manager 按 URI 复用、`jmg` socket
按 path 缓存；构造期三事件（disconnect 终止等待者/
invalid-credentials/lame-duck-server-shutdown）。

### 业务事件面

- 订阅：connect / connect_error / change-ack /
  partial-update（解析失败有专门日志）；
- 发送：reset-sequence-id、change；
- **change→change-ack 超时回路**——可靠写确认
  （"Timeout waiting for change-ack"）。

### upsert-note 契约

`id/title/createdAt/updatedAt/isFavorited/lastOpened/
deletedAt/subjectId` + `titleOp/thumbnailOp/linkShareSettings`
op 三元组（`{timestamp, siteId}` 时钟）——链接分享设置
缺失有专门告警。

## Harmony 侧

无 Socket.IO/WebSocket 同步客户端——实时推送链整体
fail-closed；本地 `OperationSyncRepository` 保留 ops
上传/校验语义（840）。

## 验证

- Replay `d02-library-state-websocket.mjs`：**23/23**
  （连接模型、事件面、负载契约、Harmony 断言）。
- ADR-0793。**混淆层协议面首个高价值恢复。**
