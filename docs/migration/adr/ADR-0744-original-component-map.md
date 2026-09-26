# ADR-0744 — 原版组件面→Harmony Ability 映射收尾

日期：2026-09-29
状态：已登记（组件面闭合；无源码变更）
证据：`docs/migration/evidence/phase-800-original-component-map.md`
Replay：`docs/migration/replays/d02-original-component-map.mjs`

## 背景

manifest 组件面逐项映射：6 app Activity（两版零差）、
5 WidgetProvider、3 Service、2 Provider、1 Receiver、
6 androidx.startup Initializer。

## 决策

- MainActivity→NoteAbility；FolderNotes/NoteThumbnail
  ConfigActivity→对应 FormEditAbility；登录双 Activity
  →771 fail-closed。
- 5 WidgetProvider+WidgetImageProvider→NoteFormAbility
  + 三张卡片页（RemoteViews/FileProvider 为 Android 专有）。
- MissingNativeLibraryActivity 登记 Android-only
  （HAP 原生库安装期校验，无运行时缺失面）。
- HwrEngineService/RecordingForegroundService/
  AudioCaptureService/ExportFileProvider/AppUpgradeReceiver/
  六个 Initializer 各归既有簇或机制替代。

## 后果

- manifest 组件面闭合；1.4.2 证据八维完成
  （七维 + 组件映射）。
