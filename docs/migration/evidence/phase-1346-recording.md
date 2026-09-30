# Phase 1346 证据 — 录音子系统 + core 余量

来源：`core/adaptation/OriginalRecording{MicrophoneBackend,
HarmonyGateways,AssetLoader,CaptureArtifactCleanup,
DeleteController,Presentation}.ets`+`{InkInputProviderImpl,
MathBlockGeometry,OriginalNoteTitlePolicy}.ets`。

## `OriginalRecordingMicrophoneBackend` = AVRecorder 采集

```
ORIGINAL_RECORDING_AUDIO_MIME_TYPE='audio/mp4'
AVRecorder profile: AAC codec + 原版 BITRATE/CHANNELS/
  SAMPLE_RATE 常量
start() → 临时目录 capture + recorderStateHandler/
  recorderErrorHandler
```

→ 录音 = Harmony `media.AVRecorder`（AAC/mp4，参数对照
原版采集规格）+ 状态/错误 handler —— 对照原版
`AudioCaptureService`/`RecordingForegroundService`。

## `OriginalRecording*` 族

`HarmonyGateways`（Harmony API 网关）/`AssetLoader`（资产
加载）/`CaptureArtifactCleanup`（采集中断清理）/
`DeleteController`/`Presentation` —— 完整录音管线。

## 余量

- `InkInputProviderImpl` —— 触摸/笔输入 provider。
- `MathBlockGeometry` —— 数学块几何布局。
- `OriginalNoteTitlePolicy` —— 笔记标题策略。

## Harmony 决策

录音 = `AVRecorder` AAC/mp4 原版参数 + 完整管线
（gateway/loader/cleanup/delete/present）—— 对照原版
音频录制语义。

## 产出

- fixture `d02-recording.mjs`（10 断言）。
- ADR-1288；中文报告。
