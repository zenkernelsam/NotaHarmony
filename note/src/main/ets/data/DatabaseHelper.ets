// T-007 数据库 DDL 契约（契约 phase-1-data-model.md §3.10，照搬，禁止修改签名）
// 只定义 DDL 字符串常量，不 import relationalStore（实际数据库初始化在 Phase 2 实现）
// 不 import 任何 @ohos.* / @kit.* 平台模块

// 数据库版本
// T-039：folder 表新增 → 版本 2（CREATE TABLE IF NOT EXISTS 幂等迁移）
export const DB_VERSION: number = 2;
export const DB_NAME: string = 'nota.db';

// DDL 语句（工人实现时直接执行）
export const DDL_NOTE_STATE: string = `
CREATE TABLE IF NOT EXISTS note_state (
  note_id TEXT PRIMARY KEY,
  zoom REAL NOT NULL DEFAULT 1.0,
  scroll_offset_x REAL NOT NULL DEFAULT 0,
  scroll_offset_y REAL NOT NULL DEFAULT 0
)`;

export const DDL_TOOL_STATE: string = `
CREATE TABLE IF NOT EXISTS tool_state (
  tool_id TEXT PRIMARY KEY,
  tray_owner_id TEXT NOT NULL,
  tool_type INTEGER NOT NULL,
  tray_index INTEGER NOT NULL,
  color INTEGER NOT NULL DEFAULT -16777216,
  width_size REAL NOT NULL DEFAULT 36.0,
  style INTEGER NOT NULL DEFAULT 0,
  selected_color_well_index INTEGER NOT NULL DEFAULT 0,
  selected_width_well_index INTEGER NOT NULL DEFAULT 0,
  selection_is_freehand INTEGER NOT NULL DEFAULT 0,
  eraser_is_partial INTEGER NOT NULL DEFAULT 0
)`;

export const DDL_CLIENT_OP: string = `
CREATE TABLE IF NOT EXISTS client_op (
  op_id TEXT PRIMARY KEY,
  note_id TEXT NOT NULL,
  op_type INTEGER NOT NULL,
  payload BLOB NOT NULL,
  client_time INTEGER NOT NULL
)`;

export const DDL_NOTE_ASSET: string = `
CREATE TABLE IF NOT EXISTS note_asset (
  asset_hash TEXT PRIMARY KEY,
  status INTEGER NOT NULL DEFAULT 0,
  note_ids TEXT NOT NULL DEFAULT '[]',
  file_size INTEGER NOT NULL DEFAULT 0,
  mime_type TEXT NOT NULL DEFAULT '',
  local_path TEXT
)`;

export const DDL_NOTE_META: string = `
CREATE TABLE IF NOT EXISTS note_meta (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL DEFAULT '',
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  favorite INTEGER NOT NULL DEFAULT 0,
  last_opened INTEGER NOT NULL DEFAULT 0,
  folder_id TEXT,
  has_recordings INTEGER NOT NULL DEFAULT 0
)`;

export const DDL_PAGE_INFO: string = `
CREATE TABLE IF NOT EXISTS page_info (
  page_id TEXT PRIMARY KEY,
  note_id TEXT NOT NULL,
  page_index INTEGER NOT NULL,
  size INTEGER NOT NULL DEFAULT 1,
  template INTEGER NOT NULL DEFAULT 0,
  orientation INTEGER NOT NULL DEFAULT 0,
  width_mm REAL NOT NULL DEFAULT 210.0,
  height_mm REAL NOT NULL DEFAULT 297.0
)`;

// T-039：文件夹表
export const DDL_FOLDER: string = `
CREATE TABLE IF NOT EXISTS folder (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at INTEGER NOT NULL
)`;

// 索引
export const DDL_INDEXES: string[] = [
  'CREATE INDEX IF NOT EXISTS idx_client_op_note ON client_op(note_id, client_time)',
  'CREATE INDEX IF NOT EXISTS idx_page_info_note ON page_info(note_id, page_index)',
  'CREATE INDEX IF NOT EXISTS idx_note_meta_folder ON note_meta(folder_id)',
];
