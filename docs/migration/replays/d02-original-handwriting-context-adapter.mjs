import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const originalRoot = process.env.NOTABILITY_ORIGINAL_ROOT ??
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const sdkRoot = process.env.HARMONY_SDK_ROOT ??
  'C:/Program Files/Huawei/DevEco Studio/sdk/default';
const apiReferenceRoot = process.env.HARMONY_API_REFERENCE_ROOT ??
  'C:/Program Files/Huawei/DevEco Studio/plugins/openharmony/ohos-info-center-view/static/hos/JsEtsAPIReference';
const read = file => fs.readFileSync(file, 'utf8').replaceAll('\r\n', '\n');
const readRepo = relative => read(path.join(root, relative));
const readOriginal = name => read(path.join(originalRoot, name));
const hash = file => crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex').toUpperCase();
const hashOriginal = name => hash(path.join(originalRoot, name));
const hashSdk = relative => hash(path.join(sdkRoot, relative));
const readApiReference = name => read(path.join(apiReferenceRoot, name));
const hashApiReference = name => hash(path.join(apiReferenceRoot, name));

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

const kc5 = readOriginal('kc5.java');
const xr = readOriginal('xr.java');
const tc = readOriginal('tc.java');
const fr2 = readOriginal('fr2.java');
const localizationReference = readApiReference('zh-cn_topic_0000002443438060.html');
const coreVisionReference = readApiReference('zh-cn_topic_0000002336126650.html');
const policy = readRepo('note/src/main/ets/core/model/OriginalHandwritingLanguagePolicy.ets');
const locale = readRepo('note/src/main/ets/core/adaptation/OriginalHandwritingLocaleAdapter.ets');
const context = readRepo(
  'note/src/main/ets/core/adaptation/OriginalHandwritingRecognitionContextAdapter.ets');
const capability = readRepo(
  'note/src/main/ets/core/adaptation/OriginalHandwritingProviderCapabilityPolicy.ets');
const store = readRepo('note/src/main/ets/data/OriginalHandwritingLanguagePreferenceStore.ets');
const fixture = readRepo('note/src/test/OriginalHandwritingLocaleAdapter.test.ets');
const fixtureList = readRepo('note/src/test/List.test.ets');
const evidence = readRepo(
  'docs/migration/evidence/original-handwriting-context-adapter-jadx-sdk-2026-08-21.md');

check('original preference store name and key are pinned',
  /handwritingRecognitionSettings/.test(xr) && /recognitionLanguageId/.test(kc5));
check('original writer passes dc5.I to tc case 8',
  /fr2 JADX debug extraction: dc5\.I/.test(evidence) &&
  /tc\.init\(dc5\.I, 1\)/.test(evidence) &&
  /case 8:[\s\S]*tk8Var\.g\(euaVar, str\)/.test(tc));
check('original preference evidence hashes are pinned',
  hashOriginal('kc5.java') === '6C925C4479BFFEC7AA63E38167F31D7EE84CF06049A80F27674D5953C296FC42' &&
  hashOriginal('xr.java') === '0EB15420675CF64EC233DEC92D045E2475E3FCF99FBE7FC8CE1586C0FC1BD508' &&
  hashOriginal('tc.java') === '8650967C0CFC023E6225189828D46D41CF11F96D5C57909BDC59CBD303B30296' &&
  hashOriginal('fr2.java') === '475B1A29C71087E301177A4892A805E0B6C71BC37432E66733568495C7F8096D');
check('SDK evidence hashes are pinned',
  hashSdk('openharmony/ets/api/@ohos.data.preferences.d.ts') ===
    'ECF87866737F825A33397D08E0DEDCBE7681F74D5CC5334301BD124A302FDD32' &&
  hashSdk('openharmony/ets/api/@ohos.i18n.d.ts') ===
    '39434D03217E7504AC485FE8527663B3791941C4127EAEAC43F3F6F2F033F48C' &&
  hashSdk('openharmony/ets/kits/@kit.LocalizationKit.d.ts') ===
    '033815E17D5407B7C2C03E85C801120A4696DDDC9EC56798EA31375FE33ABB60' &&
  hashSdk('hms/ets/api/@hms.ai.ocr.textRecognition.d.ts') ===
    '4505242C5D3DF76A0A93176A0EB4A4AEA6454E4D2D359A500A48D0D275E2973C');
check('DevEco offline API reference hashes are pinned',
  hashApiReference('zh-cn_topic_0000002443438060.html') ===
    'E9B5DF5B923771AEFB1A0C814513F7E2157C9625E80772A3CAC064897BAAF7EA' &&
  hashApiReference('zh-cn_topic_0000002336126650.html') ===
    '64DD51D97FC1E64554D5E66058C9FC9DDC4084889176E787B547B3770B590908');
check('offline references pin official locale and CoreVision image semantics',
  /zh-Hans-CN/.test(localizationReference) &&
  /RGBA_8888/.test(coreVisionReference) &&
  /PixelMap/.test(coreVisionReference) &&
  /票据、卡证、表格/.test(coreVisionReference) &&
  /textRecognition\.recognizeText/.test(coreVisionReference));
