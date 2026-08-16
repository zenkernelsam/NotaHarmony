import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(
  path.join(root, 'note/src/main/ets/data/FolderRepositoryImpl.ets'), 'utf8');
const normalize = source.indexOf('private async normalizeSiblingOrders');
const move = source.indexOf('async moveFolder');
const movePlan = source.indexOf('const plan: FolderMovePlan = planFolderMove', move);
const oldParentWrite = source.indexOf('await this.writeSiblingSequence(store, plan.oldSiblingIds)', move);
const newParentWrite = source.indexOf('await this.writeSiblingSequence(store, plan.newSiblingIds)', move);
const moveCommit = source.indexOf('await store.commit()', move);
const deleteStart = source.indexOf('async deleteFolder');
const deleteQuery = source.indexOf('const remaining: NoteFolder[]', deleteStart);
const deleteCall = source.indexOf('await this.normalizeSiblingOrders', deleteQuery);
const orderedHelper = source.indexOf('function orderedSiblings');
const sorted = source.indexOf('siblings.sort(compareFolderOrder)', orderedHelper);
const sequenceWriter = source.indexOf('private async writeSiblingSequence');
const checks = [
  ['normalizer exists', normalize >= 0],
  ['normalizer uses the shared deterministic sibling sort',
    orderedHelper >= 0 && sorted > orderedHelper && source.indexOf('orderedSiblings(folders, parentId)', normalize) > normalize],
  ['move plans the destination child index in-transaction', movePlan > move],
  ['cross-parent move rewrites the old sibling sequence', oldParentWrite > movePlan],
  ['move rewrites the destination sibling sequence before commit',
    newParentWrite > oldParentWrite && moveCommit > newParentWrite],
  ['sequence writer checks every affected row', sequenceWriter >= 0 &&
    source.indexOf("await store.update({ 'sibling_order': index }", sequenceWriter) > sequenceWriter &&
    source.indexOf('!== 1', sequenceWriter) > sequenceWriter],
  ['delete queries remaining folders', deleteQuery > deleteStart],
  ['delete normalizes affected parents', deleteCall > deleteQuery],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
