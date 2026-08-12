import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(path.join(root, 'note/src/main/ets/ui/settings/BackupPage.ets'), 'utf8');
const checks = [
  ['canonical manifest filename helper imported', source.includes('backupManifestFileName, parseBackupBatch')],
  ['candidate filename is bound to parsed batch id', source.includes('candidates[i].name === backupManifestFileName(parsed.batchId)')],
  ['identity check precedes latest selection', source.indexOf('candidates[i].name === backupManifestFileName(parsed.batchId)') < source.indexOf('(latest === null || parsed.createdAt > latest.createdAt)')],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
