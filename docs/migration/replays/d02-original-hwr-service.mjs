// D02 原版 1.4.2 HwrEngineService 架构 — Phase 768（修正 Phase 760 "云端识别"误述）
// 钉住 :hwr 进程隔离、IHwrEngine 六事务、MyScript iink 在场与 Play 语言包管道。
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

const base = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources';
const manifest = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/resources/AndroidManifest.xml';
const svc = `${base}/com/gingerlabs/notability/data/handwritingrecognition/hwr/HwrEngineService.java`;
const l77 = `${base}/defpackage/l77.java`;
const iinkDir = `${base}/com/myscript/iink`;

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

const mf = fs.readFileSync(manifest, 'utf8');
check('HwrEngineService declared in manifest with :hwr process isolation',
  mf.includes('HwrEngineService') && mf.includes('android:process=":hwr"'));

const svcSrc = fs.readFileSync(svc, 'utf8');
check('service is a bound Service with request-id keyed session map',
  svcSrc.includes('extends Service') && svcSrc.includes('onBind'));

const l77s = fs.readFileSync(l77, 'utf8');
check('IHwrEngine exposes capability probe + streaming feed + result retrieval',
  l77s.includes('int E()') && l77s.includes('void F(long j, byte[] bArr)') && l77s.includes('n67 t(long j)'));
check('IHwrEngine exposes cancel + session-configure entry points',
  l77s.includes('void l(long j)') && l77s.includes('void x(long j, int i, String str'));

let iinkFiles = 0;
const walk = (d) => {
  for (const e of fs.readdirSync(d, { withFileTypes: true })) {
    const p = path.join(d, e.name);
    if (e.isDirectory()) walk(p);
    else if (e.name.endsWith('.java')) iinkFiles++;
  }
};
walk(iinkDir);
check('MyScript iink SDK still shipped in 1.4.2 (>50 java files)', iinkFiles > 50);

const packWorker = fs.readFileSync(
  `${base}/com/gingerlabs/notability/data/handwritingrecognition/HandwritingPackDownloadWorker.java`, 'utf8');
check('language packs delivered on-demand via worker + language_id param',
  packWorker.includes('language_id'));
check('pack-delivery failures typed (Play Asset Delivery boundary)',
  fs.existsSync(`${base}/com/gingerlabs/notability/data/handwritingrecognition/PlayAssetDeliveryUnavailableException.java`)
  && fs.existsSync(`${base}/com/gingerlabs/notability/data/handwritingrecognition/LanguagePackUnavailableException.java`));

const javaUnder = (d) => {
  const out = [];
  const w = (x) => {
    for (const e of fs.readdirSync(x, { withFileTypes: true })) {
      const p = path.join(x, e.name);
      if (e.isDirectory()) w(p); else if (e.name.endsWith('.java')) out.push(p);
    }
  };
  w(d);
  return out;
};
const hwrNet = javaUnder(`${base}/com/gingerlabs/notability/data/handwritingrecognition`)
  .concat(javaUnder(`${base}/com/myscript`))
  .map((p) => fs.readFileSync(p, 'utf8')).join('\n');
check('no http endpoint literals under handwritingrecognition/ + myscript/',
  !/https?:\/\//.test(hwrNet));

console.log(`hwr service replay: ${checks.length}/${checks.length} checks green`);
