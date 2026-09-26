# Phase 822 — 数据库拓扑与迁移链闭合

证据来源：`decompiled_1.0.1/1.0.3/1.4.2` 各 `*Database.java`/`*_Impl.java`
（`e()` 迁移列表、`ky7/ma6` 实体清单）；Harmony `data/DatabaseHelper.ets`
（`DB_VERSION=71`、DDL 常量族）、`DatabaseManager.ets`（version ladder 迁移器）。

## 一、原版数据库清单（Room）

| 数据库 | 1.0.x | 1.4.2 | 实体 |
|---|---|---|---|
| NoteStateDatabase | v4（1→2→3→4） | **v5**（+4→5） | NoteStateEntity |
| LearnDatabase | v1 无迁移 | **v7**（3→4→5→6→7） | QuizSession, QuizOp, LearnNoteState, SummaryEntity, LearnJob, StudyItemsInfo, CompletedQuizSession（7） |
| RawLibraryStateDatabase | v8（7→8） | v8 | SyncedNoteMetadata, ClientNoteUpdate, PermanentlyDeletedNote, SyncedFolderMetadata, ClientFolderEdit, ClientFolderDelete（6） |
| ToolboxDatabase | v8（2→3,4→5,7→8） | v8 | TrayEntity, ToolStateEntity, ToolboxEntity, FavoriteColorWellEntity, RecentColorWellEntity, WidthSizeWellEntity（6） |
| SearchDatabase | v1 | +迁移（3→4,6→…） | IndexedTitle, IndexedNote, FailedIndexedNote, SearchIndexSyncState, FailedInkPage, SearchIndexPendingUpload, InkPageRecognizer（7） |
| SearchIndexDatabase | v1 | v1 | search_item（FTS 索引） |
| SettingsDatabase | v1 | v1 | PaperBackground, BackgroundInfo, TemplatePaperInfo, FavoritePaperTemplate, RecentPaperTemplate, RecentGalleryTemplate, PaperTemplateUsage（7） |
| NoteAssetDatabase | v1 | v1 | NoteAsset |
| NoteBundleMetadataDatabase | v1 | v1 | SyncedOpMetadata, ClientOp, NoteIndexableChanges, DeferredSyncedOps, DraftNote, UploadRejection（6） |
| TranscriptionDatabase | v1 | v1 | transcriptions, transcription_segments |
| **CalendarDatabase** | — | **新增 v2**（1→2） | calendarSelections, calendarDismissedEvents, syllabusCourses, syllabusEvents |
| **GalleryMutationDatabase** | — | **新增 v1** | PendingLike, PendingFollow（画廊离线变更外发队列） |
| **CustomTemplatesDatabase** | — | **新增 v1** | CustomTemplate, PendingTemplateDeletion |

**13 库（1.4.2）vs 10 库（1.0.x），~45 实体。**

## 二、版本语义

- `NoteStateDatabase` v4→v5：新增迁移对应 785 登记的列增量（isTextOnly/
  zoomView*/lastCodeBlockLanguage 等）。
- `LearnDatabase` 1.0.x 为 v1 无迁移 → 1.4.2 升至 v7：Learn/Quiz 模式在
  1.4.2 完整重建（quiz 会话/操作/完成作业等全新实体）。
- `CalendarDatabase` 上线即 v2：发布前已迁移一次。
- `GalleryMutationDatabase` = 画廊互动（点赞/关注）离线外发队列——
  前端离线变更后端同步的经典 outbox 模式。
- `ToolboxDatabase` 非连续迁移（2→3,4→5,7→8）= 历史压平痕迹。

## 三、Harmony 端拓扑对照

Harmony 采用**单一 relationalStore（DB_VERSION=71，版本阶梯迁移器）**
合并原版 13 库，约 83 条 CREATE TABLE。基础表映射：

| Harmony 表 | 对应原版实体 | 说明 |
|---|---|---|
| note_state / note_meta / page_info | NoteStateEntity 等 | 笔记核心 |
| client_op / operation_log / deferred_synced_operation_bundle / synced_operation_inbox / note_sync_metadata | ClientOp/SyncedOpMetadata/DeferredSyncedOps/ClientNoteUpdate 族 | 同步外发队列合并 |
| permanently_deleted_note | PermanentlyDeletedNote | 墓碑 |
| note_asset | NoteAsset | 资源 |
| folder | ClientFolderEdit 族 | 文件夹 |
| editor_toolbox_state + editor_tray + tool_state + width_size_well + favorite_color_well + recent_color_well | ToolboxDB 6 实体 | 工具箱全覆盖 |
| PaperBackground / BackgroundInfo | SettingsDB 纸面实体 | 部分（模板喜好存于 prefs） |
| search_item / search_page_state / page_delete_checkpoint_search | SearchIndexDB.search_item 等 | 搜索索引 |
| history_checkpoint*(3) / original_*(40+) | Harmony 新增 | 撤销检查点 + LWW 胜者解析表族 |
| —（缺席） | Learn/Calendar/Gallery/Transcription 实体 | 后端功能库，fail-closed 集群登记一致 |

## 四、结论

数据库拓扑闭合：原版 13 Room 库/45 实体的域划分全部映射至 Harmony
统一 RDB 或归入已登记 fail-closed 集群（learn/calendar/gallery/transcription
为后端功能库）。版本增量（NoteState v5、Learn v7、新增 3 库）全部登记。
Harmony 的 `original_*` LWW 胜者解析表族是移植期新增的冲突消解架构。
