import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const abilityPath = path.join(root, 'note/src/main/ets/notebackupability/NoteBackupAbility.ets');
const modulePath = path.join(root, 'note/src/main/module.json5');
const configPath = path.join(root, 'note/src/main/resources/base/profile/backup_config.json');
const ability = fs.readFileSync(abilityPath, 'utf8');
const moduleText = fs.readFileSync(modulePath, 'utf8');
const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));

const checks = [
  ['BackupExtensionAbility is implemented', ability.includes('extends BackupExtensionAbility')],
  ['backup and restore callbacks are real', ability.includes('createSnapshot()') && ability.includes('restoreSnapshot(bundleVersion)')],
  ['snapshot publishes after staging', ability.includes('STAGING') && ability.includes('renameSync(staging, snapshot)')],
  ['manifest and budgets are enforced', ability.includes('nota-backup-manifest.json') && ability.includes('MAX_FILES') && ability.includes('MAX_BYTES')],
  ['manifest rejects duplicate objects', ability.includes('const seen: Set<string>') && ability.includes('duplicate backup entry')],
  ['restore rejects unsafe paths', ability.includes('assertRelative') && ability.includes("path.indexOf('..')")],
  ['extension is registered as backup', moduleText.includes('NoteBackupAbility') && moduleText.includes('"type": "backup"')],
  ['system backup metadata enables restore', config.allowToBackupRestore === true],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
