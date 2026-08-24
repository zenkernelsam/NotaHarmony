import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/settings/BackupPage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

assert.match(page, /private lifecycleGeneration: number = 0;/);
assert.match(page, /private pageDisposed: boolean = false;/);
assert.match(page,
  /aboutToDisappear\(\): void \{\s+this\.pageDisposed = true;\s+this\.lifecycleGeneration\+\+;\s+\}/);
assert.match(page,
  /if \(this\.isStaleReload\(expectedLifecycleGeneration, generation\)\) \{\s+return;\s+\}/);

const operations = ['exportAllLocal', 'importLocal', 'backupAll', 'restoreFromCloud'];
let guardCount = 0;
for (const operation of operations) {
  const marker = `private async ${operation}(): Promise<void> {`;
  const start = page.indexOf(marker);
  assert.ok(start !== -1, marker);
  const end = page.indexOf('  private async loadLatestBackupBatch', start);
  const body = page.slice(start, end);

  assert.match(body, /const lifecycleGeneration: number = \+\+this\.lifecycleGeneration;/,
    `${operation}: captures a fresh operation generation`);
  const guards = [...body.matchAll(/if \(this\.isStale\(lifecycleGeneration\)\) \{\s+return;\s+\}/g)];
  guardCount += guards.length;

  for (const effect of [
    'this.statusText',
    'this.hasLastBackup',
    'this.lastBackupText',
    'this.showAlert(',
    'this.showToast(',
  ]) {
    const firstEffect = body.indexOf(effect);
    if (firstEffect === -1) {
      continue;
    }
    const firstAcquisition = body.indexOf('backupOperationLease.tryAcquire()');
    assert.ok(firstEffect > firstAcquisition, `${operation}: ${effect}`);
  }
}

for (const anchor of [
  'await noteRepo.getAllNotes();',
  'await importer.importFromFile(context);',
  'await exporter.exportAllNotes();',
  'await publisher.publish(backups, batchId, completedAt);',
  'await WebDAVConfigStore.setLastBackup(context, operationConfig, completedAt);',
  'await client.listDir(client.backupDirectoryUrl());',
  'client, listResult.files);',
  'await restorer.fetch(manifest);',
  'await applier.apply(fetched.verified);',
]) {
  const index = page.indexOf(anchor);
  assert.ok(index !== -1, anchor);
  const guardIndex = page.indexOf('if (this.isStale(lifecycleGeneration))', index);
  assert.ok(guardIndex !== -1 && guardIndex - index < 180, `missing immediate guard: ${anchor}`);
}

assert.equal([...page.matchAll(/\} finally \{\s+this\.isBusy = false;\s+this\.statusText = '';\s+releaseOperation\(\);\s+\}/g)].length, 4);
assert.match(page, /private isStale\(lifecycleGeneration: number\): boolean \{\s+return this\.pageDisposed \|\| lifecycleGeneration !== this\.lifecycleGeneration;\s+\}/);

console.log('D02_BACKUP_OPERATIONS_DISPOSAL_BOUND_REPLAY_OK TOTAL=10 FAILED=0');
