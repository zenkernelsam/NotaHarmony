// T-017 NoteRepository 实现（relationalStore，全部方法异常安全）
import { relationalStore } from '@kit.ArkData';
import { NoteMeta, NoteViewState } from '../core/model/NoteTypes';
import { NoteRepository } from './RepositoryInterfaces';
import { DatabaseManager } from './DatabaseManager';

export class NoteRepositoryImpl implements NoteRepository {
  private db: DatabaseManager;

  constructor(db: DatabaseManager) {
    this.db = db;
  }

  async createNote(title: string, folderId: string | null): Promise<NoteMeta> {
    const store: relationalStore.RdbStore = this.db.getStore();
    const now: number = Date.now();
    const id: string = this.generateId();
    const bucket: relationalStore.ValuesBucket = {
      'id': id,
      'title': title,
      'created_at': now,
      'updated_at': now,
      'favorite': 0,
      'last_opened': now,
      'folder_id': folderId,
      'has_recordings': 0,
    };
    try {
      await store.insert('note_meta', bucket);
    } catch (e) {
      console.error(`createNote insert failed: ${JSON.stringify(e)}`);
    }
    // 创建默认首页（A4 / PLAIN）
    const pageBucket: relationalStore.ValuesBucket = {
      'page_id': this.generateId(),
      'note_id': id,
      'page_index': 0,
      'size': 1,       // PaperSize.A4
      'template': 0,   // PaperTemplate.PLAIN
      'orientation': 0,
      'width_mm': 210.0,
      'height_mm': 297.0,
    };
    try {
      await store.insert('page_info', pageBucket);
    } catch (e) {
      console.error(`createNote page insert failed: ${JSON.stringify(e)}`);
    }
    return {
      id: id,
      title: title,
      createdAt: now,
      updatedAt: now,
      favorite: false,
      lastOpened: now,
      folderId: folderId,
      hasRecordings: false,
    };
  }

  async getNote(noteId: string): Promise<NoteMeta | null> {
    const store: relationalStore.RdbStore = this.db.getStore();
    const predicates = new relationalStore.RdbPredicates('note_meta');
    predicates.equalTo('id', noteId);
    try {
      const resultSet = await store.query(predicates);
      let note: NoteMeta | null = null;
      if (resultSet.goToNextRow()) {
        note = this.rowToNote(resultSet);
      }
      resultSet.close();
      return note;
    } catch (e) {
      console.error(`getNote failed: ${JSON.stringify(e)}`);
      return null;
    }
  }

  async getAllNotes(): Promise<NoteMeta[]> {
    const store: relationalStore.RdbStore = this.db.getStore();
    const predicates = new relationalStore.RdbPredicates('note_meta');
    predicates.orderByDesc('updated_at');
    try {
      const resultSet = await store.query(predicates);
      const notes: NoteMeta[] = [];
      while (resultSet.goToNextRow()) {
        notes.push(this.rowToNote(resultSet));
      }
      resultSet.close();
      return notes;
    } catch (e) {
      console.error(`getAllNotes failed: ${JSON.stringify(e)}`);
      return [];
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
      while (resultSet.goToNextRow()) {
        notes.push(this.rowToNote(resultSet));
      }
      resultSet.close();
      return notes;
    } catch (e) {
      console.error(`getNotesByFolder failed: ${JSON.stringify(e)}`);
      return [];
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
    try {
      await store.update(bucket, predicates);
    } catch (e) {
      console.error(`updateNote failed: ${JSON.stringify(e)}`);
    }
  }

  async deleteNote(noteId: string): Promise<void> {
    const store: relationalStore.RdbStore = this.db.getStore();
    try {
      const p1 = new relationalStore.RdbPredicates('note_meta');
      p1.equalTo('id', noteId);
      await store.delete(p1);
      const p2 = new relationalStore.RdbPredicates('page_info');
      p2.equalTo('note_id', noteId);
      await store.delete(p2);
      const p3 = new relationalStore.RdbPredicates('client_op');
      p3.equalTo('note_id', noteId);
      await store.delete(p3);
      const p4 = new relationalStore.RdbPredicates('note_state');
      p4.equalTo('note_id', noteId);
      await store.delete(p4);
    } catch (e) {
      console.error(`deleteNote failed: ${JSON.stringify(e)}`);
    }
  }

  async getViewState(noteId: string): Promise<NoteViewState | null> {
    const store: relationalStore.RdbStore = this.db.getStore();
    const predicates = new relationalStore.RdbPredicates('note_state');
    predicates.equalTo('note_id', noteId);
    try {
      const resultSet = await store.query(predicates);
      let state: NoteViewState | null = null;
      if (resultSet.goToNextRow()) {
        state = {
          noteId: resultSet.getString(resultSet.getColumnIndex('note_id')),
          zoom: resultSet.getDouble(resultSet.getColumnIndex('zoom')),
          scrollOffsetX: resultSet.getDouble(resultSet.getColumnIndex('scroll_offset_x')),
          scrollOffsetY: resultSet.getDouble(resultSet.getColumnIndex('scroll_offset_y')),
        };
      }
      resultSet.close();
      return state;
    } catch (e) {
      console.error(`getViewState failed: ${JSON.stringify(e)}`);
      return null;
    }
  }

  async saveViewState(state: NoteViewState): Promise<void> {
    const store: relationalStore.RdbStore = this.db.getStore();
    const bucket: relationalStore.ValuesBucket = {
      'note_id': state.noteId,
      'zoom': state.zoom,
      'scroll_offset_x': state.scrollOffsetX,
      'scroll_offset_y': state.scrollOffsetY,
    };
    try {
      await store.insert('note_state', bucket, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
    } catch (e) {
      console.error(`saveViewState failed: ${JSON.stringify(e)}`);
    }
  }

  private rowToNote(resultSet: relationalStore.ResultSet): NoteMeta {
    try {
      return {
        id: resultSet.getString(resultSet.getColumnIndex('id')),
        title: resultSet.getString(resultSet.getColumnIndex('title')),
        createdAt: resultSet.getLong(resultSet.getColumnIndex('created_at')),
        updatedAt: resultSet.getLong(resultSet.getColumnIndex('updated_at')),
        favorite: resultSet.getLong(resultSet.getColumnIndex('favorite')) !== 0,
        lastOpened: resultSet.getLong(resultSet.getColumnIndex('last_opened')),
        folderId: resultSet.getString(resultSet.getColumnIndex('folder_id')),
        hasRecordings: resultSet.getLong(resultSet.getColumnIndex('has_recordings')) !== 0,
      };
    } catch (e) {
      throw new Error('rowToNote failed: ' + JSON.stringify(e));
    }
  }

  private generateId(): string {
    const timePart: string = Date.now().toString(36);
    const randPart: string = Math.random().toString(36).slice(2, 8);
    return timePart + randPart;
  }
}
