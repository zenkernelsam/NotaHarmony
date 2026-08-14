import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(
  path.join(root, 'note/src/main/ets/notebackupability/NoteBackupAbility.ets'), 'utf8');
const rollbackConst = source.indexOf("const RESTORE_ROLLBACK = 'nota-restore.rollback'");
const legacy = source.indexOf('private restoreLegacySnapshot');
const current = source.indexOf('private async restoreCurrentSnapshot');
const replaceFile = source.indexOf('private replaceFile');
const rollbackFiles = source.indexOf('private rollbackFiles');
const legacyRollback = source.indexOf('this.rollbackFiles(replaced)', legacy);
const legacyCleanup = source.indexOf('this.removeTreeInside(backupDir, RESTORE_ROLLBACK)', legacyRollback);
const currentRollback = source.indexOf('this.rollbackFiles(replaced)', current);
const currentCleanup = source.indexOf('this.removeTreeInside(backupDir, RESTORE_ROLLBACK)', currentRollback);
const legacySuccessCleanup = source.indexOf('legacy backup restore rollback cleanup failed', legacyRollback);
const currentSuccessCleanup = source.indexOf('system backup restore rollback cleanup failed', currentRollback);
const reverse = source.indexOf('for (let index: number = replaced.length - 1', rollbackFiles);
const typedReplacement = source.indexOf('const replacement: RestoreReplacement = {', replaceFile);
const registerBeforeCopy = source.indexOf('replaced.push(replacement)', typedReplacement);
const copy = source.indexOf('this.copyFileVerified(source, destination, expectedSize)', replaceFile);
const checks = [
  ['restore rollback directory is defined', rollbackConst >= 0],
  ['legacy and current restores track replaced files', legacy >= 0 && current > legacy &&
    source.indexOf('const replaced: RestoreReplacement[] = []', legacy) > legacy &&
    source.indexOf('const replaced: RestoreReplacement[] = []', current) > current],
  ['existing files move before replacement',
    source.indexOf('fileIo.renameSync(destination, rollback)', replaceFile) > replaceFile],
  ['directory destinations fail before rollback registration',
    source.indexOf('restore destination is a directory', replaceFile) > replaceFile &&
    source.indexOf('restore destination is a directory', replaceFile) < registerBeforeCopy],
  ['failure rolls files back in reverse order', reverse > rollbackFiles],
  ['rollback completeness is reported instead of assumed',
    source.indexOf('private rollbackFiles(replaced: RestoreReplacement[]): boolean', rollbackFiles) === rollbackFiles &&
    source.indexOf('return complete;', rollbackFiles) > reverse],
  ['missing rollback sources cannot be reported as recovered',
    source.indexOf('restore rollback source is missing', rollbackFiles) > reverse],
  ['legacy rollback staging is removed after recovery', legacyCleanup > legacyRollback],
  ['current rollback staging is removed after recovery', currentCleanup > currentRollback],
  ['successful legacy cleanup cannot trigger compensation', legacySuccessCleanup > legacyCleanup],
  ['successful current cleanup cannot trigger compensation', currentSuccessCleanup > currentCleanup],
  ['rollback entry is explicitly typed', typedReplacement > replaceFile && typedReplacement < registerBeforeCopy],
  ['files register before copy can fail', registerBeforeCopy > typedReplacement && registerBeforeCopy < copy],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
