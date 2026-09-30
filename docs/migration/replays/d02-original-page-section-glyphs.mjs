// Phase 1372 — page/section control buttons render original
// ui_designsystem__* vectors instead of unicode placeholders.
//
// ue4.java provider: r=back_arrow t=chevron_right u=close_med_regular
// x=more A=search. add_page/bookmark_tall/plus come straight from the
// design-system set. This phase also adds per-glyph native viewport (vw/vh)
// so non-24 vectors (plus=12×12, search=16×17) scale correctly.
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
const glyphs = readFileSync(join(root, 'note/src/main/ets/ui/components/ToolGlyphs.ets'), 'utf8');
const glyph = readFileSync(join(root, 'note/src/main/ets/ui/components/ToolGlyph.ets'), 'utf8');
const read = (p) => readFileSync(join(root, p), 'utf8');

const pageManagerBar = read('note/src/main/ets/ui/editor/PageManagerBar.ets');
const pageOverview = read('note/src/main/ets/ui/editor/PageOverviewPanel.ets');
const pageSettings = read('note/src/main/ets/ui/components/PageSettingsPanel.ets');
const recording = read('note/src/main/ets/ui/editor/RecordingPanel.ets');
const library = read('note/src/main/ets/ui/library/LibraryPage.ets');

let pass = 0; const fail = [];
const eq = (c, l) => { if (c) { pass++; console.log('ok -', l); } else { fail.push(l); console.log('FAIL -', l); } };

// --- new glyph keys + native viewport plumbing ---
['add_page', 'plus', 'search', 'bookmark_tall_outline', 'bookmark_tall_fill']
  .forEach(k => eq(glyphs.includes(`'${k}':`), `glyph '${k}' registered`));
eq(glyphs.includes('vw: 12') && /'plus':/.test(glyphs), 'plus keeps its 12×12 native viewport');
eq(glyphs.includes('vw: 16') && /'search':/.test(glyphs), 'search keeps its 16×17 native viewport');
eq(/'bookmark_tall_fill': \{ f: `M/.test(glyphs), 'bookmark_tall_fill is a filled icon');
eq(/\.viewPort\(\{[^}]*width: this\.paths\(\)\.vw,\s*height: this\.paths\(\)\.vh/.test(glyph),
  'ToolGlyph viewPort uses the per-glyph native vw×vh');

// --- PageManagerBar ---
eq(/glyph: 'add_page'/.test(pageManagerBar), 'add-page button -> add_page');
eq(/glyph: this\.currentPageBookmarked \? 'bookmark_tall_fill' : 'bookmark_tall_outline'/.test(pageManagerBar),
  'bookmark toggles fill/outline by currentPageBookmarked');
eq(/glyph: 'settings'/.test(pageManagerBar) && /compact/.test(pageManagerBar),
  'compact page-settings button -> settings glyph');
eq(pageManagerBar.includes("accessibilityText($r('app.string.add_page'))"), 'add_page a11y kept');
eq(pageManagerBar.includes("accessibilityText($r('app.string.bookmark_page'))"), 'bookmark a11y kept');
eq(pageManagerBar.includes("accessibilityText($r('app.string.page_settings'))"), 'page_settings a11y kept');
eq(!pageManagerBar.includes("Button('🔖')") && !pageManagerBar.includes("Button('+')"),
  'no leftover 🔖/+ in page manager');

// --- PageOverviewPanel search ---
eq(/glyph: 'search'/.test(pageOverview), 'page-overview search -> search');
eq(pageOverview.includes("accessibilityText($r('app.string.cd_pages_panel_search'))"),
  'search keeps cd_pages_panel_search a11y');
eq(/searchActive \?\s*this\.resolveTokens\(\)\.accent/.test(pageOverview),
  'search icon still tints accent when active');

// --- close buttons -> close_med_regular ---
eq((pageSettings.match(/glyph: 'close_med_regular'/g) || []).length === 2,
  'page settings panel uses close_med_regular x2');
eq(/glyph: 'close_med_regular'/.test(recording), 'recording panel close -> close_med_regular');
eq(recording.includes("accessibilityText($r('app.string.close_recordings'))"),
  'recording close keeps a11y');
eq(/glyph: 'close_med_regular'/.test(library), 'library drawer close -> close_med_regular');

// --- create FAB ---
eq(/glyph: this\.createMenuOpen \? 'close_med_regular' : 'plus'/.test(library),
  'create FAB toggles plus (collapsed) / close (expanded)');
eq(library.includes("accessibilityText($r('app.string.cd_add_note'))"),
  'create FAB keeps cd_add_note a11y');

// no unicode placeholders left in the touched sources
const all = [pageManagerBar, pageOverview, pageSettings, recording, library].join('\n');
['×', '🔖', '🔍'].forEach(ch => eq(!all.includes(`Button('${ch}')`), `no Button('${ch}') left`));

console.log(`\npage-section-glyphs: ${pass}/${pass + fail.length} checks green`);
if (fail.length) { console.log('FAILED:', fail); process.exit(1); }
