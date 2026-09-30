# Phase 1326 报告 — CubicFitter 审计

## 完成内容

- `CubicFitter` 对照原版 `sqh.f`/`wy5` 贝塞尔拟合：
  `computeOriginalFitTolerance`(zoom 感知容差）+
  `fitWithSourceRanges`（>200 点二分最长可接受终点+
  sourceRanges 溯源）+`fitCubic`(ctx 上下文最小二乘
  cubic)—— 误差界二分分段拟合保真（原版 `sqh`=
  拟合器入口，`qeh` 注册）。

## 产出

- evidence `phase-1326-cubicfitter-audit.md`
- fixture `d02-cubicfitter.mjs`（10/10）
- ADR-1270
