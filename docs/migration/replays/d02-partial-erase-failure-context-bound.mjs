import assert from 'node:assert/strict';
import fs from 'node:fs';

const canvas = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const marker = canvas.indexOf('original partial erase committed after stale page');
const start = canvas.lastIndexOf('  private commitOriginalPartialErase(', marker);
const end = canvas.indexOf('  private applyPartialEraseLocally(', start);
assert.ok(marker >= 0 && start >= 0 && end > start, 'startPartialErase section exists');
const body = canvas.slice(start, end);

assert.match(body,
  /persistence\.commitOriginalPartialErase\([\s\S]*?\.then\(/, 'durable commit is asynchronous');

const successGuardIndex = body.indexOf('if (!this.isHistoryPageContextCurrent(generation, pageId)) {');
const rejectionIndex = body.indexOf('}, (e: Object): void => {', successGuardIndex);
const completeIndex = body.indexOf('this.partialEraserPreview.complete(previewToken);', rejectionIndex);
const errorIndex = body.indexOf("'original partial erase transaction failed: %{public}s'", completeIndex);
const guardIndex = body.indexOf('if (this.isHistoryPageContextCurrent(generation, pageId)) {', errorIndex);
const toastIndex = body.indexOf('this.reportSaveFailure(e);', guardIndex);
const fallbackIndex = body.indexOf('this.applyPartialEraseLocally(plan, prepared);', guardIndex);
assert.ok(successGuardIndex > 0 && rejectionIndex > successGuardIndex && completeIndex > rejectionIndex &&
  errorIndex > completeIndex && guardIndex > errorIndex && toastIndex > guardIndex && fallbackIndex > toastIndex,
  'rejection completes preview, logs durable failure, then gates UI and local fallback');

assert.doesNotMatch(body.slice(completeIndex, guardIndex), /reportSaveFailure|applyPartialEraseLocally/,
  'no user toast or fallback precedes context gate');

console.log('D02_PARTIAL_ERASE_FAILURE_CONTEXT_BOUND_REPLAY_OK TOTAL=5 FAILED=0');
