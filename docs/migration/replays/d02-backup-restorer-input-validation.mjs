import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(path.join(root, 'note/src/main/ets/data/BackupBatchRestorer.ets'), 'utf8');
const checks = [
  ['restorer imports manifest parser', source.includes('parseBackupBatch, serializeBackupBatch')],
  ['restorer validates manifest', source.includes('parseBackupBatch(serializeBackupBatch(manifest))')],
  ['invalid manifest fails explicitly', source.includes('backup manifest failed structural validation before download')],
  ['validation precedes validated download loop', source.indexOf('const validated: BackupBatchManifest') <
    source.indexOf('for (let i: number = 0; i < validated.entries.length; i++)')],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
