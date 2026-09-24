# Phase 667 — 原版 RecentNotes 数据卡片迁移

日期：2026-09-24
前置：Phase 666（`273ba9ba`）

## 目标

将原版 `RecentNotesWidgetProvider`（4×2 数据小部件：最近笔记列表 +
头部落地 Recent 区 + 创建钮 + 行内缩略图 + note_id 行点击）迁移为
Harmony `recent_notes_card` 服务卡片，保持数据语义与路由契约一致。

## 原版行为（证据：`qk9.java` / `RecentNotesWidgetProvider.java` /
widget_info.xml / 行布局 / strings.xml）

- 头部 "Recent Notes" → `VIEW + show_recent` PendingIntent。
- 创建钮 → `CREATE_NOTE` PendingIntent。
- 行 = 48dp 缩略图（`content://<pkg>.widgetimages/thumbnail/<ttf>?f=<fp>`，
  无图时 `page_new_note_fill` 占位）+ 标题位图 + 分隔线。
- 行点击 fillInIntent = `nbnote:<ttf>` + `note_id` extra。
- 空态 "No recent notes"；数据 = 最近 10 条 lastOpened 排序。
- 尺寸 4×2 targetCell + 双向 resize。

## Harmony 实现

- `forms_config.json`：`recent_notes_card`，默认 2*4，支持
  2*2/2*4/4*4（对应 4×2 + resizeMode）。
- `RecentNotesCard.ets`：`@LocalStorageProp('items')` 列表，
  `memory://` 缩略图或占位图标、标题、文件夹副标、分隔线、空态；
  行/头部/创建钮分别 postCardAction 到 `note_id` / `show_recent` /
  `launch_action=create_note` —— 复用 OpenTargetIngress +
  LaunchActionIngress，与原版 extras 同语义。
- `RecentNotesFormFeed.ets`：
  - `registerRecentNotesForm/unregisterRecentNotesForm` ——
    实例 formId 登记进 filesDir JSON（Harmony 无活动实例枚举 API）。
  - `pushRecentNotesTitles` —— 扩展/UIAbility 两侧可用的标题推送。
  - `refreshRecentNotesForms` —— UIAbility 侧全量推送：
    `getRecentNotes()` → `getFirstPageThumbnailState` →
    `ThumbnailRenderer.renderThumbnail` → webp pack →
    `formImages: {key: fd}`（≤5 张）；pixelMap/renderer/fd 全释放。
- `NoteFormAbility`：onAddForm 登记+推标题、onUpdateForm 推标题、
  onRemoveForm 注销。
- `LibraryPage`：`refreshRecentCardFeed()` 挂在全部 7 处 loadNotes
  完成点 —— 等价原版 Realm 观察者刷新。

## 适配差异（文档化）

1. 实例 formId 自维护（无枚举 API）。
2. 缩略图两阶段：扩展进程只推标题（无 UIAbilityContext + 5s 预算），
   应用侧补齐缩略图 —— 等价原版懒加载时序。
3. 刷新触发点为 loadNotes 完成点而非 Realm 观察者 —— 覆盖全部本进程
   笔记变更路径。
4. NoteThumbnail / FolderNotes 配置型小部件保持 fail-closed
   （ADR-0632/ADR-0634 登记）。

## 验收

- `d05-original-recent-notes-card.mjs`：33/33。
- `d05-original-widget-action-cards.mjs`：卡片计数 pin 更新（3 张）。
- 全量 Desktop Replay、clean + `note@ohosTest` + `note@default` 构建全绿。

## 变更文件

- 新增：`note/src/main/ets/data/RecentNotesFormFeed.ets`、
  `note/src/main/ets/noteformability/pages/RecentNotesCard.ets`、
  `docs/migration/replays/d05-original-recent-notes-card.mjs`、
  `docs/migration/evidence/phase-667-original-recent-notes-card.md`、
  `docs/migration/adr/ADR-0634-original-recent-notes-card.md`、本报告。
- 修改：`note/src/main/ets/noteformability/NoteFormAbility.ets`、
  `note/src/main/resources/base/profile/forms_config.json`、
  `note/src/main/resources/base/element/string.json`、
  `note/src/main/resources/zh_CN/element/string.json`、
  `note/src/main/ets/ui/library/LibraryPage.ets`、
  `docs/migration/replays/d05-original-widget-action-cards.mjs`、
  三份跟踪文档。
