// Phase 591 — original DESELECT menu item = deselectMode (点按移除模式),
// NOT "Done/exit selection".
// Original evidence (decompiled_1.0.3/sources/defpackage):
//   dsc.java:71-73 — selection-menu enum ordinal 20 = DESELECT.
//   ux9.java:2396-2398 — the item renders "selection_menu_deselect" +
//     circle_minus icon (label is Deselect, not Done).
//   dhb.java:18035-18043 — dsc.DESELECT (case20) on an ftc state:
//     fvbVar.n = ftcVar2 (save pre-deselect snapshot);
//     ftc.j(ftcVar2, ..., true, ...) → deselectMode=true.
//   dl1.java case2 (ftc.h=true branch) — pointer-down in deselectMode:
//     xtc.a(jE,set) hit ∈ set → stc({id}) / group ntc → stc(cqc.b,cqc.a);
//     overlay cmb inside → utc no-op; else qtc (CancelDeselectMode).
//   ej9.java case18 — stc ids: ys2.H(g,ids) out of selectedIds,
//     ys2.J(i,ids) into deselectedIds; g empty → clear selection.
//   z39.java case17 — CancelDeselectMode: restore fvbVar.n snapshot.
//   n6d.java cases 11/12 — k2f.onConfirmDeselectMode / onCancelDeselectMode
//     (mode has explicit confirm/cancel UI).
// Harmony: SelectionState.deselectMode + deselectedIds + preDeselectSelection
//   snapshot; DESELECT menu enters the mode; tap selected element/group
//   removes it; inside-overlay miss = no-op; outside miss = cancel+restore;
//   overlay menu swaps to Done(confirm)/Cancel while in mode.
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const TOOL = 'note/src/main/ets/rendering/SelectionTool.ets';
const CANVAS = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const OVERLAY = 'note/src/main/ets/ui/components/SelectionOverlay.ets';
const STRINGS = 'note/src/main/resources/base/element/string.json';

const tool = readFileSync(TOOL, 'utf8');
const canvas = readFileSync(CANVAS, 'utf8');
const overlay = readFileSync(OVERLAY, 'utf8');
const strings = readFileSync(STRINGS, 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- SelectionState deselectMode machinery (ftc.h/ftc.i/fvbVar.n parity) ---
check(tool.includes('deselectMode: boolean') && tool.includes('deselectedIds: string[]'),
  'SelectionState carries deselectMode + deselectedIds (ftc.h/ftc.i)');
check(tool.includes('preDeselectSelection'), 'pre-deselect snapshot field (fvbVar.n)');
check(tool.includes('enterDeselectMode()'), 'enterDeselectMode entry');
check(tool.includes('deselectElements(entityIds: string[]'),
  'deselectElements per-tap removal (stc/ej9 case18)');
check(tool.includes('confirmDeselectMode()') && tool.includes('cancelDeselectMode()'),
  'confirm/cancel pair (k2f callbacks)');
const deselectEls = tool.slice(tool.indexOf('deselectElements(entityIds: string[]'),
  tool.indexOf('deselectElements(entityIds: string[]') + 1400);
check(deselectEls.includes('filter(keep)') &&
  deselectEls.includes('deselected.add(id)') &&
  deselectEls.includes('this.deselect()'),
  'removal adds to deselectedIds; empty selection → deselect (g.isEmpty → fvb.a())');
const cancel = tool.slice(tool.indexOf('cancelDeselectMode()'),
  tool.indexOf('cancelDeselectMode()') + 900);
check(cancel.includes('snapshot.selectedStrokeIds') &&
  cancel.includes('snapshot.selectedGroupIds'),
  'cancel restores the full pre-deselect snapshot (z39 case17)');

// --- Overlay: mode menu swaps to confirm/cancel ---
check(overlay.includes('@Prop deselectMode'), 'overlay takes the mode prop');
check(overlay.includes('DESELECT_CONFIRM') && overlay.includes('DESELECT_CANCEL'),
  'confirm/cancel menu actions exist');
const modeMenu = overlay.slice(overlay.indexOf('if (this.deselectMode)'),
  overlay.indexOf('if (this.deselectMode)') + 700);
check(modeMenu.includes('SelectionMenuAction.DESELECT_CONFIRM') &&
  modeMenu.includes('SelectionMenuAction.DESELECT_CANCEL'),
  'deselectMode menu = Done(confirm) + Cancel only');
check(overlay.includes("$r('app.string.deselect')"),
  'menu item labeled Deselect (selection_menu_deselect parity, not Done)');
check(strings.includes('"name": "deselect"'), 'deselect string resource');

// --- Canvas: DESELECT enters mode; confirm/cancel wired ---
const actions = canvas.slice(canvas.indexOf('onSelectionMenuAction(action: SelectionMenuAction):'),
  canvas.indexOf('onSelectionMenuAction(action: SelectionMenuAction):') + 16000);
check(actions.includes('this.selectionTool.enterDeselectMode()'),
  'DESELECT enters deselectMode (dhb case20)');
check(actions.includes('this.selectionTool.confirmDeselectMode()') &&
  actions.includes('this.selectionTool.cancelDeselectMode()'),
  'confirm/cancel menu actions reach the tool');
check(canvas.includes('deselectMode: this.selectionDeselectMode'),
  'overlay receives the mode prop');
check(canvas.includes('@State selectionDeselectMode'),
  '@State mirror drives recomposition');

// --- Canvas: deselectMode pointer-down (dl1 case2 h=true parity) ---
const branch = canvas.slice(canvas.indexOf('isSelectionActive()'),
  canvas.indexOf('isSelectionActive()') + 2400);
check(branch.includes('this.selectionTool.getState().deselectMode'),
  'deselectMode branch precedes normal selection dispatch');
check(branch.includes('this.deselectTargetIdsAt(canvasP)'),
  'hit-test probes the tap target');
check(branch.includes('this.selectionTool.deselectElements(target.entityIds, target.groupIds)'),
  'selected hit → deselectElements (stc/ej9 case18)');
check(branch.includes('this.selectionTool.cancelDeselectMode()') &&
  branch.includes('pointInSelectionRect({ x: touch.x, y: touch.y }, canvasP)'),
  'outside-overlay miss → cancelDeselectMode (qtc/z39 case17)');

// --- deselectTargetIdsAt: selected-element + group-leaf expansion ---
const target = canvas.slice(canvas.indexOf('deselectTargetIdsAt(point: Point2D)'),
  canvas.indexOf('deselectTargetIdsAt(point: Point2D)') + 1600);
check(target.includes('topmostPageElementIdAt(point, selected)'),
  'hit test whitelisted to selected ids (xtc.a(jE, ftc.g) parity)');
check(target.includes('resolveOriginalSelectedGroupLeaves(') &&
  target.includes('groupIds: [groupId]'),
  'hit inside a selected group deselects the whole group (cqc parity)');

console.log(`D02_ORIGINAL_DESELECT_MODE_OK TOTAL=${n} FAILED=0`);
