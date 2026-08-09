import { describe, it, expect } from '@ohos/hypium';
import {
  DB_VERSION, DDL_EDITOR_TOOLBOX_STATE, DDL_FOLDER, DDL_PAGE_ELEMENT_SNAPSHOT, DDL_PAGE_INFO,
  DDL_NOTE_META, DDL_NOTE_STATE, DDL_OPERATION_LOG, DDL_SEARCH_ITEM, DDL_SEARCH_PAGE_STATE,
  DDL_PAGE_DELETE_CHECKPOINT, DDL_PAGE_DELETE_CHECKPOINT_ELEMENT, DDL_PAGE_DELETE_CHECKPOINT_SEARCH,
  DDL_INDEXES, MIGRATIONS,
} from
  '../main/ets/data/DatabaseHelper';
import { isCurrentViewCoordinateModel } from '../main/ets/core/model/NoteTypes';
import { SearchItemType } from '../main/ets/data/SearchItemType';

export default function databaseHelperTest() {
  describe('DatabaseHelper', () => {
    it('uses the original note-scoped ClientOp identity', 0, () => {
      expect(DB_VERSION).assertEqual(16);
      expect(MIGRATIONS[4].join('\n')).assertContain('PRIMARY KEY(note_id, op_id)');
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
