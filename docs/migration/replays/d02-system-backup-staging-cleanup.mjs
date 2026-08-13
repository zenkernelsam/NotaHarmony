import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(
  path.join(root, 'note/src/main/ets/notebackupability/NoteBackupAbility.ets'), 'utf8');
const create = source.indexOf('private async createSnapshot()');
const start = source.indexOf('try {', create);
const cleanup = source.indexOf("this.removeTreeInside(backupDir, STAGING)", start);
const failed = source.indexOf("this.state.phase = 'failed'", cleanup);
const captureError = source.indexOf('this.state.error = this.errorMessage(e);', failed);
const rethrow = source.indexOf('throw new Error(this.state.error);', captureError);
const checks = [
  ['snapshot creation has guarded failure path', create >= 0 && start > create],
  ['failed backup removes staging tree', cleanup > start],
  ['failed backup exposes failed phase', failed > cleanup],
  ['failure message is normalized before rethrow', captureError > failed],
  ['failure is rethrown as an Error', rethrow > captureError],
  ['published snapshot cleanup remains present', source.includes("this.removeTreeInside(backupDir, PREVIOUS)")],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
