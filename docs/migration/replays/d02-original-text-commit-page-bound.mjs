import assert from 'node:assert/strict';
import fs from 'node:fs';

const canvas = fs.readFileSync(
  'note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8');

const branchIndex = canvas.indexOf('} else if (this.editingOriginalTextBlock.richText !== text) {');
assert.notEqual(branchIndex, -1);
const branchEnd = canvas.indexOf('\n      } else if (', branchIndex);
const branchEnd2 = canvas.indexOf('\n      }\n    }\n    this.textEditing = false;', branchIndex);
const bodyEnd = Math.min(...[branchEnd, branchEnd2].filter(value => value >= 0));
const body = canvas.slice(branchIndex, bodyEnd);

assert.match(body, /const generation: number = this\.pageLoadGeneration;/);
assert.match(body, /preview = await this\.persistence\.previewOriginalTextEdit\(/);
assert.match(body, /if \(this\.editingTextBlock !== editing \|\| this\.editingOriginalTextBlock !== original \|\|\s+!this\.isHistoryPageContextCurrent\(generation, pageId\)\) \{\s+hilog\.error\(0x0001, 'NoteCanvasView',\s+'original Text edit rejected after page changed'\);\s+return false;\s+\}/);
assert.match(body, /original Text edit rejected after page changed/);
assert.match(body, /replaceTextBlock\(updated\)/);
assert.match(body, /undoRedo\.push\(\{[\s\S]+?REPLACE_ELEMENT[\s\S]+?\}\);/);

assert.match(canvas,
  /private isHistoryPageContextCurrent\(generation: number, pageId: string\): boolean \{\s+return this\.lifecycleActive && generation === this\.pageLoadGeneration &&\s+pageId === this\.loadedPageId && pageId === this\.currentPage\.pageId &&\s+this\.loaded && !this\.dataLoading && !this\.dataLoadFailed;\s+\}/);

console.log('D02_ORIGINAL_TEXT_COMMIT_PAGE_BOUND_REPLAY_OK TOTAL=5 FAILED=0');
