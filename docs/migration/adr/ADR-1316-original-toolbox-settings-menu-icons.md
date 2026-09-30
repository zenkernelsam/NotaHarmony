# ADR-1316：工具箱设置工具菜单挂原版矢量图标

- 状态：Accepted
- 关联：Phase 1380、ADR-1311/1313/1314/1315（菜单图标化）、evidence `phase-1380-original-toolbox-settings-menu-icons.md`

## 背景

`ToolboxSettingsDialog.toolMenu`（工具槽的 ⋯ 上下文菜单，对应原版 `o94`/`xc2`
的工具设置行菜单）此前是纯文字 `MenuElement`。原版的每行 `go5.b(h1a, …)`
菜单项都带 vector painter。

## 决策

为可映射到原版 drawable 的项加 `MenuElement.icon`；Harmony 适配项保留无图标：

| Harmony 项 | icon | 原版 drawable | 证据 |
|---|---|---|---|
| hide_tool | `menuicon_hide` | `ui_designsystem__hide` | xc2.java:78（z 分支） |
| duplicate_tool | `selmenu_duplicate` | `ui_designsystem__duplicate` | o94.java:259 |
| delete_tool | `selmenu_delete` | `ui_designsystem__trash` | xc2.java:78（z2 分支，`ue4.z()`） |
| hide_tapes | `menuicon_tape_reveal` | `ui_tools__tape_reveal` | o94.java:283 |
| reveal_tapes | `menuicon_tape_conceal` | `ui_tools__tape_conceal` | o94.java:279 |

### 图标反映当前态（非动作态）

原版 `o94` 把 `hide_tapes` 动作配 `tape_reveal` 图标、`reveal_tapes` 动作配
`tape_conceal` 图标——图标描绘的是**当前**胶带显隐状态，而非动作结果。
Harmony 侧用 `anyTapeRevealed` 三目同时切换 label 与 icon，保持同一映射。

### 保持无图标的适配项

- `move_to_primary` / `move_to_secondary`：Harmony 工具槽管理适配；原版
  工具排序走拖拽（`settings_reorder_tool`/`pd8`/`md8.I`），无对应图标。
- `tape_patterns`：进入胶带图案子页的导航项，原版设置行菜单未单独配图标。

## 兼容性

- 仅加 `icon`，`value`/`action`/门控（`canDeleteTool`、`tapeCount`、`REVIEW`
  类型、`trayType`）不变；a11y 仍由 `value` 文字提供。
- 新增 `menuicon_hide`、`menuicon_tape_reveal`、`menuicon_tape_conceal`
  三个 media SVG；`selmenu_duplicate`、`selmenu_delete` 复用既有资产。
