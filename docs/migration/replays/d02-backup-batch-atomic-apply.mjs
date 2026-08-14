import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const applier = fs.readFileSync(
  path.join(root, 'note/src/main/ets/data/BackupBatchApplier.ets'), 'utf8');
const importer = fs.readFileSync(
  path.join(root, 'note/src/main/ets/data/NoteImporter.ets'), 'utf8');
const repository = fs.readFileSync(
  path.join(root, 'note/src/main/ets/data/NoteRepositoryImpl.ets'), 'utf8');
const page = fs.readFileSync(
  path.join(root, 'note/src/main/ets/ui/settings/BackupPage.ets'), 'utf8');
const schema = fs.readFileSync(
  path.join(root, 'note/src/main/ets/data/DatabaseHelper.ets'), 'utf8');
const testList = fs.readFileSync(path.join(root, 'note/src/test/List.test.ets'), 'utf8');

const reverse = applier.indexOf('for (let index: number = createdNoteIds.length - 1; index >= 0; index--)');
const deletion = applier.indexOf('await this.remover.removeImportedNote(noteId)', reverse);
const checks = [
  ['verified batch objects use a dedicated application coordinator',
    applier.includes('export class BackupBatchApplier')],
  ['SUCCESS and PARTIAL are the only committed import outcomes',
    applier.includes('report.result === ImportResult.SUCCESS') &&
    applier.includes('report.result === ImportResult.PARTIAL')],
  ['committed reports require a fresh non-empty note identity',
    applier.includes('report.noteId === null || report.noteId.length === 0') &&
    applier.includes('createdNoteIds.indexOf(report.noteId) >= 0')],
  ['hard failure registers importer cleanup residue',
    applier.includes('this.registerResidual(createdNoteIds, report.noteId)')],
  ['compensation deletes created notes in reverse order', reverse >= 0 && deletion > reverse],
  ['one rollback failure does not stop later compensation',
    applier.includes('rollbackFailedNoteIds.push(noteId)') && deletion <
    applier.indexOf('rollbackFailedNoteIds.push(noteId)', deletion)],
  ['untracked committed identity makes rollback explicitly incomplete',
    applier.includes('untrackedCommittedNote') &&
    applier.includes('return await this.rollback(createdNoteIds, object.entry.noteId, true)') &&
    applier.includes('rollbackFailedNoteIds.length === 0 && !untrackedCommittedNote') &&
    applier.includes('(untrackedCommittedNote ? 1 : 0)')],
  ['complete and incomplete rollback are distinct statuses',
    applier.includes('BackupBatchApplyStatus.ROLLED_BACK') &&
    applier.includes('BackupBatchApplyStatus.ROLLBACK_INCOMPLETE')],
  ['failed single-note cleanup exposes its residual note ID',
    importer.includes('noteId: cleaned ? null : createdNoteId') &&
    importer.includes('private async removeFailedImport(noteId: string | null): Promise<boolean>')],
  ['metadata-only PARTIAL imports share the importer write mutex',
    /if \(title !== null\) \{[\s\S]*?NoteImporter\.importMutex\.lock\(\)[\s\S]*?createNote\(title, null\)[\s\S]*?finally \{[\s\S]*?release\(\)/.test(
      importer)],
  ['import cleanup verifies already-absent notes idempotently',
    importer.includes('async removeImportedNote(noteId: string): Promise<boolean>') &&
    /async removeImportedNote\(noteId: string\): Promise<boolean> \{[\s\S]*?NoteImporter\.importMutex\.lock\(\)[\s\S]*?removeImportedNoteLocked\(noteId\)[\s\S]*?finally \{[\s\S]*?release\(\)/.test(
      importer) &&
    importer.includes('if (!await this.noteIdExists(noteId))')],
  ['failed-import cleanup avoids recursively acquiring the import mutex',
    /private async removeFailedImport\(noteId: string \| null\): Promise<boolean> \{[\s\S]*?removeImportedNoteLocked\(noteId\)/.test(
      importer)],
  ['note deletion unbinds assets before deleting the note row',
    repository.indexOf('const assetReferences', repository.indexOf('async deleteNote')) <
    repository.indexOf("const p1 = new relationalStore.RdbPredicates('note_meta')")],
  ['note deletion retains files still owned by another asset row',
    repository.indexOf('isAssetFilePathReferenced(store, candidatePath)',
      repository.indexOf('async deleteNote')) < repository.indexOf('await store.commit()',
      repository.indexOf('async deleteNote'))],
  ['successful note deletion forgets stale asset availability generations',
    repository.indexOf('assetAvailabilityHub.forgetNote(noteId)',
      repository.indexOf('async deleteNote')) > repository.indexOf('await store.commit()',
      repository.indexOf('async deleteNote'))],
  ['note-owned canonical files detach before the database writer is released',
    repository.indexOf('detachAssetFileForDeletion(', repository.indexOf('async deleteNote')) >
      repository.indexOf('await store.commit()', repository.indexOf('async deleteNote')) &&
    repository.indexOf('detachAssetFileForDeletion(', repository.indexOf('async deleteNote')) <
      repository.indexOf('      });', repository.indexOf('detachAssetFileForDeletion(',
        repository.indexOf('async deleteNote')))],
  ['note-owned quarantine cleanup remains inside the asset mutation mutex',
    repository.indexOf('unlinkAssetFile(detachedFiles[i], filesRoot)',
      repository.indexOf('async deleteNote')) < repository.indexOf('    });',
      repository.indexOf('unlinkAssetFile(detachedFiles[i], filesRoot)',
        repository.indexOf('async deleteNote')))],
  ['note-owned database state has cascade roots',
    (schema.match(/REFERENCES note_meta\(id\) ON DELETE CASCADE/g) ?? []).length >= 20],
  ['ArkTS batch applier tests are registered',
    testList.includes("import backupBatchApplierTest from './BackupBatchApplier.test'") &&
    testList.includes('backupBatchApplierTest();')],
  ['production uses an explicit nominal adapter instead of structural typing',
    page.includes('class NoteImporterBackupAdapter implements BackupObjectImporter, ImportedNoteRemover') &&
    page.includes('new BackupBatchApplier(adapter, adapter)')],
];

for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
