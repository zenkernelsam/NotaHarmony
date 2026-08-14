import { relationalStore } from '@kit.ArkData';
import { NoteMeta } from '../core/model/NoteTypes';
import { DatabaseManager } from './DatabaseManager';
import { libraryMetadataMutationMutex } from './LibraryMetadataMutationMutex';

export const MAX_FOLDER_DEPTH: number = 6;

export interface NoteFolder {
  id: string;
  name: string;
  createdAt: number;
  parentId: string | null;
  siblingOrder: number;
}

export interface FolderMutationResult {
  folders: NoteFolder[];
}

export interface FolderCreateResult extends FolderMutationResult {
  folder: NoteFolder;
}

export interface FolderDeleteResult extends FolderMutationResult {
  deletedFolderIds: string[];
  movedNoteIds: string[];
  notes: NoteMeta[];
}

export interface NoteFolderMoveResult {
  noteId: string;
  folderId: string | null;
}

function sameParent(left: string | null, right: string | null): boolean {
  return left === right;
}

function findFolder(folders: NoteFolder[], folderId: string): NoteFolder | null {
  for (const folder of folders) {
    if (folder.id === folderId) {
      return folder;
    }
  }
  return null;
}

function folderDepth(folders: NoteFolder[], folderId: string): number {
  let depth: number = 1;
  let current: NoteFolder | null = findFolder(folders, folderId);
  const visited: Set<string> = new Set<string>();
  while (current !== null && current.parentId !== null) {
    if (visited.has(current.id)) {
      throw new Error('folder hierarchy contains a cycle');
    }
    visited.add(current.id);
    depth++;
    current = findFolder(folders, current.parentId);
    if (current === null) {
      throw new Error('folder parent does not exist');
    }
  }
  return depth;
}

function subtreeHeightInternal(folders: NoteFolder[], folderId: string, visiting: Set<string>): number {
  if (visiting.has(folderId)) {
    throw new Error('folder hierarchy contains a cycle');
  }
  visiting.add(folderId);
  let height: number = 1;
  for (const folder of folders) {
    if (folder.parentId === folderId) {
      height = Math.max(height, 1 + subtreeHeightInternal(folders, folder.id, visiting));
    }
  }
  visiting.delete(folderId);
  return height;
}

function subtreeHeight(folders: NoteFolder[], folderId: string): number {
  return subtreeHeightInternal(folders, folderId, new Set<string>());
}

export function isFolderInSubtree(folders: NoteFolder[], rootId: string, candidateId: string): boolean {
  if (rootId === candidateId) {
    return true;
  }
  let current: NoteFolder | null = findFolder(folders, candidateId);
  const visited: Set<string> = new Set<string>();
  while (current !== null && current.parentId !== null) {
    if (visited.has(current.id)) {
      return true;
    }
    visited.add(current.id);
    if (current.parentId === rootId) {
      return true;
    }
    current = findFolder(folders, current.parentId);
  }
  return false;
}

// Mirrors 1.0.3 beb.a(): empty, slash/backslash and case-insensitive sibling duplicates are invalid.
export function validateFolderName(folders: NoteFolder[], rawName: string, parentId: string | null,
  excludedFolderId?: string): string {
  const name: string = rawName.trim();
  if (name.length === 0 || name.includes('/') || name.includes('\\')) {
    throw new Error('invalid folder name');
  }
  if (parentId !== null && findFolder(folders, parentId) === null) {
    throw new Error('folder parent does not exist');
  }
  const normalized: string = name.toLowerCase();
  for (const folder of folders) {
    if (folder.id !== excludedFolderId && sameParent(folder.parentId, parentId) &&
      folder.name.toLowerCase() === normalized) {
      throw new Error('a sibling folder already has this name');
    }
  }
  return name;
}

export function validateFolderMove(folders: NoteFolder[], folderId: string,
  newParentId: string | null): void {
  const folder: NoteFolder | null = findFolder(folders, folderId);
  if (folder === null) {
    throw new Error('folder does not exist');
  }
  if (newParentId !== null) {
    if (findFolder(folders, newParentId) === null) {
      throw new Error('folder parent does not exist');
    }
    if (isFolderInSubtree(folders, folderId, newParentId)) {
      throw new Error('cannot move a folder into its own subtree');
    }
  }
  const parentDepth: number = newParentId === null ? 0 : folderDepth(folders, newParentId);
  if (parentDepth + subtreeHeight(folders, folderId) > MAX_FOLDER_DEPTH) {
    throw new Error(`folder depth cannot exceed ${MAX_FOLDER_DEPTH}`);
  }
  validateFolderName(folders, folder.name, newParentId, folderId);
}

