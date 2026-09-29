# Phase 1059 报告 — PDF 字段 op 与资产哈希

## 范围

`ee8`/`ua0`/`sw9`/`wa0`。纯审计。

## 原版发现

- ModifyPDFField = PDF 表单域写回 op：{assetHash:ua0,
  key, valueType:ww9(STRING/BOOLEAN), valueString,
  valueBoolean}；类型-nil 一致性校验。
- `ua0` = AssetHash{bits0..bits7} 8×long=64B=**SHA-512**——
  资产内容寻址（与 sha512Hash 列呼应）。
- `sw9` = PDFAsset{metadata:wa0,layoutBehavior:xw9,
  totalPageCount,pagesConsumed,pageOffset,cropBoxes[]}。
- `wa0` 校验 fileSize>0/mime/fileName 非空。

## Harmony 决策

字段/校验/哈希布局保留。

## 产出

- 证据：`phase-1059-pdf-asset-hash.md`
- Fixture：`d02-pdf-asset-hash.mjs`（12/12）
- ADR-1003；全量 Replay 见本提交。
