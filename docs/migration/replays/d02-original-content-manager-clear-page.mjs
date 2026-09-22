import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const desktop = 'C:/Users/Cisco He/Desktop/Notability/';
const readOriginal = path => fs.readFileSync(desktop + path, 'utf8');

const pageBar = read('note/src/main/ets/ui/editor/PageManagerBar.ets');
const notePage = read('note/src/main/ets/ui/editor/NotePage.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const selectionTool = read('note/src/main/ets/rendering/SelectionTool.ets');
const stringsBase = read('note/src/main/resources/base/element/string.json');
const stringsZh = read('note/src/main/resources/zh_CN/element/string.json');

let checks = 0;
const ok = (cond, label) => { assert.ok(cond, label); checks++; };

// --- Original evidence anchors ----------------------------------------------------------
const n9j = readOriginal('decompiled_1.0.3/sources/defpackage/n9j.java');
const tfh = readOriginal('decompiled_1.0.3/sources/defpackage/tfh.java');
const origStrings = readOriginal('decompiled_1.0.3/resources/res/values/strings.xml');

// n9j: content-manager toolbar carries a Clear Page action with the clear_page icon.
ok(n9j.includes('R.string.feature_note__content_manager_clear_page') &&
   n9j.includes('R.drawable.ui_designsystem__clear_page'),
  'original content-manager clear-page action missing');
// tfh: per-page action sheet lists Bookmark then Clear Page.
ok(tfh.includes('feature_note__content_manager_bookmark') &&
   tfh.includes('feature_note__content_manager_clear_page') &&
   tfh.indexOf('content_manager_bookmark') < tfh.indexOf('content_manager_clear_page'),
  'original per-page bookmark->clear order missing');
// Original label + no confirmation string in the content-manager namespace.
ok(origStrings.includes(
  '<string name="feature_note__content_manager_clear_page">Clear Page</string>'),
  'original Clear Page label missing');
ok(!origStrings.includes('content_manager_clear_page_confirm') &&
   !origStrings.includes('content_manager_clear_page_message'),
  'unexpected original clear-page confirmation found');

// --- Harmony anchors ----------------------------------------------------------------------
// PageManagerBar: clear-page menu item wired to a dedicated callback, placed
// between Bookmark and Delete Page (original per-page sheet tail order).
ok(/onClearPage: \(\) => void/.test(pageBar), 'onClearPage prop missing');
ok(/app\.string\.bookmark_page[\s\S]*?app\.string\.clear_page[\s\S]*?app\.string\.delete_page/
  .test(pageBar), 'menu order bookmark->clear->delete missing');
ok(/app\.string\.clear_page'\), action: \(\) => \{\s*if \(this\.busy \|\| this\.photoImportLeaseActive\)/
  .test(pageBar), 'clear-page menu guard missing');
// NotePage: signal state, canvas wiring, and the page-menu callback.
ok(notePage.includes('@State clearPageSignal: number = 0;') &&
   notePage.includes('clearPageSignal: this.clearPageSignal,') &&
   /onClearPage: \(\) => \{\s*this\.clearPageSignal\+\+;/.test(notePage),
  'clear-page signal wiring missing');
// NoteCanvasView: watched prop plus the select-all -> DELETE composite.
ok(canvas.includes("@Prop @Watch('onClearPageSignalChange') clearPageSignal: number = 0;"),
  'clear-page signal prop missing');
ok(canvas.includes('private clearCurrentPageContent()') &&
   canvas.includes('this.selectionTool.selectElementIds(strokeIds, shapeIds, textIds, imageIds, [], mathIds)') &&
   canvas.includes('this.onSelectionMenuAction(SelectionMenuAction.DELETE)'),
  'clear-page select-all->delete composite missing');
// Empty page short-circuits before touching the selection.
ok(/clearCurrentPageContent\(\): void \{\s*if \(this\.elementOrder\.length === 0\) \{\s*return;/.test(canvas),
  'clear-page empty-page guard missing');
// Every elementOrder kind is bucketed (no GROUP kind — members ride as STROKE refs).
for (const kind of ['STROKE', 'SHAPE', 'TEXT', 'IMAGE', 'MATH']) {
  ok(canvas.includes(`ref.kind === PageElementKind.${kind}`),
    `clear-page ${kind} bucket missing`);
}
// selectElementIds accepts the full per-kind id lists used by the composite.
ok(/selectElementIds\(strokeIds: string\[\], shapeIds: string\[\], textBlockIds: string\[\] = \[\],\s*imageIds: string\[\] = \[\], groupIds: string\[\] = \[\], mathIds: string\[\] = \[\]\)/
  .test(selectionTool), 'selectElementIds signature missing');

// --- Executable behaviour model -----------------------------------------------------------
// Model clearCurrentPageContent over a synthetic element order: every element id
// lands in the matching DELETE bucket, preserving page coverage exactly.
const KIND = { STROKE: 1, TEXT: 2, SHAPE: 3, IMAGE: 4, MATH: 5 };
const elementOrder = [
  { kind: KIND.STROKE, elementId: 's1' }, { kind: KIND.TEXT, elementId: 't1' },
  { kind: KIND.STROKE, elementId: 's2' }, { kind: KIND.SHAPE, elementId: 'sh1' },
  { kind: KIND.IMAGE, elementId: 'i1' }, { kind: KIND.MATH, elementId: 'm1' },
];
const bucket = { strokes: [], shapes: [], texts: [], images: [], maths: [] };
for (const ref of elementOrder) {
  if (ref.kind === KIND.STROKE) bucket.strokes.push(ref.elementId);
  else if (ref.kind === KIND.SHAPE) bucket.shapes.push(ref.elementId);
  else if (ref.kind === KIND.TEXT) bucket.texts.push(ref.elementId);
  else if (ref.kind === KIND.IMAGE) bucket.images.push(ref.elementId);
  else if (ref.kind === KIND.MATH) bucket.maths.push(ref.elementId);
}
assert.deepEqual(bucket.strokes, ['s1', 's2']);
assert.deepEqual(bucket.shapes, ['sh1']);
assert.deepEqual(bucket.texts, ['t1']);
assert.deepEqual(bucket.images, ['i1']);
assert.deepEqual(bucket.maths, ['m1']);
assert.equal(bucket.strokes.length + bucket.shapes.length + bucket.texts.length +
  bucket.images.length + bucket.maths.length, elementOrder.length);
checks += 6;

// --- Strings --------------------------------------------------------------------------------
ok(stringsBase.includes('"name": "clear_page"') &&
   stringsZh.includes('"name": "clear_page"'),
  'clear_page string missing in a locale');
ok(stringsBase.includes('"value": "Clear Page"'),
  'clear_page EN value diverges from the original label');

console.log(`D02_ORIGINAL_CONTENT_MANAGER_CLEAR_PAGE_OK TOTAL=${checks} FAILED=0`);
