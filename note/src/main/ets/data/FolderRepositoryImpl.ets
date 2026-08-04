// T-039 文件夹仓储（folder 表 CRUD）
import { relationalStore } from '@kit.ArkData';
import { DatabaseManager } from './DatabaseManager';

export interface NoteFolder {
  id: string;
  name: string;
  createdAt: number;
}

export class FolderRepositoryImpl {
  private db: DatabaseManager;

  constructor(db: DatabaseManager) {
    this.db = db;
  }

  async createFolder(name: string): Promise<NoteFolder> {
    const store: relationalStore.RdbStore = this.db.getStore();
    const now: number = Date.now();
    const id: string = this.generateId();
    const bucket: relationalStore.ValuesBucket = {
      'id': id,
      'name': name,
      'created_at': now,
    };
    try {
      await store.insert('folder', bucket);
    } catch (e) {
      console.error(`createFolder failed: ${JSON.stringify(e)}`);
    }
    return { id: id, name: name, createdAt: now };
  }

  async renameFolder(folderId: string, name: string): Promise<void> {
    const store: relationalStore.RdbStore = this.db.getStore();
    const bucket: relationalStore.ValuesBucket = { 'name': name };
    const predicates = new relationalStore.RdbPredicates('folder');
    predicates.equalTo('id', folderId);
    try {
      await store.update(bucket, predicates);
    } catch (e) {
      console.error(`renameFolder failed: ${JSON.stringify(e)}`);
    }
  }

  // 删除文件夹（笔记 folder_id 置空由调用方处理——回根目录不删笔记）
  async deleteFolder(folderId: string): Promise<void> {
    const store: relationalStore.RdbStore = this.db.getStore();
    try {
      const predicates = new relationalStore.RdbPredicates('folder');
      predicates.equalTo('id', folderId);
      await store.delete(predicates);
    } catch (e) {
      console.error(`deleteFolder failed: ${JSON.stringify(e)}`);
    }
  }

  async getAllFolders(): Promise<NoteFolder[]> {
    const store: relationalStore.RdbStore = this.db.getStore();
    const predicates = new relationalStore.RdbPredicates('folder');
    predicates.orderByAsc('created_at');
    try {
      const resultSet = await store.query(predicates);
      const folders: NoteFolder[] = [];
      while (resultSet.goToNextRow()) {
        folders.push({
          id: resultSet.getString(resultSet.getColumnIndex('id')),
          name: resultSet.getString(resultSet.getColumnIndex('name')),
          createdAt: resultSet.getLong(resultSet.getColumnIndex('created_at')),
        });
      }
      resultSet.close();
      return folders;
    } catch (e) {
      console.error(`getAllFolders failed: ${JSON.stringify(e)}`);
      return [];
    }
  }

  // 移动笔记到文件夹（folderId 为 null 表示根目录）
  async moveNoteToFolder(noteId: string, folderId: string | null): Promise<void> {
    const store: relationalStore.RdbStore = this.db.getStore();
    const bucket: relationalStore.ValuesBucket = { 'folder_id': folderId };
    const predicates = new relationalStore.RdbPredicates('note_meta');
    predicates.equalTo('id', noteId);
    try {
      await store.update(bucket, predicates);
    } catch (e) {
      console.error(`moveNoteToFolder failed: ${JSON.stringify(e)}`);
    }
  }

  private generateId(): string {
    const timePart: string = Date.now().toString(36);
    const randPart: string = Math.random().toString(36).slice(2, 8);
    return timePart + randPart;
  }
}
