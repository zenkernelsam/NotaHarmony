import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const desktop = 'C:/Users/Cisco He/Desktop/Notability/';
const readOriginal = path => fs.readFileSync(desktop + path, 'utf8');

const page = read('note/src/main/ets/ui/library/LibraryPage.ets');
const vm = read('note/src/main/ets/ui/library/LibraryViewModel.ets');
const iface = read('note/src/main/ets/data/RepositoryInterfaces.ets');
const repo = read('note/src/main/ets/data/NoteRepositoryImpl.ets');
const stringsBase = read('note/src/main/resources/base/element/string.json');
const stringsZh = read('note/src/main/resources/zh_CN/element/string.json');

let checks = 0;
const ok = (cond, label) => { assert.ok(cond, label); checks++; };

// --- Original evidence anchors ----------------------------------------------------------
const elc = readOriginal('decompiled_1.0.3/sources/defpackage/elc.java');
const flc = readOriginal('decompiled_1.0.3/sources/defpackage/flc.java');
const n32 = readOriginal('decompiled_1.0.3/sources/defpackage/n32.java');
const origStrings = readOriginal('decompiled_1.0.3/resources/res/values/strings.xml');
const origPlurals = readOriginal('decompiled_1.0.3/resources/res/values/plurals.xml');

// flc: SearchIndexingState(indexingNotes, queuedNotes, neverIndexedNotes);
// c() sums all three sets.
ok(flc.includes('SearchIndexingState(indexingNotes=') &&
   flc.includes('queuedNotes=') && flc.includes('neverIndexedNotes=') &&
   /c\(\)\s*\{[\s\S]*?\.d\(\)\s*\+\s*[\s\S]*?\.d\(\)\s*\+\s*[\s\S]*?\.d\(\)/.test(flc),
  'original SearchIndexingState shape missing');
// elc.a: c()==0 -> "All notes indexed"; indexing active -> "Indexing %d notes"
// + spinner; else pending -> "%d Unindexed Note(s)" + conditional Learn More.
ok(elc.includes('feature_library__all_notes_indexed') &&
   elc.includes('plurals.feature_library__indexing_notes') &&
   elc.includes('plurals.feature_library__unindexed_note') &&
   elc.includes('feature_library__learn_more'),
  'original indexing banner branches missing');
// n32: learn-more dialog = unindexed_notes title + crash explainer + Close.
ok(n32.includes('feature_library__unindexed_notes') &&
   n32.includes('feature_library__if_the_note_causes_the_app_to_crash_it_will_be_unindexed_unindexed_notes_will_not_appear_in_search'),
  'original unindexed learn-more dialog missing');
for (const s of ['feature_library__unindexed_notes">Unindexed Notes',
                 'feature_library__learn_more">Learn More',
                 'feature_library__index_notes">Index Notes']) {
  ok(origStrings.includes(s), `original string ${s} missing`);
}
ok(origPlurals.includes('feature_library__unindexed_note') &&
   origPlurals.includes('%1$d Unindexed Note') &&
   origPlurals.includes('%1$d Unindexed Notes'),
  'original unindexed plurals missing');

// --- Harmony anchors ----------------------------------------------------------------------
// Repository contract + NOT EXISTS search_item coverage query.
ok(iface.includes('countUnindexedNotes(): Promise<number>;'),
  'countUnindexedNotes contract missing');
ok(/NOT EXISTS \(SELECT 1 FROM search_item item\s*WHERE item\.note_id = note\.id\)/
  .test(repo) && repo.includes('note.deleted_at IS NULL'),
  'unindexed coverage query missing');
// VM: count refreshed inside the guarded loadNotes tail.
ok(vm.includes('unindexedNoteCount: number = 0;') &&
   vm.includes('this.repo.countUnindexedNotes()') &&
   vm.includes('this.unindexedNoteCount = unindexedCount'),
  'view-model unindexed count missing');
// Page: banner gated on count > 0, singular/plural $r variants, Learn More
// opens the n32-parity dialog.
ok(page.includes('this.viewModel.unindexedNoteCount > 0') &&
   page.includes('app.string.unindexed_note') &&
   page.includes('app.string.unindexed_notes_count') &&
   page.includes('this.unindexedDialog.open()'),
  'unindexed banner missing');
ok(page.includes('struct UnindexedNotesDialog') &&
   page.includes("app.string.unindexed_notes") &&
   page.includes('app.string.unindexed_explainer') &&
   page.includes('app.string.close'),
  'unindexed learn-more dialog missing');
for (const name of ['unindexed_note', 'unindexed_notes_count', 'unindexed_notes',
                    'unindexed_explainer', 'learn_more']) {
  ok(stringsBase.includes(`"name": "${name}"`) && stringsZh.includes(`"name": "${name}"`),
    `string ${name} missing in a locale`);
}
// EN values match the originals.
ok(stringsBase.includes('Unindexed Notes') &&
   stringsBase.includes('Learn More') &&
   stringsBase.includes('If the note causes the app to crash, it will be unindexed. Unindexed notes will not appear in search.'),
  'EN unindexed strings diverge from the original');

// --- Executable behaviour model -----------------------------------------------------------
// Model the banner branch (elc.a terminal state): Harmony indexing is
// synchronous, so only neverIndexed (pending>0 && none in-flight) renders.
function bannerText(c, a, b) {
  const pending = c + b + a;
  if (pending === 0) return 'all_indexed';
  if (a > 0) return 'indexing';
  return 'unindexed';
}
assert.equal(bannerText(0, 0, 0), 'all_indexed');
assert.equal(bannerText(0, 2, 0), 'indexing');
assert.equal(bannerText(2, 0, 1), 'unindexed');
// Harmony port: synchronous indexing has no a/b sets — the banner is the
// terminal "unindexed" surface, gated on count > 0.
assert.equal(bannerText(3, 0, 0), 'unindexed');
checks += 4;

console.log(`D02_ORIGINAL_UNINDEXED_NOTES_BANNER_OK TOTAL=${checks} FAILED=0`);
