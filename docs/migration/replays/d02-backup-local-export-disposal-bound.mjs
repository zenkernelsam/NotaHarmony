import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/settings/BackupPage.ets', 'utf8').replaceAll('\r\n', '\n');
const start = page.indexOf('  private async exportAllLocal(): Promise<void> {');
const end = page.indexOf('  // === 本地：从 .note 导入 ===', start);
assert.ok(start !== -1 && end > start, 'exportAllLocal body');
const body = page.slice(start, end);

function assertGuard(offset, label) {
  const guardIndex = body.indexOf('if (this.isStale(lifecycleGeneration)) {', offset);
  assert.ok(guardIndex > offset, label + ': stale guard');
  const returnIndex = body.indexOf('return;', guardIndex);
  const closingIndex = body.indexOf('}', guardIndex);
  assert.ok(returnIndex > guardIndex && returnIndex < closingIndex, label + ': silent stale return');
}

const fetchGuardIndex = body.indexOf('if (this.isStale(lifecycleGeneration)) {');
assert.ok(fetchGuardIndex > -1, 'post-fetch guard');
assertGuard(fetchGuardIndex + 1, 'pre-picker');
assert.ok(body.indexOf('await exporter.exportToFile(') > body.indexOf('if (this.isStale(lifecycleGeneration)) {', fetchGuardIndex + 1), 'guard precedes picker');

const pickerAwaitIndex = body.indexOf('await exporter.exportToFile(');
const postPickerGuardOffset = pickerAwaitIndex + 'await exporter.exportToFile('.length;
assertGuard(postPickerGuardOffset, 'post-picker');
assert.ok(body.indexOf('exported++', postPickerGuardOffset) > body.indexOf('if (this.isStale(lifecycleGeneration)) {', postPickerGuardOffset), 'guard precedes count');

const toastIndex = body.indexOf('this.showToast($r(\'app.string.exported_notes_count\'');
const lastPostAwaitGuardIndex = body.lastIndexOf('if (this.isStale(lifecycleGeneration)) {', toastIndex);
const lastExportAwaitIndex = body.lastIndexOf('await exporter.exportToFile(', toastIndex);
assert.ok(lastPostAwaitGuardIndex > lastExportAwaitIndex && lastPostAwaitGuardIndex < toastIndex, 'guard precedes final toast');

console.log('D02_BACKUP_LOCAL_EXPORT_DISPOSAL_BOUND_REPLAY_OK TOTAL=5 FAILED=0');
