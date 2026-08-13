import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(path.join(root, 'note/src/main/ets/ui/settings/BackupPage.ets'), 'utf8');
const failedCount = source.indexOf('const verificationFailures: number = fetched.failedNoteIds.length');
const gate = source.indexOf('if (fetched.verified.length === 0)');
const apply = source.indexOf('await applier.apply(fetched.verified)');
const rolledBack = source.indexOf('BackupBatchApplyStatus.ROLLED_BACK', apply);
const incomplete = source.indexOf('BackupBatchApplyStatus.ROLLBACK_INCOMPLETE', rolledBack);
const checks = [
  ['verification failures are carried into the aggregate failure count', failedCount >= 0 &&
    source.indexOf('fetched.failedNoteIds.length', failedCount) > failedCount],
  ['only an entirely unverifiable batch exits early', gate >= 0 &&
    source.indexOf('fetched.verified.length === 0', gate) > gate],
  ['the zero-verified report includes failed object count', gate >= 0 &&
    source.slice(gate, apply).includes('verificationFailures, 0')],
  ['verified objects are still applied after isolated verification failures', gate >= 0 && apply > gate &&
    !source.slice(gate, apply).includes('verificationFailures > 0')],
  ['hard import failure exposes completed rollback', rolledBack > apply &&
    source.indexOf('cloud_restore_rolled_back', rolledBack) > rolledBack],
  ['incomplete rollback has a distinct critical result', incomplete > rolledBack &&
    source.indexOf('cloud_restore_rollback_incomplete', incomplete) > incomplete],
  ['partial summary is emitted only after the batch applier succeeds',
    source.indexOf('verificationFailures > 0 || applied.degraded > 0', incomplete) > incomplete],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
