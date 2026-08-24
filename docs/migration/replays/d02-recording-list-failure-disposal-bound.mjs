import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const start = page.indexOf('  private async loadRecordings(): Promise<void> {');
const end = page.indexOf('  private async persistCapturedRecording(', start);
assert.ok(start !== -1 && end > start, 'loadRecordings section exists');
const body = page.slice(start, end);

const catchIndex = body.indexOf('    } catch (error) {');
assert.notEqual(catchIndex, -1, 'failure catch exists');
const guardStart = body.indexOf('if (this.editorDisposed || generation !== this.recordingLoadGeneration) {', catchIndex);
assert.notEqual(guardStart, -1, 'disposal and generation guard exists');

const guardEnd = body.indexOf('}', guardStart);
const resetIndex = body.indexOf('this.recordings = [];', catchIndex);
const timelineIndex = body.indexOf('this.rebuildRecordingTimeline();', catchIndex);
const toastIndex = body.indexOf('promptAction.showToast(', catchIndex);
assert.ok(guardEnd > guardStart && resetIndex > guardEnd && timelineIndex > guardEnd &&
  toastIndex > guardEnd, 'guard precedes reset, timeline rebuild, and toast');

assert.match(body.slice(catchIndex),
  /if \(this\.editorDisposed \|\| generation !== this\.recordingLoadGeneration\) \{\s+return;\s+\}\s+this\.recordings = \[\];/,
  'stale or disposed failure skips local reset');

const finallyIndex = body.indexOf('    } finally {', catchIndex);
assert.ok(finallyIndex > catchIndex, 'finally exists');
assert.match(body.slice(finallyIndex),
  /if \(generation === this\.recordingLoadGeneration\) \{\s+this\.recordingsLoading = false;\s+\}/,
  'same-generation loading cleanup remains authoritative');

console.log('D02_RECORDING_LIST_FAILURE_DISPOSAL_BOUND_REPLAY_OK TOTAL=5 FAILED=0');
