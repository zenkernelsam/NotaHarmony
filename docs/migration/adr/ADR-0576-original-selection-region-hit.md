# ADR-0576 — 套索/矩形选区 ∩ 元素几何（fu1.f → g() uh5 分支）

- 状态：Accepted
- Phase 607；对齐 `fu1.f`/`fu1.g`/`fu1.h`（decompiled_1.0.3）。

## 背景

原版选区完成（`uw2` case1，套索与矩形同路径）调 `fu1.f(uh5, k11,
v09.J, x09, set)`：宽相后逐元素 `g()` 精判，`uh5` 多边形与
**元素实际几何相交**即命中——笔迹为描边路径（`h(uh5, inkPath)`
→ `jy0.e`），形状为填充路径或描边带（`z8a.b(path,Q())`），块为
本地矩形（`jy0.e(多边形, rect)`）。

Harmony 旧实现：矩形模式 `rectIntersects(选框, bounds)`（bbox 粗判），
套索模式 **bounds 中心点入多边形**。两类偏差：
- 笔迹/形状掠过套索边缘、bounds 中心在多边形外：原版命中，
  Harmony miss（套索选不中"擦边"元素——高频可感知差异）。
- 矩形仅碰 bounds 空角、未触实际路径：原版 miss，Harmony 误选。

## 决策

1. `EraserEngine.strokeIntersectsSelectionPath(stroke, polygon)`：
   复用 `sampleStroke`（cubic + widthFactor），采样点入多边形
   ∨ 采样段与多边形边（含闭合边）距离 ≤ 该处半宽
   `brushWidth·widthFactor·scale/2` ⇒ 命中——笔带 ∩ 多边形等价于
   `jy0.e(uh5, inkPath)`。
2. `ShapeGeometry.selectionPathHitsShape(polygon, shape)`：形状
   世界顶点入多边形（小形状整体套入情形）∨ 闭合多边形经
   `shapeCoveredByPath`（多边形顶点入填充区域 ∨ 多边边-形状边
   距离 ≤ `strokeWidth·scale/2`）——填充∪描边带 ∩ 多边形。
3. `SelectionTool.finalizeSelection` 增可选 `strokeHit` 注入参数：
   SelectionTool 保持纯几何、不依赖 EraserEngine；无注入时退回
   原 bounds 近似（仅测试调用点如此）。块元素沿用
   `selectionPathHitsAffineBlock`（多边形 ∩ 本地矩形，已等价）。
4. `NoteCanvasView` 注入 `eraserEngine.strokeIntersectsSelectionPath`。

## 偏差

- 原版 `aa6.t` 宽相 + `g()` 精判两段；Harmony 直接全量精判
  （z 序无关、结果同，仅省宽相）。
- `jy0.e` 精确区域求交不可见；采样带-多边形逼近在采样分辨率内
  等价。笔迹半宽取采样段起点 `widthFactor`（段内渐变亚像素级近似）。
- `s06.I()`（transientInteraction 豁免）在 Harmony 无对应状态——
  未完成笔迹本就不在 `completedStrokes` 中，天然等价。

## 验证

- `d02-original-selection-region-hit.mjs`：14 断言（注入参数、
  采样带 ∩ 多边形、闭合边、形状顶点套入 + 填充/带、canvas 接线、
  可执行相交模型）。
- 全量 Desktop Replay 全绿；`note@default`/`note@ohosTest` 通过。
