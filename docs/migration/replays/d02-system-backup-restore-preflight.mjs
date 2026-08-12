import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(
  path.join(root, 'note/src/main/ets/notebackupability/NoteBackupAbility.ets'), 'utf8');
const restore = source.indexOf('private async restoreSnapshot');
const preflight = source.indexOf('backup object mismatch', restore);
const phase = source.indexOf("this.state.phase = 'restoring'", preflight);
const copy = source.indexOf('fileIo.copyFileSync(source, destination)', phase);
const checks = [
  ['restore method exists', restore >= 0],
  ['all entries are checked before copy', preflight > restore && phase > preflight && copy > phase],
  ['preflight validates regular file and exact size',
    source.slice(restore, phase).includes('!this.isFile(source)') &&
      source.slice(restore, phase).includes('fileIo.statSync(source).size !== entry.size')],
  ['restoring phase is explicit', phase > preflight],
  ['copy occurs only after preflight', copy > phase],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
