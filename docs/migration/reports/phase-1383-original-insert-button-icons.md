# Phase 1383：工具栏内联插入按钮挂原版图标 + add_files 映射校正

## 概述

原版插入动作（`qc.java`）是 `apb.f` icon+label 下拉菜单。Harmony 宽屏
`!compact` 分支此前用 4 个纯文字内联按钮；本阶段收敛为 `InsertButton`
（icon+label），并校正 `add_files` 图标映射。

## 变更

- `note/src/main/ets/ui/editor/EditorToolbar.ets`
  - 新增 `InsertButton(label, icon, onTap)` @Builder（Image 图标 + 13pt 文字，
    保留 height(32)/enabled/lease-guard）。
  - 4 个内联插入按钮改用 InsertButton 挂图标。
  - 紧凑菜单 `add_files` 图标 `menuicon_attach_file` → `menuicon_paper`
    （qc.java:65 → `paper_plain_outline`）。
- 新增 media：`menuicon_paper.svg`；删除未引用的 `menuicon_attach_file.svg`。

## 校正点

`add_files` 原版图标是 `paper_plain_outline`（纸张），不是 `attach_file`
（回形针）——Phase 1382 误映，本阶段按 qc.java 校正。

## 验证

- Replay `d02-original-insert-button-icons.mjs`：10/10 全绿。
- 同步更新 3 个受影响的旧 fixture。
- 全量 Desktop Replay 基线、note@ohosTest、note@default 静态构建均绿。

## 兼容 / 风险

- `enabled` + `photoImportLeaseActive` 门控收敛进 InsertButton，语义不变；
  `onAddFiles`/`onInsertPhotos`/`onTakePhoto`/`onInsertMath` 回调原样。
- `add_gif` 仍未移植（原版条件项，Harmony 无 GIF 插入入口）。
