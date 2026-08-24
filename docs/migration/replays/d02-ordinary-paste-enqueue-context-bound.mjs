import assert from 'node:assert/strict';
import fs from 'node:fs';

const canvas=fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets','utf8').replaceAll('\r\n','\n');
const start=canvas.indexOf('  private applyClipboardPaste(');
const end=canvas.indexOf('  private createClipboardElementId(',start);
assert.ok(start!==-1&&end>start,'applyClipboardPaste section exists');
const body=canvas.slice(start,end);

assert.match(body,/try \{\s+this\.persistence\.queueSaveElements\(this\.noteId, this\.loadedPageId,[\s\S]*?nextImages, nextMathBlocks\);\s+\} catch \(e\) \{\s+if \(!this\.isHistoryPageContextCurrent\(this\.pageLoadGeneration, this\.loadedPageId\)\) \{\s+return;\s+\}\s+this\.reportSaveFailure\(e as Object\);\s+return;\s+\}/,
'stale or disposed enqueue failures skip user toast');

const catchIndex=body.indexOf('catch (e) {', body.indexOf('queueSaveElements'));
const guardIndex=body.indexOf('if (!this.isHistoryPageContextCurrent(',catchIndex);
const toastIndex=body.indexOf('this.reportSaveFailure(e as Object);',guardIndex);
assert.ok(catchIndex>=0&&guardIndex>catchIndex&&toastIndex>guardIndex,'failure guard precedes toast');

const deferredGuardIndex=body.indexOf("persistedPageId === this.currentPage.pageId && this.loaded &&",toastIndex);
assert.ok(deferredGuardIndex>toastIndex,'deferred flush retains healthy-page gate');

console.log('D02_ORDINARY_PASTE_ENQUEUE_CONTEXT_BOUND_REPLAY_OK TOTAL=4 FAILED=0');
