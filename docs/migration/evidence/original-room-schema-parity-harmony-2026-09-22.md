# Harmony 证据 — 原版 Room schema 逐表比对（Phase 530）

- 范围：`decompiled_1.0.3` 全部 10 个 Room 数据库的建表 DDL vs Harmony `nota.db` v66
  （`note/src/main/ets/data/DatabaseHelper.ets`）。
- 原版证据来源：Room 生成的 open-helper 回调 `e47.java`（每个 `*Database_Impl.g()` 返回
  `new e47(this)`，DDL 集中在 `e47.java:322-411`）；自动迁移 `ba8.java:34-181`；
  DAO 语句 `ve9.java:117` / `vb4.java:23` / `na4.java:583` / `wp1.java:532-552`；
  资料库合并查询 `x17.java:143`（ClientPivot CTE）。
- 结论：对“移植范围内”的每一项原版状态，Harmony schema 均给出等价或更强的承载；
  三条历史结构性推断（D-01 无页维度 / D-02 op-log 退化 / D-05 缺外键）就此升级为
  代码级闭环证据 ✅。比对同时登记 7 条原版已建表、Harmony 尚无对应物的差异，
  全部为特性级缺口（非已实现路径的错误），见下。

## 一、逐表映射与判定

| 原版实体（库） | Harmony 表 | 判定 |
|---|---|---|
| `NoteStateEntity`（NoteState） | `note_state` | ✅ 等价。原版单列 `scrollOffset INTEGER`（一维纵向滚动，`ay6.java:212/224` 非负校验）；Harmony 用 `scroll_offset_x/y REAL` 承载自身二维视口模型，`getViewState/saveViewState` 已接线（NoteRepositoryImpl:343/370，NoteCanvasView:516/1640）。原版 `lastCodeBlockLanguage`/`zoomViewSourceRect`/`zoomViewShown` 未持久化 → SCHEMA-D4 |
| `NoteAsset`（NoteAsset） | `note_asset` | ✅ 等价+。原版 `assetHash BLOB PK, status TEXT, noteIds TEXT, fileSize`；Harmony `asset_hash TEXT PK, status INTEGER, note_ids TEXT, file_size` 并增 `mime_type/local_path` 支撑本地文件存储 |
| `ClientOp`（NoteBundleMetadata） | `operation_log` | ✅ 更强。原版 `PK(noteId,opId)` + `uploadImmediately/hasTitle/title/clientTime`；Harmony 保 `UNIQUE(note_id,op_id)`、`upload_immediately`，并增 CRDT 身份 `UNIQUE(note_id,editor_site_id,op_timestamp)` 与动作分组列；hasTitle/title 由 `original_note_title_winner` 承载 |
| `SyncedOpMetadata`（同上） | `note_sync_metadata` | ✅ 主体等价。原版另有 `title/titleOpId`（由 title winner 承载）与 `opFileSize/fingerprintFileLengths/opsChecksum/offsetsChecksum` 同步校验字段 → SCHEMA-D7 |
| `NoteIndexableChanges`（同上） | —（`search_page_state`） | 🟡 差异。原版把待索引变更排队（ids/pageIds/chunkIndex/processing）；Harmony 同步索引、按页记录 indexed_revision → SCHEMA-D6 |
| `DeferredSyncedOps`（同上） | `deferred_synced_operation_bundle` | ✅ 等价+。原版 `noteId/schemaVersion/tableType/fileSize/checksum` + noteId 索引；Harmony 同构且内联 `payload`，`idx_deferred_synced_bundle_note` 对应原版索引 |
| `DraftNote`（同上） | — | 🟡 差异。原版单列草稿 noteId；Harmony 无草稿笔记概念 → SCHEMA-D6 |
| `SyncedNoteMetadata`（RawLibraryState） | `note_meta` | 🟡 差异。本地字段（title/createdAt/updatedAt/favorite/lastOpened/folderId→FK SET NULL/hasRecordings）等价；原版 `deletedAt`（软删）、`thumbnailUrl`、`mostRecentOpTime`、`shared`、`linkAccessLevel/linkPermissionScope/userAccessLevel`（共享域）、`legacyNoteId`（→`note_sync_metadata.legacy_id`）未承载 → SCHEMA-D1/D7 |
| `ClientNoteUpdate`（同上） | — | 🟡 差异。原版把本地变更落成 EDIT/DELETE/UNDELETE/PERMANENTLY_DELETE 行，`x17.java:143` ClientPivot 合并出 effective `deletedAt`；Harmony 直接改 `note_meta`，无更新队列 → SCHEMA-D1 |
| `PermanentlyDeletedNote`（同上） | — | 🟡 差异。原版永久删除墓碑表，防止陈旧行复活；Harmony 硬删 → SCHEMA-D1 |
| `SyncedFolderMetadata`（同上） | `folder` | 🟡 差异。`parentId`/`siblingOrder`/`title(name)`/`createdAt` 等价；原版 `updatedAt/color/emoji` 未承载 → SCHEMA-D3 |
| `ClientFolderEdit/ClientFolderDelete`（同上） | — | 🟡 差异。文件夹变更同步队列 + `childrenHash`/`idempotencyKey`；Harmony 无同步队列 → SCHEMA-D7 |
| `IndexedTitle/IndexedNote/FailedIndexedNote`（Search） | —（`search_page_state`） | 🟡 差异。原版有失败索引登记（errorClass/timestamp/indexerVersion）；Harmony 只记 indexed_revision → SCHEMA-D6 |
| `search_item`（SearchIndex） | `search_item` | ✅ 等价。列（noteId/type/subId/pageId?/foldedText/rects?）与 `UNIQUE(noteId,type,subId)` 完全一致，另补 page_info FK |
| `PaperBackground/BackgroundInfo`（Settings） | `PaperBackground`/`BackgroundInfo` | ✅ 逐列一致（v63 刻意保留原表名/列名） |
| `TrayEntity/ToolboxEntity/ToolStateEntity`（Toolbox） | `editor_toolbox_state`/`tool_state` | 🟡 差异。tray/toolbox/工具行折叠为 `owner_id + tool_state`；`mostRecent/previousToolId`、`toolType/trayIndex/color/widthSize/style/selectedColorWellIndex/selectedWidthSizeWellIndex/selectionIsFreehand/eraserIsPartial` 均有承载；原版 `tapePattern` 无对应（Harmony 无 tape 工具）→ SCHEMA-D5 |
| `FavoriteColorWellEntity/WidthSizeWellEntity/RecentColorWellEntity`（Toolbox） | — | 🟡 差异。原版每工具收藏色井/线宽井 + 最近色井；Harmony `ColorPicker` 为硬编码 12 色网格（ColorPicker.ets:17-30），仅持久化选中下标 → SCHEMA-D2 |
| `transcriptions/transcription_segments`（Transcription） | — | ⬜ 范围外（转写特性未移植） |
| `QuizSession/QuizOp/LearnNoteState/SummaryEntity/LearnJob/StudyItemsInfo`（Learn） | — | ⬜ 范围外（AI 学习特性未移植） |
| `WorkSpec` 等（androidx.work） | — | ⬜ 平台内部表，非 Notability 状态 |

