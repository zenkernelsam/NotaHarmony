#!/usr/bin/env node
import assert from 'node:assert/strict';
import fs from 'node:fs';

const source = fs.readFileSync(
  'note/src/main/ets/ui/library/LibraryViewModel.ets', 'utf8').replaceAll('\r\n', '\n');

const remove = source.indexOf('async deleteNote(noteId: string): Promise<void> {');
const classEnd = source.indexOf('\n}', remove);
assert.ok(remove >= 0 && classEnd > remove);
const method = source.slice(remove, classEnd);

const checks = [
  ['delete remains on the shared durable mutation chain',
    method.includes('await this.enqueueMutation') &&
    method.includes('await this.repo.deleteNote(noteId)')],
  ['committed deletion still projects the visible list first',
    method.indexOf('this.removeVisibleNote(noteId)') <
    method.indexOf('if (this.isLoading)')],
  ['a delete landing during loading owns the active read lifecycle',
    method.includes('if (this.isLoading) {') &&
    method.includes('++this.loadGeneration')],
  ['stale or mutated reads retry instead of publishing old rows',
    method.includes('mutationGeneration !== this.mutationGeneration') &&
    method.includes('continue;')],
  ['the replacement read preserves search and folder context',
    method.includes('const query: string = this.activeQuery;') &&
    method.includes('await this.repo.searchNotes(query, folderId)')],
  ['the replaced read clears loading in a guarded finally',
    method.includes('finally {') &&
    method.includes('this.isLoading = false;')],
];

let failed = 0;
for (const [name, passed] of checks) {
  console.log(`${passed ? 'PASS' : 'FAIL'} ${name}`);
  if (!passed) failed += 1;
}
console.log(`D02_LIBRARY_DELETE_LOADING_BOUND_OK TOTAL=${checks.length} FAILED=${failed}`);
if (failed > 0) process.exitCode = 1;
