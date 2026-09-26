# Phase 800 证据：原版组件面→Harmony Ability 映射表

日期：2026-09-29
性质：证据登记（无 Harmony 源码变更）——manifest 组件面
逐项映射收尾。
证据源：两版 AndroidManifest、`note/src/main/module.json5`。
Replay：`docs/migration/replays/d02-original-component-map.mjs`
ADR：`ADR-0744-original-component-map.md`

## 1. Activity → Ability

| 原版 | Harmony | 状态 |
|------|---------|------|
| app.MainActivity | NoteAbility | 已映射 |
| app.MissingNativeLibraryActivity | — | Android 专有（HAP 原生库安装期校验，
无运行时缺失面）；fail-closed 概念登记 |
| app.widgets.FolderNotesConfigActivity | FolderFormEditAbility | 已映射 |
| app.widgets.NoteThumbnailConfigActivity | NoteThumbnailFormEditAbility | 已映射 |
| login.apple.AppleSignInActivity | — | 771 SSO fail-closed |
| login.microsoft.MicrosoftSignInActivity | — | 771 SSO fail-closed |

两版 activity 清单逐名一致——1.4.2 无新增 Activity
（Compose 单 Activity 架构深化）。

## 2. Widget Provider → FormAbility/卡片

原版 5 个 AppWidgetProvider（CreateNote/CreateRecording/
FolderNotes/NoteThumbnail/RecentNotes）+ WidgetImageProvider
→ Harmony `NoteFormAbility`（表单能力）+ 卡片页
（RecentNotesCard/FolderNotesCard/NoteThumbnailCard）。
WidgetImageProvider（FileProvider 图喂）为 Android
RemoteViews 专有，Harmony 卡片机制自含——边界登记。

## 3. Service

| 原版 | 归属 |
|------|------|
| HwrEngineService | 768 本地 HWR（manifest 声明佐证） |
| RecordingForegroundService (microphone) | 录音前台任务——Harmony
长时任务机制不同，录制服务已移植语义 |
| AudioCaptureService | 录音采集包装，同上 |

## 4. Provider / Receiver / Initializer

- ExportFileProvider（file:// 导出）→ Harmony 系统分享
  URI 机制替代（已登记分享面）。
- AppUpgradeReceiver → 升级钩子；Harmony 无对应广播，
  迁移在打开期完成（既存 Room/持久层迁移逻辑承担）。
- androidx.startup Initializer 五件（AppStartup/
  UserDataStore/NoteEditorSettings/Haptic/Theme）+
  ApiGatedFirebaseInitProvider → 初始化序已归 771/657/
  主题设置簇；DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION
  为广播安全声明。

## 5. 结论

manifest 组件面逐项归属完毕：4 Activity + 5 WidgetProvider
+ 2 Provider + 2 Receiver + 3 Service + 6 Initializer，
全部映射或边界登记。Activity 面两版零差。
