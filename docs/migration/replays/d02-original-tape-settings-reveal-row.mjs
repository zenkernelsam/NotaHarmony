// Phase 588 — Hide/Reveal Tapes row inside the tape tool's settings surface.
// Original evidence (decompiled_1.0.3/sources/defpackage):
//   o94.java:271-286 — case 14 renders the row in the tape tool's settings
//     sheet: z (tapesRevealed) → tape_reveal icon + "Hide Tapes"
//     (ui_tools__hide_tapes_action); !z → tape_conceal icon + "Reveal Tapes".
//   ipi.java:1490-1505 — the row composable takes (z, onClick) and emits
//     o94(z, 14); click dispatches oh9 → np0 case5 set toggle.
// Harmony: the REVIEW row ⋯ menu in ToolboxSettingsDialog is the tape tool's
//   settings surface (tape_patterns row from Phase 585 sits there). Phase 588
//   adds the same Hide/Reveal item — dynamic label by anyTapeRevealed, gated
//   on pageTapeCount > 0 (empty-set no-op parity with ti9:362), dispatching
//   the same tapeToggleSignal the editor ⋮ options-menu item uses.
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const DIALOG = 'note/src/main/ets/ui/editor/ToolboxSettingsDialog.ets';
const TOOLBAR = 'note/src/main/ets/ui/editor/EditorToolbar.ets';
const PAGE = 'note/src/main/ets/ui/editor/NotePage.ets';

const dialog = readFileSync(DIALOG, 'utf8');
const toolbar = readFileSync(TOOLBAR, 'utf8');
const page = readFileSync(PAGE, 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- Dialog props (session reveal state + toggle callback) ---
check(dialog.includes('@Prop tapeCount') && dialog.includes('@Prop anyTapeRevealed'),
  'dialog receives tape count and reveal state');
check(dialog.includes('onTapeToggle'), 'dialog receives the toggle callback');

// --- REVIEW row menu item (o94 case14 / ipi.b parity) ---
const review = dialog.slice(dialog.indexOf("tool.toolType === ToolType.REVIEW"),
  dialog.indexOf("tool.toolType === ToolType.REVIEW") + 1400);
check(review.includes('tape_patterns'), 'pattern row retained');
check(review.includes('this.tapeCount > 0'),
  'row gated on visible tapes (ti9:362 empty-set no-op parity)');
check(review.includes("this.anyTapeRevealed ?") &&
  review.includes("$r('app.string.hide_tapes')") &&
  review.includes("$r('app.string.reveal_tapes')"),
  'dynamic Hide/Reveal label (o94 z flip parity)');
check(review.includes('this.onTapeToggle()'), 'item dispatches the session toggle');

// --- Toolbar prop chain ---
check(toolbar.includes('@Prop tapeCount') && toolbar.includes('@Prop anyTapeRevealed') &&
  toolbar.includes('onTapeToggle'), 'toolbar exposes the props');
check(toolbar.includes('tapeCount: this.tapeCount') &&
  toolbar.includes('anyTapeRevealed: this.anyTapeRevealed') &&
  toolbar.includes('onTapeToggle: ()'),
  'toolbar plumbs state + callback into the dialog');

// --- NotePage: same signal as the options-menu item ---
const toolbarCtor = page.slice(page.indexOf('EditorToolbar({'),
  page.indexOf('EditorToolbar({') + 600);
check(toolbarCtor.includes('tapeCount: this.pageTapeCount') &&
  toolbarCtor.includes('anyTapeRevealed: this.anyTapeRevealed'),
  'NotePage feeds the session reveal state');
check(toolbarCtor.includes('this.tapeToggleSignal++'),
  'dialog item increments the same toggle signal as the ⋮ menu item');

// --- Both surfaces share one action (o94 case14 → oh9 parity) ---
check(page.includes('this.pageTapeCount > 0') &&
  page.includes('this.tapeToggleSignal++'),
  'options-menu item unchanged (same signal)');

console.log(`D02_ORIGINAL_TAPE_SETTINGS_REVEAL_ROW_OK TOTAL=${n} FAILED=0`);
