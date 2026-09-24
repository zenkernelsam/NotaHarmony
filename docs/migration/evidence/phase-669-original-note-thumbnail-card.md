# Phase 669 — 原版 NoteThumbnailWidgetProvider 配置型单缩略图卡片证据

日期：2026-09-24
对应 Replay：`docs/migration/replays/d05-original-note-thumbnail-card.mjs`

## 原版证据（decompiled_1.0.3）

### Provider 与配置绑定

- `sources/com/gingerlabs/notability/app/widgets/NoteThumbnailWidgetProvider.java`
  - `extends ec0`（AppWidgetProvider）；`g(context, i)`：
    `wyi.e(context, i)` 读 `widget_bindings["note_"+i]` →
    `euh.c` 解析 utf → `mc7Var.a(utf)` 查笔记 →
    `xf9`/`yf9` 渲染首页位图。
  - 有缩略图：`setImageViewBitmap(R.id.app_widgets__widget_thumbnail_image)`
    + `contentDescription=笔记标题`；无图：
    `app_widgets__widget_thumbnail_placeholder`。
  - 点击 pendingIntent：已配置 `VIEW` + `putExtra("note_id", ttf)`；
    未配置 `MAIN` + `LAUNCHER`（纯拉起）。
- `sources/defpackage/wyi.java`
  - `e(context, i)` = `widget_bindings` SharedPreferences
    `.getString("note_" + i)` —— 与 FolderNotes 的 `folder_<id>`
    同一按实例绑定机制。
- `NoteThumbnailConfigActivity.java` + manifest 声明 —— 添加部件时
  的"Choose a note"配置活动；`query` 字段 + `rv7` 列表 +
  `widget_note_picker_search_hint` 搜索过滤。
- `resources/res/xml/app_widgets__note_thumbnail_widget_info.xml`
  - `minWidth/Height=40dp`、`targetCellWidth/Height=2`、
    `resizeMode="vertical|horizontal"`、`maxResizeWidth/Height=190dp`、
    `configure=NoteThumbnailConfigActivity`。
- `strings.xml`
  - `app_widgets__widget_note_thumbnail_label`="Note"（桌面部件列表标签）、
    `..._description`="Quick access to one of your notes."、
    `..._picker_title`="Choose a note"、
    `widget_picker_no_notes`="No notes yet"、
    `widget_note_picker_search_hint` 搜索占位。

## Harmony 对齐

- `forms_config.json`：`note_thumbnail_card`（2*2 默认 ——
  对应 targetCell 2×2；`supportDimensions` 1*2/2*2/2*4/4*4 覆盖
  40–190dp 双向 resize）。
- `NoteThumbnailCard.ets`：`noteId`/`thumb`/`title`/`configured`
  LocalStorageProp；已配置显示 `memory://<key>` 缩略图 + 标题
  （contentDescription 等价物为卡片标题区）；无图显示占位图标
  （`shortcut_new_note`）；点击已配置 → `postCardAction(router)`
  `note_id` 入 `OpenTargetIngress`（= 原版 VIEW+note_id）；未配置 →
  纯拉起 `NoteAbility`（= MAIN+LAUNCHER）；编辑入口
  `postCardAction(message{edit:true})`。
- `NoteThumbnailFormFeed.ets`：`note_thumbnail_form_config.json`
  （formId→noteId，等价 `widget_bindings["note_"+id]`）；
  `registerNoteThumbnailForm`/`unregisterNoteThumbnailForm`/
  `setNoteThumbnailFormNote` 生命周期与配置存取；
  `refreshNoteThumbnailForms`（UIAbility 侧，缩略图 formImages）+
  `pushNoteThumbnailTitles`（FormExtensionAbility 侧，标题先行）；
  缩略图渲染复用 `RecentNotesFormFeed` 抽出的
  `renderFormThumbImages` 共享引擎（与 P667/668 一致的两阶段推送）。
- `NoteThumbnailFormEditAbility`（type=formEdit）+
  `NoteThumbnailEditPage` —— 对应 `NoteThumbnailConfigActivity`：
  笔记列表（`getAllNotes`）+ `TextInput` 搜索（`filteredNotes`）+
  空态 "No notes yet"；选定写回绑定并推标题。
- `NoteFormAbility`：`NOTE_THUMBNAIL_FORM_NAME` 生命周期注册 +
  `onFormEvent` 收到 `edit:true` 时按 formId 归属分发
  `openFormEditAbility(THUMB_EDIT_ABILITY)`。

## 适配差异（文档化）

1. 原版添加部件时强制走配置活动；Harmony formEdit 为后置编辑
   （卡片内入口/桌面长按）——未配置态点击即拉起主应用，卡片上
   提供编辑入口，与 FolderNotes 同一适配策略。
2. 原版 SharedPreferences 按 appWidgetId 绑定；Harmony 按 formId
   存 filesDir JSON（同 ADR-0635 适配）。
3. 原版位图由 provider 内联渲染；Harmony 分标题/缩略图两阶段推送
   ——同 ADR-0634/0635。
4. `targetCellWidth/Height=2` → Harmony `defaultDimension 2*2`；
   `resizeMode` 双向 + `maxResize` 190dp → `supportDimensions`
   1*2/2*2/2*4/4*4（Harmony 网格维度枚举无法表达 dp 区间，
   以覆盖原区间的网格集合近似）。

## fail-closed 保留

- 无。至此原版 5 个 widget provider（CreateNote、CreateRecording、
  RecentNotes、FolderNotes、NoteThumbnail）全部有 Harmony 对齐实现。
