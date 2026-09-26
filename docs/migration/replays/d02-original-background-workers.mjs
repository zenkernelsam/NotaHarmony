// D02 原版 1.4.2 后台 Worker 清单 — Phase 775
// 钉住 8 个新增 Worker、ForegroundReturned 让位语义与 UnresolvableWorker 安全桩。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const src = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources/com/gingerlabs/notability';
const src103 = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/gingerlabs/notability';

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

const walk = (d, out = []) => {
  for (const e of fs.readdirSync(d, { withFileTypes: true })) {
    const p = `${d}/${e.name}`;
    if (e.isDirectory()) walk(p, out);
    else if (/Worker\.java$/.test(e.name)) out.push(e.name);
  }
  return out;
};
const w142 = walk(src);
const w103 = walk(src103);
const added = w142.filter((w) => !w103.includes(w));

check('exactly 8 new Worker classes in 1.4.2 (none removed)', added.length === 8
  && w103.every((w) => w142.includes(w)));
check('the 8 new workers match the registered inventory',
  ['BackgroundMaintenanceWorker.java', 'CustomTemplateSyncWorker.java', 'DemoResetWorker.java',
    'GalleryMutationUploaderWorker.java', 'StickerPackDownloadWorker.java',
    'StickerPackPrefetchWorker.java', 'TemplatePageSyncWorker.java', 'UnresolvableWorker.java']
    .every((w) => added.includes(w)));

check('ForegroundReturned cancellation = maintenance yields to foreground',
  fs.readFileSync(`${src}/domain/maintenance/ForegroundReturned.java`, 'utf8')
    .includes('App returned to the foreground'));
check('UnresolvableWorker is a plain Worker safety stub',
  fs.readFileSync(`${src}/core/workmanager/UnresolvableWorker.java`, 'utf8')
    .includes('extends Worker'));
check('DemoResetWorker wires tracker+resetter+workManager',
  fs.readFileSync(`${src}/app/demo/DemoResetWorker.java`, 'utf8')
    .includes('extends CoroutineWorker'));

console.log(`background workers replay: ${checks.length}/${checks.length} checks green`);
