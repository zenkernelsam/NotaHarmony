# ADR-1245：音频录制（前台服务）

## 状态

已接受（Phase 1301）。

## 决策

前台 Service → Harmony `longTask`/continuous-task +
`AVRecorder`/`AudioCapturer` + `notificationManager`
常驻 banner —— 录制语义保真。

## 理由

`RecordingForegroundService`（NotificationChannel
`notability_recording`+FLAG_ONGOING 常驻通知+start
Foreground）+ `AudioCaptureService`（音频捕获封装）
—— 后台录制+常驻通知+笔记-音频时间轴。

## 后果

Harmony 音频录制 = longTask+AVRecorder+continuous-task
banner —— 录制/后台语义保真。
