import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

assert.match(page, /@State pageOperationBusy: boolean = false;\n  @State photoImportLeaseActive: boolean = false;\n  private pageStructureLeaseActive: boolean = false;/);
assert.doesNotMatch(page, /pageRemovalLeaseActive/);

const deleteStart = page.indexOf('  private async deleteCurrentPage(): Promise<void> {');
const moveStart = page.indexOf('  private async moveCurrentPage(', deleteStart);
assert.ok(deleteStart >= 0 && moveStart > deleteStart);
const deleteBody = page.slice(deleteStart, moveStart);

// Original de2.i compensation: the last page is deletable (a blank replaces
// it), so the preflight only rejects an empty note.
const preflight = deleteBody.indexOf(
  'if (this.pageRepo === null || this.pages.length === 0 || this.historyBridge === null) {');
const leaseSet = deleteBody.indexOf('this.pageStructureLeaseActive = true;', preflight);
const lockedCall = deleteBody.indexOf('await this.deleteCurrentPageLocked(historyBridge);', leaseSet);
const finallyRelease = deleteBody.indexOf('} finally {', lockedCall);
const releaseStatement = deleteBody.indexOf(
  'this.pageStructureLeaseActive = false;', finallyRelease);
assert.ok(preflight >= 0 && leaseSet > preflight && lockedCall > leaseSet &&
  finallyRelease > lockedCall && releaseStatement > finallyRelease);
assert.equal(deleteBody.indexOf('this.pageStructureLeaseActive = false;', releaseStatement + 1), -1,
  'the structure lease is released exactly once by its owning wrapper');

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
  assert.ok(page.slice(start, end).includes('!this.pageOperationBusy') &&
    page.slice(start, end).includes('!this.historyPending') &&
    page.slice(start, end).includes('!this.pageStructureLeaseActive'),
    `${name} rejects an active structure lease`);
}


const requestStart = page.indexOf('onRequestPage: (pageId: string) => {');
const requestSettled = page.indexOf('onPageHistorySettled:', requestStart);
assert.ok(requestStart >= 0 && requestSettled > requestStart);
const requestSection = page.slice(requestStart, requestSettled);
const requestGate = requestSection.indexOf('if (this.photoImportLeaseActive ||');
const requestStructure = requestSection.indexOf('this.pageStructureLeaseActive', requestGate);
const requestReturn = requestSection.indexOf('return;', requestGate);
const pageIndexMutation = requestSection.indexOf('this.currentPageIndex = i;');
assert.ok(requestGate >= 0 && requestStructure > requestGate && requestReturn > requestStructure &&
  pageIndexMutation > requestReturn,
  'history page requests cannot retarget selection during a page operation or structure lease');

console.log('D02_PAGE_STRUCTURE_LEASE_BOUND_REPLAY_OK TOTAL=10 FAILED=0');
