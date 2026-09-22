import { describe, it, expect } from '@ohos/hypium';
import { NoteMeta, NoteViewState } from '../main/ets/core/model/NoteTypes';
import { LibrarySection, NoteRepository } from '../main/ets/data/RepositoryInterfaces';
import { LibraryViewModel, NoteSortMode } from '../main/ets/ui/library/LibraryViewModel';

class FakeNoteRepository implements NoteRepository {
  notes: NoteMeta[] = [];
  failReads: boolean = false;
  createdFolderId: string | null = null;
  createCount: number = 0;
  deleteCount: number = 0;
  readGate: Promise<void> | null = null;
  readStarted: (() => void) | null = null;
  snapshotBeforeGate: boolean = false;
  private nextCreatedId: number = 1;

  async createNote(_title: string, folderId: string | null): Promise<NoteMeta> {
    this.createCount++;
    this.createdFolderId = folderId;
    const note: NoteMeta = makeNote(`created-${this.nextCreatedId++}`, folderId);
    this.notes.push(note);
    return note;
  }

  async getNote(noteId: string): Promise<NoteMeta | null> {
    for (const note of this.notes) {
      if (note.id === noteId) {
        return note;
      }
    }
    return null;
  }

  async getAllNotes(): Promise<NoteMeta[]> {
    let snapshot: NoteMeta[] | null = null;
    if (this.snapshotBeforeGate) {
      snapshot = this.notes.slice();
      this.snapshotBeforeGate = false;
    }
    if (this.readGate !== null) {
      const gate: Promise<void> = this.readGate;
      this.readGate = null;
      if (this.readStarted !== null) {
        const started: () => void = this.readStarted;
        this.readStarted = null;
        started();
      }
      await gate;
    }
    if (this.failReads) {
      throw new Error('read failed');
    }
    return snapshot === null ? this.notes.slice() : snapshot;
  }

  async getNotesByFolder(folderId: string): Promise<NoteMeta[]> {
    if (this.failReads) {
      throw new Error('read failed');
    }
    const result: NoteMeta[] = [];
    for (const note of this.notes) {
      if (note.folderId === folderId) {
        result.push(note);
      }
    }
    return result;
  }

  async searchNotes(query: string, folderId: string | null): Promise<NoteMeta[]> {
    const result: NoteMeta[] = [];
    for (const note of this.notes) {
      if ((folderId === null || note.folderId === folderId) &&
        note.title.toLowerCase().includes(query.toLowerCase())) {
        result.push(note);
      }
    }
    return result;
  }

  async getFavoriteNotes(): Promise<NoteMeta[]> {
    const result: NoteMeta[] = [];
    for (const note of this.notes) {
      if (note.favorite) {
        result.push(note);
      }
    }
    return result;
  }

  async getRecentNotes(): Promise<NoteMeta[]> {
    return this.notes.slice()
      .sort((a: NoteMeta, b: NoteMeta) => b.lastOpened - a.lastOpened)
      .slice(0, 10);
  }

  async getUnfiledNotes(): Promise<NoteMeta[]> {
    const result: NoteMeta[] = [];
    for (const note of this.notes) {
      if (note.folderId === null) {
        result.push(note);
      }
    }
    return result;
  }

  async searchNotesInSection(query: string, section: LibrarySection): Promise<NoteMeta[]> {
    let scoped: NoteMeta[];
    if (section === LibrarySection.FAVORITES) {
      scoped = await this.getFavoriteNotes();
    } else if (section === LibrarySection.RECENT) {
      scoped = await this.getRecentNotes();
    } else if (section === LibrarySection.UNFILED) {
      scoped = await this.getUnfiledNotes();
    } else {
      scoped = this.notes.slice();
    }
    const result: NoteMeta[] = [];
    for (const note of scoped) {
      if (note.title.toLowerCase().includes(query.toLowerCase())) {
        result.push(note);
      }
    }
    return result;
  }

