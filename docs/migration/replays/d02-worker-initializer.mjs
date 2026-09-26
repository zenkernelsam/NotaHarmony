// Phase 845 — Worker + Initializer 清单闭合
import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join } from 'node:path';

const B = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources/com/gingerlabs/notability';
const results = [];
const ck = (n, ok) => results.push([n, ok]);
const all = [];
const walk = (d) => { for (const f of readdirSync(d, { withFileTypes: true })) { const p = join(d, f.name); if (f.isDirectory()) walk(p); else if (f.name.endsWith('.java')) all.push(p); } };
walk(B);
const rel = (p) => p.replace(/\\/g, '/').split('notability/')[1];

// Worker 清单 14
const workers = all.filter(f => /Worker\.java$/.test(f)).map(rel);
const expectedWorkers = [
  'app/demo/DemoResetWorker.java',
  'core/workmanager/UnresolvableWorker.java',
  'data/gallery/outbox/GalleryMutationUploaderWorker.java',
  'data/handwritingrecognition/HandwritingPackDownloadWorker.java',
  'data/library/state/ExportSweepWorker.java',
  'data/library/state/LibraryStateUploaderWorker.java',
  'data/library/state/notes/NoteOpsUpdaterWorker.java',
  'data/note/assets/NoteAssetDownloadWorker.java',
  'data/note/assets/NoteAssetTransferWorker.java',
  'data/note/assets/NoteAssetUploadWorker.java',
  'data/settings/sync/TemplatePageSyncWorker.java',
  'data/templates/sync/CustomTemplateSyncWorker.java',
  'domain/maintenance/BackgroundMaintenanceWorker.java',
  'feature/note/stickers/packs/StickerPackDownloadWorker.java',
  'feature/note/stickers/packs/StickerPackPrefetchWorker.java',
];
ck('Worker 清单=15', workers.length === 15);
ck('Worker 全命中', expectedWorkers.every(w => workers.includes(w)));
ck('CoroutineWorker 为主（12 直系+2 经 NoteAssetTransferWorker 继承）', workers.filter(w => readFileSync(join(B, w), 'utf8').includes('CoroutineWorker')).length === 12 && readFileSync(join(B, 'data/note/assets/NoteAssetDownloadWorker.java'), 'utf8').includes('extends NoteAssetTransferWorker'));
ck('UnresolvableWorker 占位桩', readFileSync(join(B, 'core/workmanager/UnresolvableWorker.java'), 'utf8').includes('extends Worker'));

// Initializer 清单
const inits = all.filter(f => /Initializer\.java$/.test(f)).map(rel).sort();
ck('Initializer=6', inits.length === 6);
for (const n of ['UserDataStore', 'ThemeDataStore', 'NoteEditorSettings', 'HapticPreferences', 'AppStartup', 'Logging']) {
  ck(`Initializer ${n}`, inits.some(i => i.includes(n)));
}

// Harmony 侧断言
const ability = readFileSync('C:/HarmonyProject/NotaHarmony/note/src/main/ets/noteability/NoteAbility.ets', 'utf8');
ck('Harmony ThemeStore.init 注册点', ability.includes('ThemeStore.init()'));
let noSched = true;
const ui = [];
const walkEts = (d) => { try { for (const f of readdirSync(d, { withFileTypes: true })) { const p = join(d, f.name); if (f.isDirectory()) walkEts(p); else if (f.name.endsWith('.ets')) ui.push(p); } } catch {} };
walkEts('C:/HarmonyProject/NotaHarmony/note/src/main/ets');
for (const f of ui) { const t = readFileSync(f, 'utf8'); if (t.includes('workScheduler') || t.includes('transientTask')) noSched = false; }
ck('Harmony 无 workScheduler/transientTask', noSched);

let pass = 0;
for (const [n, ok] of results) {
  if (ok) { pass++; console.log(`PASS ${n}`); }
  else console.log(`FAIL ${n}`);
}
console.log(`${pass}/${results.length} checks passed`);
process.exit(pass === results.length ? 0 : 1);
