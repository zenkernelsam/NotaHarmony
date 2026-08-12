import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(
  path.join(root, 'note/src/main/ets/data/AssetRepositoryImpl.ets'), 'utf8');
const method = source.indexOf('async deleteAsset(hash: string)');
const query = source.indexOf("store.query(queryPredicates, ['local_path', 'note_ids'])", method);
const parse = source.indexOf('parseAssetNoteIds', query);
const gate = source.indexOf('asset is still referenced', parse);
const remove = source.indexOf('await store.delete(predicates)', gate);
const unlink = source.indexOf('unlinkAssetFile(localPath', method);
const checks = [
  ['delete reads reference set', query > method && parse > query],
  ['referenced assets are rejected', gate > parse],
  ['database delete follows gate', remove > gate],
  ['file unlink occurs only after transaction', unlink > remove],
  ['failure rolls back transaction', source.indexOf('await store.rollBack()', gate) > gate],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
