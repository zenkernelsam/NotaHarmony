# ADR-1298：轮廓/splat 基线归属更正

## 状态

已接受（Phase 1357，更正 Phase 1328）。

## 决策

轮廓/splat 基线更正为 bezierkit 混淆族（Bernstein/
CGPoint/CubicCurve/QuadraticCurve 对象池）；`w4a`/`y5a`/
`te6` 误标撤销。

## 理由

实读：`w4a`=synthetic when-map、`y5a`/`te6`=近邻类；
真实 bezierkit（`com.gingerlabs.notability.bezierkit`）混淆
为 `defpackage` `bw0`（Bernstein1-4 池）/`q8a`（Cubic+
Quadratic+LineSegment 池）/`lq2`/`ky0`/`iz8`/`cw0`
（CGPoint 池）—— 真实轮廓构建基线族。Harmony
`WidthOutlineBuilder`/`PencilSplatGenerator` 语义正确。

## 后果

算法基线引用全部复核更正（4 组误标撤销）；实现语义
不受影响，审计准确性提升。
