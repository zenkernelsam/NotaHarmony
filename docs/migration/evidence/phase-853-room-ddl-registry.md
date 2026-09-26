# Phase 853 — Room DDL 语句级登记（CREATE TABLE / CREATE INDEX）

Phase 822 完成数据库拓扑（13 库、版本阶梯、实体清单）；本阶段下沉到
**语句级 DDL**：反编译产物中全部 `CREATE TABLE` / `CREATE INDEX`
原文、宿主文件归属、以及迁移体重建模式（`_new_*`）。

## 证据来源

`decompiled_1.4.2/sources/defpackage/` 中 12 个含 DDL 的文件 +
`com/gingerlabs/notability/data/**/\*_Impl.java`（13 个 Room
_Impl 壳，DDL 不在壳内而在 R8 合并后的代理/迁移类）。

## 语句级清单

### 应用 DDL — `defpackage/ca3.java`（R8 合并的全部 Room createAllTables）

| 域 | 表 |
|---|---|
| CustomTemplates | `CustomTemplate`, `PendingTemplateDeletion` |
| GalleryMutation | `PendingLike`, `PendingFollow` |
| Learn | `QuizSession`, `QuizOp`, `LearnNoteState`, `SummaryEntity`,
`LearnJob`, `StudyItemsInfo`, `CompletedQuizSession` |
| NoteAsset | `NoteAsset` |
| NoteBundleMetadata(ops) | `SyncedOpMetadata`, `ClientOp`,
`NoteIndexableChanges`, `DeferredSyncedOps`, `DraftNote`,
`UploadRejection` |
| NoteState | `NoteStateEntity` |
| RawLibraryState | `SyncedNoteMetadata`, `ClientNoteUpdate`,
`PermanentlyDeletedNote`, `SyncedFolderMetadata`,
`ClientFolderEdit`, `ClientFolderDelete` |
| Search | `IndexedTitle`, `IndexedNote`, `FailedIndexedNote`,
`SearchIndexSyncState`, `FailedInkPage`,
`SearchIndexPendingUpload`, `InkPageRecognizer` |
| Settings(paper) | `PaperBackground`, `BackgroundInfo`,
`TemplatePaperInfo`, `FavoritePaperTemplate`,
`RecentPaperTemplate`, `RecentGalleryTemplate`,
`PaperTemplateUsage` |
| Toolbox | `TrayEntity`, `FavoriteColorWellEntity`,
`WidthSizeWellEntity`, `ToolStateEntity`, `ToolboxEntity`,
`RecentColorWellEntity` |
| Transcription | `transcriptions`, `transcription_segments` |
| WorkManager(vendor) | `Dependency`, `WorkSpec`, `WorkTag`,
`SystemIdInfo`, `WorkName`, `WorkProgress`, `Preference` |

合计：**54 应用表 + 7 vendor 表**（WorkManager 全家 +
room_master_table），与 822 的 45 实体清单对齐（差异为
同实体多表/索引附属行）。

### CREATE INDEX（ca3，18 条）

学习/同步/工具箱/转写/WorkManager 五域索引；语义级亮点：

- `idx_clientop_agg_optimized`（`ClientOp` 五列复合：noteId,
  hasTitle, opId, clientTime, title）— 同步聚合查询优化；
- `idx_clientop_upload_immediately` — 立即上传队列；
- `index_transcriptions_*` ×4 — 转写按录音/笔记/状态/时间检索。

### 迁移体重建（`_new_*` recreate 模式）

| 文件 | 内容 | 归属 |
|---|---|---|
| `wf1` | `syllabusCourses`, `syllabusEvents` 建表 | Calendar v1→v2 迁移 |
| `yf1` | `calendarSelections`, `calendarDismissedEvents`,
`syllabus*`, `search_item` | Calendar/SearchIndex 迁移 |
| `r4a` | `_new_SummaryEntity`, `_new_SystemIdInfo`,
`_new_WorkSpec` 等 16 表 | Learn v?→? + WorkManager 升级 |
| `zmb` | `ClientFolderEdit`, `SearchIndex*`,
`ToolStateEntity_new` 等 9 | RawLibraryState/Search/Toolbox 迁移 |
| `fgf` | `IndexedNote`, `FailedIndexedNote`, `_new_WorkSpec` | Search/WM 迁移 |
| `s4a` | `Preference` 单独 | WorkManager |

`_new_*` 命名 = Room 迁移的"建新表→拷数据→删旧表→改名"
标准模式，证明这些表在版本间经历了列级变更。

### Vendor DDL（无应用价值，登记即闭合）

- `xbf` — Google DataTransport 事件管道（events/transport_*）
- `oal` — Firebase Analytics 持久化（events/raw_events/apps…）
- `cye` — Intercom `records` KV 缓存
- `ao9` — Mixpanel（events/people/groups/anonymous_people）
- `ac3` — `room_master_table`（identity_hash，Room 通用）

## Harmony 对照

`note/src/main/ets/data/DatabaseHelper.ets`：单一 RDB
`CREATE TABLE` 语句 ×88（去重 **67 个表名**，5 个名称因
版本分支/变体 DDL 各出现两次），覆盖：

- 原 editor/ops/state 域 → `original_*` 40+ 表 +
  `note_state`/`operation_log`/`deferred_synced_operation_bundle`；
- library 域 → `folder`/`note_meta`/`note_sync_metadata`/
  `permanently_deleted_note`/`synced_operation_inbox`；
- toolbox 域 → `editor_toolbox_state`/`editor_tray`/
  `tool_state`/`favorite_color_well`/`width_size_well`/
  `recent_color_well`；
- search 域 → `search_item`/`search_page_state`；
- asset 域 → `note_asset`/`original_asset_cloud_state`；
- history/page 快照 → `history_checkpoint*`/`page_delete_*`/
  `page_element_snapshot`/`page_info`。

**Gap（fail-closed 归口）**：Learn（QuizSession 等 7 表）、
Calendar（4 表）、GalleryMutation（2 表）、Transcription（2 表）
在 Harmony RDB 无同名表——对应功能域此前各 Phase 已登记为
后端/平台绑定或未移植，DDL 层面一致 fail-closed。
WorkManager/Firebase/Mixpanel/Intercom/DataTransport vendor DDL
无对应物（平台不存在这些依赖）。

## 结论

原版 DDL 语句级完整可考（61 条 CREATE TABLE + 32 条
CREATE INDEX 分布于 12 文件）；Harmony 单库 67 表覆盖全部
本地域；学习/日历/画廊/转写/厂商 SQL 面登记为 fail-closed。
**Room DDL 面闭合。**