  async setNoteFavorite(noteId: string, favorite: boolean): Promise<NoteMeta> {
    for (let i = 0; i < this.notes.length; i++) {
      if (this.notes[i].id === noteId) {
        const note: NoteMeta = this.notes[i];
        const updated: NoteMeta = {
          id: note.id, title: note.title, createdAt: note.createdAt,
          updatedAt: note.updatedAt, favorite: favorite, lastOpened: note.lastOpened,
          folderId: note.folderId, hasRecordings: note.hasRecordings,
          deletedAt: note.deletedAt,
        };
        this.notes[i] = updated;
        return updated;
      }
    }
    throw new Error('note not found');
  }

  async touchNoteLastOpened(noteId: string, lastOpened: number): Promise<void> {
    for (const note of this.notes) {
      if (note.id === noteId) {
        note.lastOpened = lastOpened;
        return;
      }
    }
  }

  async updateNote(_note: NoteMeta): Promise<void> {
  }

  async renameNote(noteId: string, title: string): Promise<void> {
    for (const note of this.notes) {
      if (note.id === noteId) {
        note.title = title;
        return;
      }
    }
  }

  unindexedIds: Set<string> = new Set<string>();

  async countUnindexedNotes(): Promise<number> {
    return this.unindexedIds.size;
  }

  async deleteNote(_noteId: string): Promise<void> {
    this.deleteCount++;
    this.notes = this.notes.filter((note: NoteMeta) => note.id !== _noteId);
  }

  async getViewState(_noteId: string): Promise<NoteViewState | null> {
    return null;
  }

  async saveViewState(_state: NoteViewState): Promise<void> {
  }
}

function makeNote(id: string, folderId: string | null): NoteMeta {
  return {
    id: id,
    title: id,
    createdAt: 1,
    updatedAt: 1,
    favorite: false,
    lastOpened: 1,
    folderId: folderId,
    folderName: null,
    folderColor: null,
    hasRecordings: false,
    deletedAt: null,
  };
}

