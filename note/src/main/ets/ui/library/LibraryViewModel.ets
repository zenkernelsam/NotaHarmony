// T-018 资料库状态管理（@Observed）
import { NoteMeta } from '../../core/model/NoteTypes';
import { NoteRepositoryImpl } from '../../data/NoteRepositoryImpl';

@Observed
export class LibraryViewModel {
  notes: NoteMeta[] = [];
  isLoading: boolean = true;
  searchQuery: string = '';
  private repo: NoteRepositoryImpl;

  constructor(repo: NoteRepositoryImpl) {
    this.repo = repo;
  }

  async loadNotes(): Promise<void> {
    this.isLoading = true;
    this.notes = await this.repo.getAllNotes();
    this.isLoading = false;
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
