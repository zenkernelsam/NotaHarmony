// T-007 Repository 抽象接口（契约 phase-1-data-model.md §3.11，照搬，禁止修改签名）
// 接口定义不 import 任何 @ohos.* / @kit.* 平台模块
import { NoteMeta, NoteViewState, PageInfo, PaperTemplate } from '../core/model/NoteTypes';
import { EditorToolboxState, EditorTray, ToolState } from '../core/model/BrushTypes';
import { NoteAsset } from '../core/model/AssetTypes';

// Original dk9 library section ordinals (ALL_NOTES/RECENT/FAVORITES/UNFILED).
export enum LibrarySection {
  ALL_NOTES = 0,
  RECENT = 1,
  FAVORITES = 2,
  UNFILED = 3,
}

export interface NoteRepository {
  // Original cd case 0 "Templates" creation row: an explicit PaperTemplate
  // override replaces the resolved default template for the new note.
  createNote(title: string, folderId: string | null,
    templateOverride?: PaperTemplate): Promise<NoteMeta>;
  getNote(noteId: string): Promise<NoteMeta | null>;
  getAllNotes(): Promise<NoteMeta[]>;
  getNotesByFolder(folderId: string): Promise<NoteMeta[]>;
  searchNotes(query: string, folderId: string | null): Promise<NoteMeta[]>;
  // Original dk9 section queries (mk9/pk9): FAVORITES filters isFavorited,
  // UNFILED filters subjectId IS NULL, RECENT sorts lastOpened desc top 10.
  getFavoriteNotes(): Promise<NoteMeta[]>;
  getRecentNotes(): Promise<NoteMeta[]>;
  getUnfiledNotes(): Promise<NoteMeta[]>;
  // searchNotes scoped to a dk9 section (applies when no folder is selected).
  searchNotesInSection(query: string, section: LibrarySection): Promise<NoteMeta[]>;
  // Original modifyNote{isFavorited} partial update: flips favorite without
  // touching createdAt/updatedAt (x17 ClientPivot keeps snm.updatedAt).
  setNoteFavorite(noteId: string, favorite: boolean): Promise<NoteMeta>;
  // Original setLastOpened partial update powering the RECENT section.
  touchNoteLastOpened(noteId: string, lastOpened: number): Promise<void>;
  // Original d5j Rename: title-only partial edit routed through the original
  // SET_TITLE op path (updateNoteTitle).
  renameNote(noteId: string, title: string): Promise<void>;
  // Original flc SearchIndexingState.neverIndexedNotes parity: notes whose
  // save path never produced a search_item row are invisible to search and
  // surface in the original's unindexed-notes UI (elc.a/n32 learn-more).
  countUnindexedNotes(): Promise<number>;
  updateNote(note: NoteMeta): Promise<void>;
  deleteNote(noteId: string): Promise<void>;
  getTrashedNotes(): Promise<NoteMeta[]>;
  trashNote(noteId: string, deletedAt: number): Promise<void>;
  restoreNote(noteId: string): Promise<void>;
  purgeExpiredTrash(now: number): Promise<number>;
  getViewState(noteId: string): Promise<NoteViewState | null>;
  saveViewState(state: NoteViewState): Promise<void>;
}

export interface PageRepository {
  getPages(noteId: string): Promise<PageInfo[]>;
  addPage(noteId: string, page: PageInfo): Promise<PageInfo>;
  deletePage(noteId: string, pageId: string): Promise<void>;
  updatePage(page: PageInfo): Promise<void>;
  reorderPages(noteId: string, pageIds: string[], movedPageId?: string): Promise<void>;
  // Original wz9.bookmarkedRegister parity (oz9 UNBOOKMARKED/BOOKMARKED).
  setPageBookmarked(noteId: string, pageId: string, bookmarked: boolean): Promise<PageInfo>;
}

export interface ToolRepository {
  getToolStates(ownerId: string): Promise<ToolState[]>;
  saveToolState(state: ToolState): Promise<void>;
  saveToolStates(states: ToolState[]): Promise<void>;
  deleteToolState(toolId: string): Promise<void>;
  getToolboxState(ownerId: string): Promise<EditorToolboxState | null>;
  saveToolboxState(state: EditorToolboxState): Promise<void>;
  // Original tray model parity (e47 TrayEntity / cgf ordinals / zff.a mapping).
  getTrays(ownerId: string): Promise<EditorTray[]>;
  // gr7/ba8 parity: seed Primary/Secondary/Hidden trays once per owner.
  ensureTrays(ownerId: string): Promise<void>;
  // i8f.g parity: tool selection rewrites the owning tray's lastUsedToolId.
  setTrayLastUsedTool(trayType: number, ownerId: string, toolId: string): Promise<void>;
  // i8f.a parity: move a tool into a destination tray at a clamped index,
  // reindexing the source and destination trays in one transaction.
  moveToolToTray(toolId: string, destTrayType: number, insertIndex: number): Promise<void>;
  // Duplicate parity: insert a new row at state.trayIndex in its tray,
  // shifting later rows up in one transaction.
  insertToolStateAt(state: ToolState): Promise<void>;
  // d8f + yne(18) parity: wipe the owner's tool rows for reset-to-default.
  deleteAllToolStates(ownerId: string): Promise<void>;
  // Original FavoriteColorWellEntity / WidthSizeWellEntity / RecentColorWellEntity parity.
  getFavoriteColors(toolType: number): Promise<number[]>;
  setFavoriteColor(toolType: number, trayIndex: number, color: number): Promise<void>;
  removeFavoriteColor(toolType: number, trayIndex: number): Promise<void>;
  getWidthWells(toolType: number): Promise<number[]>;
  setWidthWell(toolType: number, trayIndex: number, width: number): Promise<void>;
  removeWidthWell(toolType: number, trayIndex: number): Promise<void>;
  getRecentColors(): Promise<number[]>;
  recordRecentColor(color: number): Promise<void>;
  seedDefaultToolWells(): Promise<void>;
}

export interface AssetRepository {
  getAsset(hash: string): Promise<NoteAsset | null>;
  saveAsset(asset: NoteAsset): Promise<void>;
  getAssetsByNote(noteId: string): Promise<NoteAsset[]>;
  deleteAsset(hash: string): Promise<void>;
}