export class FolderRepositoryImpl {
  private db: DatabaseManager;

  constructor(db: DatabaseManager) {
    this.db = db;
  }

  async createFolder(name: string, parentId: string | null = null): Promise<FolderCreateResult> {
    return libraryMetadataMutationMutex.runExclusive(async (): Promise<FolderCreateResult> => {
      const store: relationalStore.RdbStore = this.db.getStore();
      await store.beginTransaction();
      try {
        const folders: NoteFolder[] = await this.queryFolders(store);
        const validatedName: string = validateFolderName(folders, name, parentId);
        if (parentId !== null && folderDepth(folders, parentId) >= MAX_FOLDER_DEPTH) {
          throw new Error(`folder depth cannot exceed ${MAX_FOLDER_DEPTH}`);
        }
        const now: number = Date.now();
        const folder: NoteFolder = {
          id: this.generateId(),
          name: validatedName,
          createdAt: now,
          parentId: parentId,
          siblingOrder: this.nextSiblingOrder(folders, parentId),
        };
        const rowId: number = await store.insert('folder', this.folderBucket(folder));
        if (rowId < 0) {
          throw new Error('insert returned an invalid row id');
        }
        const afterCreate: NoteFolder[] = await this.queryFolders(store);
        await this.normalizeSiblingOrders(store, afterCreate, parentId);
        const committedFolders: NoteFolder[] = await this.queryFolders(store);
        const committedFolder: NoteFolder | null = findFolder(committedFolders, folder.id);
        if (committedFolder === null) {
          throw new Error('created folder is missing from the committed snapshot');
        }
        await store.commit();
        return { folder: committedFolder, folders: committedFolders };
      } catch (e) {
        await store.rollBack();
        throw new Error(`createFolder failed: ${JSON.stringify(e)}`);
      }
    });
  }

  async renameFolder(folderId: string, name: string): Promise<FolderMutationResult> {
    return libraryMetadataMutationMutex.runExclusive(async (): Promise<FolderMutationResult> => {
      const store: relationalStore.RdbStore = this.db.getStore();
      await store.beginTransaction();
      try {
        const folders: NoteFolder[] = await this.queryFolders(store);
        const folder: NoteFolder | null = findFolder(folders, folderId);
        if (folder === null) {
          throw new Error('folder does not exist');
        }
        const validatedName: string = validateFolderName(folders, name, folder.parentId, folderId);
        const predicates = new relationalStore.RdbPredicates('folder');
        predicates.equalTo('id', folderId);
        const changed: number = await store.update({ 'name': validatedName }, predicates);
        if (changed === 0) {
          throw new Error('folder does not exist');
        }
        const committedFolders: NoteFolder[] = await this.queryFolders(store);
        await store.commit();
        return { folders: committedFolders };
      } catch (e) {
        await store.rollBack();
        throw new Error(`renameFolder failed: ${JSON.stringify(e)}`);
      }
    });
  }

  async moveFolder(folderId: string, newParentId: string | null): Promise<FolderMutationResult> {
    return libraryMetadataMutationMutex.runExclusive(async (): Promise<FolderMutationResult> => {
      const store: relationalStore.RdbStore = this.db.getStore();
      await store.beginTransaction();
      try {
        const folders: NoteFolder[] = await this.queryFolders(store);
        validateFolderMove(folders, folderId, newParentId);
        const current: NoteFolder | null = findFolder(folders, folderId);
        if (current === null) {
          throw new Error('folder does not exist');
        }
        const oldParentId: string | null = current.parentId;
        const bucket: relationalStore.ValuesBucket = {
          'parent_id': newParentId,
          'sibling_order': this.nextSiblingOrder(folders, newParentId),
        };
        const predicates = new relationalStore.RdbPredicates('folder');
        predicates.equalTo('id', folderId);
        const changed: number = await store.update(bucket, predicates);
        if (changed === 0) {
          throw new Error('folder does not exist');
        }
        const afterMove: NoteFolder[] = await this.queryFolders(store);
        await this.normalizeSiblingOrders(store, afterMove, oldParentId);
        if (!sameParent(oldParentId, newParentId)) {
          await this.normalizeSiblingOrders(store, afterMove, newParentId);
        }
        const committedFolders: NoteFolder[] = await this.queryFolders(store);
        await store.commit();
        return { folders: committedFolders };
      } catch (e) {
        await store.rollBack();
        throw new Error(`moveFolder failed: ${JSON.stringify(e)}`);
      }
    });
  }

