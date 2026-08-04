// T-018 资料库状态管理（@Observed；T-035 增加排序）
import { NoteMeta } from '../../core/model/NoteTypes';
import { NoteRepositoryImpl } from '../../data/NoteRepositoryImpl';

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
  searchQuery: string = '';
  sortMode: NoteSortMode = NoteSortMode.UPDATED;
  // T-039：当前浏览文件夹（null=全部笔记）
  currentFolderId: string | null = null;
  private repo: NoteRepositoryImpl;

  constructor(repo: NoteRepositoryImpl) {
    this.repo = repo;
  }

  async loadNotes(): Promise<void> {
    this.isLoading = true;
    if (this.currentFolderId === null) {
      this.notes = await this.repo.getAllNotes();
    } else {
      this.notes = await this.repo.getNotesByFolder(this.currentFolderId);
    }
    this.applySort();
    this.isLoading = false;
  }

  // T-039：切换浏览文件夹并刷新
  setFolder(folderId: string | null): void {
    this.currentFolderId = folderId;
    this.loadNotes();
  }

  // 设置排序模式并刷新
  setSortMode(mode: NoteSortMode): void {
    this.sortMode = mode;
    this.applySort();
  }

  // 按当前模式排序（UPDATED 已由 repo 按 updatedAt DESC 返回）
  private applySort(): void {
    const sorted: NoteMeta[] = this.notes.slice();
    if (this.sortMode === NoteSortMode.CREATED) {
      sorted.sort((a: NoteMeta, b: NoteMeta) => b.createdAt - a.createdAt);
    } else if (this.sortMode === NoteSortMode.TITLE) {
      sorted.sort((a: NoteMeta, b: NoteMeta) => a.title.localeCompare(b.title));
    }
    // UPDATED：repo 已按 updatedAt DESC（默认保持）
    if (this.sortMode !== NoteSortMode.UPDATED) {
      this.notes = sorted;
    }
  }

  // 创建并返回 noteId
  async createNote(): Promise<string> {
    const note: NoteMeta = await this.repo.createNote('Untitled Note', null);
    await this.loadNotes();
    return note.id;
  }

  async deleteNote(noteId: string): Promise<void> {
    await this.repo.deleteNote(noteId);
    await this.loadNotes();
  }

  // 按搜索词过滤
  getFilteredNotes(): NoteMeta[] {
    if (this.searchQuery === '') {
      return this.notes;
    }
    const query: string = this.searchQuery.toLowerCase();
    const filtered: NoteMeta[] = [];
    for (const n of this.notes) {
      if (n.title.toLowerCase().includes(query)) {
        filtered.push(n);
      }
    }
    return filtered;
  }
}
