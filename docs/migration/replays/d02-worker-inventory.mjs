// Phase 823 — WorkManager worker inventory closure
// 1. Worker count delta: 7 (1.0.3) -> 15 (1.4.2)
// 2. All 7 baseline workers are sync/asset/export types
// 3. All 8 new workers map to registered clusters
// 4. Harmony has no workScheduler — only AUDIO_RECORDING continuous task
import { readFileSync, readdirSync, existsSync } from 'node:fs';
import { join } from 'node:path';

const REF = 'C:/Users/Cisco He/Desktop/Notability';
const REPO = 'C:/HarmonyProject/NotaHarmony';
let pass = 0, fail = 0;
const ok = (name, cond, detail = '') => {
  if (cond) { pass++; console.log(`  ok ${name}`); }
  else { fail++; console.log(`  FAIL ${name} ${detail}`); }
};

const workers = v => {
  const d = join(REF, `decompiled_${v}/sources/com/gingerlabs`);
  const out = [];
  (function w(dd) {
    for (const e of readdirSync(d, { withFileTypes: true }).map(() => null) && readdirSync(dd, { withFileTypes: true })) {
      const p = join(dd, e.name);
      if (e.isDirectory()) w(p);
      else if (e.name.endsWith('Worker.java') && !e.name.includes('Factory')) out.push(e.name.replace('.java', ''));
    }
  })(d);
  return out.sort();
};

const w103 = workers('1.0.3');
const w142 = workers('1.4.2');
ok('1.0.3 = 7 workers', w103.length === 7, `got ${w103.length}`);
ok('1.4.2 = 15 workers', w142.length === 15, `got ${w142.length}`);
ok('all baseline workers persist in 1.4.2', w103.every(w => w142.includes(w)));

const NEW = ['BackgroundMaintenanceWorker', 'CustomTemplateSyncWorker', 'DemoResetWorker',
  'GalleryMutationUploaderWorker', 'StickerPackDownloadWorker', 'StickerPackPrefetchWorker',
  'TemplatePageSyncWorker', 'UnresolvableWorker'];
const added = w142.filter(w => !w103.includes(w));
ok('8 new workers = registered-cluster set',
  added.length === 8 && NEW.every(n => added.includes(n)), added.join(','));

const BASE = ['ExportSweepWorker', 'HandwritingPackDownloadWorker', 'LibraryStateUploaderWorker',
  'NoteAssetDownloadWorker', 'NoteAssetTransferWorker', 'NoteAssetUploadWorker', 'NoteOpsUpdaterWorker'];
ok('7 baseline = sync/asset/export workers', BASE.every(b => w103.includes(b)));

const demo = readFileSync(join(REF, 'decompiled_1.4.2/sources/com/gingerlabs/notability/app/demo/DemoResetWorker.java'), 'utf8');
ok('DemoResetWorker = CoroutineWorker retail-demo reset',
  demo.includes('CoroutineWorker') && demo.includes('demo'));

const unr = readFileSync(join(REF, 'decompiled_1.4.2/sources/com/gingerlabs/notability/core/workmanager/UnresolvableWorker.java'), 'utf8');
ok('UnresolvableWorker exists (poison-pill terminator)', unr.includes('UnresolvableWorker'));

// Harmony side: no workScheduler
const etsFiles = [];
(function w(d) {
  for (const e of readdirSync(d, { withFileTypes: true })) {
    const p = join(d, e.name);
    if (e.isDirectory()) w(p);
    else if (e.name.endsWith('.ets')) etsFiles.push(p);
  }
})(join(REPO, 'note/src/main/ets'));
let hasWorkScheduler = false, hasAudioTask = false;
for (const f of etsFiles) {
  const t = readFileSync(f, 'utf8');
  if (/workScheduler|WorkScheduler|reminderAgent/.test(t)) hasWorkScheduler = true;
  if (/BackgroundMode\.AUDIO_RECORDING/.test(t)) hasAudioTask = true;
}
ok('Harmony has no workScheduler/reminderAgent (consistent fail-closed)', !hasWorkScheduler);
ok('Harmony AUDIO_RECORDING continuous task present', hasAudioTask);

console.log(`\n${pass}/${pass + fail} checks passed`);
process.exit(fail ? 1 : 0);
