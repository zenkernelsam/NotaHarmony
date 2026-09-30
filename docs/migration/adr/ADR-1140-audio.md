# ADR-1140：音频录制（AudioRecord PCM→AAC + 回放捕获）

## 状态

已接受（Phase 1196）。

## 决策

`AudioCaptureService` = `AudioRecord` PCM @44.1kHz/
mono/`AudioPlaybackCapture`（回放+mic）→ PCM→AAC；
`RecordingForegroundService` 前台 → Harmony `AudioCapturer`
+ `captureRenderer`/loopback + `AVRecorder`/`audioEncoder`
+ ForegroundTask；音频 ts 联动 `xgb` audioTime。

## 理由

`AudioRecord.Builder().setSampleRate(44100).setChannelMask(16)
.setBufferSizeInBytes(2048).setAudioPlaybackCaptureConfig` +
`read(short[])` + `"PCM to AAC"` + `extends Service`。

## 后果

Harmony 录音 = AudioCapturer PCM→AAC；回放捕获需
Harmony 等价 API（loopback）；前台任务保活；audioTime
同步墨迹回放。
