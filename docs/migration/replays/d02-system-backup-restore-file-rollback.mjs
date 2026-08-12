import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(
  path.join(root, 'note/src/main/ets/notebackupability/NoteBackupAbility.ets'), 'utf8');
const restore = source.indexOf('private async restoreSnapshot');
const rollbackConst = source.indexOf("const RESTORE_ROLLBACK = 'nota-restore.rollback'");
const rollbackRoot = source.indexOf('const rollbackRoot: string', restore);
const replaced = source.indexOf('const replaced:', rollbackRoot);
const reverse = source.indexOf('for (let index: number = replaced.length - 1', replaced);
const cleanup = source.indexOf('this.removeTreeInside(backupDir, RESTORE_ROLLBACK)', reverse);
const registerBeforeCopy = source.indexOf('replaced.push({ destination: destination', replaced);
const copy = source.indexOf('fileIo.copyFileSync(source, destination)', replaced);
const checks = [
  ['restore rollback directory is defined', rollbackConst >= 0],
  ['restore tracks replaced files', rollbackRoot > restore && replaced > rollbackRoot],
  ['existing files move before replacement', source.indexOf('fileIo.renameSync(destination, rollback)', replaced) > replaced],
  ['failure rolls files back in reverse order', reverse > replaced],
  ['rollback staging is removed after recovery', cleanup > reverse],
  ['files register before copy can fail', registerBeforeCopy > replaced && registerBeforeCopy < copy],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
