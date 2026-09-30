# Phase 1357 证据 — 轮廓/splat 基线归属更正

**更正 Phase 1328**：`w4a`/`y5a`/`te6` 引为 outline/splat
基线误标。真实基线 = **bezierkit 混淆族**（对象池）。

## 真实原版 bezierkit（`com.gingerlabs.notability.bezierkit`）

```
bw0 —— reusable BernsteinPolynomial1/2/3/4 池（fl6/v1b
  委托，9 个 reusable 槽）
cw0/ky0/iz8/lq2 —— reusable CGPoint / CGPoint1+2 /
  QuadraticCurve 池
q8a —— reusable CGPoint+CubicCurve+QuadraticCurve+
  LineSegment 池
```

→ bezierkit 几何核心（Bernstein 多项式/Point/Cubic/
Quadratic/Line 曲线）全在 `defpackage` 混淆名下，经
对象池（`*0`/`iz8`/`lq2`/`q8a`）复用 —— 真实轮廓构建
基线为 bezierkit `CubicCurve`/`offset`/`attributed` 族。

## 更正说明

`w4a`=synthetic when-map、`y5a`/`te6`=`i5h`/`cif` 近邻 —
— 非轮廓/splat 本体。Harmony `WidthOutlineBuilder`
（法向偏移+`appendArc` 圆帽）与 `PencilSplatGenerator`
实现本身正确（对照 bezierkit attributed-path 语义），
误标仅在符号引用。

## Harmony 决策

轮廓/splat 基线更正为 bezierkit 混淆族（Bernstein/
CGPoint/CubicCurve 池）；`w4a`/`y5a`/`te6` 误标撤销。

## 产出

- fixture `d02-outline-baseline-fix.mjs`（10 断言）。
- ADR-1298；中文报告。
