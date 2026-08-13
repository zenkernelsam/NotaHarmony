import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(
  path.join(root, 'note/src/main/ets/ui/library/LibraryViewModel.ets'), 'utf8');
const chain = source.indexOf('private mutationChain: Promise<void>');
const helper = source.indexOf('private enqueueMutation<T>');
const create = source.indexOf('return this.enqueueMutation', source.indexOf('async createNote'));
const remove = source.indexOf('await this.enqueueMutation', source.indexOf('async deleteNote'));
const continuation = source.indexOf('this.mutationChain = next.then', helper);
const checks = [
  ['view model has one mutation chain', chain >= 0],
  ['create is queued', create > 0],
  ['delete is queued', remove > 0],
  ['queue advances after success or failure', continuation > helper],
  ['create publishes committed metadata locally', source.indexOf('next.push(note)', create) > create],
  ['delete removes committed metadata locally', source.indexOf('this.removeVisibleNote(noteId)', remove) > remove],
  ['mutation result is not coupled to a reload', source.indexOf('await this.loadNotes(query)', create) < 0],
  ['stale reads retry after a committed mutation', source.includes(
    'if (mutationGeneration !== this.mutationGeneration) {\n          continue;')],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
