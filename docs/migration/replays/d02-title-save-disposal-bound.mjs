import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const disappearStart = page.indexOf('aboutToDisappear(): void {');
const onBackStart = page.indexOf('\n  onBackPress()', disappearStart);
const disappear = page.slice(disappearStart, onBackStart);
assert.match(disappear, /this\.editorDisposed = true;/);

const commitStart = page.indexOf('private async commitTitle(requested: string, generation: number): Promise<void> {');
const publishStart = page.indexOf('private publishTitleDraft(value: string, generation: number): void {', commitStart);
const commit = page.slice(commitStart, publishStart);
const guards = (commit.match(/if \(this\.editorDisposed\) \{\s+return;\s+\}/g) ?? []).length;
assert.equal(guards, 2);
assert.match(commit,
  /await this\.noteRepo\.updateNoteTitle\([\s\S]*?\);\s+if \(this\.editorDisposed\) \{\s+return;\s+\}/);
assert.match(commit, /\} catch \(e\) \{\s+if \(this\.editorDisposed\) \{\s+return;\s+\}/);

console.log('D02_TITLE_SAVE_DISPOSAL_BOUND_REPLAY_OK TOTAL=3 FAILED=0');
