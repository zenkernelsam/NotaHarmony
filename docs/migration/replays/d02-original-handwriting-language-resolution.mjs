import { createHash } from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const originalRoot = process.env.NOTABILITY_ORIGINAL_ROOT ??
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const normalize = value => value.replaceAll('\r\n', '\n');
const readRepo = relative => normalize(fs.readFileSync(path.join(root, relative), 'utf8'));
const readOriginal = name => normalize(fs.readFileSync(path.join(originalRoot, name), 'utf8'));
const hashOriginal = name => createHash('sha256')
  .update(fs.readFileSync(path.join(originalRoot, name))).digest('hex').toUpperCase();

let total = 0;
let failed = 0;
function check(label, condition) {
  total++;
  if (condition) {
    console.log(`PASS: ${label}`);
  } else {
    failed++;
    console.error(`FAIL: ${label}`);
  }
}

const dc5 = readOriginal('dc5.java');
const sh8 = readOriginal('sh8.java');
const jc5 = readOriginal('jc5.java');
const hc5 = readOriginal('hc5.java');
const pm8 = readOriginal('pm8.java');
const l2d = readOriginal('l2d.java');
const dexEvidence = readRepo(
  'docs/migration/evidence/original-handwriting-language-resolution-jadx-dex-2026-08-18.md');

check('reviewed original language evidence hashes are pinned',
  hashOriginal('dc5.java') === '9AA6A03B888842A1BD217F50DA9A7CB55B5DAE0D1124EADB895E949393D33ECA' &&
  hashOriginal('sh8.java') === 'D6BFD57D268CA9EF810744134407E09BD96F2DA85FE689D333391E737ABA499D' &&
  hashOriginal('jc5.java') === 'A015153C5590755E79C2436BA9210430222187DDCBF226FC284FD1BD2233B405' &&
  hashOriginal('hc5.java') === '9F524AADE41D95ECF36DBE24B69E4A19587932B3DF8FA134A8EE4E37A3C56E5C' &&
  hashOriginal('pm8.java') === '96DCE90733FCD3137EC49B31552AC7D85153425D735EDCD308B9536E58778064' &&
  hashOriginal('l2d.java') === '59F8064AFF73887DBE32DE9ED2FAB61B77A77B8711E759E68D8C2F778D8E04D8');
check('dc5 declares the complete provider locale and canonical tag pairs',
  /O\("en_US", "en"\)/.test(dc5) &&
  /P\("zh_CN", "zh-Hans"\)/.test(dc5) &&
  /Q\("zh_TW", "zh-Hant"\)/.test(dc5) &&
  /EF211\("fil_PH", "fil"\)/.test(dc5) &&
  /EF226\("id_ID", "id"\)/.test(dc5) &&
  /L = dc5Var/.test(dc5) && /new String\[\]\{"TW", "HK", "MO"\}/.test(dc5));
check('sh8 exact lookup accepts either dc5 locale code or language tag',
  /dc5Var\.I\.equals\(str\) \|\| dc5Var\.J\.equals\(str\)/.test(sh8));
check('jc5 selects note register global preference and system locale in that order',
  /xj2\.v\(\(\(a79\) x09Var\)\.A, a79\.M\[6\]\)/.test(jc5) &&
  /this\.a\.b\(\)\.getValue\(\)/.test(jc5) &&
  /Locale\.getDefault\(\)/.test(jc5) && /sh8\.D\(str, str2, locale\)/.test(jc5));
check('sh8 returns recognized note before global preference',
  /if \(str != null && \(dc5VarB = B\(str\)\) != null\)[\s\S]*return dc5VarB/.test(sh8) &&
  /dc5VarB2 = str2 != null \? B\(str2\) : null[\s\S]*return dc5VarB2/.test(sh8));
check('Chinese locale selection prefers Hant script then TW HK MO region unless Hans is explicit',
  /locale\.getLanguage\(\), "zh"/.test(sh8) &&
  /locale\.getScript\(\), "Hant"[\s\S]*return dc5\.Q/.test(sh8) &&
  /!ba6\.o\(locale\.getScript\(\), "Hans"\) && dc5\.N\.contains\(locale\.getCountry\(\)\)/.test(sh8) &&
  /return dc5\.P/.test(sh8));
check('legacy Java locale aliases map tl to fil and in to id',
  /language2\.equals\("tl"\)[\s\S]*language = "fil"/.test(sh8) &&
  /language2\.equals\("in"\)[\s\S]*language = "id"/.test(sh8));
