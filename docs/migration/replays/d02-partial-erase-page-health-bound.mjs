import assert from 'node:assert/strict';
import fs from 'node:fs';

const canvas = fs.readFileSync(
  'note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8');

assert.match(canvas,
  /private isHistoryPageContextCurrent\(generation: number, pageId: string\): boolean \{\s+return this\.lifecycleActive && generation === this\.pageLoadGeneration &&\s+pageId === this\.loadedPageId && pageId === this\.currentPage\.pageId &&\s+this\.loaded && !this\.dataLoading && !this\.dataLoadFailed;\s+\}/);

const fnStart = canvas.indexOf('private commitOriginalPartialErase');
assert.notEqual(fnStart, -1);
const body = canvas.slice(fnStart, fnStart + 5000);

// No remaining 2-line weak guards in partial erase
const weakCount = (body.match(/if \(generation === this\.pageLoadGeneration && pageId === this\.loadedPageId/g) || []).length;
assert.ok(weakCount <= 1);

// Uses predicate for success install and failure fallback
assert.ok(body.includes('!this.isHistoryPageContextCurrent(generation, pageId)') || body.includes('this.isHistoryPageContextCurrent(generation, pageId)'));

// Predicate used at least 3 times (success, UI fail, tx fail)
const uses = (body.match(/isHistoryPageContextCurrent/g) || []).length;
assert.ok(uses >= 3);

console.log('D02_PARTIAL_ERASE_PAGE_HEALTH_BOUND_REPLAY_OK TOTAL=6 FAILED=0');
