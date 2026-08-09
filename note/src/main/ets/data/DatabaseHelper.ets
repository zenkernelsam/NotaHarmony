// T-007 数据库 DDL 契约（契约 phase-1-data-model.md §3.10，照搬，禁止修改签名）
// 只定义 DDL 字符串常量，不 import relationalStore（实际数据库初始化在 Phase 2 实现）
// 不 import 任何 @ohos.* / @kit.* 平台模块

// 数据库版本
// v3: client_op 增加页面归属；旧的无页元素迁移到笔记第一页。
export const DB_VERSION: number = 10;
export const DB_NAME: string = 'nota.db';

// DDL 语句（工人实现时直接执行）
export const DDL_NOTE_STATE: string = `
CREATE TABLE IF NOT EXISTS note_state (
  note_id TEXT PRIMARY KEY,
  zoom REAL NOT NULL DEFAULT 1.0,
  scroll_offset_x REAL NOT NULL DEFAULT 0,
  scroll_offset_y REAL NOT NULL DEFAULT 0,
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

// Mirrors the original app's search_item(noteId, type, subId, pageId, foldedText, rects)
// model. type 0 is a title and type 1 is an editable/imported text block.
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
};
