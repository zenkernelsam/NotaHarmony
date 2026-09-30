# Phase 1326 证据 — `CubicFitter` 贝塞尔拟合审计

来源：`core/algorithm/CubicFitter.ets` vs 原版 `sqh.f`/
`wy5`。

## 原版 `sqh`/`wy5`（贝塞尔拟合）

`sqh` = 拟合器入口（`sqh.f`/`wy5`）—— **>200 点 → 二分
查找最长可接受终点（误差 ≤ tolerance）** 的误差界
分段拟合。

## Harmony `CubicFitter`（保真对齐）

```
computeOriginalFitTolerance(baseWidth, zoom)
                         —— zoom 感知容差
fitWithSourceRanges(pts, baseWidth, zoom, initialTangent)
  → {segments, sourceRanges}   —— 每段溯源输入点范围
二分分段：sqh.f/wy5 语义 —— >200 点二分最长可接受终点
          （error ≤ tolerance → 接受终点；否则回退）
fitCubic(pts, segStart, segEnd)
  ctx 上下文窗口（fitStart=segStart-ctx, fitEnd=segEnd+ctx）
  → 最小二乘 cubic segment
```

## 语义

贝塞尔拟合 = **误差界二分分段 + 最小二乘 cubic + zoom
感知容差 + 源点溯源** —— 对照原版 `sqh.f`/`wy5` 二分
语义保真。

## Harmony 决策

贝塞尔拟合逐方法保真（二分分段/容差/最小二乘/上下文
窗口/源范围溯源）—— 笔画拟合算法保真。

## 产出

- fixture `d02-cubicfitter.mjs`（10 断言）。
- ADR-1270；中文报告。
