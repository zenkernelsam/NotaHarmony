// T-017 NoteRepository 实现（relationalStore，全部方法异常安全）
import { relationalStore } from '@kit.ArkData';
import {
  CURRENT_VIEW_COORDINATE_MODEL_VERSION, isCurrentViewCoordinateModel, isFiniteViewportScrollOffset,
  isOriginalViewportZoom, NoteBackgroundSettings, NoteMeta, NoteViewState,
} from '../core/model/NoteTypes';
import {
  OriginalDefaultTemplateSelection, originalDefaultTemplateSettings,
  originalFallbackDefaultTemplate,
} from '../core/model/OriginalDefaultTemplate';
import { HistoryMetadata, NoteMetadataHistoryState } from '../core/model/OpTypes';
import { LibrarySection, NoteRepository } from './RepositoryInterfaces';
import { DatabaseManager } from './DatabaseManager';
import { databaseWriteMutex } from './DatabaseWriteMutex';
import {
  assetMutationMutex, detachAssetFileForDeletion, isAssetFilePathReferenced, parseAssetNoteIds,
  unlinkAssetFile,
} from './AssetRepositoryImpl';
import { assetAvailabilityHub } from './AssetAvailabilityHub';
import { libraryMetadataMutationMutex } from './LibraryMetadataMutationMutex';
import { escapeSearchLike, foldSearchText } from './SearchText';
import { SearchItemType } from './SearchItemType';
import {
  initializeImportedNoteSyncMetadata,
} from './OpStoreImpl';
import {
  persistOriginalNoteTitle, PersistedOriginalNoteTitle,
} from './OriginalNoteTitlePersistence';
import {
  OriginalNoteMetadataPatch,
} from './OriginalSetMetadataPayloadEncoder';
import {
  persistOriginalNoteMetadata, PersistedOriginalNoteMetadata,
} from './OriginalNoteMetadataPersistence';
import { persistOriginalBlankNoteBootstrap } from './OriginalBlankNoteBootstrapPersistence';
import { DefaultNoteTemplateRepository } from './EditorSettingsStore';

// Original Recently Deleted rule: trashed notes stay recoverable for 30 days
// (feature_settings__recently_deleted_empty_state_header), then are purged.
export const TRASH_RETENTION_MS: number = 30 * 24 * 60 * 60 * 1000;

interface NoteAssetReference {
  assetHash: string;
  noteIds: string[];
  localPath: string | null;
}

export class NoteRepositoryImpl implements NoteRepository {
  private db: DatabaseManager;
  private defaultTemplateRepository: DefaultNoteTemplateRepository | null;

  constructor(db: DatabaseManager,
    defaultTemplateRepository: DefaultNoteTemplateRepository | null = null) {
    this.db = db;
    this.defaultTemplateRepository = defaultTemplateRepository;
  }

  async createNote(title: string, folderId: string | null): Promise<NoteMeta> {
    return libraryMetadataMutationMutex.runExclusive(async (): Promise<NoteMeta> => {
      const store: relationalStore.RdbStore = this.db.getStore();
      const now: number = Date.now();
      const id: string = this.generateId();
      const note: NoteMeta = this.buildNote(id, title, now, now, folderId, false);
      const defaultTemplate = await this.resolveDefaultTemplate();
      await store.beginTransaction();
      try {
        await store.insert('note_meta', this.noteBucket(note));
        // Original id7.d(): combined title + selected default background, followed by
        // one CREATE_PAGE operation whose pageCount is two.
        await persistOriginalBlankNoteBootstrap(store, note.id, note.title, defaultTemplate);
        await store.commit();
      } catch (e) {
        await store.rollBack();
        throw new Error(`createNote failed: ${JSON.stringify(e)}`);
      }
      await this.attachFolderProjection(store, [note]);
      return note;
    });
  }

