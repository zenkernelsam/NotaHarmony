# ADR-1288：录音子系统

## 状态

已接受（Phase 1346）。

## 决策

录音 = Harmony `media.AVRecorder`（AAC/mp4，原版参数）
+ 完整管线（gateway/loader/cleanup/delete/present）。

## 理由

`OriginalRecordingMicrophoneBackend`：`AVRecorder` 采集
`audio/mp4`+AAC codec+原版 BITRATE/CHANNELS/SAMPLE_RATE
常量+状态/错误 handler —— 对照原版 `AudioCaptureService`；
配套 `HarmonyGateways`/`AssetLoader`/`CaptureArtifactCleanup`
/`DeleteController`/`Presentation` + `InkInputProviderImpl`/
`MathBlockGeometry`/`NoteTitlePolicy`。

## 后果

录音管线完整（采集+资产+清理+删除+呈现）—— 音频
录制语义保真。
