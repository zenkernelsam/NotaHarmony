# Phase 669 — 原版 NoteThumbnail 配置型单缩略图卡片迁移

日期：2026-09-24
前置：Phase 668（`69c6a7c3`）

## 目标

将原版 `NoteThumbnailWidgetProvider`（ec0 子类 + 每实例笔记绑定 +
`NoteThumbnailConfigActivity` "Choose a note" 配置活动）迁移为
Harmony `note_thumbnail_card` 服务卡片 + formEdit 笔记选择页。
至此原版 5 个 widget provider 全部落地。

## 原版行为（证据：NoteThumbnailWidgetProvider / wyi / 配置活动 / widget_info / strings）

- `wyi.e(context, i)` = `widget_bindings["note_"+appWidgetId]` ——
  每个部件实例绑定一篇笔记（与 FolderNotes 同一 SharedPreferences
  机制）。
- `g()`：绑定笔记 → `xf9` 首页位图 → `thumbnail_image`
  （contentDescription=标题）；无图 → `thumbnail_placeholder`。
- 点击：已配置 `VIEW` + `note_id`（ttf.toString()）；未配置
  `MAIN` + `LAUNCHER` 纯拉起。
- widget_info：40dp min / 2×2 targetCell / 双向 resize /
  190dp max / configure=NoteThumbnailConfigActivity。
- 配置活动：笔记列表 + `query` 搜索（widget_note_picker_search_hint）；
  "Choose a note" / "No notes yet"。

## Harmony 实现

- `forms_config.json`：`note_thumbnail_card`（2*2 默认 —
  对应 2×2 targetCell；1*2/2*2/2*4/4*4 覆盖 40–190dp resize）。
- `NoteThumbnailCard.ets`：noteId/thumb/title/configured 绑定；
  `memory://` 缩略图 + 标题 / 占位图标；点击已配置 → router
  `note_id`（OpenTargetIngress）；未配置 → 纯拉起 NoteAbility；
  ✎ → `postCardAction(message{edit:true})`。
- `NoteThumbnailFormFeed.ets`：`note_thumbnail_form_config.json`
  （formId→noteId = widget_bindings）+ 生命周期注册/注销 +
  `setNoteThumbnailFormNote` 配置写回 + `refreshNoteThumbnailForms`
  （UIAbility 侧 formImages）+ `pushNoteThumbnailTitles`（扩展侧
  标题先行）；缩略图复用共享 `renderFormThumbImages` 引擎。
- `NoteThumbnailFormEditAbility`（type=formEdit）+
  `NoteThumbnailEditPage`：`getAllNotes` 列表 + `TextInput` 搜索
  （`filteredNotes`）+ "No notes yet" 空态；选定写回绑定 + 推标题。
- `NoteFormAbility`：第三张数据卡生命周期登记；`onFormEvent` 按
  formId 归属（folderNotesFormIds / noteThumbnailFormIds）分发
  对应 edit ability。
- `LibraryPage`：`refreshRecentCardFeed` 现推送全部三个数据 feed。

## 适配差异（文档化）

1. 配置时机为后置编辑（formEdit）而非添加时强制配置 —— 同 P668。
2. 绑定存 filesDir JSON —— 同 P668。
3. 缩略图两阶段推送（标题先行 + formImages 补齐）—— 同 P667/P668。
4. dp 尺寸区间 → Harmony 网格维度枚举近似（见 ADR-0636 §4）。

## fail-closed 保留

- 无。原版 widget 表面（CreateNote / CreateRecording / RecentNotes /
  FolderNotes / NoteThumbnail）5/5 全部对齐实现。

## 验收

- `d05-original-note-thumbnail-card.mjs`：25/25。
- 全量 Desktop Replay、clean + `note@ohosTest` + `note@default`
  构建全绿。

## 变更文件

- 新增：`note/src/main/ets/data/NoteThumbnailFormFeed.ets`、
  `note/src/main/ets/noteformability/pages/NoteThumbnailCard.ets`、
  `note/src/main/ets/noteformability/pages/NoteThumbnailEditPage.ets`、
  `note/src/main/ets/noteformeditability/NoteThumbnailFormEditAbility.ets`、
  `docs/migration/replays/d05-original-note-thumbnail-card.mjs`、
  `docs/migration/evidence/phase-669-original-note-thumbnail-card.md`、
  `docs/migration/adr/ADR-0636-original-note-thumbnail-card.md`、本报告。
- 修改：`note/src/main/ets/data/RecentNotesFormFeed.ets`、
  `note/src/main/ets/noteformability/NoteFormAbility.ets`、
  `note/src/main/ets/ui/library/LibraryPage.ets`、
  `note/src/main/module.json5`、
  `note/src/main/resources/base/profile/forms_config.json`、
  `note/src/main/resources/base/profile/main_pages.json`、
  `note/src/main/resources/base/element/string.json`、
  `note/src/main/resources/zh_CN/element/string.json`、
  `docs/migration/replays/d05-original-widget-action-cards.mjs`、
  `docs/migration/replays/d05-original-recent-notes-card.mjs`、
  `docs/migration/replays/d05-original-folder-notes-card.mjs`、
  三份跟踪文档。
