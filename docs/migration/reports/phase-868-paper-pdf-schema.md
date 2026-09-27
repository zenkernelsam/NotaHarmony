# Phase 868 报告 — 纸张/PDF 子模式登记

## 范围

补齐 Phase 867 深层字段：`ge8` MODIFY_PAGE、`k3a` 纸张表、
`n3a`/`xw9` 枚举、`hu1` RGBA、`wa0` PDF 资产。纯审计阶段。

## 原版发现

- `ge8`：pages(SeqId 向量)/lxc moveTo/m2d 背景/oz9 书签四字段。
- `k3a`：n3a 纸纹 + Float 间距 + Boolean×2 + hu1 RGBA + cmf。
- `n3a`={LINES,DOTS,GRID}；`xw9`=PDF 适配三值；
  `hu1`=4B RGBA struct；`wa0`=PDF 资产（ua0+2 String+int）。

## Harmony 核对

PaperFlair 枚举等价、`flairBleeds` 线纸语义保留；ModifyPage
写手注释逐字段对应 ge8。深层子表留档。

## 产出

- 证据：`phase-868-paper-pdf-schema.md`
- Fixture：`d02-paper-pdf-schema.mjs`（23/23）
- ADR-0812；全量 Replay 与双 HAP 结果记录于提交。
