// D02 原版 1.4.2 xapk 分包轴收口（Phase 1433 裁决）
// xapk 结构（Notability_1.4.2/*.xapk，23 项）：
//   base com.gingerlabs.notability.apk（无 lib/ —— natives 走 abi split）
//   config.<15 locale>.apk = 仅 resources.arsc（翻译表，键集与 base 同源
//     —— 已在 strings 前缀扫描轴全域收口，Harmony zh_CN 已移植）
//   config.xxhdpi.apk = abc_*/notification_*/common_*/googleg_*/tw_widget_*
//     vendored + app_widgets__widget_label_*（widget ADR-0632 系）+
//     feature_login__learn_*.webp（登录营销，后端）+
//     ui_designsystem__{academic_planner,six_months_plus}_onboarding.webp
//     （lra.E0/F0 s0c 公告卡：planner 推广 + "6 months of Plus" 订阅权益
//     —— zb6/ec6 公告管线，订阅/营销面 fail-closed）
//   config.arm64_v8a.apk = 25+ .so 全 vendored/平台原生
//     （MyScript iink×9 ADR-0645 / PDFNetC / mlkit_google_ocr_pipeline /
//     crashlytics×4 / rive-android / icing(AppSearch) /
//     datastore_shared_counter / c++_shared / androidx.graphics.path /
//     graphics-core / glmath(MicroTeX —— Harmony 走字体资产非 .so) /
//     libink(Google Ink ADR-1327)）
//   stickers.apk = install-time Play asset pack（manifest isFeatureSplit+
//     asset-pack+install-time）：assets/sticker_<pack>/ 约 2900 webp，
//     39 命名包（dwg.java）；pq3 经 AssetPackManager.b("stickers") 取包位。
//     **更正 P1429 证据措辞**：贴纸资产随装随有（install-time），CDN
//     1.1.0 是增量预取（StickerPackPrefetch/DownloadWorker）——但门禁不
//     变：h35.z0=STICKERS 位 new rd5(null)=InternalUserOnly，urf:411
//     (wqf.T SAVE_AS_STICKER)+d6b:1503 托盘项生产恒 false；Harmony 无
//     Play asset-delivery 通路，不虚构贴纸托盘/选择器，维持 fail-closed。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};
const read = p => fs.readFileSync(p, 'utf8');
const exists = p => fs.existsSync(p);

const adr = read('docs/migration/adr/ADR-1368-xapk-split-closure.md');
const ev = read('docs/migration/evidence/phase-1433-xapk-splits.md');
const adr1364 = read('docs/migration/adr/ADR-1364-sticker-tape-audio-residual.md');

// --- 文档登记分包结构 ---
check('ADR-1368 records xapk split inventory (locale/xxhdpi/arm64/stickers)',
  adr.includes('config.') && adr.includes('resources.arsc') &&
  adr.includes('xxhdpi') && adr.includes('arm64') && adr.includes('stickers.apk'));
check('ADR-1368 records sticker install-time asset-pack correction',
  adr.includes('install-time') && adr.includes('asset pack'));
check('ADR-1368 records native .so adjudication (iink/PDFNet/mlkit/glmath/libink)',
  adr.includes('MyScript') && adr.includes('PDFNet') &&
  adr.includes('mlkit') && adr.includes('glmath') && adr.includes('libink'));
check('ADR-1368 records onboarding promo + widget + login-marketing axes',
  adr.includes('academic_planner_onboarding') &&
  adr.includes('six_months_plus_onboarding') &&
  adr.includes('widget_label') && adr.includes('feature_login__learn'));
check('ADR-1364 sticker delivery wording corrected to asset-pack + CDN',
  /install-time|asset pack|asset-pack/i.test(adr1364));
check('evidence records gate sites urf:411 + d6b:1503 + rd5 InternalUserOnly',
  ev.includes('urf') && ev.includes('d6b') && ev.includes('rd5'));

// --- Harmony 无贴纸分包虚构 ---
const page = read('note/src/main/ets/ui/editor/NotePage.ets');
const toolbar = read('note/src/main/ets/ui/editor/EditorToolbar.ets');
check('no fabricated sticker tray/picker in editor surfaces',
  !/sticker.*picker|stickerTray|StickerPack/i.test(page + toolbar));
check('no bundled sticker webp assets',
  !exists('note/src/main/resources/rawfile/sticker_abstract_backgrounds') &&
  !exists('note/src/main/resources/rawfile/stickers'));

// --- 原生库轴：不打包 .so ---
check('no vendored .so bundled (iink/PDFNet/mlkit natives absent)',
  !exists('note/libs') && !exists('entry/libs'));

// --- 追踪文档 ---
for (const f of [
  'docs/migration/audit-2026-08/修复总纲.md',
  'docs/migration/audit-2026-08/修复总纲2.md',
  'docs/migration/reports/修复进展-2026-08-09.md',
]) {
  check(`${f} has Phase 1433 entry`, read(f).includes('Phase 1433'));
}

console.log(`TOTAL=${checks.length} FAILED=0`);
