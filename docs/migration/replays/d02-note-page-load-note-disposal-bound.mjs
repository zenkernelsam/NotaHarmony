import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8').replaceAll('\r\n', '\n');

const start = page.indexOf('private async loadPages(): Promise<void> {');
const end = page.indexOf('// Original title commits are serialized', start);
assert.ok(start !== -1 && end > start, 'loadPages body');
const body = page.slice(start, end);

const noteAwaitIndex = body.indexOf('await this.noteRepo.getNote(this.noteId);');
const guardIndex = body.indexOf('if (this.editorDisposed || loadGeneration !== this.pageLoadGeneration) {', noteAwaitIndex);
const titlePublishIndex = body.indexOf('this.noteTitle = note.title;', guardIndex);
assert.ok(noteAwaitIndex !== -1 && guardIndex > noteAwaitIndex && titlePublishIndex > guardIndex,
  'disposed note load cannot publish title or pages');

const pagesAwaitIndex = body.indexOf('await this.pageRepo.getPages(this.noteId);', guardIndex);
const pagesGuardIndex = body.indexOf('if (this.editorDisposed || loadGeneration !== this.pageLoadGeneration) {', pagesAwaitIndex);
const backgroundAssignIndex = body.indexOf('this.noteBackground = await this.pageRepo.getNoteBackground', pagesGuardIndex);
assert.ok(pagesAwaitIndex > guardIndex && pagesGuardIndex > pagesAwaitIndex && backgroundAssignIndex > pagesGuardIndex,
  'pages publication remains guarded before background refresh');

const catchIndex = body.indexOf('} catch (e) {');
const catchGuardIndex = body.indexOf('if (loadGeneration !== this.pageLoadGeneration || this.editorDisposed) {', catchIndex);
const errorPublishIndex = body.indexOf('this.pages = [];', catchGuardIndex);
assert.ok(catchGuardIndex > catchIndex && errorPublishIndex > catchGuardIndex,
  'late load failure cannot publish error state');

const initializeCall = body.match(/await this\.viewModel\.initialize\([\s\S]*?\);/);
assert.ok(initializeCall, 'view model initialization call');
assert.match(initializeCall[0], /editorDisposed/);
assert.match(initializeCall[0], /loadGeneration === this\.pageLoadGeneration/);

console.log('D02_NOTE_PAGE_LOAD_NOTE_DISPOSAL_BOUND_REPLAY_OK TOTAL=4 FAILED=0');
