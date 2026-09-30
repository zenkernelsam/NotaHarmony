# Phase 1376 报告 — 库笔记卡片上下文菜单原版图标

- 日期：2026-08-09
- 结果：完成；`note@default` 与 `note@ohosTest` 静态构建成功。
- ADR：`ADR-1312-original-note-context-menu-icons.md`
- 证据：`phase-1376-original-note-context-menu-icons.md`
- Replay：`d02-original-note-context-menu-icons.mjs`（17/17）

## 本 Phase 做了什么

把 `LibraryPage.NoteContextMenu` 的 8 个 `MenuItem` 从纯文本升级为
icon+label，逐项挂 `startIcon` → 原版矢量（复刻 `d5j`）。

## 改动文件

- `_gen_menuicons.cjs`：追加 `menuicon_{favorite,unfavorite,export,
  showfolder,noteinfo}` 映射，新增 5 个 SVG。
- `note/src/main/resources/base/media/menuicon_*.svg`：新增 5 个。
- `note/src/main/ets/ui/library/LibraryPage.ets`：`NoteContextMenu` 每项加
  `startIcon`；favorite/unfavorite 按态切换 outline 图标；
  move_to_folder 复用 show_in_folder（原版 sort_to_folder 同）。

## 验证

- `d02-original-note-context-menu-icons.mjs`：17/17。
- `note@default`/`note@ohosTest` 静态构建成功。
- 全量 Desktop Replay 基线：全绿。
