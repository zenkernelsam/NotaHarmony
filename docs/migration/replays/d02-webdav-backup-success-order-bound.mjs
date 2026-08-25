import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const page = fs.readFileSync(path.join(root, 'note/src/main/ets/ui/settings/BackupPage.ets'), 'utf8');

function method(name) {
  const start = page.indexOf(`private async ${name}`);
  const end = page.indexOf('\n  private ', start + 1);
  return page.slice(start, end < 0 ? page.length : end);
}

for (const name of ['backupAll', 'restoreFromCloud']) {
  const source = method(name);
  if (!source.includes('} finally {') || !source.includes('releaseOperation();')) {
    throw new Error(`FAILED: ${name} must release its operation lease in finally`);
  }
  if (!source.includes('} catch (e) {') || !source.includes('if (this.isStale(lifecycleGeneration)) {\n        return;\n      }\n      this.showAlert')) {
    throw new Error(`FAILED: ${name} stale failure continuation must reach finally`);
  }
}

const backup = method('backupAll');
const successGate = backup.indexOf('if (this.isStale(lifecycleGeneration)) {\n        return;\n      }\n      await WebDAVConfigStore.setLastBackup');
const uiPublish = backup.indexOf('this.hasLastBackup = true;');
if (successGate < 0 || uiPublish < successGate) {
  throw new Error('FAILED: last-backup persistence must follow the current-generation success gate');
}
const postPersistGate = backup.indexOf(
  'if (this.isStale(lifecycleGeneration)) {\n        return;\n      }\n      this.hasLastBackup = true;',
);
if (postPersistGate < 0 || postPersistGate < backup.indexOf('await WebDAVConfigStore.setLastBackup')) {
  throw new Error('FAILED: UI must be gated immediately after last-backup persistence');
}

console.log('webdavBackupSuccessOrder=persist-gate-before-store-ui-release-in-finally');
