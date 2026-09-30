# Phase 1371 报告 — 导航 / 对话框 / 溢出按钮改用原版矢量图标

## 改动概要

继编辑器工具条（1370）后，把导航返回、对话框关闭、溢出菜单、重排
上/下移等剩余 **Unicode 占位**图标全部换成原版 `ui_designsystem__*`
矢量字形，统一走 `ToolGlyph`（Shape+Path+viewPort24）管线。

| 占位 | 语义 | 原版资源 |
|---|---|---|
| `<` ×5 | 设置页返回 | `back_arrow`（ue4.r）|
| `‹` | Tape 返回 | `chevron_left` |
| `✕` ×2 | 关闭 | `close_med_regular` |
| `...`/`⋯`/`☰` | 溢出/抽屉 | `more` / `hamburger` |
| `▲`/`▼` | 工具重排 | `chevron_down`（▲ rot180）|

## 实现

- `ToolGlyphs.ets` 现 25 键（11 tool + 7 toolbar + 7 nav/dialog）。
- `more` 三实心点进 `f` 槽 contentColor 填充；其余描边进 `o` 槽。
- 12 个文件共 18 处占位替换，onClick/enabled/bindMenu/a11y 原样保留。

## 文件

- `note/src/main/ets/ui/components/ToolGlyphs.ets`
- `note/src/main/ets/ui/editor/{ToolboxSettingsDialog,PageOverviewPanel,PageManagerBar,NotePage,TapePatternPicker}.ets`
- `note/src/main/ets/ui/components/PageSettingsPanel.ets`
- `note/src/main/ets/ui/settings/{SettingsPage,WebDAVSettingsPage,RecentlyDeletedPage,DefaultTemplatePage,BackupPage}.ets`
- `note/src/main/ets/ui/library/LibraryPage.ets`
- `docs/migration/replays/d02-original-nav-action-glyphs.mjs`（新）
- `docs/migration/adr/ADR-1307-nav-dialog-action-glyphs.md`（新）
- `docs/migration/evidence/phase-1371-nav-dialog-action-glyphs.md`（新）

## 验证

- 新 fixture：46/46。
- 全量 Replay 基线：1224/1224。
- `note@default` / `note@ohosTest` clean 构建成功。

## 已知近似

`▲`/`▼` 是 `drag_handle` 拖拽重排的按钮等价；`▲`=`chevron_down` 旋转
180°（无 `chevron_up`）。见 ADR-1307。
