import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const snapshotStart = page.indexOf('private onRecordingSessionSnapshot(snapshot: OriginalRecordingSessionSnapshot): void {');
const scheduleStart = page.indexOf('private scheduleRecordingSessionRefresh(): void {', snapshotStart);
assert.ok(snapshotStart !== -1 && scheduleStart > snapshotStart);

const snapshot = page.slice(snapshotStart, scheduleStart);
const guards = (snapshot.match(/if \(this\.editorDisposed\) \{\s+return;\s+\}/g) ?? []).length;
assert.equal(guards, 1);
assert.match(snapshot,
  /private onRecordingSessionSnapshot\(snapshot: OriginalRecordingSessionSnapshot\): void \{\s+if \(this\.editorDisposed\) \{\s+return;\s+\}\s+this\.recordingSessionSnapshot = snapshot;/);

const scheduleEnd = page.indexOf('\n  private cancelRecordingSessionRefresh', scheduleStart);
const timer = page.slice(scheduleStart, scheduleEnd);
assert.match(timer,
  /this\.recordingSessionTimer = -1;\s+if \(this\.editorDisposed\) \{\s+return;\s+\}\s+const session/);

console.log('D02_RECORDING_SESSION_SNAPSHOT_DISPOSAL_BOUND_REPLAY_OK TOTAL=3 FAILED=0');
