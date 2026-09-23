import assert from 'node:assert/strict';
import fs from 'node:fs';

const canvas = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const start = canvas.indexOf('    if (this.isPageAction(action.type)) {');
const end = canvas.indexOf('    if (action.type === UndoableActionType.GROUP_ELEMENTS) {', start);
assert.ok(start !== -1 && end > start);
const branch = canvas.slice(start, end);

assert.match(branch, /const pageHistoryGeneration: number = this\.pageLoadGeneration;/);
assert.match(branch, /const committed: boolean = applied && this\.lifecycleActive &&\s+pageHistoryGeneration === this\.pageLoadGeneration;/);
assert.match(branch, /if \(committed\) \{\s+this\.commitHistory\(action, isUndo\);\s+\}/);
assert.match(branch, /page history committed after editor changed; durable history remains available/);
assert.ok((branch.match(/this\.historyBusy = false;/g) || []).length === 2);

function body(source, marker) {
  const position = source.indexOf(marker);
  assert.notEqual(position, -1, marker);
  return source.slice(position, source.indexOf('\n  private ', position));
}

const applyBody = body(page, '  private async applyPageHistory(');
const addBody = body(page, '  private async applyAddPageHistory(');
const deleteBody = body(page, '  private async applyDeletePageHistory(');

for (const [name, text, minimum] of [
  ['applyPageHistory', applyBody, 6],
  ['applyAddPageHistory', addBody, 1],
  ['applyDeletePageHistory', deleteBody, 2],
]) {
  const checks = text.match(/if \(this\.editorDisposed\) \{\s+return false;/g)?.length ?? 0;
  assert.ok(checks >= minimum, `${name} disposal checks=${checks}`);
}

for (const [name, awaitText, publishText] of [
  ['NOTE_TITLE', 'await repository.updateNoteTitle(', 'this.noteTitle = persisted.materializedTitle;'],
  ['NOTE_METADATA', 'await repository.updateOriginalNoteMetadata(', 'return true;'],
  ['PAGE_SETTINGS', 'await pageRepository.updatePage(page, history);', 'this.replacePage(page);'],
  ['NOTE_BACKGROUND', 'await pageRepository.updateNoteBackground(', 'this.noteBackground = materialized;'],
  ['REORDER_PAGES', 'await pageRepository.reorderPages(this.noteId, order', 'this.pages = this.orderPages(this.pages, order);'],
]) {
  const awaitIndex = applyBody.indexOf(awaitText);
  const guardIndex = applyBody.indexOf('if (this.editorDisposed) {', awaitIndex);
  const publishIndex = applyBody.indexOf(publishText, awaitIndex + awaitText.length);
  assert.ok(awaitIndex !== -1 && guardIndex !== -1 && publishIndex !== -1 &&
    guardIndex < publishIndex, name);
}

assert.ok(addBody.indexOf('await this.pageRepo.addPage(') <
  addBody.indexOf('if (this.editorDisposed) {') <
  addBody.indexOf('const restored: PageInfo[]'));
assert.ok(deleteBody.indexOf('await this.pageRepo.restoreDeletedPage(') <
  deleteBody.indexOf('if (this.editorDisposed) {') <
  deleteBody.indexOf('selectPageById(action.selectedPageIdBefore)'));
assert.ok(deleteBody.indexOf('await this.pageRepo.deletePageWithCheckpoint(') <
  deleteBody.lastIndexOf('if (this.editorDisposed) {') <
  deleteBody.indexOf('this.orderPages(this.pages.filter'));

console.log('D02_PAGE_HISTORY_LIFECYCLE_BOUND_REPLAY_OK TOTAL=12 FAILED=0');
