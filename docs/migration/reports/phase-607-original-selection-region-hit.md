# Phase 607 — 套索/矩形选区 ∩ 元素几何（fu1.f → g() uh5 分支）

- 日期：2026-09-23
- 结果：已实现对齐
- 证据：`docs/migration/evidence/original-selection-region-hit-2026-09-23.md`
- ADR：`docs/migration/adr/ADR-0576-original-selection-region-hit.md`
- Replay：`d02-original-selection-region-hit.mjs`（14 项断言）

## 背景

原版 `uw2` case1 选区完成（套索/矩形同路径）走
`fu1.f(uh5, k11, v09.J, x09, set)` → `g()` 精判：选区多边形与
**元素实际几何相交**即命中——笔迹描边路径、形状填充∪描边带、
块本地矩形。

Harmony 旧实现：矩形 = bbox∩bbox；套索 = bounds 中心点入多边形。
笔迹/形状"擦边"原版命中而 Harmony miss；矩形碰 bbox 空角原版
miss 而 Harmony 误选。

## 实现

- `EraserEngine.strokeIntersectsSelectionPath(stroke, polygon)`：
  `sampleStroke` 采样；样点入多边形 ∨ 样段-多边形边距 ≤
  `brushWidth·widthFactor·scale/2` ⇒ 命中（`jy0.e` 笔带∩多边形等价）。
- `ShapeGeometry.selectionPathHitsShape(polygon, shape)`：形状顶点
  入多边形 ∨ 闭合多边形 `shapeCoveredByPath`（顶点入填充 ∨
  边距 ≤ 描边半宽）。
- `finalizeSelection` 增可选 `strokeHit` 注入参数（SelectionTool
  保持纯几何）；`NoteCanvasView` 注入引擎命中。
- 块沿用 `selectionPathHitsAffineBlock`（多边形∩本地矩形，已等价）。
- 矩形模式笔迹/形状同步收敛为多边形∩几何（原版矩形即 `uh5`
  多边形，与套索同一判定路径）。

## 验证

- Replay `d02-original-selection-region-hit.mjs`：14/14。
- 全量 Desktop Replay 全绿；`note@default`/`note@ohosTest` 通过。

## 遗留

- `jy0.e` 精确区域求交不可见；采样带-多边形为分辨率内等价逼近。
- 原版 `aa6.t` 宽相省略（结果同）。
- `s06.I()` 瞬态豁免无对应状态（未完成笔迹本不在 completedStrokes）。
