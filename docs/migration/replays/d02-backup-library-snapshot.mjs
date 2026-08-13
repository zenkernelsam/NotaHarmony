import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const read = relative => fs.readFileSync(path.join(root, relative), 'utf8');
const exporter = read('note/src/main/ets/data/NoteExporter.ets');
const persistence = read('note/src/main/ets/data/StrokePersistence.ets');
const writeQueue = read('note/src/main/ets/data/LatestWriteQueue.ets');
const guard = read('note/src/main/ets/data/BackupSnapshotGuard.ets');
const page = read('note/src/main/ets/ui/settings/BackupPage.ets');
const tests = read('note/src/test/List.test.ets');

const exportAll = exporter.slice(exporter.indexOf('async exportAllNotes()'));
const finalSnapshot = exportAll.indexOf('getBackupRevisionSnapshot()');
const checks = [
  ['all process-local editor queues flush before the note set is captured',
    exportAll.indexOf('this.persistence.flushAll()') >= 0 &&
    exportAll.indexOf('this.persistence.flushAll()') < exportAll.indexOf('getBackupRevisionSnapshot()')],
  ['editor enqueue generation fences pending in-memory saves',
    exportAll.includes('getSaveEnqueueGeneration()') &&
    (exportAll.match(/hasPendingSaves\(\)/g) ?? []).length >= 3],
  ['every note retains its individual before-after revision gate',
    exportAll.includes('revisionBefore !== note.revision') && exportAll.includes('revisionAfter') &&
    exportAll.includes('revisionBefore !== revisionAfter')],
  ['the complete library is revalidated after every file is generated',
    finalSnapshot > exportAll.indexOf('for (const note of notes)') &&
    exportAll.indexOf('assertStableBackupSnapshot(expectedSnapshot, currentSnapshot)', finalSnapshot) > finalSnapshot],
  ['the final library snapshot is one statement-level note-page query',
    persistence.includes('async getBackupRevisionSnapshot()') &&
    persistence.includes('FROM note_meta note LEFT JOIN page_info page ON page.note_id = note.id') &&
    persistence.includes('note.structure_revision AS note_structure_revision')],
  ['export revisions bind visible metadata page state content revision and element count',
    persistence.includes('title: value.title') &&
    persistence.includes('structureRevision: value.structureRevision') &&
    persistence.includes('contentRevision: resultSet.getLong') &&
    persistence.includes('elementCount: resultSet.getLong') &&
    persistence.includes("revision: `v2:${await sha256Hex(revisionBytes)}`")],
  ['clean queues leave the process registry after their flush completes',
    persistence.includes('createdQueue.setIdleHandler') &&
    persistence.includes('StrokePersistence.saveQueueRegistry.delete(createdQueue)') &&
    writeQueue.includes('if (!this.dirty && this.idleHandler !== null)')],
  ['the guard rejects collection metadata or revision divergence',
    guard.includes('expectedById.size !== currentById.size') &&
    guard.includes('source.updatedAt !== live.updatedAt') &&
    guard.includes('source.revision !== live.revision')],
  ['snapshot divergence has a local user-facing error instead of a network diagnosis',
    page.includes('backupAll preparation failed') &&
    page.includes('backups = await exporter.exportAllNotes()') &&
    page.includes('e instanceof BackupSnapshotChangedError') &&
    page.includes('backup_snapshot_changed') &&
    page.includes('backup_prepare_failed') &&
    page.indexOf('backupAll preparation failed') < page.indexOf('const publisher = new BackupBatchPublisher')],
  ['historical epoch-zero note creation timestamps remain exportable',
    guard.includes('entry.createdAt < 0') && !guard.includes('entry.createdAt <= 0') &&
    persistence.includes('value.createdAt < 0') && !persistence.includes('value.createdAt <= 0')],
  ['ArkTS guard tests are registered',
    tests.includes("import backupSnapshotGuardTest from './BackupSnapshotGuard.test'") &&
    tests.includes('backupSnapshotGuardTest();')],
];

for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
