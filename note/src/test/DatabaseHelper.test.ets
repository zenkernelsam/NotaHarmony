import { describe, it, expect } from '@ohos/hypium';
import {
  DB_VERSION, DDL_EDITOR_TOOLBOX_STATE, DDL_FOLDER, DDL_PAGE_ELEMENT_SNAPSHOT, DDL_PAGE_INFO,
  DDL_NOTE_STATE, DDL_SEARCH_ITEM, DDL_SEARCH_PAGE_STATE, DDL_INDEXES, MIGRATIONS,
} from
  '../main/ets/data/DatabaseHelper';
import { isCurrentViewCoordinateModel } from '../main/ets/core/model/NoteTypes';

export default function databaseHelperTest() {
  describe('DatabaseHelper', () => {
    it('uses the original note-scoped ClientOp identity', 0, () => {
      expect(DB_VERSION).assertEqual(11);
      expect(MIGRATIONS[4].join('\n')).assertContain('PRIMARY KEY(note_id, op_id)');
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
