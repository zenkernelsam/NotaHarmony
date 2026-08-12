import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(
  path.join(root, 'note/src/main/ets/data/NoteRepositoryImpl.ets'), 'utf8');
const method = source.indexOf('async deleteNote(noteId: string)');
const check = source.indexOf('const noteCheck', method);
const transaction = source.indexOf('await store.beginTransaction()', method);
const asset = source.indexOf('const assetReferences', check);
const deleted = source.indexOf('const deleted: number = await store.delete(p1)', asset);
const guard = source.indexOf('expected to delete one note', deleted);
const rollback = source.indexOf('await store.rollBack()', method);
const checks = [
  ['delete runs inside transaction', transaction > method],
  ['note existence is checked before asset mutation', check > transaction && check < asset],
  ['final delete requires one row', deleted > asset && guard > deleted],
  ['failure path rolls transaction back', rollback > guard],
  ['normal commit follows delete guard', source.indexOf('await store.commit()', guard) > guard],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
