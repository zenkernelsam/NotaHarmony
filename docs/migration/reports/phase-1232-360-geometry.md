# Phase 1232 报告 — 360 几何/立体结构

## 完成内容

- `q0b`=360 mesh+`i/j/k` 3×3 立体 UV 矩阵（mono/
  top-bottom/side-by-side）；`p0b`=`o0b` 左右眼+type；
  `o0b`=`r71[]` 眼 mesh；`r71`=时间→值有序队列；
  `m40`=逐帧旋转 map —— 360 逐帧几何对齐。

## 产出

- evidence `phase-1232-360-geometry.md`
- fixture `d02-360-geometry.mjs`（10/10）
- ADR-1176