  async deleteFolder(folderId: string): Promise<FolderDeleteResult> {
    return libraryMetadataMutationMutex.runExclusive(async (): Promise<FolderDeleteResult> => {
      const store: relationalStore.RdbStore = this.db.getStore();
      await store.beginTransaction();
      try {
        const folders: NoteFolder[] = await this.queryFolders(store);
        if (findFolder(folders, folderId) === null) {
          throw new Error('folder does not exist');
        }
        const deletedFolders: NoteFolder[] = folders.filter((folder: NoteFolder): boolean =>
          isFolderInSubtree(folders, folderId, folder.id));
        const deletedFolderIds: string[] = deletedFolders.map(
          (folder: NoteFolder): string => folder.id);
        const movedNoteIds: string[] = await this.queryNoteIdsInFolders(store, deletedFolderIds);
        // Deleting a parent cascades through child folders at the DB level. Move every
        // note in the full subtree first so nested-folder notes are not deleted by FK cascade.
        for (const deletedFolderId of deletedFolderIds) {
          const noteBucket: relationalStore.ValuesBucket = { 'folder_id': null };
          const notePredicates = new relationalStore.RdbPredicates('note_meta');
          notePredicates.equalTo('folder_id', deletedFolderId);
          await store.update(noteBucket, notePredicates);
        }
        const predicates = new relationalStore.RdbPredicates('folder');
        predicates.equalTo('id', folderId);
        const deleted: number = await store.delete(predicates);
        if (deleted === 0) {
          throw new Error('folder does not exist');
        }
        const remaining: NoteFolder[] = await this.queryFolders(store);
        const affectedParents: Array<string | null> = [];
        for (const folder of deletedFolders) {
          let alreadyAdded: boolean = false;
          for (const parent of affectedParents) {
            if (sameParent(parent, folder.parentId)) {
              alreadyAdded = true;
              break;
            }
          }
          if (!alreadyAdded) {
            affectedParents.push(folder.parentId);
          }
        }
        for (const parent of affectedParents) {
          await this.normalizeSiblingOrders(store, remaining, parent);
        }
        const committedFolders: NoteFolder[] = await this.queryFolders(store);
        const committedNotes: NoteMeta[] = await this.queryAllNotes(store);
        await store.commit();
        return {
          folders: committedFolders,
          deletedFolderIds: deletedFolderIds,
          movedNoteIds: movedNoteIds,
          notes: committedNotes,
        };
      } catch (e) {
        await store.rollBack();
        throw new Error(`deleteFolder failed: ${JSON.stringify(e)}`);
      }
    });
  }

  async getAllFolders(): Promise<NoteFolder[]> {
    try {
      return await this.queryFolders(this.db.getStore());
    } catch (e) {
      throw new Error(`getAllFolders failed: ${JSON.stringify(e)}`);
    }
  }

  async moveNoteToFolder(noteId: string, folderId: string | null): Promise<NoteFolderMoveResult> {
    return libraryMetadataMutationMutex.runExclusive(async (): Promise<NoteFolderMoveResult> => {
      const store: relationalStore.RdbStore = this.db.getStore();
      await store.beginTransaction();
      try {
        // Validate the target and perform the note update under the same writer gate as
        // folder deletion/rename/move, so a target cannot disappear between the checks.
        if (folderId !== null) {
          const folders: NoteFolder[] = await this.queryFolders(store);
          if (findFolder(folders, folderId) === null) {
            throw new Error('folder does not exist');
          }
        }
        const bucket: relationalStore.ValuesBucket = { 'folder_id': folderId };
        const predicates = new relationalStore.RdbPredicates('note_meta');
        predicates.equalTo('id', noteId);
        const changed: number = await store.update(bucket, predicates);
        if (changed === 0) {
          throw new Error('note does not exist');
        }
        await store.commit();
        return { noteId: noteId, folderId: folderId };
      } catch (e) {
        await store.rollBack();
        throw new Error(`moveNoteToFolder failed: ${JSON.stringify(e)}`);
      }
    });
  }

