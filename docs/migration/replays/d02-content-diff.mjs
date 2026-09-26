// Phase 812 replay: same-name resource content diffs (key-value edits).
// Pins the 11 changed shared string values, the monochrome-icon single-
// source refactor, and Harmony's post-fix parity with 1.4.2 copy.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability';
const REPO = 'C:/HarmonyProject/NotaHarmony';

let pass = 0, fail = 0;
function check(name, ok, detail = '') {
  if (ok) { pass++; console.log(`  ok  ${name}`); }
  else { fail++; console.log(`FAIL  ${name} ${detail}`); }
}

function strmap(v) {
  const txt = fs.readFileSync(
    `${ROOT}/decompiled_${v}/resources/res/values/strings.xml`, 'utf8');
  const m = new Map();
  for (const [, k, val] of txt.matchAll(
    /<string name="([^"]+)"[^>]*>([\s\S]*?)<\/string>/g)) m.set(k, val);
  return m;
}
const a = strmap('1.0.3'), b = strmap('1.4.2');
const shared = [...a.keys()].filter(k => b.has(k));
const changed = shared.filter(k => a.get(k) !== b.get(k));

check('1396 shared string keys', shared.length === 1396, shared.length);
check('exactly 11 changed shared values', changed.length === 11,
  changed.join(','));

const copyEdits = {
  'feature_library__copy_note_id': ['Copy note ID', 'Copy Note ID'],
  'feature_library__show_in_folder': ['Show in folder', 'Show in Folder'],
  'feature_note_toolbox__add_files': ['Add Files', 'From your files'],
  'feature_note_toolbox__add_gif': ['Add GIF', 'Giphy'],
  'feature_note_toolbox__add_photo': ['Add Photo', 'From your photos'],
  'feature_note_toolbox__insert_math': ['Insert Math', 'Math (LaTeX)'],
  'feature_note_toolbox__take_photo': ['Take Photo', 'Take a photo'],
  'ui_designsystem__theme_match_system': ['Match system', 'System'],
};
for (const [k, [v1, v2]] of Object.entries(copyEdits)) {
  check(`${k} copy edit ${v1} -> ${v2}`,
    a.get(k) === v1 && b.get(k) === v2,
    `${a.get(k)} -> ${b.get(k)}`);
}
check('billing error copy expanded in 1.4.2',
  b.get('feature_paywall__error_purchase_billing_unavailable')
    ?.includes('Google Play'));

// Monochrome icon: 1.4.2 sources pathData from a shared string.
const mono142 = fs.readFileSync(
  `${ROOT}/decompiled_1.4.2/resources/res/drawable/ic_launcher_monochrome.xml`,
  'utf8');
check('1.4.2 monochrome icon references ui_designsystem__app_mark_path',
  mono142.includes('@string/ui_designsystem__app_mark_path'));
check('app_mark_path string carries the app-mark vector path',
  b.get('ui_designsystem__app_mark_path')?.startsWith('M33.19,72.47'));
const mono103 = fs.readFileSync(
  `${ROOT}/decompiled_1.0.3/resources/res/drawable/ic_launcher_monochrome.xml`,
  'utf8');
check('1.0.3 monochrome icon inlined the path (no string ref)',
  !mono103.includes('@string/') && mono103.length > 800);

// Harmony post-fix parity with 1.4.2 copy.
const hbase = fs.readFileSync(
  `${REPO}/note/src/main/resources/base/element/string.json`, 'utf8');
const hzh = fs.readFileSync(
  `${REPO}/note/src/main/resources/zh_CN/element/string.json`, 'utf8');
for (const [k, v] of [
  ['show_in_folder', 'Show in Folder'],
  ['copy_note_id', 'Copy Note ID'],
  ['take_photo', 'Take a photo'],
  ['insert_math', 'Math (LaTeX)'],
]) {
  check(`Harmony ${k} = 1.4.2 copy`,
    new RegExp(`"name":\\s*"${k}",\\s*"value":\\s*"${
      v.replace(/[()]/g, '\\$&')}"`).test(hbase));
}
check('Harmony zh insert_math mirrors LaTeX disambiguation',
  hzh.includes('"insert_math", "value": "公式 (LaTeX)"'));

// File-level content diff registry: exactly 20 shared-name files changed.
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
const ha = hashTree(`${ROOT}/decompiled_1.0.3/resources/res`);
const hb = hashTree(`${ROOT}/decompiled_1.4.2/resources/res`);
const sharedFiles = [...ha.keys()].filter(k => hb.has(k));
const contentChanged = sharedFiles.filter(k => ha.get(k) !== hb.get(k));
check('551 shared res files, 20 content-changed',
  sharedFiles.length === 551 && contentChanged.length === 20,
  `${sharedFiles.length}/${contentChanged.length}`);
check('all changed files are vendor or already-registered values',
  contentChanged.every(f =>
    f.includes('common_google_signin') ||
    f === 'drawable/ic_launcher_monochrome.xml' ||
    f.startsWith('values/') ||
    f === 'xml/core_remoteconfig__remote_config_defaults.xml'),
  contentChanged.filter(f =>
    !(f.includes('common_google_signin') || f.startsWith('values/') ||
      f === 'drawable/ic_launcher_monochrome.xml' ||
      f === 'xml/core_remoteconfig__remote_config_defaults.xml')).join(','));

console.log(`\ncontent-diff replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
