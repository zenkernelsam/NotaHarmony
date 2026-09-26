# Phase 850 — NoteOpsWebSocket 笔记 ops 实时通道

证据：`decompiled_1.4.2` `defpackage/xgb`（ops socket 宿主）；
工厂同 849 的 `yca.n`。

## 一、通道模型

- `yca.n("NoteOpsWebSocket", host:443, "/open-note/<noteId>", …)`
  ——**每笔记一条 socket**；
- `this.P`（dge 句柄）持有连接；重建前 K0 反注册
  `peer-event`/`receive-ops`/`acknowledge-appended-ops`。
- `this.R` 协程流：im5(100ms)+ 重连/心跳管线。

## 二、事件面

- 订阅（M0/N0）：`connect`、`connect_error`、`peer-event`、
  `receive-ops`、`acknowledge-appended-ops`、`message`；
- 发送（B0）：ack 名由 `g5eVar.k()` 取（receive-ops 的
  expectedAckReply——`AssertionError` 时记
  `Missing expectedAckReply in receive-ops`）；
- 构造期通用事件与 849 相同（disconnect/invalid-credentials/
  lame-duck）。

## 三、与 849 的关系

实时同步**双通道**结构：
- `/metadata`（LibraryStateWebSocket）：库级元数据广播
  （upsert-note 等）；
- `/open-note/<id>`（NoteOpsWebSocket）：笔记内 ops 实时
  收发（receive-ops + acknowledge-appended-ops 双向确认）。

## 四、Harmony 侧

`IncomingOperationSyncCoordinator` **保留了
expectedAckReply 确认契约**：`acknowledge(expectedAckReply)`
接口 + 契约校验（expectedAckReply 与 acknowledger 必须同
在/同缺）——原版 receive-ops→ack 回路的本地半边已移植；
仅 socket 传输层缺位（后端依赖，fail-closed）。

## 五、结论

实时同步双通道完备登记（849+850）；ops 通道的
双向确认协议（receive-ops→ack）与每笔记连接模型归档。
