import assert from 'node:assert/strict';
import fs from 'node:fs';

const view = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const marker = 'this.persistence.commitOriginalClipboardPaste(\n      this.noteId, pageId, plan, prepared).then(';
const start = view.indexOf(marker);
assert.ok(start !== -1);
const end = view.indexOf('\n      }).catch((e: Object): void => {', start);
const callback = view.slice(start, end);

assert.match(callback,
  /\(result: OriginalClipboardPastePersistenceResult\): void => \{\s+if \(!this\.isHistoryPageContextCurrent\(generation, pageId\)\) \{\s+hilog\.error\(0x0001, 'NoteCanvasView',\s+'original Group Paste committed after stale page; durable history remains available'\);\s+return;\s+\}/);

const effects = [
  'this.strokeClipboard.commitPreparedPaste(',
  'this.undoRedo.push(action, prepared);',
  'this.lastQueuedHistoryRevision = this.undoRedo.getHistoryRevision();',
  'this.notifyUndoRedo();',
];
for (const effect of effects) {
  assert.ok(callback.includes(effect), `missing effect: ${effect}`);
}

const staleGuardEnd = callback.indexOf('return;\n        }');
const effectStart = Math.min(...effects.map(effect => callback.indexOf(effect)));
assert.ok(staleGuardEnd !== -1 && effectStart > staleGuardEnd);
assert.equal(callback.split('this.isHistoryPageContextCurrent(generation, pageId)').length - 1, 2);
assert.match(view.replace(callback, ''), /\.finally\(\(\): void => \{\s+this\.historyBusy = false;/);

console.log('D02_ORIGINAL_GROUP_PASTE_STALE_BOUND_REPLAY_OK TOTAL=6 FAILED=0');
