import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const ddl = read('note/src/main/ets/data/DatabaseHelper.ets');
const evidence = read(
  'docs/migration/evidence/original-room-schema-parity-harmony-2026-09-22.md');

let checks = 0;
const ok = (cond, label) => { assert.ok(cond, label); checks++; };
const eq = (a, b, label) => { assert.equal(a, b, label); checks++; };
const has = (needle, label) => ok(ddl.includes(needle), label);

// --- Original NoteStateEntity (e47.java:347) vs note_state ---------------------
has('CREATE TABLE IF NOT EXISTS note_state', 'note_state table missing');
has('note_id TEXT PRIMARY KEY', 'note_state note_id PK missing');
has('zoom REAL NOT NULL DEFAULT 1.0', 'note_state zoom column missing');
has('scroll_offset_x REAL NOT NULL DEFAULT 0', 'note_state scroll_offset_x missing');
has('scroll_offset_y REAL NOT NULL DEFAULT 0', 'note_state scroll_offset_y missing');

// --- Original NoteAsset (e47.java:332) vs note_asset ---------------------------
has('CREATE TABLE IF NOT EXISTS note_asset', 'note_asset table missing');
has('asset_hash TEXT PRIMARY KEY', 'note_asset asset_hash PK missing');
has('status INTEGER NOT NULL DEFAULT 0', 'note_asset status missing');
has("note_ids TEXT NOT NULL DEFAULT '[]'", 'note_asset note_ids missing');
has('file_size INTEGER NOT NULL DEFAULT 0', 'note_asset file_size missing');

// --- Original ClientOp (e47.java:336) vs operation_log --------------------------
has('CREATE TABLE IF NOT EXISTS operation_log', 'operation_log table missing');
has('UNIQUE(note_id, op_id)', 'operation_log note+op identity missing');
has('UNIQUE(note_id, editor_site_id, op_timestamp)',
  'operation_log CRDT identity unique missing');
has('upload_immediately INTEGER NOT NULL DEFAULT 0', 'operation_log upload flag missing');
has('op_timestamp INTEGER NOT NULL CHECK (op_timestamp BETWEEN 0 AND 4294967295)',
  'operation_log op_timestamp bound missing');

// --- Original SyncedOpMetadata (e47.java:336) vs note_sync_metadata -------------
has('CREATE TABLE IF NOT EXISTS note_sync_metadata', 'note_sync_metadata missing');
has('editor_site_id INTEGER NOT NULL CHECK (editor_site_id BETWEEN 0 AND 65535)',
  'sync metadata editor_site_id bound missing');
has('synced_op_count INTEGER NOT NULL DEFAULT 0', 'sync metadata op count missing');
has('schema_version INTEGER NOT NULL DEFAULT 1', 'sync metadata schema_version missing');
has('acked_through_sequence <= uploaded_through_sequence',
  'sync metadata ack<=uploaded invariant missing');

// --- Original SyncedNoteMetadata (e47.java:351) vs note_meta ---------------------
has('CREATE TABLE IF NOT EXISTS note_meta', 'note_meta table missing');
has('favorite INTEGER NOT NULL DEFAULT 0', 'note_meta favorite missing');
has('last_opened INTEGER NOT NULL DEFAULT 0', 'note_meta last_opened missing');
has('FOREIGN KEY(folder_id) REFERENCES folder(id) ON DELETE SET NULL',
  'note_meta folder FK missing');

// --- Original SyncedFolderMetadata (e47.java:353) vs folder ----------------------
has('CREATE TABLE IF NOT EXISTS folder', 'folder table missing');
has('sibling_order REAL NOT NULL DEFAULT 0', 'folder sibling_order missing');
has('FOREIGN KEY(parent_id) REFERENCES folder(id) ON DELETE CASCADE',
  'folder parent FK cascade missing');

// --- Original search_item (e47.java:366) vs search_item ---------------------------
has('CREATE TABLE IF NOT EXISTS search_item', 'search_item table missing');
has('folded_text TEXT NOT NULL', 'search_item folded_text missing');
has('rects BLOB', 'search_item rects missing');
has('UNIQUE(note_id, type, sub_id)', 'search_item unique identity missing');
has('FOREIGN KEY(note_id, page_id) REFERENCES page_info(note_id, page_id) ON DELETE CASCADE',
  'search_item page FK missing');

// --- Original PaperBackground/BackgroundInfo (e47.java:371) -----------------------
has('CREATE TABLE IF NOT EXISTS PaperBackground', 'PaperBackground missing');
has('paperSize INTEGER NOT NULL', 'PaperBackground paperSize missing');
has('paperOrientation TEXT NOT NULL', 'PaperBackground paperOrientation missing');
has('paperLineType TEXT NOT NULL', 'PaperBackground paperLineType missing');
has('hasOptions INTEGER NOT NULL', 'PaperBackground hasOptions missing');
has('CREATE TABLE IF NOT EXISTS BackgroundInfo', 'BackgroundInfo missing');
has('PRIMARY KEY(paperLineType)', 'BackgroundInfo PK missing');

// --- Original Toolbox entities (e47.java:376-383) ---------------------------------
has('CREATE TABLE IF NOT EXISTS tool_state', 'tool_state table missing');
has('tray_owner_id TEXT NOT NULL', 'tool_state tray_owner_id missing');
has('selection_is_freehand INTEGER NOT NULL DEFAULT 0',
  'tool_state selection_is_freehand missing');
has('eraser_is_partial INTEGER NOT NULL DEFAULT 0',
  'tool_state eraser_is_partial missing');
