// T-007 数据库 DDL 契约（契约 phase-1-data-model.md §3.10，照搬，禁止修改签名）
// 只定义 DDL 字符串常量，不 import relationalStore（实际数据库初始化在 Phase 2 实现）
// 不 import 任何 @ohos.* / @kit.* 平台模块

// 数据库版本
// v36: preserve the original MODIFY_BLOCK common LWW registers.
export const DB_VERSION: number = 36;
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

export const DDL_ORIGINAL_PAGE_VISIBILITY_WINNER: string = `
CREATE TABLE IF NOT EXISTS original_page_visibility_winner (
  note_id TEXT NOT NULL,
  page_timestamp INTEGER NOT NULL CHECK (page_timestamp BETWEEN 0 AND 4294967295),
  page_site_id INTEGER NOT NULL CHECK (page_site_id BETWEEN 0 AND 65535),
  page_index INTEGER NOT NULL CHECK (page_index BETWEEN 0 AND 4294967295),
  winner_timestamp INTEGER NOT NULL CHECK (winner_timestamp BETWEEN 0 AND 4294967295),
  winner_site_id INTEGER NOT NULL CHECK (winner_site_id BETWEEN 0 AND 65535),
  deleted INTEGER NOT NULL CHECK (deleted IN (0, 1)),
  PRIMARY KEY(note_id, page_timestamp, page_site_id, page_index),
  FOREIGN KEY(note_id, page_timestamp, page_site_id, page_index)
    REFERENCES original_page_identity(note_id, seq_timestamp, seq_site_id, seq_index) ON DELETE CASCADE,
  FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE
)`;

export const DDL_ORIGINAL_PAGE_BACKGROUND_WINNER: string = `
CREATE TABLE IF NOT EXISTS original_page_background_winner (
  note_id TEXT NOT NULL,
  page_timestamp INTEGER NOT NULL CHECK (page_timestamp BETWEEN 0 AND 4294967295),
  page_site_id INTEGER NOT NULL CHECK (page_site_id BETWEEN 0 AND 65535),
  page_index INTEGER NOT NULL CHECK (page_index BETWEEN 0 AND 4294967295),
  winner_timestamp INTEGER NOT NULL CHECK (winner_timestamp BETWEEN 0 AND 4294967295),
  winner_site_id INTEGER NOT NULL CHECK (winner_site_id BETWEEN 0 AND 65535),
  size INTEGER NOT NULL,
  template INTEGER NOT NULL,
  orientation INTEGER NOT NULL,
  width_mm REAL NOT NULL CHECK (width_mm > 0),
  height_mm REAL NOT NULL CHECK (height_mm > 0),
  background_json TEXT NOT NULL CHECK (length(background_json) > 0),
  PRIMARY KEY(note_id, page_timestamp, page_site_id, page_index),
  FOREIGN KEY(note_id, page_timestamp, page_site_id, page_index)
    REFERENCES original_page_identity(note_id, seq_timestamp, seq_site_id, seq_index) ON DELETE CASCADE,
  FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE
)`;

export const DDL_ORIGINAL_DELETED_PAGE: string = `
CREATE TABLE IF NOT EXISTS original_deleted_page (
  note_id TEXT NOT NULL,
  page_timestamp INTEGER NOT NULL CHECK (page_timestamp BETWEEN 0 AND 4294967295),
  page_site_id INTEGER NOT NULL CHECK (page_site_id BETWEEN 0 AND 65535),
  page_index INTEGER NOT NULL CHECK (page_index BETWEEN 0 AND 4294967295),
  page_id TEXT NOT NULL CHECK (length(page_id) > 0),
  size INTEGER NOT NULL,
  template INTEGER NOT NULL,
  orientation INTEGER NOT NULL,
  width_mm REAL NOT NULL,
  height_mm REAL NOT NULL,
  background_json TEXT,
  content_revision INTEGER NOT NULL CHECK (content_revision >= 0),
  indexed_revision INTEGER CHECK (indexed_revision IS NULL OR
    (indexed_revision >= 0 AND indexed_revision <= content_revision)),
  PRIMARY KEY(note_id, page_timestamp, page_site_id, page_index),
  UNIQUE(note_id, page_id),
  FOREIGN KEY(note_id, page_timestamp, page_site_id, page_index)
    REFERENCES original_page_identity(note_id, seq_timestamp, seq_site_id, seq_index) ON DELETE CASCADE,
  FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE
)`;

export const DDL_ORIGINAL_DELETED_PAGE_ELEMENT: string = `
CREATE TABLE IF NOT EXISTS original_deleted_page_element (
  note_id TEXT NOT NULL,
  page_timestamp INTEGER NOT NULL,
  page_site_id INTEGER NOT NULL,
  page_index INTEGER NOT NULL,
  element_id TEXT NOT NULL,
  kind INTEGER NOT NULL,
  payload BLOB NOT NULL,
  revision INTEGER NOT NULL CHECK (revision >= 0),
  element_order INTEGER NOT NULL CHECK (element_order >= 0),
  PRIMARY KEY(note_id, page_timestamp, page_site_id, page_index, element_id, kind),
  FOREIGN KEY(note_id, page_timestamp, page_site_id, page_index)
    REFERENCES original_deleted_page(note_id, page_timestamp, page_site_id, page_index) ON DELETE CASCADE
)`;

export const DDL_ORIGINAL_DELETED_PAGE_SEARCH: string = `
CREATE TABLE IF NOT EXISTS original_deleted_page_search (
  note_id TEXT NOT NULL,
  page_timestamp INTEGER NOT NULL,
  page_site_id INTEGER NOT NULL,
  page_index INTEGER NOT NULL,
  type INTEGER NOT NULL,
  sub_id TEXT NOT NULL CHECK (length(sub_id) > 0),
  folded_text TEXT NOT NULL,
  rects BLOB,
  PRIMARY KEY(note_id, page_timestamp, page_site_id, page_index, type, sub_id),
  FOREIGN KEY(note_id, page_timestamp, page_site_id, page_index)
    REFERENCES original_deleted_page(note_id, page_timestamp, page_site_id, page_index) ON DELETE CASCADE
)`;

