# Phase 1380：工具箱设置工具菜单挂原版矢量图标

## 概述

工具槽 ⋯ 上下文菜单（`ToolboxSettingsDialog.toolMenu`，原版 `o94`/`xc2`
工具设置行菜单）原本纯文字。本阶段为可映射到原版 drawable 的项补
`MenuElement.icon`。

## 变更

- `note/src/main/ets/ui/editor/ToolboxSettingsDialog.ets`
  - `hide_tool` → `menuicon_hide`
  - `duplicate_tool` → `selmenu_duplicate`
  - `delete_tool` → `selmenu_delete`
  - `hide_tapes`/`reveal_tapes` → 动态 `menuicon_tape_reveal`/`menuicon_tape_conceal`
    （图标反映当前胶带显隐态，与原版一致）
- 新增 media：`menuicon_hide`、`menuicon_tape_reveal`、`menuicon_tape_conceal`。

## 保持无图标

`move_to_primary`/`move_to_secondary`（原版工具排序走拖拽，无对应图标）、
`tape_patterns`（子页导航项）。

## 验证

- Replay fixture `d02-original-toolbox-settings-menu-icons.mjs`：13/13 全绿。
- 全量 Desktop Replay 基线、note@ohosTest、note@default 静态构建均绿。

## 兼容 / 风险

- 仅附加图标；`hideTool`/`duplicateTool`/`deleteTool`/`onTapeToggle` 回调与
  `canDeleteTool`/`tapeCount`/`REVIEW`/`trayType` 门控不变。
