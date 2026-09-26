# Phase 822 — 数据库拓扑与迁移链闭合

## 范围

原版 Room 数据库集群清单、逐库版本号与迁移链、实体映射；
Harmony 统一 relationalStore 的域覆盖核验。

## 原版证据

### 库清单（13 库 / ~45 实体）

| 域 | 版本 | 要点 |
|---|---|---|
| NoteStateDatabase | 1.0.x v4 → **1.4.2 v5** | 新增 4→5 迁移对应 785 列增量 |
| LearnDatabase | v1 → **v7** | Learn/Quiz 在 1.4.2 重建（QuizSession/QuizOp/CompletedQuizSession 等 7 实体） |
| RawLibraryStateDatabase | v8 | 同步外发（SyncedNoteMetadata/ClientNoteUpdate/墓碑等 6 实体） |
| ToolboxDatabase | v8 | 工具箱全 schema（Tray/ToolState/ColorWell/WidthSize 6 实体） |
| SearchDatabase | +迁移 | 索引与同步队列（IndexedNote/FailedIndexedNote/InkPageRecognizer 等 7 实体） |
| SearchIndexDatabase | v1 | `search_item` FTS 表 |
| SettingsDatabase | v1 | 纸面/模板偏好 7 实体 |
| NoteAssetDatabase | v1 | NoteAsset |
| NoteBundleMetadataDatabase | v1 | op 同步 6 实体（ClientOp/DeferredSyncedOps/DraftNote 等） |
| TranscriptionDatabase | v1 | transcriptions/transcription_segments |
| **CalendarDatabase** | **1.4.2 新增，v2** | syllabus 导入（上线即迁移一次） |
| **GalleryMutationDatabase** | **1.4.2 新增，v1** | PendingLike/PendingFollow 画廊离线 outbox |
| **CustomTemplatesDatabase** | **1.4.2 新增，v1** | CustomTemplate/PendingTemplateDeletion |

## Harmony 映射

统一 relationalStore（`DB_VERSION=71`，版本阶梯迁移器）约 83 表
合并原版 13 库域；核心域全覆盖（笔记/同步外发/墓碑/资源/文件夹/
工具箱/纸面/搜索索引）。缺席的 Learn/Calendar/Gallery/Transcription
表与各后端集群 fail-closed 登记一致。Harmony 新增的
`original_*_winner`/`history_checkpoint` 表族为移植期冲突消解架构。

## 交付物

- 证据：`docs/migration/evidence/phase-822-database-topology.md`
- ADR：`docs/migration/adr/ADR-0766-database-topology.md`
- Replay：`docs/migration/replays/d02-database-topology.mjs`（13 项断言）

## 验证

- 新增 Replay：13/13 通过（首次 12/13——`client_op` 为版本化表名
  `client_op_v6`，改前缀匹配后通过）。
- 全量 Desktop Replay、双 HAP 构建随本 Phase 完成。

## 下一步

持久层闭合。候选轴：baseline.prof 热点方法抽样、混淆常量池残留、
或 Harmony 侧 `ets/` 死代码/未挂接功能反向审计。
