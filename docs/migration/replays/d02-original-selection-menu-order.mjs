// D02-REPLAY Phase 544 — original selection menu order parity.
// Original dsc enum (dsc.java) fixes the selection-menu order; ux9 maps each
// ordinal to its r68 item; v49 renders paste as a separate floating chip.
// Harmony: buildSelectionMenu now emits the portable subset in dsc order plus
// DUPLICATE / SEND_TO_FRONT / SEND_TO_BACK implementations.
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, '..', '..', '..');
const evidenceRoot =
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';

const dsc = readFileSync(join(evidenceRoot, 'dsc.java'), 'utf8');
const ux9 = readFileSync(join(evidenceRoot, 'ux9.java'), 'utf8');
const dhb = readFileSync(join(evidenceRoot, 'dhb.java'), 'utf8');
const overlay = readFileSync(
  join(root, 'note/src/main/ets/ui/components/SelectionOverlay.ets'), 'utf8');
const canvas = readFileSync(
  join(root, 'note/src/main/ets/ui/editor/NoteCanvasView.ets'), 'utf8');
const order = readFileSync(
  join(root, 'note/src/main/ets/core/model/PageElementOrder.ets'), 'utf8');
const baseStrings = readFileSync(
  join(root, 'note/src/main/resources/base/element/string.json'), 'utf8');
const zhStrings = readFileSync(
  join(root, 'note/src/main/resources/zh_CN/element/string.json'), 'utf8');

let total = 0;
let failed = 0;
function ok(cond, msg) {
  total++;
  try {
    assert.ok(cond, msg);
  } catch (e) {
    failed++;
    console.error(`FAIL: ${msg}`);
  }
}

// --- Original evidence anchors -------------------------------------------

// dsc enum declaration order is the menu order.
const dscNames = [...dsc.matchAll(/new dsc\("(\w+)", (\d+)\)/g)]
  .map((m) => ({ name: m[1], ordinal: Number(m[2]) }))
  .sort((a, b) => a.ordinal - b.ordinal)
  .map((e) => e.name);
assert.deepEqual(dscNames, [
  'STYLE', 'COPY', 'CUT', 'DUPLICATE', 'GROUP', 'UNGROUP', 'SEND_FORWARD',
  'SEND_BACKWARD', 'SEND_TO_FRONT', 'SEND_TO_BACK', 'DELETE',
  'CONVERT_TO_MATH', 'CONVERT_TO_TEXT', 'EDIT_MATH', 'CROP', 'FIT_TO_PAGE',
  'FLIP_HORIZONTALLY', 'FLIP_VERTICALLY', 'LOCK', 'UNLOCK', 'DESELECT', 'MORE',
]);
total++;
ok(ux9.includes('R.string.feature_note__selection_menu_duplicate'),
  'original DUPLICATE menu item missing');
ok(ux9.includes('R.string.feature_note__selection_menu_send_to_front') &&
   ux9.includes('R.string.feature_note__selection_menu_send_to_back'),
  'original SEND_TO_FRONT/BACK menu items missing');

// --- Harmony anchors ------------------------------------------------------

ok(overlay.includes('DUPLICATE = 14') &&
   overlay.includes('SEND_TO_FRONT = 15') &&
   overlay.includes('SEND_TO_BACK = 16'),
  'Harmony SelectionMenuAction missing new values');

