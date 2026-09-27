# Phase 890 报告 — `wa0` = `AssetMetadata` 实名

## 范围

实名资产元数据子表。纯审计，无源改动。

## 原版发现

- `wa0` = `AssetMetadata`（toString）：{assetHash:ua0,
  fileName, mimeType, fileSize:mmf}。
- `k1j.c` C(4)：ua0 内联@0、字符串×2@1-2、int 默认0@3；
  三槽必填。
- `ua0` = SHA-512 资产散列（875）；`aa6.x0` 内联写器。

## Harmony 核对

`AssetTypes.ets` 逐字段镜像；`assetHashBits` = 8×u64
word 串；`PdfBackgroundLoader` 三字段校验对齐。

## 产出

- 证据：`phase-890-assetmetadata-wa0.md`
- Fixture：`d02-assetmetadata-wa0.mjs`（14/14）
- ADR-0834；全量 Replay 763 文件绿。
