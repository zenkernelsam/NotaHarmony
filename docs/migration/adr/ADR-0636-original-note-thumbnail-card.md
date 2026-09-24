# ADR-0636 — 原版 NoteThumbnailWidgetProvider → note_thumbnail_card 配置型单缩略图卡片

日期：2026-09-24
状态：已实施（含 4 项文档化适配；原版 5 个 widget provider 全部落地）

## 决策

以 `note_thumbnail_card` ArkTS 卡片 + `NoteThumbnailFormFeed`（formId→
noteId 绑定存 filesDir JSON）+ `NoteThumbnailFormEditAbility`（type=
formEdit）+ `NoteThumbnailEditPage`（"Choose a note" 搜索选择器）
复刻原版 NoteThumbnailWidgetProvider + NoteThumbnailConfigActivity：
已配置显示首页缩略图 + 标题，无图显示占位，点击已配置 → note_id
打开笔记（复用 OpenTargetIngress），未配置 → 纯拉起 NoteAbility
（MAIN+LAUNCHER 等价）；`onFormEvent` 按 formId 归属分发
`openFormEditAbility` 复用同一编辑链。

## 证据锚点

`NoteThumbnailWidgetProvider.java`（extends ec0；g() 用 wyi.e 取绑定
noteId → xf9 首页位图 → thumbnail_image/placeholder；点击 VIEW+
note_id 或 MAIN+LAUNCHER）、`wyi.java`（widget_bindings
SharedPreferences "note_"+id）、`NoteThumbnailConfigActivity.java`
（query 搜索 + rv7 列表）、`app_widgets__note_thumbnail_widget_info.xml`
（40dp min / 2×2 targetCell / 双向 resize / 190dp max / configure）、
`strings.xml`（label=Note / picker_title=Choose a note /
picker_no_notes=No notes yet / search_hint）。详见
`docs/migration/evidence/phase-669-original-note-thumbnail-card.md`。

## 复用与连带

- 缩略图渲染复用 `RecentNotesFormFeed.ets` 抽出的
  `renderFormThumbImages` 共享引擎 —— 标题先行（扩展侧）+
  缩略图 formImages 补齐（UIAbility 侧），与 P667/P668 一致。
- `note_id` 路由完全复用 Phase 666 `OpenTargetIngress`
  （32-hex + dashed UUID 双形态解析）。
- `LibraryPage.refreshRecentCardFeed` 现同时推送 RecentNotes、
  FolderNotes、NoteThumbnail 三个 feed（loadNotes 完成点）。

## 文档化适配（非 fail-closed，行为等价）

1. **配置时机**：原版添加部件时强制配置活动；Harmony formEdit 为
   后置编辑（卡片内 ✎ → onFormEvent → openFormEditAbility），
   与 ADR-0635 同策略。
2. **绑定存取**：widget_bindings SharedPreferences →
   `filesDir/note_thumbnail_form_config.json`（formId→noteId）。
3. **位图渲染**：provider 内联渲染 → 标题/缩略图两阶段推送
   （同 ADR-0634/0635）。
4. **尺寸映射**：40–190dp 双向 resize + 2×2 targetCell →
   `defaultDimension 2*2` + `supportDimensions 1*2/2*2/2*4/4*4`
   （Harmony 以网格维度枚举近似原 dp 区间）。

## fail-closed 保留

- 无。原版 widget 表面（2 动作卡 + 3 数据卡）全部实现；
  `NoteFormAbility` 注释中的 fail-closed 段相应清空。

## 验收

- Replay：`d05-original-note-thumbnail-card.mjs` 25/25 绿；
  P665/P667/P668 fixtures 的计数与 fail-closed pin 同步更新。
- 全量 Desktop Replay、clean + note@ohosTest + note@default 双 HAP
  构建全绿。
