import assert from 'node:assert/strict';
import fs from 'node:fs';

const source = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const start = source.indexOf('private startMathInsert(): void {');
const end = source.indexOf('private detachMathEditorForNavigation(): void {', start);
assert.ok(start !== -1 && end > start, 'startMathInsert body');
const body = source.slice(start, end);

for (const condition of [
  '!this.lifecycleActive',
  'this.mathEditorVisible',
  'this.photoImportBusy',
  'this.historyBusy',
  '!this.loaded',
  'this.dataLoading',
  'this.dataLoadFailed',
  '!this.persistence.isReady()',
  'this.loadedPageId.length === 0',
  'this.loadedPageId !== this.currentPage.pageId',
]) {
  const conditionIndex = body.indexOf(condition);
  const publishIndex = body.indexOf('this.mathEditorVisible = true;');
  assert.ok(conditionIndex !== -1 && conditionIndex < publishIndex, condition);
}

assert.match(body,
  /if \(!this\.lifecycleActive \|\| this\.mathEditorVisible \|\| this\.photoImportBusy \|\|\s+this\.historyBusy \|\|\s+!this\.loaded \|\| this\.dataLoading \|\| this\.dataLoadFailed \|\|\s+!this\.persistence\.isReady\(\) \|\| this\.loadedPageId\.length === 0 \|\|\s+this\.loadedPageId !== this\.currentPage\.pageId\) \{\s+return;\s+\}/);

console.log('D02_MATH_INSERT_ENTRY_BOUND_REPLAY_OK TOTAL=10 FAILED=0');