原版独有但非 Notability 语义的外键：仅 androidx.work 的 Dependency/SystemIdInfo 等声明
FK；**原版自己的表之间一个 FOREIGN KEY 都没有**（SyncedNoteMetadata.folderId 亦仅为裸
BLOB 列）。Harmony 反而建立了完整 FK 图（page_element_snapshot→note_meta+page_info、
original_* 全链→note_meta、search_item→note_meta+page_info、folder.parent_id→folder
CASCADE、note_meta.folder_id→folder SET NULL），并带 `verifyForeignKeys` 启动校验。
D-05「缺外键」判定：Harmony ≥ 原版，闭环 ✅。

## 二、Phase 530 代码修复

原版声明 `index_ToolStateEntity_tray_owner_id`（`e47.java:380`），Harmony
`getToolStates()` 每次打开编辑器都按 `tray_owner_id` 过滤（ToolRepositoryImpl.ets:17）
却未建索引。已在 `DDL_INDEXES` 增加
`CREATE INDEX IF NOT EXISTS idx_tool_state_tray_owner ON tool_state(tray_owner_id)`；
该数组在每次 open 时幂等执行（DatabaseManager.ets:215-217），旧库无需版本号迁移。

## 三、登记差异（均为特性级缺口，非已实现路径缺陷）

- **SCHEMA-D1（P1）**：笔记软删模型缺失。原版以 `ClientNoteUpdate` 记录
  EDIT/DELETE/UNDELETE/PERMANENTLY_DELETE，`x17.java:143` ClientPivot 合并
  `deletedAt`，`PermanentlyDeletedNote` 作永久删除墓碑；设置页有
  “Recently Deleted”入口且 30 天自动彻底清除
  （`strings.xml:831` `feature_settings__recently_deleted_empty_state_header`）。
  Harmony `deleteNote` 硬删（NoteRepositoryImpl.ets:317-321），无回收站/恢复/墓碑。
- **SCHEMA-D2（P2）**：每工具收藏色井/线宽井/最近色井缺失；色盘为硬编码 12 色。
- **SCHEMA-D3（P2）**：文件夹 `color/emoji/updatedAt` 未承载（原版同步 schema 字段；
  1.0.3 本地 UI 写路径未确认，标注 🟡）。
- **SCHEMA-D4（P2）**：`lastCodeBlockLanguage`/`zoomViewSourceRect`/`zoomViewShown`
  未持久化；与未实现的放大书写视图/代码块语言记忆同生命周期。
- **SCHEMA-D5（P2）**：`ToolStateEntity.tapePattern` 与 `TapePatternTileSize` 之外的
  tape 工具整体缺失（`ToolType` 枚举无 TAPE）。
- **SCHEMA-D6（P3）**：索引工作队列（NoteIndexableChanges）、失败登记
  （FailedIndexedNote）、草稿笔记（DraftNote）未承载；Harmony 同步索引。
- **SCHEMA-D7（P3）**：同步校验/上传队列字段未承载（opsChecksum、offsetsChecksum、
  fingerprintFileLengths、opFileSize、ClientFolderEdit/Delete、共享域列）；
  待真实同步通道落地时补齐。

## 四、验证

- 新增 Replay `d02-original-room-schema-parity.mjs`：锁定全部映射表的 DDL 锚点、
  新增 tray_owner 索引、登记差异证据锚点，并以可执行模型复放
  `x17.java:143` ClientPivot 合并语义（DELETE 胜出 / UNDELETE 清除 / 墓碑隐藏）。
- ArkTS 静态检查、全量 Desktop Replay、clean + `note@ohosTest` + `note@default`
  静态构建见 Phase 530 中文报告。
