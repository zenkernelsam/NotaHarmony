# Phase 1352 报告 — 形状检测基线归属更正

## 完成内容

- **更正 Phase 1327**：`b90.java` 实为 `AbstractSet`
  （非检测器）。真实原版形状检测基线 = `g5d`
  (`ShapeDetectorOutput{confidence,offset,shape}`)+`uf8`/
  `xf8` 检测器接口+`f5d`(0.05f 点聚类)+`h8d`(点)+`mih`
  (距离)。Harmony `ShapeDetector` 结构对齐真实基线；
  阈值 0.6/60/120 为文档化近似。

## 产出

- evidence `phase-1352-shape-baseline-fix.md`
- fixture `d02-shape-baseline-fix.mjs`（10/10）
- ADR-1293
