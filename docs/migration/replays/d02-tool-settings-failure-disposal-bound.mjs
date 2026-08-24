import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const start = page.indexOf('  private async loadPages(): Promise<void> {');
const end = page.indexOf('  private saveTitle(): Promise<void> {', start);
assert.ok(start !== -1 && end > start, 'loadPages section exists');
const body = page.slice(start, end);

assert.match(body,
  /this\.viewModel\.onPersistenceError = \(message: string\): void => \{\s+hilog\.error\(0x0001, 'NotePage', '%\{public\}s', message\);\s+if \(this\.editorDisposed\) \{\s+return;\s+\}\s+try \{\s+promptAction\.showToast\(\{\s+message: 'Tool settings could not be saved',\s+duration: 2500,?\s*\}\);/,
  'disposed persistence failures skip user toast');

const callbackStart = body.indexOf('this.viewModel.onPersistenceError =');
const logIndex = body.indexOf("hilog.error(0x0001, 'NotePage'", callbackStart);
const guardIndex = body.indexOf('if (this.editorDisposed) {', logIndex);
const toastIndex = body.indexOf('promptAction.showToast(', guardIndex);
const catchIndex = body.indexOf('catch (toastError)', toastIndex);
assert.ok(logIndex >= 0 && guardIndex > logIndex && toastIndex > guardIndex &&
  catchIndex > toastIndex,
  'callback logs first, guards disposal, then attempts toast');

assert.doesNotMatch(body.slice(guardIndex, toastIndex), /return;\s+if \(this\.editorDisposed\)/,
  'disposal guard is single and authoritative');

console.log(
  'D02_TOOL_SETTINGS_FAILURE_DISPOSAL_BOUND_REPLAY_OK TOTAL=4 FAILED=0');
