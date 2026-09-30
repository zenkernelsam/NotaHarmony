// Phase 1371 — navigation / dialog / overflow buttons render original
// ui_designsystem__* vectors instead of unicode placeholders.
//
// ue4.java is the original icon provider: r()=back_arrow, t()=chevron_right,
// u()=close_med_regular, x()=more. d32.java uses chevron_left for "previous".
// All are go5.b single-tint strokes except `more` (three filled dots).
// ToolboxSettingsDialog ▲/▼ are a Harmony reorder affordance (original uses
// ui_designsystem__drag_handle); ▲ reuses chevron_down rotated 180°.
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
const glyphs = readFileSync(join(root, 'note/src/main/ets/ui/components/ToolGlyphs.ets'), 'utf8');
const read = (p) => readFileSync(join(root, p), 'utf8');

const toolboxDlg = read('note/src/main/ets/ui/editor/ToolboxSettingsDialog.ets');
const pageOverview = read('note/src/main/ets/ui/editor/PageOverviewPanel.ets');
const pageManagerBar = read('note/src/main/ets/ui/editor/PageManagerBar.ets');
const notePage = read('note/src/main/ets/ui/editor/NotePage.ets');
const tapePicker = read('note/src/main/ets/ui/editor/TapePatternPicker.ets');
const pageSettings = read('note/src/main/ets/ui/components/PageSettingsPanel.ets');
const settings = read('note/src/main/ets/ui/settings/SettingsPage.ets');
const webdav = read('note/src/main/ets/ui/settings/WebDAVSettingsPage.ets');
const recentDel = read('note/src/main/ets/ui/settings/RecentlyDeletedPage.ets');
const defTpl = read('note/src/main/ets/ui/settings/DefaultTemplatePage.ets');
const backup = read('note/src/main/ets/ui/settings/BackupPage.ets');
const library = read('note/src/main/ets/ui/library/LibraryPage.ets');

let pass = 0; const fail = [];
const eq = (c, l) => { if (c) { pass++; console.log('ok -', l); } else { fail.push(l); console.log('FAIL -', l); } };

// --- nav glyph keys registered ---
['back_arrow', 'chevron_left', 'chevron_right', 'chevron_down',
  'close_med_regular', 'close_med_bold', 'more']
  .forEach(k => eq(glyphs.includes(`'${k}':`), `nav glyph '${k}' registered`));
// more is the three filled dots -> fill slot; the strokes go in the o slot.
eq(/'more': \{ f: `M/.test(glyphs), 'more dots render in the fill slot');
eq(/'back_arrow': \{ f: ``, o: `M/.test(glyphs), 'back_arrow is a stroke icon');

// --- ToolboxSettingsDialog ---
eq(/glyph: 'close_med_regular'/.test(toolboxDlg), 'toolbox dialog close -> close_med_regular');
eq((toolboxDlg.match(/glyph: 'chevron_down'/g) || []).length === 2,
  'toolbox move up/down reuse chevron_down');
eq(/\.rotate\(\{ angle: 180 \}\)/.test(toolboxDlg), 'move-up chevron rotated 180°');
eq(/glyph: 'more'/.test(toolboxDlg), 'toolbox per-tool overflow -> more');
eq(toolboxDlg.includes("accessibilityText($r('app.string.close'))"), 'close keeps close a11y');
eq(toolboxDlg.includes("accessibilityText($r('app.string.move_tool_up'))"), 'move-up a11y kept');
eq(toolboxDlg.includes("accessibilityText($r('app.string.move_tool_down'))"), 'move-down a11y kept');

// --- editor panels ---
eq(/glyph: 'close_med_regular'/.test(pageOverview), 'page overview close -> close_med_regular');
eq(/glyph: 'more'/.test(pageManagerBar), 'page manager overflow -> more');
eq(/glyph: 'more'/.test(notePage), 'note editor options menu -> more');
eq(/glyph: 'chevron_left'/.test(tapePicker), 'tape picker back -> chevron_left');
eq(/glyph: 'more'/.test(pageSettings), 'page template spacing overflow -> more');

// --- settings back buttons -> back_arrow ---
[['settings', settings], ['webdav', webdav], ['recentlyDeleted', recentDel],
  ['defaultTemplate', defTpl], ['backup', backup]]
  .forEach(([n, src]) => {
    eq(/glyph: 'back_arrow'/.test(src), `${n} back button -> back_arrow`);
    eq(!src.includes("Button('<')"), `${n} no leftover Button('<')`);
    eq(src.includes("accessibilityText($r('app.string.back'))"), `${n} keeps back a11y`);
  });

// --- library overflow/drawer ---
eq((library.match(/glyph: 'more'/g) || []).length === 4,
  'library folder/library/cell-menu action overflow -> more (x4)');
eq(/glyph: 'hamburger'/.test(library), 'compact folder drawer -> hamburger');
eq(!library.includes("Button('...')"), 'library no leftover Button(\'...\')');
eq(!library.includes("Button('☰')"), 'library no leftover Button(\'☰\')');

// no unicode placeholders remain anywhere in the touched sources
const all = [toolboxDlg, pageOverview, pageManagerBar, notePage, tapePicker,
  pageSettings, settings, webdav, recentDel, defTpl, backup, library].join('\n');
['✕', '▲', '▼', '⋯', '‹', '☰'].forEach(ch =>
  eq(!all.includes(`Button('${ch}')`), `no Button('${ch}') placeholder left`));

console.log(`\nnav-action-glyphs: ${pass}/${pass + fail.length} checks green`);
if (fail.length) { console.log('FAILED:', fail); process.exit(1); }
