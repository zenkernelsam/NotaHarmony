# Phase 1376 证据 — 库笔记卡片上下文菜单原版图标

- 日期：2026-08-09
- 范围：`LibraryPage.NoteContextMenu` 的 `MenuItem` 增加 `startIcon` →
  原版 `ui_designsystem__*` 矢量。
- Replay：`docs/migration/replays/d02-original-note-context-menu-icons.mjs`
  （17/17）

## 原版证据（d5j.java）

原版菜单行是 `apb.f(icon=h1a, label)` 的 icon+label 结构。逐行确认：

- `sidebar_rename` → `ui_designsystem__edit`
- `favorite`/`unfavorite` → `ui_designsystem__favorite_outline` /
  `__unfavorite_outline`
- `duplicate` → `ui_designsystem__duplicate`
- `export` → `ui_designsystem__export`
- `export_options` → `ui_designsystem__share_options`（Harmony 未实现）
- `open_in_new_window` → `ui_designsystem__open_in_window`（Harmony 未实现）
- `show_in_folder` → `ui_designsystem__show_in_folder`
- `sort_to_folder` → `ui_designsystem__show_in_folder`（同图标）
- `copy_note_id` → `ui_designsystem__note_info`
- `report_note` → `ui_designsystem__alert_outline`（Harmony 未实现）
- `sidebar_delete` → `ue4.z()` = `ui_designsystem__trash`

## 新增资源

`_gen_menuicons.cjs` 追加 5 个 `menuicon_*`（favorite_outline /
unfavorite_outline / export / show_in_folder / note_info），输出到
`base/media/`。`edit.svg`、`selmenu_duplicate`、`selmenu_delete` 复用。

## 行为不变

菜单项 `onClick`/`enabled`/`builder` 子菜单全部保持原样，仅加图标；
`note.favorite` 控制 label 与图标同步切换。
