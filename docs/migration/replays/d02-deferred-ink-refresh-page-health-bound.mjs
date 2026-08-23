import assert from 'node:assert/strict';
import fs from 'node:fs';

const canvas = fs.readFileSync(
  'note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8');

const predicatePattern = /private isHistoryPageContextCurrent\(generation: number, pageId: string\): boolean \{\s+return this\.lifecycleActive && generation === this\.pageLoadGeneration &&\s+pageId === this\.loadedPageId && pageId === this\.currentPage\.pageId &&\s+this\.loaded && !this\.dataLoading && !this\.dataLoadFailed;\s+\}/;
assert.match(canvas, predicatePattern);

function functionBody(name) {
  let start = canvas.indexOf(`private ${name}`);
  if (start === -1 && name === 'onSelectionMenuAction') {
    start = canvas.indexOf('onSelectionMenuAction(action: SelectionMenuAction): void');
  }
  assert.notEqual(start, -1);
  const nextStart = canvas.indexOf('\n  private ', start + 1);
  return canvas.slice(start, nextStart === -1 ? canvas.length : nextStart);
}

for (const name of ['onSelectionMenuAction', 'commitOriginalPartialErase', 'applyClipboardPaste']) {
  const body = functionBody(name);
  assert.match(body, /isHistoryPageContextCurrent\((?:persistedGeneration|generation), (?:persistedPageId|pageId)\)[\s\S]{0,180}refreshOriginalInkReservation\(/);
}

assert.ok(!canvas.includes('this.refreshOriginalInkReservation(this.pageLoadGeneration, persistedPageId);'));

console.log('D02_DEFERRED_INK_REFRESH_PAGE_HEALTH_BOUND_REPLAY_OK TOTAL=7 FAILED=0');
