# Phase 1460 修复报告 — ttf 顶点拖拽吸附链

## 目标

结清 Phase 1454 登记差异：`guf.c` 顶点拖拽的两级吸附
（邻边 45° 对齐 + 页/对象候选）此前 Harmony 未实现。

## 原版证据

- `guf.c`：`twm.e(旋转)≠0` 全链跳过；否则 `l4g` 非规整四边形
  →`e2n.d` 邻边射线吸附→`z(em4.F)` 旗标；落空→`twm.b`/`ne1`
  以拖顶点单点逐轴吸附+导线旗。
- `e2n.c/d`：45° 倍数射线（π/8 步进 round）、垂距阈值 5/zoom、
  双射线交点/平行退化投影。
- `fil.a`：4 顶点非退化 → 排除邻边吸附（内部循环恒真空体）。

## Harmony 实现

- 模块级 `neighborSnapRay`/`polygonNeighborSnap`/
  `filQuadrilateral`。
- `snapVertexDragPoint`：多边形邻边射线 → 落空回退
  `planOriginalSnapMove`（顶点单锚点 + `snapGuides` 导线）。
- `applyVertexDrag`：`|rot|≤1e-4` 门后增量经吸附点校正，
  再 `fq9.n0` 反旋转入局部系（原顺序不变）。

## 差异登记

- 邻边吸附不画射线辅助线（原版 `em4` 旗标渲染未解码到具体形状）。
- 正多边形规整约束（`oem.a`/`zB`）形变限制仍未完全解码。

## 验证

- `d02-original-shape-vertex-drag.mjs` 扩至 32 项绿。
- 全量基线 + note@default + note@ohosTest 构建见提交说明。
