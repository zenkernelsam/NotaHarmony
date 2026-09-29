# Phase 1027 证据 — Room 数据库清点

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`
（注解剥离；按 DAO→DB 绑定器关系钉扎）

## 至少 7 个 distinct Room 数据库

| DB | 引用计数 | DAO/绑定器 | 表域 |
|---|---|---|---|
| `NoteBundleMetadataDatabase` | 57 | wp1/kq1/hl3/iq1 | ClientOp+SyncedOp+
  Deferred+DraftNote+SyncedNoteMetadata+
  ClientNoteUpdate+PermanentlyDeleted+
  NoteAsset+LearnNoteState |
| `RawLibraryStateDatabase` | 40 | jp1/beb/bp1 | SyncedFolder+ClientFolderEdit/
  Delete+LibraryState |
| `ToolboxDatabase` | 40 | na4/ma4 | Toolbox+Tray+ToolState+wells+
  PaperBackground+NoteState+Preference+Quiz |
| `SearchIndexDatabase` / `SearchDatabase` | ~33 | klc/sq1/kc6/d6c | search_item+search_fts+Indexed*|
| `TranscriptionDatabase` | 13 | qbf/ocf | transcriptions+segments |
| `LearnDatabase` | 24 | y93 | QuizSession/QuizOp/
  LearnJob/StudyItems/SummaryEntity |
| `NoteAssetDatabase` | 15 | ? | NoteAsset |

（LibraryStateDatabase/NoteStateDatabase/SettingsDatabase
等为别名/分片；`WorkDatabase` 是 vendored。）

## 分包规律

- **按功能分库**：sync/元数据、library/folder、
  toolbox/UI-state、search、transcription、learn、
  asset 各自独立 Room DB——**模块化隔离**。
- `e47` = 主 DB（NoteBundleMetadata）的
  RoomOpenHelper（39 DDL 全集聚合处）。

## HarmonyOS 决策

- 保留分库结构（Harmony relationalStore
  也按域分文件）；表定义按域归位。
- `e47` 聚合 DDL 是 RoomOpenHelper 生成——
  Harmony 侧用 migrator/init 复刻。

## 产出

- fixture `d02-database-census.mjs`（10 断言）。
- ADR-0971；中文报告。
