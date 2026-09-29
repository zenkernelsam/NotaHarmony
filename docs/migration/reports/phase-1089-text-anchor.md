# Phase 1089 报告 — 文本锚点 + 序列 CRDT

## 完成内容

- `exc` = 文本锚点 `{a1:key, m:site, C:seq}`，
  `(a1,site,-C)` 全序（C 反向=新插靠前）。
- `kci.b` = INSERT_STRING 构建（exc 位 + qo5 域）。

## 产出

- evidence `phase-1089-text-anchor.md`
- fixture `d02-text-anchor.mjs`（10/10）
- ADR-1033
