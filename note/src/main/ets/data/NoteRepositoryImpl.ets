// T-017 NoteRepository 实现（relationalStore，全部方法异常安全）
import { relationalStore } from '@kit.ArkData';
import {
  CURRENT_VIEW_COORDINATE_MODEL_VERSION, isCurrentViewCoordinateModel, NoteMeta, NoteViewState,
} from '../core/model/NoteTypes';
import { NoteRepository } from './RepositoryInterfaces';
import { DatabaseManager } from './DatabaseManager';
import { assetMutationMutex, parseAssetNoteIds, unlinkAssetFile } from './AssetRepositoryImpl';
import { escapeSearchLike, foldSearchText } from './SearchText';
import { SearchItemType } from './SearchItemType';
import {
  initializeImportedNoteSyncMetadata,
} from './OpStoreImpl';
import { persistOriginalCreatePage } from './OriginalPagePersistence';

interface NoteAssetReference {
  assetHash: string;
  noteIds: string[];
  localPath: string | null;
}

export class NoteRepositoryImpl implements NoteRepository {
  private db: DatabaseManager;

  constructor(db: DatabaseManager) {
    this.db = db;
  }

  async createNote(title: string, folderId: string | null): Promise<NoteMeta> {
    const store: relationalStore.RdbStore = this.db.getStore();
    const now: number = Date.now();
    const id: string = this.generateId();
    const note: NoteMeta = this.buildNote(id, title, now, now, folderId, false);
    await store.beginTransaction();
    try {
      await store.insert('note_meta', this.noteBucket(note));
      // Original 1.0.3 creates an implicit Letter page when nz9 background is absent.
      await persistOriginalCreatePage(store, note.id, null);
      await this.upsertTitleSearchItem(store, note.id, note.title);
      await store.commit();
    } catch (e) {
      await store.rollBack();
      throw new Error(`createNote failed: ${JSON.stringify(e)}`);
    }
    return note;
  }

  // Import path: restore metadata without creating the normal default blank page.
  async createNoteWithMeta(id: string, title: string, createdAt: number, updatedAt: number,
    folderId: string | null, hasRecordings?: boolean, legacyId?: string | null): Promise<NoteMeta> {
    const note: NoteMeta = this.buildNote(id, title, createdAt, updatedAt, folderId,
      hasRecordings === true);
    const store: relationalStore.RdbStore = this.db.getStore();
    await store.beginTransaction();
    try {
      await store.insert('note_meta', this.noteBucket(note));
      await initializeImportedNoteSyncMetadata(
        store, note.id, legacyId === undefined ? null : legacyId, createdAt, updatedAt);
      await this.upsertTitleSearchItem(store, note.id, note.title);
      await store.commit();
    } catch (e) {
      await store.rollBack();
      throw new Error(`createNoteWithMeta failed: ${JSON.stringify(e)}`);
    }
    return note;
  }

  async getNote(noteId: string): Promise<NoteMeta | null> {
    const store: relationalStore.RdbStore = this.db.getStore();
    const predicates = new relationalStore.RdbPredicates('note_meta');
    predicates.equalTo('id', noteId);
    try {
      const resultSet = await store.query(predicates);
      let note: NoteMeta | null = null;
      try {
        if (resultSet.goToNextRow()) {
          note = this.rowToNote(resultSet);
        }
      } finally {
        resultSet.close();
      }
      return note;
    } catch (e) {
      throw new Error(`getNote failed: ${JSON.stringify(e)}`);
    }
  }

  async getAllNotes(): Promise<NoteMeta[]> {
    const store: relationalStore.RdbStore = this.db.getStore();
    const predicates = new relationalStore.RdbPredicates('note_meta');
    predicates.orderByDesc('updated_at');
    try {
      const resultSet = await store.query(predicates);
      const notes: NoteMeta[] = [];
      try {
        while (resultSet.goToNextRow()) {
          notes.push(this.rowToNote(resultSet));
        }
      } finally {
        resultSet.close();
      }
      return notes;
    } catch (e) {
      throw new Error(`getAllNotes failed: ${JSON.stringify(e)}`);
    }
  }

  async getNotesByFolder(folderId: string): Promise<NoteMeta[]> {
    const store: relationalStore.RdbStore = this.db.getStore();
    const predicates = new relationalStore.RdbPredicates('note_meta');
    predicates.equalTo('folder_id', folderId);
    predicates.orderByDesc('updated_at');
    try {
      const resultSet = await store.query(predicates);
      const notes: NoteMeta[] = [];
      try {
        while (resultSet.goToNextRow()) {
          notes.push(this.rowToNote(resultSet));
        }
      } finally {
        resultSet.close();
      }
      return notes;
    } catch (e) {
      throw new Error(`getNotesByFolder failed: ${JSON.stringify(e)}`);
    }
  }

