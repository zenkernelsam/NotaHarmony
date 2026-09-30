# Phase 1379：画布空白处长按菜单挂原版矢量图标

## 概述

画布空白处长按弹出的 `{PASTE, SELECT_ALL}` 菜单
（`NoteCanvasView.ClipboardPasteContextMenu`，对应原版 `yqa.f`/`m18.m0`）
原本只有文字项。本阶段为两个 `MenuItem` 补 `startIcon`。

## 变更

- `note/src/main/ets/ui/editor/NoteCanvasView.ets`
  - `paste` → `app.media.selmenu_paste`
  - `select_all` → `app.media.menuicon_select_all`
- 新增 media：`menuicon_select_all.svg`（`ui_designsystem__select_all`）。

## 映射

paste→paste_content_manager（复用 selmenu_paste）、select_all→select_all。

## 验证

- Replay fixture `d02-original-canvas-context-menu-icons.mjs`：9/9 全绿。
- 全量 Desktop Replay 基线、note@ohosTest、note@default 静态构建均绿。

## 兼容 / 风险

- 仅附加图标；PASTE 双源路径（元素剪贴板优先 / 系统图片兜底）与
  `photoImportBusy`、剪贴板可用性门控不变；SELECT_ALL 仍全量入选。
