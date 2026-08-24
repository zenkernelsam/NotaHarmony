import assert from 'node:assert/strict';
import fs from 'node:fs';

const page=fs.readFileSync('note/src/main/ets/ui/library/LibraryPage.ets','utf8').replaceAll('\r\n','\n');
const start=page.indexOf('  private async createAndOpen(): Promise<void> {');
const end=page.indexOf('  // 响应式断点',start);
assert.ok(start!==-1&&end>start,'createAndOpen section exists');
const body=page.slice(start,end);

const navigationIndex=body.indexOf("await router.pushUrl({ url: 'ui/editor/NotePage'");
const catchIndex=body.indexOf('} catch (e) {',navigationIndex);
const logIndex=body.indexOf('open created note failed:',catchIndex);
const guardIndex=body.indexOf('if (lifecycleGeneration !== this.lifecycleGeneration || !this.pageActive ||',logIndex);
const toastIndex=body.indexOf("promptAction.showToast({ message: $r('app.string.created_note_open_failed') });",guardIndex);
const finallyIndex=body.indexOf('    } finally {',toastIndex);
assert.ok(navigationIndex>=0&&catchIndex>navigationIndex&&logIndex>catchIndex&&
  guardIndex>logIndex&&toastIndex>guardIndex&&finallyIndex>toastIndex,
  'navigation failure logs first, checks context, then toasts and keeps busy cleanup');

assert.match(body,/\} finally \{\s+this\.createBusy = false;\s+\}/,'finally busy cleanup remains authoritative');
assert.doesNotMatch(body.slice(logIndex,guardIndex),/showToast|return;/,'no UI publication precedes context gate');

console.log('D02_CREATED_NOTE_OPEN_FAILURE_CONTEXT_BOUND_REPLAY_OK TOTAL=4 FAILED=0');