export const DDL_ORIGINAL_ELEMENT_Z_INDEX: string = `
CREATE TABLE IF NOT EXISTS original_element_z_index (
  note_id TEXT NOT NULL,
  element_timestamp INTEGER NOT NULL CHECK (element_timestamp BETWEEN 0 AND 4294967295),
  element_site_id INTEGER NOT NULL CHECK (element_site_id BETWEEN 0 AND 65535),
  page_timestamp INTEGER NOT NULL CHECK (page_timestamp BETWEEN 0 AND 4294967295),
  page_site_id INTEGER NOT NULL CHECK (page_site_id BETWEEN 0 AND 65535),
  page_index INTEGER NOT NULL CHECK (page_index BETWEEN 0 AND 4294967295),
  kind INTEGER NOT NULL CHECK (kind BETWEEN 1 AND 3),
  z_index TEXT NOT NULL CHECK (
    typeof(z_index) = 'text' AND length(z_index) BETWEEN 1 AND 20
    AND z_index NOT GLOB '*[^0-9]*'
    AND (z_index = '0' OR substr(z_index, 1, 1) <> '0')
    AND (length(z_index) < 20 OR z_index <= '18446744073709551615')
  ),
  PRIMARY KEY(note_id, element_timestamp, element_site_id),
  FOREIGN KEY(note_id, page_timestamp, page_site_id, page_index)
    REFERENCES original_page_identity(note_id, seq_timestamp, seq_site_id, seq_index) ON DELETE CASCADE,
  FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE
)`;

const DDL_ORIGINAL_INK_STATE_V27: string = `
CREATE TABLE IF NOT EXISTS original_ink_state (
  note_id TEXT NOT NULL,
  ink_timestamp INTEGER NOT NULL CHECK (ink_timestamp BETWEEN 0 AND 4294967295),
  ink_site_id INTEGER NOT NULL CHECK (ink_site_id BETWEEN 0 AND 65535),
  base_center_path BLOB NOT NULL CHECK (length(base_center_path) BETWEEN 3 AND 16777216),
  PRIMARY KEY(note_id, ink_timestamp, ink_site_id),
  FOREIGN KEY(note_id, ink_timestamp, ink_site_id)
    REFERENCES original_element_z_index(note_id, element_timestamp, element_site_id) ON DELETE CASCADE
)`;

