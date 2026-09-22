# Phase 541 — 原版笔记上下文菜单补齐（Harmony 证据）

日期：2026-09-22
范围：`note/src/main/ets/ui/library/LibraryPage.ets`、`LibraryViewModel.ets`、
`RepositoryInterfaces.ets`、`NoteRepositoryImpl.ets`、双语言字符串、专项 replay。

## 原版证据链（decompiled_1.0.3）

`d5j.java` 笔记卡片上下文菜单（按 R.string 出现序）：

| 序 | 项 | 字符串 | 图标 |
|---|---|---|---|
| 1 | Rename | `feature_library__sidebar_rename` | `ui_designsystem__edit` |
| 2 | Favorite/Unfavorite | `feature_library__favorite`/`unfavorite` | `favorite_outline`/`unfavorite_outline` |
| 3 | Duplicate | `feature_library__duplicate` | `duplicate` |
| 4 | Export | `feature_library__export` | `export` |
| 5 | Export options | `feature_library__export_options` | `share_options` |
| 6 | Open in new window | `feature_library__open_in_new_window` | `open_in_window` |
| 7 | Show in folder | `feature_library__show_in_folder` | `show_in_folder` |
| 8 | Sort to folder | `feature_library__sort_to_folder` | `show_in_folder` |
| 9 | Copy note ID | `feature_library__copy_note_id` | `note_info` |
| 10 | Report note | `feature_library__report_note` | `alert_outline` |
| 11 | Delete | `feature_library__sidebar_delete` | — |

`d5j.java:112-268` 顺序固定；`gj9` 按当前收藏态翻转标签/图标（Phase 537
已落地）。Export options/Open in new window/Report 为条件渲染项。

## Harmony 落地

`NoteContextMenu` 现按原版可移植子集顺序渲染：
Rename → Favorite/Unfavorite → Duplicate → Export → Show in folder →
Move to folder（≡sort_to_folder）→ Copy note ID → Delete。

- **Rename**：新增 `noteDialog`（复用 `NameDialog`，新增
  `showDecoration` 门——文件夹对话框传 true，笔记重命名不显示装饰区）；
  `VM.renameNote` → `repo.renameNote` → `updateNoteTitle`（原版
  SET_TITLE op 管线，支持 history）；成功后用物化 `getNote` 回填
  行投影 + `applySort`（TITLE 序可重排）。
- **Duplicate**：`NoteExporter.exportNote` → `NoteImporter.importFromData`
  无损包往返；导入器 `allocateImportedNoteId` 在源存在时分配新 id——
  等价原版复制语义（op 史不复制，登记差异）。
- **Export**：`NoteExporter.exportToFile(context, id, title)` 单笔记
  .note 包 + 结果 toast。
- **Show in folder**：`vm.showNoteInFolder` → `setFolder(note.folderId)`
  （folder 选择复位 dk9 分区为 ALL_NOTES，与原版一致）；未归档笔记
  菜单项置灰。
- **Copy note ID**：`pasteboard.createPlainTextData(note.id)` +
  `getSystemPasteboard().setData` + toast。

## 验证

- `d02-original-note-context-menu.mjs`：43 断言（d5j 顺序锚点 +
  Harmony 锚点 + 可移植子集顺序模型）。
- 全套 replay：436 PASS 0 FAIL。
- `note@default`、`note@ohosTest`：BUILD SUCCESSFUL。

## 登记差异

- `export_options`（分享面板）、`open_in_new_window`（多窗口）、
  `report_note`（反馈服务）不可移植，未实现——登记。
- Duplicate 经包往返生成新 op 历史起点（原版为 Realm 行级复制）；
  结果对库投影等价。
- Show in folder 对未归档笔记置灰（原版该项语义仅对有文件夹者有意义）。
