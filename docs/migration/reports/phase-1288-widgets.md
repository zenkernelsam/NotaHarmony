# Phase 1288 报告 — 桌面 widget

## 完成内容

- 5 个 AppWidgetProvider：`CreateNote`/`CreateRecording`
  （快捷新建）+`FolderNotes`/`RecentNotes`（`qk9` Glance
  集合列表）+`NoteThumbnail`（`ec0`+`fzi.d` 位图缩放
  渲染）+`WidgetImageProvider`（ContentProvider
  image/png）+`FolderNotesConfig`/`NoteThumbnailConfig`
  配置 Activity —— 桌面快捷+笔记预览 widget。

## 产出

- evidence `phase-1288-widgets.md`
- fixture `d02-widgets.mjs`（10/10）
- ADR-1232