check('Harmony keeps the original independent store and exact key',
  /ORIGINAL_HANDWRITING_LANGUAGE_PREFERENCE_STORE_NAME: string =\s*'handwritingRecognitionSettings'/.test(store) &&
  /ORIGINAL_HANDWRITING_LANGUAGE_PREFERENCE_KEY: string =\s*'recognitionLanguageId'/.test(store));
check('Harmony writes canonical dc5.I, not dc5.J',
  /originalHandwritingRecognitionLocaleCode\(value\)/.test(store) &&
  /await this\.storage\.put\(localeCode\)/.test(store));
check('preference reads reject wrong types and unknown values',
  /typeof raw !== 'string'/.test(store) &&
  /return originalHandwritingRecognitionLocaleCode\(raw\)/.test(store) &&
  /unsupported/.test(store));
check('preference writes compensate a failed flush',
  /hadPrevious/.test(store) && /commit and rollback failed/.test(store) &&
  /await this\.storage\.flush\(\)/.test(store) &&
  /await this\.storage\.put\(localeCode\)/.test(store) &&
  /rollbackMutationSucceeded/.test(store) &&
  /if \(rollbackMutationSucceeded\)/.test(store));
check('preference storage reuses one Harmony Preferences instance',
  /private storePromise: Promise<preferences\.Preferences> \| null = null/.test(store) &&
  /private async getStore\(\): Promise<preferences\.Preferences>/.test(store) &&
  /this\.storePromise = preferences\.getPreferences/.test(store) &&
  /await this\.getStore\(\)/.test(store));
check('Locale source uses LocalizationKit system APIs',
  /import \{ i18n \} from '@kit\.LocalizationKit'/.test(locale) &&
  /i18n\.System\.getSystemLanguage\(\)/.test(locale) &&
  /i18n\.System\.getSystemLocale\(\)/.test(locale));
check('Locale parsing is pure and BCP-47 based',
  /parseOriginalHandwritingSystemLocale/.test(locale) &&
  /value\.includes\('_'\)/.test(locale) && /titleCaseScript/.test(locale));
check('Locale adapter fails closed on platform exceptions and inconsistent values',
  /catch \(_error\)/.test(locale) && /return emptyOriginalLocale\(\)/.test(locale) &&
  /languageLocale\.language !== locale\.language/.test(locale) &&
  /fieldsConflict\(languageLocale\.script, locale\.script\)/.test(locale) &&
  /fieldsConflict\(languageLocale\.country, locale\.country\)/.test(locale) &&
  /return null;/.test(locale) && /unknownExtension/.test(fixture));
check('production context reads the independent global preference',
  /getRecognitionLanguageId\(\): Promise<string \| null>/.test(context) &&
  /globalLanguage: await preference\.getRecognitionLanguageId\(\)/.test(context));
check('production context reads the note register through existing metadata state',
  /readOriginalNoteMetadataState/.test(context) &&
  /hasHandwritingLanguage/.test(context) && /noteLanguage: note\.hasHandwritingLanguage/.test(context));
check('CoreVision capability policy names the documented OCR syscap',
  /SystemCapability\.AI\.OCR\.TextRecognition/.test(capability) &&
  /HARMONY_CORE_VISION_DOCUMENTED_LANGUAGE_IDS/.test(capability));
check('CoreVision is rejected for non-stroke input and missing per-call language lock',
  /acceptsOrderedPointerStrokes: false/.test(capability) &&
  /preservesForce: false/.test(capability) &&
  /supportsPerCallLocaleCode: false/.test(capability) &&
  /supportedLocaleCodes: \[\]/.test(capability) &&
  /INPUT_IS_NOT_STROKE_NATIVE/.test(capability));
check('capability probe is injected and replayable',
  /evaluateHarmonyCoreVisionTextRecognitionCompatibility/.test(capability) &&
  /capabilityProbe\(HARMONY_CORE_VISION_TEXT_RECOGNITION_SYSCAP\)/.test(capability));
check('ArkTS fixture covers malformed locale, preference rollback and capability gate',
  /fails closed on malformed or inconsistent/.test(fixture) &&
  /rolls back a failed flush/.test(fixture) &&
  /compensates a put failure before flush/.test(fixture) &&
  /does not flush an unknown value after rollback mutation fails/.test(fixture) &&
  /keeps CoreVision image OCR outside/.test(fixture));
check('fixture is registered in the test suite',
  /import originalHandwritingLocaleAdapterTest/.test(fixtureList) &&
  /originalHandwritingLocaleAdapterTest\(\)/.test(fixtureList));
check('evidence records the exact original and SDK sources',
  /kc5\.java/.test(evidence) && /fr2\.java/.test(evidence) &&
  /@kit\.LocalizationKit\.d\.ts/.test(evidence) &&
  /@hms\.ai\.ocr\.textRecognition\.d\.ts/.test(evidence));

console.log(`D02_ORIGINAL_HANDWRITING_CONTEXT_OK TOTAL=${total} FAILED=${failed}`);
if (failed > 0) {
  process.exit(1);
}