has('CREATE TABLE IF NOT EXISTS editor_toolbox_state', 'editor_toolbox_state missing');
has('most_recent_tool_id TEXT NOT NULL', 'toolbox most_recent_tool_id missing');
has('previous_tool_id TEXT NOT NULL', 'toolbox previous_tool_id missing');
// Original index_ToolStateEntity_tray_owner_id parity (Phase 530 fix).
has('CREATE INDEX IF NOT EXISTS idx_tool_state_tray_owner ON tool_state(tray_owner_id)',
  'tool_state tray_owner_id parity index missing');

// --- Original DeferredSyncedOps (e47.java:340) vs deferred bundle ------------------
has('CREATE TABLE IF NOT EXISTS deferred_synced_operation_bundle',
  'deferred_synced_operation_bundle missing');
has("table_type TEXT NOT NULL CHECK (table_type IN (\n    'NOTE_BUNDLE', 'OPS_BUNDLE', 'RECEIVE_OPS_EVENT'\n  ))",
  'deferred bundle table_type enum missing');
has('checksum INTEGER NOT NULL', 'deferred bundle checksum missing');
has('idx_deferred_synced_bundle_note', 'deferred bundle note index missing');

// --- Registered deltas must stay documented (Phase 530 evidence) -------------------
for (const id of ['SCHEMA-D1', 'SCHEMA-D2', 'SCHEMA-D3', 'SCHEMA-D4', 'SCHEMA-D5',
  'SCHEMA-D6', 'SCHEMA-D7']) {
  ok(evidence.includes(id), `evidence missing ${id}`);
}
ok(evidence.includes('x17.java'), 'evidence must cite the ClientPivot query');
ok(evidence.includes('e47.java'), 'evidence must cite the Room DDL callback');

// --- Original ClientPivot merge model (x17.java:143) -------------------------------
// Replays the original library merge so the registered SCHEMA-D1 delta stays
// executable: effective rows = synced metadata merged with pivoted
// ClientNoteUpdate rows, minus PermanentlyDeletedNote tombstones.
const pivot = (updates) => {
  const byId = new Map();
  for (const u of updates) {
    const p = byId.get(u.id) ?? {
      editCreatedAt: null, editFavorite: null, editLastOpened: null,
      editFolderId: null, deleteDeletedAt: null, hasUndelete: null,
      hasPermanentlyDelete: null,
    };
    if (u.type === 'EDIT') {
      p.editCreatedAt = u.createdAt ?? p.editCreatedAt;
      p.editFavorite = u.favorite ?? p.editFavorite;
      p.editLastOpened = u.lastOpened ?? p.editLastOpened;
      p.editFolderId = u.folderId ?? p.editFolderId;
    } else if (u.type === 'DELETE') {
      p.deleteDeletedAt = u.deletedAt ?? p.deleteDeletedAt;
    } else if (u.type === 'UNDELETE') {
      // leb.java: undelete upserts the UNDELETE row and deletes the DELETE row,
      // so the pivot's unconditional MAX(DELETE.deletedAt) never sees it again.
      p.hasUndelete = 1;
      p.deleteDeletedAt = null;
    } else if (u.type === 'PERMANENTLY_DELETE') {
      p.hasPermanentlyDelete = 1;
    }
    byId.set(u.id, p);
  }
  return byId;
};
const mergeNotes = (synced, updates, tombstones) => {
  const pivoted = pivot(updates);
  const ids = new Set(synced.keys());
  for (const [id, p] of pivoted) {
    if (!ids.has(id) && p.hasPermanentlyDelete === null && p.editCreatedAt !== null) {
      ids.add(id);
    }
  }
  const rows = [];
  for (const id of ids) {
    if (tombstones.has(id)) continue;
    const s = synced.get(id) ?? null;
    const p = pivoted.get(id) ?? null;
    const deletedAt = p !== null && p.deleteDeletedAt !== null ? p.deleteDeletedAt :
      (p !== null && p.hasUndelete === 1 ? null : (s === null ? null : s.deletedAt));
    rows.push({ id, deletedAt });
  }
  return rows;
};
const synced = new Map([
  ['n1', { deletedAt: null }], ['n2', { deletedAt: 50 }], ['n3', { deletedAt: null }],
]);
const updates = [
  { id: 'n1', type: 'DELETE', deletedAt: 90 },
  { id: 'n2', type: 'UNDELETE' },
  { id: 'n4', type: 'EDIT', createdAt: 10, favorite: 1, lastOpened: null, folderId: null },
  { id: 'n5', type: 'EDIT', createdAt: 20, favorite: null, lastOpened: null, folderId: null },
  { id: 'n5', type: 'PERMANENTLY_DELETE' },
  { id: 'n6', type: 'EDIT', createdAt: 30, favorite: null, lastOpened: null, folderId: null },
  { id: 'n6', type: 'DELETE', deletedAt: 40 },
  { id: 'n6', type: 'UNDELETE' },
];
const tombstones = new Set(['n6-tombstoned']);
const merged = mergeNotes(synced, updates, tombstones);
const byId = new Map(merged.map(row => [row.id, row.deletedAt]));
eq(byId.get('n1'), 90);           // client DELETE wins over synced null
eq(byId.get('n2'), null);         // UNDELETE clears synced deletedAt
eq(byId.get('n3'), null);         // untouched synced row survives
eq(byId.get('n4'), null);         // client-only EDIT note is alive
eq(byId.get('n6'), null);         // DELETE then UNDELETE restores
// A client-only note with a PERMANENTLY_DELETE pivot row must not appear.
ok(!merged.some(row => row.id === 'n5'), 'n5 must be excluded');

// PermanentlyDeletedNote tombstone hides a stale synced row.
const merged2 = mergeNotes(new Map([['n6-tombstoned', { deletedAt: null }]]), [],
  tombstones);
ok(merged2.length === 0, 'tombstoned synced note must stay hidden');

console.log(`TOTAL=${checks} FAILED=0`);
