// Phase 890 — wa0=AssetMetadata 回归
// 证据：docs/migration/evidence/phase-890-assetmetadata-wa0.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const ETS = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');
const rde = (f) => readFileSync(join(ETS, f), 'utf8');

const wa0 = rd('wa0.java');
const k1j = rd('k1j.java');
const aa6 = rd('aa6.java');

// ---- wa0 = AssetMetadata ----
ok(wa0.includes('public final class wa0 extends cee implements ka4'), 'wa0 cee+ka4');
ok(wa0.includes('AssetMetadata(assetHash='), 'wa0 toString = AssetMetadata');
ok(wa0.includes('fileName=') && wa0.includes('mimeType=') &&
   wa0.includes('fileSize='), 'wa0 four named fields');
ok(wa0.includes('public final ua0 j()'), 'wa0 j()->ua0 hash');
ok(wa0.includes('public final String k()') &&
   wa0.includes('public final String m()'), 'wa0 k/m -> String fields');
ok(wa0.includes('public final int l()') && wa0.includes('mmf.a(l())'),
  'wa0 l() int mmf-wrapped fileSize');

// ---- k1j.c 写侧 ----
ok(k1j.includes('aVar.C(4)'), 'k1j.c C(4)');
ok(k1j.includes('aVar.j(0, aa6.x0(ua0VarJ, aVar))'), 'k1j.c f0 = ua0 inline');
ok(k1j.includes('dbj.c(strK, aVar)') && k1j.includes('aVar.h(1, iC)') &&
   k1j.includes('aVar.h(2, iC2)'), 'k1j.c f1/f2 strings');
ok(k1j.includes('aVar.e(3, iL, 0)'), 'k1j.c f3 int default 0');
ok(k1j.includes('aVar.z(iN, 4)') && k1j.includes('aVar.z(iN, 6)') &&
   k1j.includes('aVar.z(iN, 8)'), 'k1j.c three required marks');
ok(aa6.includes('public static final int x0(ua0 ua0Var, a aVar)'),
  'aa6.x0 ua0 inline writer');

// ---- Harmony 对齐 ----
const assets = rde('core/model/AssetTypes.ets');
ok(assets.includes('assetHash:') && assets.includes('fileSize:') &&
   assets.includes('mimeType:'), 'Harmony AssetTypes mirrors wa0');
const pdf = rde('core/adaptation/PdfBackgroundLoader.ets');
ok(pdf.includes('metadata.assetHashBits') && pdf.includes('metadata.fileSize') &&
   pdf.includes('metadata.mimeType'), 'PdfBackgroundLoader reads wa0 fields');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
