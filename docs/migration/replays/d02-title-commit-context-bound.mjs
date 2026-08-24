import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const start = page.indexOf(
  'private async commitTitle(requested: string, generation: number): Promise<void> {',
);
const end = page.indexOf('\n  private publishTitleDraft', start);
assert.ok(start !== -1 && end > start);
const body = page.slice(start, end);

const titleAwait = body.indexOf('await this.noteRepo.updateNoteTitle(');
const disposedGate = body.indexOf('if (this.editorDisposed) {', titleAwait);
const identityGate = body.indexOf(
  "if (this.pages[this.currentPageIndex]?.pageId !== selectedPageId) {",
  disposedGate,
);
const stalePublish = body.indexOf('this.noteTitle = persisted.materializedTitle;', identityGate);
const staleAction = body.indexOf('action.titleBefore = persisted.before;', stalePublish + 1);
const normalPublish = body.lastIndexOf('this.noteTitle = persisted.materializedTitle;');
const historyPush = body.indexOf('bridge.pushPageAction(action, history);');
assert.ok(titleAwait >= 0 && disposedGate > titleAwait && identityGate > disposedGate,
  'title persistence is followed by disposal and page-identity authorization');
assert.ok(stalePublish > identityGate && staleAction > stalePublish,
  'page-drift path materializes durable title before returning without action work');
assert.ok(normalPublish < historyPush,
  'accepted title continuation publishes before undo history');

console.log('D02_TITLE_COMMIT_CONTEXT_BOUND_REPLAY_OK TOTAL=4 FAILED=0');
