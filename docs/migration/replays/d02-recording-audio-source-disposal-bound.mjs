import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const start = page.indexOf('private async startRecording(): Promise<void> {');
const end = page.indexOf('\n  private async pauseRecording', start);
assert.ok(start !== -1 && end > start);

const fn = page.slice(start, end);
const guards = (fn.match(/if \(this\.editorDisposed\) \{\s+return;\s+\}/g) ?? []).length;
assert.equal(guards, 2);
assert.match(fn,
  /if \(response\.index === 0\) \{\s+if \(this\.editorDisposed\) \{\s+return;\s+\}\s+await session\.start\(OriginalRecordingAudioSource\.MICROPHONE\);/);
assert.match(fn,
  /\} else if \(response\.index === 1\) \{\s+if \(this\.editorDisposed\) \{\s+return;\s+\}\s+await session\.start\(OriginalRecordingAudioSource\.DEVICE_ONLY\);/);

console.log('D02_RECORDING_AUDIO_SOURCE_DISPOSAL_BOUND_REPLAY_OK TOTAL=3 FAILED=0');
