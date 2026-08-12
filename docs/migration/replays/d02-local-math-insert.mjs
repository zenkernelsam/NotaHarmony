import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const original = value => fs.readFileSync(originalRoot + value, 'utf8');

const y08 = original('y08.java');
const z39 = original('z39.java');
const fh3 = original('fh3.java');
const n07 = original('n07.java');
const g18 = original('g18.java');
const s18 = original('s18.java');
const u5j = original('u5j.java');
const toolbar = read('note/src/main/ets/ui/editor/EditorToolbar.ets');
const page = read('note/src/main/ets/ui/editor/NotePage.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const plan = read('note/src/main/ets/core/model/OriginalMathInsertPlan.ets');
const persistence = read('note/src/main/ets/data/StrokePersistence.ets');
const fixture = read('note/src/test/OriginalMathInsertPlan.test.ets');

assert.match(y08, /implements z08/);
assert.match(y08, /return "Insert"/);
assert.match(z39, /case 1:[\s\S]*?asdVar\.k\(null, y08\.a\)/);
assert.match(fh3, /z08Var instanceof x08[\s\S]*?str = ""[\s\S]*?fsi\.T\(str\)/);
assert.match(n07, /case 10:[\s\S]*?new ku5\(z08Var, g18Var, str, null, 16\)/);
assert.match(g18, /public static final SizeF U = new SizeF\(240\.0f, 120\.0f\)/);
assert.match(g18, /public static final Object j\(g18 g18Var, String str/);
assert.match(g18, /No page at viewport center for math insert/);
assert.match(g18, /cz0\.MATH[\s\S]*?sizeF\.getWidth\(\)[\s\S]*?str2[\s\S]*?tu1\.a\(0\.0f, 0\.0f, 0\.0f, 1\.0f\)/);
assert.match(s18, /nativeMeasure\(str, f, fMax\)/);
assert.match(s18, /Math\.min\(fFloor \/ f3, fFloor2 \/ f4\)/);
assert.match(u5j, /baj\.a\(cz0Var, ty0\.SQUARE/);

assert.match(toolbar, /app\.string\.insert_math/);
assert.match(toolbar, /this\.onInsertMath\(\)/);
assert.match(page, /this\.mathInsertSignal\+\+/);
assert.match(canvas, /@Watch\('onMathInsertSignalChange'\)/);
assert.match(canvas, /createOriginalMathInsertDraft/);
assert.match(canvas, /this\.persistence\.commitOriginalMathInsert/);
assert.match(canvas, /onPageChange[\s\S]*?this\.cancelMathEditing\(\)[\s\S]*?this\.switchPageData\(\)/);
assert.match(canvas, /this\.mathBlocks = this\.mathBlocks\.concat\(\[result\.math\]\)/);
assert.match(canvas, /this\.selectionTool\.selectElementIds\(\[\], \[\], \[\], \[\], \[\], \[result\.math\.id\]\)/);
assert.match(persistence, /async commitOriginalMathInsert/);
assert.match(persistence, /OriginalCreateBlockOperationApplier\(\)\.applyBatchedPayload/);
assert.match(persistence, /OpType\.ORIGINAL_CREATE_BLOCK/);
assert.match(persistence, /uploadImmediately: true/);
assert.match(persistence, /appendHistoryCompanion\(store, finalSnapshot, mutation\)/);
assert.match(persistence, /await store\.rollBack\(\)/);
assert.match(plan, /ORIGINAL_MATH_INSERT_MAX_WIDTH: number = 240/);
assert.match(plan, /ORIGINAL_MATH_INSERT_MAX_HEIGHT: number = 120/);
assert.match(plan, /color: -16777216/);
assert.match(plan, /rotationRadians: 0, corner: 0, textWrap: 0/);
assert.match(fixture, /centers the original maximum Math box with original defaults/);
assert.match(fixture, /accepts measured engine output within the original maximum box/);

console.log('localMathInsert=' +
  'original-insert-state-empty-editor|viewport-center|240x120-engine-bound|' +
  'type22-create-block|upload-immediate|single-revision|persistent-history|' +
  'durable-before-ui|selected-result|page-switch-cancel|rollback-keeps-draft');
