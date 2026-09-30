# ADR-1258：UI 层覆盖

## 状态

已接受（Phase 1314）。

## 决策

Harmony `ui/` = ArkUI 全实现（编辑器/库/设置/主题/
组件覆层）—— 对照原版 Compose UI 语义保真。

## 理由

`ui/`(31)：editor(11：Stylus/Toolbar/Canvas/Page/Zoom/
PageManager/Overview/Recording/Tape/ToolboxSettings)+
components(11：Color/Crop/Import/Math/Onboarding/Page
Settings/PdfPassword/Selection/TextBlock/WidthSlider)+
library+settings(5：含 WebDAV 备份）+theme —— UI 全
功能 ArkUI 移植。

## 后果

UI 全功能映射原版 —— ArkUI 语义保真（含 WebDAV
备份等平台增强）。
