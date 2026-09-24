import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/library/LibraryPage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

assert.match(page,
  /private confirmDelete\(note: NoteMeta\): void \{\s+if \(!this\.pageActive \|\| this\.deleteBusy\) \{\s+return;\s+\}/,
  'stale note context cannot open the delete dialog');

const deleteStart = page.indexOf('private async deleteNoteAndRefresh(noteId: string): Promise<void> {');
const createStart = page.indexOf('private async createAndLaunch(autoRecord: boolean,', deleteStart);
const endMarker = page.indexOf('private drainDeepLinkIngress(): void {', createStart);
assert.ok(deleteStart !== -1 && createStart > deleteStart && endMarker > createStart);

const deleteFn = page.slice(deleteStart, createStart);
assert.match(deleteFn,
  /if \(!this\.pageActive \|\| this\.viewModel === null \|\| this\.deleteBusy\) \{\s+return;\s+\}/,
  'stale deletion cannot start a durable mutation');
assert.match(deleteFn, /const lifecycleGeneration: number = this\.lifecycleGeneration;/);
const deleteGuards = (deleteFn.match(
  /lifecycleGeneration !== this\.lifecycleGeneration \|\| !this\.pageActive \|\|\s+this\.viewModel !== vm/g) ?? []).length;
assert.equal(deleteGuards, 2);

const createFn = page.slice(createStart, endMarker);
assert.match(createFn,
  /if \(!this\.pageActive \|\| this\.viewModel === null \|\| this\.createBusy\) \{\s+return;\s+\}/,
  'stale create cannot start a durable mutation');
assert.match(createFn, /const lifecycleGeneration: number = this\.lifecycleGeneration;/);
const createGuards = (createFn.match(
  /lifecycleGeneration !== this\.lifecycleGeneration \|\| !this\.pageActive \|\|\s+this\.viewModel !== vm/g) ?? []).length;
assert.equal(createGuards, 3);
assert.match(createFn,
  /if \(lifecycleGeneration !== this\.lifecycleGeneration[\s\S]*?this\.createBusy = false;\s+return;\s+\}/);

const navCatch = createFn.indexOf("catch (e) {", createFn.indexOf("await router.pushUrl({ url: 'ui/editor/NotePage'"));
assert.ok(navCatch >= 0);
const navGuardIndex = createFn.indexOf('if (lifecycleGeneration !== this.lifecycleGeneration', navCatch);
const navToastIndex = createFn.indexOf("$r('app.string.created_note_open_failed')", navGuardIndex);
assert.ok(navGuardIndex > navCatch && navToastIndex > navGuardIndex,
  'navigation failure must check context before toast');

// Phase 545: the file-import creation path carries the same lifecycle guards.
const importStart = page.indexOf('private async importAndOpen(): Promise<void> {', endMarker);
assert.ok(importStart > endMarker);
const importFn = page.slice(importStart,
  page.indexOf('\n  // 原版 ib7/pk9.onDocScanned', importStart));
assert.match(importFn,
  /if \(!this\.pageActive \|\| this\.viewModel === null \|\| this\.createBusy\) \{\s+return;\s+\}/,
  'stale import cannot start a durable mutation');
assert.match(importFn, /const lifecycleGeneration: number = this\.lifecycleGeneration;/);
const importGuards = (importFn.match(
  /lifecycleGeneration !== this\.lifecycleGeneration \|\| !this\.pageActive \|\|\s+this\.viewModel !== vm/g) ?? []).length;
assert.equal(importGuards, 2);

console.log('D02_LIBRARY_NOTE_CREATE_DELETE_LIFECYCLE_BOUND_REPLAY_OK TOTAL=11 FAILED=0');
