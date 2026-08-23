import assert from 'node:assert/strict';
import fs from 'node:fs';

const view = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const marker = 'this.persistence.reserveOriginalInkCreate(this.noteId, pageId).then(';
const start = view.indexOf(marker);
assert.ok(start !== -1);
const end = view.indexOf('\n        });', start);
const callback = view.slice(start, end);

const successGuards = callback.match(/if \(!this\.isHistoryPageContextCurrent\(generation, pageId\)\) \{\s+return;\s+\}/g) ?? [];
assert.equal(successGuards.length, 1);
assert.match(callback,
  /if \(!this\.isHistoryPageContextCurrent\(generation, pageId\)\) \{\s+return;\s+\}\s+this\.applyClipboardPaste\(metadata, source\.kind, targetCenter\);/);
assert.equal((callback.match(/isHistoryPageContextCurrent\(generation, pageId\)/g) ?? []).length, 2);
assert.match(callback,
  /if \(this\.isHistoryPageContextCurrent\(generation, pageId\)\) \{\s+this\.reportSaveFailure\(e\);/);
assert.match(callback,
  /\} else \{\s+hilog\.error\(0x0001, 'NoteCanvasView',\s+'stale paste identity reservation failed:/);
assert.match(callback, /\.finally\(\(\): void => \{\s+this\.historyBusy = false;/);

console.log('D02_ORIGINAL_PASTE_RESERVATION_DISPOSAL_BOUND_REPLAY_OK TOTAL=5 FAILED=0');