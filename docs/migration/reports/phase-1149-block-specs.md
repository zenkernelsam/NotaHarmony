# Phase 1149 报告 — 块 spec + schema 泄漏

## 完成内容

- `hp5` = 图像块（`cropRect`/`imageFlippedV/H` + `m4c`）；
  `cie` = 纸块（`paper`/`resizesWidthToFitText` + `m4c`）。
- `w1b` 泄漏 `core.flatbuffers.{Rect,Paper}` + 真属性名。

## 产出

- evidence `phase-1149-block-specs.md`
- fixture `d02-block-specs.mjs`（10/10）
- ADR-1093