// Harmony menu emits the urf (1.4.2) assembly order flat: main row then
// MORE-submenu tail (Phase 1440 — urf supersedes the 1.0.3 dsc enum-order
// assumption; wqf dsc names map 1:1 to wqf letters).
const menuStart = overlay.indexOf('private buildSelectionMenu()');
ok(menuStart >= 0, 'Harmony buildSelectionMenu missing');
let menuBody = overlay.slice(menuStart);
// Phase 1441: the lockedOnly early-return row (urf z-branch single-item
// [UNLOCK] menu) dispatches SelectionMenuAction.LOCK and sits before the
// sequential assembly — strip it so the order-walk sees only flat rows.
const lockOnlyAt = menuBody.indexOf('if (this.lockedOnly) {');
ok(lockOnlyAt >= 0, 'lockedOnly early-return row missing');
const lockOnlyEnd = menuBody.indexOf('return items;', lockOnlyAt);
ok(lockOnlyEnd >= 0, 'lockedOnly block end missing');
menuBody = menuBody.slice(0, lockOnlyAt) + menuBody.slice(lockOnlyEnd);
const harmonyOrder = [
  'SelectionMenuAction.CROP', 'SelectionMenuAction.EDIT_MATH',
  'SelectionMenuAction.STYLE', 'SelectionMenuAction.COPY',
  'SelectionMenuAction.CUT', 'SelectionMenuAction.DUPLICATE',
  'SelectionMenuAction.PASTE',
  'SelectionMenuAction.GROUP', 'SelectionMenuAction.UNGROUP',
  'SelectionMenuAction.LOCK', 'SelectionMenuAction.DESELECT)',
  'SelectionMenuAction.DELETE', 'SelectionMenuAction.FLIP_H',
  'SelectionMenuAction.FLIP_V',
  'SelectionMenuAction.SEND_TO_FRONT', 'SelectionMenuAction.SEND_TO_BACK',
  'SelectionMenuAction.SEND_FORWARD', 'SelectionMenuAction.SEND_BACKWARD',
];
let cursor = -1;
for (const item of harmonyOrder) {
  // ')' suffix keeps DESELECT from prefix-matching DESELECT_CONFIRM/CANCEL
  // (Phase 591 deselectMode branch sits earlier in buildSelectionMenu).
  const at = menuBody.indexOf(item);
  assert.ok(at > cursor, `${item} out of order or missing`);
  cursor = at;
}
total += harmonyOrder.length;

// Every menu item is a subsequence of the 1.4.2 urf flat order (PASTE
// excluded — it is the floating-chip adaptation and has no wqf ordinal).
const urfFlat = [
  'CROP', 'EDIT_MATH', 'STYLE', 'COPY', 'CUT', 'DUPLICATE', 'GROUP',
  'UNGROUP', 'LOCK', 'DESELECT', 'DELETE', 'FLIP_HORIZONTALLY',
  'FLIP_VERTICALLY', 'SEND_TO_FRONT', 'SEND_TO_BACK', 'SEND_FORWARD',
  'SEND_BACKWARD',
];
const urfIndex = new Map(urfFlat.map((n, i) => [n, i]));
const mapped = [
  ['STYLE', 'STYLE'], ['COPY', 'COPY'], ['CUT', 'CUT'], ['DUPLICATE', 'DUPLICATE'],
  ['GROUP', 'GROUP'], ['UNGROUP', 'UNGROUP'],
  ['LOCK', 'LOCK'], ['DESELECT', 'DESELECT'], ['DELETE', 'DELETE'],
  ['FLIP_H', 'FLIP_HORIZONTALLY'], ['FLIP_V', 'FLIP_VERTICALLY'],
  ['SEND_TO_FRONT', 'SEND_TO_FRONT'], ['SEND_TO_BACK', 'SEND_TO_BACK'],
  ['SEND_FORWARD', 'SEND_FORWARD'], ['SEND_BACKWARD', 'SEND_BACKWARD'],
];
let prev = -1;
for (const [harmony, original] of mapped) {
  const idx = urfIndex.get(original);
  assert.ok(idx !== undefined && idx > prev,
    `${harmony} violates urf order`);
  prev = idx;
}
total++;

// Canvas handlers for the new actions.
ok(/action === SelectionMenuAction\.SEND_TO_FRONT \|\| action === SelectionMenuAction\.SEND_TO_BACK/.test(canvas) &&
   canvas.includes('this.reorderSelectedToExtreme('),
  'Harmony extreme reorder dispatch missing');
ok(canvas.includes('action === SelectionMenuAction.DUPLICATE') &&
   canvas.includes('this.duplicateSelected('),
  'Harmony duplicate dispatch missing');
ok(order.includes('export function movePageElementRefsToExtreme'),
  'Harmony movePageElementRefsToExtreme missing');
ok(canvas.includes('OriginalZOrderCommand.BRING_FRONT') &&
   canvas.includes('OriginalZOrderCommand.SEND_BACK'),
  'Harmony BRING_FRONT/SEND_BACK hint wiring missing');
ok(canvas.includes('this.lastPasteRequestTime = 0;'),
  'Harmony duplicate paste-debounce reset missing');
