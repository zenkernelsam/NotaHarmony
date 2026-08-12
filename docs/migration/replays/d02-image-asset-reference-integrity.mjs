import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const asset = fs.readFileSync(path.join(root, 'note/src/main/ets/data/AssetRepositoryImpl.ets'), 'utf8');
const image = fs.readFileSync(path.join(root, 'note/src/main/ets/data/ImageAssetPackageStore.ets'), 'utf8');
const helper = asset.indexOf('export async function validateNoteReferences');
const saveCall = image.indexOf('await validateNoteReferences(store, noteIds)');
const transaction = image.indexOf('await store.beginTransaction()');
const insert = image.indexOf("await store.insert('note_asset'", saveCall);
const checks = [
  ['shared validator is exported', helper >= 0],
  ['image import calls shared validator', saveCall > transaction],
  ['validation precedes canonical insert', insert < 0 || saveCall < insert],
  ['asset path retains transaction rollback', image.indexOf('await store.rollBack()', transaction) > transaction],
  ['validator rejects missing note IDs', asset.includes('note_asset references a missing note')],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
