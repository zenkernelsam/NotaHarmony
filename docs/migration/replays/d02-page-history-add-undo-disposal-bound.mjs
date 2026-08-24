import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const functionStart = page.indexOf('  private async applyAddPageHistory(');
const functionEnd = page.indexOf('  private async applyDeletePageHistory(', functionStart);
assert.ok(functionStart !== -1 && functionEnd > functionStart,
  'applyAddPageHistory section exists');
const action = page.slice(functionStart, functionEnd);

const undoStart = action.indexOf('    if (isUndo) {');
const redoStart = action.indexOf('    const assignedPage: PageInfo = await this.pageRepo.addPage(', undoStart);
assert.ok(undoStart !== -1 && redoStart > undoStart, 'ADD_PAGE undo and redo sections exist');
const undo = action.slice(undoStart, redoStart);

const deleteAwait = undo.indexOf('await this.pageRepo.deletePage(this.noteId, action.pageId, history);');
assert.notEqual(deleteAwait, -1, 'ADD_PAGE undo durable delete exists');

const guardStart = undo.indexOf('if (this.editorDisposed) {', deleteAwait);
const guardEnd = undo.indexOf('}', guardStart);
const guard = guardStart !== -1 && guardEnd > guardStart
  ? undo.slice(guardStart, guardEnd + 1).replaceAll(/\s+/g, ' ').trim() : '';
assert.equal(guard, 'if (this.editorDisposed) { return false; }',
  'ADD_PAGE undo disposal guard returns false');

const pagesMutation = undo.indexOf('this.pages = this.orderPages(', deleteAwait);
const selectionMutation = undo.indexOf('this.selectPageById(action.selectedPageIdBefore);', deleteAwait);
assert.ok(guardStart !== -1 && pagesMutation > guardEnd &&
  selectionMutation > guardEnd, 'guard precedes local pages mutation and selection');

const redoGuard = action.slice(redoStart).match(
  /await this\.pageRepo\.addPage\([\s\S]*?if \(this\.editorDisposed\) \{\s+return false;\s+\}/);
assert.ok(redoGuard, 'existing ADD_PAGE redo disposal guard remains intact');

console.log('D02_PAGE_HISTORY_ADD_UNDO_DISPOSAL_BOUND_REPLAY_OK TOTAL=5 FAILED=0');
