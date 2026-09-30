# Phase 1380 evidence：工具箱设置工具菜单图标

## 目标

`ToolboxSettingsDialog.toolMenu`（工具槽 ⋯ 上下文菜单，原版 `o94`/`xc2`
工具设置行菜单）的可映射项补上图标。

## 原版证据

- `xc2.java:78`：delete/hide/show 一行三态——
  `z2`→`trash`+`settings_delete_tool`、`z`→`hide`+`settings_hide_tool`、
  else→`show`+`settings_show_tool`。
- `o94.java:259`：duplicate_tool → `ui_designsystem__duplicate`。
- `o94.java:279/283`：reveal_tapes_action → `ui_tools__tape_conceal`、
  hide_tapes_action → `ui_tools__tape_reveal`（图标反映当前态）。
- 原版工具排序用拖拽（`settings_reorder_tool`/`pd8`/`md8.I`），
  无 move_to_primary/secondary 图标；`tape_patterns` 为子页导航。

## 图标映射（MenuElement.icon）

| MenuElement value | icon | 原版 drawable |
|---|---|---|
| `hide_tool` | `app.media.menuicon_hide` | `ui_designsystem__hide` |
| `duplicate_tool` | `app.media.selmenu_duplicate` | `ui_designsystem__duplicate` |
| `delete_tool` | `app.media.selmenu_delete` | `ui_designsystem__trash` |
| `hide_tapes`（anyTapeRevealed） | `app.media.menuicon_tape_reveal` | `ui_tools__tape_reveal` |
| `reveal_tapes` | `app.media.menuicon_tape_conceal` | `ui_tools__tape_conceal` |

无图标：`move_to_primary`/`move_to_secondary`/`tape_patterns`（适配/子页导航）。

## 新增 media 资源

- `menuicon_hide.svg`（`ui_designsystem__hide`，24×24）
- `menuicon_tape_reveal.svg`（`ui_tools__tape_reveal`，23×18）
- `menuicon_tape_conceal.svg`（`ui_tools__tape_conceal`，23×20）

复用：`selmenu_duplicate`、`selmenu_delete`。

## 验证

- Replay fixture `d02-original-toolbox-settings-menu-icons.mjs`：13/13。
- `note@default` 静态构建绿。
