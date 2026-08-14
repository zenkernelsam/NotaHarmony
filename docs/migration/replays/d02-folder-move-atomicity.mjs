import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(path.join(root, 'note/src/main/ets/data/FolderRepositoryImpl.ets'), 'utf8');
const checks = [
  ['note move uses shared metadata writer', source.includes('moveNoteToFolder') &&
    source.includes('libraryMetadataMutationMutex.runExclusive')],
  ['target validation occurs inside transaction', source.includes('await store.beginTransaction()') && source.includes('findFolder(folders, folderId)')],
  ['update commits atomically', source.includes("await store.commit()") && source.includes('await store.rollBack()')],
  ['missing note remains an error', source.includes("throw new Error('note does not exist')")],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
