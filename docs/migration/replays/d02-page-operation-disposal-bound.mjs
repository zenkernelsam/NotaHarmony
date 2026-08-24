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
for (const effect of [
  'action.backgroundAfter = cloneNoteBackgroundSettings(materialized);',
  'this.noteBackground = materialized;',
]) {
  const effectIndex = background.indexOf(effect);
  assert.notEqual(effectIndex, -1, effect);
  assert.ok(background.lastIndexOf(guard, effectIndex) !== -1, `background guard before ${effect}`);
}

const add = section('  private async addPage(): Promise<void> {', '  private async deleteCurrentPage(');
const addAwait = add.indexOf('await this.pageRepo.addPage(');
const addGuard = add.indexOf(guard, addAwait);
assert.ok(addAwait !== -1 && addGuard > addAwait &&
  addGuard < add.indexOf('action.pageId = assignedPage.pageId;', addAwait));

const remove = section('  private async deleteCurrentPage(', '  private async moveCurrentPage(');
const removeAwait = remove.indexOf('await this.pageRepo.deletePageWithCheckpoint(');
const removeGuard = remove.indexOf(guard, removeAwait);
assert.ok(removeAwait !== -1 && removeGuard > removeAwait &&
  removeGuard < remove.indexOf('const updated: PageInfo[] = [];', removeAwait));
assert.match(remove, /catch \(e\) \{\s+this\.historyBridge\.cancelPageRemoval\(pageId\);/);

const move = section('  private async moveCurrentPage(', '  private async applyPageHistory(');
const moveAwait = move.indexOf('await this.pageRepo.reorderPages(');
const moveGuard = move.indexOf(guard, moveAwait);
assert.ok(moveAwait !== -1 && moveGuard > moveAwait &&
  moveGuard < move.indexOf('this.pages = this.orderPages(this.pages, orderAfter);', moveAwait));

console.log('D02_PAGE_OPERATION_DISPOSAL_BOUND_REPLAY_OK TOTAL=8 FAILED=0');
