# Phase 1465 报告：lsf 单形状拖拽吸附锚点 = og0.e 轮廓点 + og0.h/i 质心

## 原版行为（1.4.2 证据）

`guf.b`（guf.java:104-157）xtf 移动会话每帧吸附，旋转门
`!twm.e(fJ)` 后按选区类型构造 `kdc(锚点列, 中心)`：

- ksf/有 sbe：`u64.c(sbe)` 四角 + `u64.b(sbe)` 中心；
- lsf 单元素：`og0.e(r0b, hv6)` 轮廓点列优先，空则回退界框四角；
  中心 `og0.h`/`og0.i`。

`og0.e`（og0.java:494-533）按元素类型取点：

- **f5g 形状** `U().b()`：j4g 线仅首末端点（`m4g.b()` 的贝塞尔中点
  被丢弃）；l4g 多边形顶点，`zx7.r(first,last)` 闭合重尾去一
  （`m3(1)`）；k4g 局部框四边中点；
- **非形状**：`hv6.H()` 局部界四角；
- 逐点 `kw9.c` 元素变换 + `xxb.g` 页原点 → 页坐标。

`og0.h`（571-601）：l4g 且 ≥3 点 → 鞋带质心
（d=2A，cx=Σ(xi+xi+1)ci/3d）；退化或非多边形 → `og0.i` 均值。
`ne1.w`（ne1.java:410-446）：锚点+位移集**追加 center+delta**，
逐候选逐轴裁决 → mkg(校正位移,导线)。

## Harmony 缺口（P1456 登记）

`planSelectionSnap` 一律 `originalSnapMoveAnchors(bounds)` = 界框
四角+框心——单形状拖拽时顶点/端点不参吸（三角形顶点不对齐网格）。

## 实现（NoteCanvasView.ets）

`singleShapeSnapAnchors()`：单选形状门 → LINE 两端点 / POLYGON
顶点去闭合重尾+鞋带质心 / ELLIPSE `shapeVertexDots` 四基向点，
统一 `transformMemberPoint` 世界化并追加中心。`planSelectionSnap`
分流 `?? originalSnapMoveAnchors(bounds)`。

## 验证

- `d02-original-snap-to-grid.mjs`：47→57 项（锚点分支断言 +
  鞋带质心可执行模型）。
- `note@default` 构建通过；全量 Replay 与 `note@ohosTest` 收尾
  验证。

## 遗留差异

- 剪切变换非形状元素：原版变换四角 vs Harmony AABB 四角——无剪切
  产生路径，登记不纠。
- `zq.m` 页判空/`xxb.g` 页原点换算在页内坐标系下恒等退化。
