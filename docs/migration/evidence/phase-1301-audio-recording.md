# Phase 1301 证据 — 音频录制（前台服务）

来源：`feature/note/toolbox/audio/record/
{RecordingForegroundService, wrapper/audio/
AudioCaptureService}.java`。

## `RecordingForegroundService extends Service`

```
onStartCommand →
  createNotificationChannel("notability_recording",
    channel_name, importance=2/LOW)
  wk9(NotificationCompat.Builder) 前台通知
    icon=record_option / title=recording_notification_title
    flags |= FLAG_ONGOING_EVENT(2)     // 常驻不可滑掉
  startForeground(...)
```

→ **前台录制服务** —— 持续通知 + 后台录制（用户切应用
仍录），录音与笔记关联。

## `wrapper/audio/AudioCaptureService` = 音频捕获封装 —
— MediaRecorder/AudioRecord 录制 → 笔记音频轨。

## 语义

**笔记音频录制** —— 前台 Service + 常驻通知 +
音频捕获封装 → 录音时笔记-音频时间轴同步。

## Harmony 决策

前台 Service → Harmony **`@ContinuousTask`/`longTask`**
（后台音频）+ `AVRecorder`/`AudioCapturer` + 常驻通知
（`notificationManager` continuous-task banner）—— 录制
语义保真。

## 产出

- fixture `d02-audio-recording.mjs`（10 断言）。
- ADR-1245；中文报告。
