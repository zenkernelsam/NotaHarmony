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
  'this.failureDialog.open();',
]) {
  const effectIndex = catchBody.indexOf(effect);
  const guardIndex = catchBody.indexOf('this.editorDisposed');
  assert.ok(effectIndex !== -1 && effectIndex > guardIndex, effect);
}

assert.match(body,
  /if \(this\.editorDisposed \|\| loadGeneration !== this\.pageLoadGeneration\) \{\s+return;\s+\}/);
// Original u49.a parity (Phase 543): the retry button was removed — the
// failure surface is a terminal dialog whose dismissal routes back once.
assert.match(page,
  /private dismissLoadFailure\(\): void \{\s+if \(this\.failureDismissHandled \|\| this\.editorDisposed\) \{\s+return;\s+\}\s+this\.failureDismissHandled = true;\s+router\.back\(\);/,
  'disposed editor failure dismiss rejects before navigation');

const initializeCall = body.match(/await this\.viewModel\.initialize\([\s\S]*?\);/);
assert.ok(initializeCall, 'view model initialization call');
assert.match(initializeCall[0], /'primary-editor'/);
assert.match(initializeCall[0], /editorDisposed/);
assert.match(initializeCall[0], /loadGeneration === this\.pageLoadGeneration/);

console.log('D02_EDITOR_INITIALIZATION_DISPOSAL_BOUND_REPLAY_OK TOTAL=7 FAILED=0');
