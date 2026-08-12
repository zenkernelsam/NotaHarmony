import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(
  path.join(root, 'note/src/main/ets/data/BackupBatchPublisher.ets'), 'utf8');
const sets = source.indexOf('const noteIds: Set<string>');
const duplicateCheck = source.indexOf('noteIds.has(source.noteId)', sets);
const remoteWrite = source.indexOf('this.transport.ensureBackupDir()');
const checks = [
  ['publisher tracks note IDs', sets >= 0 && source.includes('const noteIds: Set<string>')],
  ['publisher tracks generated file names', source.includes('const fileNames: Set<string>')],
  ['duplicate IDs or names fail', duplicateCheck > sets && source.includes('fileNames.has(fileName)')],
  ['uniqueness runs before remote writes', duplicateCheck > 0 && duplicateCheck < remoteWrite],
  ['rejection reports no verified objects', source.includes('return this.failed(BackupPublishStage.OBJECT_UPLOAD, 0, total)')],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
