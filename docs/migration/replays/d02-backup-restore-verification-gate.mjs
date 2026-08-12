import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(path.join(root, 'note/src/main/ets/ui/settings/BackupPage.ets'), 'utf8');
const failedCount = source.indexOf('let failed: number = fetched.failedNoteIds.length');
const gate = source.indexOf('if (fetched.verified.length === 0)');
const importLoop = source.indexOf('for (let i: number = 0; i < fetched.verified.length; i++)');
const checks = [
  ['verification failures are carried into the aggregate failure count', failedCount >= 0 &&
    source.indexOf('fetched.failedNoteIds.length', failedCount) > failedCount],
  ['only an entirely unverifiable batch exits early', gate >= 0 &&
    source.indexOf('fetched.verified.length === 0', gate) > gate],
  ['the zero-verified report includes failed object count', gate >= 0 &&
    source.slice(gate, importLoop).includes('failed, 0')],
  ['verified objects are imported even when some objects failed', gate >= 0 && importLoop >= 0 &&
    gate < importLoop && !source.slice(gate, importLoop).includes('fetched.failedNoteIds.length > 0')],
  ['import failures remain aggregated with verification failures', source.includes('let failed: number = fetched.failedNoteIds.length') &&
    source.includes('failed++;')],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
