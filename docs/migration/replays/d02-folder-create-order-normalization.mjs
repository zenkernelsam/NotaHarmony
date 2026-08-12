import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(
  path.join(root, 'note/src/main/ets/data/FolderRepositoryImpl.ets'), 'utf8');
const create = source.indexOf('async createFolder');
const insert = source.indexOf("store.insert('folder'", create);
const normalize = source.indexOf('await this.normalizeSiblingOrders', insert);
const commit = source.indexOf('await store.commit()', normalize);
const helper = source.indexOf('private async normalizeSiblingOrders');
const checks = [
  ['create inserts before normalization', insert > create && normalize > insert],
  ['create normalization precedes commit', commit > normalize],
  ['normalizer is shared with other folder mutations', helper >= 0],
  ['normalizer targets requested parent', source.indexOf('afterCreate, parentId', normalize) > normalize],
  ['failure remains transactional', source.indexOf('await store.rollBack()', create) > commit],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
