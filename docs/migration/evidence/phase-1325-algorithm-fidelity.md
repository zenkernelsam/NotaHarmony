# Phase 1325 证据 — 算法保真度抽查（ForceSmoother 等）

来源：`core/algorithm/*` vs 原版 `defpackage/{ms1,dr4,
ws4,sqh,w4a,y5a,xaa,oz5,te6,b90}`。

## `ForceSmoother`（对照 `ws4`/`dr4`）

```
smoothingWindowMs = 8        // 原版 ws4 smoothingWindow
maxForceChange    = 0.15     // 原版 dr4 单点最大 force 变化
t = clamp(dt/8ms, 0, 1)      // 时间加权系数
force = lastForce + clamp(delta, ±maxForceChange)  // EMA+限幅
```

→ **时间加权压力平滑器** —— 8ms 窗 EMA + 单点变化
限幅 —— 对照原版 `ws4`/`dr4` 参数保真。

## `ms1` = `ClosedRange<Float>`（`{I,J}` 边界+`e`=≤
contains）—— 平滑器的浮点区间工具（非平滑器本体）。

## `core/algorithm/` 全量

```
CubicFitter        贝塞尔拟合（正规方程/病态回退/二分）
ForceSmoother      压力 EMA+限幅（上）
PencilSplatGenerator 铅笔 splat（LCG/压感⁵/散布/T-033 钳制）
ShapeDetector      形状检测（阈值/评分/多边形分支）
WidthOutlineBuilder 宽度轮廓（Hermite 细分/法向量偏移）
```

## 语义

算法层 = **原版压力/几何算法保真移植** —— 各文件内
联引用原版类（ws4/dr4/ms1/sqh/b90/xaa）+参数对齐 —
— 算法语义保真。

## Harmony 决策

算法参数/公式对照原版（8ms 窗、0.15 限幅、贝塞尔
拟合等）—— 逐方法保真移植。

## 产出

- fixture `d02-algorithm-fidelity.mjs`（10 断言）。
- ADR-1269；中文报告。
