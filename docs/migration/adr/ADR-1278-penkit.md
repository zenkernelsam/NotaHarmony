# ADR-1278：PenKitPredictor 平台预测

## 状态

已接受（Phase 1335）。

## 决策

笔画预测 = `@kit.Penkit.PointPredictor`（平台输入层，
对齐原版 AndroidX Ink 架构）+ 无手写笔设备 fail-soft。

## 理由

`PenKitPredictor` 委托 HarmonyOS `PointPredictor`（API12+
系统手写预测）：lazy 实例 + `getPredictionPoint`+finite
校验；不支持 `Stylus.Handwrite` 的设备 catch→null 无损
降级。原版 AndroidX Ink 同样只取平台输入层预测 ——
同架构（非自研 Kalman），且降级更安全。

## 后果

笔画预测用系统级预测器、无手写笔能力设备安全降级 —
— 架构对齐+更稳。
