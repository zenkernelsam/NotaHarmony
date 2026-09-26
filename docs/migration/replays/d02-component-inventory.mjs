// Phase 824 — manifest app-component inventory closure
// receivers: 6 app-level, stable across 3 versions
// services: 2->2->3 (HwrEngineService new in 1.4.2)
// providers: 1->2->3 (ExportFileProvider 1.0.3, ApiGatedFirebaseInitProvider 1.4.2)
import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

const REF = 'C:/Users/Cisco He/Desktop/Notability';
const REPO = 'C:/HarmonyProject/NotaHarmony';
let pass = 0, fail = 0;
const ok = (name, cond, detail = '') => {
  if (cond) { pass++; console.log(`  ok ${name}`); }
  else { fail++; console.log(`  FAIL ${name} ${detail}`); }
};

const comp = v => {
  const m = readFileSync(join(REF, `decompiled_${v}/resources/AndroidManifest.xml`), 'utf8');
  const out = { receiver: [], service: [], provider: [] };
  const rx = /<(receiver|service|provider)[^>]*android:name="([^"]+)"/g;
  for (const mm of m.matchAll(rx)) out[mm[1]].push(mm[2]);
  return out;
};
const c101 = comp('1.0.1'), c103 = comp('1.0.3'), c142 = comp('1.4.2');
const app = l => l.filter(n => n.includes('gingerlabs'));

// -- receivers ------------------------------------------------------------------
ok('6 app receivers, stable across all versions',
  app(c101.receiver).length === 6 && app(c103.receiver).length === 6
    && app(c142.receiver).length === 6
    && app(c142.receiver).every(r => app(c101.receiver).includes(r)));
ok('5 widget providers + AppUpgradeReceiver',
  app(c142.receiver).filter(r => r.includes('WidgetProvider')).length === 5
    && app(c142.receiver).some(r => r.includes('AppUpgradeReceiver')));

// -- services ---------------------------------------------------------------------
ok('services 2->2->3 (HwrEngineService added 1.4.2)',
  app(c101.service).length === 2 && app(c103.service).length === 2
    && app(c142.service).length === 3
    && app(c142.service).some(s => s.includes('HwrEngineService'))
    && !app(c103.service).some(s => s.includes('HwrEngineService')));

// -- providers ----------------------------------------------------------------------
ok('providers 1->2->3 (ExportFileProvider 1.0.3, ApiGated 1.4.2)',
  app(c101.provider).length === 1
    && app(c103.provider).length === 2
    && app(c142.provider).length === 3
    && app(c103.provider).some(p => p.includes('ExportFileProvider'))
    && app(c142.provider).some(p => p.includes('ApiGatedFirebaseInitProvider'))
    && !app(c103.provider).some(p => p.includes('ApiGatedFirebaseInitProvider'))
    && !app(c101.provider).some(p => p.includes('FileProvider')));

// -- Harmony equivalents --------------------------------------------------------------
const forms = readdirSync(join(REPO, 'note/src/main/ets/data')).filter(f => /FormFeed/.test(f));
ok('Harmony has >=3 FormFeed data sources (widget providers)',
  forms.length >= 3, forms.join(','));
ok('Harmony NoteFormAbility exists',
  existsSyncSafe(join(REPO, 'note/src/main/ets/noteformability/NoteFormAbility.ets')));
const rec = readFileSync(join(REPO, 'note/src/main/ets/core/adaptation/OriginalRecordingSourceBackend.ets'), 'utf8');
ok('Harmony AUDIO_RECORDING continuous task (services equivalent)',
  rec.includes('BackgroundMode.AUDIO_RECORDING'));

function existsSyncSafe(p) { try { readFileSync(p); return true; } catch { return false; } }

console.log(`\n${pass}/${pass + fail} checks passed`);
process.exit(fail ? 1 : 0);
