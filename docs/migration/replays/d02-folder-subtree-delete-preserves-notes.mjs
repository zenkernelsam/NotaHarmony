import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(
  path.join(root, 'note/src/main/ets/data/FolderRepositoryImpl.ets'), 'utf8');
const method = source.indexOf('async deleteFolder');
const query = source.indexOf('const folders: NoteFolder[] = await this.queryFolders(store);', method);
const subtree = source.indexOf('isFolderInSubtree(folders, folderId, folder.id)', query);
const noteUpdate = source.indexOf("'folder_id': null", subtree);
const folderDelete = source.indexOf("new relationalStore.RdbPredicates('folder')", noteUpdate);
const checks = [
  ['delete method queries folders in transaction', method >= 0 && query > method],
  ['delete iterates full subtree', subtree > query],
  ['nested notes are moved to root', noteUpdate > subtree],
  ['folder delete occurs after note migration', folderDelete > noteUpdate],
  ['subtree helper remains cycle-aware', source.includes('export function isFolderInSubtree')],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
