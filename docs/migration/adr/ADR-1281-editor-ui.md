# ADR-1281：编辑器 UI 层

## 状态

已接受（Phase 1338）。

## 决策

编辑器 UI = ArkUI 组件 + **原版资源字符串键保留**
—— UI 文案与原版一致。

## 理由

`ui/editor`（EditorToolbar 保留原版字符串键
`data_onboarding__first_text_tooltip_text`/分享
`feature_note__toprighttoolbar_share_action`；Canvas/
Page/Zoom/PageManager/Recording/Toolbox/ViewModel/
StylusAdapter）+`ui/components` 11 overlay（取色/裁剪/
数学/选区/文本块/线宽/导入/引导/页设置/PDF 密码）。

## 后果

编辑器 UI 覆盖完整且文案键名与原版一致 —— UI 保真。
