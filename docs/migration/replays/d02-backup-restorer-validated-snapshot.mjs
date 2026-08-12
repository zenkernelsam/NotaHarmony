import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(
  path.join(root, 'note/src/main/ets/data/BackupBatchRestorer.ets'), 'utf8');
const validation = source.indexOf('const validated: BackupBatchManifest');
const loop = source.indexOf('for (let i: number = 0; i < validated.entries.length; i++)');
const checks = [
  ['manifest is validated before any download', validation >= 0 && loop > validation],
  ['download loop uses the validated entry snapshot', loop >= 0 &&
    source.indexOf('const entry: BackupBatchEntry = validated.entries[i]', loop) > loop],
  ['download URL uses the validated batch identity', loop >= 0 &&
    source.indexOf('backupBatchObjectUrl(validated.batchId, entry.fileName)', loop) > loop],
  ['the caller-owned manifest is not used as the async loop source',
    source.indexOf('manifest.entries.length') < 0 && source.indexOf('manifest.batchId') < 0],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
