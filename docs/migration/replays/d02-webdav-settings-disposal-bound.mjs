import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/settings/WebDAVSettingsPage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

assert.match(page, /aboutToDisappear\(\): void \{\s+this\.pageDisposed = true;\s+this\.lifecycleGeneration\+\+;\s+\}/);
assert.match(page,
  /private async loadConfig\(expectedLifecycleGeneration: number = this\.lifecycleGeneration\): Promise<void> \{/);

function functionBody(startMarker, endMarker) {
  const start = page.indexOf(startMarker);
  const end = endMarker === null ? page.length : page.indexOf(endMarker, start);
  assert.ok(start !== -1 && end !== -1 && end > start, startMarker);
  return page.slice(start, end);
}

const load = functionBody('private async loadConfig(', 'private async testConnection(): Promise<void> {');
assert.match(load, /await WebDAVConfigStore\.load\(context\);\s+if \(this\.isDisposed\(expectedLifecycleGeneration\)\) \{\s+return;\s+\}/);
for (const effect of ['this.serverUrl = config.serverUrl;', 'this.password = config.password;']) {
  assert.ok(load.indexOf(effect) > load.indexOf('if (this.isDisposed(expectedLifecycleGeneration))'));
}

const test = functionBody('private async testConnectionOnce()', 'private async saveConfig(): Promise<void> {');
assert.match(test, /const lifecycleGeneration: number = this\.lifecycleGeneration;/);
assert.equal([...test.matchAll(/if \(this\.isDisposed\(lifecycleGeneration\)\) \{\s+return;\s+\}/g)].length, 2);
const httpTestIndex = test.indexOf('await client.testConnection();');
const firstGuard = test.indexOf('if (this.isDisposed(lifecycleGeneration))');
assert.ok(firstGuard < test.indexOf('if (this.isInsecureHttp()') && httpTestIndex > firstGuard);
for (const effect of ['this.testSucceeded = result.success;', 'this.testResult = result.message;']) {
  assert.ok(test.indexOf(effect) > test.lastIndexOf('if (this.isDisposed(lifecycleGeneration))'));
}

const save = functionBody('private async saveConfigOnce()', 'private normalizedDraft(');
assert.match(save, /const lifecycleGeneration: number = this\.lifecycleGeneration;/);
assert.equal([...save.matchAll(/if \(this\.isDisposed\(lifecycleGeneration\)\) \{\s+return;\s+\}/g)].length, 2);
const persistIndex = save.indexOf('await WebDAVConfigStore.save(context, config);');
const lastGuard = save.lastIndexOf('if (this.isDisposed(lifecycleGeneration))');
assert.ok(lastGuard > persistIndex);
for (const effect of ['this.applyNormalizedDraft(config);', "this.safeToast(result.cleanupPending ? $r('app.string.settings_saved_cleanup_pending') :", "          $r('app.string.settings_saved'));"]) {
  assert.ok(save.indexOf(effect) > lastGuard, effect);
}
assert.match(save, /\} finally \{\s+releaseOperation\(\);\s+\}/);

const safeToast = functionBody('private safeToast', 'private isInsecureHttp(): boolean {');
assert.match(safeToast, /if \(this\.pageDisposed\) \{\s+return;\s+\}/);

console.log('D02_WEBDAV_SETTINGS_DISPOSAL_BOUND_REPLAY_OK TOTAL=9 FAILED=0');
