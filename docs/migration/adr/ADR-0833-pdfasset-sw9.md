# ADR-0833 — `sw9` = `PDFAsset` + `zwd` 结构派发

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3`，toString 实证）

- `sw9` = `PDFAsset{metadata:wa0@0, layoutBehavior:xw9@1
  (默认2), totalPageCount:mmf@2(默认1), pagesConsumed:mmf@3
  (默认1), pageOffset:mmf@4(默认0), cropBoxes:qed[]@5
  (D(8,n,4) 结构向量)}`——`j7j.c` C(6) + 两槽必填标记。
- `zwd.a` = xwd 结构序列化派发：惰性注册表查 `wx4`，
  未注册→`rgc.b`+抛（fail-closed，同 ree 模式）。
- `lv2.v` = cropBoxes 向量物化器。
- `mmf` = 页数/页序值类（与 ln2.pageCount 同型复用）。

## Harmony 决策

PDF 布局槽六字段 ↔ 背景表 PDF 编码；xw9 三值缩放 ↔
PDF 适配模式；cropBoxes ↔ 裁切框编码；页数三值 ↔
PDF 页面范围状态。

## Parity 状态

等价（PDFAsset 全字段实名对齐）。

## 验证

- `d02-pdfasset-sw9.mjs`：18/18 通过。
- 全量 Replay 与双 HAP 构建见 Phase 889 提交。