// Phase 595 — dsc.STYLE (ordinal 0): gated on ink selection, opens the
// selection style surface (selectionMode ColorPickerView + WidthSlider).
ok(overlay.includes('@Prop canStyle: boolean = false;') &&
   menuBody.indexOf('if (this.canStyle)') >= 0 &&
   menuBody.indexOf('if (this.canStyle)') <
   menuBody.indexOf('SelectionMenuAction.STYLE'),
  'Harmony STYLE item must be gated by canStyle before the push');
ok(canvas.includes('this.selectionCanStyle = state.selectedStrokeIds.length > 0 ||') &&
   canvas.includes('state.selectedShapeIds.length > 0;'),
  'Harmony selectionCanStyle must cover strokes and shapes');
ok(canvas.includes('action === SelectionMenuAction.STYLE') &&
   canvas.includes('this.viewModel.showColorPicker = true;') &&
   canvas.includes('this.viewModel.showWidthSlider = true;'),
  'Harmony STYLE must open the selection color+width surface');
ok(baseStrings.includes('"name": "selection_style"') &&
   zhStrings.includes('"name": "selection_style"'),
  'Harmony selection_style string missing');
ok(/copySelectedToClipboard\(ids, shapeIds, textIds, imageIds, mathIds, groupIds\)/.test(canvas) &&
   canvas.includes('this.pasteClipboard(target);'),
  'Harmony duplicate copy+paste composite missing');
// Extreme move keeps undo + z-order hint parity with the one-step path.
const extremeStart = canvas.indexOf('private reorderSelectedToExtreme(');
const extremeEnd = canvas.indexOf('private duplicateSelected(', extremeStart);
ok(extremeStart >= 0 && extremeEnd > extremeStart,
  'Harmony reorderSelectedToExtreme body missing');
const extremeBody = canvas.slice(extremeStart, extremeEnd);
ok(extremeBody.includes('UndoableActionType.REORDER_ELEMENTS') &&
   extremeBody.includes('resolveOriginalSelectedGroupLeaves') &&
   extremeBody.includes('areCanonicalOriginalPositionSelection'),
  'Harmony extreme reorder must keep undo/group/hint parity');

// Strings.
for (const s of ['send_to_front', 'send_to_back']) {
  ok(baseStrings.includes(`"name": "${s}"`), `base string ${s} missing`);
  ok(zhStrings.includes(`"name": "${s}"`), `zh string ${s} missing`);
}
ok(baseStrings.includes('"value": "Send forward"') &&
   baseStrings.includes('"value": "Send backward"'),
  'Harmony send forward/backward labels must match original copy');

// --- Executable model -----------------------------------------------------

// Extreme move: selected units partition to the front or back, preserving
// relative order (non-group units only).
function extreme(units, selected, front) {
  const moving = [];
  const staying = [];
  for (const u of units) {
    (selected.has(u) ? moving : staying).push(u);
  }
  return front ? staying.concat(moving) : moving.concat(staying);
}
assert.deepEqual(extreme(['a', 'b', 'c', 'd'], new Set(['b', 'd']), true),
  ['a', 'c', 'b', 'd']);
assert.deepEqual(extreme(['a', 'b', 'c', 'd'], new Set(['b', 'd']), false),
  ['b', 'd', 'a', 'c']);
total += 2;

// Phase 633 — FIT_TO_PAGE is an upstream stub: ux9 renders the item but
// dhb's case 15 handler is a bare NotImplementedError. Harmony's omission is
// parity (strictly better than a crash item), so the menu must NOT grow it.
const dhbCase15 = dhb.slice(dhb.indexOf('case 15:'), dhb.indexOf('case 15:') + 200);
ok(dhbCase15.includes('throw new NotImplementedError'),
  'original dhb case15 (FIT_TO_PAGE) must remain a NotImplementedError stub');
ok(!overlay.includes('SelectionMenuAction.FIT_TO_PAGE') &&
   !overlay.includes('fit_to_page'),
  'Harmony must not expose a FIT_TO_PAGE menu action');
ok(overlay.includes('NotImplementedError'),
  'SelectionOverlay comment must cite the upstream stub');
total += 3;

console.log(`D02_ORIGINAL_SELECTION_MENU_ORDER_OK TOTAL=${total} FAILED=${failed}`);
if (failed > 0) {
  process.exit(1);
}
