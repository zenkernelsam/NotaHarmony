# ADR-0834 — `wa0` = `AssetMetadata` 通用资产表

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3`，toString 实证）

- `wa0` = `AssetMetadata{assetHash:ua0@0(64B SHA-512 内联),
  fileName:String@1, mimeType:String@2, fileSize:mmf@3
  (默认0)}`——`k1j.c` C(4) + 三槽必填标记。
- `ua0` 经 `aa6.x0` 内联写；`dbj.c` 字符串写器。
- wa0 是 PDFAsset.metadata 与全资产引用链路的公共子表。

## Harmony 决策

`AssetTypes.ets` 逐字段镜像（assetHash/fileSize/mimeType）；
`assetHashBits` = ua0 的 8×u64 十进制 word 串；
`PdfBackgroundLoader` 运行时三字段校验对齐。

## Parity 状态

等价（四字段全实名，hash 结构逐位对应）。

## 验证

- `d02-assetmetadata-wa0.mjs`：14/14 通过。
- 全量 Replay 763 文件绿，见 Phase 890 提交。
