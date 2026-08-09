import { describe, it, expect } from '@ohos/hypium';
import { NoteMeta, NoteViewState } from '../main/ets/core/model/NoteTypes';
import { NoteRepository } from '../main/ets/data/RepositoryInterfaces';
import { LibraryViewModel, NoteSortMode } from '../main/ets/ui/library/LibraryViewModel';

class FakeNoteRepository implements NoteRepository {
  notes: NoteMeta[] = [];
  failReads: boolean = false;
  createdFolderId: string | null = null;

  async createNote(_title: string, folderId: string | null): Promise<NoteMeta> {
    this.createdFolderId = folderId;
    const note: NoteMeta = makeNote('created', folderId);
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
    if (this.failReads) {
      throw new Error('read failed');
    }
    return this.notes.slice();
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

  async updateNote(_note: NoteMeta): Promise<void> {
  }

  async deleteNote(_noteId: string): Promise<void> {
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
    hasRecordings: false,
  };
}

export default function libraryViewModelTest() {
  describe('LibraryViewModel', () => {
    it('preserves the visible list and clears loading after a read failure', 0, async () => {
      const repository = new FakeNoteRepository();
      repository.notes = [makeNote('existing', null)];
      const viewModel = new LibraryViewModel(repository);
      await viewModel.loadNotes();
      repository.failReads = true;
      try {
        await viewModel.loadNotes();
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
      await viewModel.loadNotes();
      repository.failReads = true;
      try {
        await viewModel.setFolder('broken-folder');
      } catch (_error) {
      }
      expect(viewModel.currentFolderId === null).assertTrue();
      expect(viewModel.notes[0].id).assertEqual('root-note');
    });

    it('creates a note in the currently selected folder', 0, async () => {
      const repository = new FakeNoteRepository();
      const viewModel = new LibraryViewModel(repository);
      viewModel.currentFolderId = 'folder-a';
      const noteId: string = await viewModel.createNote();
      expect(noteId).assertEqual('created');
      expect(repository.createdFolderId).assertEqual('folder-a');
      expect(viewModel.notes.length).assertEqual(1);
      expect(viewModel.notes[0].folderId).assertEqual('folder-a');
    });

    it('loads search results through the repository query state', 0, async () => {
      const repository = new FakeNoteRepository();
      repository.notes = [makeNote('Alpha', null), makeNote('Beta', null)];
      const viewModel = new LibraryViewModel(repository);
      await viewModel.setSearchQuery('pha');
      expect(viewModel.getFilteredNotes().length).assertEqual(1);
      expect(viewModel.getFilteredNotes()[0].id).assertEqual('Alpha');
    });

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
      await viewModel.loadNotes();
      expect(viewModel.notes[0].id).assertEqual('beta');
      expect(viewModel.notes[1].id).assertEqual('gamma');
      expect(viewModel.notes[2].id).assertEqual('alpha');

      viewModel.setSortMode(NoteSortMode.TITLE);
      expect(viewModel.notes[0].id).assertEqual('alpha');
      expect(viewModel.notes[1].id).assertEqual('beta');
      expect(viewModel.notes[2].id).assertEqual('gamma');

      viewModel.setSortMode(NoteSortMode.UPDATED);
      expect(viewModel.notes[0].id).assertEqual('beta');
      expect(viewModel.notes[1].id).assertEqual('gamma');
      expect(viewModel.notes[2].id).assertEqual('alpha');

      viewModel.setSortMode(NoteSortMode.CREATED);
      expect(viewModel.notes[0].id).assertEqual('alpha');
      expect(viewModel.notes[1].id).assertEqual('gamma');
      expect(viewModel.notes[2].id).assertEqual('beta');
    });
  });
}
