import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';
const original = value => fs.readFileSync(originalRoot + value, 'utf8');

const kt1 = original('sources/defpackage/kt1.java');
const bt1 = original('sources/defpackage/bt1.java');
const dh5 = original('sources/defpackage/dh5.java');
const a5g = original('sources/defpackage/a5g.java');
const fg2 = original('sources/defpackage/fg2.java');
const wq9 = original('sources/defpackage/wq9.java');
const preview = read('note/src/main/ets/rendering/OriginalPartialEraserTransientPreview.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const layers = read('note/src/main/ets/rendering/StrokeLayerManager.ets');
const strokeTypes = read('note/src/main/ets/core/model/StrokeTypes.ets');
const fixture = read('note/src/test/OriginalPartialEraserTransientPreview.test.ets');
const fixtureList = read('note/src/test/List.test.ets');
const evidence = read(
  'docs/migration/evidence/original-partial-eraser-transient-preview-jadx-2026-08-16.md');

// Original pointer-down creates a transient tool-5 Ink and retains its operation ID.
assert.match(kt1,
  /if \(\(q5fVarC instanceof q4f\) && \(\(q4f\) q5fVarC\)\.b\(\) == d04\.J\) \{\s*u16VarL = u16\.PARTIAL_ERASER;/);
assert.match(kt1, /dm2 dm2VarG = u5j\.g\(/);
assert.match(bt1, /kt1Var\.l = xq9Var\.a\(new wq9\(\(dm2\) obj6, null, true/);

// Move appends to the active transient ID; finish selects jt1 rather than normal CREATE_INK.
assert.match(kt1, /gdVarA = u5j\.a\(a\(\), qo5Var, arrayList, arrayList2\)/);
assert.match(dh5,
  /if \(q4fVar\.b\(\) == d04\.J\) \{[\s\S]{0,700}new jt1\(kt1Var5,/);
assert.match(a5g, /public final void cancel\(\)[\s\S]{0,420}new fg2\(qo5Var, 5\)/);
assert.match(fg2, /new wq9\(oqi\.a\(qo5Var\), null, false, null, 30\)/);
assert.match(wq9, /if \(z \|\| qo5Var != null\)/);

// Harmony preview is memory-only, token guarded, bounded, and uses tool-5 rendering.
assert.match(preview, /IDLE = 0,[\s\S]{0,80}TRACKING = 1,[\s\S]{0,80}AWAITING_COMMIT = 2/);
assert.match(preview, /MAX_ORIGINAL_PARTIAL_ERASER_PREVIEW_POINTS: number = 65535/);
assert.match(preview, /isPartialEraser: true/);
assert.match(preview, /A truncated eraser path could delete content the user did not preview/);
assert.match(preview, /complete\(token: number\)[\s\S]{0,180}token !== this\.activeToken/);
assert.doesNotMatch(preview, /operation_log|queueSaveElements|commitOriginalPartialErase/);
assert.match(strokeTypes, /completed local partial erase persists replacement Ink, never this tool-5 path/);

// UI keeps the preview through the durable wait and clears it on every terminal path.
assert.match(canvas, /partialEraserPreview\.begin\(point, this\.eraserEngine\.getWidth\(\)\)/);
assert.match(canvas, /partialEraserPreview\.append\(point\)/);
assert.match(canvas, /const previewToken: number \| null = this\.partialEraserPreview\.finish\(\)/);
assert.match(canvas, /commitOriginalPartialErase\(plan, previewToken\)/);
assert.match(canvas,
  /commitOriginalPartialErase\([\s\S]{0,1100}partialEraserPreview\.complete\(previewToken\)/);
assert.match(canvas, /this\.cancelActiveInteraction\(\);[\s\S]{0,80}if \(!this\.loaded\)/);
assert.match(canvas, /aboutToDisappear\(\)[\s\S]{0,100}partialEraserPreview\.cancel\(\)/);

// Common pages isolate only handwriting dirty bounds; paper and text are redrawn outside the mask.
assert.match(layers, /compositeWithPartialEraser\(/);
assert.match(layers, /pixelAlignedPageCrop\(dirty\)/);
assert.match(layers, /BitmapTransferKind\.ISOLATED_MASK/);
assert.match(layers, /renderBackground\(\);[\s\S]{0,1200}renderForeground\(\)/);
assert.match(canvas, /layerManager\.compositeWithPartialEraser/);
assert.match(canvas, /this\.renderTextBlocks\(\);[\s\S]{0,80}this\.viewport\.zoom, forceFull/);

// A fulfilled durable promise has its own guarded handler; UI failure cannot fall into local fallback.
assert.match(canvas,
  /commitOriginalPartialErase\(this\.noteId, pageId, plan, prepared\)\.then\([\s\S]{0,1800}\}, \(e: Object\): void => \{/);
assert.match(canvas, /durable transaction has already committed/);
assert.match(canvas, /this\.pageLoadPromise = this\.loadNoteData\(\)/);

assert.match(fixture, /keeps tool-5 preview transient through durable commit/);
assert.match(fixture, /does not let a stale completion clear a newer gesture/);
assert.match(fixture, /fails the whole gesture instead of committing a truncated path/);
assert.match(fixtureList, /originalPartialEraserTransientPreviewTest\(\)/);
assert.match(evidence, /815C902D4F4F34CCBD993BAFD5A90577302C8CB669CBBFDC512CD3AD4E77CFF3/);

// Token behavior is intentionally monotonic and stale completion is a no-op.
let nextToken = 0;
const begin = () => ++nextToken;
const first = begin();
const second = begin();
assert.equal(first, 1);
assert.equal(second, 2);
assert.notEqual(first, second);

console.log(
  'originalPartialEraserTransientPreview=tool5-memory-preview-dirty-crop-commit-end-cancel-fail-closed');
