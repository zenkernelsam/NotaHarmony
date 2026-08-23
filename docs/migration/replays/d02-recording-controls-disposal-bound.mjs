import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const start = page.indexOf('private async pauseRecording(): Promise<void> {');
const end = page.indexOf('\n  private closeRecordings', start);
assert.ok(start !== -1 && end > start);

const controls = page.slice(start, end);
const guards = (controls.match(/if \(this\.editorDisposed\) \{\s+return;\s+\}/g) ?? []).length;
assert.equal(guards, 3);
for (const op of ['pause', 'resume', 'stop']) {
  assert.match(controls,
    new RegExp(`private async ${op}Recording\\(\\): Promise<void> \\{\\s+if \\(this\\.editorDisposed\\) \\{\\s+return;\\s+\\}`));
}

console.log('D02_RECORDING_CONTROLS_DISPOSAL_BOUND_REPLAY_OK TOTAL=3 FAILED=0');
