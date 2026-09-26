// Phase 825 — uses-permission lineage + Harmony mapping
// 1. Original perms 19->21->22 (AD_ID+SINGULAR in 1.0.3, READ_CALENDAR in 1.4.2)
// 2. Custom permission LAUNCH_CAPTURE_CONTENT_ACTIVITY_FOR_NOTE stable
// 3. Harmony declares exactly 4; camera via system picker (no CAMERA perm)
import { readFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';

const REF = 'C:/Users/Cisco He/Desktop/Notability';
const REPO = 'C:/HarmonyProject/NotaHarmony';
let pass = 0, fail = 0;
const ok = (name, cond, detail = '') => {
  if (cond) { pass++; console.log(`  ok ${name}`); }
  else { fail++; console.log(`  FAIL ${name} ${detail}`); }
};

const perms = v => {
  const m = readFileSync(join(REF, `decompiled_${v}/resources/AndroidManifest.xml`), 'utf8');
  return new Set([...m.matchAll(/name="([^"]*(?:permission|PERMISSION)[^"]*)"/g)].map(x => x[1]));
};
const p101 = perms('1.0.1'), p103 = perms('1.0.3'), p142 = perms('1.4.2');

ok('permission sets grow 19->21->22', p101.size === 19 && p103.size === 21 && p142.size === 22,
  `${p101.size}/${p103.size}/${p142.size}`);
ok('1.0.3 adds AD_ID + SINGULAR preinstall perm',
  p103.has('com.google.android.gms.permission.AD_ID')
    && p103.has('com.singular.preinstall.READ_PERMISSION_SINGULAR')
    && !p101.has('com.google.android.gms.permission.AD_ID'));
ok('1.4.2 adds READ_CALENDAR',
  p142.has('android.permission.READ_CALENDAR') && !p103.has('android.permission.READ_CALENDAR'));
ok('custom capture permission stable across versions',
  [p101, p103, p142].every(p => p.has('android.permission.LAUNCH_CAPTURE_CONTENT_ACTIVITY_FOR_NOTE')));
ok('core perms stable: RECORD_AUDIO/CAMERA/INTERNET in all',
  [p101, p103, p142].every(p =>
    p.has('android.permission.RECORD_AUDIO') && p.has('android.permission.CAMERA')
      && p.has('android.permission.INTERNET')));

// Harmony side
const mod = JSON.parse(JSON.stringify(readFileSync(join(REPO, 'note/src/main/module.json5'), 'utf8')));
const reqPerms = [...mod.matchAll(/"name": "(ohos\.permission\.[^"]+)"/g)].map(m => m[1]);
ok('Harmony declares exactly 4 requestPermissions',
  reqPerms.length === 4, reqPerms.join(','));
ok('Harmony perms = INTERNET/KEEP_BACKGROUND_RUNNING/MICROPHONE/READ_PASTEBOARD',
  ['ohos.permission.INTERNET', 'ohos.permission.KEEP_BACKGROUND_RUNNING',
    'ohos.permission.MICROPHONE', 'ohos.permission.READ_PASTEBOARD']
    .every(p => reqPerms.includes(p)));
ok('no CAMERA perm (system cameraPicker model)', !reqPerms.some(p => p.includes('CAMERA')));
ok('cameraPicker caller exists for take-photo',
  existsSync(join(REPO, 'note/src/main/ets/data/OriginalCameraPickerCaller.ets')));
ok('permission reason strings exist for MIC/PASTEBOARD',
  mod.includes('microphone_permission_reason') && mod.includes('read_pasteboard_permission_reason'));

console.log(`\n${pass}/${pass + fail} checks passed`);
process.exit(fail ? 1 : 0);
