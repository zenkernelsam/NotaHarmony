import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const helper = fs.readFileSync(path.join(root, 'note/src/main/ets/data/DatabaseHelper.ets'), 'utf8');
const manager = fs.readFileSync(path.join(root, 'note/src/main/ets/data/DatabaseManager.ets'), 'utf8');
const checks = [
  ['database version advances to 62', helper.includes('DB_VERSION: number = 62')],
  ['version 62 migration is registered', helper.includes('62: []')],
  ['startup invokes asset repair in transaction', manager.indexOf('repairAssetNoteReferences(store)') >= 0],
  ['repair parses JSON structurally', manager.indexOf('JSON.parse(raw)') >= 0],
  ['repair filters against note_meta', manager.indexOf('valid.has(value)') >= 0],
  ['empty assets are removed', manager.indexOf('if (filtered.length === 0)') >= 0],
  ['empty removal precedes unchanged fast path', manager.indexOf('if (filtered.length === 0)') <
    manager.indexOf('if (unchanged)')],
  ['asset rows are snapshotted before mutation', manager.indexOf('const assetRows') >= 0 &&
    manager.indexOf('assets.close()', manager.indexOf('const assetRows')) >= 0],
  ['invalid JSON is quarantined instead of aborting startup', manager.indexOf('quarantineInvalidAssetReference') >= 0],
  ['quarantine marks asset failed with empty references', manager.indexOf("'note_ids': '[]', 'status': 4") >= 0],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
