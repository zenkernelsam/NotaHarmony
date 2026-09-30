# Phase 1381：编辑器 ⋮ 选项菜单挂原版矢量图标

## 概述

编辑器右上 ⋮ 选项菜单（`NotePage.buildEditorOptionsMenu`，原版 `o94`
case14）原本纯文字。本阶段为两项补 `MenuElement.icon`。

## 变更

- `note/src/main/ets/ui/editor/NotePage.ets`
  - `hide_tapes`/`reveal_tapes` → 动态 `menuicon_tape_reveal`/`menuicon_tape_conceal`
    （图标反映当前态，沿用 Phase 1380 的 o94 证据）
  - `options_menu_app_settings` → `menuicon_settings`（齿轮轮廓）
- 新增 media：`menuicon_settings.svg`。

## 验证

- Replay fixture `d02-original-editor-options-menu-icons.mjs`：6/6 全绿。
- 全量 Desktop Replay 基线、note@ohosTest、note@default 静态构建均绿。

## 兼容 / 风险

- 仅附加图标；`pageTapeCount` 门控、`tapeToggleSignal++`、
  `navigateToSettings()` 不变。
