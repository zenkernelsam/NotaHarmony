// Phase 819 — runtime prefs inventory + identity label fix + zh placeholder parity
// 1. Original SharedPreferences inventory: 3 app + 13 vendor names
// 2. 4 proto-DataStore initializers exist in all 3 versions
// 3. Harmony identity labels fixed (no scaffold values); zh_CN covers them
// 4. zh_CN placeholder parity = 0 mismatches on shared keys
// 5. Harmony prefs layer (EditorSettingsStore) exists
import { readFileSync, existsSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

const REF = 'C:/Users/Cisco He/Desktop/Notability';
const REPO = 'C:/HarmonyProject/NotaHarmony';
let pass = 0, fail = 0;
const ok = (name, cond, detail = '') => {
  if (cond) { pass++; console.log(`  ok ${name}`); }
  else { fail++; console.log(`  FAIL ${name} ${detail}`); }
};

// -- 1. SharedPreferences inventory ----------------------------------------
const src142 = join(REF, 'decompiled_1.4.2/sources');
const files = [];
(function walk(d) {
  for (const e of readdirSync(d, { withFileTypes: true })) {
    const p = join(d, e.name);
    if (e.isDirectory()) walk(p);
    else if (e.name.endsWith('.java')) files.push(p);
  }
})(src142);
const names = new Set();
const rx = /getSharedPreferences\("([^"]+)"/g;
for (const f of files) {
  const t = readFileSync(f, 'utf8');
  for (const m of t.matchAll(rx)) names.add(m[1]);
}
ok('original SharedPreferences inventory = 16 files', names.size === 16, `got ${names.size}`);
const APP = ['backend_override', 'search_engine', 'widget_bindings'];
ok('3 app-level prefs files', APP.every(n => names.has(n)),
  APP.filter(n => !names.has(n)).join(','));
const VENDOR = ['FirebasePerfSharedPrefs', 'androidx.work.util.id', 'androidx.work.util.preferences',
  'app_set_id_storage', 'app_update', 'com.google.android.gms.measurement.prefs',
  'com.google.android.gms.signin', 'com.google.firebase.common.prefs:',
  'com.google.firebase.crashlytics', 'com.google.mlkit.internal', 'frc_',
  'google.analytics.deferred.deeplink.prefs', 'opentelemetry-android'];
ok('13 vendor prefs files', VENDOR.every(n => names.has(n)),
  VENDOR.filter(n => !names.has(n)).join(','));

// -- 2. proto-DataStore initializers across versions ------------------------
const INITS = [
  'core/user/UserDataStoreInitializer.java',
  'data/theme/ThemeDataStoreInitializer.java',
  'data/settings/NoteEditorSettingsInitializer.java',
  'data/stylus/haptic/HapticPreferencesInitializer.java',
];
for (const v of ['1.0.1', '1.0.3', '1.4.2']) {
  ok(`4 DataStore initializers present in ${v}`,
    INITS.every(f => existsSync(join(REF, `decompiled_${v}/sources/com/gingerlabs/notability/${f}`))));
}

// -- 3. Harmony identity labels ---------------------------------------------
const base = JSON.parse(readFileSync(join(REPO, 'note/src/main/resources/base/element/string.json'), 'utf8')).string;
const bmap = new Map(base.map(s => [s.name, s.value]));
const SCAFFOLD = new Set(['label', 'description', 'module description']);
ok('no scaffold identity labels remain',
  !SCAFFOLD.has(bmap.get('module_desc')) && !SCAFFOLD.has(bmap.get('NoteAbility_desc'))
    && !SCAFFOLD.has(bmap.get('NoteAbility_label')),
  `${bmap.get('module_desc')}|${bmap.get('NoteAbility_desc')}|${bmap.get('NoteAbility_label')}`);
ok('NoteAbility_label matches app branding', bmap.get('NoteAbility_label') === 'NotaHarmony',
  bmap.get('NoteAbility_label'));
const zh = JSON.parse(readFileSync(join(REPO, 'note/src/main/resources/zh_CN/element/string.json'), 'utf8')).string;
const zmap = new Map(zh.map(s => [s.name, s.value]));
ok('zh_CN covers the 3 identity keys',
  zmap.has('module_desc') && zmap.has('NoteAbility_desc') && zmap.has('NoteAbility_label'));

// -- 4. zh_CN placeholder parity ---------------------------------------------
const ph = s => (s.match(/%(\d+\$)?[sdfl@]/g) || []).sort().join(',');
let phBad = 0;
const phBadKeys = [];
for (const [k, v] of bmap) {
  if (!zmap.has(k)) continue;
  if (ph(v) !== ph(zmap.get(k))) { phBad++; phBadKeys.push(k); }
}
ok('zh_CN placeholder parity 0 mismatches', phBad === 0, phBadKeys.slice(0, 8).join(','));

// -- 5. Harmony prefs layer ---------------------------------------------------
const ess = readFileSync(join(REPO, 'note/src/main/ets/data/EditorSettingsStore.ets'), 'utf8');
ok('Harmony noteEditorSettings prefs store exists',
  ess.includes("STORE_NAME: string = 'noteEditorSettings'") && ess.includes('preferences.getPreferences'));

console.log(`\n${pass}/${pass + fail} checks passed`);
process.exit(fail ? 1 : 0);
