import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/settings/BackupPage.ets', 'utf8').replaceAll('\r\n', '\n');

function body(startMarker, endMarker) {
  const start = page.indexOf(startMarker);
  const end = page.indexOf(endMarker, start);
  assert.ok(start !== -1 && end > start, startMarker);
  return page.slice(start, end);
}

const reloadBody = body(
  '  private async reloadPage(): Promise<void> {',
  '  // === 本地：导出全部笔记 ===',
);
const reloadCatchIndex = reloadBody.indexOf('} catch (e) {');
const reloadLogIndex = reloadBody.indexOf('console.error(`BackupPage reload failed:', reloadCatchIndex);
assert.ok(reloadLogIndex > reloadCatchIndex, 'reload logs before lifecycle guard');
const reloadGuardIndex = reloadBody.indexOf('if (generation === this.loadGeneration) {', reloadCatchIndex);
const disposedGuardIndex = reloadBody.indexOf('if (this.pageDisposed) {', reloadGuardIndex);
const resetIndex = reloadBody.indexOf('this.config = {', disposedGuardIndex);
const errorPublishIndex = reloadBody.indexOf('this.loadState = BackupLoadState.ERROR;', disposedGuardIndex);
assert.ok(reloadGuardIndex > reloadLogIndex, 'reload generation guard precedes state mutation');
assert.ok(disposedGuardIndex > reloadGuardIndex, 'disposed guard precedes state reset');
assert.ok(resetIndex > disposedGuardIndex && errorPublishIndex > disposedGuardIndex, 'stale reload cannot reset or publish');

const backupBody = body(
  '  private async backupAll(): Promise<void> {',
  '  // === WebDAV：从云端恢复最近一次已发布的完整批次 ===',
);
const preparationTryStart = backupBody.indexOf('try {' + String.fromCharCode(10) + '        backups = await exporter.exportAllNotes();');
assert.notEqual(preparationTryStart, -1, 'preparation try block');
const preparationCatchIndex = backupBody.indexOf('} catch (e) {', preparationTryStart);
const preparationLogIndex = backupBody.indexOf('console.error(`backupAll preparation failed:', preparationCatchIndex);
const preparationGuardIndex = backupBody.indexOf('if (this.isStale(lifecycleGeneration)) {', preparationLogIndex);
const preparationAlertIndex = backupBody.indexOf('this.showAlert(', preparationGuardIndex);
assert.ok(preparationAlertIndex > preparationGuardIndex && preparationGuardIndex > preparationLogIndex,
  'stale preparation feedback is silent');

console.log('D02_BACKUP_LOAD_PREPARATION_DISPOSAL_BOUND_REPLAY_OK TOTAL=5 FAILED=0');
