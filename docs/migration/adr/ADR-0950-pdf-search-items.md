# ADR-0950 — PDF/资产搜索项生产（kw1 case 6）

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `kw1` case 6：按页迭代 PDF 资产 → `wkc` 项：
  type=`me2.P`(PDF)、subId=`{ua0}_{pageIdx}`、
  pageId=`z5c.Z(cxc)`、文本=PDF 提取（`aa6.E0`
  截 50000）与第二源 `\n\n` 合并再截 50000。
- `lvd.b1(n,s)` = `substring(0,min(n,len))`，负 n→
  `s5c.h` IllegalArgument。
- `tz9{a:cxc}` 页位置表。

## Harmony 决策

键格式/上限/合并规则等价；PDF 提取走 Harmony PDF
能力。

## Parity 状态

等价。

## 验证

- `d02-pdf-search-items.mjs`：10/10 通过。
