# Phase 1167 证据 — app 入口 + widget + native 兜底

来源：`app/` 命名类。

## 入口

- `NbApplication` = Application 类。
- `MainActivity` = 主入口。
- `MissingNativeLibraryActivity extends Activity` =
  **native-lib 缺失兜底** —— `libglmath`（Phase 1120）/
  native 加载失败时显示的降级 Activity —— 证实即便在
  Android 上也 graceful-degrade。
- `AppUpgradeReceiver extends BroadcastReceiver` = 升级
  广播。
- `initializers/{AppStartup,Logging}Initializer` =
  androidx.startup `Initializer`。

## `widgets/` = 桌面 widget×8

```java
CreateNoteWidgetProvider        // 新建笔记
CreateRecordingWidgetProvider   // 新建录音
FolderNotesWidgetProvider + ConfigActivity   // 文件夹
NoteThumbnailWidgetProvider + ConfigActivity // 缩略图
RecentNotesWidgetProvider       // 最近
WidgetImageProvider             // widget 图供
（do2 = obf AppWidgetProvider）
```

8 个桌面 widget（4 provider + 2 config activity + 图供）。

## 语义

- `MissingNativeLibraryActivity` = native 加载失败的
  降级 —— 对 HarmonyOS **无 native** 的情况提供先例：
  原版也优雅降级（不是 fail-closed，而是功能降级）。
- widget = 桌面快捷（新建笔记/录音/文件夹/缩略图/
  最近）—— Harmony `FormExtensionAbility`。

## Harmony 决策

- `MissingNativeLibrary` → Harmony 原生库缺失时同样
  降级（math 渲染 fail-soft 而非 crash）。
- widget → Harmony `FormExtensionAbility` 卡片。

## 产出

- fixture `d02-app.mjs`（10 断言）。
- ADR-1111；中文报告。
