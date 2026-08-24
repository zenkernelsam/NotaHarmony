import assert from 'node:assert/strict';
import fs from 'node:fs';

const canvas = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const saveStart = canvas.lastIndexOf('this.persistence.flush(this.noteId, persistedPageId).then((): void => {');
const helperStart = canvas.indexOf('private createClipboardElementId(', saveStart);
assert.ok(saveStart !== -1 && helperStart > saveStart, 'ordinary paste deferred continuation');
const body = canvas.slice(saveStart, helperStart);

const catchIndex = body.indexOf('.catch((e: Object): void => {');
assert.ok(catchIndex > 0, 'deferred failure continuation');
const success = body.slice(0, catchIndex);
const failure = body.slice(catchIndex);

assert.match(success, /if \(this\.isHistoryPageContextCurrent\(persistedGeneration, persistedPageId\) &&\s+!this\.persistence\.hasDirtySave\(this\.noteId, persistedPageId\)\) \{\s+this\.saveFailed = false;/);
assert.equal(success.indexOf('persistedGeneration === this.pageLoadGeneration'), -1, 'success uses shared guard');

const reportIndex = failure.indexOf('this.reportSaveFailure(e);');
const guardIndex = failure.lastIndexOf('if (this.isHistoryPageContextCurrent(persistedGeneration, persistedPageId)) {', reportIndex);
assert.ok(reportIndex !== -1 && guardIndex !== -1 && guardIndex < reportIndex, 'failure toast is disposal bound');

console.log('D02_ORDINARY_PASTE_FAILURE_DISPOSAL_BOUND_REPLAY_OK TOTAL=6 FAILED=0');
