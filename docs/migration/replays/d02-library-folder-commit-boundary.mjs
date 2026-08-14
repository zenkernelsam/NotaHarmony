import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const folder = fs.readFileSync(
  path.join(root, 'note/src/main/ets/data/FolderRepositoryImpl.ets'), 'utf8');
const note = fs.readFileSync(
  path.join(root, 'note/src/main/ets/data/NoteRepositoryImpl.ets'), 'utf8');
const mutex = fs.readFileSync(
  path.join(root, 'note/src/main/ets/data/LibraryMetadataMutationMutex.ets'), 'utf8');
const page = fs.readFileSync(
  path.join(root, 'note/src/main/ets/ui/library/LibraryPage.ets'), 'utf8');
const viewModel = fs.readFileSync(
  path.join(root, 'note/src/main/ets/ui/library/LibraryViewModel.ets'), 'utf8');

function section(source, startText, endText) {
  const start = source.indexOf(startText);
  const end = source.indexOf(endText, start + startText.length);
  if (start < 0 || end < 0) return '';
  return source.slice(start, end);
}

const createNote = section(note, 'async createNote(', 'async createNoteWithMeta(');
const createWithMeta = section(note, 'async createNoteWithMeta(', 'async getNote(');
const updateNote = section(note, 'async updateNote(', 'async deleteNote(');
const deleteNote = section(note, 'async deleteNote(', 'async getViewState(');
const folderDialog = section(page, 'private async onFolderDialogConfirm(', 'private async deleteFolder(');
const deleteFolder = section(page, 'private async deleteFolder(', 'private async moveFolder(');
const moveFolder = section(page, 'private async moveFolder(', 'private async moveNote(');
const moveNote = section(page, 'private async moveNote(', 'private publishCommittedFolders(');

const checks = [
  ['shared metadata mutex is module-level', mutex.includes(
    'export const libraryMetadataMutationMutex: AsyncMutex = databaseWriteMutex')],
  ['note create paths share the metadata writer', createNote.includes(
    'libraryMetadataMutationMutex.runExclusive') && createWithMeta.includes(
    'libraryMetadataMutationMutex.runExclusive')],
  ['note update and delete share the metadata writer', updateNote.includes(
    'libraryMetadataMutationMutex.runExclusive') && deleteNote.includes(
    'libraryMetadataMutationMutex.runExclusive')],
  ['delete keeps asset-before-metadata lock order', deleteNote.indexOf(
    'assetMutationMutex.runExclusive') < deleteNote.indexOf(
    'libraryMetadataMutationMutex.runExclusive')],
  ['title patch cannot replay stale folder or recording fields', !updateNote.includes("'folder_id'") &&
    !updateNote.includes("'has_recordings'") && !updateNote.includes("'favorite'") &&
    !updateNote.includes("'last_opened'")],
  ['folder repository removed its private writer', !folder.includes('private static writeMutex') &&
    (folder.match(/libraryMetadataMutationMutex\.runExclusive/g) ?? []).length === 5],
  ['folder mutations return transaction snapshots', folder.includes('FolderCreateResult') &&
    folder.includes('FolderDeleteResult') && folder.includes('committedFolders')],
  ['folder delete returns exact moved and deleted IDs', folder.includes('deletedFolderIds: deletedFolderIds') &&
    folder.includes('movedNoteIds: movedNoteIds') && folder.includes('notes: committedNotes')],
  ['folder dialog does not await a post-commit folder read', !folderDialog.includes('await repo.getAllFolders') &&
    folderDialog.includes('publishCommittedFolders(result.folders)')],
  ['folder delete separates commit from note/folder refresh', !deleteFolder.includes('await vm.setFolder') &&
    !deleteFolder.includes('await this.refreshThumbnails') &&
    deleteFolder.includes('publishCommittedFolderDelete')],
  ['folder move publishes commit result before best-effort read', !moveFolder.includes(
    'await repo.getAllFolders') && moveFolder.indexOf('publishCommittedFolders') <
    moveFolder.indexOf('reloadFoldersBestEffort')],
  ['note move projects commit before best-effort reload', !moveNote.includes('await vm.loadNotes') &&
    !moveNote.includes('await this.refreshThumbnails') &&
    moveNote.indexOf('publishCommittedNoteMove') < moveNote.indexOf('reloadVisibleNotesAfterMutation')],
  ['folder refresh is guarded by lifecycle and mutation generation', page.includes(
    'mutationGeneration === this.folderMutationGeneration') && page.includes(
    'readGeneration === this.folderReadGeneration')],
  ['committed folder mutations invalidate stale note reads', viewModel.includes(
    'publishCommittedNoteMove') && viewModel.includes('publishCommittedFolderDelete') &&
    (viewModel.match(/this\.mutationGeneration\+\+/g) ?? []).length >= 4],
];

for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
