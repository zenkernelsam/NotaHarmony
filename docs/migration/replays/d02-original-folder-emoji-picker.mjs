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
const du3 = readOriginal('decompiled_1.0.3/sources/defpackage/du3.java');
const hq4 = readOriginal('decompiled_1.0.3/sources/defpackage/hq4.java');
const wm2 = readOriginal('decompiled_1.0.3/sources/defpackage/wm2.java');
const gaj = readOriginal('decompiled_1.0.3/sources/defpackage/gaj.java');
const q31 = readOriginal('decompiled_1.0.3/sources/defpackage/q31.java');
const md = readOriginal('decompiled_1.0.3/sources/defpackage/md.java');
const ru3 = readOriginal('decompiled_1.0.3/sources/defpackage/ru3.java');
const ac4 = readOriginal('decompiled_1.0.3/sources/defpackage/ac4.java');
const origStrings = readOriginal('decompiled_1.0.3/resources/res/values/strings.xml');

// du3: the nine emoji categories in original order.
for (const cat of ['Smileys', 'PeopleBody', 'AnimalsNature', 'FoodDrink', 'Activities',
  'Objects', 'TravelPlaces', 'Symbols', 'Flags']) {
  ok(du3.includes(cat + '(R.string.ui_emojipicker__category_'),
    `original emoji category ${cat} missing`);
}
// hq4: decoration enum Color | Emoji.
ok(hq4.includes('Color(R.string.ui_folder__decoration_color)') &&
   hq4.includes('Emoji(R.string.ui_folder__decoration_emoji)'),
  'original decoration Color|Emoji enum missing');
// wm2 case 0: switching to the Color tab clears the emoji (exclusive decoration).
ok(/hq4Var == hq4\.Color\)\s*\{\s*gl8Var2\.setValue\(null\)/.test(wm2) &&
   wm2.includes('gl8Var.setValue(hq4Var)'),
  'original Color-tab-clears-emoji semantics missing');
// gaj: initial tab = Emoji iff the flag is on and an emoji is already set;
// tab row renders only under the flag; content switches on ordinal.
ok(gaj.includes('hq4.Color : hq4.Emoji') && /getValue\(\)\)\.ordinal\(\)/.test(gaj),
  'original decoration tab selection semantics missing');
// q31: the tab row iterates hq4.M (Color, Emoji).
ok(q31.includes('nz3 nz3Var = hq4.M'), 'original decoration tab row missing');
// md: category strip icons come from ui_designsystem__emojis_* drawables.
for (const icon of ['emojis_smiley', 'emojis_pawprint', 'emojis_food',
  'emojis_basketball', 'emojis_lightbulb', 'emojis_car', 'emojis_numbers', 'emojis_flag']) {
  ok(md.includes('ui_designsystem__' + icon), `original category icon ${icon} missing`);
}
// ru3: emoji data is a bundled Realm EmojiInfo model (not recoverable source).
ok(ru3.includes('com.gingerlabs.notability.ui.emojipicker.EmojiInfo') &&
   ru3.includes('"emoji"'),
  'original EmojiInfo store anchor missing');
ok(ac4.includes('LIBRARY_FOLDER_EMOJI_PICKER'), 'original emoji picker flag missing');
ok(origStrings.includes('ui_emojipicker__category_smileys') &&
   origStrings.includes('ui_folder__decoration_color') &&
   origStrings.includes('ui_folder__decoration_emoji'),
  'original decoration/category strings missing');

// --- Harmony anchors ---------------------------------------------------------------------
// Categorized data in du3 order (curated subset — original Realm data unrecoverable).
ok(page.includes('const FOLDER_EMOJI_CATEGORIES: string[][]') &&
   page.includes('const FOLDER_EMOJI_CATEGORY_ICONS: string[]'),
  'categorized emoji data missing');
{
  const categories = page.match(/FOLDER_EMOJI_CATEGORIES: string\[\]\[\] = \[([\s\S]*?)\];/);
  assert.ok(categories !== null, 'category table not found');
  const rows = categories[1].match(/\[(.*?)\]/g);
  assert.equal(rows.length, 9, 'must have exactly nine du3-order categories');
  checks++;
}
// hq4 tab state + gaj initial-tab semantics (emoji set -> Emoji tab).
ok(page.includes('@State decorationTab: number = 0') &&
   page.includes("this.decorationTab = this.initialEmoji.length > 0 ? 1 : 0"),
  'decoration tab state/initial semantics missing');
// wm2: switching to Color clears the emoji.
ok(/tab === 0[\s\S]{0,80}this\.selectedEmoji = ''/.test(page),
  'Color-tab-clears-emoji parity missing');
// Tab labels + category strip + grid.
ok(page.includes("decorationTabButton(0, $r('app.string.decoration_color'))") &&
   page.includes("decorationTabButton(1, $r('app.string.decoration_emoji'))") &&
   page.includes('ForEach(FOLDER_EMOJI_CATEGORY_ICONS') &&
   page.includes('ForEach(FOLDER_EMOJI_CATEGORIES[this.emojiCategory]'),
  'decoration tabs / category strip / grid missing');
// Row precedence: emoji when set, else the color dot (exclusive decoration).
ok(/if \(item\.folder\.emoji !== null\)[\s\S]*?else \{\s*Circle\(\)[\s\S]*?\.fill\(item\.folder\.color\)/.test(page),
  'folder row emoji-over-color precedence missing');
// Strings in both locales.
for (const name of ['decoration_color', 'decoration_emoji',
  'emoji_category_0', 'emoji_category_8']) {
  ok(stringsBase.includes(`"name": "${name}"`) && stringsZh.includes(`"name": "${name}"`),
    `string ${name} missing in a locale`);
}
// Confirm path unchanged.
ok(page.includes('this.onConfirm(this.inputText, this.selectedColor, this.selectedEmoji)'),
  'dialog confirm must still return color/emoji');

// --- Executable model: wm2 exclusive-decoration semantics ----------------------------------
function switchTab(state, tab) {
  const next = { ...state, tab };
  if (tab === 0) { next.emoji = null; }
  return next;
}
let s = { tab: 0, color: -7431250, emoji: null };
s = switchTab(s, 1);            // pick Emoji tab
assert.equal(s.emoji, null); checks++;
s.emoji = '⭐';                 // pick an emoji in the grid
s = switchTab(s, 0);            // switch to Color -> emoji cleared
assert.equal(s.emoji, null); checks++;
s = switchTab(s, 1);
assert.equal(s.emoji, null); checks++;
// Emoji-tab switch never clears color.
assert.equal(s.color, -7431250); checks++;

console.log(`D02_ORIGINAL_FOLDER_EMOJI_PICKER_OK TOTAL=${checks} FAILED=0`);
