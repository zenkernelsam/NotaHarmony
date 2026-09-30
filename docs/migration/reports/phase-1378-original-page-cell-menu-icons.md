# Phase 1378：页缩略图长按菜单挂原版矢量图标

## 概述

页概览网格里长按某一页弹出的上下文菜单（`PageOverviewPanel.buildCellMenu`）
原本只有文字项。本阶段为 9 个页操作 `MenuItem` 补上 `startIcon`，映射到
原版 `n9j`/`fd2` 页菜单的对应 vector drawable，与 Phase 1377 的
`PageManagerBar` 页操作菜单使用同一套图标资产。

## 变更

- `note/src/main/ets/ui/editor/PageOverviewPanel.ets`
  - `buildCellMenu` 的 9 个 `MenuItem` 各加 `startIcon`。
- 新增 media 资源：
  - `menuicon_add_page.svg`（`ui_designsystem__add_page`）
  - `menuicon_select_circle.svg`（`ui_designsystem__check_circle_fill`）
- 复用：`selmenu_cut/copy/paste/duplicate/delete`、`menuicon_rotate_page`、
  `menuicon_clear_page`。

## 映射

add_page→add_page、cut→cut、copy→copy、paste→paste_content_manager、
duplicate→duplicate、rotate→rotate_page、clear→clear_page、delete→trash、
pages_menu_select→check_circle_fill。

## 验证

- Replay fixture `d02-original-page-cell-menu-icons.mjs`：21/21 全绿。
- 全量 Desktop Replay 基线、note@ohosTest、note@default 静态构建均绿
  （见下方收尾验证）。

## 兼容 / 风险

- 仅附加图标，`content`/动作回调/显隐门控不变；a11y 仍由文字项提供。
- 两处页菜单（PageManagerBar 顶部菜单 + 缩略图长按菜单）现在图标一致。
