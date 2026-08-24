import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const start = page.indexOf('  private async runPageOperation(operation: () => Promise<void>): Promise<void> {');
const end = page.indexOf('  private async addPage(): Promise<void> {', start);
assert.ok(start !== -1 && end > start, 'runPageOperation section exists');
const body = page.slice(start, end);

assert.match(body,
  /\} catch \(e\) \{\s+hilog\.error\(0x0001, 'NotePage', 'page operation failed: %{public}s', JSON\.stringify\(e\)\);\s+if \(this\.editorDisposed\) \{\s+return;\s+\}\s+try \{/,
  'disposed failure skips user toast');

const logIndex = body.indexOf("hilog.error(0x0001, 'NotePage'");
const guardIndex = body.indexOf('if (this.editorDisposed) {', logIndex);
const toastIndex = body.indexOf('promptAction.showToast(', guardIndex);
const finallyIndex = body.indexOf('    } finally {');
assert.ok(logIndex >= 0 && guardIndex > logIndex && toastIndex > guardIndex &&
  finallyIndex > toastIndex, 'guard precedes toast and busy cleanup remains');

assert.match(body,
  /\} finally \{\s+this\.pageOperationBusy = false;\s+\}/,
  'finally busy cleanup remains authoritative');

console.log('D02_PAGE_OPERATION_FAILURE_DISPOSAL_BOUND_REPLAY_OK TOTAL=3 FAILED=0');
