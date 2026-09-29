# Phase 1006 报告 — PDF/资产搜索项生产

## 范围

kw1 case 6 搜索项生成器、文本截断/合并规则、
me2.P=PDF 确认。纯审计。

## 原版发现

- 每资产分页产 `wkc{PDF, subId={ua0}_{pageIdx},
  pageId=z5c.Z(cxc)}`。
- 文本 = `aa6.E0(bx9,50000)` PDF 提取 ∩ 50000 cap；
  第二源非空时 `\n\n` 追加并二次截至 50000。
- `lvd.b1` = `substring(0,min)` 前缀截断。

## Harmony 决策

等价（键/上限/合并）；PDF 提取平台化。

## 产出

- 证据：`phase-1006-pdf-search-items.md`
- Fixture：`d02-pdf-search-items.mjs`（10/10）
- ADR-0950；全量 Replay 见本提交。
