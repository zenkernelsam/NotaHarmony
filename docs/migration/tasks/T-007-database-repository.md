# T-007 数据库 DDL 与 Repository 接口

## 目标

创建数据库初始化文件（DDL 常量 + 版本常量）和 Repository 抽象接口文件。这是 Phase 2/3 数据层的契约基础。

## 参考

- 知识库：REVERSE_ANALYSIS.md §8（Room 表结构全量还原：NoteStateEntity/ToolStateEntity/ClientOp/NoteAsset/SyncedNoteMetadata）
- 契约：`docs/migration/phase-1-data-model.md` §3.10 和 §3.11

## 实现要求

### 创建文件

1. `note/src/main/ets/data/DatabaseHelper.ets`
2. `note/src/main/ets/data/RepositoryInterfaces.ets`

### DatabaseHelper.ets 必须导出

- `const DB_VERSION: number = 1`
- `const DB_NAME: string = 'nota.db'`
- `const DDL_NOTE_STATE: string`（CREATE TABLE note_state，4 列）
- `const DDL_TOOL_STATE: string`（CREATE TABLE tool_state，11 列）
- `const DDL_CLIENT_OP: string`（CREATE TABLE client_op，5 列）
- `const DDL_NOTE_ASSET: string`（CREATE TABLE note_asset，6 列）
- `const DDL_NOTE_META: string`（CREATE TABLE note_meta，8 列）
- `const DDL_PAGE_INFO: string`（CREATE TABLE page_info，8 列）
- `const DDL_INDEXES: string[]`（3 条索引）

### RepositoryInterfaces.ets 必须导出

- `interface NoteRepository`（8 方法：createNote/getNote/getAllNotes/getNotesByFolder/updateNote/deleteNote/getViewState/saveViewState）
- `interface PageRepository`（5 方法：getPages/addPage/deletePage/updatePage/reorderPages）
- `interface ToolRepository`（2 方法：getToolStates/saveToolState）
- `interface AssetRepository`（4 方法：getAsset/saveAsset/getAssetsByNote/deleteAsset）

### 依赖

- DatabaseHelper.ets: 无 import（纯字符串常量）
- RepositoryInterfaces.ets:
  - `import { NoteMeta, NoteViewState, PageInfo } from '../core/model/NoteTypes'`
  - `import { ToolState } from '../core/model/BrushTypes'`
  - `import { NoteAsset } from '../core/model/AssetTypes'`

### 鸿蒙特有约束

- DatabaseHelper.ets 只定义 DDL 字符串常量，**不 import relationalStore**（实际数据库初始化在 Phase 2 实现）。
- DDL 使用标准 SQLite 语法（relationalStore 底层为 SQLite）。
- 所有 Repository 方法返回 `Promise<T>`。
- DDL 中布尔字段用 `INTEGER NOT NULL DEFAULT 0`（SQLite 无 BOOLEAN）。
- DDL 中 BLOB 字段用 `BLOB NOT NULL`。
- note_asset.note_ids 用 `TEXT NOT NULL DEFAULT '[]'`（JSON 数组字符串）。
- 索引名带 `idx_` 前缀。

### DDL 字段对照（防遗漏）

| 表 | 主键 | 必填字段 |
|----|------|----------|
| note_state | note_id TEXT | zoom REAL, scroll_offset_x REAL, scroll_offset_y REAL |
| tool_state | tool_id TEXT | tray_owner_id, tool_type INT, tray_index INT, color INT, width_size REAL, style INT, selected_color_well_index INT, selected_width_well_index INT, selection_is_freehand INT, eraser_is_partial INT |
| client_op | op_id TEXT | note_id TEXT, op_type INT, payload BLOB, client_time INT |
| note_asset | asset_hash TEXT | status INT, note_ids TEXT, file_size INT, mime_type TEXT, local_path TEXT(nullable) |
| note_meta | id TEXT | title TEXT, created_at INT, updated_at INT, favorite INT, last_opened INT, folder_id TEXT(nullable), has_recordings INT |
| page_info | page_id TEXT | note_id TEXT, page_index INT, size INT, template INT, orientation INT, width_mm REAL, height_mm REAL |

## 验收标准

- [ ] 两个文件存在且 `check_ets_files` 零错误
- [ ] `build_project` 编译通过
- [ ] DDL_NOTE_STATE 到 DDL_PAGE_INFO 共 6 条 CREATE TABLE
- [ ] DDL_INDEXES 包含 3 条 CREATE INDEX
- [ ] RepositoryInterfaces 中所有方法返回 Promise
- [ ] DatabaseHelper.ets 不含任何 `@ohos` import
- [ ] 不修改契约签名

## 完成报告

`docs/migration/reports/T-007-完成.md`