export const DDL_ORIGINAL_INK_STATE: string = `
CREATE TABLE IF NOT EXISTS original_ink_state (
  note_id TEXT NOT NULL,
  ink_timestamp INTEGER NOT NULL CHECK (ink_timestamp BETWEEN 0 AND 4294967295),
  ink_site_id INTEGER NOT NULL CHECK (ink_site_id BETWEEN 0 AND 65535),
  base_center_path BLOB NOT NULL CHECK (length(base_center_path) BETWEEN 3 AND 16777216),
  center_path_winner_timestamp INTEGER NOT NULL
    CHECK (center_path_winner_timestamp BETWEEN 0 AND 4294967295),
  center_path_winner_site_id INTEGER NOT NULL
    CHECK (center_path_winner_site_id BETWEEN 0 AND 65535),
  center_path_winner_present INTEGER NOT NULL CHECK (center_path_winner_present IN (0, 1)),
  create_custom_path BLOB CHECK (create_custom_path IS NULL OR length(create_custom_path) = 0 OR
    length(create_custom_path) BETWEEN 3 AND 16777216),
  custom_path_value BLOB CHECK (custom_path_value IS NULL OR length(custom_path_value) = 0 OR
    length(custom_path_value) BETWEEN 3 AND 16777216),
  custom_path_winner_timestamp INTEGER NOT NULL
    CHECK (custom_path_winner_timestamp BETWEEN 0 AND 4294967295),
  custom_path_winner_site_id INTEGER NOT NULL
    CHECK (custom_path_winner_site_id BETWEEN 0 AND 65535),
  custom_path_winner_present INTEGER NOT NULL CHECK (custom_path_winner_present IN (0, 1)),
  create_fill_path BLOB CHECK (create_fill_path IS NULL OR length(create_fill_path) = 0 OR
    length(create_fill_path) BETWEEN 3 AND 16777216),
  fill_path_value BLOB CHECK (fill_path_value IS NULL OR length(fill_path_value) = 0 OR
    length(fill_path_value) BETWEEN 3 AND 16777216),
  fill_path_winner_timestamp INTEGER NOT NULL
    CHECK (fill_path_winner_timestamp BETWEEN 0 AND 4294967295),
  fill_path_winner_site_id INTEGER NOT NULL
    CHECK (fill_path_winner_site_id BETWEEN 0 AND 65535),
  fill_path_winner_present INTEGER NOT NULL CHECK (fill_path_winner_present IN (0, 1)),
  create_fill_color INTEGER CHECK (create_fill_color IS NULL OR
    create_fill_color BETWEEN -2147483648 AND 2147483647),
  fill_color_value INTEGER CHECK (fill_color_value IS NULL OR
    fill_color_value BETWEEN -2147483648 AND 2147483647),
  fill_color_winner_timestamp INTEGER NOT NULL
    CHECK (fill_color_winner_timestamp BETWEEN 0 AND 4294967295),
  fill_color_winner_site_id INTEGER NOT NULL
    CHECK (fill_color_winner_site_id BETWEEN 0 AND 65535),
  fill_color_winner_present INTEGER NOT NULL CHECK (fill_color_winner_present IN (0, 1)),
  create_style_map BLOB CHECK (create_style_map IS NULL OR length(create_style_map) = 0 OR
    (length(create_style_map) BETWEEN 20 AND 1310700 AND length(create_style_map) % 20 = 0)),
  style_map_value BLOB CHECK (style_map_value IS NULL OR length(style_map_value) = 0 OR
    (length(style_map_value) BETWEEN 20 AND 1310700 AND length(style_map_value) % 20 = 0)),
  style_map_winner_timestamp INTEGER NOT NULL
    CHECK (style_map_winner_timestamp BETWEEN 0 AND 4294967295),
  style_map_winner_site_id INTEGER NOT NULL
    CHECK (style_map_winner_site_id BETWEEN 0 AND 65535),
  style_map_winner_present INTEGER NOT NULL CHECK (style_map_winner_present IN (0, 1)),
  style_value INTEGER CHECK (style_value IS NULL OR style_value BETWEEN 0 AND 3),
  style_winner_timestamp INTEGER NOT NULL
    CHECK (style_winner_timestamp BETWEEN 0 AND 4294967295),
  style_winner_site_id INTEGER NOT NULL
    CHECK (style_winner_site_id BETWEEN 0 AND 65535),
  style_winner_present INTEGER NOT NULL CHECK (style_winner_present IN (0, 1)),
  color_value INTEGER CHECK (color_value IS NULL OR color_value BETWEEN -2147483648 AND 2147483647),
  color_winner_timestamp INTEGER NOT NULL
    CHECK (color_winner_timestamp BETWEEN 0 AND 4294967295),
  color_winner_site_id INTEGER NOT NULL
    CHECK (color_winner_site_id BETWEEN 0 AND 65535),
  color_winner_present INTEGER NOT NULL CHECK (color_winner_present IN (0, 1)),
  width_value REAL CHECK (width_value IS NULL OR
    width_value BETWEEN -3.4028234663852886e38 AND 3.4028234663852886e38),
  width_winner_timestamp INTEGER NOT NULL
    CHECK (width_winner_timestamp BETWEEN 0 AND 4294967295),
  width_winner_site_id INTEGER NOT NULL
    CHECK (width_winner_site_id BETWEEN 0 AND 65535),
  width_winner_present INTEGER NOT NULL CHECK (width_winner_present IN (0, 1)),
  create_origin_x REAL,
  create_origin_y REAL,
  create_page_timestamp INTEGER CHECK (create_page_timestamp IS NULL OR
    create_page_timestamp BETWEEN 0 AND 4294967295),
  create_page_site_id INTEGER CHECK (create_page_site_id IS NULL OR
    create_page_site_id BETWEEN 0 AND 65535),
  create_page_index INTEGER CHECK (create_page_index IS NULL OR
    create_page_index BETWEEN 0 AND 4294967295),
  create_rotation REAL,
  create_scale_x REAL,
  create_scale_y REAL,
  rotation_value REAL,
  rotation_winner_timestamp INTEGER NOT NULL
    CHECK (rotation_winner_timestamp BETWEEN 0 AND 4294967295),
  rotation_winner_site_id INTEGER NOT NULL
    CHECK (rotation_winner_site_id BETWEEN 0 AND 65535),
  rotation_winner_present INTEGER NOT NULL CHECK (rotation_winner_present IN (0, 1)),
  scale_x_value REAL,
  scale_y_value REAL,
  scale_winner_timestamp INTEGER NOT NULL
    CHECK (scale_winner_timestamp BETWEEN 0 AND 4294967295),
  scale_winner_site_id INTEGER NOT NULL
    CHECK (scale_winner_site_id BETWEEN 0 AND 65535),
  scale_winner_present INTEGER NOT NULL CHECK (scale_winner_present IN (0, 1)),
  page_origin_page_timestamp INTEGER CHECK (page_origin_page_timestamp IS NULL OR
    page_origin_page_timestamp BETWEEN 0 AND 4294967295),
  page_origin_page_site_id INTEGER CHECK (page_origin_page_site_id IS NULL OR
    page_origin_page_site_id BETWEEN 0 AND 65535),
  page_origin_page_index INTEGER CHECK (page_origin_page_index IS NULL OR
    page_origin_page_index BETWEEN 0 AND 4294967295),
  page_origin_x REAL,
  page_origin_y REAL,
  page_origin_winner_timestamp INTEGER NOT NULL
    CHECK (page_origin_winner_timestamp BETWEEN 0 AND 4294967295),
  page_origin_winner_site_id INTEGER NOT NULL
    CHECK (page_origin_winner_site_id BETWEEN 0 AND 65535),
  page_origin_winner_present INTEGER NOT NULL CHECK (page_origin_winner_present IN (0, 1)),
  create_z_index TEXT CHECK (create_z_index IS NULL OR (
    typeof(create_z_index) = 'text' AND length(create_z_index) BETWEEN 1 AND 20
    AND create_z_index NOT GLOB '*[^0-9]*'
    AND (create_z_index = '0' OR substr(create_z_index, 1, 1) <> '0')
    AND (length(create_z_index) < 20 OR create_z_index <= '18446744073709551615'))),
  z_index_value TEXT CHECK (z_index_value IS NULL OR (
    typeof(z_index_value) = 'text' AND length(z_index_value) BETWEEN 1 AND 20
    AND z_index_value NOT GLOB '*[^0-9]*'
    AND (z_index_value = '0' OR substr(z_index_value, 1, 1) <> '0')
    AND (length(z_index_value) < 20 OR z_index_value <= '18446744073709551615'))),
  z_index_winner_timestamp INTEGER NOT NULL
    CHECK (z_index_winner_timestamp BETWEEN 0 AND 4294967295),
  z_index_winner_site_id INTEGER NOT NULL
    CHECK (z_index_winner_site_id BETWEEN 0 AND 65535),
  z_index_winner_present INTEGER NOT NULL CHECK (z_index_winner_present IN (0, 1)),
  CHECK ((create_origin_x IS NULL AND create_origin_y IS NULL AND create_rotation IS NULL
      AND create_scale_x IS NULL AND create_scale_y IS NULL) OR
    (create_origin_x IS NOT NULL AND create_origin_y IS NOT NULL AND create_rotation IS NOT NULL
      AND create_scale_x IS NOT NULL AND create_scale_y IS NOT NULL)),
  CHECK ((create_page_timestamp IS NULL AND create_page_site_id IS NULL
      AND create_page_index IS NULL) OR
    (create_page_timestamp IS NOT NULL AND create_page_site_id IS NOT NULL
      AND create_page_index IS NOT NULL)),
  CHECK ((scale_x_value IS NULL AND scale_y_value IS NULL) OR
    (scale_x_value IS NOT NULL AND scale_y_value IS NOT NULL)),
  CHECK ((page_origin_page_timestamp IS NULL AND page_origin_page_site_id IS NULL
      AND page_origin_page_index IS NULL AND page_origin_x IS NULL AND page_origin_y IS NULL) OR
    (page_origin_page_timestamp IS NOT NULL AND page_origin_page_site_id IS NOT NULL
      AND page_origin_page_index IS NOT NULL AND page_origin_x IS NOT NULL
      AND page_origin_y IS NOT NULL)),
  CHECK ((z_index_winner_present = 0 AND z_index_value IS NULL) OR
    (z_index_winner_present = 1 AND z_index_value IS NOT NULL)),
  PRIMARY KEY(note_id, ink_timestamp, ink_site_id),
  FOREIGN KEY(note_id, ink_timestamp, ink_site_id)
    REFERENCES original_element_z_index(note_id, element_timestamp, element_site_id) ON DELETE CASCADE
)`;

