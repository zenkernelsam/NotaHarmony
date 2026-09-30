# Phase 1382：紧凑工具/插入菜单挂原版矢量图标

## 概述

紧凑/窄屏模式的工具+插入溢出菜单
（`EditorToolbar.buildCompactToolMenu`，原版 `x5f`/`fie`）原本纯文字。
本阶段为 8 项补 `MenuElement.icon`。

## 变更

- `note/src/main/ets/ui/editor/EditorToolbar.ets`：8 个 MenuElement 各加 icon。
- 新增 8 个 media SVG：menuicon_eraser_whole/eraser_partial/selectrect/
  text/paper/insert_media/camera/insert_math。

## 映射

whole_eraser→eraser_whole、partial_eraser→eraser_partial、
selection→selectrectangle_outline、add_text→text_outline、
add_files→paper_plain_outline、insert_photo→insert_media_fill_outline、
take_photo→camera_outline、insert_math→insert_math。

## 验证

- Replay fixture `d02-original-compact-tool-menu-icons.mjs`：18/18 全绿。
- 全量 Desktop Replay 基线、note@ohosTest、note@default 静态构建均绿。

## 兼容 / 风险

- 仅附加图标；`selectTool`/`onAddFiles`/`onInsertPhotos`/`onTakePhoto`/
  `onInsertMath` 回调与 `photoImportLeaseActive` 门控不变。
