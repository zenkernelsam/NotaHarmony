import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/library/LibraryPage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const deleteStart = page.indexOf('private async deleteNoteAndRefresh(noteId: string): Promise<void> {');
const createStart = page.indexOf('private async createAndOpen(): Promise<void> {', deleteStart);
const endMarker = page.indexOf('\n  // 响应式断点', createStart);
assert.ok(deleteStart !== -1 && createStart > deleteStart && endMarker > createStart);

const deleteFn = page.slice(deleteStart, createStart);
assert.match(deleteFn, /const lifecycleGeneration: number = this\.lifecycleGeneration;/);
const deleteGuards = (deleteFn.match(
  /lifecycleGeneration !== this\.lifecycleGeneration \|\| !this\.pageActive \|\|\s+this\.viewModel !== vm/g) ?? []).length;
assert.equal(deleteGuards, 2);

const createFn = page.slice(createStart, endMarker);
assert.match(createFn, /const lifecycleGeneration: number = this\.lifecycleGeneration;/);
const createGuards = (createFn.match(
  /lifecycleGeneration !== this\.lifecycleGeneration \|\| !this\.pageActive \|\|\s+this\.viewModel !== vm/g) ?? []).length;
assert.equal(createGuards, 2);
assert.match(createFn,
  /if \(lifecycleGeneration !== this\.lifecycleGeneration[\s\S]*?this\.createBusy = false;\s+return;\s+\}/);

console.log('D02_LIBRARY_NOTE_CREATE_DELETE_LIFECYCLE_BOUND_REPLAY_OK TOTAL=4 FAILED=0');
