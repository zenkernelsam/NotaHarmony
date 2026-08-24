import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const guard = 'if (this.editorDisposed) {\n      return;\n    }';

function section(startMarker, endMarker) {
  const start = page.indexOf(startMarker);
  const end = page.indexOf(endMarker, start);
  assert.ok(start !== -1 && end > start, startMarker);
  return page.slice(start, end);
}

const background = section('  private async applyNoteBackgroundSettings(', '  private async runPageOperation(');
const backgroundAwait = background.indexOf('await this.pageRepo.updateNoteBackground(');
const earlySelection = background.indexOf('this.selectPageById(selectedPageId);', backgroundAwait);
const pagesRefresh = background.indexOf('await this.pageRepo.getPages(this.noteId);', earlySelection);
assert.ok(backgroundAwait >= 0 && earlySelection > backgroundAwait && pagesRefresh > earlySelection,
  'background continuation reselects its target before the async page refresh');
const actionEffect = background.indexOf('action.backgroundAfter = cloneNoteBackgroundSettings(materialized);');
const settingsEffect = background.indexOf('this.noteBackground = materialized;', pagesRefresh);
assert.notEqual(actionEffect, -1);
assert.notEqual(settingsEffect, -1);
assert.ok(background.lastIndexOf(guard, actionEffect) !== -1, 'background guard before action effect');
assert.ok(background.lastIndexOf(guard, settingsEffect) !== -1, 'background guard before settings publication');

const add = section('  private async addPage(): Promise<void> {', '  private async deleteCurrentPage(');
const addAwait = add.indexOf('await this.pageRepo.addPage(');
const addGuard = add.indexOf(guard, addAwait);
assert.ok(addAwait !== -1 && addGuard > addAwait &&
  addGuard < add.indexOf('action.pageId = assignedPage.pageId;', addAwait));
const addSelectionIndex = add.indexOf('this.currentPageIndex = this.pages.findIndex(', addGuard);
const addMutationIndex = add.indexOf('action.pageId = assignedPage.pageId;', addGuard);
assert.ok(addSelectionIndex > addGuard && addSelectionIndex < addMutationIndex,
  'accepted add selects the assigned page before publishing history action');
const originGateIndex = add.indexOf(
  "if (this.pages[this.currentPageIndex]?.pageId !== selectedBefore) {",
  addGuard,
);
assert.ok(originGateIndex > addGuard && originGateIndex < addSelectionIndex,
  'add continuation is rejected if the user switched pages during persistence');
const addPublishIndex = add.indexOf('this.pages = updated;', addMutationIndex);
assert.ok(addPublishIndex > 0 && add.indexOf('this.currentPageIndex = updated.length - 1;', addPublishIndex) > 0,
  'new-page selection uses the published list length');

const remove = section('  private async deleteCurrentPage(', '  private async moveCurrentPage(');
const flushAwait = remove.indexOf('await this.historyBridge.flushCurrentPage()');
const identityGate = remove.indexOf(
  "if (this.pages[this.currentPageIndex]?.pageId !== pageId) {",
  flushAwait,
);
const snapshotIndex = remove.indexOf(
  'const snapshot: PageContentSnapshot = this.historyBridge.captureCurrentPage();',
  identityGate,
);
assert.ok(flushAwait >= 0 && identityGate > flushAwait && snapshotIndex > identityGate,
  'delete snapshots only if flush did not switch to another page');
const removeAwait = remove.indexOf('await this.pageRepo.deletePageWithCheckpoint(');
const removeGuard = remove.indexOf(guard, removeAwait);
assert.ok(removeAwait !== -1 && removeGuard > removeAwait &&
  removeGuard < remove.indexOf('const updated: PageInfo[] = [];', removeAwait));
assert.match(remove, /catch \(e\) \{\s+this\.historyBridge\.cancelPageRemoval\(pageId\);/);
const publishIndex = remove.indexOf('this.pages = updated;');
assert.ok(remove.indexOf("selectedAfter: string = orderAfter[") >= 0 && publishIndex > 0);
assert.match(remove.slice(publishIndex),
  /this\.selectPageById\(selectedAfter\);/,
  'post-deletion selection uses the captured successor ID');

const move = section('  private async moveCurrentPage(', '  private async applyPageHistory(');
const moveAwait = move.indexOf('await this.pageRepo.reorderPages(');
const moveGuard = move.indexOf(guard, moveAwait);
assert.ok(moveAwait !== -1 && moveGuard > moveAwait &&
  moveGuard < move.indexOf('this.pages = this.orderPages(this.pages, orderAfter);', moveAwait));

console.log('D02_PAGE_OPERATION_DISPOSAL_BOUND_REPLAY_OK TOTAL=14 FAILED=0');
