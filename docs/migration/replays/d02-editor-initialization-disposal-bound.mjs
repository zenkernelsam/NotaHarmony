import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const start = page.indexOf('private async loadPages(): Promise<void> {');
const end = page.indexOf('// Original title commits are serialized', start);
assert.ok(start !== -1 && end !== -1);
const body = page.slice(start, end);

const catchStart = body.lastIndexOf('} catch (e) {');
const catchBody = body.slice(catchStart);
assert.match(catchBody,
  /if \(loadGeneration !== this\.pageLoadGeneration \|\| this\.editorDisposed\) \{\s+return;\s+\}/);

for (const effect of [
  'this.pages = [];',
  'this.pageLoadFailed = true;',
  "$r('app.string.note_open_failed')",
]) {
  const effectIndex = catchBody.indexOf(effect);
  const guardIndex = catchBody.indexOf('this.editorDisposed');
  assert.ok(effectIndex !== -1 && effectIndex > guardIndex, effect);
}

assert.match(body, /if \(loadGeneration !== this\.pageLoadGeneration\) \{\s+return;\s+\}/);

console.log('D02_EDITOR_INITIALIZATION_DISPOSAL_BOUND_REPLAY_OK TOTAL=5 FAILED=0');