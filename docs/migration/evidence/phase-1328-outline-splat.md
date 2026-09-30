# Phase 1328 证据 — `WidthOutlineBuilder` + `PencilSplat`

来源：`core/algorithm/{WidthOutlineBuilder,PencilSplat
Generator}.ets` vs 原版 `w4a`/`y5a`/`xaa`/`oz5`/`te6`。

## `WidthOutlineBuilder` = 变宽笔画轮廓

```
halfWidth(widthFactor, baseWidth)  —— 逐点半径
build: 左偏移曲线 + appendArc(start 圆头) +
       右偏移曲线 + appendArc(end 圆头)
       → outlinePoints 闭多边形（isValid = ≥3 点）
```

→ **变宽笔画→轮廓多边形** —— bezierkit attributed
path 的轮廓生成（法向偏移+圆头帽）—— 对照原版
`w4a`(bezierkit)/`y5a`（迭代器）。

## `PencilSplatGenerator` = 铅笔 splat 纹理

对照原版 `xaa`(yaa iface)/`oz5`(496 行 splat 引擎)/
`te6`(cif 子类） —— 铅笔 splat stamp 生成（LCG 随机
散布+压感⁵+T-033 钳制）。

## 语义

- 变宽轮廓：法向偏移曲线+圆头帽→多边形（笔画外形）。
- 铅笔 splat：纹理 stamp 序列（铅笔颗粒感）。

## Harmony 决策

变宽轮廓+铅笔 splat 逐方法保真（偏移/圆帽/LCG/压感/
钳制）—— 笔画外形算法保真。

## 产出

- fixture `d02-outline-splat.mjs`（10 断言）。
- ADR-1272；中文报告。
