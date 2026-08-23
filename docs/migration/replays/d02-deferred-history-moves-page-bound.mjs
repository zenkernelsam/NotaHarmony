import assert from 'node:assert/strict';
import fs from 'node:fs';

const canvas = fs.readFileSync(
  'note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8');

const staleSuccessLogs = [
  /Group history committed after page changed; durable history remains available/s,
  /original clipboard Paste history committed after page changed;[\s\S]{0,80}durable history remains available/s,
  /original partial erase history committed after page changed;[\s\S]{0,80}durable history remains available/s,
  /original handwriting conversion history committed after page changed;[\s\S]{0,80}durable history remains available/s,
  /history group committed after page changed; durable history remains available/s,
];

for (const message of staleSuccessLogs) {
  assert.match(canvas, message, `missing stale success guard: ${message}`);
}

assert.match(canvas,
  /private isHistoryPageContextCurrent\(generation: number, pageId: string\): boolean \{\s+return this\.lifecycleActive && generation === this\.pageLoadGeneration &&\s+pageId === this\.loadedPageId && pageId === this\.currentPage\.pageId &&\s+this\.loaded && !this\.dataLoading && !this\.dataLoadFailed;\s+\}/);

assert.match(canvas,
  /await this\.persistence\.flush\(this\.noteId, pageId\);\s+if \(!this\.isHistoryPageContextCurrent\(generation, pageId\)\) \{\s+hilog\.error\(0x0001, 'NoteCanvasView',\s+'history group source changed after page navigation; refusing local apply'\);/);

assert.ok(
  (canvas.match(/isHistoryPageContextCurrent/g) || []).length >= 10);

for (const functionName of [
  'applyOriginalGroupHistoryMove',
  'applyOriginalClipboardPasteHistoryMove',
  'applyOriginalPartialEraseHistoryMove',
  'applyOriginalHandwritingConversionHistoryMove',
]) {
  const functionIndex = canvas.indexOf(`private async ${functionName}(`);
  assert.notEqual(functionIndex, -1);
  const body = canvas.slice(functionIndex, canvas.indexOf('\n  }', functionIndex));
  assert.match(body,
    /if \(!this\.isHistoryPageContextCurrent\(generation, action\.pageId\)\)/);
}

console.log('D02_DEFERRED_HISTORY_MOVES_PAGE_BOUND_REPLAY_OK TOTAL=9 FAILED=0');
