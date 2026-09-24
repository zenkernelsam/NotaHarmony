# Phase 667 — 原版 RecentNotesWidgetProvider 数据卡片证据

日期：2026-09-24
对应 Replay：`docs/migration/replays/d05-original-recent-notes-card.mjs`

## 原版证据（decompiled_1.0.3）

### Provider 与布局

- `sources/com/gingerlabs/notability/app/widgets/RecentNotesWidgetProvider.java`
  - `onUpdate` → `qk9` 构建 RemoteViews 集合。
  - `putExtra("show_recent", true)`：部件本体（头部）点击落地 Recent 区。
- `sources/defpackage/qk9.java`
  - `R.layout.app_widgets__widget_notes` 容器 + `app_widgets__widget_notes_row` 行。
  - 头部：`setOnClickPendingIntent(widget_header, xld.d())`（VIEW+show_recent）。
  - 创建钮：`setOnClickPendingIntent(widget_create, xld.a())`（CREATE_NOTE）。
  - 行：48dp `widget_row_thumbnail_image` ← `content://<pkg>.widgetimages/thumbnail/<ttf>?f=<fp>`；
    无图时 `thumbnail_placeholder`（`page_new_note_fill`）显、image 隐（visibility 8）。
  - 行点击：`setOnClickFillInIntent(widget_row_root, Intent().setData(Uri.fromParts("nbnote", ttf, null)).putExtra("note_id", ttf))`。
  - 空态：`setEmptyView(notes_list, widget_empty)` + `app_widgets__widget_recent_notes_empty` = "No recent notes"。
  - 行尾分隔线 `widget_row_divider`（最后一行隐藏）。
- `resources/res/xml/app_widgets__recent_notes_widget_info.xml`
  - `targetCellWidth="4" targetCellHeight="2"`（4×2）+ `resizeMode="vertical|horizontal"`。
- `resources/res/layout/app_widgets__widget_notes_row.xml`
  - 行结构：缩略图 FrameLayout(48dp) + 标题 + 分隔线。
- `resources/res/values/strings.xml`
  - `app_widgets__widget_recent_notes_label` = "Recent Notes"；
    `app_widgets__widget_recent_notes_empty` = "No recent notes"。
- 最近列表：`au1.N1(10)`/`mk9` —— lastOpened 排序上限 10 条，
  与 `NoteRepositoryImpl.getRecentNotes()` 的
  `ORDER BY last_opened DESC, updated_at DESC LIMIT 10` 完全一致。

## Harmony 对齐

- `note/src/main/resources/base/profile/forms_config.json`
  - `recent_notes_card`：`defaultDimension: "2*4"`（= 4×2 targetCell），
    `supportDimensions: 2*2/2*4/4*4`（= 双向 resizeMode）。
- `note/src/main/ets/noteformability/pages/RecentNotesCard.ets`
  - `@LocalStorageProp('items')` + ForEach 行；
    行 `Image('memory://'+thumb)` 或 `shortcut_new_note` 占位；
    `Divider()` 分隔线；空态 `form_recent_notes_empty`。
  - 行点击 `postCardAction(router, NoteAbility, {note_id: item.id})`
    → OpenTargetIngress（与原版 note_id extra 同语义）。
  - 头部 `postCardAction(..., {show_recent: true})` → RECENT 区。
  - 创建钮 `postCardAction(..., {launch_action: 'create_note'})`
    → LaunchActionIngress → createAndLaunch。
- `note/src/main/ets/data/RecentNotesFormFeed.ets`
  - 实例 formId 登记 `filesDir/recent_notes_form_ids.json`
    （Harmony `formProvider.getFormsInfo` 只返回声明态，无活动实例枚举 —— 文档化适配）。
  - `pushRecentNotesTitles(context, formId?)`：扩展/UIAbility 两侧可用的标题-only 推送。
  - `refreshRecentNotesForms(uiContext, theme)`：标题 + 缩略图全量推送；
    `getFirstPageThumbnailState` → `ThumbnailRenderer.renderThumbnail` →
    webp pack → 写文件 → `formImages: {key: fd}`（≤5 张，API≤19 上限）；
    `pixelMap.release()` + `renderer.dispose()` + fd 关闭。
- `note/src/main/ets/noteformability/NoteFormAbility.ets`
  - `onAddForm` 读 `IDENTITY_KEY`/`NAME_KEY` → 登记 formId → 推标题。
  - `onUpdateForm` → 推标题；`onRemoveForm` → 注销。
- `note/src/main/ets/ui/library/LibraryPage.ets`
  - `refreshRecentCardFeed()` 挂在全部 loadNotes 完成点（7 处）
    —— 等价原版 Realm 观察者驱动刷新。

## 适配差异（文档化）

1. 原版行标题是位图（RemoteViews 不支持自定义字体文本）；Harmony 卡片可直接
   渲染 Text —— 语义等价、视觉近似。
2. 原版缩略图经 ContentProvider 懒加载；Harmony 扩展进程无
   UIAbilityContext，缩略图仅由 UIAbility 侧推送 —— onAddForm 时先出标题，
   应用下次运行补齐缩略图（等价懒加载时序）。
3. 原版 Realm 观察者即时刷新；Harmony 在 loadNotes 完成点推送 —— 覆盖全部
   本进程笔记变更路径。
4. NoteThumbnail / FolderNotes 两张**配置型**数据小部件保持 fail-closed
   （ADR-0632）：需要 FormEditExtensionAbility 配置链路，登记为独立后续阶段。
