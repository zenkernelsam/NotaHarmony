import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const start = page.indexOf('  private async loadPages(): Promise<void> {');
const end = page.indexOf('  // Original title commits are serialized', start);
assert.ok(start !== -1 && end > start);
const catchBody = page.slice(start, end).slice(page.slice(start, end).lastIndexOf('    } catch (e) {'));

assert.match(catchBody,
  /this\.recordingLoadGeneration\+\+;\s+this\.recordingsLoading = false;/,
  'page failure owns loading after invalidating old recording loads');
assert.ok(catchBody.indexOf('this.recordingsLoading = false;') <
  catchBody.indexOf('this.pageLoadFailed = true;'),
  'loading handoff precedes the failure projection');

const load = page.match(/private async loadRecordings\(\): Promise<void> \{[\s\S]*?\n  \}/);
assert.ok(load);
assert.match(load[0],
  /\} finally \{\s+if \(generation === this\.recordingLoadGeneration\) \{\s+this\.recordingsLoading = false;\s+\}/,
  'same-generation loads retain finally cleanup');

console.log('D02_RECORDING_LOADING_PAGE_FAILURE_OWNERSHIP_BOUND_REPLAY_OK TOTAL=3 FAILED=0');
