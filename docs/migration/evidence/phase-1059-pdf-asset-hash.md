# Phase 1059 证据 — ee8 PDF 字段 op + ua0 AssetHash + sw9 PDFAsset

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `ee8` ModifyPDFField（表单域 op）

`{assetHash:ua0, key:String, valueType:ww9(STRING/BOOLEAN),
valueString:String?, valueBoolean:Boolean?}`

校验：valueType=STRING 但 string nil → "Type is string but
the string is nil"；BOOLEAN 同理（"Type is bool but the
bool is nil"）——类型-值一致性校验。

## `ua0` = AssetHash（xwd struct，8×long=64B）

`{bits0..bits7}`（c()..j() 各 `getLong(I+8k)`）——
**SHA-512 资产哈希**（对应 Phase 1011 sha512Hash 列）。

## `sw9` PDFAsset（cee 表）

`{metadata:wa0, layoutBehavior:xw9, totalPageCount,
pagesConsumed, pageOffset, cropBoxes:qed[]}`

- `o()`=pagesConsumed（Phase 1046 校验引用源）、
  `n()`=pageOffset、`p()`=totalPageCount、`l()`=xw9 盒模式。
- `j(slot,qed)`/`lv2.v` = cropBox 向量写/读。

## `wa0` AssetMetadata 校验

fileSize>0（"Asset file size must be larger than 0"）、
mimeType 非空、fileName 非空。

## 语义注记

- PDF 表单字段（复选框/文本域）经 ee8 写回——
  Notability PDF 批注的表单层。
- assetHash 而非 URL 引用资产——内容寻址存储。

## Harmony 决策

- ee8 字段+类型-值校验保留；ua0 64B 哈希 struct 保留；
  sw9 页消耗语义（cropBoxes 逐页）保留。

## 产出

- fixture `d02-pdf-asset-hash.mjs`（12 断言）。
- ADR-1003；中文报告。
