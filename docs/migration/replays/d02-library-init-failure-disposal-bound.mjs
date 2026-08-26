import assert from 'node:assert/strict';
import fs from 'node:fs';

const page=fs.readFileSync('note/src/main/ets/ui/library/LibraryPage.ets','utf8').replaceAll('\r\n','\n');

assert.match(page,
  /Button\(\$r\('app\.string\.retry'\)\)\s+\.height\(36\)\s+\.margin\(\{ top: 12 \}\)\s+\.onClick\(\(\) => \{\s+if \(!this\.pageActive\) \{\s+return;\s+\}\s+const lifecycleGeneration: number = this\.activatePage\(\);/,
  'disposed library retry cannot reactivate initialization');

const start=page.indexOf('  private async initData(expectedLifecycleGeneration: number = this.lifecycleGeneration): Promise<void> {');
const end=page.indexOf('  private onSystemDarkChange(): void {',start);
assert.ok(start!==-1&&end>start,'initData section exists');
const body=page.slice(start,end);

assert.match(body,/\} catch \(e\) \{\s+console\.error\(\`LibraryPage init failed: \${JSON\.stringify\(e\)\}\`\);\s+if \(!this\.pageActive \|\| expectedLifecycleGeneration !== this\.lifecycleGeneration\) \{\s+return;\s+\}\s+this\.libraryLoading = false;/,
'stale initialization failures skip UI and retry toast');

const logIndex=body.indexOf('LibraryPage init failed:');
const guardIndex=body.indexOf('if (!this.pageActive ||',logIndex);
const stateIndex=body.indexOf('this.libraryLoading = false;',guardIndex);
const toastIndex=body.indexOf("promptAction.showToast({ message: $r('app.string.library_load_retry') });",stateIndex);
assert.ok(logIndex>=0&&guardIndex>logIndex&&stateIndex>guardIndex&&toastIndex>stateIndex,
'failure logs first, guards lifecycle, then publishes error state and toast');

assert.doesNotMatch(body.slice(logIndex,guardIndex),/libraryLoading|hasInitError|showToast/,
'no UI publication precedes lifecycle gate');

console.log('D02_LIBRARY_INIT_FAILURE_DISPOSAL_BOUND_REPLAY_OK TOTAL=5 FAILED=0');
