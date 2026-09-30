# ADR-1249：Socket.IO + OTel + Metro + TIFF

## 状态

已接受（Phase 1305）。

## 决策

- Socket.IO → Harmony `webSocket`/自实现 socket.io
  客户端（CRDT 实时传输）。
- OTel → `hiAppEvent`/`hilog`+自缓冲导出。
- Metro DI → Harmony 手动 DI。
- TIFF/SVG → `multimedia.image`。

## 理由

`io/socket`（Socket.IO+Engine.IO —— CRDT 实时协作
传输）+ `io/opentelemetry`（磁盘缓冲遥测导出）+
`dev/zacsweers/metrox`（Metro DI 编译器插件）+
`org/beyka`（TIFF）+`caverock`（SVG）—— 传输/遥测/
DI/媒体基建。

## 后果

Harmony 实时协作 = webSocket 客户端；遥测 = 平台
等价物+自缓冲；DI = 手动容器；图片格式 = multimedia
—— 基建语义保真。
