import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

assert.match(page, /@State pageOperationBusy: boolean = false;\n  @State photoImportLeaseActive: boolean = false;\n  private pageStructureLeaseActive: boolean = false;/);

const deleteStart = page.indexOf('  private async deleteCurrentPage(): Promise<void> {');
const moveStart = page.indexOf('  private async moveCurrentPage(', deleteStart);
assert.ok(deleteStart >= 0 && moveStart > deleteStart);
const deleteBody = page.slice(deleteStart, moveStart);

const preflight = deleteBody.indexOf(
  'if (this.pageRepo === null || this.pages.length <= 1 || this.historyBridge === null) {');
const leaseSet = deleteBody.indexOf('try {', preflight);
const lockedCall = deleteBody.indexOf('await this.deleteCurrentPageLocked(historyBridge);', leaseSet);
const finallyRelease = deleteBody.indexOf('} finally {', lockedCall);
const releaseStatement = deleteBody.indexOf('this.pageStructureLeaseActive = false;', finallyRelease);
assert.ok(preflight >= 0 && leaseSet > preflight && lockedCall > leaseSet && finallyRelease > lockedCall);
assert.ok(finallyRelease > lockedCall && releaseStatement > finallyRelease);
assert.equal(deleteBody.indexOf('this.pageStructureLeaseActive = false;', releaseStatement + 1) === -1, true,
  'the deletion lease is released exactly once by its owning wrapper');

const removalPrepare = deleteBody.indexOf('historyBridge.preparePageRemoval(pageId);');
const durableDelete = deleteBody.indexOf('deletePageWithCheckpoint(this.noteId, pageId, history)');
const removalCancel = deleteBody.indexOf('historyBridge.cancelPageRemoval(pageId);');
assert.ok(removalPrepare > lockedCall && durableDelete > removalPrepare && removalCancel > durableDelete);

for (const [name, startMarker, endMarker] of [
  ['prev navigation', 'onPrev: () => {', 'onNext: () => {'],
  ['next navigation', 'onNext: () => {', 'onAdd: () => {'],
]) {
  const start = page.indexOf(startMarker);
  const end = page.indexOf(endMarker, start);
  assert.ok(start >= 0 && end > start, name);
  const section = page.slice(start, end);
  assert.ok(section.includes('!this.pageStructureLeaseActive'), `${name} rejects an active deletion lease`);
}

for (const [name, signal] of [['undo', 'this.undoSignal++'], ['redo', 'this.redoSignal++']]) {
  const trigger = page.indexOf(signal);
  assert.ok(trigger >= 0, `${name} trigger`);
  const guarded = page.lastIndexOf(
    'if (!this.photoImportLeaseActive && !this.pageOperationBusy &&\n              !this.historyPending) {',
    trigger,
  );
  const close = page.indexOf('}', trigger);
  assert.ok(guarded >= 0 && close > trigger,
    `${name} cannot dispatch during a serialized page operation`);
}

const requestStart = page.indexOf('onRequestPage: (pageId: string) => {');
const requestSettled = page.indexOf('onPageHistorySettled:', requestStart);
assert.ok(requestStart >= 0 && requestSettled > requestStart);
const requestSection = page.slice(requestStart, requestSettled);
const requestGate = requestSection.indexOf('if (this.photoImportLeaseActive ||');
const requestStructure = requestSection.indexOf('this.pageStructureLeaseActive', requestGate);
const requestReturn = requestSection.indexOf('return;', requestGate);
const pageIndexMutation = requestSection.indexOf('this.currentPageIndex = i;');
assert.ok(
  requestGate >= 0 && requestStructure > requestGate && requestReturn > requestStructure &&
    pageIndexMutation > requestReturn,
  'history page requests cannot retarget selection during a deletion lease',
);

console.log('D02_PAGE_DELETE_REMOVAL_LEASE_BOUND_REPLAY_OK TOTAL=10 FAILED=0');
