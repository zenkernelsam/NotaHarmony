// Phase 821 — public.xml public-resource diff + string-removal audit
// 1. public.xml delta: -1844/+914 entries
// 2. attr/style/dimen removals are vendor pruning
// 3. 107 removed strings decompose: 17 re-keyed + vendor + app-level
// 4. convert_to_math / fit_to_page = real feature removals
// 5. Harmony correctly absent on removed keys
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const REF = 'C:/Users/Cisco He/Desktop/Notability';
const REPO = 'C:/HarmonyProject/NotaHarmony';
let pass = 0, fail = 0;
const ok = (name, cond, detail = '') => {
  if (cond) { pass++; console.log(`  ok ${name}`); }
  else { fail++; console.log(`  FAIL ${name} ${detail}`); }
};

const parse = t => {
  const m = new Set();
  for (const mm of t.matchAll(/type="(\w+)" name="([^"]+)"/g)) m.add(mm[1] + '/' + mm[2]);
  return m;
};
const pub103 = parse(readFileSync(join(REF, 'decompiled_1.0.3/resources/res/values/public.xml'), 'utf8'));
const pub142 = parse(readFileSync(join(REF, 'decompiled_1.4.2/resources/res/values/public.xml'), 'utf8'));
const rm = [...pub103].filter(x => !pub142.has(x));
const add = [...pub142].filter(x => !pub103.has(x));

// -- 1. totals --------------------------------------------------------------
ok('public.xml -1844/+914', rm.length === 1844 && add.length === 914,
  `-${rm.length}/+${add.length}`);
const byType = {};
for (const x of rm) { const t = x.split('/')[0]; byType[t] = (byType[t] || 0) + 1; }
ok('attr removals = 1200 (vendor prune)', byType.attr === 1200, `attr=${byType.attr}`);
ok('style removals = 215', byType.style === 215, `style=${byType.style}`);
ok('string removals = 107', byType.string === 107, `string=${byType.string}`);

// -- 3. string-removal decomposition -----------------------------------------
const s142 = readFileSync(join(REF, 'decompiled_1.4.2/resources/res/values/strings.xml'), 'utf8');
const keys142 = new Set([...s142.matchAll(/name="([^"]+)"/g)].map(m => m[1]));
const rmStrings = rm.filter(x => x.startsWith('string/')).map(x => x.split('/')[1]);
let rekeyed = 0, vendor = 0, appDel = [];
for (const n of rmStrings) {
  if (/^(abc_|mtrl_|material_|exo_|bottomsheet|character_counter|path_password|password_toggle|clear_text_|error_icon_|exposed_dropdown|side_sheet|default_web_client|google_crash)/.test(n)) { vendor++; continue; }
  const suf = n.replace(/^(feature_|ui_)[a-z_]+__/, '');
  if ([...keys142].some(k => k.endsWith('__' + suf) || k === suf)) rekeyed++;
  else appDel.push(n);
}
ok('17 strings re-keyed', rekeyed === 17, `got ${rekeyed}`);
ok('vendor string deletions >= 60', vendor >= 60, `got ${vendor}`);
ok('app-level true deletions 20-30', appDel.length >= 20 && appDel.length <= 30,
  `got ${appDel.length}`);

// -- 4. drawable icon prune (strings survive = code-vector migration) -------------
const rmDraw = rm.filter(x => x.startsWith('drawable/'));
ok('convert_to_math/fit_to_page drawable pruned',
  rmDraw.includes('drawable/feature_note__selection_menu_convert_to_math')
    && rmDraw.includes('drawable/feature_note__selection_menu_fit_to_page'));
ok('icon strings survive in 1.4.2 (code-vector migration)',
  keys142.has('feature_note__selection_menu_convert_to_math')
    && keys142.has('feature_note__selection_menu_fit_to_page'));
ok('logout sync-warning family deleted',
  appDel.filter(n => n.startsWith('feature_settings__logout_')).length >= 8);

// -- 5. Harmony absence ----------------------------------------------------------
const hz = JSON.parse(readFileSync(join(REPO, 'note/src/main/resources/base/element/string.json'), 'utf8')).string;
const hkeys = new Set(hz.map(s => s.name));
const absent = ['convert_to_math', 'fit_to_page', 'hwr_toggle_description',
  'learn_toggle_description', 'toprighttoolbar_undo_action', 'logout_syncing'];
ok('Harmony absent on all 1.4.2-deleted keys',
  absent.every(k => ![...hkeys].some(h => h.includes(k))));

console.log(`\n${pass}/${pass + fail} checks passed`);
process.exit(fail ? 1 : 0);