check('APK DEX resolves both no and nn to the dc5 Norwegian Bokmal tag',
  /const-string v0, "no"/.test(dexEvidence) &&
  /const-string v0, "nn"/.test(dexEvidence) &&
  /const-string p1, "nb"/.test(dexEvidence) &&
  /APK SHA-256: `3C616F6ED15B4DA14108A66B67A480BBA5789916A901FCDF7DE5192FA55B674B`/.test(dexEvidence));
check('unsupported system languages fall back to the English dc5 default',
  /dc5Var == null \? dc5\.L : dc5Var/.test(sh8) && /L = dc5Var/.test(dc5));
check('text recognition short-circuits an empty selected stroke list',
  /List listA2 = jc5\.a\(jc5Var, x09Var, collection, true\)[\s\S]*listA2\.isEmpty\(\)[\s\S]*new pzb\(""\)/.test(hc5));
check('resolved language is passed into the text recognizer path',
  /dc5 dc5VarE = jc5Var\.e\(x09Var\)/.test(hc5) &&
  /pm8Var2\.c\(map2, listA2, dc5VarE, this\)/.test(hc5));
check('MyScript receives dc5.I as both lang configuration keys',
  /configuration\.setString\("lang", dc5Var2\.I\)/.test(pm8) &&
  /configuration\.setString\("recognizer\.lang", dc5Var2\.I\)/.test(pm8) &&
  /str = "Text"/.test(pm8));
check('MyScript receives separate selected Ink pointer sequences with force',
  /Iterator it = list\.iterator\(\)/.test(pm8) &&
  /recognizer\.pointerDown\([^\r\n;]*0L, f3\)/.test(pm8) &&
  /recognizer\.pointerMove\([^\r\n;]*0L, f3\)/.test(pm8) &&
  /recognizer\.pointerUp\([^\r\n;]*0L, po4Var\.f\)/.test(pm8) &&
  /Object objE = e\(im8Var, mimeType, map, list, lm8Var2\)/.test(pm8));
