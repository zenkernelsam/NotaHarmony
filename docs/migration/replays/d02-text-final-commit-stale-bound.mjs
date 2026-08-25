import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8')
  .replaceAll('\r\n', '\n');

assert.match(page, /private textCommitGeneration: number = 0;/);
const start = page.indexOf('  async onTextCommit(text: string): Promise<boolean> {');
const end = page.indexOf('  onTextCancel(): void {', start);
assert.ok(start !== -1 && end !== -1 && end > start);
const body = page.slice(start, end);

const generationIndex = body.indexOf('const commitGeneration: number = ++this.textCommitGeneration;');
const busyIndex = body.indexOf('this.historyBusy');
const photoIndex = body.indexOf('this.photoImportBusy');
assert.ok(busyIndex >= 0 && generationIndex > busyIndex);
assert.ok(photoIndex >= 0 && photoIndex < busyIndex,
  'shared ingress lease is rejected before the history guard');

const previewIndex = body.indexOf('await this.persistence.previewOriginalTextEdit(');
const staleGuard = body.indexOf('if (commitGeneration !== this.textCommitGeneration ||', previewIndex);
assert.ok(previewIndex !== -1 && staleGuard > previewIndex);
assert.match(body,
  /if \(commitGeneration !== this\.textCommitGeneration \|\|\s+this\.editingTextBlock !== editing \|\| this\.editingOriginalTextBlock !== original \|\|\s+!this\.isHistoryPageContextCurrent\(generation, pageId\)\) \{\s+hilog\.error\(0x0001, 'NoteCanvasView',\s+'original Text edit rejected after page changed'\);\s+return false;\s+\}/);

for (const effect of [
'this.textEditing = false;',
  'this.persist(rearmOriginalCreate);',
]) {
  const effectIndex = body.indexOf(effect);
  assert.ok(effectIndex > staleGuard, `${effect} is bound behind the stale guard`);
}

console.log('D02_TEXT_FINAL_COMMIT_STALE_BOUND_REPLAY_OK TOTAL=6 FAILED=0');
