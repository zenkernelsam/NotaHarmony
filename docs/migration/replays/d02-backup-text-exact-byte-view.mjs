import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(
  path.join(root, 'note/src/main/ets/notebackupability/NoteBackupAbility.ets'), 'utf8');
const checks = [
  ['writeText keeps encoded byte view', source.includes('const bytes: Uint8Array')],
  ['writeText slices by offset', source.includes('bytes.byteOffset')],
  ['writeText slices by length', source.includes('bytes.byteLength')],
  ['writeText writes exact buffer', source.includes('writeSync(file.fd, exact)')],
  ['writeText still closes file', source.includes('fileIo.closeSync(file)')],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);

