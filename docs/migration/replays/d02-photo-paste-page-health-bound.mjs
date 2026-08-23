import assert from 'node:assert/strict';
import fs from 'node:fs';

const canvas = fs.readFileSync(
  'note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8');

assert.match(canvas,
  /private isHistoryPageContextCurrent\(generation: number, pageId: string\): boolean \{\s+return this\.lifecycleActive && generation === this\.pageLoadGeneration &&\s+pageId === this\.loadedPageId && pageId === this\.currentPage\.pageId &&\s+this\.loaded && !this\.dataLoading && !this\.dataLoadFailed;\s+\}/);

const photoStart = canvas.indexOf('private async insertOriginalPhotos(');
assert.notEqual(photoStart, -1);
const photoEnd = canvas.indexOf('private async confirmMathInsert', photoStart);
assert.notEqual(photoEnd, -1);
const photoBody = canvas.slice(photoStart, photoEnd);

// Photo success install uses predicate
assert.ok(photoBody.includes('this.isHistoryPageContextCurrent(generation, pageId)'));

// No remaining 2-line weak guards in photo function
const weakGuardCount = (photoBody.match(/if \(generation === this\.pageLoadGeneration && pageId === this\.loadedPageId/g) || []).length;
assert.equal(weakGuardCount, 0);

// Photo catch: reportSaveFailure gated by predicate
const photoCatchIdx = photoBody.indexOf('reportSaveFailure');
assert.notEqual(photoCatchIdx, -1);
const beforeCatch = photoBody.lastIndexOf('isHistoryPageContextCurrent(generation, pageId)', photoCatchIdx);
assert.notEqual(beforeCatch, -1);

// Group paste success and catch both use predicate
const pasteFnStart = canvas.indexOf('private applyOriginalGroupClipboardPaste(');
assert.notEqual(pasteFnStart, -1);
const pasteBody = canvas.slice(pasteFnStart, pasteFnStart + 5000);
const predicateUsesInPaste = (pasteBody.match(/isHistoryPageContextCurrent/g) || []).length;
assert.ok(predicateUsesInPaste >= 2);

console.log('D02_PHOTO_PASTE_PAGE_HEALTH_BOUND_REPLAY_OK TOTAL=10 FAILED=0');