export default function libraryViewModelTest() {
  describe('LibraryViewModel', () => {
    it('preserves the visible list and clears loading after a read failure', 0, async () => {
      const repository = new FakeNoteRepository();
      repository.notes = [makeNote('existing', null)];
      const viewModel = new LibraryViewModel(repository);
      await viewModel.loadNotes('');
      repository.failReads = true;
      try {
        await viewModel.loadNotes('');
      } catch (_error) {
      }
      expect(viewModel.notes.length).assertEqual(1);
      expect(viewModel.notes[0].id).assertEqual('existing');
      expect(viewModel.isLoading).assertFalse();
      expect(viewModel.loadError.length > 0).assertTrue();
    });

    it('rolls back the selected folder when its read fails', 0, async () => {
      const repository = new FakeNoteRepository();
      repository.notes = [makeNote('root-note', null)];
      const viewModel = new LibraryViewModel(repository);
      await viewModel.loadNotes('');
      repository.failReads = true;
      try {
        await viewModel.setFolder('broken-folder', '');
      } catch (_error) {
      }
      expect(viewModel.currentFolderId === null).assertTrue();
      expect(viewModel.notes[0].id).assertEqual('root-note');
    });

    it('creates a note in the currently selected folder', 0, async () => {
      const repository = new FakeNoteRepository();
      const viewModel = new LibraryViewModel(repository);
      viewModel.currentFolderId = 'folder-a';
      const noteId: string = await viewModel.createNote('');
      expect(noteId).assertEqual('created-1');
      expect(repository.createdFolderId).assertEqual('folder-a');
      expect(viewModel.notes.length).assertEqual(1);
      expect(viewModel.notes[0].folderId).assertEqual('folder-a');
    });

    it('keeps a committed create successful when the authoritative refresh fails', 0, async () => {
      const repository = new FakeNoteRepository();
      repository.failReads = true;
      const viewModel = new LibraryViewModel(repository);
      const noteId: string = await viewModel.createNote('');
      expect(noteId).assertEqual('created-1');
      expect(repository.createCount).assertEqual(1);
      expect(viewModel.notes.length).assertEqual(1);
      expect(viewModel.notes[0].id).assertEqual('created-1');
      try {
        await viewModel.loadNotes('');
      } catch (_error) {
      }
      expect(repository.createCount).assertEqual(1);
      expect(viewModel.notes.length).assertEqual(1);
      expect(viewModel.notes[0].id).assertEqual('created-1');
    });

    it('publishes a created note when it matches the active search query', 0, async () => {
      const repository = new FakeNoteRepository();
      const viewModel = new LibraryViewModel(repository);
      const noteId: string = await viewModel.createNote('untitled');
      expect(noteId).assertEqual('created-1');
      expect(viewModel.notes.length).assertEqual(1);
      expect(viewModel.notes[0].id).assertEqual('created-1');
    });

    it('removes a committed delete even when the authoritative refresh fails', 0, async () => {
      const repository = new FakeNoteRepository();
      repository.notes = [makeNote('existing', null)];
      const viewModel = new LibraryViewModel(repository);
      await viewModel.loadNotes('');
      await viewModel.deleteNote('existing');
      expect(repository.deleteCount).assertEqual(1);
      expect(viewModel.notes.length).assertEqual(0);
      repository.failReads = true;
      try {
        await viewModel.loadNotes('');
      } catch (_error) {
      }
      expect(repository.deleteCount).assertEqual(1);
      expect(viewModel.notes.length).assertEqual(0);
    });

    it('clears stale loading after a delete commits during an in-flight read', 0, async () => {
      const repository = new FakeNoteRepository();
      repository.snapshotBeforeGate = true;
      let releaseRead: () => void = (): void => {};
      let notifyReadStarted: () => void = (): void => {};
      repository.readGate = new Promise<void>((resolve: () => void) => {
        releaseRead = resolve;
      });
      const readStarted: Promise<void> = new Promise<void>((resolve: () => void) => {
        notifyReadStarted = resolve;
      });
      repository.readStarted = notifyReadStarted;
      const viewModel = new LibraryViewModel(repository);
      viewModel.notes = [makeNote('existing', null)];
      const read: Promise<void> = viewModel.loadNotes('');
      await readStarted;
      await viewModel.deleteNote('existing');
      expect(viewModel.isLoading).assertFalse();
      releaseRead();
      try {
        await read;
      } catch (_error) {
      }
      expect(viewModel.isLoading).assertFalse();
      expect(viewModel.notes.length).assertEqual(0);
    });

    it('retries an in-flight read made stale by a committed create', 0, async () => {
      const repository = new FakeNoteRepository();
      repository.snapshotBeforeGate = true;
      let releaseRead: () => void = (): void => {};
      let notifyReadStarted: () => void = (): void => {};
      repository.readGate = new Promise<void>((resolve: () => void) => {
        releaseRead = resolve;
      });
      const readStarted: Promise<void> = new Promise<void>((resolve: () => void) => {
        notifyReadStarted = resolve;
      });
      repository.readStarted = notifyReadStarted;
      const viewModel = new LibraryViewModel(repository);
      const load: Promise<void> = viewModel.loadNotes('');
      await readStarted;
      const created: Promise<string> = viewModel.createNote('');
      await created;
      releaseRead();
      await load;
      expect(repository.createCount).assertEqual(1);
      expect(viewModel.notes.length).assertEqual(1);
      expect(viewModel.notes[0].id).assertEqual('created-1');
    });

    it('keeps a moved note visible in all notes and publishes its committed folder', 0, () => {
      const repository = new FakeNoteRepository();
      const viewModel = new LibraryViewModel(repository);
      viewModel.notes = [makeNote('existing', 'folder-a')];
      viewModel.publishCommittedNoteMove('existing', 'folder-b');
      expect(viewModel.notes.length).assertEqual(1);
      expect(viewModel.notes[0].folderId).assertEqual('folder-b');
    });

    it('keeps the active query after delete takes over an in-flight read', 0, async () => {
      const repository = new FakeNoteRepository();
      repository.notes = [makeNote('Alpha', null), makeNote('Beta', null)];
      repository.snapshotBeforeGate = true;
      let releaseRead: () => void = (): void => {};
      let notifyReadStarted: () => void = (): void => {};
      repository.readGate = new Promise<void>((resolve: () => void) => {
        releaseRead = resolve;
      });
      const readStarted: Promise<void> = new Promise<void>((resolve: () => void) => {
        notifyReadStarted = resolve;
      });
      repository.readStarted = notifyReadStarted;
      const viewModel = new LibraryViewModel(repository);
      const read: Promise<void> = viewModel.loadNotes('alp');
      await readStarted;
      await viewModel.deleteNote('Alpha');
      releaseRead();
      try {
        await read;
      } catch (_error) {
      }
      expect(repository.deleteCount).assertEqual(1);
      expect(viewModel.isLoading).assertFalse();
      expect(viewModel.notes.length).assertEqual(0);
    });

    it('removes a moved note from the selected source folder', 0, () => {
      const repository = new FakeNoteRepository();
      const viewModel = new LibraryViewModel(repository);
      viewModel.currentFolderId = 'folder-a';
      viewModel.notes = [makeNote('existing', 'folder-a')];
      viewModel.publishCommittedNoteMove('existing', 'folder-b');
      expect(viewModel.notes.length).assertEqual(0);
    });

    it('projects a committed subtree delete before the authoritative reload', 0, () => {
      const repository = new FakeNoteRepository();
      const viewModel = new LibraryViewModel(repository);
      viewModel.currentFolderId = 'child';
      viewModel.notes = [makeNote('moved', 'child'), makeNote('stale', 'child')];
      viewModel.publishCommittedFolderDelete(
        ['parent', 'child'], ['moved'], [makeNote('moved', null)], 'query');
      expect(viewModel.currentFolderId === null).assertTrue();
      expect(viewModel.notes.length).assertEqual(1);
      expect(viewModel.notes[0].id).assertEqual('moved');
      expect(viewModel.notes[0].folderId === null).assertTrue();
    });

    it('publishes the complete all-notes snapshot when the selected folder is deleted', 0, () => {
      const repository = new FakeNoteRepository();
      const viewModel = new LibraryViewModel(repository);
      viewModel.currentFolderId = 'child';
      viewModel.notes = [makeNote('moved', 'child')];
      viewModel.publishCommittedFolderDelete(['child'], ['moved'],
        [makeNote('moved', null), makeNote('other', 'other-folder')], '');
      expect(viewModel.currentFolderId === null).assertTrue();
      expect(viewModel.notes.length).assertEqual(2);
    });

    it('retries an in-flight read made stale by a committed folder move', 0, async () => {
      const repository = new FakeNoteRepository();
      repository.notes = [makeNote('existing', 'folder-a')];
      repository.snapshotBeforeGate = true;
      let releaseRead: () => void = (): void => {};
      let notifyReadStarted: () => void = (): void => {};
      repository.readGate = new Promise<void>((resolve: () => void) => {
        releaseRead = resolve;
      });
      const readStarted: Promise<void> = new Promise<void>((resolve: () => void) => {
        notifyReadStarted = resolve;
      });
      repository.readStarted = notifyReadStarted;
      const viewModel = new LibraryViewModel(repository);
      const load: Promise<void> = viewModel.loadNotes('');
      await readStarted;
      repository.notes = [makeNote('existing', 'folder-b')];
      viewModel.notes = [makeNote('existing', 'folder-a')];
      viewModel.publishCommittedNoteMove('existing', 'folder-b');
      releaseRead();
      await load;
      expect(viewModel.notes.length).assertEqual(1);
      expect(viewModel.notes[0].folderId).assertEqual('folder-b');
    });

    it('loads search results through the repository query state', 0, async () => {
      const repository = new FakeNoteRepository();
      repository.notes = [makeNote('Alpha', 'folder-a'), makeNote('Beta', 'folder-a'),
        makeNote('Alphabet', 'folder-b')];
      const viewModel = new LibraryViewModel(repository);
      await viewModel.setSearchQuery('pha');
      expect(viewModel.getFilteredNotes().length).assertEqual(2);
      expect(viewModel.getFilteredNotes()[0].id).assertEqual('Alpha');
      await viewModel.setFolder('folder-b', 'pha');
      expect(viewModel.getFilteredNotes().length).assertEqual(1);
      expect(viewModel.getFilteredNotes()[0].id).assertEqual('Alphabet');
    });

    // Original pk9.s: he7 field sorts produce the ascending list, je7
    // DESCENDING (the z97 default) reverses it via au1.E1.
    it('reapplies recently modified order after switching sort modes', 0, async () => {
      const repository = new FakeNoteRepository();
      const alpha: NoteMeta = makeNote('alpha', null);
      alpha.title = 'Alpha';
      alpha.createdAt = 30;
      alpha.updatedAt = 10;
      const beta: NoteMeta = makeNote('beta', null);
      beta.title = 'Beta';
      beta.createdAt = 10;
      beta.updatedAt = 30;
      const gamma: NoteMeta = makeNote('gamma', null);
      gamma.title = 'Gamma';
      gamma.createdAt = 20;
      gamma.updatedAt = 20;
      repository.notes = [gamma, beta, alpha];

      const viewModel = new LibraryViewModel(repository);
      await viewModel.loadNotes('');
      expect(viewModel.notes[0].id).assertEqual('beta');
      expect(viewModel.notes[1].id).assertEqual('gamma');
      expect(viewModel.notes[2].id).assertEqual('alpha');

      // NAME + DESCENDING = Z to A.
      viewModel.setSortMode(NoteSortMode.TITLE);
      expect(viewModel.notes[0].id).assertEqual('gamma');
      expect(viewModel.notes[1].id).assertEqual('beta');
      expect(viewModel.notes[2].id).assertEqual('alpha');

      // Field and direction are independent (inh.b keeps je7 across he7 picks).
      viewModel.setSortDescending(false);
      expect(viewModel.notes[0].id).assertEqual('alpha');
      expect(viewModel.notes[1].id).assertEqual('beta');
      expect(viewModel.notes[2].id).assertEqual('gamma');

      viewModel.setSortMode(NoteSortMode.UPDATED);
      expect(viewModel.notes[0].id).assertEqual('alpha');
      expect(viewModel.notes[1].id).assertEqual('gamma');
      expect(viewModel.notes[2].id).assertEqual('beta');

      viewModel.setSortDescending(true);
      viewModel.setSortMode(NoteSortMode.CREATED);
      expect(viewModel.notes[0].id).assertEqual('alpha');
      expect(viewModel.notes[1].id).assertEqual('gamma');
      expect(viewModel.notes[2].id).assertEqual('beta');
    });

    // Original dk9.FAVORITES (mk9 section query on isFavorited).
    it('lists only favorited notes inside the Favorites section', 0, async () => {
      const repository = new FakeNoteRepository();
      const kept: NoteMeta = makeNote('kept', null);
      kept.favorite = true;
      repository.notes = [kept, makeNote('plain', null), makeNote('filed', 'folder-1')];

      const viewModel = new LibraryViewModel(repository);
      await viewModel.setSection(LibrarySection.FAVORITES, '');
      expect(viewModel.currentSection).assertEqual(LibrarySection.FAVORITES);
      expect(viewModel.currentFolderId === null).assertTrue();
      expect(viewModel.notes.length).assertEqual(1);
      expect(viewModel.notes[0].id).assertEqual('kept');
    });

    // Original dk9.RECENT (mk9: lastOpened desc, au1.N1 top 10).
    it('orders Recent by lastOpened desc and caps at ten', 0, async () => {
      const repository = new FakeNoteRepository();
      const notes: NoteMeta[] = [];
      for (let i = 0; i < 12; i++) {
        const note: NoteMeta = makeNote(`note-${i}`, null);
        note.lastOpened = i + 1;
        notes.push(note);
      }
      repository.notes = notes;

      const viewModel = new LibraryViewModel(repository);
      await viewModel.setSection(LibrarySection.RECENT, '');
      expect(viewModel.notes.length).assertEqual(10);
      expect(viewModel.notes[0].id).assertEqual('note-11');
      expect(viewModel.notes[9].id).assertEqual('note-2');
      // RECENT bypasses the section sort modes (mk9 skips pk9.s).
      viewModel.setSortMode(NoteSortMode.TITLE);
      expect(viewModel.notes[0].id).assertEqual('note-11');
    });

    // Original dk9.UNFILED (subjectId IS NULL).
    it('lists only folderless notes inside Unfiled', 0, async () => {
      const repository = new FakeNoteRepository();
      repository.notes = [makeNote('loose', null), makeNote('filed', 'folder-1')];

      const viewModel = new LibraryViewModel(repository);
      await viewModel.setSection(LibrarySection.UNFILED, '');
      expect(viewModel.notes.length).assertEqual(1);
      expect(viewModel.notes[0].id).assertEqual('loose');
    });

    // Original setFavorite partial update: the flag flips in place and drops
    // out of the FAVORITES projection, without touching updatedAt.
    it('toggles favorite and keeps the section projection consistent', 0, async () => {
      const repository = new FakeNoteRepository();
      const alpha: NoteMeta = makeNote('alpha', null);
      alpha.updatedAt = 42;
      const beta: NoteMeta = makeNote('beta', null);
      beta.favorite = true;
      repository.notes = [alpha, beta];

      const viewModel = new LibraryViewModel(repository);
      await viewModel.loadNotes('');
      await viewModel.toggleFavorite('alpha');
      expect(repository.notes[0].favorite).assertTrue();
      expect(viewModel.notes.find((n: NoteMeta) => n.id === 'alpha')?.favorite)
        .assertTrue();
      expect(repository.notes[0].updatedAt).assertEqual(42);

      await viewModel.setSection(LibrarySection.FAVORITES, '');
      expect(viewModel.notes.length).assertEqual(2);
      await viewModel.toggleFavorite('alpha');
      expect(viewModel.notes.length).assertEqual(1);
      expect(viewModel.notes[0].id).assertEqual('beta');
    });

    // Folder selection resets the dk9 section back to ALL_NOTES (pk9 default).
    it('resets the section when a folder is selected', 0, async () => {
      const repository = new FakeNoteRepository();
      repository.notes = [makeNote('filed', 'folder-1')];

      const viewModel = new LibraryViewModel(repository);
      await viewModel.setSection(LibrarySection.FAVORITES, '');
      await viewModel.setFolder('folder-1', '');
      expect(viewModel.currentSection).assertEqual(LibrarySection.ALL_NOTES);
      expect(viewModel.currentFolderId).assertEqual('folder-1');
    });

    // w09.g/h: a committed move carries the destination folder's name/color
    // onto the card so the folder chip (cti.c) renders immediately.
    it('carries the destination folder projection on a committed move', 0, async () => {
      const repository = new FakeNoteRepository();
      repository.notes = [makeNote('alpha', null), makeNote('beta', null)];

      const viewModel = new LibraryViewModel(repository);
      await viewModel.loadNotes('');
      viewModel.publishCommittedNoteMove('alpha', 'folder-9', 'Work', 0xFF4FA8DE);
      const moved: NoteMeta | undefined =
        viewModel.notes.find((n: NoteMeta) => n.id === 'alpha');
      expect(moved?.folderId).assertEqual('folder-9');
      expect(moved?.folderName).assertEqual('Work');
      expect(moved?.folderColor).assertEqual(0xFF4FA8DE);
      // Unfiled move clears the projection (cti.c renders no chip).
      viewModel.publishCommittedNoteMove('alpha', null, null, null);
      const unfiled: NoteMeta | undefined =
        viewModel.notes.find((n: NoteMeta) => n.id === 'alpha');
      expect(unfiled?.folderName === null).assertTrue();
      expect(unfiled?.folderColor === null).assertTrue();
    });
  });
}
