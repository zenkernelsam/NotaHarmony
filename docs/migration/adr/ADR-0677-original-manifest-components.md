# ADR-0677 AndroidManifest 组件审计 + 录音后台续录长时任务

- 状态：Accepted
- 日期：2026-09-25
- 关联 Phase：729
- 证据：`docs/migration/evidence/original-manifest-components-jadx-2026-09-25.md`
- Replay：`docs/migration/replays/d02-original-manifest-components.mjs`

## 背景

`decompiled_1.0.3/resources/AndroidManifest.xml`（31799 字节）：应用级
6 activity + 2 service + 6 receiver + 2 provider + 23 权限 + 20
intent-filter；其余为库合并组件。逐项审计归属。

## 决策

### 移植（本阶段代码变更）

**录音后台续录**：原版 `RecordingForegroundService` 在录音会话期间
`startForeground` + PARTIAL_WAKE_LOCK（最长 24h），保证退后台/熄屏
不丢录音；Harmony 现状中 AVRecorder 在 `reason=BACKGROUND` 时进入
paused/stopped（`OriginalRecordingMicrophoneBackend` interruption
监听即为此设）。对齐物 = `backgroundTaskManager.startBackgroundRunning
(BackgroundMode.AUDIO_RECORDING, wantAgent)`：

- `OriginalRecordingSourceBackend` 新增 `context` 参数（第三参，
  可空兜底），会话 `start()` 成功后开长时任务，`stop()`/`abort()`
  一律 `endContinuousTask()`（finally 保证）。
- 任务启动失败仅丧失后台续录、不阻断前台录音（对应原版
  `ForegroundServiceStartNotAllowedException` 容错路径）。
- `module.json5` 新增 `ohos.permission.KEEP_BACKGROUND_RUNNING`
  （normal 级，与 INTERNET 同级声明）。
- 顺带修复 `start()` 中 `active` 先于 await 赋值的残留 bug：
  底层 start 抛错时 active 卡非空，后续 `selectSource`/`start`
  被永久阻断；现 try/catch 清空。

### 已覆盖（无需变更）

- `MainActivity` intent-filter：`viewData`/`sendData`/`sendMultipleData`
  + `file:application/pdf` skills 已声明；深链 notability.com/app/note
  在位；CREATE_NOTE 应用内路径由 `launch_action` 卡片/快捷方式承载。
- 5 widget provider + 2 config activity → NoteFormAbility 五卡 +
  两个 formEdit 能力（Phase 726 视觉对齐）。
- `AudioCaptureService`（设备内录）→ `OriginalRecordingInternalAudioBackend`
  + libnota_recording.so AVScreenCapture 已移植，服务壳随长时任务覆盖。
- `ExportFileProvider`/`WidgetImageProvider` → fileUri 分享 /
  formBindingData 传图，功能等价、机制不同。
- CAMERA → cameraPicker 系统拍照免权限。

### 边界登记（不移植）

- `MissingNativeLibraryActivity`：ABI 兜底页，Harmony 单 ABI 出包。
- `AppUpgradeReceiver`：仅触发 androidx.profileinstaller 基线
  profile 安装，零应用行为。
- `AppleSignInActivity`/`MicrosoftSignInActivity` + `msauth` 回调
  scheme：ADR-0662 登录面边界。
- `LAUNCH_CAPTURE_CONTENT_ACTIVITY_FOR_NOTE`：Samsung 特权权限。
- USE_BIOMETRIC/USE_FINGERPRINT/BOOT_COMPLETED/库级 service/receiver/
  provider：JADX 无应用级引用，均为合并库声明。

## 后果

manifest 组件级审计闭合。录音后台续录从"退后台即被系统暂停"升级为
与原版一致的长时任务托管——属于运行时行为变更，已加真机验收行。
