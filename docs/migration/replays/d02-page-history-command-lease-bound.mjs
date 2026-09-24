import assert from 'node:assert/strict';
import fs from 'node:fs';

const canvas = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const start = canvas.indexOf('  private performHistory(isUndo: boolean): void {');
const end = canvas.indexOf('  private preparePageHistory(', start);
assert.ok(start !== -1 && end > start);
const historyBody = canvas.slice(start, end);

assert.equal(historyBody.match(/this\.pendingHistoryDirection = isUndo \? -1 : 1;/g)?.length, 6);
assert.equal(historyBody.match(/this\.pendingHistoryDirection = isUndo \? -1 : 1;\s+this\.onPageHistorySettled\(true\);\s+this\.onRequestPage\(action\.pageId\);/g)?.length, 6);
assert.match(historyBody, /if \(action\.pageId !== this\.loadedPageId\) \{\s+this\.pendingHistoryDirection = isUndo \? -1 : 1;\s+this\.onPageHistorySettled\(true\);/);

const resumeStart = canvas.indexOf('  private resumePendingHistory(): void {');
const resumeEnd = canvas.indexOf('  private isPageAction(', resumeStart);
assert.ok(resumeStart !== -1 && resumeEnd > resumeStart);
const resumeBody = canvas.slice(resumeStart, resumeEnd);
const directionRead = resumeBody.indexOf('const isUndo: boolean =');
const settledRelease = resumeBody.indexOf('this.onPageHistorySettled(false);', directionRead);
const performCall = resumeBody.indexOf('this.performHistory(isUndo);', settledRelease);
assert.ok(directionRead !== -1 && settledRelease > directionRead && performCall > settledRelease);
assert.equal(resumeBody.slice(performCall + 'this.performHistory(isUndo);'.length).includes('this.performHistory(isUndo);'), false);

const callbackIndex = page.indexOf('onPageHistorySettled: (pending: boolean) => {');
const bridgeIndex = page.indexOf('onHistoryBridgeReady:', callbackIndex);
const requestIndex = page.indexOf('onRequestPage:');
assert.ok(requestIndex >= 0 && callbackIndex > requestIndex && bridgeIndex > callbackIndex);
assert.match(page, /onPageHistorySettled: \(pending: boolean\) => \{\s+this\.historyPending = pending;\s+\},/);
assert.match(page, /onRequestPage: \(pageId: string\) => \{[\s\S]{0,360}?this\.currentPageIndex = i;\s+this\.historyPending = true;\s+return;/);

for (const [name, section] of [
  ['prev navigation lease gate', page.slice(page.indexOf('onPrev: () =>'), page.indexOf('onNext: () =>'))],
  ['next navigation lease gate', page.slice(page.indexOf('onNext: () =>'), page.indexOf('onAdd: () =>'))],
]) {
  assert.match(section, /!this\.historyPending/,
    `${name} rejects a pending cross-page history command`);
}

for (const [name, signal] of [['undo', 'this.undoSignal++'], ['redo', 'this.redoSignal++']]) {
  const trigger = page.indexOf(signal);
  const guardedStart = page.lastIndexOf('if (!this.photoImportLeaseActive', trigger);
  const guardedEnd = page.indexOf('!this.historyPending)', guardedStart);
  assert.ok(trigger >= 0 && guardedStart >= 0 && guardedEnd > guardedStart,
    `${name} rejects pending history and active photo ingress`);
}
const pageActionStart = canvas.indexOf('if (this.isPageAction(action.type)) {');
const groupActionStart = canvas.indexOf('if (action.type === UndoableActionType.GROUP_ELEMENTS) {', pageActionStart);
assert.ok(pageActionStart >= 0 && groupActionStart > pageActionStart);
const pageActionBody = canvas.slice(pageActionStart, groupActionStart);

const applyAwait = pageActionBody.indexOf('this.onApplyPageHistory(action, isUndo, history)');
const successRelease = pageActionBody.indexOf(
  'this.historyBusy = false;\n        this.onPageHistorySettled(false);',
  applyAwait,
);
const failureRelease = pageActionBody.lastIndexOf(
  'this.historyBusy = false;\n        this.onPageHistorySettled(false);',
);
assert.ok(applyAwait >= 0 && successRelease > applyAwait && failureRelease > successRelease,
  'page history commands release the navigation lease after both accepted and rejected moves');

console.log('D02_PAGE_HISTORY_COMMAND_LEASE_BOUND_REPLAY_OK TOTAL=10 FAILED=0');
