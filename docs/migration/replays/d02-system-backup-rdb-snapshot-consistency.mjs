import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(
  path.join(root, 'note/src/main/ets/notebackupability/NoteBackupAbility.ets'), 'utf8');
const create = source.indexOf('private async createSnapshot()');
const createLocked = source.indexOf('private async createSnapshotLocked()');
const restore = source.indexOf('private async restoreSnapshot(bundleVersion: BundleVersion)');
const firstBackup = source.indexOf('await databaseStore.backup(DATABASE_CAPTURE_BEFORE)', createLocked);
const collect = source.indexOf('this.collect(filesPath, filesPath, FILES_ROOT, entries)', createLocked);
const secondBackup = source.indexOf('await databaseStore.backup(DATABASE_CAPTURE_AFTER)', createLocked);
const compare = source.indexOf('this.filesEqual(databaseBeforePath, databaseAfterPath)', secondBackup);
const publish = source.indexOf('fileIo.renameSync(staging, snapshot)', compare);
const checks = [
  ['current manifest schema is version 2', source.includes('const CURRENT_MANIFEST_SCHEMA = 2;') &&
    source.includes('schema: CURRENT_MANIFEST_SCHEMA')],
  ['RDB store uses the application database identity', source.includes('name: DB_NAME') &&
    source.includes('securityLevel: relationalStore.SecurityLevel.S1')],
  ['backup obtains asset lock before shared database writer', create >= 0 &&
    source.indexOf('assetMutationMutex.runExclusive', create) > create &&
    source.indexOf('databaseWriteMutex.runExclusive', create) > source.indexOf('assetMutationMutex.runExclusive', create) &&
    source.indexOf('databaseWriteMutex.runExclusive', create) < createLocked],
  ['restore uses the same asset then database lock order', restore >= 0 &&
    source.indexOf('assetMutationMutex.runExclusive', restore) > restore &&
    source.indexOf('databaseWriteMutex.runExclusive', restore) > source.indexOf('assetMutationMutex.runExclusive', restore)],
  ['unresolved restore recovery blocks creation of a newer backup',
    source.indexOf('this.assertRestoreWorkspaceEmpty(backupDir);', createLocked) > createLocked &&
    source.indexOf('this.assertRestoreWorkspaceEmpty(backupDir);', createLocked) < firstBackup],
  ['first online database snapshot precedes file collection', firstBackup > createLocked && collect > firstBackup],
  ['active databaseDir is never recursively copied',
    !source.slice(createLocked, restore).includes('for (const rootName of ROOTS)') &&
    source.includes('entry.root === DATABASE_ROOT ? databaseBeforePath')],
  ['database snapshot is represented only as databaseDir/nota.db',
    source.includes('entries.push({ root: DATABASE_ROOT, relativePath: DB_NAME, size: databaseSize })')],
  ['second online snapshot follows file copy', secondBackup > collect],
  ['snapshot publication requires byte-identical database captures', compare > secondBackup && publish > compare &&
    source.includes('database changed while the system backup snapshot was collected')],
  ['temporary database captures are removed in finally',
    source.indexOf('this.removeDatabaseTemporary(DATABASE_CAPTURE_BEFORE)', publish) > publish &&
    source.indexOf('this.removeDatabaseTemporary(DATABASE_CAPTURE_AFTER)', publish) > publish],
  ['copied objects are checked byte-for-byte', source.includes('private copyFileVerified') &&
    source.includes('!this.filesEqual(source, destination)')],
  ['comparison closes the first handle if opening the second fails',
    source.indexOf('const left: fileIo.File = fileIo.openSync', source.indexOf('private filesEqual')) <
      source.indexOf('try {', source.indexOf('const left: fileIo.File = fileIo.openSync')) &&
    source.indexOf('const right: fileIo.File = fileIo.openSync', source.indexOf('private filesEqual')) >
      source.indexOf('try {', source.indexOf('const left: fileIo.File = fileIo.openSync'))],
  ['release serially closes the cached RDB store', source.includes('await this.enqueueOperation(async (): Promise<void> => {') &&
    source.includes('await store.close();') && source.includes('this.databaseStore = null;')],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
