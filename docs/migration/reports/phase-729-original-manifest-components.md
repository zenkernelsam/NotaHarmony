# Phase 729 中文报告：AndroidManifest 组件审计 + 录音后台续录长时任务

## 范围

`decompiled_1.0.3/resources/AndroidManifest.xml` 全量组件审计：
6 应用级 activity + 2 service + 6 receiver + 2 provider + 23 权限 +
20 intent-filter。

## 原版证据

见 `docs/migration/evidence/original-manifest-components-jadx-2026-09-25.md`。

关键发现：`RecordingForegroundService.onStartCommand` 创建
`notability_recording` 通知渠道 + `startForeground(2001)` +
PARTIAL_WAKE_LOCK（`acquire(86400000L)`，24h）——原版录音会话退后台/
熄屏不中断。`AudioCaptureService` 是 MediaProjection 设备内录前台服务。

## 本阶段变更

- `OriginalRecordingSourceBackend`：新增 `context` 第三参；
  `start()` 成功后经 `backgroundTaskManager.startBackgroundRunning
  (BackgroundMode.AUDIO_RECORDING, wantAgent)` 开长时任务（wantAgent
  回拉 NoteAbility）；`stop()`/`abort()` 在 finally 收任务；
  任务启动失败仅丧失后台续录、不阻断前台录音。
- 顺带修复 `start()` 失败路径 `active` 残留 bug（原代码先赋值后
  await，底层抛错时 active 卡非空、后续 start/selectSource 被永久
  阻断）。
- `module.json5` 新增 `ohos.permission.KEEP_BACKGROUND_RUNNING`。

## 归属登记（ADR-0677）

- 已覆盖：MainActivity intent-filter（viewData/sendData/sendMultiple
  Data + file:application/pdf + notability.com/app/note 深链）、
  5 widget provider + 2 config activity（Phase 726）、AudioCapture
  Service（InternalAudioBackend+libnota_recording.so）、
  ExportFileProvider/WidgetImageProvider（fileUri/formBindingData
  功能等价）、CAMERA（cameraPicker 免权限）。
- 边界：MissingNativeLibraryActivity（单 ABI 出包）、AppUpgrade
  Receiver（仅 androidx.profileinstaller）、Apple/MS sign-in +
  msauth（ADR-0662）、LAUNCH_CAPTURE_CONTENT_ACTIVITY_FOR_NOTE
  （Samsung 特权）、biometric/boot/库级组件（无应用级引用）。

## 验证

- `d02-original-manifest-components.mjs` 专项全绿。
- 全量 Desktop Replay 全绿；note@ohosTest + note@default clean 构建
  成功（仅存量警告）。
- 运行时行为变更：录音退后台续录 → 已登记真机验收清单。
