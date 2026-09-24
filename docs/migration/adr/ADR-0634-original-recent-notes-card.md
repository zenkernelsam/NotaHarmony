# ADR-0634 — 原版 RecentNotesWidgetProvider → recent_notes_card 数据卡片

日期：2026-09-24
状态：已实施（含 3 项文档化适配 + 1 项 fail-closed 登记）

## 决策

以 `FormExtensionAbility` + `recent_notes_card` ArkTS 卡片 +
`RecentNotesFormFeed`（formProvider.updateForm 数据通道）复刻原版
RecentNotes 数据小部件：头部→show_recent、创建钮→CREATE_NOTE、
行→note_id 单开、空态、缩略图/占位、分隔线、4×2 默认尺寸 + 双向 resize。

## 证据锚点

`RecentNotesWidgetProvider.java`（show_recent）、`qk9.java`（RemoteViews
集合/行 fillInIntent/占位可见性/空态）、
`app_widgets__recent_notes_widget_info.xml`（4×2 + resize）、
`app_widgets__widget_notes_row.xml`（行布局）、`strings.xml`（标签/空态）、
`au1.N1(10)`（上限 10）。详见
`docs/migration/evidence/phase-667-original-recent-notes-card.md`。

## 文档化适配（非 fail-closed，行为等价）

1. **实例 formId 自维护**：Harmony 无活动实例枚举 API
   （`getFormsInfo` 仅返回 forms_config 声明态）。formId 由
   onAddForm/onRemoveForm 登记进 `filesDir/recent_notes_form_ids.json`，
   UIAbility 与 FormExtensionAbility 共享沙箱均可读写。
2. **缩略图两阶段**：FormExtensionAbility 后台预算 ~5s 且无
   UIAbilityContext（ThumbnailRenderer 需要其初始化纹理/数学引擎）。
   onAddForm/onUpdateForm 推标题-only；缩略图由 UIAbility 侧
   `refreshRecentNotesForms` 补齐 —— 等价原版 WidgetImageProvider
   懒加载（标题先行、图像后至）。
3. **刷新触发**：原版 Realm 观察者即时推送；Harmony 挂在 LibraryPage
   全部 loadNotes 完成点（7 处），覆盖本进程全部笔记变更路径。

## fail-closed 登记（保留差异）

- **NoteThumbnailWidgetProvider / FolderNotesWidgetProvider**：
  两张**配置型**数据小部件（原配有配置 Activity）。Harmony 需要
  `FormEditExtensionAbility`/卡片编辑链路 + 文件夹/单笔记选择 UI，
  属独立阶段规模 —— 继续登记 fail-closed（承袭 ADR-0632）。
  本次交付后，5 张原版小部件剩 2 张配置型未实现，其余 3 张已对齐。

## 验收

- Replay：`d05-original-recent-notes-card.mjs` 33/33 绿；
  `d05-original-widget-action-cards.mjs` 卡片计数 pin 更新为 3。
- 全量 Desktop Replay、clean + note@ohosTest + note@default 双 HAP 构建全绿。
