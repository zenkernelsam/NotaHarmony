import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const spec = fs.readFileSync(path.join(root, 'note/src/main/ets/data/BackupBatchSpec.ets'), 'utf8');
const publisher = fs.readFileSync(path.join(root, 'note/src/main/ets/data/BackupBatchPublisher.ets'), 'utf8');
const checks = [
  ['manifest createdAt is safe integer', spec.includes('Number.isSafeInteger(parsed.createdAt)')],
  ['entry updatedAt is safe integer', spec.includes('Number.isSafeInteger(entry.updatedAt)')],
  ['publisher completion time is safe integer', publisher.includes('Number.isSafeInteger(completedAt)')],
  ['publisher source time is safe integer', publisher.includes('Number.isSafeInteger(source.updatedAt)')],
  ['timestamps remain positive', spec.includes('parsed.createdAt <= 0') && spec.includes('entry.updatedAt <= 0')],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
