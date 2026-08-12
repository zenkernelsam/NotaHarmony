import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(
  path.join(root, 'note/src/main/ets/data/AssetRepositoryImpl.ets'), 'utf8');
const save = source.indexOf('async saveAsset');
const merge = source.indexOf('const mergedNoteIds', save);
const validate = source.indexOf('validateNoteReferences(store, mergedNoteIds)', merge);
const helper = source.indexOf('export async function validateNoteReferences');
const missing = source.indexOf('note_asset references a missing note', helper);
const rollback = source.indexOf('await store.rollBack()', save);
const checks = [
  ['asset save merges references first', merge > save],
  ['merged references are validated before insert', validate > merge && validate < source.indexOf("await store.insert('note_asset'", validate)],
  ['validation checks note existence', helper > validate && missing > helper],
  ['validation runs inside transaction failure path', rollback > validate],
  ['empty IDs are rejected', source.indexOf('contains an empty note ID', helper) > helper],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
