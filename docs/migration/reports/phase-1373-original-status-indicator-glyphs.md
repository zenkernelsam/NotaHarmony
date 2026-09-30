# Phase 1373 报告 — 状态/指示标记原版矢量字形迁移

- 日期：2026-08-09
- 结果：完成；全量 Replay 基线全绿；`note@default` 与 `note@ohosTest`
  静态构建成功。
- ADR：`ADR-1309-original-status-indicator-glyphs.md`
- 证据：`phase-1373-original-status-indicator-glyphs.md`
- Replay：`d02-original-status-indicator-glyphs.mjs`（28/28）

## 本 Phase 做了什么

把库卡片、页缩略图、多选勾选圈与页导航上的状态/指示标记，从
Unicode/Emoji 占位（`✓`、`♥`、`🎙`、`🔖`、`⋯`、`<`/`>`）迁到原版
`ui_designsystem__*` 矢量字形。

## 改动文件

- `_gen_toolglyphs.cjs`：新增 `favorite_fill`、`record_mic_outline`、
  `record_mic_fill`、`general_check_med_reg`、`check_tiny_bold`、`edit`、
  `checkmark_circle`、`circle_empty_med_outline` 共 8 个指示字形（映射到
  `f`/`o` 槽）。`ToolGlyphs.ets` 重生成到 38 键。
- `note/src/main/ets/ui/components/ToolGlyph.ets`：`contentColor` prop
  类型放宽为 `ResourceColor`。
- `note/src/main/ets/ui/library/LibraryPage.ets`：`♥`×2 → `favorite_fill`；
  `🎙`×2 → `record_mic_outline`；`✓`×2 → `general_check_med_reg`；
  `SelectCircle` → `checkmark_circle`/`circle_empty_med_outline`；
  `⋯` `NoteMenuButton` → `more`。
- `note/src/main/ets/ui/editor/PageManagerBar.ets`：`🔖` →
  `bookmark_tall_fill`；`<`/`>` 翻页 → `chevron_left`/`chevron_right`
  （`NavigationButton` 签名收窄）。
- `note/src/main/ets/ui/editor/PageOverviewPanel.ets`：`🔖` →
  `bookmark_tall_fill`；选择态圆点 → `checkmark_circle`/
  `circle_empty_med_outline`。
- `note/src/main/ets/ui/editor/EditorToolbar.ets`：内容管理选择态圆点 →
  `checkmark_circle`/`circle_empty_med_outline`。

## 更新/新增 Replay

- 新增 `d02-original-status-indicator-glyphs.mjs`。
- 更新锚点：`d02-original-folder-dialog-labels`、`d02-original-library-favorites`、
  `d02-original-library-multi-select`、`d02-original-nav-action-glyphs`（more 3→4）、
  `d02-original-page-bookmark-parity`、`d02-page-bar-shared-lease-bound`、
  `d02-original-editor-toolbar-glyphs`（计数 30→38）。

## 无障碍

`folder_selected`、`select_note`、`note_actions`、`bookmark_page`、
`previous_page`/`next_page` 标签全部保留。

## 验证

- 全量 Desktop Replay 基线：全绿。
- `note@default` clean 静态构建：成功。
- `note@ohosTest` clean 静态构建：成功。
