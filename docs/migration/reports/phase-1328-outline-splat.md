# Phase 1328 报告 — WidthOutlineBuilder + PencilSplat

## 完成内容

- `WidthOutlineBuilder`（变宽笔画→轮廓多边形：halfWidth
  逐点半径+左右法向偏移曲线+`appendArc` 圆头帽，对照
  `w4a`/`y5a` bezierkit）；`PencilSplatGenerator`（铅笔
  splat stamp，对照 `xaa`/`oz5`/`te6` splat 引擎——LCG
  散布+压感⁵+T-033 钳制）—— 笔画外形+铅笔纹理保真。

## 产出

- evidence `phase-1328-outline-splat.md`
- fixture `d02-outline-splat.mjs`（10/10）
- ADR-1272
