import assert from 'node:assert/strict';
import fs from 'node:fs';

const pagePath = 'note/src/main/ets/ui/editor/NotePage.ets';
const controllerPath =
  'note/src/main/ets/core/adaptation/OriginalRecordingDeleteController.ets';
const page = fs.readFileSync(pagePath, 'utf8').replaceAll('\r\n', '\n');
const controllerSource = fs.readFileSync(controllerPath, 'utf8')
  .replaceAll('\r\n', '\n');

function slice(source, startMarker, endMarker) {
  const start = source.indexOf(startMarker);
  const end = source.indexOf(endMarker, start);
  assert.ok(start !== -1 && end > start, `${startMarker} -> ${endMarker}`);
  return source.slice(start, end);
}

const commit = slice(
  page,
  '  private async commitRecordingDeletes(',
  '  private onRecordingAssetAvailabilityChanged(');
const listener = slice(
  page,
  '    this.recordingDeleteController.setListener(',
  '    this.recordingDeleteController.setFailureListener(');
const startCommit = slice(controllerSource, '  private startCommit(', '  private publish(): void');
const request = slice(controllerSource, '  request(recordingId: string): boolean {', '  undo(recordingId: string): boolean {');

assert.match(commit,
  /await this\.recordingStore\.deleteVisible\([\s\S]*?\)\);\s+if \(this\.editorDisposed\) \{\s+return;\s+\}\s+await this\.loadRecordings\(\);\s+if \(this\.editorDisposed\) \{\s+return;\s+\}\s+\}/);
assert.ok(!commit.includes('pendingRecordingDeleteIds'));

assert.match(listener, /if \(this\.editorDisposed\) \{\s+return;\s+\}\s+this\.pendingRecordingDeleteIds = pendingIds;/);
assert.match(startCommit,
  /\.finally\(\(\): void => \{\s+for \(const recordingId of recordingIds\) \{\s+this\.pending\.delete\(recordingId\);\s+\}\s+const index: number = this\.commits\.indexOf\(commit\);\s+if \(index >= 0\) \{\s+this\.commits\.splice\(index, 1\);\s+\}\s+this\.publish\(\);\s+\}\);/);
assert.match(request, /this\.pending\.set\(recordingId, entry\);\s+this\.publish\(\);/);

console.log('D02_RECORDING_DELETE_PENDING_OWNERSHIP_BOUND_REPLAY_OK TOTAL=5 FAILED=0');
