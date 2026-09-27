# Phase 890 证据 — `wa0` = `AssetMetadata` 通用资产表

## 目的

实名 `wa0`（PDFAsset.metadata 及全资产链路的通用元
数据表）。toString 实证（`decompiled_1.0.3`）。

## `wa0` = `AssetMetadata`（toString 实证）

`AssetMetadata(assetHash=, fileName=, mimeType=, fileSize=)`
——`k1j.c` 写侧 `C(4)`：

| 字段 | 访问器 | 类型 | 语义 |
|------|--------|------|------|
| 0 | `j()` | `ua0` 经 `aa6.x0` 内联 | **assetHash**：64B SHA-512 结构（8×u64） |
| 1 | `k()` | String `dbj.c` | **fileName** |
| 2 | `m()` | String `dbj.c` | **mimeType** |
| 3 | `l()` | int 默认 0（`mmf` 包装） | **fileSize** |

- 三槽必填标记：`z(iN,4)`+`z(iN,6)`+`z(iN,8)`。
- `ua0` = 875 已登记的 SHA-512 资产散列结构（`.note`
  `assets/<sha512>` 键名来源）；`aa6.x0` = 其内联写器。

## Harmony 侧

- `AssetTypes.ets`：`{assetHash, fileSize, mimeType}` 镜像；
  `ElementTypes` 注释实证 `assetHashBits` = 8 个 uint64
  十进制 word（非 SHA-256）——与 `ua0` 8×u64 逐位对应。
- `PdfBackgroundLoader`：`metadata.{assetHashBits,fileSize,
  mimeType}` 三字段校验（stat.size 比对、mime 小写比对）
  = wa0 字段语义的运行时对齐。

## 结论

资产元数据四字段全实名（hash+fileName+mimeType+fileSize）；
wa0 是 PDFAsset.metadata 与全资产引用链路的公共子表；
Harmony 已逐字段对齐。纯文档+fixture 阶段。
