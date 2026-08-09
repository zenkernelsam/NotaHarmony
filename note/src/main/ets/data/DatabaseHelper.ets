// T-007 数据库 DDL 契约（契约 phase-1-data-model.md §3.10，照搬，禁止修改签名）
// 只定义 DDL 字符串常量，不 import relationalStore（实际数据库初始化在 Phase 2 实现）
// 不 import 任何 @ohos.* / @kit.* 平台模块

// 数据库版本
// v23: separate stable original page identities from CREATE/MOVE sequence positions.
export const DB_VERSION: number = 23;
export const DB_NAME: string = 'nota.db';

// DDL 语句（工人实现时直接执行）
export const DDL_NOTE_STATE: string = `
CREATE TABLE IF NOT EXISTS note_state (
  note_id TEXT PRIMARY KEY,
  zoom REAL NOT NULL DEFAULT 1.0,
  scroll_offset_x REAL NOT NULL DEFAULT 0,
  scroll_offset_y REAL NOT NULL DEFAULT 0,
  coordinate_model_version INTEGER NOT NULL DEFAULT 1,
  FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE
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

// payload is intentionally BLOB: StrokePersistence stores UTF-8 encoded JSON bytes,
// and legacy client_op payload bytes migrate without SQLite TEXT coercion.
export const DDL_PAGE_ELEMENT_SNAPSHOT: string = `
CREATE TABLE IF NOT EXISTS page_element_snapshot (
  note_id TEXT NOT NULL,
  page_id TEXT NOT NULL,
  element_id TEXT NOT NULL,
  kind INTEGER NOT NULL,
  payload BLOB NOT NULL,
  revision INTEGER NOT NULL,
  element_order INTEGER NOT NULL,
  PRIMARY KEY(note_id, page_id, element_id, kind),
  FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE,
  FOREIGN KEY(note_id, page_id) REFERENCES page_info(note_id, page_id) ON DELETE CASCADE
)`;

export const DDL_OPERATION_LOG: string = `
CREATE TABLE IF NOT EXISTS operation_log (
  sequence INTEGER PRIMARY KEY AUTOINCREMENT,
  note_id TEXT NOT NULL,
  op_id TEXT NOT NULL,
  op_type INTEGER NOT NULL,
  payload BLOB NOT NULL,
  client_time INTEGER NOT NULL,
  op_timestamp INTEGER NOT NULL CHECK (op_timestamp BETWEEN 0 AND 4294967295),
  editor_site_id INTEGER NOT NULL CHECK (editor_site_id BETWEEN 0 AND 65535),
  upload_immediately INTEGER NOT NULL DEFAULT 0 CHECK (upload_immediately IN (0, 1)),
  action_id TEXT,
  history_effect INTEGER,
  coalesce_track INTEGER,
  action_time INTEGER,
  CHECK ((action_id IS NULL AND history_effect IS NULL AND coalesce_track IS NULL AND action_time IS NULL)
    OR (action_id IS NOT NULL AND history_effect IS NOT NULL AND coalesce_track IS NOT NULL AND action_time IS NOT NULL)),
  UNIQUE(note_id, op_id),
  UNIQUE(note_id, editor_site_id, op_timestamp),
  FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE
)`;

export const DDL_LOCAL_EDITOR_IDENTITY: string = `
CREATE TABLE IF NOT EXISTS local_editor_identity (
  singleton INTEGER PRIMARY KEY CHECK (singleton = 1),
  editor_id TEXT NOT NULL UNIQUE
)`;

// Mirrors the durable part of NoteStaticMetadata/SyncedOpMetadata. Site 0 is the original
// local-unsynced fallback; a future sync resolver may replace it before minting remote ops.
export const DDL_NOTE_SYNC_METADATA: string = `
CREATE TABLE IF NOT EXISTS note_sync_metadata (
  note_id TEXT PRIMARY KEY,
  legacy_id TEXT,
  editor_site_id INTEGER NOT NULL CHECK (editor_site_id BETWEEN 0 AND 65535),
  editor_id TEXT NOT NULL,
  creator_id TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  max_server_time TEXT CHECK (max_server_time IS NULL OR (
    typeof(max_server_time) = 'text' AND length(max_server_time) BETWEEN 1 AND 20
    AND max_server_time NOT GLOB '*[^0-9]*'
    AND (max_server_time = '0' OR substr(max_server_time, 1, 1) <> '0')
    AND (length(max_server_time) < 20 OR max_server_time <= '18446744073709551615')
  )),
  synced_op_count INTEGER NOT NULL DEFAULT 0 CHECK (synced_op_count >= 0),
  max_op_timestamp INTEGER NOT NULL DEFAULT 0 CHECK (max_op_timestamp BETWEEN 0 AND 4294967295),
  schema_version INTEGER NOT NULL DEFAULT 1,
  uploaded_through_sequence INTEGER NOT NULL DEFAULT 0 CHECK (uploaded_through_sequence >= 0),
  acked_through_sequence INTEGER NOT NULL DEFAULT 0 CHECK (acked_through_sequence >= 0),
  CHECK (acked_through_sequence <= uploaded_through_sequence),
  FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE
)`;

const DDL_NOTE_SYNC_METADATA_V18: string = `
CREATE TABLE IF NOT EXISTS note_sync_metadata (
  note_id TEXT PRIMARY KEY,
  legacy_id TEXT,
  editor_site_id INTEGER NOT NULL CHECK (editor_site_id BETWEEN 0 AND 65535),
  editor_id TEXT NOT NULL,
  creator_id TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  max_server_time INTEGER,
  synced_op_count INTEGER NOT NULL DEFAULT 0 CHECK (synced_op_count >= 0),
  max_op_timestamp INTEGER NOT NULL DEFAULT 0 CHECK (max_op_timestamp BETWEEN 0 AND 4294967295),
  schema_version INTEGER NOT NULL DEFAULT 1,
  uploaded_through_sequence INTEGER NOT NULL DEFAULT 0 CHECK (uploaded_through_sequence >= 0),
  acked_through_sequence INTEGER NOT NULL DEFAULT 0 CHECK (acked_through_sequence >= 0),
  CHECK (acked_through_sequence <= uploaded_through_sequence),
  FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE
)`;

const DDL_NOTE_SYNC_METADATA_V19: string = `
CREATE TABLE note_sync_metadata_v19 (
  note_id TEXT PRIMARY KEY,
  legacy_id TEXT,
  editor_site_id INTEGER NOT NULL CHECK (editor_site_id BETWEEN 0 AND 65535),
  editor_id TEXT NOT NULL,
  creator_id TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  max_server_time TEXT CHECK (max_server_time IS NULL OR (
    typeof(max_server_time) = 'text' AND length(max_server_time) BETWEEN 1 AND 20
    AND max_server_time NOT GLOB '*[^0-9]*'
    AND (max_server_time = '0' OR substr(max_server_time, 1, 1) <> '0')
    AND (length(max_server_time) < 20 OR max_server_time <= '18446744073709551615')
  )),
  synced_op_count INTEGER NOT NULL DEFAULT 0 CHECK (synced_op_count >= 0),
  max_op_timestamp INTEGER NOT NULL DEFAULT 0 CHECK (max_op_timestamp BETWEEN 0 AND 4294967295),
  schema_version INTEGER NOT NULL DEFAULT 1,
  uploaded_through_sequence INTEGER NOT NULL DEFAULT 0 CHECK (uploaded_through_sequence >= 0),
  acked_through_sequence INTEGER NOT NULL DEFAULT 0 CHECK (acked_through_sequence >= 0),
  CHECK (acked_through_sequence <= uploaded_through_sequence),
  FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE
)`;

// Raw synced ops stay isolated until their original FlatBuffer payload can be validated/applied.
export const DDL_SYNCED_OPERATION_INBOX: string = `
CREATE TABLE IF NOT EXISTS synced_operation_inbox (
  note_id TEXT NOT NULL,
  op_timestamp INTEGER NOT NULL CHECK (op_timestamp BETWEEN 0 AND 4294967295),
  editor_site_id INTEGER NOT NULL CHECK (editor_site_id BETWEEN 0 AND 65535),
  client_time TEXT NOT NULL CHECK (
    typeof(client_time) = 'text' AND length(client_time) BETWEEN 1 AND 20
    AND client_time NOT GLOB '*[^0-9]*'
    AND (client_time = '0' OR substr(client_time, 1, 1) <> '0')
    AND (length(client_time) < 20 OR client_time <= '18446744073709551615')
  ),
  server_time TEXT NOT NULL CHECK (
    typeof(server_time) = 'text' AND length(server_time) BETWEEN 1 AND 20
    AND server_time NOT GLOB '*[^0-9]*'
    AND (server_time = '0' OR substr(server_time, 1, 1) <> '0')
    AND (length(server_time) < 20 OR server_time <= '18446744073709551615')
  ),
  schema_version INTEGER NOT NULL CHECK (schema_version BETWEEN 0 AND 65535),
  payload_type INTEGER NOT NULL CHECK (payload_type BETWEEN 0 AND 255),
  raw_operation BLOB NOT NULL CHECK (length(raw_operation) BETWEEN 1 AND 67108864),
  state INTEGER NOT NULL DEFAULT 0 CHECK (state IN (0, 1, 2)),
  deferred_reason TEXT,
  received_at INTEGER NOT NULL CHECK (received_at BETWEEN 0 AND 9007199254740991),
  CHECK ((state = 1 AND deferred_reason IS NOT NULL AND length(deferred_reason) > 0)
    OR (state IN (0, 2) AND deferred_reason IS NULL)),
  PRIMARY KEY(note_id, op_timestamp, editor_site_id),
  FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE
)`;

export const DDL_ORIGINAL_PAGE_INSERT_GROUP: string = `
CREATE TABLE IF NOT EXISTS original_page_insert_group (
  note_id TEXT NOT NULL,
  op_timestamp INTEGER NOT NULL CHECK (op_timestamp BETWEEN 0 AND 4294967295),
  op_site_id INTEGER NOT NULL CHECK (op_site_id BETWEEN 0 AND 65535),
  parent_timestamp INTEGER CHECK (parent_timestamp BETWEEN 0 AND 4294967295),
  parent_site_id INTEGER CHECK (parent_site_id BETWEEN 0 AND 65535),
  parent_index INTEGER CHECK (parent_index BETWEEN 0 AND 4294967295),
  page_count INTEGER NOT NULL CHECK (page_count BETWEEN 1 AND 10000),
  modified_time TEXT NOT NULL CHECK (
    typeof(modified_time) = 'text' AND length(modified_time) BETWEEN 1 AND 20
    AND modified_time NOT GLOB '*[^0-9]*'
    AND (modified_time = '0' OR substr(modified_time, 1, 1) <> '0')
    AND (length(modified_time) < 20 OR modified_time <= '18446744073709551615')
  ),
  CHECK ((parent_timestamp IS NULL AND parent_site_id IS NULL AND parent_index IS NULL)
    OR (parent_timestamp IS NOT NULL AND parent_site_id IS NOT NULL AND parent_index IS NOT NULL)),
  PRIMARY KEY(note_id, op_timestamp, op_site_id),
  FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE
)`;

export const DDL_ORIGINAL_PAGE_IDENTITY: string = `
CREATE TABLE IF NOT EXISTS original_page_identity (
  note_id TEXT NOT NULL,
  seq_timestamp INTEGER NOT NULL CHECK (seq_timestamp BETWEEN 0 AND 4294967295),
  seq_site_id INTEGER NOT NULL CHECK (seq_site_id BETWEEN 0 AND 65535),
  seq_index INTEGER NOT NULL CHECK (seq_index BETWEEN 0 AND 4294967295),
  page_id TEXT,
  visible INTEGER NOT NULL DEFAULT 1 CHECK (visible IN (0, 1)),
  CHECK ((visible = 1 AND page_id IS NOT NULL AND length(page_id) > 0)
    OR (visible = 0 AND page_id IS NULL)),
  PRIMARY KEY(note_id, seq_timestamp, seq_site_id, seq_index),
  UNIQUE(note_id, page_id),
  FOREIGN KEY(note_id, seq_timestamp, seq_site_id)
    REFERENCES original_page_insert_group(note_id, op_timestamp, op_site_id) ON DELETE CASCADE,
  FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE
)`;

export const DDL_ORIGINAL_PAGE_POSITION_GROUP: string = `
CREATE TABLE IF NOT EXISTS original_page_position_group (
  note_id TEXT NOT NULL,
  op_timestamp INTEGER NOT NULL CHECK (op_timestamp BETWEEN 0 AND 4294967295),
  op_site_id INTEGER NOT NULL CHECK (op_site_id BETWEEN 0 AND 65535),
  parent_timestamp INTEGER CHECK (parent_timestamp BETWEEN 0 AND 4294967295),
  parent_site_id INTEGER CHECK (parent_site_id BETWEEN 0 AND 65535),
  parent_index INTEGER CHECK (parent_index BETWEEN 0 AND 4294967295),
  position_count INTEGER NOT NULL CHECK (position_count BETWEEN 1 AND 10000),
  modified_time TEXT NOT NULL CHECK (
    typeof(modified_time) = 'text' AND length(modified_time) BETWEEN 1 AND 20
    AND modified_time NOT GLOB '*[^0-9]*'
    AND (modified_time = '0' OR substr(modified_time, 1, 1) <> '0')
    AND (length(modified_time) < 20 OR modified_time <= '18446744073709551615')
  ),
  CHECK ((parent_timestamp IS NULL AND parent_site_id IS NULL AND parent_index IS NULL)
    OR (parent_timestamp IS NOT NULL AND parent_site_id IS NOT NULL AND parent_index IS NOT NULL)),
  PRIMARY KEY(note_id, op_timestamp, op_site_id),
  FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE
)`;

export const DDL_ORIGINAL_PAGE_POSITION: string = `
CREATE TABLE IF NOT EXISTS original_page_position (
  note_id TEXT NOT NULL,
  pos_timestamp INTEGER NOT NULL CHECK (pos_timestamp BETWEEN 0 AND 4294967295),
  pos_site_id INTEGER NOT NULL CHECK (pos_site_id BETWEEN 0 AND 65535),
  pos_index INTEGER NOT NULL CHECK (pos_index BETWEEN 0 AND 4294967295),
  page_timestamp INTEGER NOT NULL CHECK (page_timestamp BETWEEN 0 AND 4294967295),
  page_site_id INTEGER NOT NULL CHECK (page_site_id BETWEEN 0 AND 65535),
  page_index INTEGER NOT NULL CHECK (page_index BETWEEN 0 AND 4294967295),
  PRIMARY KEY(note_id, pos_timestamp, pos_site_id, pos_index),
  FOREIGN KEY(note_id, pos_timestamp, pos_site_id)
    REFERENCES original_page_position_group(note_id, op_timestamp, op_site_id) ON DELETE CASCADE,
  FOREIGN KEY(note_id, page_timestamp, page_site_id, page_index)
    REFERENCES original_page_identity(note_id, seq_timestamp, seq_site_id, seq_index) ON DELETE CASCADE,
  FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE
)`;

export const DDL_ORIGINAL_PAGE_POSITION_WINNER: string = `
CREATE TABLE IF NOT EXISTS original_page_position_winner (
  note_id TEXT NOT NULL,
  page_timestamp INTEGER NOT NULL CHECK (page_timestamp BETWEEN 0 AND 4294967295),
  page_site_id INTEGER NOT NULL CHECK (page_site_id BETWEEN 0 AND 65535),
  page_index INTEGER NOT NULL CHECK (page_index BETWEEN 0 AND 4294967295),
  winner_timestamp INTEGER NOT NULL CHECK (winner_timestamp BETWEEN 0 AND 4294967295),
  winner_site_id INTEGER NOT NULL CHECK (winner_site_id BETWEEN 0 AND 65535),
  position_index INTEGER NOT NULL CHECK (position_index BETWEEN 0 AND 4294967295),
  PRIMARY KEY(note_id, page_timestamp, page_site_id, page_index),
  UNIQUE(note_id, winner_timestamp, winner_site_id, position_index),
  FOREIGN KEY(note_id, page_timestamp, page_site_id, page_index)
    REFERENCES original_page_identity(note_id, seq_timestamp, seq_site_id, seq_index) ON DELETE CASCADE,
  FOREIGN KEY(note_id, winner_timestamp, winner_site_id, position_index)
    REFERENCES original_page_position(note_id, pos_timestamp, pos_site_id, pos_index) ON DELETE CASCADE,
  FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE
)`;

// Original DeferredSyncedOps points to checksummed files. Harmony keeps the equivalent raw
// bundle in SQLite so row and bytes cross the same transaction boundary.
export const DDL_DEFERRED_SYNCED_OPERATION_BUNDLE: string = `
CREATE TABLE IF NOT EXISTS deferred_synced_operation_bundle (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  note_id TEXT NOT NULL,
  schema_version INTEGER NOT NULL CHECK (schema_version BETWEEN 0 AND 65535),
  table_type TEXT NOT NULL CHECK (table_type IN (
    'NOTE_BUNDLE', 'OPS_BUNDLE', 'RECEIVE_OPS_EVENT'
  )),
  payload BLOB NOT NULL,
  payload_size INTEGER NOT NULL CHECK (payload_size BETWEEN 1 AND 67108864),
  checksum INTEGER NOT NULL CHECK (checksum BETWEEN -2147483648 AND 2147483647),
  received_at INTEGER NOT NULL CHECK (received_at BETWEEN 0 AND 9007199254740991),
  CHECK (length(payload) = payload_size),
  FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE
)`;

const DDL_DEFERRED_SYNCED_OPERATION_BUNDLE_V21: string = `
CREATE TABLE deferred_synced_operation_bundle_v21 (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  note_id TEXT NOT NULL,
  schema_version INTEGER NOT NULL CHECK (schema_version BETWEEN 0 AND 65535),
  table_type TEXT NOT NULL CHECK (table_type IN (
    'NOTE_BUNDLE', 'OPS_BUNDLE', 'RECEIVE_OPS_EVENT'
  )),
  payload BLOB NOT NULL,
  payload_size INTEGER NOT NULL CHECK (payload_size BETWEEN 1 AND 67108864),
  checksum INTEGER NOT NULL CHECK (checksum BETWEEN -2147483648 AND 2147483647),
  received_at INTEGER NOT NULL CHECK (received_at BETWEEN 0 AND 9007199254740991),
  CHECK (length(payload) = payload_size),
  FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE
)`;

export const DDL_PAGE_DELETE_CHECKPOINT: string = `
CREATE TABLE IF NOT EXISTS page_delete_checkpoint (
  note_id TEXT NOT NULL,
  action_id TEXT NOT NULL,
  page_id TEXT NOT NULL,
  page_index INTEGER NOT NULL,
  size INTEGER NOT NULL,
  template INTEGER NOT NULL,
  orientation INTEGER NOT NULL,
  width_mm REAL NOT NULL,
  height_mm REAL NOT NULL,
  content_revision INTEGER NOT NULL,
  indexed_revision INTEGER,
  created_time INTEGER NOT NULL,
  PRIMARY KEY(note_id, action_id),
  FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE
)`;

export const DDL_PAGE_DELETE_CHECKPOINT_ELEMENT: string = `
CREATE TABLE IF NOT EXISTS page_delete_checkpoint_element (
  note_id TEXT NOT NULL,
  action_id TEXT NOT NULL,
  element_id TEXT NOT NULL,
  kind INTEGER NOT NULL,
  payload BLOB NOT NULL,
  revision INTEGER NOT NULL,
  element_order INTEGER NOT NULL,
  PRIMARY KEY(note_id, action_id, element_id, kind),
  FOREIGN KEY(note_id, action_id) REFERENCES page_delete_checkpoint(note_id, action_id) ON DELETE CASCADE
)`;

export const DDL_PAGE_DELETE_CHECKPOINT_SEARCH: string = `
CREATE TABLE IF NOT EXISTS page_delete_checkpoint_search (
  note_id TEXT NOT NULL,
  action_id TEXT NOT NULL,
  type INTEGER NOT NULL,
  sub_id TEXT NOT NULL,
  folded_text TEXT NOT NULL,
  rects BLOB,
  PRIMARY KEY(note_id, action_id, type, sub_id),
  FOREIGN KEY(note_id, action_id) REFERENCES page_delete_checkpoint(note_id, action_id) ON DELETE CASCADE
)`;

export const DDL_HISTORY_CHECKPOINT: string = `
CREATE TABLE IF NOT EXISTS history_checkpoint (
  note_id TEXT PRIMARY KEY,
  through_sequence INTEGER NOT NULL,
  legacy_operation_count INTEGER NOT NULL,
  created_time INTEGER NOT NULL,
  FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE
)`;

export const DDL_HISTORY_CHECKPOINT_ACTION: string = `
CREATE TABLE IF NOT EXISTS history_checkpoint_action (
  note_id TEXT NOT NULL,
  stack_kind INTEGER NOT NULL,
  stack_index INTEGER NOT NULL,
  action_id TEXT NOT NULL,
  coalesce_track INTEGER NOT NULL,
  action_time INTEGER NOT NULL,
  CHECK (stack_kind IN (0, 1)),
  PRIMARY KEY(note_id, stack_kind, stack_index),
  UNIQUE(note_id, action_id),
  FOREIGN KEY(note_id) REFERENCES history_checkpoint(note_id) ON DELETE CASCADE
)`;

export const DDL_HISTORY_CHECKPOINT_OPERATION: string = `
CREATE TABLE IF NOT EXISTS history_checkpoint_operation (
  note_id TEXT NOT NULL,
  stack_kind INTEGER NOT NULL,
  stack_index INTEGER NOT NULL,
  operation_index INTEGER NOT NULL,
  op_id TEXT NOT NULL,
  op_type INTEGER NOT NULL,
  payload BLOB NOT NULL,
  client_time INTEGER NOT NULL,
  PRIMARY KEY(note_id, stack_kind, stack_index, operation_index),
  FOREIGN KEY(note_id, stack_kind, stack_index)
    REFERENCES history_checkpoint_action(note_id, stack_kind, stack_index) ON DELETE CASCADE
)`;

// Historical migrations must never reference the evolving latest-schema DDL.
const DDL_OPERATION_LOG_V13: string = `
CREATE TABLE IF NOT EXISTS operation_log (
  sequence INTEGER PRIMARY KEY AUTOINCREMENT,
  note_id TEXT NOT NULL,
  op_id TEXT NOT NULL,
  op_type INTEGER NOT NULL,
  payload BLOB NOT NULL,
  client_time INTEGER NOT NULL,
  UNIQUE(note_id, op_id),
  FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE
)`;

const DDL_OPERATION_LOG_V18: string = `
CREATE TABLE operation_log_v18 (
  sequence INTEGER PRIMARY KEY AUTOINCREMENT,
  note_id TEXT NOT NULL,
  op_id TEXT NOT NULL,
  op_type INTEGER NOT NULL,
  payload BLOB NOT NULL,
  client_time INTEGER NOT NULL,
  op_timestamp INTEGER NOT NULL CHECK (op_timestamp BETWEEN 0 AND 4294967295),
  editor_site_id INTEGER NOT NULL CHECK (editor_site_id BETWEEN 0 AND 65535),
  upload_immediately INTEGER NOT NULL DEFAULT 0 CHECK (upload_immediately IN (0, 1)),
  action_id TEXT,
  history_effect INTEGER,
  coalesce_track INTEGER,
  action_time INTEGER,
  CHECK ((action_id IS NULL AND history_effect IS NULL AND coalesce_track IS NULL AND action_time IS NULL)
    OR (action_id IS NOT NULL AND history_effect IS NOT NULL AND coalesce_track IS NOT NULL AND action_time IS NOT NULL)),
  UNIQUE(note_id, op_id),
  UNIQUE(note_id, editor_site_id, op_timestamp),
  FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE
)`;

// The original ToolboxEntity keeps both the active and previous tool IDs.
export const DDL_EDITOR_TOOLBOX_STATE: string = `
CREATE TABLE IF NOT EXISTS editor_toolbox_state (
  owner_id TEXT PRIMARY KEY,
  most_recent_tool_id TEXT NOT NULL,
  previous_tool_id TEXT NOT NULL
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
  has_recordings INTEGER NOT NULL DEFAULT 0,
  structure_revision INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY(folder_id) REFERENCES folder(id) ON DELETE SET NULL
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
  height_mm REAL NOT NULL DEFAULT 297.0,
  content_revision INTEGER NOT NULL DEFAULT 0,
  UNIQUE(note_id, page_index),
  UNIQUE(note_id, page_id),
  FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE
)`;

// T-039：文件夹表
export const DDL_FOLDER: string = `
CREATE TABLE IF NOT EXISTS folder (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  parent_id TEXT,
  sibling_order REAL NOT NULL DEFAULT 0,
  FOREIGN KEY(parent_id) REFERENCES folder(id) ON DELETE CASCADE
)`;

// Mirrors the original app's search_item(noteId, type, subId, pageId, foldedText, rects).
// Types are defined in SearchItemType.ets: title=0, main body=1, text block=2, ink=3, PDF=6.
export const DDL_SEARCH_ITEM: string = `
CREATE TABLE IF NOT EXISTS search_item (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  note_id TEXT NOT NULL,
  type INTEGER NOT NULL,
  sub_id TEXT NOT NULL,
  page_id TEXT,
  folded_text TEXT NOT NULL,
  rects BLOB,
  UNIQUE(note_id, type, sub_id),
  FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE,
  FOREIGN KEY(note_id, page_id) REFERENCES page_info(note_id, page_id) ON DELETE CASCADE
)`;

export const DDL_SEARCH_PAGE_STATE: string = `
CREATE TABLE IF NOT EXISTS search_page_state (
  note_id TEXT NOT NULL,
  page_id TEXT NOT NULL,
  indexed_revision INTEGER NOT NULL,
  PRIMARY KEY(note_id, page_id),
  FOREIGN KEY(note_id, page_id) REFERENCES page_info(note_id, page_id) ON DELETE CASCADE
)`;

// 索引
export const DDL_INDEXES: string[] = [
  `CREATE INDEX IF NOT EXISTS idx_page_snapshot_note
    ON page_element_snapshot(note_id, revision)`,
  `CREATE INDEX IF NOT EXISTS idx_page_snapshot_page
    ON page_element_snapshot(note_id, page_id, element_order)`,
  `CREATE INDEX IF NOT EXISTS idx_operation_log_note_time
    ON operation_log(note_id, client_time, sequence)`,
  `CREATE INDEX IF NOT EXISTS idx_operation_log_note_action
    ON operation_log(note_id, action_id, sequence)`,
  `CREATE INDEX IF NOT EXISTS idx_operation_log_pending_upload
    ON operation_log(note_id, sequence, upload_immediately)`,
  `CREATE INDEX IF NOT EXISTS idx_synced_operation_inbox_server_time
    ON synced_operation_inbox(note_id, length(server_time), server_time,
      length(client_time), client_time, op_timestamp, editor_site_id)`,
  `CREATE INDEX IF NOT EXISTS idx_synced_operation_inbox_state
    ON synced_operation_inbox(note_id, state, received_at)`,
  `CREATE INDEX IF NOT EXISTS idx_original_page_group_parent
    ON original_page_insert_group(note_id, parent_timestamp, parent_site_id, parent_index)`,
  `CREATE INDEX IF NOT EXISTS idx_original_page_identity_page
    ON original_page_identity(note_id, page_id)`,
  `CREATE INDEX IF NOT EXISTS idx_original_page_position_parent
    ON original_page_position_group(note_id, parent_timestamp, parent_site_id, parent_index)`,
  `CREATE INDEX IF NOT EXISTS idx_original_page_position_value
    ON original_page_position(note_id, page_timestamp, page_site_id, page_index)`,
  `CREATE INDEX IF NOT EXISTS idx_deferred_synced_bundle_note
    ON deferred_synced_operation_bundle(note_id, id)`,
  `CREATE INDEX IF NOT EXISTS idx_page_delete_checkpoint_page
    ON page_delete_checkpoint(note_id, page_id, created_time)`,
  'CREATE UNIQUE INDEX IF NOT EXISTS idx_page_info_note ON page_info(note_id, page_index)',
  'CREATE INDEX IF NOT EXISTS idx_note_meta_folder ON note_meta(folder_id)',
  'CREATE INDEX IF NOT EXISTS idx_folder_parent_order ON folder(parent_id, sibling_order)',
  'CREATE UNIQUE INDEX IF NOT EXISTS idx_search_item_identity ON search_item(note_id, type, sub_id)',
  'CREATE INDEX IF NOT EXISTS idx_search_item_note_text ON search_item(note_id, folded_text)',
];

// Key is the target version. Each version is applied atomically by DatabaseManager.
export const MIGRATIONS: Record<number, string[]> = {
  3: [
    "ALTER TABLE client_op ADD COLUMN page_id TEXT NOT NULL DEFAULT ''",
    "UPDATE client_op SET page_id = COALESCE((SELECT page_id FROM page_info " +
      "WHERE page_info.note_id = client_op.note_id ORDER BY page_index LIMIT 1), '') " +
      "WHERE page_id = ''",
    'CREATE INDEX IF NOT EXISTS idx_client_op_page ON client_op(note_id, page_id, client_time)',
  ],
  4: [
    `CREATE TABLE client_op_v4 (
      op_id TEXT NOT NULL,
      note_id TEXT NOT NULL,
      page_id TEXT NOT NULL DEFAULT '',
      op_type INTEGER NOT NULL,
      payload BLOB NOT NULL,
      client_time INTEGER NOT NULL,
      PRIMARY KEY(note_id, op_id)
    )`,
    `INSERT INTO client_op_v4(op_id, note_id, page_id, op_type, payload, client_time)
      SELECT op_id, note_id, page_id, op_type, payload, client_time FROM client_op`,
    'DROP TABLE client_op',
    'ALTER TABLE client_op_v4 RENAME TO client_op',
  ],
  5: [
    'DROP TABLE IF EXISTS page_order_v5',
    `CREATE TEMP TABLE page_order_v5 (
      page_id TEXT PRIMARY KEY,
      page_index INTEGER NOT NULL
    )`,
    `INSERT INTO page_order_v5(page_id, page_index)
      SELECT current.page_id,
        (SELECT COUNT(*) FROM page_info previous
         WHERE previous.note_id = current.note_id
           AND (previous.page_index < current.page_index
             OR (previous.page_index = current.page_index AND previous.page_id < current.page_id)))
      FROM page_info current`,
    `UPDATE page_info SET page_index =
      (SELECT page_index FROM page_order_v5 WHERE page_order_v5.page_id = page_info.page_id)`,
    'DROP TABLE page_order_v5',
    'DROP INDEX IF EXISTS idx_page_info_note',
    'CREATE UNIQUE INDEX IF NOT EXISTS idx_page_info_note ON page_info(note_id, page_index)',
  ],
  6: [
    `UPDATE note_meta SET folder_id = NULL
      WHERE folder_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM folder WHERE folder.id = note_meta.folder_id
      )`,
    `INSERT OR IGNORE INTO note_meta
      (id, title, created_at, updated_at, favorite, last_opened, folder_id, has_recordings)
      SELECT DISTINCT note_id, 'Recovered Note', 0, 0, 0, 0, NULL, 0 FROM page_info
      WHERE NOT EXISTS (SELECT 1 FROM note_meta WHERE note_meta.id = page_info.note_id)`,
    `INSERT OR IGNORE INTO note_meta
      (id, title, created_at, updated_at, favorite, last_opened, folder_id, has_recordings)
      SELECT DISTINCT note_id, 'Recovered Note', 0, 0, 0, 0, NULL, 0 FROM client_op
      WHERE NOT EXISTS (SELECT 1 FROM note_meta WHERE note_meta.id = client_op.note_id)`,
    `INSERT OR IGNORE INTO note_meta
      (id, title, created_at, updated_at, favorite, last_opened, folder_id, has_recordings)
      SELECT DISTINCT note_id, 'Recovered Note', 0, 0, 0, 0, NULL, 0 FROM note_state
      WHERE NOT EXISTS (SELECT 1 FROM note_meta WHERE note_meta.id = note_state.note_id)`,
    `INSERT INTO page_info
      (page_id, note_id, page_index, size, template, orientation, width_mm, height_mm)
      SELECT 'recovered-' || lower(hex(randomblob(16))), source.note_id, 0, 1, 0, 0, 210.0, 297.0
      FROM (SELECT DISTINCT note_id FROM client_op) source
      WHERE NOT EXISTS (SELECT 1 FROM page_info WHERE page_info.note_id = source.note_id)`,
    `UPDATE client_op SET page_id = (
        SELECT page_id FROM page_info
        WHERE page_info.note_id = client_op.note_id ORDER BY page_index LIMIT 1
      )
      WHERE NOT EXISTS (
        SELECT 1 FROM page_info
        WHERE page_info.note_id = client_op.note_id AND page_info.page_id = client_op.page_id
      )`,
    `CREATE TABLE note_meta_v6 (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL DEFAULT '',
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      favorite INTEGER NOT NULL DEFAULT 0,
      last_opened INTEGER NOT NULL DEFAULT 0,
      folder_id TEXT,
      has_recordings INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY(folder_id) REFERENCES folder(id) ON DELETE SET NULL
    )`,
    `INSERT INTO note_meta_v6
      SELECT id, title, created_at, updated_at, favorite, last_opened, folder_id, has_recordings
      FROM note_meta`,
    'DROP TABLE note_meta',
    'ALTER TABLE note_meta_v6 RENAME TO note_meta',
    `CREATE TABLE page_info_v6 (
      page_id TEXT PRIMARY KEY,
      note_id TEXT NOT NULL,
      page_index INTEGER NOT NULL,
      size INTEGER NOT NULL DEFAULT 1,
      template INTEGER NOT NULL DEFAULT 0,
      orientation INTEGER NOT NULL DEFAULT 0,
      width_mm REAL NOT NULL DEFAULT 210.0,
      height_mm REAL NOT NULL DEFAULT 297.0,
      UNIQUE(note_id, page_index),
      UNIQUE(note_id, page_id),
      FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE
    )`,
    `INSERT INTO page_info_v6
      SELECT page_id, note_id, page_index, size, template, orientation, width_mm, height_mm
      FROM page_info`,
    'DROP TABLE page_info',
    'ALTER TABLE page_info_v6 RENAME TO page_info',
    `CREATE TABLE note_state_v6 (
      note_id TEXT PRIMARY KEY,
      zoom REAL NOT NULL DEFAULT 1.0,
      scroll_offset_x REAL NOT NULL DEFAULT 0,
      scroll_offset_y REAL NOT NULL DEFAULT 0,
      FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE
    )`,
    `INSERT INTO note_state_v6
      SELECT note_id, zoom, scroll_offset_x, scroll_offset_y FROM note_state`,
    'DROP TABLE note_state',
    'ALTER TABLE note_state_v6 RENAME TO note_state',
    `CREATE TABLE client_op_v6 (
      op_id TEXT NOT NULL,
      note_id TEXT NOT NULL,
      page_id TEXT NOT NULL,
      op_type INTEGER NOT NULL,
      payload BLOB NOT NULL,
      client_time INTEGER NOT NULL,
      PRIMARY KEY(note_id, op_id),
      FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE,
      FOREIGN KEY(note_id, page_id) REFERENCES page_info(note_id, page_id) ON DELETE CASCADE
    )`,
    `INSERT INTO client_op_v6
      SELECT op_id, note_id, page_id, op_type, payload, client_time FROM client_op`,
    'DROP TABLE client_op',
    'ALTER TABLE client_op_v6 RENAME TO client_op',
  ],
  7: [
    'ALTER TABLE page_info ADD COLUMN content_revision INTEGER NOT NULL DEFAULT 0',
    `CREATE TABLE page_element_snapshot_v7 (
      note_id TEXT NOT NULL,
      page_id TEXT NOT NULL,
      element_id TEXT NOT NULL,
      kind INTEGER NOT NULL,
      payload BLOB NOT NULL,
      revision INTEGER NOT NULL,
      element_order INTEGER NOT NULL,
      PRIMARY KEY(note_id, page_id, element_id, kind),
      FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE,
      FOREIGN KEY(note_id, page_id) REFERENCES page_info(note_id, page_id) ON DELETE CASCADE
    )`,
    `INSERT INTO page_element_snapshot_v7
      (note_id, page_id, element_id, kind, payload, revision, element_order)
      SELECT current.note_id, current.page_id, current.op_id, 0, current.payload, 1,
        (SELECT COUNT(*) FROM client_op previous
         WHERE previous.note_id = current.note_id AND previous.page_id = current.page_id
           AND (previous.client_time < current.client_time
             OR (previous.client_time = current.client_time AND previous.op_id < current.op_id)))
      FROM client_op current`,
    `UPDATE page_info SET content_revision = 1
      WHERE EXISTS (SELECT 1 FROM client_op WHERE client_op.note_id = page_info.note_id
        AND client_op.page_id = page_info.page_id)`,
    'DROP TABLE client_op',
    'DROP TABLE page_element_snapshot',
    'ALTER TABLE page_element_snapshot_v7 RENAME TO page_element_snapshot',
  ],
  8: [DDL_EDITOR_TOOLBOX_STATE],
  9: [
    'ALTER TABLE folder ADD COLUMN parent_id TEXT REFERENCES folder(id) ON DELETE CASCADE',
    'ALTER TABLE folder ADD COLUMN sibling_order REAL NOT NULL DEFAULT 0',
    `UPDATE folder SET sibling_order = (
      SELECT COUNT(*) FROM folder previous
      WHERE previous.created_at < folder.created_at
        OR (previous.created_at = folder.created_at AND previous.id < folder.id)
    )`,
  ],
  10: [
    DDL_SEARCH_ITEM,
    DDL_SEARCH_PAGE_STATE,
    `INSERT OR IGNORE INTO search_item(note_id, type, sub_id, page_id, folded_text, rects)
      SELECT id, 0, id, NULL, lower(title), NULL FROM note_meta`,
  ],
  11: [
    'ALTER TABLE note_state ADD COLUMN coordinate_model_version INTEGER NOT NULL DEFAULT 0',
  ],
  12: [
    `DELETE FROM search_item
      WHERE search_item.type = 1 AND EXISTS (
        SELECT 1 FROM search_item current
        WHERE current.note_id = search_item.note_id AND current.type = 2
          AND current.sub_id = search_item.sub_id
      )`,
    'UPDATE search_item SET type = 2 WHERE type = 1',
  ],
  13: [DDL_OPERATION_LOG_V13],
  14: ['ALTER TABLE note_meta ADD COLUMN structure_revision INTEGER NOT NULL DEFAULT 0'],
  15: [
    'ALTER TABLE operation_log ADD COLUMN action_id TEXT',
    'ALTER TABLE operation_log ADD COLUMN history_effect INTEGER',
    'ALTER TABLE operation_log ADD COLUMN coalesce_track INTEGER',
    'ALTER TABLE operation_log ADD COLUMN action_time INTEGER',
    `CREATE INDEX IF NOT EXISTS idx_operation_log_note_action
      ON operation_log(note_id, action_id, sequence)`,
  ],
  16: [
    DDL_PAGE_DELETE_CHECKPOINT,
    DDL_PAGE_DELETE_CHECKPOINT_ELEMENT,
    DDL_PAGE_DELETE_CHECKPOINT_SEARCH,
    `CREATE INDEX IF NOT EXISTS idx_page_delete_checkpoint_page
      ON page_delete_checkpoint(note_id, page_id, created_time)`,
  ],
  17: [
    DDL_HISTORY_CHECKPOINT,
    DDL_HISTORY_CHECKPOINT_ACTION,
    DDL_HISTORY_CHECKPOINT_OPERATION,
  ],
  18: [
    DDL_LOCAL_EDITOR_IDENTITY,
    `INSERT OR IGNORE INTO local_editor_identity(singleton, editor_id)
      VALUES (1, lower(hex(randomblob(16))))`,
    DDL_NOTE_SYNC_METADATA_V18,
    `INSERT OR IGNORE INTO note_sync_metadata
      (note_id, editor_site_id, editor_id, creator_id, created_at, updated_at,
       synced_op_count, max_op_timestamp, schema_version, uploaded_through_sequence,
       acked_through_sequence)
      SELECT note.id, 0, identity.editor_id, identity.editor_id, note.created_at, note.updated_at,
        0, COALESCE(MAX(log.sequence), 0), 1, 0, 0
      FROM note_meta note CROSS JOIN local_editor_identity identity
      LEFT JOIN operation_log log ON log.note_id = note.id
      GROUP BY note.id`,
    DDL_OPERATION_LOG_V18,
    `INSERT INTO operation_log_v18
      (sequence, note_id, op_id, op_type, payload, client_time, op_timestamp,
       editor_site_id, upload_immediately, action_id, history_effect, coalesce_track, action_time)
      SELECT sequence, note_id, op_id, op_type, payload, client_time, sequence,
        0, 0, action_id, history_effect, coalesce_track, action_time
      FROM operation_log ORDER BY sequence`,
    'DROP TABLE operation_log',
    'ALTER TABLE operation_log_v18 RENAME TO operation_log',
  ],
  19: [
    DDL_NOTE_SYNC_METADATA_V19,
    `INSERT INTO note_sync_metadata_v19
      (note_id, legacy_id, editor_site_id, editor_id, creator_id, created_at, updated_at,
       max_server_time, synced_op_count, max_op_timestamp, schema_version,
       uploaded_through_sequence, acked_through_sequence)
      SELECT note_id, legacy_id, editor_site_id, editor_id, creator_id, created_at, updated_at,
        CASE WHEN max_server_time IS NULL THEN NULL ELSE CAST(max_server_time AS TEXT) END,
        synced_op_count, max_op_timestamp, schema_version,
        uploaded_through_sequence, acked_through_sequence
      FROM note_sync_metadata`,
    'DROP TABLE note_sync_metadata',
    'ALTER TABLE note_sync_metadata_v19 RENAME TO note_sync_metadata',
  ],
  20: [
    DDL_SYNCED_OPERATION_INBOX,
    DDL_DEFERRED_SYNCED_OPERATION_BUNDLE,
  ],
  21: [
    `DELETE FROM deferred_synced_operation_bundle
      WHERE table_type NOT IN ('NOTE_BUNDLE', 'OPS_BUNDLE', 'RECEIVE_OPS_EVENT')`,
    DDL_DEFERRED_SYNCED_OPERATION_BUNDLE_V21,
    `INSERT INTO deferred_synced_operation_bundle_v21
      (id, note_id, schema_version, table_type, payload, payload_size, checksum, received_at)
      SELECT id, note_id, schema_version, table_type, payload, payload_size, checksum, received_at
      FROM deferred_synced_operation_bundle`,
    'DROP TABLE deferred_synced_operation_bundle',
    `ALTER TABLE deferred_synced_operation_bundle_v21
      RENAME TO deferred_synced_operation_bundle`,
    `CREATE INDEX IF NOT EXISTS idx_deferred_synced_bundle_note
      ON deferred_synced_operation_bundle(note_id, id)`,
  ],
  22: [
    DDL_ORIGINAL_PAGE_INSERT_GROUP,
    DDL_ORIGINAL_PAGE_IDENTITY,
    `CREATE INDEX IF NOT EXISTS idx_original_page_group_parent
      ON original_page_insert_group(note_id, parent_timestamp, parent_site_id, parent_index)`,
    `CREATE INDEX IF NOT EXISTS idx_original_page_identity_page
      ON original_page_identity(note_id, page_id)`,
  ],
  23: [
    DDL_ORIGINAL_PAGE_POSITION_GROUP,
    DDL_ORIGINAL_PAGE_POSITION,
    DDL_ORIGINAL_PAGE_POSITION_WINNER,
    `INSERT INTO original_page_position_group
      (note_id, op_timestamp, op_site_id, parent_timestamp, parent_site_id, parent_index,
       position_count, modified_time)
      SELECT note_id, op_timestamp, op_site_id, parent_timestamp, parent_site_id, parent_index,
        page_count, modified_time FROM original_page_insert_group`,
    `INSERT INTO original_page_position
      (note_id, pos_timestamp, pos_site_id, pos_index,
       page_timestamp, page_site_id, page_index)
      SELECT note_id, seq_timestamp, seq_site_id, seq_index,
        seq_timestamp, seq_site_id, seq_index FROM original_page_identity`,
    `INSERT INTO original_page_position_winner
      (note_id, page_timestamp, page_site_id, page_index,
       winner_timestamp, winner_site_id, position_index)
      SELECT note_id, seq_timestamp, seq_site_id, seq_index,
        seq_timestamp, seq_site_id, seq_index FROM original_page_identity`,
    `CREATE INDEX IF NOT EXISTS idx_original_page_position_parent
      ON original_page_position_group(note_id, parent_timestamp, parent_site_id, parent_index)`,
    `CREATE INDEX IF NOT EXISTS idx_original_page_position_value
      ON original_page_position(note_id, page_timestamp, page_site_id, page_index)`,
  ],
};
