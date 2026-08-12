import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(path.join(root, 'note/src/main/ets/data/BackupBatchPublisher.ets'), 'utf8');
const checks = [
  ['publisher reuses batch id validator', source.includes('isValidBackupBatchId(batchId)')],
  ['publisher validates completion time', source.includes('!Number.isFinite(completedAt)')],
  ['publisher validates source identity', source.includes('source.noteId.length === 0') && source.includes('source.revision.length === 0')],
  ['publisher validates source timestamp and data', source.includes('!Number.isFinite(source.updatedAt)') && source.includes('source.data.length <= 0')],
  ['prevalidation precedes remote directory creation', source.indexOf('if (!isValidBackupBatchId(batchId)') < source.indexOf('this.transport.ensureBackupDir()')],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
