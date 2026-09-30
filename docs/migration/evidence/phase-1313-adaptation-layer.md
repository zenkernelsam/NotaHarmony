# Phase 1313 证据 — Harmony `core/adaptation` 适配层

来源：`core/adaptation/`（40 文件）—— 原版行为→
Harmony 平台适配桥。

## 平台桥接

```
输入/预测    InkInputProvider(Impl)/PointerSampleStream/
             Predictor(抽象)/NullPredictor/
             **PenKitPredictor** = Harmony PenKit 触控笔
             预测（替代原版 bi8/sl6 Kalman！）
渲染         Canvas2DStrokeRenderer/Canvas2DTextRenderer/
             StrokeRenderer/BitmapTransferTracker/
             LayerCacheGeometry
原版保真     OriginalLaserPointer(激光笔)/OriginalAudio
             LinkedInkPlayback(录音-笔画联动)/
             OriginalPaperTextureLoader/PencilTextureLoader/
             PencilSplatMath(mea/lea splat 移植)/
             OriginalPencilWidthGeometry/
             OriginalRecording*/OriginalHandwriting*
资产/识别    PdfBackgroundLoader/ImageAssetLoader/
             RecognitionProvider(手写识别抽象)
```

## 语义

适配层 = **原版行为 ↔ Harmony 平台桥**：
- 触控笔预测 → Harmony `PenKit`（平台原生预测，
  非自实现 Kalman）。
- 激光笔/录音-笔画联动/纸纹/铅笔 splat → 原版行为
  保留移植。
- 手写识别 → `RecognitionProvider` 抽象（引擎可插拔/
  fail-closed）。

## Harmony 决策

平台能力用 Harmony 原生（PenKit 预测）；原版专有行为
移植保留（splat/激光笔/联动）；引擎抽象 fail-closed —
— 适配层桥接语义保真。

## 产出

- fixture `d02-adaptation-layer.mjs`（10 断言）。
- ADR-1257；中文报告。
