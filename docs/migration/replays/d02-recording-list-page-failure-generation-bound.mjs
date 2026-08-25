import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const start = page.indexOf('  private async loadPages(): Promise<void> {');
const end = page.indexOf('  // Original title commits are serialized', start);
assert.ok(start !== -1 && end > start);
const body = page.slice(start, end);
const catchStart = body.lastIndexOf('    } catch (e) {');
const catchBody = body.slice(catchStart);

assert.match(catchBody,
  /if \(loadGeneration !== this\.pageLoadGeneration \|\| this\.editorDisposed\) \{\s+return;\s+\}\s+this\.recordingLoadGeneration\+\+;/,
  'current page failure invalidates recording loads');
assert.ok(catchBody.indexOf('this.recordingLoadGeneration++') <
  catchBody.indexOf('this.recordings = [];'),
  'invalidation precedes failure reset');
assert.match(catchBody,
  /this\.recordings = \[\];\s+this\.rebuildRecordingTimeline\(\);/,
  'failure projection remains explicit');

const load = page.match(/private async loadRecordings\(\): Promise<void> \{[\s\S]*?\n  \}/);
assert.ok(load);
assert.match(load[0],
  /\} finally \{\s+if \(generation === this\.recordingLoadGeneration\) \{\s+this\.recordingsLoading = false;\s+\}/,
  'stale recording load cannot publish or clear loading');

console.log('D02_RECORDING_LIST_PAGE_FAILURE_GENERATION_BOUND_REPLAY_OK TOTAL=4 FAILED=0');
