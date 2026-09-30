# Phase 1258 报告 — 文本缓冲

## 完成内容

- `o7a`=gap-buffer CharSequence（`a`=char[] replace）；
- `dle`=`Appendable` TextEditBuffer（`ele`/`o7a`/`jqe`/
  `rnh`，`g` 物化 `ele`）；`ele`=不可变文本+`rh8.A`
  钳位选区；`jqe`=packed long TextRange —— 文本编辑
  缓冲层。

## 产出

- evidence `phase-1258-text-buffer.md`
- fixture `d02-text-buffer.mjs`（10/10）
- ADR-1202
