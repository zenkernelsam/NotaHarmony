# Phase 1301 报告 — 音频录制

## 完成内容

- `RecordingForegroundService`（Service + `notability
  _recording` NotificationChannel + FLAG_ONGOING 常驻
  通知 + startForeground —— 后台持续录制）+ `wrapper/
  audio/AudioCaptureService`（音频捕获封装）—— 笔记
  音频录制功能（录音与笔记时间轴同步）。

## 产出

- evidence `phase-1301-audio-recording.md`
- fixture `d02-audio-recording.mjs`（10/10）
- ADR-1245
