# Phase 1165 证据 — feature 音频录制 + OAuth 登录

来源：`feature/` 命名类。

## `feature/note/toolbox/audio/record/` = 音频录制服务

- `RecordingForegroundService extends Service` = **前台
  录音服务**（Android `Service` 常驻 —— 录笔记音频时
  防杀；`wcj` 伴生）。
- `wrapper/audio/AudioCaptureService` = 音频捕获服务。

工具箱的"录音"功能 —— `RecordingSegment` schema
（Phase 1117）对应的服务侧：前台服务 + 音频捕获。

## `feature/login/` = OAuth 登录 Activity

- `apple/AppleSignInActivity extends r12` = Apple 登录。
- `microsoft/MicrosoftSignInActivity` = 微软登录。

`r12` = Activity 基 —— OAuth 跳转/回调 Activity。

## 语义

- 录音 = Android 前台 `Service` + 音频捕获 —
  对应 `RecordingSegment` 数据模型。
- 登录 = Apple/Microsoft OAuth Activity —— 平台认证。

## Harmony 决策

- 录音服务 → `@ohos.multimedia.audio` `AudioCapturer` +
  长时任务（`@ohos.app.ability` 后台保持）—— Harmony
  无"前台 Service"，用 `longTask`/`audio` 后台模式。
- OAuth → Harmony 平台认证 / fail-closed（Apple/MS 登录
  走 Web 或平台 SDK —— 无直接等价时 fail-closed）。

## 产出

- fixture `d02-feature.mjs`（10 断言）。
- ADR-1109；中文报告。
