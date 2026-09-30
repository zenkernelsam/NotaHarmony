# Phase 1196 证据 — 音频录制引擎（AudioCaptureService + RecordingForegroundService）

来源：`feature/note/toolbox/audio/record/`。

## `RecordingForegroundService extends Service`

前台录音服务（持久通知 + `onStartCommand`）。

## `AudioCaptureService extends Service` = PCM 捕获

```java
new AudioRecord.Builder()
  .setAudioFormat(AudioFormat.sampleRate(44100)
                  .channelMask(16).build())   // 44.1kHz
  .setBufferSizeInBytes(2048)
  .setAudioPlaybackCaptureConfig(cfg)        // **AudioPlaybackCapture**
  .build()
while (…) audioRecord.read(short[] sArr, 0, N) > 0
```

- **`AudioPlaybackCaptureConfig`** —— 捕获**回放音频**
  （系统/其它应用音频，Android 10+ API，非仅麦克风）。
- `AudioRecord.read(short[])` PCM 采样 44.1kHz/2048。
- **PCM → AAC**：`"PCM to AAC conversion failed/succeeded"`
  —— 录 PCM 再转码 `.aac`/`file`。
- `oc M` 回调；`ep7/yn7` 日志。

## 判定

**音频录制 = 系统回放 + 麦克风 PCM @44.1k → AAC**：
`AudioPlaybackCapture`（回放）+ AudioRecord PCM +
PCM→AAC 转码 —— 笔记音频同步录制（音频时间戳
联动 `xgb`/audioTime，Phase 1126 的 `rawAudioTime`）。

## Harmony 决策

- `AudioRecord`/`AudioPlaybackCapture` → Harmony
  **`AudioCapturer`**（`@ohos.multimedia.audio`）+ 回放
  捕获用 `captureRenderer`/loopback（Harmony 回放捕获
  API 不同 —— 需 `audioCapturerInfo.source`）。
- PCM→AAC → Harmony `AVRecorder`/`audioEncoder`。
- `RecordingForegroundService` → Harmony `ForegroundTask`/连续任务。

## 产出

- fixture `d02-audio.mjs`（10 断言）。
- ADR-1140；中文报告。
