// T-007 Repository 抽象接口（契约 phase-1-data-model.md §3.11，照搬，禁止修改签名）
// 接口定义不 import 任何 @ohos.* / @kit.* 平台模块
import { NoteMeta, NoteViewState, PageInfo } from '../core/model/NoteTypes';
import { ToolState } from '../core/model/BrushTypes';
import { NoteAsset } from '../core/model/AssetTypes';

export interface NoteRepository {
  createNote(title: string, folderId: string | null): Promise<NoteMeta>;
  getNote(noteId: string): Promise<NoteMeta | null>;
  getAllNotes(): Promise<NoteMeta[]>;
  getNotesByFolder(folderId: string): Promise<NoteMeta[]>;
  updateNote(note: NoteMeta): Promise<void>;
  deleteNote(noteId: string): Promise<void>;
  getViewState(noteId: string): Promise<NoteViewState | null>;
  saveViewState(state: NoteViewState): Promise<void>;
}

export interface PageRepository {
  getPages(noteId: string): Promise<PageInfo[]>;
  addPage(noteId: string, page: PageInfo): Promise<void>;
  deletePage(noteId: string, pageId: string): Promise<void>;
  updatePage(page: PageInfo): Promise<void>;
  reorderPages(noteId: string, pageIds: string[]): Promise<void>;
}

export interface ToolRepository {
  getToolStates(ownerId: string): Promise<ToolState[]>;
  saveToolState(state: ToolState): Promise<void>;
}

export interface AssetRepository {
  getAsset(hash: string): Promise<NoteAsset | null>;
  saveAsset(asset: NoteAsset): Promise<void>;
  getAssetsByNote(noteId: string): Promise<NoteAsset[]>;
  deleteAsset(hash: string): Promise<void>;
}