check('SET_METADATA validation only checks the exact prefix before underscore',
  /lvd\.R0\(strJ, new String\[\]\{"_"\}/.test(l2d) &&
  /Locale\.getISOLanguages\(\)/.test(l2d));

const policy = readRepo('note/src/main/ets/core/model/OriginalHandwritingLanguagePolicy.ets');
const recognition = readRepo('note/src/main/ets/core/adaptation/OriginalHandwritingRecognition.ets');
const legacyProvider = readRepo('note/src/main/ets/core/adaptation/RecognitionProvider.ets');
const fixture = readRepo('note/src/test/OriginalHandwritingRecognition.test.ets');
const fixtureList = readRepo('note/src/test/List.test.ets');

check('Harmony pins all 23 dc5 locale/tag definitions and English fallback',
  /ORIGINAL_HANDWRITING_RECOGNITION_LANGUAGE_COUNT: number = 23/.test(policy) &&
  (policy.match(/localeCode: '/g) ?? []).length === 23 &&
  /localeCode: 'en_US', languageTag: 'en'/.test(policy) &&
  /DEFAULT_ENGLISH = 3/.test(policy));
check('Harmony keeps exact note and global lookup before locale fallback',
  /findOriginalHandwritingLanguage\(noteLanguage\)/.test(policy) &&
  /NOTE_REGISTER/.test(policy) && /findOriginalHandwritingLanguage\(globalLanguage\)/.test(policy) &&
  /GLOBAL_PREFERENCE/.test(policy) && /languageFromSystemLocale\(systemLocale\)/.test(policy));
check('Harmony reproduces Chinese Hant Hans and region selection',
  /locale\.script === 'Hant'/.test(policy) &&
  /locale\.script !== 'Hans'/.test(policy) &&
  /country === 'TW' \|\| country === 'HK' \|\| country === 'MO'/.test(policy));
check('Harmony maps tl in and both Norwegian locale aliases without broad guessing',
  /language === 'tl'[\s\S]*language = 'fil'/.test(policy) &&
  /language === 'in'[\s\S]*language = 'id'/.test(policy) &&
  /language === 'no' \|\| language === 'nn'[\s\S]*language = 'nb'/.test(policy) &&
  /language\.localeCode === value \|\| language\.languageTag === value/.test(policy));
check('language-aware provider receives localeCode and no provider stays unavailable',
  /recognizeText\(strokes: OriginalHandwritingRecognitionStroke\[\], localeCode: string\)/.test(recognition) &&
  /Promise<string \| null>/.test(recognition) &&
  /provider === null \|\| !provider\.isAvailable\(\) \|\| strokes\.length === 0/.test(recognition) &&
  /await provider\.recognizeText\(strokes, language\.localeCode\)/.test(recognition));
check('Harmony provider boundary preserves ordered stroke samples and force',
  /samples: OriginalHandwritingRecognitionSample\[\]/.test(recognition) &&
  /position: Point2D/.test(recognition) && /force: number/.test(recognition) &&
  /provider\.lastStrokes === selected/.test(fixture) &&
  /samples\[1\]\.force/.test(fixture));
check('legacy shape provider contract warns against masquerading as handwriting OCR',
  /生产手写 OCR 不得复用/.test(legacyProvider) &&
  /OriginalHandwritingRecognition/.test(legacyProvider));
check('ArkTS fixture covers priority locale aliases provider gate and localeCode handoff',
  /uses exact note then global language lookup/.test(fixture) &&
  /maps the original Chinese script and country branches/.test(fixture) &&
  /maps tl in no and nn/.test(fixture) &&
  /fails closed without a language-aware provider/.test(fixture) &&
  /passes ordered strokes force and dc5 localeCode/.test(fixture) &&
  /originalHandwritingRecognitionTest\(\)/.test(fixtureList));

const definitions = [
  ['de_DE', 'de'], ['en_US', 'en'], ['es_ES', 'es'], ['fr_FR', 'fr'],
  ['it_IT', 'it'], ['ja_JP', 'ja'], ['ko_KR', 'ko'], ['nl_NL', 'nl'],
  ['no_NO', 'nb'], ['pt_BR', 'pt'], ['ru_RU', 'ru'], ['tr_TR', 'tr'],
  ['zh_CN', 'zh-Hans'], ['zh_TW', 'zh-Hant'], ['th_TH', 'th'],
  ['fil_PH', 'fil'], ['id_ID', 'id'], ['ms_MY', 'ms'], ['pl_PL', 'pl'],
  ['sv_SE', 'sv'], ['uk_UA', 'uk'], ['vi_VN', 'vi'], ['da_DK', 'da'],
].map(([localeCode, languageTag]) => ({ localeCode, languageTag }));
const exact = value => definitions.find(item => item.localeCode === value || item.languageTag === value) ?? null;
function model(noteLanguage, globalLanguage, locale) {
  const note = noteLanguage === null ? null : exact(noteLanguage);
  if (note !== null) return { ...note, source: 'note' };
  const global = globalLanguage === null ? null : exact(globalLanguage);
  if (global !== null) return { ...global, source: 'global' };
  let localeTag = locale.language;
  if (localeTag === 'zh') {
    localeTag = locale.script === 'Hant' ||
      (locale.script !== 'Hans' && ['TW', 'HK', 'MO'].includes(locale.country)) ?
      'zh-Hant' : 'zh-Hans';
  } else if (localeTag === 'tl') {
    localeTag = 'fil';
  } else if (localeTag === 'in') {
    localeTag = 'id';
  } else if (localeTag === 'no' || localeTag === 'nn') {
    localeTag = 'nb';
  }
  const system = exact(localeTag);
  return system === null ? { ...exact('en'), source: 'default' } : { ...system, source: 'system' };
}

check('model keeps exact unsupported note values from overriding a valid global preference',
  model('en_GB', 'fr', { language: 'ja', script: '', country: '' }).localeCode === 'fr_FR');
check('model distinguishes Hant region fallback from explicit Hans',
  model(null, null, { language: 'zh', script: '', country: 'HK' }).localeCode === 'zh_TW' &&
  model(null, null, { language: 'zh', script: 'Hans', country: 'HK' }).localeCode === 'zh_CN');
check('model maps Java aliases and defaults an unsupported locale to English',
  model(null, null, { language: 'tl', script: '', country: '' }).localeCode === 'fil_PH' &&
  model(null, null, { language: 'in', script: '', country: '' }).localeCode === 'id_ID' &&
  model(null, null, { language: 'nn', script: '', country: '' }).localeCode === 'no_NO' &&
  model(null, null, { language: 'ar', script: '', country: '' }).source === 'default');

console.log(`D02_ORIGINAL_HANDWRITING_LANGUAGE_OK TOTAL=${total} FAILED=${failed}`);
if (failed > 0) process.exit(1);