  async searchNotes(query: string, folderId: string | null): Promise<NoteMeta[]> {
    const foldedQuery: string = foldSearchText(query).trim();
    if (foldedQuery.length === 0) {
      return folderId === null ? this.getAllNotes() : this.getNotesByFolder(folderId);
    }
    const escapedPattern: string = `%${escapeSearchLike(foldedQuery)}%`;
    const store: relationalStore.RdbStore = this.db.getStore();
    try {
      let resultSet: relationalStore.ResultSet;
      if (folderId === null) {
        resultSet = await store.querySql(`SELECT note.* FROM note_meta note
          WHERE EXISTS (SELECT 1 FROM search_item item
            WHERE item.note_id = note.id AND item.folded_text LIKE ? ESCAPE '\\')
          ORDER BY note.updated_at DESC`, [escapedPattern]);
      } else {
        resultSet = await store.querySql(`SELECT note.* FROM note_meta note
          WHERE note.folder_id = ? AND EXISTS (SELECT 1 FROM search_item item
            WHERE item.note_id = note.id AND item.folded_text LIKE ? ESCAPE '\\')
          ORDER BY note.updated_at DESC`, [folderId, escapedPattern]);
      }
      const notes: NoteMeta[] = [];
      try {
        while (resultSet.goToNextRow()) {
          notes.push(this.rowToNote(resultSet));
        }
      } finally {
        resultSet.close();
      }
      return notes;
    } catch (e) {
      throw new Error(`searchNotes failed: ${JSON.stringify(e)}`);
    }
  }

  async updateNote(note: NoteMeta): Promise<void> {
    const store: relationalStore.RdbStore = this.db.getStore();
    const bucket: relationalStore.ValuesBucket = {
      'title': note.title,
      'updated_at': Date.now(),
      'favorite': note.favorite ? 1 : 0,
      'last_opened': note.lastOpened,
      'folder_id': note.folderId,
      'has_recordings': note.hasRecordings ? 1 : 0,
    };
    const predicates = new relationalStore.RdbPredicates('note_meta');
    predicates.equalTo('id', note.id);
    await store.beginTransaction();
    try {
      const changed: number = await store.update(bucket, predicates);
      if (changed === 0) {
        throw new Error('note does not exist');
      }
      await this.upsertTitleSearchItem(store, note.id, note.title);
      await store.commit();
    } catch (e) {
      await store.rollBack();
      throw new Error(`updateNote failed: ${JSON.stringify(e)}`);
    }
  }

  async deleteNote(noteId: string): Promise<void> {
    const store: relationalStore.RdbStore = this.db.getStore();
    const filesToDelete: string[] = [];
    await assetMutationMutex.runExclusive(async (): Promise<void> => {
      await store.beginTransaction();
      try {
        const noteCheck = new relationalStore.RdbPredicates('note_meta');
        noteCheck.equalTo('id', noteId);
        const noteRows = await store.query(noteCheck, ['id']);
        try {
          if (!noteRows.goToFirstRow()) {
            throw new Error('note does not exist');
          }
        } finally {
          noteRows.close();
        }
        const assetReferences: NoteAssetReference[] = [];
        const assetResultSet = await store.query(new relationalStore.RdbPredicates('note_asset'));
        try {
          while (assetResultSet.goToNextRow()) {
            const noteIds: string[] = parseAssetNoteIds(
              assetResultSet.getString(assetResultSet.getColumnIndex('note_ids')));
            if (noteIds.indexOf(noteId) >= 0) {
              const localPathColumn: number = assetResultSet.getColumnIndex('local_path');
              assetReferences.push({
                assetHash: assetResultSet.getString(assetResultSet.getColumnIndex('asset_hash')),
                noteIds: noteIds,
                localPath: assetResultSet.isColumnNull(localPathColumn) ? null :
                  assetResultSet.getString(localPathColumn),
              });
            }
          }
        } finally {
          assetResultSet.close();
        }
        for (let i: number = 0; i < assetReferences.length; i++) {
          const reference: NoteAssetReference = assetReferences[i];
          const remainingNoteIds: string[] = [];
          for (let j: number = 0; j < reference.noteIds.length; j++) {
            if (reference.noteIds[j] !== noteId) {
              remainingNoteIds.push(reference.noteIds[j]);
            }
          }
          const assetPredicates = new relationalStore.RdbPredicates('note_asset');
          assetPredicates.equalTo('asset_hash', reference.assetHash);
          if (remainingNoteIds.length === 0) {
            await store.delete(assetPredicates);
            if (reference.localPath !== null && reference.localPath.length > 0) {
              filesToDelete.push(reference.localPath);
            }
          } else {
            const assetBucket: relationalStore.ValuesBucket = {
              'note_ids': JSON.stringify(remainingNoteIds),
            };
            await store.update(assetBucket, assetPredicates);
          }
        }
        const p2 = new relationalStore.RdbPredicates('page_info');
        p2.equalTo('note_id', noteId);
        await store.delete(p2);
        const p3 = new relationalStore.RdbPredicates('page_element_snapshot');
        p3.equalTo('note_id', noteId);
        await store.delete(p3);
        const p4 = new relationalStore.RdbPredicates('note_state');
        p4.equalTo('note_id', noteId);
        await store.delete(p4);
        const p1 = new relationalStore.RdbPredicates('note_meta');
        p1.equalTo('id', noteId);
        const deleted: number = await store.delete(p1);
        if (deleted !== 1) {
          throw new Error(`expected to delete one note, deleted ${deleted}`);
        }
        await store.commit();
      } catch (e) {
        await store.rollBack();
        throw new Error(`deleteNote failed: ${JSON.stringify(e)}`);
      }
    });
    const filesRoot: string = this.db.getFilesDir();
    for (let i: number = 0; i < filesToDelete.length; i++) {
      unlinkAssetFile(filesToDelete[i], filesRoot);
    }
  }

