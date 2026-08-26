import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/library/LibraryPage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

assert.match(page, /private isCurrentNotesRequest\(generation: number, viewModel: LibraryViewModel,\s+query: string, folderId: string \| null,\s+lifecycleGeneration: number = this\.lifecycleGeneration\): boolean \{\s+return this\.pageActive && lifecycleGeneration === this\.lifecycleGeneration &&\s+generation === this\.notesRequestGeneration &&\s+this\.viewModel === viewModel && this\.searchText === query &&\s+this\.currentFolderId === folderId && viewModel\.currentFolderId === folderId;\s+\}/);
assert.match(page,
  /\.onChange\(\(value: string\) => \{\s+if \(!this\.pageActive\) \{\s+return;\s+\}\s+this\.searchText = value;/,
  'stale search input cannot publish query or start a request');

const start = page.indexOf("this.searchTimer = setTimeout(() => {");
const end = page.indexOf('}, 180);', start);
assert.ok(start !== -1 && end !== -1);
const body = page.slice(start, end);

assert.match(body, /const lifecycleGeneration: number = this\.lifecycleGeneration;/);
assert.match(body, /lifecycleGeneration !== this\.lifecycleGeneration \|\|\s+notesRequestGeneration !== this\.notesRequestGeneration/);
assert.equal([...body.matchAll(/this\.isCurrentNotesRequest\(notesRequestGeneration, vm, value, folderId, lifecycleGeneration\)/g)].length, 2);
for (const effect of [
  'this.notes = vm.getFilteredNotes().slice();',
  "promptAction.showToast({ message: $r('app.string.search_failed') });",
]) {
  const effectIndex = body.indexOf(effect);
  const guardIndex = body.indexOf('isCurrentNotesRequest(notesRequestGeneration, vm, value, folderId, lifecycleGeneration)');
  assert.ok(effectIndex > guardIndex, effect);
}
assert.ok(body.indexOf('this.libraryLoading = false;') < body.indexOf('.catch((e: Error) => {'));

console.log('D02_LIBRARY_SEARCH_LIFECYCLE_BOUND_REPLAY_OK TOTAL=8 FAILED=0');
