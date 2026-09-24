# Phase 668 — 原版 FolderNotesWidgetProvider 配置型数据卡片证据

日期：2026-09-24
对应 Replay：`docs/migration/replays/d05-original-folder-notes-card.mjs`

## 原版证据（decompiled_1.0.3）

### Provider 与配置绑定

- `sources/com/gingerlabs/notability/app/widgets/FolderNotesWidgetProvider.java`
  - `extends qk9` —— 与 RecentNotes 共用 RemoteViews 集合基类。
  - `g(context, i, mc7)`：`wyi.c(context, i)` 读绑定的 folderId →
    `euh.c` 解析 utf → `mc7Var.a(utf)` 查文件夹 →
    `xld(title=文件夹名, createIntent, headerIntent, collection)`。
  - createIntent = `CREATE_NOTE` + `putExtra("folder_id", wtf.e(utf))`；
    headerIntent = `VIEW` + `putExtra("folder_id", ...)`。
  - 配置/文件夹缺失 → `g()` 返回 null（qk9 显示加载/占位态）。
  - 空态 `app_widgets__widget_folder_no_notes` =
    "No notes in this folder"；未配置 `widget_folder_empty` =
    "Tap to open Notability"。
- `sources/defpackage/wyi.java`
  - `context.getSharedPreferences("widget_bindings", 0)`
    `.getString("folder_" + i)` / `"note_" + i` —— 按 appWidgetId
    的每实例绑定存取（FolderNotes=folderId，NoteThumbnail=noteId）。
- `FolderNotesConfigActivity.java` + manifest 声明 —— 添加部件时的
  文件夹选择配置活动。

## Harmony 对齐

- `forms_config.json`：`folder_notes_card`（2*4 默认，2*2/4*4 支持，
  与 RecentNotes 同基座）。
- `FolderNotesCard.ets`：`items` + `folderId`/`folderName`/`configured`
  LocalStorageProp；头部=文件夹名 → `folder_id` 落地；创建钮 →
  `launch_action=create_note` + `folder_id`；行 → `note_id`；
  未配置态 = "Tap to open Notability"（点按 → 编辑页）、空文件夹 =
  "No notes in this folder"；编辑入口 `postCardAction(message{edit:true})`。
- `FolderNotesFormFeed.ets`：`folder_notes_form_config.json`
  （formId→folderId，等价 widget_bindings）；`resolveFolderTargets`
  每实例解 folderId+folderName+notes（`getNotesByFolder` +
  `getAllFolders`）；推送复用 `pushNoteListForms` 共享引擎。
- `RecentNotesFormFeed.ets`：抽出通用 `pushNoteListForms(context,
  theme, pushes)` 引擎 —— 标题-only（theme=null，扩展侧）或
  缩略图 formImages（theme 非空，UIAbility 侧），缩略图跨实例按
  noteId 去重渲染。
- `FolderFormEditAbility`（type=formEdit）+ `FolderNotesEditPage`
  —— 对应原版配置活动；卡片/桌面长按经 `openFormEditAbility` 拉起，
  选定写回绑定并推标题。
- `OpenTargetIngress`：`folder_id` extra → `LANDING_FOLDER_PREFIX`
  队列 → LibraryPage `landInFolder`（先校验存在 —— 等价原版 g()
  文件夹缺失返回 null）→ `vm.setFolder`。
- `LaunchActionIngress`：`folder_id` extra → `LaunchRequest.folderId`
  → `createAndLaunch(folderId)` → `vm.createNote(folderIdOverride)`
  —— 新笔记建进指定文件夹，不改当前库位置。

## 适配差异（文档化）

1. 原版添加部件时强制走配置活动；Harmony formEdit 为后置编辑
   （卡片内入口/桌面长按）——未配置态显示原版同串
   "Tap to open Notability" 引导编辑。
2. 原版 SharedPreferences 按 appWidgetId 绑定；Harmony 按 formId
   存 filesDir JSON（无活动实例枚举 API —— 文档化适配）。
3. 缩略图仍两阶段（标题先行、UIAbility 侧补齐）——同 ADR-0634。

## fail-closed 保留

- NoteThumbnailWidgetProvider（单缩略图配置型部件）继续登记。
