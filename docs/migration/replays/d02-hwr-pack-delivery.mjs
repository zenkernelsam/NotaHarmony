// Phase 863 — 手写识别语言包投递层登记回归
// 证据：docs/migration/evidence/phase-863-hwr-pack-delivery.md
import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources';
const HARM = 'note/src/main/ets';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };

// ---- dc5 23 语言枚举 ----
const dc5 = readFileSync(join(SRC, 'defpackage/dc5.java'), 'utf8');
const langs = [...dc5.matchAll(/"([a-z]{2,3}_[A-Z]{2})",\s*"([a-zA-Z-]+)"/g)]
  .map(m => [m[1], m[2]]);
ok(langs.length === 23, `dc5 has 23 languages (got ${langs.length})`);
const dc5Map = Object.fromEntries(langs);
for (const [code, tag] of [['en_US', 'en'], ['zh_CN', 'zh-Hans'],
    ['zh_TW', 'zh-Hant'], ['fil_PH', 'fil'], ['no_NO', 'nb'],
    ['id_ID', 'id'], ['da_DK', 'da']]) {
  ok(dc5Map[code] === tag, `dc5 ${code} -> ${tag}`);
}
ok(dc5.includes('x90.W0(new String[]{"TW", "HK", "MO"})'), 'dc5.N = {TW,HK,MO} Hant regions');
ok(/dc5 dc5Var = O;/.test(dc5), 'dc5.L = en_US default');

// ---- gg1 安装器契约 ----
const gg1 = readFileSync(join(SRC, 'defpackage/gg1.java'), 'utf8');
ok(gg1.includes('implements zb5'), 'gg1 implements zb5 installer');
ok(gg1.includes('ys2.P(dc5.O)'), 'gg1 bundled set = {en_US} only');
ok(gg1.includes('4.4.0'), 'gg1 pack schema version 4.4.0');
ok(gg1.includes('https://android-assets.notability.com'), 'gg1 CDN fallback host');
ok(gg1.includes('LanguagePackUnavailableException'), 'gg1.d() throws pack-unavailable');

// ---- 三异常门 ----
const hwr = join(SRC, 'com/gingerlabs/notability/data/handwritingrecognition');
ok(readFileSync(join(hwr, 'HandwritingPackDownloadWorker.java'), 'utf8')
  .includes('CoroutineWorker'), 'pack download is a WorkManager CoroutineWorker');
ok(readFileSync(join(hwr, 'MathRecognitionUnsupportedException.java'), 'utf8')
  .includes('MyScript certificate does not support the Math recognizer'),
  'math recognizer is MyScript-certificate gated');
ok(readFileSync(join(hwr, 'PlayAssetDeliveryUnavailableException.java'), 'utf8')
  .includes('extends IOException'), 'Play-asset-delivery failure is IOException');

// ---- Harmony 侧 ----
const policy = readFileSync(join(HARM, 'core/model/OriginalHandwritingLanguagePolicy.ets'), 'utf8');
ok(policy.includes('ORIGINAL_HANDWRITING_RECOGNITION_LANGUAGE_COUNT: number = 23'),
  'Harmony pins 23 languages');
ok((policy.match(/localeCode: '/g) || []).length === 23, '23 locale rows present');
ok(policy.includes("ORIGINAL_HANDWRITING_DEFAULT_LOCALE_CODE: string = 'en_US'"),
  'Harmony default en_US');
for (const pair of ["'zh_CN', languageTag: 'zh-Hans'", "'zh_TW', languageTag: 'zh-Hant'",
    "'fil_PH', languageTag: 'fil'", "'no_NO', languageTag: 'nb'"]) {
  ok(policy.includes(pair), `Harmony row ${pair}`);
}
ok(policy.includes("language = 'fil'") && policy.includes("language = 'id'") &&
   policy.includes("language = 'nb'"), 'legacy ISO remaps tl->fil in->id no|nn->nb');
ok(policy.includes('isTraditionalChineseCountry'), 'zh region gate (TW/HK/MO)');
ok(policy.includes('NOTE_REGISTER') && policy.includes('GLOBAL_PREFERENCE') &&
   policy.includes('SYSTEM_LOCALE') && policy.includes('DEFAULT_ENGLISH'),
  'four-source resolution chain');

const rec = readFileSync(join(HARM, 'core/adaptation/OriginalHandwritingRecognition.ets'), 'utf8');
ok(rec.includes('provider === null || !provider.isAvailable()'), 'fail-closed on null provider');
ok(rec.includes('recognizeText(strokes, language.localeCode)'), 'passes localeCode (dc5.I)');

const cap = readFileSync(join(HARM, 'core/adaptation/OriginalHandwritingProviderCapabilityPolicy.ets'), 'utf8');
ok(cap.includes('SYSTEM_CAPABILITY_UNAVAILABLE'), 'syscap gate');
ok(cap.includes('LANGUAGE_COVERAGE_INCOMPLETE'), 'language-coverage gate');
ok(cap.includes('SystemCapability.AI.OCR.TextRecognition'), 'CoreVision OCR syscap pin');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
