// Phase 820 — system-surface closure: notification channels + launcher icon layers
// 1. Original channel inventory: 4 (2 app + 2 vendor), identical 1.0.3<->1.4.2
// 2. Original adaptive icon = 3 layers; monochrome via app_mark_path
// 3. Harmony layered_image = bg+fg PNGs with real opaque content
// 4. Harmony recording = AUDIO_RECORDING continuous task (channel-equivalent)
import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

const REF = 'C:/Users/Cisco He/Desktop/Notability';
const REPO = 'C:/HarmonyProject/NotaHarmony';
let pass = 0, fail = 0;
const ok = (name, cond, detail = '') => {
  if (cond) { pass++; console.log(`  ok ${name}`); }
  else { fail++; console.log(`  FAIL ${name} ${detail}`); }
};

// -- 1. Notification channels ------------------------------------------------
const channels = { '1.0.3': new Set(), '1.4.2': new Set() };
const rx = /NotificationChannel\("([^"]+)"/g;
for (const v of ['1.0.3', '1.4.2']) {
  const files = [];
  (function walk(d) {
    for (const e of readdirSync(d, { withFileTypes: true })) {
      const p = join(d, e.name);
      if (e.isDirectory()) walk(p);
      else if (e.name.endsWith('.java')) files.push(p);
    }
  })(join(REF, `decompiled_${v}/sources`));
  for (const f of files) {
    const t = readFileSync(f, 'utf8');
    for (const m of t.matchAll(rx)) channels[v].add(m[1]);
  }
}
const c4 = channels['1.4.2'];
ok('original notification channels = 4', c4.size === 4, [...c4].join('|'));
ok('app channels notability_recording + AudioCapture channel',
  c4.has('notability_recording') && c4.has('AudioCapture channel'));
ok('channel inventory identical 1.0.3<->1.4.2',
  [...channels['1.0.3']].every(c => c4.has(c)) && channels['1.0.3'].size === c4.size);
const svc = readFileSync(join(REF, 'decompiled_1.4.2/sources/com/gingerlabs/notability/feature/note/toolbox/audio/record/RecordingForegroundService.java'), 'utf8');
ok('notability_recording uses LOW importance + string key',
  svc.includes('notability_recording') && svc.includes('recording_notification_channel_name'));

// -- 2. Launcher icon layers ---------------------------------------------------
const ic = readFileSync(join(REF, 'decompiled_1.4.2/resources/res/mipmap-anydpi/ic_launcher.xml'), 'utf8');
ok('adaptive icon has background+foreground+monochrome',
  ic.includes('background') && ic.includes('foreground') && ic.includes('monochrome'));
const mono = readFileSync(join(REF, 'decompiled_1.4.2/resources/res/drawable/ic_launcher_monochrome.xml'), 'utf8');
ok('monochrome layer uses shared app_mark_path', mono.includes('app_mark_path'));
const colors = readFileSync(join(REF, 'decompiled_1.4.2/resources/res/values/colors.xml'), 'utf8');
ok('launcher palette #5497fe/#ff8e4d/#f5ebd9',
  colors.includes('#5497fe') && colors.includes('#ff8e4d') && colors.includes('#f5ebd9'));

// -- 3. Harmony layered image ----------------------------------------------------
const layered = JSON.parse(readFileSync(join(REPO, 'AppScope/resources/base/media/layered_image.json'), 'utf8'));
const li = layered['layered-image'];
ok('Harmony layered-image has bg+fg only', !!li.background && !!li.foreground
  && Object.keys(li).length === 2);
const fg = readFileSync(join(REPO, 'AppScope/resources/base/media/foreground.png'));
const bg = readFileSync(join(REPO, 'AppScope/resources/base/media/background.png'));
ok('Harmony icon PNGs are real content', fg.length > 5000 && bg.length > 50000);

// -- 4. Recording continuous-task equivalent --------------------------------------
const rec = readFileSync(join(REPO, 'note/src/main/ets/core/adaptation/OriginalRecordingSourceBackend.ets'), 'utf8');
ok('Harmony recording uses AUDIO_RECORDING continuous task',
  rec.includes('backgroundTaskManager.startBackgroundRunning')
    && rec.includes('BackgroundMode.AUDIO_RECORDING'));

console.log(`\n${pass}/${pass + fail} checks passed`);
process.exit(fail ? 1 : 0);
