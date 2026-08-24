import assert from 'node:assert/strict';
import fs from 'node:fs';

const canvas=fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets','utf8').replaceAll('\r\n','\n');
const start=canvas.indexOf('  private persist(rearmOriginalInk: boolean = false,');
const end=canvas.indexOf('  private async refreshOriginalInkReservation(',start);
assert.ok(start!==-1&&end>start,'persist section exists');
const body=canvas.slice(start,end);

const queueIndex=body.indexOf('this.persistence.queueSaveElements(');
const flushCatchIndex=body.indexOf('.catch((e: Object) => {',queueIndex);
const deferredGuardIndex=body.indexOf('if (this.isHistoryPageContextCurrent(generation, pageId)) {',flushCatchIndex);
const syncCatchIndex=body.indexOf('} catch (e) {',deferredGuardIndex);
const syncGuardIndex=body.indexOf('if (this.isHistoryPageContextCurrent(generation, pageId)) {',syncCatchIndex);
const toastIndex=body.indexOf('this.reportSaveFailure(e as Object);',syncGuardIndex);
assert.ok(queueIndex>=0&&flushCatchIndex>queueIndex&&deferredGuardIndex>flushCatchIndex&&
  syncCatchIndex>deferredGuardIndex&&syncGuardIndex>syncCatchIndex&&toastIndex>syncGuardIndex,
  'both deferred and synchronous failures use the same context gate');

assert.doesNotMatch(body.slice(syncCatchIndex,syncGuardIndex),/reportSaveFailure|return;/,
  'synchronous catch gates before UI');

console.log('D02_PERSIST_ENQUEUE_FAILURE_CONTEXT_BOUND_REPLAY_OK TOTAL=4 FAILED=0');
