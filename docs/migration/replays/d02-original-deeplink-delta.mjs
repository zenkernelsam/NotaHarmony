// D02 原版 1.4.2 深链差登记 — Phase 796
import assert from 'node:assert/strict';
import fs from 'node:fs';

const M103 = fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/resources/AndroidManifest.xml', 'utf8');
const M142 = fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/resources/AndroidManifest.xml', 'utf8');
const MODULE = fs.readFileSync('C:/HarmonyProject/NotaHarmony/note/src/main/module.json5', 'utf8');
const INGRESS = fs.readFileSync('C:/HarmonyProject/NotaHarmony/note/src/main/ets/data/DeepLinkIngress.ets', 'utf8');

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

check('1.4.2 adds /gallery pathPrefix deep link (774 cluster)',
  M142.includes('android:pathPrefix="/gallery"')
  && !M103.includes('/gallery'));
check('1.4.2 adds /event/planner2627 marketing deep link (782 cluster)',
  M142.includes('android:path="/event/planner2627"')
  && M142.includes('android:path="/event/planner2627/"')
  && !M103.includes('planner2627'));
check('pre-existing links unchanged (authlink/app.note/plus25/learn)',
  ['/authlink', '/app/note', '/event/learn-from-home', '/event/plus25']
    .every((p) => M142.includes(p) && M103.includes(p)));
check('msauth SSO callback + PDF import filters unchanged',
  M142.includes('msauth') && M103.includes('msauth')
  && M142.includes('application/pdf') && M103.includes('application/pdf'));
check('HwrEngineService declared in manifest (768 evidence)',
  M142.includes('HwrEngineService'));
check('Harmony ingress handles notability.com + documents /event/* fail-closed',
  MODULE.includes('notability.com')
  && INGRESS.includes('/event/'));

console.log(`deeplink-delta replay: ${checks.length}/${checks.length} checks green`);
