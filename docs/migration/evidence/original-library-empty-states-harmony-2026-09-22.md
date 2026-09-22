# Phase 549 — 原版库分区/文件夹空态（Harmony 证据）

日期：2026-09-22
范围：`note/src/main/ets/ui/library/LibraryPage.ets`、双语言字符串、
专项 replay。

## 原版证据链（decompiled_1.0.3）

`hf0.java` 按 `yw3` 空态描述符渲染（图标 + 可选标题 + 正文）：

- `rw3`（ALL_NOTES）：`lets_get_started` + `tap_on_the_create_button…`
- `vw3`（RECENT）：`empty_recent_notes_title`/`_body` + recents_xxlrg
- `tw3`（FAVORITES）：`empty_favorite_notes_title`/`_body` +
  favorite_xxlrg
- `xw3`（UNFILED）：`empty_unfiled_notes_title`/`_body` + folder_xxlrg
- `ww3`（SHARED）：`empty_shared_notes_*`（不可移植——无共享）
- `sw3`（空文件夹）：`empty_folder_body`，无标题（`b(null, …)`）
- `uw3`（有子项的空文件夹）：`empty_folder_with_children_body`，
  携带 `empty_folder_subfolder_count`/`empty_folder_note_count`
  复数计数（"%d folder(s)"/"%d note(s)"），无标题；正文含 HTML
  `<b>` 加粗（Harmony 纯文本——登记）。

## Harmony 落地

- `emptyStateIcon()`/`emptyStateHasTitle()`/`emptyStateTitle()`/
  `emptyStateBody()` 帮助函数按 `currentFolderId`/`currentSection`
  分派；搜索激活时保留 `no_matching_notes`。
- 文件夹有子文件夹时渲染计数正文（子文件夹数 + 笔记数=0——该态
  仅在文件夹投影为空时出现）；`getPluralStringSync` 在本 SDK 仅
  有异步 `getPluralString`，故以单/复数两种正文变体替代。
- 新增 9 条双语言字符串（EN 值与原版一致；HTML `<b>` 去标签）。

## 差异登记

- 图标为 ♥/🕘/📂/📁/📝 字形而非 xxlrg 矢量；HTML 加粗省略；
  计数复数用双正文变体实现（SDK 无同步 plural API）；SHARED 空态
  不可移植。
