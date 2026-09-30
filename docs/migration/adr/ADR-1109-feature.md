# ADR-1109：feature 音频录制 + 登录

## 状态

已接受（Phase 1165）。

## 决策

- 录音 = Android 前台 `Service`（RecordingForeground/
  AudioCapture）→ Harmony `@ohos.multimedia.audio`
  `AudioCapturer` + 长时后台任务（无前台 Service，用
  `longTask`/audio 后台模式）。
- OAuth = `Apple/MicrosoftSignInActivity` → Harmony 平台
  认证 / fail-closed（无直接等价）。

## 依据

`extends Service` + `extends r12`（Activity）命名类。

## 后果

Harmony：录音后台任务 + 音频捕获；登录走 Web/平台 SDK
或 fail-closed。`RecordingSegment` 数据可移植。
