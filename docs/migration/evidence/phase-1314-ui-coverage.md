# Phase 1314 证据 — Harmony `ui/` 层覆盖（对照原版 UI）

来源：`note/src/main/ets/ui/`（31 文件）。

## UI 分层（对照原版 Compose UI）

```
components(11)  ColorPicker/ImageCropOverlay/
                ImportDetailsSheet/MathEditorOverlay/
                OnboardingTipBubble/PageSettingsPanel/
                PdfPasswordDialog/SelectionOverlay(+Layout)/
                TextBlockOverlay/WidthSlider
library(2)      LibraryPage/LibraryViewModel ≈ 原版库
settings(5)     SettingsPage/BackupPage/DefaultTemplate
                Page/RecentlyDeletedPage/WebDAVSettingsPage
theme(2)        EditorTheme/ThemeStore
editor(11)      ArkUIStylusAdapter/EditorToolbar/Editor
                ViewModel/NoteCanvasView/NotePage/NoteZoom
                View/PageManagerBar/PageOverviewPanel/
                RecordingPanel/TapePatternPicker/
                ToolboxSettingsDialog
```

## 语义

- 编辑器 UI 全套（触控笔适配/工具栏/画布/页/缩放/
  页管理/总览/录音面板/胶带图案/工具箱设置）。
- 组件覆层（取色/裁剪/导入详情/数学编辑/引导气泡/
  页设置/PDF 密码/选择/文本块/粗细滑块）。
- 库/设置/主题 —— `WebDAVSettingsPage`（WebDAV 备份
  设置）等。

## Harmony 决策

UI 层 = ArkUI 组件全实现（编辑器/库/设置/主题/组件
覆层）—— 对照原版 Compose UI 语义保真。

## 产出

- fixture `d02-ui-coverage.mjs`（10 断言）。
- ADR-1258；中文报告。
