import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const original = value => fs.readFileSync(originalRoot + value, 'utf8');

const dhb = original('dhb.java');
const x08 = original('x08.java');
const v08 = original('v08.java');
const n07 = original('n07.java');
const strings = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/resources/res/values/strings.xml', 'utf8');
const encoder = read('note/src/main/ets/data/OriginalModifyBlockPayloadEncoder.ets');
const persistence = read('note/src/main/ets/data/StrokePersistence.ets');
const overlay = read('note/src/main/ets/ui/components/MathEditorOverlay.ets');
const selection = read('note/src/main/ets/ui/components/SelectionOverlay.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const encoderFixture = read('note/src/test/OriginalModifyBlockPayloadEncoder.test.ets');
const persistenceFixture = read('note/src/test/StrokePersistence.test.ets');
const overlayFixture = read('note/src/test/MathEditorOverlay.test.ets');

assert.match(dhb, /new x08\([^,]+,\s*\(\(u08\)[^)]+\)\.R\(\)\)/);
assert.match(x08, /Edit\(blockId=/);
assert.match(v08, /feature_note__math_editor_title/);
assert.match(v08, /feature_note__math_editor_invalid/);
assert.match(v08, /instanceof owa/);
assert.match(n07, /case 10:[\s\S]*?new ku5\(z08Var, g18Var, str, null, 16\)/);
assert.match(strings, /feature_note__selection_menu_edit_math/);
assert.match(strings, /feature_note__math_editor_failed/);

assert.match(encoder, /export function encodeOriginalMathLatex/);
assert.match(encoder, /fields\[10\] = 8/);
assert.match(encoder, /writeVtable\(bytes, setterVtable, 8, \[4\]\)/);
assert.match(encoder, /MAX_ORIGINAL_MATH_LATEX_BYTES/);
assert.match(persistence, /export function classifyOriginalMathLatexMutation/);
assert.match(persistence, /before\.latex === after\.latex/);
assert.match(persistence, /commitOriginalMathLatex/);
assert.match(persistence, /applyOriginalMathLatex/);
assert.match(persistence, /uploadImmediately: true/);
assert.match(persistence, /local Math latex reducer diverged from the requested canonical snapshot/);
assert.match(selection, /SelectionMenuAction\.EDIT_MATH/);
assert.match(selection, /app\.string\.edit_math/);
assert.match(canvas, /selectedMathIds\.length === 1/);
assert.match(canvas, /this\.persistence\.commitOriginalMathLatex/);
assert.match(canvas, /this\.undoRedo\.push\(action, prepared\)/);
assert.match(canvas, /this\.mathEditorFailed = true/);
assert.match(overlay, /isOriginalMathLatexDraftValid/);
assert.match(overlay, /OriginalMathEditorDraftState/);
assert.match(overlay, /enabled\(isOriginalMathEditorDoneEnabled\(this\.draftState, this\.busy\)\)/);
assert.match(canvas, /originalMathEngine\.render\(draft/);
assert.match(encoderFixture, /round-trips the Math latex nullable setter string/);
assert.match(persistenceFixture, /classifies one canonical Math latex-only edit and reverse Undo/);
assert.match(overlayFixture, /enables Done only for an idle native-rendered Ok state/);

console.log('localMathLatexEdit=' +
  'original-edit-menu-prefill-native-four-state-preview-done|type23-field10|single-transaction|' +
  'upload-immediate|canonical-reducer|persistent-history|failure-keeps-draft');
