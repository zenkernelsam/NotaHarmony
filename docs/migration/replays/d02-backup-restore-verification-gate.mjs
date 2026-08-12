import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(path.join(root, 'note/src/main/ets/ui/settings/BackupPage.ets'), 'utf8');
const gate = source.indexOf('fetched.failedNoteIds.length > 0 || fetched.verified.length !== manifest.entries.length');
const importLoop = source.indexOf('for (let i: number = 0; i < fetched.verified.length; i++)');
const checks = [
  ['failed object gate exists', gate >= 0],
  ['verified count must equal manifest count', source.includes('fetched.verified.length !== manifest.entries.length')],
  ['gate precedes local import loop', gate >= 0 && importLoop >= 0 && gate < importLoop],
  ['failed verification reports zero restored', source.includes("$r('app.string.cloud_restore_partial', 0, manifest.entries.length")],
  ['failed verification exits before import', source.slice(gate, importLoop).includes('return;')],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
