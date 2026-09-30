# ADR-1317：编辑器 ⋮ 选项菜单挂原版矢量图标

- 状态：Accepted
- 关联：Phase 1381、ADR-1316（工具设置菜单图标）、evidence `phase-1381-original-editor-options-menu-icons.md`

## 背景

`NotePage.buildEditorOptionsMenu`（编辑器右上 ⋮ 选项菜单，对应原版 `o94`
case14）有两项：`hide_tapes`/`reveal_tapes`（有 tape 时）与
`options_menu_app_settings`。此前是纯文字 `MenuElement`。

## 决策

为两项加 `MenuElement.icon`：

| Harmony 项 | icon | 原版 drawable | 证据 |
|---|---|---|---|
| hide_tapes | `menuicon_tape_reveal` | `ui_tools__tape_reveal` | o94.java:283 |
| reveal_tapes | `menuicon_tape_conceal` | `ui_tools__tape_conceal` | o94.java:279 |
| options_menu_app_settings | `menuicon_settings` | `ui_designsystem__settings_outline` | 编辑器设置入口齿轮 |

胶带图标沿用 Phase 1380 引入的"图标反映当前态"约定（hide 配 reveal、
reveal 配 conceal），与该处共用同一份 `o94` 证据。
`menuicon_settings` 用 `settings_outline`（齿轮轮廓单 path，黑白描边），
是设置项的扁平版等价物——编辑器工具栏的 `settings` 仍是 5 层 `m4f`，
菜单里用单描边轮廓即可。

## 兼容性

- 仅加 `icon`，`value`/`action`/`pageTapeCount` 门控不变。
- `tapeToggleSignal++` 与 `navigateToSettings()` 语义保持。
- 新增 `menuicon_settings.svg`；两个胶带 SVG 复用 Phase 1380 资产。
