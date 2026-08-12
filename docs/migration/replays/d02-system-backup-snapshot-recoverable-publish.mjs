import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(
  path.join(root, 'note/src/main/ets/notebackupability/NoteBackupAbility.ets'), 'utf8');
const publish = source.indexOf("this.state.phase = 'publishing'");
const previous = source.indexOf('const previous: string');
const moveOld = source.indexOf('fileIo.renameSync(snapshot, previous)', previous);
const publishNew = source.indexOf('fileIo.renameSync(staging, snapshot)', moveOld);
const restoreOld = source.indexOf('fileIo.renameSync(previous, snapshot)', publishNew);
const cleanup = source.indexOf('this.removeTreeInside(backupDir, PREVIOUS)', publishNew);
const checks = [
  ['previous snapshot path exists', source.includes("const PREVIOUS = 'nota-snapshot.previous'")],
  ['old snapshot moves to previous first', previous >= 0 && moveOld > publish],
  ['staging publishes after old snapshot move', publishNew > moveOld],
  ['failed publish restores previous', restoreOld > publishNew],
  ['previous cleanup follows successful publish', cleanup > publishNew],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