  // Import path: restore metadata without creating the normal default blank page.
  async createNoteWithMeta(id: string, title: string, createdAt: number, updatedAt: number,
    folderId: string | null, hasRecordings?: boolean, legacyId?: string | null): Promise<NoteMeta> {
    return libraryMetadataMutationMutex.runExclusive(async (): Promise<NoteMeta> => {
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
      await this.attachFolderProjection(store, [note]);
      return note;
    });
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
      if (note !== null) {
        await this.attachFolderProjection(store, [note]);
      }
      return note;
    } catch (e) {
      throw new Error(`getNote failed: ${JSON.stringify(e)}`);
    }
  }

  async getAllNotes(): Promise<NoteMeta[]> {
    const store: relationalStore.RdbStore = this.db.getStore();
    const predicates = new relationalStore.RdbPredicates('note_meta');
    // Original library projection excludes deletedAt != null (ClientPivot merge).
    predicates.isNull('deleted_at');
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
      await this.attachFolderProjection(store, notes);
      return notes;
    } catch (e) {
      throw new Error(`getAllNotes failed: ${JSON.stringify(e)}`);
    }
  }

  async countUnindexedNotes(): Promise<number> {
    const store: relationalStore.RdbStore = this.db.getStore();
    const rows = await store.querySql(
      `SELECT COUNT(*) AS total FROM note_meta note
         WHERE note.deleted_at IS NULL
           AND NOT EXISTS (SELECT 1 FROM search_item item
             WHERE item.note_id = note.id)`);
    try {
      if (!rows.goToFirstRow()) {
        return 0;
      }
      const total: number = rows.getLong(rows.getColumnIndex('total'));
      return total;
    } finally {
      rows.close();
    }
  }

  async getNotesByFolder(folderId: string): Promise<NoteMeta[]> {
    const store: relationalStore.RdbStore = this.db.getStore();
    const predicates = new relationalStore.RdbPredicates('note_meta');
    predicates.equalTo('folder_id', folderId);
    predicates.isNull('deleted_at');
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
      await this.attachFolderProjection(store, notes);
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
          WHERE note.deleted_at IS NULL AND EXISTS (SELECT 1 FROM search_item item
            WHERE item.note_id = note.id AND item.folded_text LIKE ? ESCAPE '\\')
          ORDER BY note.updated_at DESC`, [escapedPattern]);
      } else {
        resultSet = await store.querySql(`SELECT note.* FROM note_meta note
          WHERE note.folder_id = ? AND note.deleted_at IS NULL
            AND EXISTS (SELECT 1 FROM search_item item
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
      await this.attachFolderProjection(store, notes);
      return notes;
    } catch (e) {
      throw new Error(`searchNotes failed: ${JSON.stringify(e)}`);
    }
  }

  // Original dk9.FAVORITES (x17 merged favorite=1), newest edit first like
  // the ALL_NOTES projection (gb6.c0 date field = updatedAt).
  async getFavoriteNotes(): Promise<NoteMeta[]> {
    const store: relationalStore.RdbStore = this.db.getStore();
    const predicates = new relationalStore.RdbPredicates('note_meta');
    predicates.equalTo('favorite', 1);
    predicates.isNull('deleted_at');
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
      await this.attachFolderProjection(store, notes);
      return notes;
    } catch (e) {
      throw new Error(`getFavoriteNotes failed: ${JSON.stringify(e)}`);
    }
  }

  // Original dk9.RECENT: mk9 sorts by apb.F (lastOpened, falling back to the
  // note timestamp) descending and takes the top 10 (au1.N1(..., 10)).
  async getRecentNotes(): Promise<NoteMeta[]> {
    const store: relationalStore.RdbStore = this.db.getStore();
    try {
      const resultSet = await store.querySql(
        `SELECT * FROM note_meta WHERE deleted_at IS NULL
         ORDER BY last_opened DESC, updated_at DESC LIMIT 10`, []);
      const notes: NoteMeta[] = [];
      try {
        while (resultSet.goToNextRow()) {
          notes.push(this.rowToNote(resultSet));
        }
      } finally {
        resultSet.close();
      }
      await this.attachFolderProjection(store, notes);
      return notes;
    } catch (e) {
      throw new Error(`getRecentNotes failed: ${JSON.stringify(e)}`);
    }
  }

  // Original dk9.UNFILED: notes whose subjectId/folder is unset.
  async getUnfiledNotes(): Promise<NoteMeta[]> {
    const store: relationalStore.RdbStore = this.db.getStore();
    const predicates = new relationalStore.RdbPredicates('note_meta');
    predicates.isNull('folder_id');
    predicates.isNull('deleted_at');
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
      await this.attachFolderProjection(store, notes);
      return notes;
    } catch (e) {
      throw new Error(`getUnfiledNotes failed: ${JSON.stringify(e)}`);
    }
  }

  async searchNotesInSection(query: string, section: LibrarySection): Promise<NoteMeta[]> {
    if (section === LibrarySection.ALL_NOTES) {
      return this.searchNotes(query, null);
    }
    const foldedQuery: string = foldSearchText(query).trim();
    if (foldedQuery.length === 0) {
      if (section === LibrarySection.FAVORITES) {
        return this.getFavoriteNotes();
      }
      return section === LibrarySection.RECENT ? this.getRecentNotes() :
        this.getUnfiledNotes();
    }
    const escapedPattern: string = `%${escapeSearchLike(foldedQuery)}%`;
    const store: relationalStore.RdbStore = this.db.getStore();
    try {
      let resultSet: relationalStore.ResultSet;
      if (section === LibrarySection.FAVORITES) {
        resultSet = await store.querySql(`SELECT note.* FROM note_meta note
          WHERE note.deleted_at IS NULL AND note.favorite = 1
            AND EXISTS (SELECT 1 FROM search_item item
              WHERE item.note_id = note.id AND item.folded_text LIKE ? ESCAPE '\\')
          ORDER BY note.updated_at DESC`, [escapedPattern]);
      } else if (section === LibrarySection.UNFILED) {
        resultSet = await store.querySql(`SELECT note.* FROM note_meta note
          WHERE note.deleted_at IS NULL AND note.folder_id IS NULL
            AND EXISTS (SELECT 1 FROM search_item item
              WHERE item.note_id = note.id AND item.folded_text LIKE ? ESCAPE '\\')
          ORDER BY note.updated_at DESC`, [escapedPattern]);
      } else {
        resultSet = await store.querySql(`SELECT note.* FROM note_meta note
          WHERE note.deleted_at IS NULL
            AND EXISTS (SELECT 1 FROM search_item item
              WHERE item.note_id = note.id AND item.folded_text LIKE ? ESCAPE '\\')
          ORDER BY note.last_opened DESC, note.updated_at DESC LIMIT 10`, [escapedPattern]);
      }
      const notes: NoteMeta[] = [];
      try {
        while (resultSet.goToNextRow()) {
          notes.push(this.rowToNote(resultSet));
        }
      } finally {
        resultSet.close();
      }
      await this.attachFolderProjection(store, notes);
      return notes;
    } catch (e) {
      throw new Error(`searchNotesInSection failed: ${JSON.stringify(e)}`);
    }
  }

  // Original setFavorite → modifyNote{isFavorited}: a partial metadata update
  // that must not touch createdAt/updatedAt (x17 ClientPivot keeps them).
  async setNoteFavorite(noteId: string, favorite: boolean): Promise<NoteMeta> {
    return libraryMetadataMutationMutex.runExclusive(async (): Promise<NoteMeta> => {
      const store: relationalStore.RdbStore = this.db.getStore();
      await store.beginTransaction();
      try {
        const bucket: relationalStore.ValuesBucket = { 'favorite': favorite ? 1 : 0 };
        const predicates = new relationalStore.RdbPredicates('note_meta');
        predicates.equalTo('id', noteId);
        const updated: number = await store.update(bucket, predicates);
        if (updated !== 1) {
          throw new Error(`expected to update one note, updated ${updated}`);
        }
        const note: NoteMeta | null = await this.getNote(noteId);
        if (note === null) {
          throw new Error('favorited note does not exist');
        }
        await store.commit();
        return note;
      } catch (e) {
        await store.rollBack();
        throw new Error(`setNoteFavorite failed: ${JSON.stringify(e)}`);
      }
    });
  }

  // Original setLastOpened partial update: powers the dk9.RECENT section
  // without touching createdAt/updatedAt.
  async touchNoteLastOpened(noteId: string, lastOpened: number): Promise<void> {
    await libraryMetadataMutationMutex.runExclusive(async (): Promise<void> => {
      const store: relationalStore.RdbStore = this.db.getStore();
      const bucket: relationalStore.ValuesBucket = { 'last_opened': lastOpened };
      const predicates = new relationalStore.RdbPredicates('note_meta');
      predicates.equalTo('id', noteId);
      await store.update(bucket, predicates);
    }).catch((e: Error) => {
      throw new Error(`touchNoteLastOpened failed: ${JSON.stringify(e)}`);
    });
  }

  // Recently Deleted projection: original lists ClientPivot rows whose
  // deleteDeletedAt is set, newest first.
  async getTrashedNotes(): Promise<NoteMeta[]> {
    const store: relationalStore.RdbStore = this.db.getStore();
    const predicates = new relationalStore.RdbPredicates('note_meta');
    predicates.isNotNull('deleted_at');
    predicates.orderByDesc('deleted_at');
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
      await this.attachFolderProjection(store, notes);
      return notes;
    } catch (e) {
      throw new Error(`getTrashedNotes failed: ${JSON.stringify(e)}`);
    }
  }

  // Original leb.java: clears any UNDELETE row then upserts DELETE with
  // deletedAt=now. The local-only equivalent keeps all note rows and only
  // stamps deleted_at, so restore is a single UPDATE.
  async trashNote(noteId: string, deletedAt: number): Promise<void> {
    await libraryMetadataMutationMutex.runExclusive(async (): Promise<void> => {
      const store: relationalStore.RdbStore = this.db.getStore();
      const predicates = new relationalStore.RdbPredicates('note_meta');
      predicates.equalTo('id', noteId);
      const bucket: relationalStore.ValuesBucket = { 'deleted_at': deletedAt };
      try {
        const updated: number = await store.update(bucket, predicates);
        if (updated !== 1) {
          throw new Error(`expected to trash one note, updated ${updated}`);
        }
      } catch (e) {
        throw new Error(`trashNote failed: ${JSON.stringify(e)}`);
      }
    });
  }

  // Original restore removes the queued DELETE row (tp1: DELETE ... WHERE
  // id=? AND type != 'PERMANENTLY_DELETE'), which is exactly deleted_at=NULL.
  async restoreNote(noteId: string): Promise<void> {
    await libraryMetadataMutationMutex.runExclusive(async (): Promise<void> => {
      const store: relationalStore.RdbStore = this.db.getStore();
      const predicates = new relationalStore.RdbPredicates('note_meta');
      predicates.equalTo('id', noteId);
      const bucket: relationalStore.ValuesBucket = { 'deleted_at': null };
      try {
        const updated: number = await store.update(bucket, predicates);
        if (updated !== 1) {
          throw new Error(`expected to restore one note, updated ${updated}`);
        }
      } catch (e) {
        throw new Error(`restoreNote failed: ${JSON.stringify(e)}`);
      }
    });
  }

  // Original Recently Deleted rule: notes stay recoverable for 30 days, then
  // are permanently deleted. Runs on library load so expiry is guaranteed
  // even without a background worker.
  async purgeExpiredTrash(now: number): Promise<number> {
    const cutoff: number = now - TRASH_RETENTION_MS;
    const store: relationalStore.RdbStore = this.db.getStore();
    const expiredIds: string[] = [];
    try {
      const rows = await store.querySql(`SELECT id FROM note_meta
        WHERE deleted_at IS NOT NULL AND deleted_at <= ?`, [cutoff]);
      try {
        while (rows.goToNextRow()) {
          expiredIds.push(rows.getString(rows.getColumnIndex('id')));
        }
      } finally {
        rows.close();
      }
    } catch (e) {
      throw new Error(`purgeExpiredTrash scan failed: ${JSON.stringify(e)}`);
    }
    for (let i: number = 0; i < expiredIds.length; i++) {
      await this.deleteNote(expiredIds[i]);
    }
    return expiredIds.length;
  }

  async updateNote(note: NoteMeta): Promise<void> {
    // The library model exposes the non-null materialized projection; an empty
    // title therefore means the original nullable register is explicitly null.
    await this.updateNoteTitle(note.id, note.title.length === 0 ? null : note.title);
  }

  // Original d5j Rename (library context menu): title-only edit through the
  // SET_TITLE op path; an empty title is the original nullable-register null.
  async renameNote(noteId: string, title: string): Promise<void> {
    await this.updateNoteTitle(noteId, title.length === 0 ? null : title);
  }

  async updateNoteTitle(noteId: string, title: string | null, selectedPageId?: string,
    history?: HistoryMetadata): Promise<PersistedOriginalNoteTitle> {
    return libraryMetadataMutationMutex.runExclusive(async (): Promise<PersistedOriginalNoteTitle> => {
      const store: relationalStore.RdbStore = this.db.getStore();
      await store.beginTransaction();
      try {
        // Title, its LWW winner, search materialization, upload operation and optional
        // durable history companion must commit as one original SET_METADATA transaction.
        const persisted: PersistedOriginalNoteTitle = await persistOriginalNoteTitle(
          store, noteId, title, selectedPageId, history);
        await store.commit();
        return persisted;
      } catch (e) {
        await store.rollBack();
        throw new Error(`updateNoteTitle failed: ${JSON.stringify(e)}`);
      }
    });
  }

  // Local original SET_METADATA preference registers are kept behind the same
  // library mutex and transaction boundary as title/background mutations.
  async updateOriginalNoteMetadata(noteId: string,
    patch: OriginalNoteMetadataPatch, selectedPageId?: string,
    history?: HistoryMetadata, expectedSource?: NoteMetadataHistoryState):
    Promise<PersistedOriginalNoteMetadata> {
    return libraryMetadataMutationMutex.runExclusive(
      async (): Promise<PersistedOriginalNoteMetadata> => {
        const store: relationalStore.RdbStore = this.db.getStore();
        await store.beginTransaction();
        try {
          const persisted: PersistedOriginalNoteMetadata = await persistOriginalNoteMetadata(
            store, noteId, patch, selectedPageId, history, expectedSource);
          await store.commit();
          return persisted;
        } catch (e) {
          await store.rollBack();
          throw new Error(`updateOriginalNoteMetadata failed: ${JSON.stringify(e)}`);
        }
      });
  }

  // recordTombstone=false is only for import rollback: a note that never became
  // user-visible must not poison its id in permanently_deleted_note.
  async deleteNote(noteId: string, recordTombstone: boolean = true): Promise<void> {
    await assetMutationMutex.runExclusive(async (): Promise<void> => {
      const candidateFilesToDelete: string[] = [];
      const filesToDetach: string[] = [];
      const detachedFiles: string[] = [];
      const filesRoot: string = this.db.getFilesDir();
      await libraryMetadataMutationMutex.runExclusive(async (): Promise<void> => {
        const store: relationalStore.RdbStore = this.db.getStore();
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
                candidateFilesToDelete.push(reference.localPath);
              }
            } else {
              const assetBucket: relationalStore.ValuesBucket = {
                'note_ids': JSON.stringify(remainingNoteIds),
              };
              await store.update(assetBucket, assetPredicates);
            }
          }
          for (let i: number = 0; i < candidateFilesToDelete.length; i++) {
            const candidatePath: string = candidateFilesToDelete[i];
            if (filesToDetach.indexOf(candidatePath) < 0 &&
              !await isAssetFilePathReferenced(store, candidatePath)) {
              filesToDetach.push(candidatePath);
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
          // A permanently deleted note must not leave index orphans; original
          // removes its index ops inside the same mutation.
          const p5 = new relationalStore.RdbPredicates('search_item');
          p5.equalTo('note_id', noteId);
          await store.delete(p5);
          if (recordTombstone) {
            // Original PermanentlyDeletedNote tombstone: stale rows re-imported
            // later can never resurrect this id.
            const tombstone: relationalStore.ValuesBucket = { 'note_id': noteId };
            await store.insert('permanently_deleted_note', tombstone,
              relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
          }
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
        for (let i: number = 0; i < filesToDetach.length; i++) {
          const detachedPath: string | null = detachAssetFileForDeletion(
            filesToDetach[i], filesRoot);
          if (detachedPath !== null) {
            detachedFiles.push(detachedPath);
          }
        }
      });
      for (let i: number = 0; i < detachedFiles.length; i++) {
        unlinkAssetFile(detachedFiles[i], filesRoot);
      }
      assetAvailabilityHub.forgetNote(noteId);
    });
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
    if (!isOriginalViewportZoom(state.zoom)) {
      throw new Error(`saveViewState invalid zoom: ${state.zoom}`);
    }
    if (!isFiniteViewportScrollOffset(state.scrollOffsetX, state.scrollOffsetY)) {
      throw new Error(`saveViewState invalid scroll offset: ${state.scrollOffsetX},${state.scrollOffsetY}`);
    }
    await databaseWriteMutex.runExclusive(async (): Promise<void> => {
      const store: relationalStore.RdbStore = this.db.getStore();
      const bucket: relationalStore.ValuesBucket = {
        'note_id': state.noteId,
        'zoom': state.zoom,
        'scroll_offset_x': state.scrollOffsetX,
        'scroll_offset_y': state.scrollOffsetY,
        'coordinate_model_version': CURRENT_VIEW_COORDINATE_MODEL_VERSION,
      };
      try {
        await store.insert('note_state', bucket,
          relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
      } catch (e) {
        throw new Error(`saveViewState failed: ${JSON.stringify(e)}`);
      }
    });
  }

  private rowToNote(resultSet: relationalStore.ResultSet): NoteMeta {
    try {
      const folderColumn: number = resultSet.getColumnIndex('folder_id');
      const deletedColumn: number = resultSet.getColumnIndex('deleted_at');
      return {
        id: resultSet.getString(resultSet.getColumnIndex('id')),
        title: resultSet.getString(resultSet.getColumnIndex('title')),
        createdAt: resultSet.getLong(resultSet.getColumnIndex('created_at')),
        updatedAt: resultSet.getLong(resultSet.getColumnIndex('updated_at')),
        favorite: resultSet.getLong(resultSet.getColumnIndex('favorite')) !== 0,
        lastOpened: resultSet.getLong(resultSet.getColumnIndex('last_opened')),
        folderId: resultSet.isColumnNull(folderColumn) ? null : resultSet.getString(folderColumn),
        // Resolved afterwards by attachFolderProjection (w09.g/h parity).
        folderName: null,
        folderColor: null,
        hasRecordings: resultSet.getLong(resultSet.getColumnIndex('has_recordings')) !== 0,
        deletedAt: resultSet.isColumnNull(deletedColumn) ? null : resultSet.getLong(deletedColumn),
      };
    } catch (e) {
      throw new Error('rowToNote failed: ' + JSON.stringify(e));
    }
  }

  // Original w09 merged projection: the library note model carries the folder's
  // name (g) and color (h) so cards can render the folder chip. One batched
  // lookup covers every list path; a deleted folder can never surface because
  // note_meta.folder_id is ON DELETE SET NULL.
  private async attachFolderProjection(store: relationalStore.RdbStore,
    notes: NoteMeta[]): Promise<void> {
    const folderIds: Set<string> = new Set<string>();
    for (const note of notes) {
      if (note.folderId !== null) {
        folderIds.add(note.folderId);
      }
    }
    if (folderIds.size === 0) {
      return;
    }
    const ids: string[] = Array.from(folderIds);
    const placeholders: string = ids.map((): string => '?').join(', ');
    try {
      const resultSet = await store.querySql(
        `SELECT id, name, color FROM folder WHERE id IN (${placeholders})`, ids);
      const projections: Map<string, [string, number]> = new Map<string, [string, number]>();
      try {
        while (resultSet.goToNextRow()) {
          projections.set(resultSet.getString(resultSet.getColumnIndex('id')), [
            resultSet.getString(resultSet.getColumnIndex('name')),
            resultSet.getLong(resultSet.getColumnIndex('color')),
          ]);
        }
      } finally {
        resultSet.close();
      }
      for (const note of notes) {
        const projection: [string, number] | undefined =
          note.folderId === null ? undefined : projections.get(note.folderId);
        note.folderName = projection === undefined ? null : projection[0];
        note.folderColor = projection === undefined ? null : projection[1];
      }
    } catch (e) {
      throw new Error(`attachFolderProjection failed: ${JSON.stringify(e)}`);
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
      folderName: null,
      folderColor: null,
      hasRecordings: hasRecordings,
      deletedAt: null,
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
      'deleted_at': note.deletedAt,
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

  private async resolveDefaultTemplate(): Promise<NoteBackgroundSettings> {
    let selection: OriginalDefaultTemplateSelection = originalFallbackDefaultTemplate();
    if (this.defaultTemplateRepository !== null) {
      try {
        selection = await this.defaultTemplateRepository.getSelectedDefaultTemplate();
      } catch (e) {
        console.warn(`selected default template fallback: ${JSON.stringify(e)}`);
      }
    }
    return originalDefaultTemplateSettings(selection);
  }

  private generateId(): string {
    const timePart: string = Date.now().toString(36);
    const randPart: string = Math.random().toString(36).slice(2, 8);
    return timePart + randPart;
  }
}
