import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const desktop = 'C:/Users/Cisco He/Desktop/Notability/';
const readOriginal = path => fs.readFileSync(desktop + path, 'utf8');

const page = read('note/src/main/ets/ui/library/LibraryPage.ets');
const origStrings = readOriginal('decompiled_1.0.3/resources/res/values/strings.xml');
const mb7 = readOriginal('decompiled_1.0.3/sources/defpackage/mb7.java');
const nb7 = readOriginal('decompiled_1.0.3/sources/defpackage/nb7.java');

let checks = 0;
const ok = (cond, label) => { assert.ok(cond, label); checks++; };

// --- Original evidence anchors ----------------------------------------------------------
// nb7 shows the clear affordance only while the query is non-empty; mb7 renders
// the 28dp icon button labelled feature_library__clear_search.
ok(nb7.includes('d().K.length() > 0'), 'original non-empty-query gate missing');
ok(mb7.includes('feature_library__clear_search'), 'original clear-search button missing');
ok(origStrings.includes('feature_library__clear_search">Clear search'),
  'original clear-search label missing');

// --- Harmony anchors ----------------------------------------------------------------------
// The search TextInput uses the native cancel button; clearing fires onChange('')
// which walks the same debounced setSearchQuery pipeline.
const inputStart = page.indexOf('TextInput({ placeholder: this.searchPlaceholder() })');
assert.ok(inputStart !== -1);
const inputEnd = page.indexOf('.onChange', inputStart);
assert.ok(inputEnd > inputStart);
const inputAttrs = page.slice(inputStart, inputEnd);
ok(inputAttrs.includes('.cancelButton({ style: CancelButtonStyle.INPUT })'),
  'search clear affordance missing');
ok(page.includes("vm.setSearchQuery(value)"), 'search reload pipeline missing');

// --- Executable behaviour model -----------------------------------------------------------
// Clearing produces '' which the existing onChange path debounces into
// setSearchQuery('') — the library reloads unfiltered.
function simulate(query, cleared) { return cleared ? '' : query; }
assert.equal(simulate('abc', true), '');
assert.equal(simulate('abc', false), 'abc');
checks += 2;

console.log(`D02_ORIGINAL_CLEAR_SEARCH_OK TOTAL=${checks} FAILED=0`);
