import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const spec = fs.readFileSync(path.join(root, 'note/src/main/ets/data/BackupBatchSpec.ets'), 'utf8');
const publisher = fs.readFileSync(path.join(root, 'note/src/main/ets/data/BackupBatchPublisher.ets'), 'utf8');
const checks = [
  ['entry count budget exists', spec.includes('BACKUP_MAX_ENTRY_COUNT: number = 10000')],
  ['total byte budget exists', spec.includes('BACKUP_MAX_TOTAL_BYTES: number = 1024 * 1024 * 1024')],
  ['manifest rejects excessive entry count', spec.includes('parsed.entries.length > BACKUP_MAX_ENTRY_COUNT')],
  ['manifest accumulates total bytes', spec.includes('totalBytes > BACKUP_MAX_TOTAL_BYTES - entry.size')],
  ['publisher checks package count and bytes', publisher.includes('total > BACKUP_MAX_ENTRY_COUNT') && publisher.includes('totalBytes > BACKUP_MAX_TOTAL_BYTES - source.data.length')],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
