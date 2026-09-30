# Phase 1313 报告 — `core/adaptation` 适配层

## 完成内容

- `core/adaptation`（40 文件）= 原版→Harmony 平台桥：
  `InkInputProvider`/`PointerSampleStream`/`Predictor`
  抽象+**`PenKitPredictor`**（Harmony PenKit 触控笔预测
  —— 替代原版自实现 Kalman）；渲染（Canvas2D Stroke/
  Text/StrokeRenderer/BitmapTransfer/LayerCache）；原版
  保真（LaserPointer/AudioLinkedInkPlayback/Paper
  Texture/PencilSplatMath/PencilWidth）+ `Recognition
  Provider`+录音后端 —— 平台桥接语义保真。

## 产出

- evidence `phase-1313-adaptation-layer.md`
- fixture `d02-adaptation-layer.mjs`（10/10）
- ADR-1257
