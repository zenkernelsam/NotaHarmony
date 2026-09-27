# Phase 889 报告 — `sw9` = `PDFAsset` 实名

## 范围

实名 nz9 字段1 的 PDF 布局全部字段。纯审计，无源改动。

## 原版发现

- `sw9` = `PDFAsset`（toString）：{metadata:wa0,
  layoutBehavior:xw9(默认2), totalPageCount:mmf(1),
  pagesConsumed:mmf(1), pageOffset:mmf(0), cropBoxes:qed[]}。
- `j7j.c` C(6)：wa0@0、xw9 byte@1、int×3@2-4、8B 结构
  向量@5；两槽必填标记；负长守卫。
- `zwd.a` = xwd 结构派发（注册表→wx4；缺→rgc.b fail-closed）。
- `lv2.v` = cropBoxes 物化器；`mmf` = 页数/页序值类。

## Harmony 核对

PDF 布局六字段 ↔ 背景表 PDF 编码；xw9 缩放 ↔ 适配模式；
cropBoxes ↔ 裁切框；页数三值 ↔ 页面范围。

## 产出

- 证据：`phase-889-pdfasset-sw9.md`
- Fixture：`d02-pdfasset-sw9.mjs`（18/18）
- ADR-0833；全量 Replay 与双 HAP 结果记录于提交。
