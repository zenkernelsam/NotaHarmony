# 原版 AndroidManifest 组件级证据（decompiled_1.0.3/resources/AndroidManifest.xml）

日期：2026-09-25。manifest 全量 31799 字节；应用级组件逐项如下，
其余为 AppCompat/M3/GMS/Firebase/Samsung-IAP/MLKit/Pairip/WorkManager
合并库组件（平台边界）。

## 应用级 activity（6）

| 组件 | 原版行为 | Harmony 归属 |
|---|---|---|
| `MainActivity` | LAUNCHER + `VIEW content|file application/pdf` + `SEND application/pdf` + `msauth`/`com.gingerlabs.notability` 回调 + `CREATE_NOTE` | `NoteAbility`（viewData/sendData/sendMultipleData + file:application/pdf skills 已声明）；深链 notability.com/app/note 已声明；CREATE_NOTE 为 Android 系统级"创建笔记"意图（手写笔/助手入口），JADX 中仅 widget provider 引用、应用内落到同一新建路径——Harmony 由 postCardAction/shortcut 的 `launch_action` 承载（`LaunchActionIngress`），系统级公共入口无对应 want action→边界。msauth 回调属登录边界（ADR-0662）。 |
| `MissingNativeLibraryActivity` | ABI 不匹配的兜底页 | Harmony HAP 按 arm64 单 ABI 出包，无等价位→平台边界。 |
| `FolderNotesConfigActivity` | 文件夹 widget 配置页 | `FolderNotesEditPage`/`FolderFormEditAbility` 已移植。 |
| `NoteThumbnailConfigActivity` | 缩略图 widget 配置页 | `NoteThumbnailEditPage`/`NoteThumbnailFormEditAbility` 已移植。 |
| `AppleSignInActivity`/`MicrosoftSignInActivity` | Apple/MS 登录回流 | ADR-0662 登录面边界。 |

## 应用级 service（2）

| 组件 | 原版行为 | Harmony 归属 |
|---|---|---|
| `RecordingForegroundService` | 录音会话期间 `startForeground(2001)` + PARTIAL_WAKE_LOCK 24h，notification channel `notability_recording`、icon `feature_note_toolbox__record_option`——**保证退后台录音不中断** | Phase 729 移植为 `backgroundTaskManager.startBackgroundRunning(BackgroundMode.AUDIO_RECORDING)` 长时任务（`OriginalRecordingSourceBackend` 会话级开/停）+ `ohos.permission.KEEP_BACKGROUND_RUNNING`。Harmony 长时任务由系统托管横幅通知，无需手造 notification 文案。 |
| `AudioCaptureService` | MediaProjection 回放音频捕获（设备内录）前台服务 | `OriginalRecordingInternalAudioBackend`（libnota_recording.so AVScreenCapture）已移植；其服务壳随上一条长时任务覆盖。 |

## 应用级 receiver（6）

| 组件 | 原版行为 | Harmony 归属 |
|---|---|---|
| `AppUpgradeReceiver` | `MY_PACKAGE_REPLACED` → `nza.b` = **androidx.profileinstaller** 基线 profile 安装 | 纯库机制，零应用行为→平台边界。 |
| 5× `*WidgetProvider`（CreateNote/CreateRecording/FolderNotes/NoteThumbnail/RecentNotes） | APPWIDGET_UPDATE/CONFIGURE/LOCALE_CHANGED | NoteFormAbility 五张卡片 + 两个 formEdit 能力已移植（Phase 726 视觉对齐）。 |

## 应用级 provider（2）

| 组件 | 原版行为 | Harmony 归属 |
|---|---|---|
| `WidgetImageProvider` | FileProvider 向 widget 出图 | Harmony 卡片经 formBindingData/formProvider 传图，机制不同→平台边界（功能等价）。 |
| `ExportFileProvider` | FileProvider 给分享导出颁 content:// URI | Harmony 分享经 fileUri+系统分享（ADR-0639/0641 已移植），FileProvider 机制无对应→平台边界（功能等价）。 |

## 权限对表

| 原版权限 | Harmony 归属 |
|---|---|
| INTERNET / RECORD_AUDIO / WAKE_LOCK | INTERNET / MICROPHONE 已声明；WAKE_LOCK 由 AUDIO_RECORDING 长时任务等价托管 |
| FOREGROUND_SERVICE(+MEDIA_PROJECTION,+MICROPHONE,+DATA_SYNC) | KEEP_BACKGROUND_RUNNING（Phase 729 新增） |
| CAMERA | cameraPicker 系统拍照不申请 CAMERA 权限（已有 `OriginalCameraPickerCaller`） |
| USE_BIOMETRIC/USE_FINGERPRINT | JADX 中无应用级 Biometric 引用——库合并声明→平台边界 |
| BOOT_COMPLETED | WorkManager RescheduleReceiver（库）→平台边界 |
| LAUNCH_CAPTURE_CONTENT_ACTIVITY_FOR_NOTE | Samsung 笔记捕获特权权限→平台边界 |
| BILLING/IAP/AD_ID/CHECK_LICENSE/READ_PHONE_STATE/EXT_STORAGE 等 | GMS/计费/legacy 存储→ADR-0662/平台边界 |

## 结论

manifest 应用级组件逐项有归属：6 activity（1 移植+2 widget-config
移植+2 登录边界+1 ABI 兜底平台边界）、2 service（录音前台服务→
长时任务已移植、内录服务已覆盖）、6 receiver（ProfileInstaller
边界 + 5 widget 已移植）、2 provider（FileProvider 机制边界但功能
等价）。Phase 729 唯一代码变更是录音后台续录长时任务。
