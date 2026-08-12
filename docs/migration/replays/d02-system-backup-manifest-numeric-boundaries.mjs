import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(
  path.join(root, 'note/src/main/ets/notebackupability/NoteBackupAbility.ets'), 'utf8');
const validate = source.indexOf('private validateManifest');
const checks = [
  ['system manifest createdAt uses safe integer',
    source.includes('Number.isSafeInteger(manifest.createdAt)')],
  ['system manifest createdAt is positive', source.includes('manifest.createdAt <= 0')],
  ['system entry size uses safe integer', source.includes('Number.isSafeInteger(entry.size)')],
  ['system entry size remains non-negative', source.includes('entry.size < 0')],
  ['numeric checks are in manifest validation', validate >= 0 &&
    source.indexOf('Number.isSafeInteger(manifest.createdAt)', validate) > validate &&
    source.indexOf('Number.isSafeInteger(entry.size)', validate) > validate],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
