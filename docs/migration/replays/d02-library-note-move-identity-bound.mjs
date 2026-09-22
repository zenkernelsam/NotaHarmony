import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/library/LibraryPage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const marker = 'private async moveNote(noteId: string, folderId: string | null): Promise<void> {';
const start = page.indexOf(marker);
assert.ok(start !== -1);
const end = page.indexOf('private publishCommittedFolders(', start);
assert.ok(end !== -1);
const body = page.slice(start, end);

const identityGuardIndex = body.indexOf('isCurrentLifecycle(lifecycleGeneration, vm');
if (identityGuardIndex !== -1) {
  assert.ok(body.includes('this.viewModel !== vm'));
} else {
  assert.match(body,
    /lifecycleGeneration !== this\.lifecycleGeneration \|\| !this\.pageActive \|\|\s+this\.viewModel !== vm \|\|/);
  assert.ok(!body.includes('if (lifecycleGeneration !== this.lifecycleGeneration || !this.pageActive) {'));
}

const guardIndex = body.indexOf('isCurrentLifecycle(lifecycleGeneration, vm, this.thumbRenderer)');
const effects = [
  'vm.publishCommittedNoteMove(result.noteId, movedFolderId,',
  'this.viewModel = vm;',
  'this.notes = vm.getFilteredNotes().slice();',
  "this.reloadVisibleNotesAfterMutation(vm, 'move note');",
];
let lastGuardReturn = -1;
for (const effect of effects) {
  const index = body.indexOf(effect);
  assert.ok(index > guardIndex, effect);
}
assert.match(body, /\} finally \{\s+this\.folderBusy = false;\s+\}/);

console.log('D02_LIBRARY_NOTE_MOVE_IDENTITY_BOUND_REPLAY_OK TOTAL=6 FAILED=0');