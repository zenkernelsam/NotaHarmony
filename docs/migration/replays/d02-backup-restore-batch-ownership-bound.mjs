import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const read = (relativePath) =>
  fs.readFileSync(path.join(root, relativePath), 'utf8');

const page = read('note/src/main/ets/ui/settings/BackupPage.ets');
const settings = read('note/src/main/ets/ui/settings/WebDAVSettingsPage.ets');
const applier = read('note/src/main/ets/data/BackupBatchApplier.ets');
const importer = read('note/src/main/ets/data/NoteImporter.ets');
const exporter = read('note/src/main/ets/data/NoteExporter.ets');
const guard = read('note/src/main/ets/data/BackupSnapshotGuard.ets');

const operationStart = (source, methodName) =>
  source.indexOf(`private async ${methodName}(): Promise<void>`);
const restoreStart = operationStart(page, 'restoreFromCloud');
const localImportStart = operationStart(page, 'importLocal');
const cloudBackupStart = operationStart(page, 'backupAll');
const settingsSaveStart = settings.indexOf('private async saveConfigOnce(): Promise<void> {');

function ordered(outer, inner) {
  return outer >= 0 && inner > outer;
}

const checks = [
  ['cloud restore owns the shared backup-page mutation lease',
    ordered(restoreStart, page.indexOf('backupOperationLease.tryAcquire()', restoreStart))],
  ['local import serializes through the same shared lease',
    ordered(localImportStart, page.indexOf('backupOperationLease.tryAcquire()', localImportStart))],
  ['cloud backup cannot overlap restore or local import',
    ordered(cloudBackupStart, page.indexOf('backupOperationLease.tryAcquire()', cloudBackupStart))],
  ['WebDAV configuration commit also joins the shared mutation lease',
    ordered(settingsSaveStart,
      settings.indexOf('backupOperationLease.tryAcquire()', settingsSaveStart))],
  ['restore compensation and creation use one nominal importer adapter',
    page.includes('class NoteImporterBackupAdapter implements BackupObjectImporter, ImportedNoteRemover') &&
    page.includes('new BackupBatchApplier(adapter, adapter)')],
  ['batch application creates notes only through the owned importer',
    !applier.includes('createNote(') && applier.includes('this.importer.importFromData(object.data)')],
  ['batch compensation deletes only tracked or residual imported identities',
    applier.includes('const createdNoteIds: string[] = []') &&
    applier.includes('await this.remover.removeImportedNote(noteId)') &&
    /for \(let index: number = createdNoteIds\.length - 1; index >= 0; index--\) \{[\s\S]*?removeImportedNote/.test(
      applier)],
  ['residual identity registration rejects duplicates',
    applier.includes('createdNoteIds.indexOf(noteId) < 0')],
  ['compensation removal reacquires the authoritative import mutex',
    /async removeImportedNote\(noteId: string\): Promise<boolean> \{[\s\S]*?NoteImporter\.importMutex\.lock\(\)[\s\S]*?removeImportedNoteLocked\(noteId\)[\s\S]*?finally \{[\s\S]*?release\(\)/.test(
      importer)],
  ['export validates terminal editor-save state before the final library snapshot',
    (() => {
      const method = exporter.indexOf('async exportAllNotes(): Promise<BackupSourcePackage[]> {');
      const firstTerminal = exporter.indexOf('getSaveEnqueueGeneration() !== saveGeneration', method);
      const finalSnapshot =
        exporter.indexOf("getBackupRevisionSnapshot()", exporter.indexOf('currentSnapshot', method));
      const finalGate =
        exporter.indexOf('getSaveEnqueueGeneration() !== saveGeneration', finalSnapshot);
      const assertion = exporter.indexOf('assertStableBackupSnapshot(expectedSnapshot, currentSnapshot)', method);
      return ordered(method, firstTerminal) && ordered(firstTerminal, finalSnapshot) &&
        ordered(finalSnapshot, finalGate) && ordered(finalGate, assertion);
    })()],
  ['final snapshot comparison fails closed on collection or per-note drift',
    guard.includes(
      "throw new BackupSnapshotChangedError('the note collection changed during backup export')") &&
    guard.includes('source.title !== live.title') && guard.includes('source.revision !== live.revision')],
];

for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
