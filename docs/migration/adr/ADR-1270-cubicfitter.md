# ADR-1270：CubicFitter 贝塞尔拟合

## 状态

已接受（Phase 1326）。

## 决策

贝塞尔拟合逐方法保真（二分分段/容差/最小二乘/上下
文窗口/源范围溯源）—— 笔画拟合算法保真。

## 理由

`CubicFitter`：`computeOriginalFitTolerance`(zoom 感知容
差）+`fitWithSourceRanges`(>200 点二分最长可接受终点，
`sqh.f`/`wy5` 语义）+`fitCubic`(ctx 上下文窗口最小二乘
cubic)+sourceRanges 溯源 —— 对照原版误差界分段拟合
保真。

## 后果

笔画→cubic path 拟合与原版语义一致（容差/分段/溯源）
—— 笔迹几何保真。
