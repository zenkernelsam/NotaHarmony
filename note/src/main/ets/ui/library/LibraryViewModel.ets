// T-018 资料库状态管理（@Observed；T-035 增加排序）
import { NoteMeta, PaperTemplate } from '../../core/model/NoteTypes';
import { ORIGINAL_NOTE_DEFAULT_TITLE } from '../../core/model/OriginalNoteTitlePolicy';
import { LibrarySection, NoteRepository } from '../../data/RepositoryInterfaces';

export { LibrarySection }

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
  // Original je7 (z97 default "DESCENDING"); pk9.s sorts the field
  // ascending first, then reverses when the direction is descending.
  sortDescending: boolean = true;
  // T-039：当前浏览文件夹（null=全部笔记）
  currentFolderId: string | null = null;
  // Original dk9 section (ALL_NOTES/RECENT/FAVORITES/UNFILED chips; ua5.java).
  // Sections apply when no folder is selected; selecting a folder resets to
  // ALL_NOTES and selecting a section clears the folder selection.
  currentSection: LibrarySection = LibrarySection.ALL_NOTES;
  // Original bk9 FolderFilter.isShowingAllNotes — while searching inside
  // a folder, widening the toggle searches all notes without leaving the
  // folder. Resets on folder/section changes.
  searchAllNotes: boolean = false;
  // Original flc SearchIndexingState terminal state: notes with no
  // search_item coverage never match library search (the original's
  // "unindexed notes will not appear in search" contract).
  unindexedNoteCount: number = 0;
  private repo: NoteRepository;
  private loadGeneration: number = 0;
  private mutationGeneration: number = 0;
  private activeQuery: string = '';
  private mutationChain: Promise<void> = Promise.resolve();

  constructor(repo: NoteRepository) {
    this.repo = repo;
  }

  async loadNotes(query: string): Promise<void> {
    const generation: number = ++this.loadGeneration;
    this.activeQuery = query;
    this.isLoading = true;
    this.loadError = '';
    // Original Recently Deleted rule: notes older than 30 days are permanently
    // deleted. Purging on library load needs no background worker.
    try {
      await this.repo.purgeExpiredTrash(Date.now());
    } catch (e) {
      console.error(`purgeExpiredTrash failed: ${JSON.stringify(e)}`);
    }
    try {
      while (generation === this.loadGeneration) {
        const mutationGeneration: number = this.mutationGeneration;
        const folderId: string | null = this.currentFolderId;
        const section: LibrarySection = this.currentSection;
        let loaded: NoteMeta[];
        try {
          loaded = await this.queryNotes(query, folderId, section);
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
        try {
          const unindexedCount: number = await this.repo.countUnindexedNotes();
          if (generation === this.loadGeneration) {
            this.unindexedNoteCount = unindexedCount;
          }
        } catch (e) {
          console.error(`countUnindexedNotes failed: ${JSON.stringify(e)}`);
        }
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
    const previousSection: LibrarySection = this.currentSection;
    const previousSearchAll: boolean = this.searchAllNotes;
    this.currentFolderId = folderId;
    // Folder selection is a separate dimension in the original; picking a
    // subject leaves the dk9 chips on ALL_NOTES (pk9 default).
    this.currentSection = LibrarySection.ALL_NOTES;
    this.searchAllNotes = false;
    try {
      await this.loadNotes(query);
    } catch (e) {
      this.currentFolderId = previousFolderId;
      this.currentSection = previousSection;
      this.searchAllNotes = previousSearchAll;
      throw new Error(`setFolder failed: ${JSON.stringify(e)}`);
    }
  }

  // Original d5j Rename: a title-only partial edit — the repository routes it
  // through updateNoteTitle (original SET_TITLE op) and we update the visible
  // projection in place; TITLE sort may reorder the row.
  async renameNote(noteId: string, title: string): Promise<void> {
    await this.enqueueMutation(async (): Promise<void> => {
      const note: NoteMeta | null = await this.repo.getNote(noteId);
      if (note === null) {
        return;
      }
      await this.repo.renameNote(noteId, title);
      const persisted: NoteMeta | null = await this.repo.getNote(noteId);
      if (persisted === null) {
        return;
      }
      this.mutationGeneration++;
      this.notes = this.notes.map((item: NoteMeta): NoteMeta =>
        item.id === noteId ? persisted : item);
      this.applySort();
    });
  }

  // Original d5j Show in folder: navigates to the containing folder; an
  // unfiled note lands on ALL_NOTES (folder selection resets the dk9 section).
  async showNoteInFolder(note: NoteMeta, query: string): Promise<void> {
    await this.setFolder(note.folderId, query);
  }

  // Original dk9 chip selection (ua5): a section replaces the folder view.
  async setSection(section: LibrarySection, query: string): Promise<void> {
    const previousFolderId: string | null = this.currentFolderId;
    const previousSection: LibrarySection = this.currentSection;
    const previousSearchAll: boolean = this.searchAllNotes;
    this.currentFolderId = null;
    this.currentSection = section;
    this.searchAllNotes = false;
    try {
      await this.loadNotes(query);
    } catch (e) {
      this.currentFolderId = previousFolderId;
      this.currentSection = previousSection;
      this.searchAllNotes = previousSearchAll;
      throw new Error(`setSection failed: ${JSON.stringify(e)}`);
    }
  }

  // Original bk9.isShowingAllNotes toggle (yj9 folder-filter-toggle chip):
  // widens a folder-scoped search to all notes, then reloads.
  async setSearchAllNotes(searchAll: boolean, query: string): Promise<void> {
    this.searchAllNotes = searchAll;
    await this.loadNotes(query);
  }

  // Original setFavorite (modifyNote{isFavorited}): toggles the flag and
  // updates the visible projection; unfavoriting inside FAVORITES drops the
  // row exactly like the original section filter would on reload.
  async toggleFavorite(noteId: string): Promise<void> {
    await this.enqueueMutation(async (): Promise<void> => {
      const note: NoteMeta | null = await this.repo.getNote(noteId);
      if (note === null) {
        return;
      }
      const persisted: NoteMeta = await this.repo.setNoteFavorite(noteId, !note.favorite);
      this.mutationGeneration++;
      const next: NoteMeta[] = [];
      for (const item of this.notes) {
        if (item.id !== noteId) {
          next.push(item);
          continue;
        }
        if (this.currentSection === LibrarySection.FAVORITES &&
          this.currentFolderId === null && !persisted.favorite) {
          continue;
        }
        next.push(this.noteWithFavorite(item, persisted.favorite));
      }
      this.notes = next;
      this.applySort();
    });
  }

  private queryNotes(query: string, folderId: string | null,
    section: LibrarySection): Promise<NoteMeta[]> {
    if (query.trim().length > 0) {
      // bk9.isShowingAllNotes: an active folder search can be widened to
      // all notes while staying inside the folder view.
      if (this.searchAllNotes && folderId !== null) {
        return this.repo.searchNotes(query, null);
      }
      return folderId === null && section !== LibrarySection.ALL_NOTES ?
        this.repo.searchNotesInSection(query, section) :
        this.repo.searchNotes(query, folderId);
    }
    if (folderId !== null) {
      return this.repo.getNotesByFolder(folderId);
    }
    if (section === LibrarySection.FAVORITES) {
      return this.repo.getFavoriteNotes();
    }
    if (section === LibrarySection.RECENT) {
      return this.repo.getRecentNotes();
    }
    if (section === LibrarySection.UNFILED) {
      return this.repo.getUnfiledNotes();
    }
    return this.repo.getAllNotes();
  }

  // 设置排序模式并刷新
  setSortMode(mode: NoteSortMode): void {
    this.sortMode = mode;
    this.applySort();
  }

  // Original je7 direction toggle (inh.b arrow button dispatches the
  // opposite direction). Field and direction are independent settings.
  setSortDescending(descending: boolean): void {
    this.sortDescending = descending;
    this.applySort();
  }

  async setSearchQuery(query: string): Promise<void> {
    await this.loadNotes(query);
  }

  // 按当前模式排序。
  private applySort(): void {
    // Original dk9.RECENT has a fixed ordering (mk9: lastOpened desc, top 10)
    // that bypasses the he7/je7 section sort entirely.
    if (this.currentFolderId === null && this.currentSection === LibrarySection.RECENT) {
      return;
    }
    const sorted: NoteMeta[] = this.notes.slice();
    // Original pk9.s: he7 field comparators produce the ascending list
    // (fh7(10) created, fh7(11) modified, bg1 collator name); a descending
    // je7 then reverses it via au1.E1.
    if (this.sortMode === NoteSortMode.UPDATED) {
      sorted.sort((a: NoteMeta, b: NoteMeta) => a.updatedAt - b.updatedAt);
    } else if (this.sortMode === NoteSortMode.CREATED) {
      sorted.sort((a: NoteMeta, b: NoteMeta) => a.createdAt - b.createdAt);
    } else if (this.sortMode === NoteSortMode.TITLE) {
      sorted.sort((a: NoteMeta, b: NoteMeta) => a.title.localeCompare(b.title));
    }
    if (this.sortDescending) {
      sorted.reverse();
    }
    this.notes = sorted;
  }

  // 创建并返回 noteId
  async createNote(query: string, templateOverride?: PaperTemplate): Promise<string> {
    const folderId: string | null = this.currentFolderId;
    const viewGeneration: number = this.loadGeneration;
    return this.enqueueMutation(async (): Promise<string> => {
      const note: NoteMeta = await this.repo.createNote(ORIGINAL_NOTE_DEFAULT_TITLE,
        folderId, templateOverride);
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

  // Original behavior: library Delete moves the note to Recently Deleted
  // (ClientNoteUpdate DELETE row); permanent delete only happens from the
  // Recently Deleted section or after the 30-day retention expires.
  async deleteNote(noteId: string): Promise<void> {
    await this.enqueueMutation(async (): Promise<void> => {
      await this.repo.trashNote(noteId, Date.now());
      this.removeVisibleNote(noteId);
      if (this.isLoading) {
        const generation: number = ++this.loadGeneration;
        const query: string = this.activeQuery;
        try {
          while (generation === this.loadGeneration) {
            const mutationGeneration: number = this.mutationGeneration;
            const folderId: string | null = this.currentFolderId;
            const section: LibrarySection = this.currentSection;
            let loaded: NoteMeta[];
            try {
              loaded = await this.queryNotes(query, folderId, section);
            } catch (error) {
              if (generation !== this.loadGeneration ||
                mutationGeneration !== this.mutationGeneration) {
                return;
              }
              this.loadError = `loadNotes failed: ${JSON.stringify(error)}`;
              throw new Error(this.loadError);
            }
            if (generation !== this.loadGeneration) {
              return;
            }
            if (mutationGeneration !== this.mutationGeneration) {
              continue;
            }
            this.notes = loaded;
            this.applySort();
          }
        } finally {
          if (generation === this.loadGeneration) {
            this.isLoading = false;
          }
        }
      }
    });
  }

  publishCommittedNoteMove(noteId: string, folderId: string | null,
    folderName: string | null, folderColor: number | null): void {
    this.mutationGeneration++;
    const next: NoteMeta[] = [];
    for (const note of this.notes) {
      if (note.id !== noteId) {
        next.push(note);
        continue;
      }
      if (this.currentFolderId === null || this.currentFolderId === folderId) {
        next.push(this.noteWithFolder(note, folderId, folderName, folderColor));
      }
    }
    this.notes = next;
    this.applySort();
  }

  publishCommittedFolderDelete(deletedFolderIds: string[], movedNoteIds: string[],
    committedNotes: NoteMeta[], query: string): void {
    this.mutationGeneration++;
    const deleted: Set<string> = new Set<string>(deletedFolderIds);
    const moved: Set<string> = new Set<string>(movedNoteIds);
    if (this.currentFolderId !== null && deleted.has(this.currentFolderId)) {
      this.currentFolderId = null;
    }
    if (this.currentFolderId === null && query.trim().length === 0) {
      this.notes = committedNotes.slice();
      this.applySort();
      return;
    }
    const next: NoteMeta[] = [];
    for (const note of this.notes) {
      let candidate: NoteMeta = note;
      if (moved.has(note.id)) {
        candidate = this.noteWithFolder(note, null, null, null);
      } else if (note.folderId !== null && deleted.has(note.folderId)) {
        // The committed transaction did not move this stale card, so it was changed or deleted
        // by an earlier serialized mutation and must not survive this local projection.
        continue;
      }
      if (this.currentFolderId === null || candidate.folderId === this.currentFolderId) {
        next.push(candidate);
      }
    }
    this.notes = next;
    this.applySort();
  }

  private removeVisibleNote(noteId: string): void {
    this.mutationGeneration++;
    this.notes = this.notes.filter((note: NoteMeta) => note.id !== noteId);
  }

  private createdNoteMatchesQuery(note: NoteMeta, query: string): boolean {
    const foldedQuery: string = query.trim().toLowerCase();
    return foldedQuery.length === 0 || note.title.toLowerCase().includes(foldedQuery);
  }

  private noteWithFolder(note: NoteMeta, folderId: string | null,
    folderName: string | null, folderColor: number | null): NoteMeta {
    return {
      id: note.id,
      title: note.title,
      createdAt: note.createdAt,
      updatedAt: note.updatedAt,
      favorite: note.favorite,
      lastOpened: note.lastOpened,
      folderId: folderId,
      folderName: folderName,
      folderColor: folderColor,
      hasRecordings: note.hasRecordings,
      deletedAt: note.deletedAt,
    };
  }

  private noteWithFavorite(note: NoteMeta, favorite: boolean): NoteMeta {
    return {
      id: note.id,
      title: note.title,
      createdAt: note.createdAt,
      updatedAt: note.updatedAt,
      favorite: favorite,
      lastOpened: note.lastOpened,
      folderId: note.folderId,
      folderName: note.folderName,
      folderColor: note.folderColor,
      hasRecordings: note.hasRecordings,
      deletedAt: note.deletedAt,
    };
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
