# Phase 1381 evidence：编辑器 ⋮ 选项菜单图标

## 目标

`NotePage.buildEditorOptionsMenu`（编辑器 ⋮ 选项菜单，原版 `o94` case14）
的两项补上图标。

## 原版证据

- `o94.java:279/283`：reveal_tapes_action → `tape_conceal`、
  hide_tapes_action → `tape_reveal`（图标反映当前态）。
- `ui_designsystem__settings_outline`：设置齿轮轮廓（单 path 描边），
  编辑器设置入口的扁平等价物。

## 图标映射（MenuElement.icon）

| MenuElement value | icon | 原版 drawable |
|---|---|---|
| `hide_tapes`（anyTapeRevealed） | `app.media.menuicon_tape_reveal` | `ui_tools__tape_reveal` |
| `reveal_tapes` | `app.media.menuicon_tape_conceal` | `ui_tools__tape_conceal` |
| `options_menu_app_settings` | `app.media.menuicon_settings` | `ui_designsystem__settings_outline` |

## 新增 media 资源

- `menuicon_settings.svg`（`ui_designsystem__settings_outline`，24×24）。
- 胶带两枚复用 Phase 1380 资产。

## 语义保持

- 仅加 `icon`；`pageTapeCount` 门控、`tapeToggleSignal++`、
  `navigateToSettings()` 不变。

## 验证

- Replay fixture `d02-original-editor-options-menu-icons.mjs`：6/6。
- `note@default` 静态构建绿。
