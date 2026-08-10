import { describe, it, expect } from '@ohos/hypium';
import {
  DB_VERSION, DDL_EDITOR_TOOLBOX_STATE, DDL_FOLDER, DDL_PAGE_ELEMENT_SNAPSHOT, DDL_PAGE_INFO,
  DDL_NOTE_META, DDL_NOTE_STATE, DDL_OPERATION_LOG, DDL_SEARCH_ITEM, DDL_SEARCH_PAGE_STATE,
  DDL_PAGE_DELETE_CHECKPOINT, DDL_PAGE_DELETE_CHECKPOINT_ELEMENT, DDL_PAGE_DELETE_CHECKPOINT_SEARCH,
  DDL_HISTORY_CHECKPOINT, DDL_HISTORY_CHECKPOINT_ACTION, DDL_HISTORY_CHECKPOINT_OPERATION,
  DDL_DEFERRED_SYNCED_OPERATION_BUNDLE, DDL_LOCAL_EDITOR_IDENTITY, DDL_NOTE_SYNC_METADATA,
  DDL_SYNCED_OPERATION_INBOX, DDL_ORIGINAL_PAGE_INSERT_GROUP, DDL_ORIGINAL_PAGE_IDENTITY,
  DDL_ORIGINAL_PAGE_VISIBILITY_WINNER, DDL_ORIGINAL_PAGE_BACKGROUND_WINNER,
  DDL_ORIGINAL_ELEMENT_Z_INDEX, DDL_ORIGINAL_INK_STATE, DDL_ORIGINAL_INK_PATH_APPEND,
  DDL_ORIGINAL_BLOCK_STATE,
  DDL_ORIGINAL_DELETED_PAGE,
  DDL_ORIGINAL_DELETED_PAGE_ELEMENT, DDL_ORIGINAL_DELETED_PAGE_SEARCH,
  DDL_INDEXES, MIGRATIONS,
} from
  '../main/ets/data/DatabaseHelper';
import { isCurrentViewCoordinateModel } from '../main/ets/core/model/NoteTypes';
import { SearchItemType } from '../main/ets/data/SearchItemType';

