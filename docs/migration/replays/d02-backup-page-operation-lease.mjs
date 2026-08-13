import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const read = relative => fs.readFileSync(path.join(root, relative), 'utf8');
const lease = read('note/src/main/ets/data/BackupOperationLease.ets');
const page = read('note/src/main/ets/ui/settings/BackupPage.ets');
const settings = read('note/src/main/ets/ui/settings/WebDAVSettingsPage.ets');
const store = read('note/src/main/ets/data/WebDAVConfigStore.ets');
const testList = read('note/src/test/List.test.ets');

const operations = ['exportAllLocal', 'importLocal', 'backupAll', 'restoreFromCloud'];
const checks = [
  ['one process-wide non-queuing lease is exported',
    lease.includes('export const backupOperationLease') &&
    lease.includes('tryAcquire(): BackupOperationRelease | null')],
  ['lease release is idempotent', lease.includes('let released: boolean = false') &&
    lease.includes('if (released)')],
  ['all backup-page mutations acquire and release the shared lease',
    operations.every(name => {
      const start = page.indexOf(`private async ${name}`);
      const end = page.indexOf('\n  private ', start + 1);
      const body = page.slice(start, end < 0 ? page.length : end);
      return body.includes('backupOperationLease.tryAcquire()') &&
        body.includes('backup_operation_in_progress') && body.includes('releaseOperation();');
    })],
  ['configuration save shares the same mutation lease',
    settings.indexOf('backupOperationLease.tryAcquire()', settings.indexOf('private async saveConfig')) >= 0 &&
    settings.indexOf('releaseOperation();', settings.indexOf('private async saveConfig')) >= 0],
  ['configuration save and connection test have a local duplicate-submit gate',
    settings.includes('@State isSaving: boolean = false') &&
    settings.includes('this.isTesting = true') &&
    settings.includes('await this.testConnectionOnce()') &&
    settings.includes('this.isTesting = false') &&
    settings.includes('if (this.isSaving || this.isTesting)') &&
    (settings.match(/\.enabled\(!this\.isTesting && !this\.isSaving\)/g) ?? []).length === 2],
  ['backup and restore freeze a configuration snapshot',
    (page.match(/const operationConfig: WebDAVConfig = this\.snapshotConfig\(\)/g) ?? []).length === 2 &&
    page.includes('new WebDAVClient(operationConfig)')],
  ['last-backup reads and writes are target-bound',
    page.includes('getLastBackup(context, config)') &&
    page.includes('setLastBackup(context, operationConfig, completedAt)') &&
    store.includes('KEY_LAST_BACKUP_TARGET') &&
    store.includes('storedTarget !== targetIdentity')],
  ['target identity excludes password but includes server user and path',
    store.includes('identityPart(normalized.serverUrl)') &&
    store.includes('identityPart(normalized.username)') &&
    store.includes('identityPart(normalized.backupPath)') &&
    !/webDAVBackupTargetIdentity[\s\S]*?identityPart\(normalized\.password\)/.test(store)],
  ['lease tests are registered',
    testList.includes("import backupOperationLeaseTest from './BackupOperationLease.test'") &&
    testList.includes('backupOperationLeaseTest();')],
];

for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
