# Phase 1215 报告 — pdf TransformedTextFieldState

## 完成内容

- `pdf` toString 泄漏实名 `TransformedTextFieldState`；
- `qoe`=TextFieldState、`ov1`=OutputTransformation、
  `ps3`=CodepointTransformation、`na3`=MutableState；
- `d`/`f`=output/visualText、`g`/`h`/`i`=偏移映射、
  `k`/`l`/`a`=提交助手 + `qoe.f(true)` undo 边界。

## 产出

- evidence `phase-1215-pdf-transformed-text.md`
- fixture `d02-pdf-transformed-text.mjs`（10/10）
- ADR-1159
