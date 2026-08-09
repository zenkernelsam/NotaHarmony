// T-018 资料库状态管理（@Observed；T-035 增加排序）
import { NoteMeta } from '../../core/model/NoteTypes';
import { NoteRepository } from '../../data/RepositoryInterfaces';

// 排序模式（T-035）
export enum NoteSortMode {
  UPDATED = 0,   // 最近修改（默认）
  CREATED = 1,   // 最近创建
  TITLE = 2,     // 标题
}

@Observed
export class LibraryViewModel {
  notes: NoteMeta[] = [];
  isLoading: boolean = true;
  loadError: string = '';
  searchQuery: string = '';
  sortMode: NoteSortMode = NoteSortMode.UPDATED;
  // T-039：当前浏览文件夹（null=全部笔记）
  currentFolderId: string | null = null;
  private repo: NoteRepository;
  private loadGeneration: number = 0;

  constructor(repo: NoteRepository) {
    this.repo = repo;
  }

  async loadNotes(): Promise<void> {
    const generation: number = ++this.loadGeneration;
    this.isLoading = true;
    this.loadError = '';
    try {
      let loaded: NoteMeta[];
      if (this.searchQuery.trim().length > 0) {
        loaded = await this.repo.searchNotes(this.searchQuery, this.currentFolderId);
      } else if (this.currentFolderId === null) {
        loaded = await this.repo.getAllNotes();
      } else {
        loaded = await this.repo.getNotesByFolder(this.currentFolderId);
      }
      if (generation === this.loadGeneration) {
        this.notes = loaded;
        this.applySort();
      }
    } catch (e) {
      const error: string = `loadNotes failed: ${JSON.stringify(e)}`;
      if (generation !== this.loadGeneration) {
        return;
      }
      this.loadError = error;
      throw new Error(error);
    } finally {
      if (generation === this.loadGeneration) {
        this.isLoading = false;
      }
    }
  }

  // T-039：切换浏览文件夹并刷新
  async setFolder(folderId: string | null): Promise<void> {
    const previousFolderId: string | null = this.currentFolderId;
    this.currentFolderId = folderId;
    try {
      await this.loadNotes();
    } catch (e) {
      this.currentFolderId = previousFolderId;
      throw new Error(`setFolder failed: ${JSON.stringify(e)}`);
    }
  }

  // 设置排序模式并刷新
  setSortMode(mode: NoteSortMode): void {
    this.sortMode = mode;
    this.applySort();
  }

  async setSearchQuery(query: string): Promise<void> {
    this.searchQuery = query;
    await this.loadNotes();
  }

  // 按当前模式排序。
  private applySort(): void {
    const sorted: NoteMeta[] = this.notes.slice();
    if (this.sortMode === NoteSortMode.UPDATED) {
      sorted.sort((a: NoteMeta, b: NoteMeta) => b.updatedAt - a.updatedAt);
    } else if (this.sortMode === NoteSortMode.CREATED) {
      sorted.sort((a: NoteMeta, b: NoteMeta) => b.createdAt - a.createdAt);
    } else if (this.sortMode === NoteSortMode.TITLE) {
      sorted.sort((a: NoteMeta, b: NoteMeta) => a.title.localeCompare(b.title));
    }
    this.notes = sorted;
  }

  // 创建并返回 noteId
  async createNote(): Promise<string> {
    const note: NoteMeta = await this.repo.createNote('Untitled Note', this.currentFolderId);
    await this.loadNotes();
    return note.id;
  }

  async deleteNote(noteId: string): Promise<void> {
    await this.repo.deleteNote(noteId);
    await this.loadNotes();
  }

  // Search, folder and sort are resolved into one observable list by loadNotes().
  getFilteredNotes(): NoteMeta[] {
    return this.notes;
  }
}
