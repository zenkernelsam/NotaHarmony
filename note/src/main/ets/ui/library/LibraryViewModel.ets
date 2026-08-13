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
  sortMode: NoteSortMode = NoteSortMode.UPDATED;
  // T-039：当前浏览文件夹（null=全部笔记）
  currentFolderId: string | null = null;
  private repo: NoteRepository;
  private loadGeneration: number = 0;
  private mutationGeneration: number = 0;
  private mutationChain: Promise<void> = Promise.resolve();

  constructor(repo: NoteRepository) {
    this.repo = repo;
  }

  async loadNotes(query: string): Promise<void> {
    const generation: number = ++this.loadGeneration;
    this.isLoading = true;
    this.loadError = '';
    try {
      while (generation === this.loadGeneration) {
        const mutationGeneration: number = this.mutationGeneration;
        const folderId: string | null = this.currentFolderId;
        let loaded: NoteMeta[];
        try {
          if (query.trim().length > 0) {
            loaded = await this.repo.searchNotes(query, folderId);
          } else if (folderId === null) {
            loaded = await this.repo.getAllNotes();
          } else {
            loaded = await this.repo.getNotesByFolder(folderId);
          }
        } catch (e) {
          if (generation !== this.loadGeneration) {
            return;
          }
          if (mutationGeneration !== this.mutationGeneration) {
            continue;
          }
          const error: string = `loadNotes failed: ${JSON.stringify(e)}`;
          this.loadError = error;
          throw new Error(error);
        }
        if (generation !== this.loadGeneration) {
          return;
        }
        if (mutationGeneration !== this.mutationGeneration) {
          continue;
        }
        this.notes = loaded;
        this.applySort();
        return;
      }
    } finally {
      if (generation === this.loadGeneration) {
        this.isLoading = false;
      }
    }
  }

  // T-039：切换浏览文件夹并刷新
  async setFolder(folderId: string | null, query: string): Promise<void> {
    const previousFolderId: string | null = this.currentFolderId;
    this.currentFolderId = folderId;
    try {
      await this.loadNotes(query);
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
    await this.loadNotes(query);
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
  async createNote(query: string): Promise<string> {
    const folderId: string | null = this.currentFolderId;
    const viewGeneration: number = this.loadGeneration;
    return this.enqueueMutation(async (): Promise<string> => {
      const note: NoteMeta = await this.repo.createNote('Untitled Note', folderId);
      this.mutationGeneration++;
      if (viewGeneration === this.loadGeneration && this.currentFolderId === folderId &&
        this.createdNoteMatchesQuery(note, query)) {
        const next: NoteMeta[] = this.notes.filter((item: NoteMeta) => item.id !== note.id);
        next.push(note);
        this.notes = next;
        this.applySort();
      }
      return note.id;
    });
  }

  async deleteNote(noteId: string): Promise<void> {
    await this.enqueueMutation(async (): Promise<void> => {
      await this.repo.deleteNote(noteId);
      this.removeVisibleNote(noteId);
    });
  }

  private removeVisibleNote(noteId: string): void {
    this.mutationGeneration++;
    this.notes = this.notes.filter((note: NoteMeta) => note.id !== noteId);
  }

  private createdNoteMatchesQuery(note: NoteMeta, query: string): boolean {
    const foldedQuery: string = query.trim().toLowerCase();
    return foldedQuery.length === 0 || note.title.toLowerCase().includes(foldedQuery);
  }

  // Search, folder and sort are resolved into one observable list by loadNotes().
  getFilteredNotes(): NoteMeta[] {
    return this.notes;
  }

  private enqueueMutation<T>(operation: () => Promise<T>): Promise<T> {
    const next: Promise<T> = this.mutationChain.then(operation);
    this.mutationChain = next.then((): void => {
    }, (): void => {
    });
    return next;
  }
}
