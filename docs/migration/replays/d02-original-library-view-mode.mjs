import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const desktop = 'C:/Users/Cisco He/Desktop/Notability/';
const readOriginal = path => fs.readFileSync(desktop + path, 'utf8');

const page = read('note/src/main/ets/ui/library/LibraryPage.ets');
const stringsBase = read('note/src/main/resources/base/element/string.json');
const stringsZh = read('note/src/main/resources/zh_CN/element/string.json');

let checks = 0;
const ok = (cond, label) => { assert.ok(cond, label); checks++; };

// --- Original evidence anchors ----------------------------------------------------------
const ie7 = readOriginal('decompiled_1.0.3/sources/defpackage/ie7.java');
const inh = readOriginal('decompiled_1.0.3/sources/defpackage/inh.java');
const zy7 = readOriginal('decompiled_1.0.3/sources/defpackage/zy7.java');
const yj9 = readOriginal('decompiled_1.0.3/sources/defpackage/yj9.java');
const z97 = readOriginal('decompiled_1.0.3/sources/defpackage/z97.java');

// ie7: GRID(0) / LIST(1).
ok(ie7.includes('"GRID", 0') && ie7.includes('"LIST", 1'),
  'original ie7 enum missing');
// inh.d: icon button dispatches the opposite mode.
ok(/ie7\.J;\s*if \(ie7Var == ie7Var2\) \{\s*ie7Var2 = ie7\.I/.test(inh) &&
   inh.includes('ej9(26, ix4Var, ie7Var2)'),
  'original view-mode toggle dispatch missing');
// zy7 case 20: the icon depicts the TARGET mode (grid_view vs list_bullet).
ok(zy7.includes('feature_library__grid_view') &&
   zy7.includes('feature_library__list_bullet'),
  'original view-mode icons missing');
// z97 persists ie7 with GRID default.
ok(z97.includes('"GRID"') && z97.includes('ie7.valueOf'),
  'original view-mode pref missing');
// yj9 picks b5j.b (grid card) vs m5j.b (list row) per ie7.ordinal().
ok(yj9.includes('b5j.b(') && yj9.includes('m5j.b(') &&
   yj9.includes('ie7Var.ordinal()'),
  'original grid/list render split missing');

// --- Harmony anchors ----------------------------------------------------------------------
// Page state + pref key + restore (default GRID).
ok(page.includes('@State listView: boolean = false;') &&
   page.includes("PREF_VIEW_MODE_KEY: string = 'library_view_mode'") &&
   page.includes('(pref.getSync(this.PREF_VIEW_MODE_KEY, 0) as number) === 1'),
  'view-mode state/pref missing');
// Guarded toggle persists the mode.
ok(/private toggleViewMode\(\): void \{\s*if \(!this\.pageActive\) \{\s*return;/.test(page) &&
   page.includes('pref.putSync(this.PREF_VIEW_MODE_KEY, listView ? 1 : 0)'),
  'view-mode toggle persistence missing');
// Header button shows the TARGET mode icon (inh.d/zy7 parity).
ok(page.includes("Button(this.listView ? '⊞' : '☰')") &&
   page.includes('this.toggleViewMode();'),
  'view-mode toggle button missing');
// Content split: List of NoteListRow vs Grid of NoteCard.
ok(/if \(this\.listView\) \{\s*List\(\) \{[\s\S]*?this\.NoteListRow\(note\)[\s\S]*?\} else \{\s*Grid\(\) \{[\s\S]*?this\.NoteCard\(note\)/.test(page),
  'grid/list content split missing');
// List row: thumbnail box + title/date/chip column + same interactions.
ok(/NoteListRow\(note: NoteMeta\) \{[\s\S]*?this\.NoteContextMenu\(note\)[\s\S]*?pushUrl\(\{ url: 'ui\/editor\/NotePage'/.test(page),
  'list row interactions missing');
// Compact menu carries a view toggle entry.
ok(page.includes("this.listView ? $r('app.string.grid_view') : $r('app.string.list_view')"),
  'compact view-mode entry missing');
for (const name of ['grid_view', 'list_view']) {
  ok(stringsBase.includes(`"name": "${name}"`) && stringsZh.includes(`"name": "${name}"`),
    `string ${name} missing in a locale`);
}

console.log(`D02_ORIGINAL_LIBRARY_VIEW_MODE_OK TOTAL=${checks} FAILED=0`);