  private async queryFolders(store: relationalStore.RdbStore): Promise<NoteFolder[]> {
    const predicates = new relationalStore.RdbPredicates('folder');
    predicates.orderByAsc('sibling_order');
    predicates.orderByAsc('created_at');
    const resultSet = await store.query(predicates);
    const folders: NoteFolder[] = [];
    try {
      while (resultSet.goToNextRow()) {
        const parentColumn: number = resultSet.getColumnIndex('parent_id');
        folders.push({
          id: resultSet.getString(resultSet.getColumnIndex('id')),
          name: resultSet.getString(resultSet.getColumnIndex('name')),
          createdAt: resultSet.getLong(resultSet.getColumnIndex('created_at')),
          parentId: resultSet.isColumnNull(parentColumn) ? null : resultSet.getString(parentColumn),
          siblingOrder: resultSet.getDouble(resultSet.getColumnIndex('sibling_order')),
        });
      }
    } finally {
      resultSet.close();
    }
    return folders;
  }

  private async queryNoteIdsInFolders(store: relationalStore.RdbStore,
    folderIds: string[]): Promise<string[]> {
    const resultSet = await store.query(new relationalStore.RdbPredicates('note_meta'),
      ['id', 'folder_id']);
    const noteIds: string[] = [];
    try {
      while (resultSet.goToNextRow()) {
        const folderColumn: number = resultSet.getColumnIndex('folder_id');
        if (!resultSet.isColumnNull(folderColumn) && folderIds.indexOf(
          resultSet.getString(folderColumn)) >= 0) {
          noteIds.push(resultSet.getString(resultSet.getColumnIndex('id')));
        }
      }
    } finally {
      resultSet.close();
    }
    return noteIds;
  }

  private async queryAllNotes(store: relationalStore.RdbStore): Promise<NoteMeta[]> {
    const predicates = new relationalStore.RdbPredicates('note_meta');
    predicates.orderByDesc('updated_at');
    const resultSet = await store.query(predicates);
    const notes: NoteMeta[] = [];
    try {
      while (resultSet.goToNextRow()) {
        const folderColumn: number = resultSet.getColumnIndex('folder_id');
        notes.push({
          id: resultSet.getString(resultSet.getColumnIndex('id')),
          title: resultSet.getString(resultSet.getColumnIndex('title')),
          createdAt: resultSet.getLong(resultSet.getColumnIndex('created_at')),
          updatedAt: resultSet.getLong(resultSet.getColumnIndex('updated_at')),
          favorite: resultSet.getLong(resultSet.getColumnIndex('favorite')) !== 0,
          lastOpened: resultSet.getLong(resultSet.getColumnIndex('last_opened')),
          folderId: resultSet.isColumnNull(folderColumn) ? null : resultSet.getString(folderColumn),
          hasRecordings: resultSet.getLong(resultSet.getColumnIndex('has_recordings')) !== 0,
        });
      }
    } finally {
      resultSet.close();
    }
    return notes;
  }

  private nextSiblingOrder(folders: NoteFolder[], parentId: string | null): number {
    let order: number = -1;
    for (const folder of folders) {
      if (sameParent(folder.parentId, parentId)) {
        order = Math.max(order, folder.siblingOrder);
      }
    }
    return order + 1;
  }

  private async normalizeSiblingOrders(store: relationalStore.RdbStore,
    folders: NoteFolder[], parentId: string | null): Promise<void> {
    const siblings: NoteFolder[] = folders.filter((folder: NoteFolder): boolean =>
      sameParent(folder.parentId, parentId));
    siblings.sort((left: NoteFolder, right: NoteFolder): number => {
      if (left.siblingOrder !== right.siblingOrder) {
        return left.siblingOrder - right.siblingOrder;
      }
      if (left.createdAt !== right.createdAt) {
        return left.createdAt - right.createdAt;
      }
      return left.id < right.id ? -1 : left.id > right.id ? 1 : 0;
    });
    for (let index: number = 0; index < siblings.length; index++) {
      if (siblings[index].siblingOrder === index) {
        continue;
      }
      const predicates = new relationalStore.RdbPredicates('folder');
      predicates.equalTo('id', siblings[index].id);
      if (await store.update({ 'sibling_order': index }, predicates) !== 1) {
        throw new Error('folder sibling order update affected an unexpected number of rows');
      }
    }
  }

  private folderBucket(folder: NoteFolder): relationalStore.ValuesBucket {
    return {
      'id': folder.id,
      'name': folder.name,
      'created_at': folder.createdAt,
      'parent_id': folder.parentId,
      'sibling_order': folder.siblingOrder,
    };
  }

  private generateId(): string {
    const timePart: string = Date.now().toString(36);
    const randPart: string = Math.random().toString(36).slice(2, 8);
    return timePart + randPart;
  }
}
