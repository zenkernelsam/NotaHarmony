# Phase 1224 报告 — 样式文本模型

## 完成内容

- `a00`=AnnotatedString（zz 注记分 K/L span/paragraph）；
- `zqe`=TextStyle（gnd SpanStyle + ima ParagraphStyle +
  f31 Brush，toString 泄漏 color/fontSize/fontWeight）。

## 产出

- evidence `phase-1224-styled-text.md`
- fixture `d02-styled-text.mjs`（10/10）
- ADR-1168
