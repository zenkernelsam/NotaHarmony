# Phase 1357 报告 — 轮廓/splat 基线更正

## 完成内容

- **更正 Phase 1328**：`w4a`/`y5a`/`te6` 误标撤销；真实
  bezierkit（`com.gingerlabs.notability.bezierkit`）混淆为
  `defpackage` `bw0`（Bernstein1-4 池）/`q8a`（Cubic+
  Quadratic+LineSegment 池）/`lq2`/`ky0`/`iz8`/`cw0`
  （CGPoint 池）—— 真实轮廓构建基线族。Harmony
  `WidthOutlineBuilder`/`PencilSplatGenerator` 语义正确，
  误标仅在符号引用。
- **算法基线更正全部完成**（检测/拟合/平滑/轮廓四组）。

## 产出

- evidence `phase-1357-outline-baseline-fix.md`
- fixture `d02-outline-baseline-fix.mjs`（10/10）
- ADR-1298
