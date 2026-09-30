# Phase 1374 报告 — 子面板/拖拽柄/剩余指示标记矢量化

- 日期：2026-08-09
- 结果：完成；`note@default` 与 `note@ohosTest` 静态构建成功。
- ADR：`ADR-1310-original-subpanel-indicator-glyphs.md`
- 证据：`phase-1374-original-subpanel-indicator-glyphs.md`
- Replay：`d02-original-subpanel-indicator-glyphs.mjs`（16/16）

## 本 Phase 做了什么

收尾剩余零散 Unicode/Emoji 指示占位，统一到原版矢量：分享子面板
`›`/`‹`、缩放视图 `≡` 拖拽柄、设置/导入单 `✓`、导入单排序 `↑`/`↓`、
调色板 `+`，以及两个桌面卡片的 `✎` 编辑角标。

## 改动文件

- `_gen_toolglyphs.cjs`：新增 `drag_handle`（o 槽）。`ToolGlyphs.ets` 39 键。
- `note/src/main/resources/base/media/edit.svg`：新增（复刻
  `ui_designsystem__edit`）。
- `note/src/main/ets/ui/editor/EditorToolbar.ets`：`›`×2 → `chevron_right`；
  `‹`×2 → `chevron_left`。
- `note/src/main/ets/ui/editor/NoteZoomView.ets`：`≡` → `drag_handle`
  （新增 import）。
- `note/src/main/ets/ui/settings/SettingsPage.ets`：`✓`×2 →
  `general_check_med_reg`。
- `note/src/main/ets/ui/components/ImportDetailsSheet.ets`：`↑`/`↓` →
  `chevron_down`(rot180)/`chevron_down`；`✓` → `general_check_med_reg`
  （新增 import）。
- `note/src/main/ets/ui/components/ColorPicker.ets`：`+` → `plus`
  （新增 import）。
- `noteformability/pages/FolderNotesCard.ets`、`NoteThumbnailCard.ets`：
  `✎` → `Image(app.media.edit)` + `.fillColor()`（widget 受限不用 ToolGlyph）。

## Replay

- 新增 `d02-original-subpanel-indicator-glyphs.mjs`。
- 更新 `d02-original-editor-toolbar-glyphs.mjs` 计数 38→39。

## 验证

- `note@default` clean 静态构建：成功（`app.media.edit` 解析通过）。
- `note@ohosTest` clean 静态构建：成功。
- 全量 Desktop Replay 基线：全绿。
