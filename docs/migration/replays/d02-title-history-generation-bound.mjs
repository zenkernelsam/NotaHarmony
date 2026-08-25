import assert from 'node:assert/strict';
import fs from 'node:fs';

const canvas = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

assert.match(page,
  /private titleSaveQueue: Promise<void> = Promise\.resolve\(\);\s+private titleSaveGeneration: number = 0;/);
const saveStart = page.indexOf('  private saveTitle(): Promise<void> {');
const commitStart = page.indexOf('  private async commitTitle(', saveStart);
assert.ok(saveStart >= 0 && commitStart > saveStart);
const saveBody = page.slice(saveStart, commitStart);
const queueAssign = saveBody.indexOf('this.titleSaveInFlightCount++;');
const finallyReset = saveBody.indexOf('this.titleSaveInFlightCount--;', queueAssign);
assert.ok(queueAssign >= 0 && finallyReset > queueAssign,
  'title saves expose an authoritative in-flight boundary');

const callbackIndex = page.indexOf('onApplyNoteTitleHistory: (action: UndoableAction, isUndo: boolean,');
const bridgeIndex = page.indexOf('onHistoryBridgeReady:', callbackIndex);
assert.ok(callbackIndex >= 0 && bridgeIndex > callbackIndex);

const callbackBody = page.slice(callbackIndex, bridgeIndex);
const gate = callbackBody.indexOf('if (this.pageOperationBusy || this.titleSaveInFlightCount > 0) {');
const staleReturn = callbackBody.indexOf('return Promise.resolve(false);', gate);
const applyCall = callbackBody.indexOf('return this.runPageHistoryOperation(action, isUndo, history);', staleReturn);
assert.ok(gate >= 0 && staleReturn > gate && applyCall > staleReturn,
  'title history applies only for the current queued save generation and outside page operations');

const branchStart = canvas.indexOf('if (this.isPageAction(action.type)) {');
const groupStart = canvas.indexOf('if (action.type === UndoableActionType.GROUP_ELEMENTS) {', branchStart);
assert.ok(branchStart >= 0 && groupStart > branchStart);
const branch = canvas.slice(branchStart, groupStart);
const dispatch = branch.indexOf('const applyPromise = this.isNoteTitleAction(action.type)');
const titleCall = branch.indexOf('this.onApplyNoteTitleHistory(action, isUndo, history)', dispatch);
const genericCall = branch.indexOf('this.onApplyPageHistory(action, isUndo, history)', titleCall);
assert.ok(dispatch >= 0 && titleCall > dispatch && genericCall > titleCall,
  'NOTE_TITLE uses the generation-bound title history entry');

console.log('D02_TITLE_HISTORY_GENERATION_BOUND_REPLAY_OK TOTAL=3 FAILED=0');
