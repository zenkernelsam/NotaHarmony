# Phase 835 — AudioCaptureService 代码语义（媒体内录）

证据：`decompiled_1.4.2/sources/.../wrapper/audio/AudioCaptureService.java`（390 行）

## 一、服务合约

- `startForeground(123, ...)`：FGS id=**123**；
- channel `AudioCapture channel` / 显示名 "Notability Audio
  Capture Service Channel"，importance=**3**（DEFAULT——
  比录音渠道的 LOW 高一级）；
- `onStartCommand` 按 action hashCode 分发：
  `"AudioCaptureService:Start"` → `getMediaProjection(-1,
  ResultData)`（`AudioCaptureService:Extra:ResultData` 携带
  MediaProjection 授权结果）；
- `M` busy 标志 + 空 intent → return 2（NOT_STICKY）；
- FGS 启动包 `ForegroundServiceStartNotAllowedException` +
  `SecurityException` → `a()` 降级。

## 二、音频采集管线（精确参数）

```java
AudioPlaybackCaptureConfiguration.Builder(mediaProjection)
    .addMatchingUsage(1)                 // USAGE_MEDIA
AudioFormat: encoding=2(PCM_16BIT)
             sampleRate=44100
             channelMask=16(MONO)
AudioRecord.Builder.setBufferSizeInBytes(1024 shorts)
```

- 读循环：`audioRecord.read(sArr, 0, 1024)` 短路→
  小端 byte 写入 `FileOutputStream`；
- 输出：`filesDir/AudioCaptures/Recording-dd-MM-yyyy-hh-mm-ss.pcm`
  —— **44.1kHz 单声道 16bit 原始 PCM**；
- 结束日志带文件路径+字节数。

## 三、语义定位

**系统播放内录**（MediaProjection 投影 + USAGE_MEDIA 回放采集），
非麦克风录音——与 `RecordingForegroundService`（麦克风）互补：
一个是"录我在放的"，一个是"录我在说的"。

## 四、Harmony 侧映射

| 原版 | Harmony | 状态 |
|------|---------|------|
| MediaProjection 回放内录 | 无系统音频内录 API | **fail-closed**（829 已登记 fst 面，本相位补合约） |
| FGS id 123 + DEFAULT 渠道 | 无对应 | 登记 |
| 44.1k/mono/PCM16 输出格式 | — | 登记格式参数备查 |
| `AudioCaptures/*.pcm` 产物 | — | 登记产物路径 |

## 五、结论

AudioCaptureService 合约完整解码：action-hash 分发、投影授权
Intent 传递、USAGE_MEDIA 回放采集、PCM 写盘。Harmony 无系统
音频内录能力，整条链 fail-closed（已登记），本相位固化参数。
