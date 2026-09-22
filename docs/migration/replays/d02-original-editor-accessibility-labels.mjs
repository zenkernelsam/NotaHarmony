// Phase 558 — original editor accessibility labels.
// Original strings.xml evidence:
//   feature_note__toprighttoolbar_undo_action "Undo Action"   → ↶ button
//   feature_note__toprighttoolbar_redo_action "Redo Action"   → ↷ button
//   feature_note__cd_quick_tool_color         "Color"         → color well
//   feature_note__toolbar_more_menu           "More options"  → overflow menus
//   feature_note_toolbox__settings_close      "Close"         → ✕ dialog close
//   feature_note__page_indicator              "%1$d of %2$d"  → page indicator
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const toolbar = readFileSync('note/src/main/ets/ui/editor/EditorToolbar.ets', 'utf8');
const bar = readFileSync('note/src/main/ets/ui/editor/PageManagerBar.ets', 'utf8');
const dlg = readFileSync('note/src/main/ets/ui/editor/ToolboxSettingsDialog.ets', 'utf8');
const canvas = readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8');
const baseJson = JSON.parse(readFileSync('note/src/main/resources/base/element/string.json', 'utf8'));
const zhJson = JSON.parse(readFileSync('note/src/main/resources/zh_CN/element/string.json', 'utf8'));
const baseVal = n => baseJson.string.find(e => e.name === n)?.value;
const zhVal = n => zhJson.string.find(e => e.name === n)?.value;

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- String values match the originals (EN verbatim; zh non-empty) ---
check(baseVal('cd_undo_action') === 'Undo Action', 'cd_undo_action EN');
check(baseVal('cd_redo_action') === 'Redo Action', 'cd_redo_action EN');
check(baseVal('cd_quick_tool_color') === 'Color', 'cd_quick_tool_color EN');
check(baseVal('cd_page_indicator') === '%1$d of %2$d', 'cd_page_indicator EN');
check(baseVal('toolbar_more_menu') === 'More options', 'toolbar_more_menu EN');
check(zhVal('cd_undo_action')?.length > 0, 'cd_undo_action zh');
check(zhVal('cd_redo_action')?.length > 0, 'cd_redo_action zh');
check(zhVal('cd_quick_tool_color')?.length > 0, 'cd_quick_tool_color zh');
check(zhVal('cd_page_indicator')?.includes('%1$d'), 'cd_page_indicator zh placeholders');
check(zhVal('toolbar_more_menu')?.length > 0, 'toolbar_more_menu zh');

// --- Undo/redo glyph buttons carry the original descriptions ---
const undoIdx = toolbar.indexOf("Button('↶')");
const undoBlock = toolbar.slice(undoIdx, toolbar.indexOf('onClick', undoIdx));
check(undoBlock.includes('cd_undo_action'), 'undo button label');
const redoIdx = toolbar.indexOf("Button('↷')");
const redoBlock = toolbar.slice(redoIdx, toolbar.indexOf('onClick', redoIdx));
check(redoBlock.includes('cd_redo_action'), 'redo button label');

// --- Color well (empty-label circle) announces "Color" ---
const colorIdx = toolbar.indexOf('.borderRadius(16)');
const colorBlock = toolbar.slice(toolbar.lastIndexOf('Button()', colorIdx), toolbar.indexOf('onClick', colorIdx));
check(colorBlock.includes('cd_quick_tool_color'), 'color well label');

// --- Overflow menus use "More options" (toolbar_more_menu) ---
check(toolbar.includes("accessibilityText($r('app.string.toolbar_more_menu'))"), 'toolbar overflow label');
check(!toolbar.includes("accessibilityText($r('app.string.more_tools'))"), 'more_tools label replaced');
check(dlg.includes("accessibilityText($r('app.string.toolbar_more_menu'))"), 'tool ⋯ menu label');

// --- Toolbox settings dialog ✕ announces Close ---
const closeIdx = dlg.indexOf("Button('✕')");
const closeBlock = dlg.slice(closeIdx, dlg.indexOf('onClick', closeIdx));
check(closeBlock.includes("accessibilityText($r('app.string.close'))"), 'dialog close label');

// --- Page indicator announces "N of M" (original page_indicator cd) ---
check(bar.includes("cd_page_indicator"), 'page indicator uses cd_page_indicator');
check(bar.includes('this.currentPageIndex + 1') && bar.includes('this.pageCount'),
  'page indicator passes both format args');

// --- Zoom strip labels (Harmony-side controls, no original cd) ---
check(canvas.includes("$r('app.string.zoom_out')"), 'zoom out label');
check(canvas.includes("$r('app.string.zoom_in')"), 'zoom in label');
check(baseVal('zoom_in')?.length > 0 && baseVal('zoom_out')?.length > 0, 'zoom strings exist');

console.log(`TOTAL=${n}`);
