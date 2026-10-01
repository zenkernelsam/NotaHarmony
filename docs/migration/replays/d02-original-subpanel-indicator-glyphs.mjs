// Phase 1374 — sub-panel disclosure chevrons, the zoom-view drag grip,
// settings/import selected-checks, and the color-picker "+" adopt original
// vectors. The two widget edit badges use an Image+media-SVG of
// ui_designsystem__edit because FormExtensionAbility ArkUI cannot host the
// Shape/Path-based ToolGlyph.
//
// ue4.java chevron_left/right for the share-sheet disclosure/back.  wfg.c
// drag_handle for the zoom-view move grip.  general_check_med_reg for the
// settings/import selected-row check.  plus for the color-well "add" cell.
// te4 arrange-mode up/down maps to chevron_down (rot180 for up) — the original
// exposes move_up/move_down only as a11y actions on a drag-reorder row.
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
const glyphs = readFileSync(join(root, 'note/src/main/ets/ui/components/ToolGlyphs.ets'), 'utf8');
const read = (p) => readFileSync(join(root, p), 'utf8');

const toolbar = read('note/src/main/ets/ui/editor/EditorToolbar.ets');
const zoomView = read('note/src/main/ets/ui/editor/NoteZoomView.ets');
const settings = read('note/src/main/ets/ui/settings/SettingsPage.ets');
const importSheet = read('note/src/main/ets/ui/components/ImportDetailsSheet.ets');
const colorPicker = read('note/src/main/ets/ui/components/ColorPicker.ets');
const folderCard = read('note/src/main/ets/noteformability/pages/FolderNotesCard.ets');
const thumbCard = read('note/src/main/ets/noteformability/pages/NoteThumbnailCard.ets');
const editSvg = read('note/src/main/resources/base/media/edit.svg');

let pass = 0; const fail = [];
const eq = (c, l) => { if (c) { pass++; console.log('ok -', l); } else { fail.push(l); console.log('FAIL -', l); } };

// --- new glyph key ---
eq(glyphs.includes("'drag_handle':"), 'drag_handle registered (wfg.c zoom grip)');

// --- share-sheet disclosure/back chevrons (EditorToolbar) ---
eq((toolbar.match(/glyph: 'chevron_right'/g) || []).length >= 2,
  'share-sheet forward disclosure uses chevron_right (x2)');
eq((toolbar.match(/glyph: 'chevron_left'/g) || []).length >= 2,
  'share-sheet back uses chevron_left (x2)');
eq(!/Text\('›'\)/.test(toolbar) && !/Text\('‹'\)/.test(toolbar),
  'no ›/‹ text chevrons remain in the share sheet');

// --- zoom-view drag grip ---
eq(zoomView.includes("glyph: 'drag_handle'") &&
   zoomView.includes("$r('app.string.zoom_view_move')"),
  'zoom-view move grip uses drag_handle + zoom_view_move a11y');
eq(!/Text\('≡'\)/.test(zoomView), 'no ≡ text grip remains');

// --- settings selected-row checks ---
// Phase 1411：TitlePositionDialog 新增第三处 selected-check（ibb 三态选择器）。
eq((settings.match(/glyph: 'general_check_med_reg'/g) || []).length === 3,
  'settings option rows use general_check_med_reg (x3)');
eq(!/Text\('✓'\)/.test(settings), 'no ✓ text checks remain in settings');

// --- import-sheet arrange arrows + selected check ---
eq((importSheet.match(/glyph: 'chevron_down'/g) || []).length === 2 &&
   importSheet.includes('.rotate({ angle: 180 })'),
  'import arrange uses chevron_down (rot180 for up)');
eq(importSheet.includes("$r('app.string.import_move_up')") &&
   importSheet.includes("$r('app.string.import_move_down')"),
  'import move_up/move_down a11y preserved');
eq(importSheet.includes("glyph: 'general_check_med_reg'"),
  'import selected-note uses general_check_med_reg');
eq(!/Text\('↑'\)|Text\('↓'\)|Text\('✓'\)/.test(importSheet),
  'no ↑/↓/✓ text marks remain in the import sheet');

// --- color-picker add cell ---
eq(colorPicker.includes("glyph: 'plus'") && !/Text\('\+'\)/.test(colorPicker),
  'color-picker add cell uses plus glyph');

// --- widget edit badges use Image+media-SVG (FormCard restriction) ---
eq(editSvg.includes('stroke="#000000"') && editSvg.includes('M17.02,2.23'),
  'edit.svg carries the ui_designsystem__edit vector');
eq(folderCard.includes("$r('app.media.edit')") && !/Text\('✎'\)/.test(folderCard),
  'FolderNotesCard edit badge uses app.media.edit Image');
eq(thumbCard.includes("$r('app.media.edit')") && !/Text\('✎'\)/.test(thumbCard),
  'NoteThumbnailCard edit badge uses app.media.edit Image');

console.log(`\nsubpanel-indicator-glyphs: ${pass}/${pass + fail.length} checks green`);
if (fail.length) { console.log('FAILED:', fail); process.exit(1); }
