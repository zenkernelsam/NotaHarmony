# ADR-1003 — PDF 字段 op 与资产哈希

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `ee8` ModifyPDFField{assetHash:ua0,key,valueType:ww9,
  valueString/valueBoolean}——类型-值一致性校验。
- `ua0` AssetHash = **64B SHA-512**（8×long bits0-7，
  xwd struct）——内容寻址资产。
- `sw9` PDFAsset{metadata:wa0,layoutBehavior:xw9,
  totalPageCount,pagesConsumed,pageOffset,cropBoxes:qed[]}。
- `wa0`：size>0/mime 非空/name 非空。

## Harmony 决策

字段/校验/哈希布局保留；内容寻址语义保留。

## Parity 状态

等价。

## 验证

- `d02-pdf-asset-hash.mjs`：12/12 通过。
