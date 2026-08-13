import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const read = relative => fs.readFileSync(path.join(root, relative), 'utf8').replaceAll('\r\n', '\n');
const backup = read('note/src/main/ets/notebackupability/NoteBackupAbility.ets');
const database = read('note/src/main/ets/data/DatabaseManager.ets');

const createStart = backup.indexOf('private async createSnapshot()');
const restoreStart = backup.indexOf('private async restoreSnapshot(');
const collectStart = backup.indexOf('private collect(', restoreStart);
const create = backup.slice(createStart, restoreStart);
const restore = backup.slice(restoreStart, collectStart);
const repairStart = database.indexOf('private async repairAssetNoteReferences(');
const repairEnd = database.indexOf('private async removeInvalidAssetReference(', repairStart);
const repair = database.slice(repairStart, repairEnd);

const checks = [
  ['backup method boundaries are found', createStart >= 0 && restoreStart > createStart && collectStart > restoreStart],
  ['backup failure messages avoid nested Error prefixes', backup.includes('private errorMessage(error: Object)') &&
    backup.includes('error instanceof Error ? error.message : String(error)') &&
    create.includes('this.state.error = this.errorMessage(e);') &&
    restore.includes('this.state.error = this.errorMessage(e);')],
  ['backup failures are rethrown as Error', create.includes('throw new Error(this.state.error);') &&
    restore.includes('throw new Error(this.state.error);') && !backup.includes('throw e;')],
  ['restore rollback uses a named interface', backup.includes('interface RestoreReplacement {') &&
    restore.includes('const replaced: RestoreReplacement[] = [];')],
  ['restore rollback object is explicitly typed', restore.includes('const replacement: RestoreReplacement = {') &&
    restore.includes('replaced.push(replacement);')],
  ['restore rollback has no anonymous array type', !restore.includes('Array<{ destination: string;')],
  ['asset repair method boundaries are found', repairStart >= 0 && repairEnd > repairStart],
  ['asset repair rows use a named interface', database.includes('interface AssetReferenceRepairRow {') &&
    repair.includes('const assetRows: AssetReferenceRepairRow[] = [];')],
  ['asset repair row object is explicitly typed', repair.includes('const row: AssetReferenceRepairRow = {') &&
    repair.includes('assetRows.push(row);')],
  ['parsed references avoid ArkTS unknown', repair.includes('let parsed: string[];') &&
    repair.includes('JSON.parse(raw) as string[]') && !repair.includes('let parsed: unknown')],
  ['runtime JSON shape checks remain intact', repair.includes('if (!Array.isArray(parsed))') &&
    repair.includes("typeof value !== 'string'")],
];

for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
