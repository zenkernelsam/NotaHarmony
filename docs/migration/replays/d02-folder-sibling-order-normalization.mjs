import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(
  path.join(root, 'note/src/main/ets/data/FolderRepositoryImpl.ets'), 'utf8');
const normalize = source.indexOf('private async normalizeSiblingOrders');
const move = source.indexOf('async moveFolder');
const moveCall = source.indexOf('await this.normalizeSiblingOrders', move);
const deleteStart = source.indexOf('async deleteFolder');
const deleteQuery = source.indexOf('const remaining: NoteFolder[]', deleteStart);
const deleteCall = source.indexOf('await this.normalizeSiblingOrders', deleteQuery);
const sorted = source.indexOf('siblings.sort', normalize);
const checks = [
  ['normalizer exists', normalize >= 0],
  ['normalizer sorts deterministically', sorted > normalize],
  ['move normalizes old/new parents', moveCall > move && source.indexOf('newParentId', moveCall) > moveCall],
  ['delete queries remaining folders', deleteQuery > deleteStart],
  ['delete normalizes affected parents', deleteCall > deleteQuery],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
