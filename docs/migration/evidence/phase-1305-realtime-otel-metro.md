# Phase 1305 证据 — Socket.IO 实时 + OTel 导出 + Metro DI

来源：`io/socket/`、`io/opentelemetry/`、`dev/zacsweers/
metrox/`、`org/beyka/`、`com/caverock/`。

## `io/socket` = Socket.IO + Engine.IO（实时 websocket）

`SocketIOException`/`EngineIOException`/`Decoding
Exception` —— Socket.IO/Engine.IO 客户端 —— **CRDT
实时协作传输层**（32-op 实时同步走 websocket）。

## `io/opentelemetry` = OpenTelemetry + 磁盘缓冲导出

`context`/`exporter`/`contrib/disk/buffering` —— OTel
遥测 + **磁盘缓冲导出器**（离线缓冲遥测→批量 flush）
—— 对应 `d4d` SEVERITY（Phase 1279）。

## `dev/zacsweers/metrox` = Metro DI

`MetroAppComponentFactory` —— **Metro**（Zac Sweers
Kotlin DI 编译器插件）应用组件工厂 —— 应用 DI 实为
Metro（`fed`/`x30` 生成代码）。

## `org/beyka/tiffbitmapfactory` = TIFF 解码

`TiffBitmapFactory`+`IProgressListener` —— TIFF 图片
导入解码。

## `com/caverock` = AndroidSVG（SVG 渲染）。

## 语义

实时协作（Socket.IO websocket）+ 可观测（OTel 磁盘
缓冲导出）+ DI（Metro 编译器插件）+ 图片格式（TIFF/
SVG/Jackson JSON）—— 传输/遥测/DI/媒体基建。

## Harmony 决策

- Socket.IO → Harmony `webSocket`/自实现 socket.io
  客户端（CRDT 实时同步传输）。
- OTel → Harmony `hiAppEvent`/`hilog`+自缓冲。
- Metro → Harmony 手动 DI。
- TIFF/SVG → `multimedia.image` 格式支持。

## 产出

- fixture `d02-realtime-otel-metro.mjs`（10 断言）。
- ADR-1249；中文报告。