export default function databaseHelperTest() {
  describe('DatabaseHelper', () => {
    it('uses the original note-scoped ClientOp identity', 0, () => {
      expect(DB_VERSION).assertEqual(36);
      expect(MIGRATIONS[4].join('\n')).assertContain('PRIMARY KEY(note_id, op_id)');
    });

    it('persists original editor-site clocks and ordered sync acknowledgement', 0, () => {
      expect(DDL_OPERATION_LOG).assertContain('op_timestamp INTEGER NOT NULL');
      expect(DDL_OPERATION_LOG).assertContain('editor_site_id INTEGER NOT NULL');
      expect(DDL_OPERATION_LOG).assertContain('UNIQUE(note_id, editor_site_id, op_timestamp)');
      expect(DDL_LOCAL_EDITOR_IDENTITY).assertContain('singleton = 1');
      expect(DDL_NOTE_SYNC_METADATA).assertContain('max_op_timestamp');
      expect(DDL_NOTE_SYNC_METADATA).assertContain('uploaded_through_sequence');
      expect(DDL_NOTE_SYNC_METADATA).assertContain('acked_through_sequence <= uploaded_through_sequence');
      const migration: string = MIGRATIONS[18].join('\n');
      expect(migration).assertContain('CREATE TABLE operation_log_v18');
      expect(migration).assertContain('SELECT sequence, note_id, op_id');
      expect(migration).assertContain('lower(hex(randomblob(16)))');
    });

    it('migrates unsigned server cursors to precision-safe canonical decimal text', 0, () => {
      expect(DDL_NOTE_SYNC_METADATA).assertContain('max_server_time TEXT');
      expect(DDL_NOTE_SYNC_METADATA).assertContain('18446744073709551615');
      const migration: string = MIGRATIONS[19].join('\n');
      expect(migration).assertContain('note_sync_metadata_v19');
      expect(migration).assertContain('CAST(max_server_time AS TEXT)');
    });

    it('keeps received and deferred synced ops outside the local upload log', 0, () => {
      expect(DDL_SYNCED_OPERATION_INBOX)
        .assertContain('PRIMARY KEY(note_id, op_timestamp, editor_site_id)');
      expect(DDL_SYNCED_OPERATION_INBOX).assertContain('raw_operation BLOB NOT NULL');
      expect(DDL_SYNCED_OPERATION_INBOX).assertContain('state IN (0, 1, 2)');
      expect(DDL_DEFERRED_SYNCED_OPERATION_BUNDLE).assertContain('length(payload) = payload_size');
      expect(MIGRATIONS[20].join('\n')).assertNotContain('operation_log');
      expect(DDL_DEFERRED_SYNCED_OPERATION_BUNDLE).assertContain('RECEIVE_OPS_EVENT');
      expect(MIGRATIONS[21].join('\n')).assertContain('deferred_synced_operation_bundle_v21');
      expect(MIGRATIONS[21].join('\n')).assertContain("table_type NOT IN ('NOTE_BUNDLE'");
      expect(MIGRATIONS[22].join('\n')).assertContain('original_page_insert_group');
      expect(MIGRATIONS[22].join('\n')).assertContain('original_page_identity');
      expect(MIGRATIONS[23].join('\n')).assertContain('original_page_position_group');
      expect(MIGRATIONS[23].join('\n')).assertContain('original_page_position_winner');
      expect(MIGRATIONS[24].join('\n')).assertContain('original_page_visibility_winner');
      expect(MIGRATIONS[25].join('\n')).assertContain('original_page_background_winner');
      expect(MIGRATIONS[26].join('\n')).assertContain('original_element_z_index');
      expect(MIGRATIONS[27].join('\n')).assertContain('original_ink_state');
      expect(MIGRATIONS[27].join('\n')).assertContain('original_ink_path_append');
      expect(MIGRATIONS[28].join('\n')).assertContain('center_path_winner_timestamp');
      expect(MIGRATIONS[28].join('\n')).assertContain('center_path_winner_site_id');
      expect(MIGRATIONS[28].join('\n')).assertContain('SET center_path_winner_timestamp = ink_timestamp');
      expect(MIGRATIONS[29].join('\n')).assertContain('style_winner_timestamp');
      expect(MIGRATIONS[29].join('\n')).assertContain('color_winner_timestamp');
      expect(MIGRATIONS[29].join('\n')).assertContain('width_winner_timestamp');
      expect(MIGRATIONS[30].join('\n')).assertContain('center_path_winner_present');
      expect(MIGRATIONS[30].join('\n')).assertContain('rotation_winner_present');
      expect(MIGRATIONS[30].join('\n')).assertContain('scale_winner_present');
      expect(MIGRATIONS[30].join('\n')).assertContain('create_origin_x');
      expect(MIGRATIONS[31].join('\n')).assertContain('create_page_timestamp');
      expect(MIGRATIONS[31].join('\n')).assertContain('page_origin_winner_present');
      expect(MIGRATIONS[32].join('\n')).assertContain('create_z_index');
      expect(MIGRATIONS[32].join('\n')).assertContain('z_index_winner_present');
      expect(MIGRATIONS[33].join('\n')).assertContain('custom_path_winner_present');
      expect(MIGRATIONS[34].join('\n')).assertContain('style_map_winner_present');
      expect(MIGRATIONS[35].join('\n')).assertContain('original_block_state');
      expect(MIGRATIONS[36].join('\n')).assertContain('page_origin_winner_present');
      expect(MIGRATIONS[36].join('\n')).assertContain('z_index_winner_present');
      expect(DDL_ORIGINAL_ELEMENT_Z_INDEX).assertContain('z_index TEXT NOT NULL');
      expect(DDL_ORIGINAL_ELEMENT_Z_INDEX).assertContain('18446744073709551615');
      expect(DDL_ORIGINAL_INK_STATE).assertContain('base_center_path BLOB NOT NULL');
      expect(DDL_ORIGINAL_INK_STATE).assertContain('center_path_winner_timestamp INTEGER NOT NULL');
      expect(DDL_ORIGINAL_INK_STATE).assertContain('style_value INTEGER');
      expect(DDL_ORIGINAL_INK_STATE).assertContain('color_value INTEGER');
      expect(DDL_ORIGINAL_INK_STATE).assertContain('width_value REAL');
      expect(DDL_ORIGINAL_INK_STATE).assertContain('center_path_winner_present INTEGER NOT NULL');
      expect(DDL_ORIGINAL_INK_STATE).assertContain('rotation_value REAL');
      expect(DDL_ORIGINAL_INK_STATE).assertContain('scale_x_value REAL');
      expect(DDL_ORIGINAL_INK_STATE).assertContain('page_origin_page_timestamp INTEGER');
      expect(DDL_ORIGINAL_INK_STATE).assertContain('z_index_value TEXT');
      expect(DDL_ORIGINAL_INK_STATE).assertContain('z_index_winner_present INTEGER NOT NULL');
      expect(DDL_ORIGINAL_INK_STATE).assertContain('create_style_map BLOB');
      expect(DDL_ORIGINAL_INK_STATE).assertContain('style_map_winner_present INTEGER NOT NULL');
      expect(DDL_ORIGINAL_INK_STATE).assertContain('REFERENCES original_element_z_index');
      expect(DDL_ORIGINAL_INK_PATH_APPEND)
        .assertContain('PRIMARY KEY(note_id, append_timestamp, append_site_id)');
      expect(DDL_ORIGINAL_INK_PATH_APPEND).assertContain('REFERENCES original_ink_state');
      expect(DDL_ORIGINAL_BLOCK_STATE).assertContain('create_margin_left REAL NOT NULL');
      expect(DDL_ORIGINAL_BLOCK_STATE).assertContain('page_origin_winner_present');
      expect(DDL_ORIGINAL_BLOCK_STATE).assertContain('rotation_winner_present');
      expect(DDL_ORIGINAL_BLOCK_STATE).assertContain('z_index_winner_present');
      expect(DDL_ORIGINAL_BLOCK_STATE).assertContain('REFERENCES original_element_z_index');
      expect(DDL_ORIGINAL_PAGE_VISIBILITY_WINNER).assertContain('deleted IN (0, 1)');
      expect(DDL_ORIGINAL_PAGE_BACKGROUND_WINNER).assertContain('winner_timestamp');
      expect(DDL_ORIGINAL_PAGE_BACKGROUND_WINNER).assertContain('background_json TEXT NOT NULL');
      expect(DDL_ORIGINAL_DELETED_PAGE).assertContain('indexed_revision');
      expect(DDL_ORIGINAL_DELETED_PAGE.includes('REFERENCES page_info')).assertFalse();
      expect(DDL_ORIGINAL_DELETED_PAGE_ELEMENT).assertContain('payload BLOB NOT NULL');
      expect(DDL_ORIGINAL_DELETED_PAGE_SEARCH).assertContain('folded_text TEXT NOT NULL');
      expect(DDL_ORIGINAL_PAGE_INSERT_GROUP).assertContain('parent_index');
      expect(DDL_ORIGINAL_PAGE_INSERT_GROUP).assertContain('page_count BETWEEN 1 AND 10000');
      expect(DDL_ORIGINAL_PAGE_IDENTITY).assertContain('visible = 0 AND page_id IS NULL');
    });

    it('tracks note-scoped page structure revisions', 0, () => {
      expect(DDL_NOTE_META).assertContain('structure_revision INTEGER NOT NULL DEFAULT 0');
      expect(MIGRATIONS[14].join('\n')).assertContain('ADD COLUMN structure_revision');
      expect(MIGRATIONS[15].join('\n')).assertContain('ADD COLUMN action_id');
      expect(MIGRATIONS[15].join('\n')).assertContain('ADD COLUMN history_effect');
      expect(MIGRATIONS[15].join('\n')).assertContain('ADD COLUMN coalesce_track');
      expect(MIGRATIONS[15].join('\n')).assertContain('ADD COLUMN action_time');
      expect(MIGRATIONS[13].join('\n').includes('action_id')).assertFalse();
    });

    it('keeps durable deleted-page contents outside the live page foreign-key domain', 0, () => {
      expect(DDL_PAGE_DELETE_CHECKPOINT).assertContain('PRIMARY KEY(note_id, action_id)');
      expect(DDL_PAGE_DELETE_CHECKPOINT).assertContain('content_revision');
      expect(DDL_PAGE_DELETE_CHECKPOINT).assertContain('indexed_revision');
      expect(DDL_PAGE_DELETE_CHECKPOINT).assertContain('REFERENCES note_meta(id) ON DELETE CASCADE');
      expect(DDL_PAGE_DELETE_CHECKPOINT.includes('REFERENCES page_info')).assertFalse();
      expect(DDL_PAGE_DELETE_CHECKPOINT_ELEMENT).assertContain('payload BLOB NOT NULL');
      expect(DDL_PAGE_DELETE_CHECKPOINT_ELEMENT).assertContain('element_order');
      expect(DDL_PAGE_DELETE_CHECKPOINT_SEARCH).assertContain('folded_text');
      expect(MIGRATIONS[16].join('\n')).assertContain('page_delete_checkpoint');
    });

    it('stores a bounded canonical history stack separately from the append-only sync log', 0, () => {
      expect(DDL_HISTORY_CHECKPOINT).assertContain('through_sequence INTEGER NOT NULL');
      expect(DDL_HISTORY_CHECKPOINT).assertContain('legacy_operation_count INTEGER NOT NULL');
      expect(DDL_HISTORY_CHECKPOINT_ACTION).assertContain('UNIQUE(note_id, action_id)');
      expect(DDL_HISTORY_CHECKPOINT_ACTION).assertContain('CHECK (stack_kind IN (0, 1))');
      expect(DDL_HISTORY_CHECKPOINT_OPERATION).assertContain('payload BLOB NOT NULL');
      expect(DDL_HISTORY_CHECKPOINT_OPERATION).assertContain('operation_index INTEGER NOT NULL');
      expect(MIGRATIONS[17].join('\n')).assertContain('history_checkpoint_operation');
    });

    it('keeps the append-only operation log separate from page snapshots', 0, () => {
      expect(DDL_OPERATION_LOG).assertContain('sequence INTEGER PRIMARY KEY AUTOINCREMENT');
      expect(DDL_OPERATION_LOG).assertContain('UNIQUE(note_id, op_id)');
      expect(DDL_OPERATION_LOG).assertContain('payload BLOB NOT NULL');
      expect(DDL_OPERATION_LOG).assertContain('ON DELETE CASCADE');
      expect(DDL_INDEXES.join('\n')).assertContain('operation_log(note_id, client_time, sequence)');
      expect(MIGRATIONS[13].join('\n')).assertContain('CREATE TABLE IF NOT EXISTS operation_log');
    });

    it('persists original-style current and previous tool identities', 0, () => {
      expect(DDL_EDITOR_TOOLBOX_STATE).assertContain('most_recent_tool_id');
      expect(DDL_EDITOR_TOOLBOX_STATE).assertContain('previous_tool_id');
      expect(MIGRATIONS[8].join('\n')).assertContain('editor_toolbox_state');
    });

    it('migrates folders to the original hierarchical ordering model', 0, () => {
      expect(DDL_FOLDER).assertContain('parent_id');
      expect(DDL_FOLDER).assertContain('sibling_order');
      expect(DDL_FOLDER).assertContain('REFERENCES folder(id) ON DELETE CASCADE');
      expect(MIGRATIONS[9].join('\n')).assertContain('parent_id');
      expect(MIGRATIONS[9].join('\n')).assertContain('sibling_order');
    });

    it('uses the original search item identity and revision-aware page backfill', 0, () => {
      expect(DDL_SEARCH_ITEM).assertContain('UNIQUE(note_id, type, sub_id)');
      expect(DDL_SEARCH_ITEM).assertContain('folded_text');
      expect(DDL_SEARCH_ITEM).assertContain('ON DELETE CASCADE');
      expect(DDL_SEARCH_PAGE_STATE).assertContain('indexed_revision');
      expect(MIGRATIONS[10].join('\n')).assertContain('lower(title)');
      expect(SearchItemType.TITLE).assertEqual(0);
      expect(SearchItemType.MAIN_BODY_TEXT).assertEqual(1);
      expect(SearchItemType.TEXT_BLOCK).assertEqual(2);
      expect(SearchItemType.INK).assertEqual(3);
      expect(SearchItemType.PDF).assertEqual(6);
      expect(MIGRATIONS[12].join('\n')).assertContain('SET type = 2 WHERE type = 1');
    });

    it('versions viewport coordinates and rejects legacy state deterministically', 0, () => {
      const migration: string = MIGRATIONS[11].join('\n');
      expect(DDL_NOTE_STATE).assertContain('coordinate_model_version INTEGER NOT NULL DEFAULT 1');
      expect(migration).assertContain('coordinate_model_version');
      expect(migration).assertContain('DEFAULT 0');
      expect(isCurrentViewCoordinateModel(0)).assertFalse();
      expect(isCurrentViewCoordinateModel(1)).assertTrue();
    });

    it('repairs orphans before rebuilding tables with foreign keys', 0, () => {
      const migration: string = MIGRATIONS[6].join('\n');
      expect(migration).assertContain('Recovered Note');
      expect(migration).assertContain('UPDATE client_op SET page_id');
      expect(migration).assertContain('ON DELETE CASCADE');
      expect(migration).assertContain('ON DELETE SET NULL');
      expect(DDL_PAGE_ELEMENT_SNAPSHOT).assertContain('REFERENCES page_info(note_id, page_id)');
      expect(DDL_PAGE_INFO).assertContain('UNIQUE(note_id, page_id)');
    });

    it('enforces the corrected relational integrity contract', 0, () => {
      expect(DDL_NOTE_STATE).assertContain('REFERENCES note_meta(id) ON DELETE CASCADE');
      expect(DDL_NOTE_META).assertContain('REFERENCES folder(id) ON DELETE SET NULL');
      expect(DDL_PAGE_INFO).assertContain('UNIQUE(note_id, page_index)');
      expect(DDL_PAGE_INFO).assertContain('REFERENCES note_meta(id) ON DELETE CASCADE');
      expect(DDL_PAGE_ELEMENT_SNAPSHOT).assertContain(
        'REFERENCES page_info(note_id, page_id) ON DELETE CASCADE');
    });

    it('names the current storage as an ordered page snapshot', 0, () => {
      expect(DDL_PAGE_ELEMENT_SNAPSHOT).assertContain('page_element_snapshot');
      expect(DDL_PAGE_ELEMENT_SNAPSHOT).assertContain('element_order');
      expect(DDL_PAGE_ELEMENT_SNAPSHOT).assertContain('revision');
      expect(DDL_PAGE_INFO).assertContain('content_revision');
      expect(MIGRATIONS[7].join('\n')).assertContain('ADD COLUMN content_revision');
      expect(MIGRATIONS[7].join('\n')).assertContain('FROM client_op current');
    });

    it('deduplicates page indexes before creating the unique index', 0, () => {
      expect(DDL_PAGE_INFO).assertContain('UNIQUE(note_id, page_index)');
      expect(DDL_INDEXES.join('\n')).assertContain('CREATE UNIQUE INDEX');
      const migration: string = MIGRATIONS[5].join('\n');
      expect(migration).assertContain('page_order_v5');
      expect(migration).assertContain('DROP INDEX IF EXISTS idx_page_info_note');
      expect(migration).assertContain('CREATE UNIQUE INDEX IF NOT EXISTS idx_page_info_note');
    });
  });
}
