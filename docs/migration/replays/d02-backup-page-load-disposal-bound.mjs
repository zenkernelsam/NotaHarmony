import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/settings/BackupPage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

assert.match(page,
  /aboutToDisappear\(\): void \{\s+this\.pageDisposed = true;\s+this\.lifecycleGeneration\+\+;/);
assert.ok(page.includes('if (this.pdfPasswordResolve !== null)') &&
  page.includes('resolve(null)'),
  'dispose resolves any pending encrypted-PDF password prompt');
assert.match(page,
  /Button\(\$r\('app\.string\.retry'\)\)\s+\.width\('90%'\)\s+\.margin\(\{ bottom: 12 \}\)\s+\.enabled\(!this\.isBusy\)\s+\.onClick\(\(\) => \{\s+if \(this\.isBusy\) \{\s+return;\s+\}\s+this\.reloadPage\(\);/,
  'backup retry rejects busy state');

const start = page.indexOf('private async reloadPage(): Promise<void> {');
const end = page.indexOf('\n  // === 本地：导出全部笔记 ===', start);
assert.ok(start !== -1 && end > start, 'reloadPage body');
const body = page.slice(start, end);

assert.match(body,
  /const expectedLifecycleGeneration: number = this\.lifecycleGeneration;\s+const generation: number = \+\+this\.loadGeneration;/);
assert.match(body,
  /await this\.db\.initialize\(context\);[\s\S]*?if \(this\.isStaleReload\(expectedLifecycleGeneration, generation\)\) \{\s+return;\s+\}/);

const successGuardIndex = body.indexOf('if (this.isStaleReload(expectedLifecycleGeneration, generation))');
for (const effect of [
  'this.config = config;',
  "this.loadState = BackupLoadState.READY;",
]) {
  assert.ok(body.indexOf(effect) > successGuardIndex, effect);
}

const catchIndex = body.indexOf('} catch (e) {');
const catchGuardIndex = body.indexOf('if (!this.isStaleReload(expectedLifecycleGeneration, generation))', catchIndex);
for (const effect of ["this.loadState = BackupLoadState.ERROR;", 'this.serverText = \'\';']) {
  const effectIndex = body.indexOf(effect, catchIndex);
  assert.ok(effectIndex > catchGuardIndex, effect);
}

const finallyIndex = body.indexOf('} finally {');
const finallyGuardIndex = body.indexOf('if (!this.isStaleReload(expectedLifecycleGeneration, generation))', finallyIndex);
const initializedIndex = body.indexOf('this.initialized = true;', finallyIndex);
assert.ok(finallyGuardIndex > finallyIndex && initializedIndex > finallyGuardIndex);

console.log('D02_BACKUP_PAGE_LOAD_DISPOSAL_BOUND_REPLAY_OK TOTAL=8 FAILED=0');
