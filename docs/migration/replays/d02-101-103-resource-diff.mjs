// Phase 817 replay: 1.0.1 -> 1.0.3 full resource/manifest diff.
// Pins the file-level delta (font family completion, Singular SDK
// onboarding, service-name reshuffle) plus manifest-level additions.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability';

let pass = 0, fail = 0;
function check(name, ok, detail = '') {
  if (ok) { pass++; console.log(`  ok  ${name}`); }
  else { fail++; console.log(`FAIL  ${name} ${detail}`); }
}

function hashTree(dir) {
  const out = new Map();
  const walk = (d) => {
    for (const f of fs.readdirSync(d, { withFileTypes: true })) {
      const p = path.join(d, f.name);
      if (f.isDirectory()) walk(p);
      else out.set(path.relative(dir, p).replaceAll('\\', '/'),
        crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex'));
    }
  };
  walk(dir);
  return out;
}

const a = hashTree(`${ROOT}/decompiled_1.0.1/resources`);
const b = hashTree(`${ROOT}/decompiled_1.0.3/resources`);
const added = [...b.keys()].filter(k => !a.has(k));
const removed = [...a.keys()].filter(k => !b.has(k));
const changed = [...a.keys()].filter(k => b.has(k) && a.get(k) !== b.get(k));

check('file counts 1166 -> 1174', a.size === 1166 && b.size === 1174,
  `${a.size}/${b.size}`);
check('19 added / 11 removed', added.length === 19 && removed.length === 11,
  `+${added.length}/-${removed.length}`);

check('5 brand fonts land in 1.0.3',
  ['res/font/gtamericamono_bold.otf', 'res/font/gtflairebasic_extra.otf',
   'res/font/proximasoft_medium.otf', 'res/font/untitledserif_medium.otf',
   'res/font/untitledserif_regular_italic.otf']
    .every(f => added.includes(f)));
check('Singular SDK kotlin_module arrives in 1.0.3',
  added.some(k => k.includes('Singular-v12.15.0')));
check('play-services-appset prop arrives in 1.0.3',
  added.includes('play-services-appset.properties'));
check('check_tny_bold drawable arrives in 1.0.3',
  added.includes('res/drawable/ui_designsystem__general_check_tny_bold.xml'));
check('all removals are obfuscated META-INF/services names',
  removed.every(k => k.startsWith('META-INF/services/')));

check('exactly 9 same-path content changes', changed.length === 9,
  changed.join(','));

// strings/plurals key deltas
const keys = (v, f) => new Set(
  [...fs.readFileSync(
    `${ROOT}/decompiled_${v}/resources/res/values/${f}.xml`, 'utf8')
    .matchAll(/name="([^"]+)"/g)].map(m => m[1]));
const s1 = keys('1.0.1', 'strings'), s3 = keys('1.0.3', 'strings');
const sAdd = [...s3].filter(k => !s1.has(k));
const sRem = [...s1].filter(k => !s3.has(k));
check('strings +33/-12', sAdd.length === 33 && sRem.length === 12,
  `+${sAdd.length}/-${sRem.length}`);
check('logout sync-status family arrives in 1.0.3',
  ['feature_settings__logout_sync_now', 'feature_settings__logout_syncing',
   'feature_settings__sign_out_countdown',
   'feature_settings__logout_unsynced_title']
    .every(k => sAdd.includes(k)));
check('account-deletion confirm family arrives in 1.0.3',
  sAdd.some(k => k === 'app__account_deletion_notice_title') &&
  sAdd.some(k => k === 'feature_settings__account_deletion_confirm_title'));
const pAdd = [...keys('1.0.3', 'plurals')].filter(k => !keys('1.0.1', 'plurals').has(k));
check('plurals +1 (free_trial_footnote)',
  pAdd.length === 1 && pAdd[0] === 'feature_paywall__free_trial_footnote');

// manifest additions: Singular/Ads permissions, FB/IG queries,
// ExportFileProvider swap.
const mani = v => new Set(
  [...fs.readFileSync(
    `${ROOT}/decompiled_${v}/resources/AndroidManifest.xml`, 'utf8')
    .matchAll(/android:name="([^"]+)"/g)].map(m => m[1]));
const m1 = mani('1.0.1'), m3 = mani('1.0.3');
const mAdd = [...m3].filter(x => !m1.has(x));
const mRem = [...m1].filter(x => !m3.has(x));
check('manifest adds Singular/Ads permissions',
  mAdd.includes('com.google.android.gms.permission.AD_ID') &&
  mAdd.includes('com.singular.preinstall.READ_PERMISSION_SINGULAR'));
check('manifest adds FB/IG share queries',
  mAdd.includes('com.facebook.katana') &&
  mAdd.includes('com.instagram.android'));
check('FileProvider -> ExportFileProvider swap',
  mRem.includes('androidx.core.content.FileProvider') &&
  mAdd.includes('com.gingerlabs.notability.data.library.state.ExportFileProvider'));

console.log(`\n101-103-resource-diff replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
