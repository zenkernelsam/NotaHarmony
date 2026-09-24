# Phase 668 — 原版 FolderNotes 配置型数据卡片迁移

日期：2026-09-24
前置：Phase 667（`c7a27e0d`）

## 目标

将原版 `FolderNotesWidgetProvider`（qk9 子类 + 每实例文件夹绑定 +
`FolderNotesConfigActivity` 配置活动）迁移为 Harmony
`folder_notes_card` 服务卡片 + formEdit 配置页，并落地两个原版
`folder_id` extra 语义（VIEW 落地 / CREATE_NOTE 建进文件夹）。

## 原版行为（证据：FolderNotesWidgetProvider / wyi / 配置活动 / strings）

- `wyi.c(context, i)` = `widget_bindings["folder_"+appWidgetId]`
  —— 每个部件实例绑定一个文件夹。
- `g()` → `xld(title=文件夹名, CREATE_NOTE+folder_id,
  VIEW+folder_id, 该文件夹笔记)`；绑定/文件夹缺失 → null。
- 空态 "No notes in this folder"；未配置 "Tap to open Notability"。
- 行结构与 RecentNotes 同（缩略图/占位 + 标题 + 分隔线 + note_id）。

## Harmony 实现

- `forms_config.json`：`folder_notes_card`（2*4 默认，2*2/4*4）。
- `FolderNotesCard.ets`：folderId/folderName/configured 绑定；
  头部→`folder_id` 落地、创建钮→`create_note`+`folder_id`、
  行→`note_id`；未配置态点按/✎ → `postCardAction(message{edit})`。
- `FolderNotesFormFeed.ets`：`folder_notes_form_config.json` 绑定
  存取 + `resolveFolderTargets`（getAllFolders + getNotesByFolder）
  + 推送复用共享引擎。
- `RecentNotesFormFeed.ets`：抽出 `pushNoteListForms(context, theme,
  pushes)` 通用引擎 —— 两卡共用，缩略图跨实例去重渲染。
- `FolderFormEditAbility`（type=formEdit）+ `FolderNotesEditPage`：
  对应原版配置活动；`session.loadContent` + LocalStorage 传
  editFormId；选定 → 写回绑定 + 推标题。
- `NoteFormAbility`：onAddForm 按 NAME_KEY 分别登记两张数据卡；
  onFormEvent → `openFormEditAbility`；onUpdateForm/onRemoveForm
  双卡通吃。
- `OpenTargetIngress`：`folder_id` → `folder:<id>` 落地队列；
  LibraryPage `landInFolder` 校验存在后 `vm.setFolder`。
- `LaunchActionIngress`：`folder_id` → `LaunchRequest.folderId`；
  `createAndLaunch` 透传 → `vm.createNote(folderIdOverride)`。

## 适配差异（文档化）

1. 配置时机为后置编辑（formEdit）而非添加时强制配置；未配置态用
   原版同串引导。
2. 绑定存 filesDir JSON（无活动实例枚举/SharedPreferences 对应物）。
3. 缩略图两阶段推送同 ADR-0634。

## fail-closed 保留

- `NoteThumbnailWidgetProvider` —— 最后一张未实现部件，登记后续。

## 验收

- `d05-original-folder-notes-card.mjs`：30/30。
- 全量 Desktop Replay、clean + `note@ohosTest` + `note@default`
  构建全绿。

## 变更文件

- 新增：`note/src/main/ets/data/FolderNotesFormFeed.ets`、
  `note/src/main/ets/noteformability/pages/FolderNotesCard.ets`、
  `note/src/main/ets/noteformability/pages/FolderNotesEditPage.ets`、
  `note/src/main/ets/noteformeditability/FolderFormEditAbility.ets`、
  `docs/migration/replays/d05-original-folder-notes-card.mjs`、
  `docs/migration/evidence/phase-668-original-folder-notes-card.md`、
  `docs/migration/adr/ADR-0635-original-folder-notes-card.md`、本报告。
- 修改：`note/src/main/ets/data/RecentNotesFormFeed.ets`、
  `note/src/main/ets/data/OpenTargetIngress.ets`、
  `note/src/main/ets/data/LaunchActionIngress.ets`、
  `note/src/main/ets/noteformability/NoteFormAbility.ets`、
  `note/src/main/ets/ui/library/LibraryPage.ets`、
  `note/src/main/ets/ui/library/LibraryViewModel.ets`、
  `note/src/main/module.json5`、
  `note/src/main/resources/base/profile/forms_config.json`、
  `note/src/main/resources/base/profile/main_pages.json`、
  `note/src/main/resources/base/element/string.json`、
  `note/src/main/resources/zh_CN/element/string.json`、
  `docs/migration/replays/d05-original-widget-action-cards.mjs`、
  `docs/migration/replays/d05-original-recent-notes-card.mjs`、
  `docs/migration/replays/d05-original-launcher-shortcuts.mjs`、
  三份跟踪文档。
