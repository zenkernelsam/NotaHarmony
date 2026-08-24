import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/library/LibraryPage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const marker = 'this.persistence.backfillSearchIndex().then(() => {';
const start = page.indexOf(marker);
assert.ok(start !== -1);
const end = page.indexOf('}).catch((e: Error) => {', start);
const callback = page.slice(start, end);

assert.match(callback,
  /\n        if \(!this\.isCurrentLifecycle\(expectedLifecycleGeneration, vm, renderer\)\) \{\n          return;\n        \}\n/);

const guardEnd = callback.indexOf('return;\n        }');
const activeStart = callback.indexOf('const activeViewModel');
const loadStart = callback.indexOf('activeViewModel.loadNotes(activeQuery)');
assert.ok(guardEnd !== -1 && activeStart > guardEnd && loadStart > activeStart);

const requestGuard = callback.indexOf('isCurrentNotesRequest(backfillRequestGeneration');
assert.ok(requestGuard > loadStart);

console.log('D02_LIBRARY_BACKFILL_LIFECYCLE_BOUND_REPLAY_OK TOTAL=5 FAILED=0');