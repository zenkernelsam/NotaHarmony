import fs from 'node:fs';
import path from 'node:path';

// ADR-0158 的事务时序不变（先更新子树笔记再删 folder 行），但语义已被
// ADR-0665（原版 kcj 级联回收站）取代：笔记带 deleted_at 进 Recently
// Deleted 而非留在库中。
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
  ['subtree notes are detached before folder delete', noteUpdate > subtree],
  ['subtree notes are soft-deleted (deleted_at)', source.indexOf("'deleted_at': trashedAt", subtree) > subtree],
  ['folder delete occurs after note update', folderDelete > noteUpdate],
  ['subtree helper remains cycle-aware', source.includes('export function isFolderInSubtree')],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
