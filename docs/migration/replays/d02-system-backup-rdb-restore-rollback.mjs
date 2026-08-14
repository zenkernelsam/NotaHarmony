import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(
  path.join(root, 'note/src/main/ets/notebackupability/NoteBackupAbility.ets'), 'utf8');
const dispatch = source.indexOf('private async restoreSnapshotLocked');
const legacy = source.indexOf('private restoreLegacySnapshot');
const current = source.indexOf('private async restoreCurrentSnapshot');
const currentEnd = source.indexOf('private collect(', current);
const currentBody = source.slice(current, currentEnd);
const backupRollback = currentBody.indexOf('await databaseStore.backup(DATABASE_RESTORE_ROLLBACK)');
const replaceFiles = currentBody.indexOf('this.replaceFile(');
const restoreDatabase = currentBody.indexOf('await databaseStore.restore(DATABASE_RESTORE_SOURCE)');
const rollbackDatabase = currentBody.indexOf('await databaseStore.restore(DATABASE_RESTORE_ROLLBACK)');
const rollbackFiles = currentBody.indexOf('this.rollbackFiles(replaced)');
const checks = [
  ['restore dispatch keeps schema 1 compatibility', dispatch >= 0 && legacy > dispatch &&
    source.indexOf('this.restoreLegacySnapshot(snapshot, manifest.entries)', dispatch) > dispatch],
  ['schema 2 restore uses the RDB-specific path', dispatch >= 0 && current > legacy &&
    source.indexOf('await this.restoreCurrentSnapshot(snapshot, manifest.entries)', dispatch) > dispatch],
  ['unresolved file or database recovery blocks another restore',
    source.includes('this.assertRestoreWorkspaceEmpty(backupDir);') &&
    source.includes('unresolved file restore recovery exists') &&
    source.includes('unresolved database restore recovery exists')],
  ['schema 2 permits at most one positive nota.db entry',
    source.includes('databaseEntries > 1 || entry.relativePath !== DB_NAME || entry.size <= 0')],
  ['database source is verified into a private restore name',
    currentBody.includes('this.copyFileVerified(source, this.databaseTemporaryPath(DATABASE_RESTORE_SOURCE)')],
  ['current database rollback snapshot precedes destination changes',
    backupRollback >= 0 && replaceFiles > backupRollback && restoreDatabase > replaceFiles],
  ['database restore is marked attempted before invocation',
    currentBody.indexOf('databaseRestoreAttempted = true') >= 0 &&
    currentBody.indexOf('databaseRestoreAttempted = true') < restoreDatabase],
  ['failed database restore attempts database rollback first',
    rollbackDatabase > restoreDatabase && rollbackFiles > rollbackDatabase],
  ['failed database compensation preserves its rollback snapshot',
    currentBody.indexOf('databaseRollbackComplete = false') > rollbackDatabase &&
    currentBody.includes('if (databaseRollbackComplete)') &&
    currentBody.includes('system backup database recovery preserved at')],
  ['file replacements roll back after database compensation', rollbackFiles > rollbackDatabase],
  ['restore source and database rollback temporaries are always removed',
    currentBody.includes('this.removeDatabaseTemporary(DATABASE_RESTORE_SOURCE)') &&
    currentBody.includes('this.removeDatabaseTemporary(DATABASE_RESTORE_ROLLBACK)')],
  ['successful rollback-directory cleanup is best effort after compensation boundary',
    currentBody.indexOf('system backup restore rollback cleanup failed') > rollbackFiles],
  ['legacy restore retains file-level database compatibility',
    source.slice(legacy, current).includes('this.rootPath(entry.root)') &&
    source.slice(legacy, current).includes('this.replaceFile(')],
  ['schema 2 requires bundle version code while schema 1 keeps it optional',
    source.includes('(manifest.schema === CURRENT_MANIFEST_SCHEMA && manifest.bundleVersionCode === undefined)') &&
    source.includes('bundleVersionCode?: number;')],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
