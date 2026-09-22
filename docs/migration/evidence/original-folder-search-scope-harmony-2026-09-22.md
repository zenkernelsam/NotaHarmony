# Phase 548 — 原版文件夹搜索域（Harmony 证据）

日期：2026-09-22
范围：`note/src/main/ets/ui/library/LibraryViewModel.ets`、
`LibraryPage.ets`、双语言字符串、专项 replay。

## 原版证据链（decompiled_1.0.3）

- `bk9.java`：`FolderFilter(name, isShowingAllNotes)`——文件夹搜索态。
- `yj9.java:852`：搜索框占位符在选中文件夹时为
  `feature_library__search_in_folder`（"Search in \"%s\""），否则
  `feature_library__search`。
- `yj9.java:1726`：搜索激活且 `bk9` 非空时，列表控件行渲染
  `folder-filter-toggle` 项（`h74`）。
- `mhh.java`：该项 = "Show results for all notes" 标签 +
  `e9e.a` 开关（绑定 `bk9Var.b`，`km3` 派发切换）。
- 语义：文件夹内搜索默认限定文件夹；开关打开后范围扩至全部笔记，
  但不离开该文件夹视图。

## Harmony 落地

- VM：`searchAllNotes` 标志（默认 false），`setFolder`/`setSection`
  重置（含失败回滚恢复）；`queryNotes` 在
  `searchAllNotes && folderId !== null` 时改走
  `searchNotes(query, null)`；新增 `setSearchAllNotes(on, query)`。
- 页面：占位符 `searchPlaceholder()`（文件夹态 =
  `search_in_folder`+文件夹名）；搜索激活且处于文件夹时渲染
  "显示所有笔记的结果" + Switch；`setSearchAllNotes` 走
  `beginNotesRequest`/`isCurrentNotesRequest` 同款守卫。
- 新增 `search_in_folder`/`search_show_all_notes` 双语言字符串
  （EN 值与原版一致）。

## 差异登记

- 原版开关为结果区控件行内 chip；Harmony 渲染为搜索栏下方一行
  （登记）。Switch 控件替代原版 e9e 开关（等价）。