  async getViewState(noteId: string): Promise<NoteViewState | null> {
    const store: relationalStore.RdbStore = this.db.getStore();
    const predicates = new relationalStore.RdbPredicates('note_state');
    predicates.equalTo('note_id', noteId);
    try {
      const resultSet = await store.query(predicates);
      let state: NoteViewState | null = null;
      try {
        if (resultSet.goToNextRow()) {
          state = {
            noteId: resultSet.getString(resultSet.getColumnIndex('note_id')),
            zoom: resultSet.getDouble(resultSet.getColumnIndex('zoom')),
            scrollOffsetX: resultSet.getDouble(resultSet.getColumnIndex('scroll_offset_x')),
            scrollOffsetY: resultSet.getDouble(resultSet.getColumnIndex('scroll_offset_y')),
            coordinateModelVersion:
              resultSet.getLong(resultSet.getColumnIndex('coordinate_model_version')),
          };
        }
      } finally {
        resultSet.close();
      }
      return state;
    } catch (e) {
      throw new Error(`getViewState failed: ${JSON.stringify(e)}`);
    }
  }

  async saveViewState(state: NoteViewState): Promise<void> {
    if (!isCurrentViewCoordinateModel(state.coordinateModelVersion)) {
      throw new Error(`saveViewState coordinate model mismatch: ${state.coordinateModelVersion}`);
    }
    const store: relationalStore.RdbStore = this.db.getStore();
    const bucket: relationalStore.ValuesBucket = {
      'note_id': state.noteId,
      'zoom': state.zoom,
      'scroll_offset_x': state.scrollOffsetX,
      'scroll_offset_y': state.scrollOffsetY,
      'coordinate_model_version': CURRENT_VIEW_COORDINATE_MODEL_VERSION,
    };
    try {
      await store.insert('note_state', bucket, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
    } catch (e) {
      throw new Error(`saveViewState failed: ${JSON.stringify(e)}`);
    }
  }

  private rowToNote(resultSet: relationalStore.ResultSet): NoteMeta {
    try {
      const folderColumn: number = resultSet.getColumnIndex('folder_id');
      return {
        id: resultSet.getString(resultSet.getColumnIndex('id')),
        title: resultSet.getString(resultSet.getColumnIndex('title')),
        createdAt: resultSet.getLong(resultSet.getColumnIndex('created_at')),
        updatedAt: resultSet.getLong(resultSet.getColumnIndex('updated_at')),
        favorite: resultSet.getLong(resultSet.getColumnIndex('favorite')) !== 0,
        lastOpened: resultSet.getLong(resultSet.getColumnIndex('last_opened')),
        folderId: resultSet.isColumnNull(folderColumn) ? null : resultSet.getString(folderColumn),
        hasRecordings: resultSet.getLong(resultSet.getColumnIndex('has_recordings')) !== 0,
      };
    } catch (e) {
      throw new Error('rowToNote failed: ' + JSON.stringify(e));
    }
  }

  private buildNote(id: string, title: string, createdAt: number, updatedAt: number,
    folderId: string | null, hasRecordings: boolean): NoteMeta {
    return {
      id: id,
      title: title,
      createdAt: createdAt,
      updatedAt: updatedAt,
      favorite: false,
      lastOpened: updatedAt,
      folderId: folderId,
      hasRecordings: hasRecordings,
    };
  }

  private noteBucket(note: NoteMeta): relationalStore.ValuesBucket {
    return {
      'id': note.id,
      'title': note.title,
      'created_at': note.createdAt,
      'updated_at': note.updatedAt,
      'favorite': note.favorite ? 1 : 0,
      'last_opened': note.lastOpened,
      'folder_id': note.folderId,
      'has_recordings': note.hasRecordings ? 1 : 0,
    };
  }

  private async upsertTitleSearchItem(store: relationalStore.RdbStore, noteId: string,
    title: string): Promise<void> {
    const bucket: relationalStore.ValuesBucket = {
      'note_id': noteId,
      'type': SearchItemType.TITLE,
      'sub_id': noteId,
      'page_id': null,
      'folded_text': foldSearchText(title),
      'rects': null,
    };
    await store.insert('search_item', bucket, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
  }

  private generateId(): string {
    const timePart: string = Date.now().toString(36);
    const randPart: string = Math.random().toString(36).slice(2, 8);
    return timePart + randPart;
  }
}
