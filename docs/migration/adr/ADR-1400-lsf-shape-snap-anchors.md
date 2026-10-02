# ADR-1400: lsf 单形状拖拽吸附锚点 = 元素轮廓点 + 质心

- **状态**: 已接受
- **日期**: 2026-08-10
- **阶段**: Phase 1465
- **关联**: evidence/phase-1465-lsf-shape-snap-anchors.md
  （`guf.b`/`og0.e`/`og0.h`/`ne1.w` 解码）、ADR-1391（吸附旋转门，
  Phase 1456）

## 背景

`guf.b` 对 lsf 单元素拖拽构造的吸附锚点列并非界框四角：f5g 形状
走 `og0.e` 取**定义轮廓点**（j4g 线仅端点、l4g 多边形顶点去闭合
重尾、k4g 局部框四边中点），中心用 `og0.h` 鞋带质心（退化回退
`og0.i` 均值）；`ne1.w` 再把中心+delta 并入锚点集。Harmony 此前
一律用界框四角+框心，P1456 登记「lsf 锚点粒度」差异。

## 决策

`planSelectionSnap` 分流：恰好单选形状成员时用
`singleShapeSnapAnchors()`（轮廓点+质心/均值），其余维持
`originalSnapMoveAnchors(bounds)`（u64.c(sbe) 四角+u64.b 中心
等价）。

- LINE：`[start,end]` 世界坐标（`m4g.b()` 的贝塞尔中点被 og0.e
  j4g 支丢弃，不参吸）；
- POLYGON：顶点变换世界坐标（`first===last` 闭合重尾按
  `zx7.r`/`m3(1)` 去一）；中心=鞋带质心（world anchors 上算，
  `og0.h` 输入本就是变换后 s64 点列）；
- ELLIPSE：`shapeVertexDots` 四基向点 = `k4g.b()` 四边中点；
- 非形状 lsf（笔画/文本/图/数）：原版 `hv6.H()` 局部界四角经变换
  ——旋转已被 `twm.e` 门排除，轴对齐下与界框锚点等价，不另实现。

## 边界

- 剪切变换元素（非形状）：原版变换四角 ≠ AABB 四角——Harmony 无
  剪切变换产生路径，登记不纠。
- `og0.e` 的 `zq.m` 页判空与 `xxb.g` 页原点换算在 Harmony 页内
  坐标系下退化为恒等。
- 旋转选区仍由 `selectionSnapRotation` 门先禁吸附（未变）。

## 后果

斜线/多边形拖拽时形状顶点本身成为吸附锚（对齐网格/邻元），与
原版 guf.b lsf 支一致；非形状选区行为不变。