export const DDL_ORIGINAL_INK_PATH_APPEND: string = `
CREATE TABLE IF NOT EXISTS original_ink_path_append (
  note_id TEXT NOT NULL,
  ink_timestamp INTEGER NOT NULL CHECK (ink_timestamp BETWEEN 0 AND 4294967295),
  ink_site_id INTEGER NOT NULL CHECK (ink_site_id BETWEEN 0 AND 65535),
  append_timestamp INTEGER NOT NULL CHECK (append_timestamp BETWEEN 0 AND 4294967295),
  append_site_id INTEGER NOT NULL CHECK (append_site_id BETWEEN 0 AND 65535),
  center_path_elements BLOB NOT NULL CHECK (length(center_path_elements) BETWEEN 3 AND 16777216),
  PRIMARY KEY(note_id, append_timestamp, append_site_id),
  FOREIGN KEY(note_id, ink_timestamp, ink_site_id)
    REFERENCES original_ink_state(note_id, ink_timestamp, ink_site_id) ON DELETE CASCADE
)`;

const DDL_ORIGINAL_BLOCK_STATE_V35: string = `
CREATE TABLE IF NOT EXISTS original_block_state (
  note_id TEXT NOT NULL,
  block_timestamp INTEGER NOT NULL CHECK (block_timestamp BETWEEN 0 AND 4294967295),
  block_site_id INTEGER NOT NULL CHECK (block_site_id BETWEEN 0 AND 65535),
  block_type INTEGER NOT NULL CHECK (block_type BETWEEN 0 AND 2),
  create_page_timestamp INTEGER NOT NULL CHECK (create_page_timestamp BETWEEN 0 AND 4294967295),
  create_page_site_id INTEGER NOT NULL CHECK (create_page_site_id BETWEEN 0 AND 65535),
  create_page_index INTEGER NOT NULL CHECK (create_page_index BETWEEN 0 AND 4294967295),
  create_origin_x REAL NOT NULL,
  create_origin_y REAL NOT NULL,
  create_rotation REAL,
  create_scale_x REAL,
  create_scale_y REAL,
  create_width REAL NOT NULL CHECK (create_width >= 0),
  create_height REAL NOT NULL CHECK (create_height >= 0),
  create_corner INTEGER NOT NULL CHECK (create_corner BETWEEN 0 AND 1),
  create_text_wrap INTEGER NOT NULL CHECK (create_text_wrap BETWEEN 0 AND 1),
  create_enable_caption INTEGER NOT NULL CHECK (create_enable_caption IN (0, 1)),
  create_position_locked INTEGER NOT NULL CHECK (create_position_locked IN (0, 1)),
  create_resizes_width INTEGER NOT NULL CHECK (create_resizes_width IN (0, 1)),
  create_margin_top REAL NOT NULL CHECK (create_margin_top >= 0),
  create_margin_bottom REAL NOT NULL CHECK (create_margin_bottom >= 0),
  create_margin_left REAL NOT NULL CHECK (create_margin_left >= 0),
  create_margin_right REAL NOT NULL CHECK (create_margin_right >= 0),
  create_z_index TEXT NOT NULL CHECK (
    typeof(create_z_index) = 'text' AND length(create_z_index) BETWEEN 1 AND 20
    AND create_z_index NOT GLOB '*[^0-9]*'
    AND (create_z_index = '0' OR substr(create_z_index, 1, 1) <> '0')
    AND (length(create_z_index) < 20 OR create_z_index <= '18446744073709551615')
  ),
  CHECK ((create_scale_x IS NULL AND create_scale_y IS NULL) OR
    (create_scale_x IS NOT NULL AND create_scale_y IS NOT NULL)),
  PRIMARY KEY(note_id, block_timestamp, block_site_id),
  FOREIGN KEY(note_id, block_timestamp, block_site_id)
    REFERENCES original_element_z_index(note_id, element_timestamp, element_site_id) ON DELETE CASCADE
)`;

