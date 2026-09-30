# Phase 1338 证据 — 编辑器 UI 层

来源：`ui/editor/`（11 文件）+`ui/components/`（11 overlay）。

## `ui/editor` 编辑器骨架

- `EditorToolbar` —— 工具栏：`toolTypeLabel`+onboarding
  tip（原版字符串 `data_onboarding__first_text_tooltip_
  text`）+分享动作（`feature_note__toprighttoolbar_
  share_action`→`ui_share__chip_note`）——**原版资源
  字符串键保留**。
- `NoteCanvasView`/`NotePage`/`NoteZoomView` —— 画布/
  页/缩放。
- `PageManagerBar`/`PageOverviewPanel` —— 页管理/概览。
- `RecordingPanel`/`TapePatternPicker`/`ToolboxSettingsDialog`
  /`EditorViewModel`/`ArkUIStylusAdapter` —— 录音面板/
  胶带样式/工具箱/VM/触控笔适配。

## `ui/components` overlay 层

`ColorPicker`/`ImageCropOverlay`/`MathEditorOverlay`/
`SelectionOverlay`(+`Layout`)/`TextBlockOverlay`/
`WidthSlider`/`ImportDetailsSheet`/`OnboardingTipBubble`/
`PageSettingsPanel`/`PdfPasswordDialog` —— 取色/裁剪/
数学/选区/文本块/线宽/导入/引导/页设置/PDF 密码。

## Harmony 决策

编辑器 UI = ArkUI 组件 + **原版资源字符串键保留**
（onboarding/share/工具标签）—— UI 文案与原版一致。

## 产出

- fixture `d02-editor-ui.mjs`（10 断言）。
- ADR-1281；中文报告。
