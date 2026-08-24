import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/settings/WebDAVSettingsPage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

function functionBody(startMarker, endMarker) {
  const start = page.indexOf(startMarker);
  const end = endMarker === null ? page.length : page.indexOf(endMarker, start);
  assert.ok(start !== -1 && end !== -1 && end > start, startMarker);
  return page.slice(start, end);
}

const test = functionBody('private async testConnectionOnce()', 'private async saveConfig(): Promise<void> {');
const guards = [...test.matchAll(/if \(this\.isDisposed\(lifecycleGeneration\)\) \{\s+return;\s+\}/g)];
assert.equal(guards.length, 4);

const failureLogs = [
  'insecure HTTP confirmation failed:',
  'testConnection failed:',
];
let checkedPaths = 0;
for (const logMarker of failureLogs) {
  const logIndex = test.indexOf(`console.error(\`${logMarker}`);
  assert.notEqual(logIndex, -1, logMarker);
  const guardIndex = test.indexOf('if (this.isDisposed(lifecycleGeneration))', logIndex);
  assert.notEqual(guardIndex, -1, logMarker);
  const effectIndex = test.indexOf('this.testSucceeded = false;', guardIndex);
  assert.ok(effectIndex > guardIndex, logMarker);
  assert.ok(test.indexOf("this.testResult = $r('app.string.connection_request_failed');", effectIndex) > effectIndex);
  assert.ok(test.indexOf('this.hasTestResult = true;', effectIndex) > effectIndex);
  checkedPaths += 1;
}
assert.equal(checkedPaths, failureLogs.length);

console.log('D02_WEBDAV_TEST_FAILURES_DISPOSAL_BOUND_REPLAY_OK TOTAL=4 FAILED=0');
