// Phase 1373 — status/indicator marks render original ui_designsystem__*
// vectors instead of unicode/emoji placeholders (✓ ♥ 🎙 🔖 ⋯ < >).
//
// o94.java select-circle: selected=ui_designsystem__checkmark_circle,
// unselected=ui_designsystem__circle_empty_med_outline.  b41/o94 folder row
// check = ui_designsystem__general_check_med_reg.  note-card badges use
// ui_designsystem__favorite_fill / w09.l record_mic_outline.  md.java page
// bookmark = bookmark_tall_fill.  cell overflow = ui_designsystem__more.
// ue4 page nav = chevron_left / chevron_right.
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
const glyphs = readFileSync(join(root, 'note/src/main/ets/ui/components/ToolGlyphs.ets'), 'utf8');
const read = (p) => readFileSync(join(root, p), 'utf8');

const library = read('note/src/main/ets/ui/library/LibraryPage.ets');
const pageManagerBar = read('note/src/main/ets/ui/editor/PageManagerBar.ets');
const pageOverview = read('note/src/main/ets/ui/editor/PageOverviewPanel.ets');
const toolbar = read('note/src/main/ets/ui/editor/EditorToolbar.ets');

let pass = 0; const fail = [];
const eq = (c, l) => { if (c) { pass++; console.log('ok -', l); } else { fail.push(l); console.log('FAIL -', l); } };

// --- indicator glyph keys registered ---
['favorite_fill', 'record_mic_outline', 'record_mic_fill', 'general_check_med_reg',
 'check_tiny_bold', 'edit', 'checkmark_circle', 'circle_empty_med_outline',
 'bookmark_tall_fill']
  .forEach(k => eq(glyphs.includes(`'${k}':`), `glyph '${k}' registered`));

// --- note-card badges (LibraryPage) ---
eq(/ToolGlyph\(\{\s*\n\s*glyph: 'favorite_fill'/.test(library),
  'note-card favorite badge uses favorite_fill');
eq(/glyph: 'record_mic_outline'/.test(library),
  'note-card mic badge uses record_mic_outline (w09.l)');
eq(!/Text\('♥'\)/.test(library) && !/Text\('🎙'\)/.test(library),
  'no ♥/🎙 emoji badges remain on note cards');

// --- folder/section selected check (general_check_med_reg) ---
eq(library.match(/glyph: 'general_check_med_reg'/g).length >= 2,
  'folder + section selected rows use general_check_med_reg');
eq(!/Text\('✓'\)/.test(library), 'no ✓ text checkmarks remain in LibraryPage');

// --- o94 multi-select select-circles ---
eq(library.includes("glyph: 'checkmark_circle'") &&
   library.includes("glyph: 'circle_empty_med_outline'"),
  'LibraryPage SelectCircle uses checkmark_circle / circle_empty_med_outline');
eq(toolbar.includes("this.checked ? 'checkmark_circle' : 'circle_empty_med_outline'"),
  'EditorToolbar select-circle uses the o94 glyph pair');
eq(pageOverview.includes("this.checked ? 'checkmark_circle' : 'circle_empty_med_outline'"),
  'PageOverviewPanel select-circle uses the o94 glyph pair');

// --- page bookmark (bookmark_tall_fill) ---
eq(pageManagerBar.includes("glyph: 'bookmark_tall_fill'"),
  'PageManagerBar page indicator uses bookmark_tall_fill');
eq(pageOverview.includes("glyph: 'bookmark_tall_fill'"),
  'PageOverviewPanel bookmark badge uses bookmark_tall_fill');
eq(!/Text\('🔖'\)/.test(pageManagerBar) && !/Text\('🔖'\)/.test(pageOverview),
  'no 🔖 emoji bookmarks remain');

// --- cell overflow + page nav chevrons ---
eq(library.includes("glyph: 'more'") && !/Text\('⋯'\)/.test(library),
  'NoteMenuButton overflow uses more glyph');
eq(pageManagerBar.includes("previous ? 'chevron_left' : 'chevron_right'"),
  'NavigationButton uses chevron_left/right');
eq(!/Button\('<'\)|Button\('>'\)/.test(pageManagerBar),
  'no </> text nav buttons remain');

// --- a11y labels preserved on the swapped indicators ---
eq(library.includes("$r('app.string.folder_selected')"),
  'folder_selected a11y preserved');
eq(library.includes("$r('app.string.select_note')"),
  'select_note a11y preserved');
eq(library.includes("$r('app.string.note_actions')"),
  'note_actions a11y preserved');
eq(pageManagerBar.includes("$r('app.string.bookmark_page')"),
  'bookmark_page a11y preserved');
eq(pageManagerBar.includes("$r('app.string.previous_page')") &&
   pageManagerBar.includes("$r('app.string.next_page')"),
  'previous/next page a11y preserved');

console.log(`\nstatus-indicator-glyphs: ${pass}/${pass + fail.length} checks green`);
if (fail.length) { console.log('FAILED:', fail); process.exit(1); }
