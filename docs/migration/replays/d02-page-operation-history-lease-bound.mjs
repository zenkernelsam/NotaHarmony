import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const operationStart = page.indexOf('  private async runPageOperation(');
const historyStart = page.indexOf('  private async runPageHistoryOperation(', operationStart);
const addStart = page.indexOf('  private async addPage(): Promise<void> {');
assert.ok(operationStart >= 0 && historyStart > operationStart && addStart > historyStart);
const operationBody = page.slice(operationStart, historyStart);

const busyGate = operationBody.indexOf(
  'if (this.photoImportLeaseActive || this.pageOperationBusy || this.historyPending ||\n      this.pageStructureLeaseActive) {');
const gateReturn = operationBody.indexOf('return;', busyGate);
const setBusy = operationBody.indexOf('this.pageOperationBusy = true;', gateReturn);
const tryOpen = operationBody.indexOf('try {', setBusy);
const awaitOperation = operationBody.indexOf('await operation();', tryOpen);
const finallyOpen = operationBody.indexOf('} finally {', awaitOperation);
const clearBusy = operationBody.indexOf('this.pageOperationBusy = false;', finallyOpen);
assert.ok(busyGate >= 0 && gateReturn > busyGate && setBusy > gateReturn &&
  tryOpen > setBusy && awaitOperation > tryOpen && finallyOpen > awaitOperation &&
  clearBusy > finallyOpen, 'structure operations acquire one exclusive lease only after all history gates pass');

const historyBody = page.slice(historyStart, addStart);
const historyGate = historyBody.indexOf('if (this.pageOperationBusy) {');
const historyReturn = historyBody.indexOf('return false;', historyGate);
const historySet = historyBody.indexOf('this.pageOperationBusy = true;', historyReturn);
const historyTry = historyBody.indexOf('try {', historySet);
const applyCall = historyBody.indexOf('await this.applyPageHistory(action, isUndo, history);', historyTry);
const historyFinally = historyBody.indexOf('} finally {', applyCall);
const historyClear = historyBody.indexOf('this.pageOperationBusy = false;', historyFinally);
assert.ok(historyGate >= 0 && historyReturn > historyGate && historySet > historyReturn &&
  historyTry > historySet && applyCall > historyTry && historyFinally > applyCall &&
  historyClear > historyFinally,
  'durable page history owns the same operation lease through success and failure');
assert.equal(historyBody.indexOf('this.pageOperationBusy = false;', historyClear + 1), -1);

for (const [name, callback] of [
  ['title history', page.slice(page.indexOf('onApplyNoteTitleHistory:'), page.indexOf('onHistoryBridgeReady:'))],
  ['metadata history', page.slice(page.indexOf('onApplyNoteMetadataHistory:'), page.indexOf('onSelectionInkControlsChanged:'))],
  ['generic page history', page.slice(page.indexOf('onApplyPageHistory:'), page.indexOf('})\n          .layoutWeight(1)'))],
]) {
  assert.match(callback, /runPageHistoryOperation\(action, isUndo, history\)/, name);
}

for (const [name, callback] of [
  ['title flight gate', page.slice(page.indexOf('onApplyNoteTitleHistory:'), page.indexOf('runPageHistoryOperation'))],
  ['metadata flight gate', page.slice(page.indexOf('onApplyNoteMetadataHistory:'), page.lastIndexOf('runPageHistoryOperation'))],
]) {
  assert.match(callback, /this\.titleSaveInFlightCount > 0/, `${name} remains specialized`);
}

for (const [name, section] of [
  ['prev navigation', page.slice(page.indexOf('onPrev: () =>'), page.indexOf('onNext: () =>'))],
  ['next navigation', page.slice(page.indexOf('onNext: () =>'), page.indexOf('onAdd: () =>'))],
  ['cross-page request', page.slice(page.indexOf('onRequestPage:'), page.indexOf('onPageHistorySettled:'))],
]) {
  assert.match(section, /pageStructureLeaseActive/, `${name} keeps its structure-lease rejection`);
}

console.log('D02_PAGE_OPERATION_HISTORY_LEASE_BOUND_REPLAY_OK TOTAL=10 FAILED=0');
