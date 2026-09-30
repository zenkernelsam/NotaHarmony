# Phase 1335 证据 — PenKitPredictor（平台级笔画预测）

来源：`core/adaptation/{PenKitPredictor,Predictor}.ets`。

## `PenKitPredictor` = HarmonyOS `PointPredictor` 适配

```
import { PointPredictor } from '@kit.Penkit';
// HarmonyOS 5.0/API12+ 系统手写预测器。
// 与原版 AndroidX Ink 一样，预测只来自平台输入层。
predict(event):
  lazy new PointPredictor()
  getPredictionPoint(event) → {x,y}
  校验 finite → 非数返回 null
  catch → return null（不支持 Stylus.Handwrite 的
    设备无损降级为无预测）
reset() —— no-op（PointPredictor 从 TouchEvent
  历史样本计算，无可重置状态）
```

→ **平台级预测**：原版用 AndroidX Ink（其内部亦为
平台/Kalman 类滤波），Harmony 用 PenKit `PointPredictor`
—— 同一架构（委托 OS 输入层预测，非自研 Kalman），
且对无手写笔能力的设备 **fail-soft**（null 降级非崩溃）。

## Harmony 决策

笔画预测 = `@kit.Penkit.PointPredictor`（平台输入层，
对齐原版 AndroidX Ink 架构）+ finite 校验 + 无手写笔
能力设备无损降级。

## 产出

- fixture `d02-penkit.mjs`（10 断言）。
- ADR-1278；中文报告。