export const DDL_ORIGINAL_BLOCK_STATE: string = `
CREATE TABLE IF NOT EXISTS original_block_state (
  note_id TEXT NOT NULL,
  block_timestamp INTEGER NOT NULL CHECK (block_timestamp BETWEEN 0 AND 4294967295),
  block_site_id INTEGER NOT NULL CHECK (block_site_id BETWEEN 0 AND 65535),
  block_type INTEGER NOT NULL CHECK (block_type BETWEEN 0 AND 2),
  create_page_timestamp INTEGER NOT NULL CHECK (create_page_timestamp BETWEEN 0 AND 4294967295),
  create_page_site_id INTEGER NOT NULL CHECK (create_page_site_id BETWEEN 0 AND 65535),
  create_page_index INTEGER NOT NULL CHECK (create_page_index BETWEEN 0 AND 4294967295),
  create_origin_x REAL NOT NULL,
  create_origin_y REAL NOT NULL,
  create_rotation REAL,
  create_scale_x REAL,
  create_scale_y REAL,
  create_width REAL NOT NULL CHECK (create_width >= 0),
  create_height REAL NOT NULL CHECK (create_height >= 0),
  create_corner INTEGER NOT NULL CHECK (create_corner BETWEEN 0 AND 1),
  create_text_wrap INTEGER NOT NULL CHECK (create_text_wrap BETWEEN 0 AND 1),
  create_enable_caption INTEGER NOT NULL CHECK (create_enable_caption IN (0, 1)),
  create_position_locked INTEGER NOT NULL CHECK (create_position_locked IN (0, 1)),
  create_resizes_width INTEGER NOT NULL CHECK (create_resizes_width IN (0, 1)),
  create_margin_top REAL NOT NULL CHECK (create_margin_top >= 0),
  create_margin_bottom REAL NOT NULL CHECK (create_margin_bottom >= 0),
  create_margin_left REAL NOT NULL CHECK (create_margin_left >= 0),
  create_margin_right REAL NOT NULL CHECK (create_margin_right >= 0),
  create_z_index TEXT NOT NULL CHECK (
    typeof(create_z_index) = 'text' AND length(create_z_index) BETWEEN 1 AND 20
    AND create_z_index NOT GLOB '*[^0-9]*'
    AND (create_z_index = '0' OR substr(create_z_index, 1, 1) <> '0')
    AND (length(create_z_index) < 20 OR create_z_index <= '18446744073709551615')
  ),
  page_origin_page_timestamp INTEGER,
  page_origin_page_site_id INTEGER,
  page_origin_page_index INTEGER,
  page_origin_x REAL,
  page_origin_y REAL,
  page_origin_winner_timestamp INTEGER,
  page_origin_winner_site_id INTEGER,
  page_origin_winner_present INTEGER NOT NULL DEFAULT 0 CHECK (page_origin_winner_present IN (0, 1)),
  rotation_value REAL,
  rotation_winner_timestamp INTEGER,
  rotation_winner_site_id INTEGER,
  rotation_winner_present INTEGER NOT NULL DEFAULT 0 CHECK (rotation_winner_present IN (0, 1)),
  scale_x_value REAL,
  scale_y_value REAL,
  scale_winner_timestamp INTEGER,
  scale_winner_site_id INTEGER,
  scale_winner_present INTEGER NOT NULL DEFAULT 0 CHECK (scale_winner_present IN (0, 1)),
  size_width_value REAL,
  size_height_value REAL,
  size_winner_timestamp INTEGER,
  size_winner_site_id INTEGER,
  size_winner_present INTEGER NOT NULL DEFAULT 0 CHECK (size_winner_present IN (0, 1)),
  corner_value INTEGER,
  corner_winner_timestamp INTEGER,
  corner_winner_site_id INTEGER,
  corner_winner_present INTEGER NOT NULL DEFAULT 0 CHECK (corner_winner_present IN (0, 1)),
  text_wrap_value INTEGER,
  text_wrap_winner_timestamp INTEGER,
  text_wrap_winner_site_id INTEGER,
  text_wrap_winner_present INTEGER NOT NULL DEFAULT 0 CHECK (text_wrap_winner_present IN (0, 1)),
  enable_caption_value INTEGER,
  enable_caption_winner_timestamp INTEGER,
  enable_caption_winner_site_id INTEGER,
  enable_caption_winner_present INTEGER NOT NULL DEFAULT 0 CHECK (enable_caption_winner_present IN (0, 1)),
  position_locked_value INTEGER,
  position_locked_winner_timestamp INTEGER,
  position_locked_winner_site_id INTEGER,
  position_locked_winner_present INTEGER NOT NULL DEFAULT 0 CHECK (position_locked_winner_present IN (0, 1)),
  z_index_value TEXT,
  z_index_winner_timestamp INTEGER,
  z_index_winner_site_id INTEGER,
  z_index_winner_present INTEGER NOT NULL DEFAULT 0 CHECK (z_index_winner_present IN (0, 1)),
  CHECK ((create_scale_x IS NULL AND create_scale_y IS NULL) OR
    (create_scale_x IS NOT NULL AND create_scale_y IS NOT NULL)),
  CHECK ((scale_x_value IS NULL AND scale_y_value IS NULL) OR
    (scale_x_value IS NOT NULL AND scale_y_value IS NOT NULL)),
  PRIMARY KEY(note_id, block_timestamp, block_site_id),
  FOREIGN KEY(note_id, block_timestamp, block_site_id)
    REFERENCES original_element_z_index(note_id, element_timestamp, element_site_id) ON DELETE CASCADE
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
  background_json TEXT,
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
  background_json TEXT,
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
  `CREATE INDEX IF NOT EXISTS idx_original_element_page_z
    ON original_element_z_index(note_id, page_timestamp, page_site_id, page_index,
      length(z_index), z_index, element_timestamp, element_site_id)`,
  `CREATE INDEX IF NOT EXISTS idx_original_ink_append_target
    ON original_ink_path_append(note_id, ink_timestamp, ink_site_id,
      append_timestamp, append_site_id)`,
  `CREATE INDEX IF NOT EXISTS idx_original_page_position_parent
    ON original_page_position_group(note_id, parent_timestamp, parent_site_id, parent_index)`,
  `CREATE INDEX IF NOT EXISTS idx_original_page_position_value
    ON original_page_position(note_id, page_timestamp, page_site_id, page_index)`,
  `CREATE INDEX IF NOT EXISTS idx_original_deleted_page_storage
    ON original_deleted_page(note_id, page_id)`,
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
  24: [
    DDL_ORIGINAL_PAGE_VISIBILITY_WINNER,
    DDL_ORIGINAL_DELETED_PAGE,
    DDL_ORIGINAL_DELETED_PAGE_ELEMENT,
    DDL_ORIGINAL_DELETED_PAGE_SEARCH,
    `CREATE INDEX IF NOT EXISTS idx_original_deleted_page_storage
      ON original_deleted_page(note_id, page_id)`,
  ],
  25: [
    'ALTER TABLE page_info ADD COLUMN background_json TEXT',
    'ALTER TABLE page_delete_checkpoint ADD COLUMN background_json TEXT',
    'ALTER TABLE original_deleted_page ADD COLUMN background_json TEXT',
    DDL_ORIGINAL_PAGE_BACKGROUND_WINNER,
  ],
  26: [
    DDL_ORIGINAL_ELEMENT_Z_INDEX,
    `CREATE INDEX IF NOT EXISTS idx_original_element_page_z
      ON original_element_z_index(note_id, page_timestamp, page_site_id, page_index,
        length(z_index), z_index, element_timestamp, element_site_id)`,
  ],
  27: [
    DDL_ORIGINAL_INK_STATE_V27,
    DDL_ORIGINAL_INK_PATH_APPEND,
    `CREATE INDEX IF NOT EXISTS idx_original_ink_append_target
      ON original_ink_path_append(note_id, ink_timestamp, ink_site_id,
        append_timestamp, append_site_id)`,
  ],
  28: [
    `ALTER TABLE original_ink_state ADD COLUMN center_path_winner_timestamp INTEGER NOT NULL
      DEFAULT 0 CHECK (center_path_winner_timestamp BETWEEN 0 AND 4294967295)`,
    `ALTER TABLE original_ink_state ADD COLUMN center_path_winner_site_id INTEGER NOT NULL
      DEFAULT 0 CHECK (center_path_winner_site_id BETWEEN 0 AND 65535)`,
    `UPDATE original_ink_state SET center_path_winner_timestamp = ink_timestamp,
      center_path_winner_site_id = ink_site_id`,
  ],
  29: [
    `ALTER TABLE original_ink_state ADD COLUMN style_value INTEGER
      CHECK (style_value IS NULL OR style_value BETWEEN 0 AND 3)`,
    `ALTER TABLE original_ink_state ADD COLUMN style_winner_timestamp INTEGER NOT NULL
      DEFAULT 0 CHECK (style_winner_timestamp BETWEEN 0 AND 4294967295)`,
    `ALTER TABLE original_ink_state ADD COLUMN style_winner_site_id INTEGER NOT NULL
      DEFAULT 0 CHECK (style_winner_site_id BETWEEN 0 AND 65535)`,
    `ALTER TABLE original_ink_state ADD COLUMN color_value INTEGER
      CHECK (color_value IS NULL OR color_value BETWEEN -2147483648 AND 2147483647)`,
    `ALTER TABLE original_ink_state ADD COLUMN color_winner_timestamp INTEGER NOT NULL
      DEFAULT 0 CHECK (color_winner_timestamp BETWEEN 0 AND 4294967295)`,
    `ALTER TABLE original_ink_state ADD COLUMN color_winner_site_id INTEGER NOT NULL
      DEFAULT 0 CHECK (color_winner_site_id BETWEEN 0 AND 65535)`,
    `ALTER TABLE original_ink_state ADD COLUMN width_value REAL CHECK (width_value IS NULL OR
      width_value BETWEEN -3.4028234663852886e38 AND 3.4028234663852886e38)`,
    `ALTER TABLE original_ink_state ADD COLUMN width_winner_timestamp INTEGER NOT NULL
      DEFAULT 0 CHECK (width_winner_timestamp BETWEEN 0 AND 4294967295)`,
    `ALTER TABLE original_ink_state ADD COLUMN width_winner_site_id INTEGER NOT NULL
      DEFAULT 0 CHECK (width_winner_site_id BETWEEN 0 AND 65535)`,
    `UPDATE original_ink_state SET
      style_winner_timestamp = ink_timestamp, style_winner_site_id = ink_site_id,
      color_winner_timestamp = ink_timestamp, color_winner_site_id = ink_site_id,
      width_winner_timestamp = ink_timestamp, width_winner_site_id = ink_site_id`,
  ],
  30: [
    `ALTER TABLE original_ink_state ADD COLUMN center_path_winner_present INTEGER NOT NULL
      DEFAULT 0 CHECK (center_path_winner_present IN (0, 1))`,
    `ALTER TABLE original_ink_state ADD COLUMN style_winner_present INTEGER NOT NULL
      DEFAULT 0 CHECK (style_winner_present IN (0, 1))`,
    `ALTER TABLE original_ink_state ADD COLUMN color_winner_present INTEGER NOT NULL
      DEFAULT 0 CHECK (color_winner_present IN (0, 1))`,
    `ALTER TABLE original_ink_state ADD COLUMN width_winner_present INTEGER NOT NULL
      DEFAULT 0 CHECK (width_winner_present IN (0, 1))`,
    `UPDATE original_ink_state SET
      center_path_winner_present = CASE WHEN center_path_winner_timestamp = ink_timestamp
        AND center_path_winner_site_id = ink_site_id THEN 0 ELSE 1 END,
      style_winner_present = CASE WHEN style_winner_timestamp = ink_timestamp
        AND style_winner_site_id = ink_site_id THEN 0 ELSE 1 END,
      color_winner_present = CASE WHEN color_winner_timestamp = ink_timestamp
        AND color_winner_site_id = ink_site_id THEN 0 ELSE 1 END,
      width_winner_present = CASE WHEN width_winner_timestamp = ink_timestamp
        AND width_winner_site_id = ink_site_id THEN 0 ELSE 1 END`,
    'ALTER TABLE original_ink_state ADD COLUMN create_origin_x REAL',
    'ALTER TABLE original_ink_state ADD COLUMN create_origin_y REAL',
    'ALTER TABLE original_ink_state ADD COLUMN create_rotation REAL',
    'ALTER TABLE original_ink_state ADD COLUMN create_scale_x REAL',
    'ALTER TABLE original_ink_state ADD COLUMN create_scale_y REAL',
    'ALTER TABLE original_ink_state ADD COLUMN rotation_value REAL',
    `ALTER TABLE original_ink_state ADD COLUMN rotation_winner_timestamp INTEGER NOT NULL
      DEFAULT 0 CHECK (rotation_winner_timestamp BETWEEN 0 AND 4294967295)`,
    `ALTER TABLE original_ink_state ADD COLUMN rotation_winner_site_id INTEGER NOT NULL
      DEFAULT 0 CHECK (rotation_winner_site_id BETWEEN 0 AND 65535)`,
    `ALTER TABLE original_ink_state ADD COLUMN rotation_winner_present INTEGER NOT NULL
      DEFAULT 0 CHECK (rotation_winner_present IN (0, 1))`,
    'ALTER TABLE original_ink_state ADD COLUMN scale_x_value REAL',
    'ALTER TABLE original_ink_state ADD COLUMN scale_y_value REAL',
    `ALTER TABLE original_ink_state ADD COLUMN scale_winner_timestamp INTEGER NOT NULL
      DEFAULT 0 CHECK (scale_winner_timestamp BETWEEN 0 AND 4294967295)`,
    `ALTER TABLE original_ink_state ADD COLUMN scale_winner_site_id INTEGER NOT NULL
      DEFAULT 0 CHECK (scale_winner_site_id BETWEEN 0 AND 65535)`,
    `ALTER TABLE original_ink_state ADD COLUMN scale_winner_present INTEGER NOT NULL
      DEFAULT 0 CHECK (scale_winner_present IN (0, 1))`,
  ],
  31: [
    `ALTER TABLE original_ink_state ADD COLUMN create_page_timestamp INTEGER
      CHECK (create_page_timestamp IS NULL OR create_page_timestamp BETWEEN 0 AND 4294967295)`,
    `ALTER TABLE original_ink_state ADD COLUMN create_page_site_id INTEGER
      CHECK (create_page_site_id IS NULL OR create_page_site_id BETWEEN 0 AND 65535)`,
    `ALTER TABLE original_ink_state ADD COLUMN create_page_index INTEGER
      CHECK (create_page_index IS NULL OR create_page_index BETWEEN 0 AND 4294967295)`,
    `ALTER TABLE original_ink_state ADD COLUMN page_origin_page_timestamp INTEGER
      CHECK (page_origin_page_timestamp IS NULL OR
        page_origin_page_timestamp BETWEEN 0 AND 4294967295)`,
    `ALTER TABLE original_ink_state ADD COLUMN page_origin_page_site_id INTEGER
      CHECK (page_origin_page_site_id IS NULL OR page_origin_page_site_id BETWEEN 0 AND 65535)`,
    `ALTER TABLE original_ink_state ADD COLUMN page_origin_page_index INTEGER
      CHECK (page_origin_page_index IS NULL OR page_origin_page_index BETWEEN 0 AND 4294967295)`,
    'ALTER TABLE original_ink_state ADD COLUMN page_origin_x REAL',
    'ALTER TABLE original_ink_state ADD COLUMN page_origin_y REAL',
    `ALTER TABLE original_ink_state ADD COLUMN page_origin_winner_timestamp INTEGER NOT NULL
      DEFAULT 0 CHECK (page_origin_winner_timestamp BETWEEN 0 AND 4294967295)`,
    `ALTER TABLE original_ink_state ADD COLUMN page_origin_winner_site_id INTEGER NOT NULL
      DEFAULT 0 CHECK (page_origin_winner_site_id BETWEEN 0 AND 65535)`,
    `ALTER TABLE original_ink_state ADD COLUMN page_origin_winner_present INTEGER NOT NULL
      DEFAULT 0 CHECK (page_origin_winner_present IN (0, 1))`,
  ],
  32: [
    `ALTER TABLE original_ink_state ADD COLUMN create_z_index TEXT CHECK (create_z_index IS NULL OR (
      typeof(create_z_index) = 'text' AND length(create_z_index) BETWEEN 1 AND 20
      AND create_z_index NOT GLOB '*[^0-9]*'
      AND (create_z_index = '0' OR substr(create_z_index, 1, 1) <> '0')
      AND (length(create_z_index) < 20 OR create_z_index <= '18446744073709551615')))`,
    `ALTER TABLE original_ink_state ADD COLUMN z_index_value TEXT CHECK (z_index_value IS NULL OR (
      typeof(z_index_value) = 'text' AND length(z_index_value) BETWEEN 1 AND 20
      AND z_index_value NOT GLOB '*[^0-9]*'
      AND (z_index_value = '0' OR substr(z_index_value, 1, 1) <> '0')
      AND (length(z_index_value) < 20 OR z_index_value <= '18446744073709551615')))`,
    `ALTER TABLE original_ink_state ADD COLUMN z_index_winner_timestamp INTEGER NOT NULL
      DEFAULT 0 CHECK (z_index_winner_timestamp BETWEEN 0 AND 4294967295)`,
    `ALTER TABLE original_ink_state ADD COLUMN z_index_winner_site_id INTEGER NOT NULL
      DEFAULT 0 CHECK (z_index_winner_site_id BETWEEN 0 AND 65535)`,
    `ALTER TABLE original_ink_state ADD COLUMN z_index_winner_present INTEGER NOT NULL
      DEFAULT 0 CHECK (z_index_winner_present IN (0, 1))`,
  ],
  33: [
    `ALTER TABLE original_ink_state ADD COLUMN create_custom_path BLOB
      CHECK (create_custom_path IS NULL OR length(create_custom_path) = 0 OR
        length(create_custom_path) BETWEEN 3 AND 16777216)`,
    `ALTER TABLE original_ink_state ADD COLUMN custom_path_value BLOB
      CHECK (custom_path_value IS NULL OR length(custom_path_value) = 0 OR
        length(custom_path_value) BETWEEN 3 AND 16777216)`,
    `ALTER TABLE original_ink_state ADD COLUMN custom_path_winner_timestamp INTEGER NOT NULL
      DEFAULT 0 CHECK (custom_path_winner_timestamp BETWEEN 0 AND 4294967295)`,
    `ALTER TABLE original_ink_state ADD COLUMN custom_path_winner_site_id INTEGER NOT NULL
      DEFAULT 0 CHECK (custom_path_winner_site_id BETWEEN 0 AND 65535)`,
    `ALTER TABLE original_ink_state ADD COLUMN custom_path_winner_present INTEGER NOT NULL
      DEFAULT 0 CHECK (custom_path_winner_present IN (0, 1))`,
    `ALTER TABLE original_ink_state ADD COLUMN create_fill_path BLOB
      CHECK (create_fill_path IS NULL OR length(create_fill_path) = 0 OR
        length(create_fill_path) BETWEEN 3 AND 16777216)`,
    `ALTER TABLE original_ink_state ADD COLUMN fill_path_value BLOB
      CHECK (fill_path_value IS NULL OR length(fill_path_value) = 0 OR
        length(fill_path_value) BETWEEN 3 AND 16777216)`,
    `ALTER TABLE original_ink_state ADD COLUMN fill_path_winner_timestamp INTEGER NOT NULL
      DEFAULT 0 CHECK (fill_path_winner_timestamp BETWEEN 0 AND 4294967295)`,
    `ALTER TABLE original_ink_state ADD COLUMN fill_path_winner_site_id INTEGER NOT NULL
      DEFAULT 0 CHECK (fill_path_winner_site_id BETWEEN 0 AND 65535)`,
    `ALTER TABLE original_ink_state ADD COLUMN fill_path_winner_present INTEGER NOT NULL
      DEFAULT 0 CHECK (fill_path_winner_present IN (0, 1))`,
    `ALTER TABLE original_ink_state ADD COLUMN create_fill_color INTEGER
      CHECK (create_fill_color IS NULL OR create_fill_color BETWEEN -2147483648 AND 2147483647)`,
    `ALTER TABLE original_ink_state ADD COLUMN fill_color_value INTEGER
      CHECK (fill_color_value IS NULL OR fill_color_value BETWEEN -2147483648 AND 2147483647)`,
    `ALTER TABLE original_ink_state ADD COLUMN fill_color_winner_timestamp INTEGER NOT NULL
      DEFAULT 0 CHECK (fill_color_winner_timestamp BETWEEN 0 AND 4294967295)`,
    `ALTER TABLE original_ink_state ADD COLUMN fill_color_winner_site_id INTEGER NOT NULL
      DEFAULT 0 CHECK (fill_color_winner_site_id BETWEEN 0 AND 65535)`,
    `ALTER TABLE original_ink_state ADD COLUMN fill_color_winner_present INTEGER NOT NULL
      DEFAULT 0 CHECK (fill_color_winner_present IN (0, 1))`,
  ],
  34: [
    `ALTER TABLE original_ink_state ADD COLUMN create_style_map BLOB
      CHECK (create_style_map IS NULL OR length(create_style_map) = 0 OR
        (length(create_style_map) BETWEEN 20 AND 1310700 AND length(create_style_map) % 20 = 0))`,
    `ALTER TABLE original_ink_state ADD COLUMN style_map_value BLOB
      CHECK (style_map_value IS NULL OR length(style_map_value) = 0 OR
        (length(style_map_value) BETWEEN 20 AND 1310700 AND length(style_map_value) % 20 = 0))`,
    `ALTER TABLE original_ink_state ADD COLUMN style_map_winner_timestamp INTEGER NOT NULL
      DEFAULT 0 CHECK (style_map_winner_timestamp BETWEEN 0 AND 4294967295)`,
    `ALTER TABLE original_ink_state ADD COLUMN style_map_winner_site_id INTEGER NOT NULL
      DEFAULT 0 CHECK (style_map_winner_site_id BETWEEN 0 AND 65535)`,
    `ALTER TABLE original_ink_state ADD COLUMN style_map_winner_present INTEGER NOT NULL
      DEFAULT 0 CHECK (style_map_winner_present IN (0, 1))`,
  ],
  35: [DDL_ORIGINAL_BLOCK_STATE_V35],
  36: [
    `ALTER TABLE original_block_state ADD COLUMN page_origin_page_timestamp INTEGER`,
    `ALTER TABLE original_block_state ADD COLUMN page_origin_page_site_id INTEGER`,
    `ALTER TABLE original_block_state ADD COLUMN page_origin_page_index INTEGER`,
    `ALTER TABLE original_block_state ADD COLUMN page_origin_x REAL`,
    `ALTER TABLE original_block_state ADD COLUMN page_origin_y REAL`,
    `ALTER TABLE original_block_state ADD COLUMN page_origin_winner_timestamp INTEGER`,
    `ALTER TABLE original_block_state ADD COLUMN page_origin_winner_site_id INTEGER`,
    `ALTER TABLE original_block_state ADD COLUMN page_origin_winner_present INTEGER NOT NULL DEFAULT 0
      CHECK (page_origin_winner_present IN (0, 1))`,
    `ALTER TABLE original_block_state ADD COLUMN rotation_value REAL`,
    `ALTER TABLE original_block_state ADD COLUMN rotation_winner_timestamp INTEGER`,
    `ALTER TABLE original_block_state ADD COLUMN rotation_winner_site_id INTEGER`,
    `ALTER TABLE original_block_state ADD COLUMN rotation_winner_present INTEGER NOT NULL DEFAULT 0
      CHECK (rotation_winner_present IN (0, 1))`,
    `ALTER TABLE original_block_state ADD COLUMN scale_x_value REAL`,
    `ALTER TABLE original_block_state ADD COLUMN scale_y_value REAL`,
    `ALTER TABLE original_block_state ADD COLUMN scale_winner_timestamp INTEGER`,
    `ALTER TABLE original_block_state ADD COLUMN scale_winner_site_id INTEGER`,
    `ALTER TABLE original_block_state ADD COLUMN scale_winner_present INTEGER NOT NULL DEFAULT 0
      CHECK (scale_winner_present IN (0, 1))`,
    `ALTER TABLE original_block_state ADD COLUMN size_width_value REAL`,
    `ALTER TABLE original_block_state ADD COLUMN size_height_value REAL`,
    `ALTER TABLE original_block_state ADD COLUMN size_winner_timestamp INTEGER`,
    `ALTER TABLE original_block_state ADD COLUMN size_winner_site_id INTEGER`,
    `ALTER TABLE original_block_state ADD COLUMN size_winner_present INTEGER NOT NULL DEFAULT 0
      CHECK (size_winner_present IN (0, 1))`,
    `ALTER TABLE original_block_state ADD COLUMN corner_value INTEGER`,
    `ALTER TABLE original_block_state ADD COLUMN corner_winner_timestamp INTEGER`,
    `ALTER TABLE original_block_state ADD COLUMN corner_winner_site_id INTEGER`,
    `ALTER TABLE original_block_state ADD COLUMN corner_winner_present INTEGER NOT NULL DEFAULT 0
      CHECK (corner_winner_present IN (0, 1))`,
    `ALTER TABLE original_block_state ADD COLUMN text_wrap_value INTEGER`,
    `ALTER TABLE original_block_state ADD COLUMN text_wrap_winner_timestamp INTEGER`,
    `ALTER TABLE original_block_state ADD COLUMN text_wrap_winner_site_id INTEGER`,
    `ALTER TABLE original_block_state ADD COLUMN text_wrap_winner_present INTEGER NOT NULL DEFAULT 0
      CHECK (text_wrap_winner_present IN (0, 1))`,
    `ALTER TABLE original_block_state ADD COLUMN enable_caption_value INTEGER`,
    `ALTER TABLE original_block_state ADD COLUMN enable_caption_winner_timestamp INTEGER`,
    `ALTER TABLE original_block_state ADD COLUMN enable_caption_winner_site_id INTEGER`,
    `ALTER TABLE original_block_state ADD COLUMN enable_caption_winner_present INTEGER NOT NULL DEFAULT 0
      CHECK (enable_caption_winner_present IN (0, 1))`,
    `ALTER TABLE original_block_state ADD COLUMN position_locked_value INTEGER`,
    `ALTER TABLE original_block_state ADD COLUMN position_locked_winner_timestamp INTEGER`,
    `ALTER TABLE original_block_state ADD COLUMN position_locked_winner_site_id INTEGER`,
    `ALTER TABLE original_block_state ADD COLUMN position_locked_winner_present INTEGER NOT NULL DEFAULT 0
      CHECK (position_locked_winner_present IN (0, 1))`,
    `ALTER TABLE original_block_state ADD COLUMN z_index_value TEXT`,
    `ALTER TABLE original_block_state ADD COLUMN z_index_winner_timestamp INTEGER`,
    `ALTER TABLE original_block_state ADD COLUMN z_index_winner_site_id INTEGER`,
    `ALTER TABLE original_block_state ADD COLUMN z_index_winner_present INTEGER NOT NULL DEFAULT 0
      CHECK (z_index_winner_present IN (0, 1))`,
  ],
};
