import assert from 'node:assert/strict';
import fs from 'node:fs';

const canvas = fs.readFileSync(
  'note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8');

assert.ok(canvas.includes('private detachMathEditorForNavigation(): void {'));
assert.ok(canvas.includes('!this.mathEditorVisible && !this.mathEditorBusy'));
assert.ok(canvas.includes('this.mathEditorVisible = false;'));

assert.ok(canvas.includes('this.detachMathEditorForNavigation();'));


// Math edit: catch uses healthy predicate for reportSaveFailure
const editCatchIdx = canvas.indexOf('original Math latex commit failed');
assert.notEqual(editCatchIdx, -1);
const editCatchStart = canvas.lastIndexOf('catch (e) {', editCatchIdx);
assert.notEqual(editCatchStart, -1);
const editCatchBody = canvas.slice(editCatchStart, editCatchIdx);
assert.ok(editCatchBody.includes('isHistoryPageContextCurrent(generation, pageId)'));
assert.ok(editCatchBody.includes('reportSaveFailure'));

// Math insert: catch uses healthy predicate
const insertCatchIdx = canvas.indexOf('original Math insert failed');
assert.notEqual(insertCatchIdx, -1);
const insertCatchStart = canvas.lastIndexOf('catch (e) {', insertCatchIdx);
assert.notEqual(insertCatchStart, -1);
const insertCatchBody = canvas.slice(insertCatchStart, insertCatchIdx);
assert.ok(insertCatchBody.includes('isHistoryPageContextCurrent(generation, pageId)'));
assert.ok(insertCatchBody.includes('reportSaveFailure'));

// Math insert success: no old weak guard
const insertFnStart = canvas.indexOf('private async confirmMathInsert');
assert.notEqual(insertFnStart, -1);
const insertFnEnd = canvas.indexOf('private groupSelectedElements', insertFnStart);
assert.notEqual(insertFnEnd, -1);
const insertBody = canvas.slice(insertFnStart, insertFnEnd);
assert.ok(!insertBody.includes('if (generation === this.pageLoadGeneration && pageId === this.loadedPageId &&'));
assert.ok(insertBody.includes('this.isHistoryPageContextCurrent(generation, pageId)'));

// Math edit success: no old weak guard
const editFnStart = canvas.indexOf('private async confirmMathEditing');
assert.notEqual(editFnStart, -1);
const editFnEnd = canvas.indexOf('private canStartOriginalPhotoInsert', editFnStart);
assert.notEqual(editFnEnd, -1);
const editBody = canvas.slice(editFnStart, editFnEnd);
assert.ok(!editBody.includes('if (generation === this.pageLoadGeneration && pageId === this.loadedPageId &&'));
assert.ok(editBody.includes('this.isHistoryPageContextCurrent(generation, pageId)'));

console.log('D02_MATH_EDITOR_PAGE_HEALTH_BOUND_REPLAY_OK TOTAL=14 FAILED=0');
