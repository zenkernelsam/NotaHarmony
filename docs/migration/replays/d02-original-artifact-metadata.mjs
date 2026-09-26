// D02 原版工件级收尾 + 版本号注册 — Phase 794
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

const M103 = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/resources/AndroidManifest.xml';
const M142 = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/resources/AndroidManifest.xml';
const A103 = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/resources/assets';
const A142 = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/resources/assets';
const APPJSON = 'C:/HarmonyProject/NotaHarmony/AppScope/app.json5';

const m103 = fs.readFileSync(M103, 'utf8');
const m142 = fs.readFileSync(M142, 'utf8');
const appJson = fs.readFileSync(APPJSON, 'utf8');

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

check('original version triple registered (1.0.3=1014, 1.4.2=1040002)',
  m103.includes('android:versionCode="1014"')
  && m103.includes('android:versionName="1.0.3"')
  && m142.includes('android:versionCode="1040002"')
  && m142.includes('android:versionName="1.4.2"'));
check('Harmony self-reports 1.0.0/1000000 (T-042 input)',
  appJson.includes('"versionCode": 1000000')
  && appJson.includes('"versionName": "1.0.0"'));
check('dexopt baseline profiles present in both (Android-only)',
  fs.existsSync(path.join(A103, 'dexopt', 'baseline.prof'))
  && fs.existsSync(path.join(A142, 'dexopt', 'baseline.prof'))
  && fs.existsSync(path.join(A142, 'dexopt', 'baseline.profm')));
check('MyScript resources/ persists in 1.4.2 (engine bundled)',
  ['analyzer', 'document_layout', 'en_US', 'math', 'shape']
    .every((d) => fs.existsSync(path.join(A142, 'resources', d))));
check('only three lite .res variants removed in en_US/',
  ['en_US-ak-cur.lite.res', 'en_US-ak-superimposed.lite.res',
    'en_US-lk-text.lite.res']
    .every((f) => fs.existsSync(path.join(A103, 'resources', 'en_US', f))
      && !fs.existsSync(path.join(A142, 'resources', 'en_US', f)))
  && fs.existsSync(path.join(A142, 'resources', 'en_US', 'en_US-lk-text.res')));
check('en_US.conf + two .res files updated in 1.4.2',
  fs.readFileSync(path.join(A103, 'conf', 'en_US.conf'), 'utf8')
    !== fs.readFileSync(path.join(A142, 'conf', 'en_US.conf'), 'utf8')
  && fs.readFileSync(path.join(A103, 'resources', 'math', 'math-sr.res'))
    .compare(fs.readFileSync(path.join(A142, 'resources', 'math', 'math-sr.res'))) !== 0);

console.log(`artifact-metadata replay: ${checks.length}/${checks.length} checks green`);
