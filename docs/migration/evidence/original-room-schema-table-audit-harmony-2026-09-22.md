# Phase 576 — 原版 Room Schema 逐表对比审计证据（HarmonyOS）

日期：2026-09-22
基准：`decompiled_1.0.3/sources/defpackage/e47.java`（Room 生成的全部 DDL 汇
编）、`com/gingerlabs/notability/data/note/state/NoteStateDatabase_Impl.java`
（迁移 1→2 / 2→3 / 3→4，标识 `NoteStateEntity`）。

## 原版表清单与 Harmony 落点

`e47.java` 共汇编 40 张表 + `room_master_table`。逐表核对结果：

| 原版表 | Harmony 落点 | 结论 |
| --- | --- | --- |
| `NoteStateEntity` | `note_state` | 结构适配（双轴 scroll_offset + coordinate_model_version；原版 scrollOffset 为单列）。原版 zoom/scroll 语义已对齐。 |
| `ToolboxEntity` | `editor_toolbox_state` | v69 移植：mostRecentlySelectedToolId / previouslySelectedToolId 对齐。 |
| `TrayEntity` | `editor_tray` + `tool_state.tray_type` | v69 扁平化：原版 tray 为独立行（tray_id/tray_type/toolbox_owner_id/lastUsedToolId，FK→ToolboxEntity CASCADE）；Harmony 以 `editor_tray` 行 + `tool_state.tray_type`（cgf 序数 0/1/2）表达，语义等价。 |
| `ToolStateEntity` | `tool_state` | **本 Phase 补齐 `tape_pattern`**；其余列逐一对应（tool_id/tray_owner_id/toolType/trayIndex/color/widthSize/style/selectedColorWellIndex/selectedWidthSizeWellIndex/selectionIsFreehand/eraserIsPartial）。 |
| `FavoriteColorWellEntity` | `favorite_color_well` | 逐列一致（e47.java:377）。 |
| `WidthSizeWellEntity` | `width_size_well` | 逐列一致（e47.java:378）。 |
| `RecentColorWellEntity` | `recent_color_well` | 逐列一致（e47.java:382；dedupe+7 上限在 `ehb.java`）。 |
| `ClientOp` | `operation_log` + `client_op` | 原版 op 为 (noteId, opId) 键控 BLOB，无 page 列——Harmony page-in-payload 设计为原版忠实（D-01 证据升级）。Harmony operation_log 为结构化超集（FK/索引超出原版）。 |
| `SyncedOpMetadata` | `note_sync_metadata` / `synced_operation_inbox` | 同步元数据超集对齐。 |
| `SyncedNoteMetadata` | `note_meta` | 标题/时间戳/收藏/软删（v67 deleted_at）已对齐。 |
| `SyncedFolderMetadata` / `ClientFolderEdit` | `folder`（v68 color/emoji/updated_at） | 已对齐。 |
| `PermanentlyDeletedNote` | `permanently_deleted_note` | v67 已对齐。 |
| `search_item` | `search_item` | 逐列一致；UNIQUE(noteId,type,subId) 索引保留（Harmony 额外 FK + `search_page_state`）。 |
| `PaperBackground` | `PaperBackground`（保留驼峰列名） | 逐列一致（e47.java:371）。 |
| `BackgroundInfo` | `BackgroundInfo` | 逐列一致（PK=paperLineType）。 |
| `NoteAsset` | `note_asset` + `original_asset_cloud_state` | 对齐并扩展云状态。 |
| `NoteIndexableChanges`/`IndexedNote`/`IndexedTitle`/`FailedIndexedNote`/`DraftNote`/`ClientNoteUpdate`/`ClientFolderDelete`/`Dependency`/`DeferredSyncedOps` | 索引/同步队列族 | Harmony 以 `original_*` 寄存器族 + `deferred_synced_operation_bundle` 覆盖等价语义；纯同步队列语义在本地构建下 fail-closed（ADR-0502）。 |
| `LearnJob`/`LearnNoteState`/`StudyItemsInfo`/`QuizOp`/`QuizSession`/`SummaryEntity`/`transcriptions`/`transcription_segments` | — | AI/学习功能域，Harmony 未承载：fail-closed（订阅+模型依赖，无本地等价）。 |
| `WorkSpec`/`WorkName`/`WorkProgress`/`WorkTag`/`SystemIdInfo`/`Preference` | — | WorkManager 运行时表，属平台机制非业务语义；Harmony 无对应需求。 |

## 唯一可执行缺口：`ToolStateEntity.tapePattern`

原版 DDL（e47.java）：

```sql
`tapePattern` INTEGER DEFAULT NULL
```

位于 `selectedWidthSizeWellIndex` 与 `selectionIsFreehand` 之间——REVIEW
（胶带/遮盖）工具的选中图案跨重启持久化。Harmony `tool_state` 缺该列。

本 Phase 修复（v71）：

- `DDL_TOOL_STATE` 增加 `tape_pattern INTEGER`（可空、无 CHECK，与原版一致）。
- `MIGRATIONS[71]` = `ALTER TABLE tool_state ADD COLUMN tape_pattern INTEGER`。
- `ToolState.tapePattern?: TapePattern | null`；`rowToState` 以
  `isColumnNull` 区分 NULL；`toBucket`/`cloneState` 以 `?? null` 往返。

## 已确认的"非缺口"（审计条目可关闭/升级）

- **D-01（无页维度）**：原版 `ClientOp`/`SyncedOpMetadata` 均无 page 列，页
  面归属在 op payload 内——Harmony 设计原版忠实。
- **D-02（op 日志降级）**：原版 op 即 (noteId, opId)→BLOB；Harmony
  `operation_log` 为结构化超集，未降级。
- **D-05（缺外键）**：原版仅在 Toolbox→Tray→Tool 链与 `SystemIdInfo`→
  `WorkSpec` 上用 FK；Harmony `note_meta`→各子表、`page_info`→元素/搜索
  快照全 CASCADE，FK 覆盖面超过原版。`tool_state` 因 v69 扁平化无 Tray 行
  可指，属结构适配而非缺失。

## 已知结构适配差异（不修复，已文档化）

- `note_state`：原版单列 `scrollOffset`（INTEGER），Harmony 双轴
  `scroll_offset_x/y` + `coordinate_model_version`——坐标模型适配。
- `ToolStateEntity.color`/`widthSize`：原版可空（工具类型化缺省），Harmony
  NOT NULL DEFAULT ——v69 期决策，默认行即补齐，语义等价。
- `tool_id`/`tray_owner_id`：原版 INTEGER 自增，Harmony TEXT——ID 体系
  适配（原版 owner 为 ToolboxEntity PK，Harmony 为 note/owner 字符串）。

## Replay

`docs/migration/replays/d02-original-tool-state-tape-pattern.mjs`
（17 断言）：版本号、v71 ALTER、DDL 列位/可空性、模型/仓储往返、以及
favorite/recent well、PaperBackground、search_item 的逐列不变量复核。
