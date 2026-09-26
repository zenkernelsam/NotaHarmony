// Phase 809 replay: plurals surface closure + values-file pruning registry.
// Verifies the plurals version delta (+12, zero removals, cluster mapping)
// and the values-file pruning counts registered in evidence.
import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability';
const REPO = 'C:/HarmonyProject/NotaHarmony';

function pluralsXml(v) {
  return readFileSync(
    join(ROOT, `decompiled_${v}/resources/res/values/plurals.xml`), 'utf8');
}
function names(xml) {
  return [...xml.matchAll(/<plurals name="([^"]+)"/g)].map(m => m[1]);
}
function countEntries(v, file, tag) {
  const p = join(ROOT, `decompiled_${v}/resources/res/values/${file}.xml`);
  const xml = readFileSync(p, 'utf8');
  return [...xml.matchAll(new RegExp(`<${tag}[ >]`, 'g'))].length;
}

let pass = 0, fail = 0;
function check(name, ok, detail = '') {
  if (ok) { pass++; console.log(`  ok  ${name}`); }
  else { fail++; console.log(`FAIL  ${name} ${detail}`); }
}

const p103 = names(pluralsXml('1.0.3'));
const p142 = names(pluralsXml('1.4.2'));

check('plurals counts 16 -> 28', p103.length === 16 && p142.length === 28,
  `${p103.length}/${p142.length}`);

const removed = p103.filter(n => !p142.includes(n));
check('zero plurals removed', removed.length === 0, removed.join(','));

const added = p142.filter(n => !p103.includes(n));
check('12 new plurals', added.length === 12, added.join(','));

// New plurals map to registered clusters (prefix-family anchors).
const clusterAnchors = [
  'feature_learn_quiz__', 'feature_library__', 'feature_library_gallery__',
  'feature_note_stickers__', 'feature_paywall__note_limit_offer',
  'ui_learn__flashcards', 'ui_share__gallery',
];
check('all new plurals map to registered clusters',
  added.every(n => clusterAnchors.some(a => n.startsWith(a))),
  added.filter(n => !clusterAnchors.some(a => n.startsWith(a))).join(','));

// Novel semantics pinned: home exam countdown + gallery publish limits.
const xml142 = pluralsXml('1.4.2');
check('home exam countdown plural present',
  /feature_library__home_exam_days_until/.test(xml142) &&
  /In %d day/.test(xml142));
check('gallery publish limit plurals present',
  xml142.includes('ui_share__gallery_characters_remaining') &&
  xml142.includes('ui_share__gallery_tags_remaining'));

// Values-file pruning counts (vendor/Compose prune, no semantics).
check('bools identical (6/6)',
  countEntries('1.0.3', 'bools', 'bool') === 6 &&
  countEntries('1.4.2', 'bools', 'bool') === 6);
check('dimens pruned 245 -> 129',
  countEntries('1.0.3', 'dimens', 'dimen') === 245 &&
  countEntries('1.4.2', 'dimens', 'dimen') === 129);
check('styles pruned 242 -> 37',
  countEntries('1.0.3', 'styles', 'style') === 242 &&
  countEntries('1.4.2', 'styles', 'style') === 37);
check('attrs pruned 1589 -> 400',
  countEntries('1.0.3', 'attrs', 'attr') === 1589 &&
  countEntries('1.4.2', 'attrs', 'attr') === 400);

// Harmony plural pattern: paired _one/_other keys (ArkUI has no plurals type).
const sjson = readFileSync(
  join(REPO, 'note/src/main/resources/base/element/string.json'), 'utf8');
check('Harmony count-string pairs exist',
  sjson.includes('import_files_count_one') &&
  sjson.includes('import_files_count_other') &&
  sjson.includes('note_selected_singular'));

console.log(`\nplurals-surface replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
