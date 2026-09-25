// Phase 737 — app/initializers + MissingNativeLibrary + HCT a11y 边界
import fs from 'node:fs';
import path from 'node:path';

const REPO = path.resolve(process.cwd());
const ORIG = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources';
const R = (p) => path.join(REPO, p);
const read = (p) => fs.readFileSync(R(p), 'utf8');

let total = 0, failed = 0;
const check = (name, cond) => {
  total++;
  if (!cond) { failed++; console.log('FAIL', name); }
};

const adrP = 'docs/migration/adr/ADR-0685-original-initializers-hct.md';
const evP = 'docs/migration/evidence/original-initializers-hct-jadx-2026-09-25.md';
const rpP = 'docs/migration/reports/phase-737-original-initializers-hct.md';
check('ADR-0685 存在', fs.existsSync(R(adrP)));
check('证据文档存在', fs.existsSync(R(evP)));
check('Phase 737 报告存在', fs.existsSync(R(rpP)));

const adr = read(adrP);
const ev = read(evP);

// —— 原版证据 ——
const init = fs.readFileSync(
  path.join(ORIG, 'com/gingerlabs/notability/app/initializers/AppStartupInitializer.java'), 'utf8');
check('原版 Rive.init', init.includes('Rive.init'));
check('原版 HCT observer 注册', init.includes('high_text_contrast_enabled'));
check('原版 je5 ContentObserver', init.includes('registerContentObserver'));
const ke5 = fs.readFileSync(path.join(ORIG, 'defpackage/ke5.java'), 'utf8');
check('ke5 Secure 读 HCT', ke5.includes('high_text_contrast_enabled'));
const ie5 = fs.readFileSync(path.join(ORIG, 'defpackage/ie5.java'), 'utf8');
check('ie5 返回 bh5 HCT Canvas', ie5.includes('new bh5(bitmap)'));
const missing = fs.readFileSync(
  path.join(ORIG, 'com/gingerlabs/notability/app/MissingNativeLibraryActivity.java'), 'utf8');
check('MissingNativeLibrary AlertDialog', missing.includes('missing_native_library_title'));
const logging = fs.readFileSync(
  path.join(ORIG, 'com/gingerlabs/notability/app/initializers/LoggingInitializer.java'), 'utf8');
check('LoggingInitializer backend_override', logging.includes('backend_override'));

// —— ADR/证据 ——
check('ADR 登记 HCT 边界', adr.includes('high_text_contrast_enabled'));
check('ADR 记录 ke5/je5/ie5/bh5 链', adr.includes('ke5') && adr.includes('bh5'));
check('ADR 登记 Rive/MissingNativeLibrary', adr.includes('MissingNativeLibraryActivity'));
check('ADR 登记 backend_override 后门', adr.includes('backend_override'));
check('ADR 声明 Harmony 无 HCT API', adr.includes('@ohos.accessibility'));
check('证据记录 ie5 兜底日志', ev.includes('framework HCT path is broken'));
check('证据记录 vw7 消费点', ev.includes('vw7'));
check('证据含未验证声明', ev.includes('未验证声明'));

// —— Harmony 侧复核（无残留引入）——
let any = false;
for (const f of [
  'note/src/main/ets/noteability/NoteAbility.ets',
  'note/src/main/ets/data/NoteExporter.ets',
]) { any = any || /high_text_contrast|highContrastText/i.test(read(f)); }
check('Harmony 无 HCT 残留引用', !any);

// —— 追踪 ——
check('修复总纲登记 Phase 737', read('docs/migration/audit-2026-08/修复总纲.md').includes('Phase 737'));
check('修复总纲2 登记 Phase 737', read('docs/migration/audit-2026-08/修复总纲2.md').includes('Phase 737'));
check('进展文档登记 Phase 737', read('docs/migration/reports/修复进展-2026-08-09.md').includes('Phase 737'));

console.log(`D02_ORIGINAL_INITIALIZERS_HCT_REPLAY_OK TOTAL=${total} FAILED=${failed}`);
process.exit(failed ? 1 : 0);
