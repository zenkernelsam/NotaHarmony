import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(
  path.join(root, 'note/src/main/ets/notebackupability/NoteBackupAbility.ets'), 'utf8');
const enqueue = source.indexOf('private enqueueOperation');
const chain = source.indexOf('private operationChain: Promise<void>');
const backup = source.indexOf('await this.enqueueOperation', source.indexOf('async onBackup()'));
const restore = source.indexOf('await this.enqueueOperation', source.indexOf('async onRestore('));
const backupEx = source.indexOf('await this.enqueueOperation', source.indexOf('async onBackupEx('));
const restoreEx = source.indexOf('await this.enqueueOperation', source.indexOf('async onRestoreEx('));
const continuation = source.indexOf('this.operationChain = next.catch', enqueue);
const checks = [
  ['ability owns one operation chain', chain >= 0],
  ['queue helper is present', enqueue >= 0],
  ['onBackup is serialized', backup > 0],
  ['onRestore is serialized', restore > 0],
  ['extended backup is serialized', backupEx > 0],
  ['extended restore is serialized', restoreEx > 0],
  ['failed operation does not poison queue', continuation > enqueue],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
