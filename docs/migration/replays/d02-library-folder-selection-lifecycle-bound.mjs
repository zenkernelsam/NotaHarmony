import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/library/LibraryPage.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const start = page.indexOf('  private async selectFolder(folderId: string | null): Promise<void> {');
const end = page.indexOf('  // T-035：排序切换 + Preferences 持久化', start);
assert.ok(start !== -1 && end !== -1 && end > start);
const body = page.slice(start, end);

assert.match(body, /const lifecycleGeneration: number = this\.lifecycleGeneration;/);
assert.equal([...body.matchAll(/this\.isCurrentNotesRequest\(notesRequestGeneration, vm, query, folderId,\s+lifecycleGeneration\)/g)].length, 3);
assert.ok(!body.includes('notesRequestGeneration === this.notesRequestGeneration &&'));

const successGuard = body.indexOf('this.isCurrentNotesRequest(notesRequestGeneration, vm, query, folderId,\n        lifecycleGeneration)');
for (const effect of [
  "this.initError = '';",
  'this.notes = vm.getFilteredNotes().slice();',
  'await this.refreshThumbnails();',
  'this.closeCompactFolderDrawer();',
]) {
  const effectIndex = body.indexOf(effect);
  assert.ok(effectIndex > successGuard, effect);
}

const catchIndex = body.indexOf('} catch (e) {');
const failureGuard = body.indexOf('this.isCurrentNotesRequest(notesRequestGeneration, vm, query, folderId,', catchIndex);
for (const effect of ['this.currentFolderId = vm.currentFolderId;', "'app.string.load_notes_failed'"]) {
  const effectIndex = body.indexOf(effect, catchIndex);
  assert.ok(effectIndex > failureGuard, effect);
}
assert.match(body, /\} finally \{\s+this\.folderBusy = false;\s+\}/);

console.log('D02_LIBRARY_FOLDER_SELECTION_LIFECYCLE_BOUND_REPLAY_OK TOTAL=7 FAILED=0');
