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
assert.ok(addPublishIndex > 0 && add.indexOf('this.currentPageIndex = insertIndex;', addPublishIndex) > 0,
  'new-page selection lands on the anchor position in the published list');

const remove = section('  private async deleteCurrentPage(', '  private async moveCurrentPage(');
const flushAwait = remove.indexOf('await historyBridge.flushCurrentPage()');
const bridgeCapture = remove.indexOf(
  'const historyBridge: EditorHistoryBridge = this.historyBridge;',
  0,
);
const identityGate = remove.indexOf(
  "if (this.pages[pageIndex]?.pageId !== pageId) {",
  flushAwait,
);
const snapshotIndex = remove.indexOf(
  'const snapshot: PageContentSnapshot = isCurrent ?',
  identityGate,
);
assert.ok(bridgeCapture >= 0 && flushAwait >= 0 && identityGate > flushAwait &&
  snapshotIndex > identityGate,
  'delete snapshots only if flush did not switch to another page');
const removeAwait = remove.indexOf(
  'const pageRepository: PageRepositoryImpl | null = this.pageRepo;',
);
const durableRepositoryGuard = remove.indexOf(
  'if (pageRepository === null) {',
  removeAwait,
);
const durableCall = remove.indexOf('deletePageWithCheckpoint(this.noteId, pageId, history)', removeAwait);
const removeGuard = remove.indexOf(guard, durableCall);
assert.ok(removeAwait !== -1 && removeGuard > removeAwait &&
  durableCall > durableRepositoryGuard &&
  removeGuard < remove.indexOf('const updated: PageInfo[] = [];', removeAwait));
assert.ok(durableRepositoryGuard > removeAwait, 'durable delete rechecks the captured repository');
assert.match(remove, /catch \(e\) \{\s+historyBridge\.cancelPageRemoval\(pageId\);/);
const publishIndex = remove.indexOf('this.pages = updated;');
// de2.i compensation: the captured successor is used for plain deletes, the
// returned blank page becomes the selection for compensated deletes.
assert.ok(remove.indexOf("selectedAfter: string = !isCurrent ? selectedBefore :") >= 0 &&
  publishIndex > 0);
assert.match(remove.slice(publishIndex),
  /this\.selectPageById\(isCurrent && compensation !== null \? compensation\.pageId : selectedAfter\);/,
  'post-deletion selection uses the captured successor ID');

const move = section('  private async moveCurrentPage(', '  private async applyPageHistory(');
const moveAwait = move.indexOf('await this.pageRepo.reorderPages(');
const moveGuard = move.indexOf(guard, moveAwait);
assert.ok(moveAwait !== -1 && moveGuard > moveAwait &&
  moveGuard < move.indexOf('this.pages = this.orderPages(this.pages, orderAfter);', moveAwait));
const moveGate = move.indexOf(
  "if (this.pages[this.currentPageIndex]?.pageId !== selectedPageId) {",
  moveGuard,
);
const movePublish = move.indexOf('this.pages = this.orderPages(this.pages, orderAfter);', moveGate);
assert.ok(moveGate > moveGuard && movePublish > moveGate,
  'move continuation is rejected after user page switch before stale order publication');

console.log('D02_PAGE_OPERATION_DISPOSAL_BOUND_REPLAY_OK TOTAL=15 FAILED=0');
