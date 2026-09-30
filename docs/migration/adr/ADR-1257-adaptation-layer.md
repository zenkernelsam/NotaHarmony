# ADR-1257：`core/adaptation` 适配层

## 状态

已接受（Phase 1313）。

## 决策

平台能力用 Harmony 原生（PenKit 预测替代 Kalman）；
原版专有行为移植保留；手写识别抽象 fail-closed。

## 理由

`core/adaptation`(40)：`PenKitPredictor`（Harmony PenKit
触控笔预测 —— 替代原版 `bi8`/`sl6` 自实现 Kalman）+
`Predictor`/`NullPredictor` 抽象 + `OriginalLaserPointer`/
`OriginalAudioLinkedInkPlayback`/`PencilSplatMath`/
`OriginalPaperTextureLoader`（原版行为移植）+`Recognition
Provider`（引擎抽象）+ 录音后端×2 —— 平台桥接层。

## 后果

平台能力 → Harmony 原生 API；原版行为 → 移植保留；
不可移植引擎 → 抽象+fail-closed —— 适配语义保真。
