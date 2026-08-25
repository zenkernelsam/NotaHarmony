#!/usr/bin/env node
import assert from 'node:assert/strict';
import fs from 'node:fs';

const canvas = fs.readFileSync(
  'note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets',
  'utf8').replaceAll('\r\n', '\n');

assert.match(canvas,
  /private resumePendingHistory\(\): void \{\s+if \(this\.pendingHistoryDirection === 0\) \{\s+return;\s+\}\s+if \(!this\.lifecycleActive \|\| !this\.loaded \|\| this\.dataLoading \|\| this\.dataLoadFailed \|\|\s+this\.historyBusy\) \{\s+this\.pendingHistoryDirection = 0;\s+this\.onPageHistorySettled\(false\);\s+return;\s+\}/);

const switchStart = canvas.indexOf(
  'private async switchPageData(): Promise<void> {');
const failureMarker =
  "console.error(`NoteCanvasView page switch failed: ${JSON.stringify(e)}`);";
const failureIndex = canvas.indexOf(failureMarker, switchStart);
const catchIndex = canvas.indexOf('} catch (e) {', switchStart);
const finallyIndex = canvas.indexOf('} finally {', failureIndex);
assert.ok(switchStart >= 0 && catchIndex > switchStart &&
  failureIndex > catchIndex && finallyIndex > failureIndex);

const releaseBlock = [
  'if (this.pendingHistoryDirection !== 0) {',
  'this.pendingHistoryDirection = 0;',
  'this.onPageHistorySettled(false);',
].join('\n        ');
const releaseSource = canvas.slice(catchIndex, failureIndex);
assert.ok(releaseSource.includes(releaseBlock));

const operationStart = page.indexOf('private async runPageOperation(');
const historyStart = page.indexOf('private async runPageHistoryOperation(',
  operationStart);
assert.ok(operationStart >= 0 && historyStart > operationStart);
const operationBody = page.slice(operationStart, historyStart);
const gateIndex = operationBody.indexOf('if (this.photoImportLeaseActive ||');
const structureIndex = operationBody.indexOf('this.pageStructureLeaseActive', gateIndex);
const returnIndex = operationBody.indexOf('return;', structureIndex);
assert.ok(gateIndex >= 0 && structureIndex > gateIndex && returnIndex > structureIndex,
  'structure operations also reject an active photo import lease');

console.log(
  'D02_CROSS_PAGE_HISTORY_FAILURE_RELEASE_REPLAY_OK TOTAL=10 FAILED=0');
