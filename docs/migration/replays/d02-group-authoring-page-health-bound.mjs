import assert from 'node:assert/strict';
import fs from 'node:fs';

const canvas = fs.readFileSync(
  'note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8');

assert.match(canvas,
  /private isHistoryPageContextCurrent\(generation: number, pageId: string\): boolean \{\s+return this\.lifecycleActive && generation === this\.pageLoadGeneration &&\s+pageId === this\.loadedPageId && pageId === this\.currentPage\.pageId &&\s+this\.loaded && !this\.dataLoading && !this\.dataLoadFailed;\s+\}/);

function authoringBody(functionName) {
  const startMarker = 'private ' + functionName + '(): void {';
  const start = canvas.indexOf(startMarker);
  assert.notEqual(start, -1);
  const end = canvas.indexOf('\n  private ', start + 1);
  assert.notEqual(end, -1);
  return canvas.slice(start, end);
}

for (const [functionName, operationName] of [
  ['groupSelectedElements', 'Group'],
  ['ungroupSelectedElements', 'Ungroup'],
]) {
  const body = authoringBody(functionName);

  assert.match(body, /const pageId: string = this\.loadedPageId;/);
  assert.match(body, /const generation: number = this\.pageLoadGeneration;/);
  assert.ok(body.includes(operationName + ' committed after page changed; durable history remains available'));
  assert.ok(!body.includes('if (generation !== this.pageLoadGeneration'));

  const successIndex = body.indexOf(operationName + ' committed after page changed');
  assert.ok(body.includes('!this.isHistoryPageContextCurrent(generation, pageId)'));
  const guardPos = body.indexOf('!this.isHistoryPageContextCurrent(generation, pageId)');
  const afterGuard = body.slice(guardPos);
  assert.ok(afterGuard.includes('this.undoRedo.push(action, prepared);'));
  assert.ok(afterGuard.includes('this.originalInkIneligiblePages.delete(pageId);'));

  const failIdx = body.indexOf(operationName + ' failed for stale page');
  assert.notEqual(failIdx, -1);
  const afterFail = body.slice(failIdx);
  assert.ok(afterFail.includes('if (this.isHistoryPageContextCurrent(generation, pageId)) {'));
  assert.ok(afterFail.includes('this.reportSaveFailure(e);'));
}

console.log('D02_GROUP_AUTHORING_PAGE_HEALTH_BOUND_REPLAY_OK TOTAL=12 FAILED=0');
