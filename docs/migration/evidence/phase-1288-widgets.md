# Phase 1288 证据 — app/widgets 5 桌面 widget

来源：`app/widgets/*.java`。

## Widget 提供器

```
CreateNoteWidgetProvider    extends do2   // 点击→新建笔记
CreateRecordingWidgetProvider            // 点击→新建录音
FolderNotesWidgetProvider   extends qk9   // 文件夹笔记列表（Glance 集合）
RecentNotesWidgetProvider   extends qk9   // 最近笔记列表
NoteThumbnailWidgetProvider extends ec0   // 笔记缩略图
    // Bitmap bitmapD = fzi.d(bitmap, w, h, f)  // 缩放渲染
WidgetImageProvider         extends ContentProvider  // image/png
FolderNotesConfigActivity / NoteThumbnailConfigActivity  // 配置
```

## `do2`/`qk9`/`ec0` = AppWidgetProvider/Glance 基类

`qk9` = Glance 集合 widget 提供者（`FolderNotes`/
`RecentNotes` 共用 —— RemoteViews 列表/网格）；
`do2`/`ec0` = 单元格/动作 widget；`fzi.d` = 位图缩放
（缩略图裁剪）。

## 语义

**Android 桌面 widget 层** —— 5 个 AppWidgetProvider
（新建笔记/录音快捷、文件夹+最近笔记列表、笔记
缩略图）+ ContentProvider 喂 PNG + 配置 Activity —
— 桌面快捷入口+笔记预览。

## Harmony 决策

AppWidgetProvider/Glance → Harmony `FormExtensionAbility`
+`formProvider`+`FormBinding`（卡片）—— widget 语义
映射为服务卡片；RemoteViews 列表 → Form 卡片 UI。

## 产出

- fixture `d02-widgets.mjs`（10 断言）。
- ADR-1232；中文报告。
