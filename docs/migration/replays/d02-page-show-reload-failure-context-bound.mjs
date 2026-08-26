import assert from 'node:assert/strict';
import fs from 'node:fs';

const page=fs.readFileSync('note/src/main/ets/ui/library/LibraryPage.ets','utf8').replaceAll('\r\n','\n');
const start=page.indexOf('  onPageShow(): void {');
const navigationStart=page.indexOf('  private navigateToSettings(): void {',start);
assert.ok(start!==-1&&navigationStart>start,'onPageShow section exists');
const body=page.slice(start,navigationStart);
const navigationEnd=page.indexOf('  // 缩略图只由页面持有；generation 丢弃迟到结果，worker 数限制峰值内存。',navigationStart);
assert.ok(navigationEnd>navigationStart,'navigation method body exists');
const navigation=page.slice(navigationStart,navigationEnd);
assert.match(navigation,
  /private navigateToSettings\(\): void \{\s+if \(!this\.pageActive\) \{\s+return;\s+\}\s+router\.pushUrl\(\{ url: 'ui\/settings\/SettingsPage' \}\)/,
  'stale library page cannot navigate to settings');

const successGuardIndex=body.indexOf('if (!this.isCurrentLifecycle(lifecycleGeneration, vm, renderer) ||');
const catchIndex=body.indexOf('.catch((e: Error) => {',successGuardIndex);
const logIndex=body.indexOf('LibraryPage onPageShow reload failed:',catchIndex);
const guardIndex=body.indexOf('if (!this.isCurrentLifecycle(lifecycleGeneration, vm, renderer) ||',logIndex);
const stateIndex=body.indexOf('this.libraryLoading = false;',guardIndex);
const toastIndex=body.indexOf("promptAction.showToast({ message: $r('app.string.load_notes_failed') });",stateIndex);
assert.ok(successGuardIndex>=0&&catchIndex>successGuardIndex&&logIndex>catchIndex&&
  guardIndex>logIndex&&stateIndex>guardIndex&&toastIndex>stateIndex,
  'failure logs first, applies lifecycle/request gate, then publishes UI and toast');

assert.doesNotMatch(body.slice(logIndex,guardIndex),/libraryLoading|hasInitError|showToast/,
  'no UI publication precedes context gate');

console.log('D02_PAGE_SHOW_RELOAD_FAILURE_CONTEXT_BOUND_REPLAY_OK TOTAL=5 FAILED=0');
