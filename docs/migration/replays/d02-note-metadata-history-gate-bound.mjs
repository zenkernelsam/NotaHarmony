import assert from 'node:assert/strict';
import fs from 'node:fs';

const canvas = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const callbackIndex = page.indexOf('onApplyNoteMetadataHistory: (action: UndoableAction, isUndo: boolean,');
const selectionIndex = page.indexOf('onSelectionInkControlsChanged:', callbackIndex);
assert.ok(callbackIndex >= 0 && selectionIndex > callbackIndex);

const callbackBody = page.slice(callbackIndex, selectionIndex);
const gate = callbackBody.indexOf('if (this.pageOperationBusy || this.titleSaveInFlightCount > 0) {');
const staleReturn = callbackBody.indexOf('return Promise.resolve(false);', gate);
const applyCall = callbackBody.indexOf('return this.applyPageHistory(action, isUndo, history);', staleReturn);
assert.ok(gate >= 0 && staleReturn > gate && applyCall > staleReturn,
  'note metadata history fails closed while serialized note state is changing');

const branchStart = canvas.indexOf('if (this.isPageAction(action.type)) {');
const groupStart = canvas.indexOf('if (action.type === UndoableActionType.GROUP_ELEMENTS) {', branchStart);
assert.ok(branchStart >= 0 && groupStart > branchStart);
const branch = canvas.slice(branchStart, groupStart);
const dispatch = branch.indexOf('const applyPromise = this.isNoteTitleAction(action.type)');
const titleCall = branch.indexOf('this.onApplyNoteTitleHistory(action, isUndo, history)', dispatch);
const metadataCheck = branch.indexOf('this.isNoteMetadataAction(action.type)', titleCall);
const metadataCall = branch.indexOf('this.onApplyNoteMetadataHistory(action, isUndo, history)', metadataCheck);
const genericCall = branch.indexOf('this.onApplyPageHistory(action, isUndo, history)', metadataCall);
assert.ok(dispatch >= 0 && titleCall > dispatch && metadataCheck > titleCall &&
  metadataCall > metadataCheck && genericCall > metadataCall,
  'note-level metadata uses its guarded history entry');

console.log('D02_NOTE_METADATA_HISTORY_GATE_BOUND_REPLAY_OK TOTAL=3 FAILED=0');
