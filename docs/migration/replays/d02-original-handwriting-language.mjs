// Phase 567 — original handwriting recognition language setting.
// Original evidence: x22 case 5 renders feature_settings__language inside the
// Handwriting & Drawing subsection (after straight_lines / shapes_detection /
// palm_detection / auto_deselect_eraser / ruler_units). pb5 case 0 renders the
// row's trailing value as the current dc5 language display name via
// uy7.b0(dc5Var, map); vmc is the picker screen listing all dc5 languages.
// Harmony landing: a Language row under the handwriting block shows the
// effective recognition language and opens a 23-option picker persisted via
// the already-ported OriginalHandwritingLanguagePreferenceStore (dc5.I
// localeCode — the same value the recognition pipeline resolves).
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const settings = readFileSync('note/src/main/ets/ui/settings/SettingsPage.ets', 'utf8');
const policy = readFileSync('note/src/main/ets/core/model/OriginalHandwritingLanguagePolicy.ets', 'utf8');
const baseJson = JSON.parse(readFileSync('note/src/main/resources/base/element/string.json', 'utf8'));
const zhJson = JSON.parse(readFileSync('note/src/main/resources/zh_CN/element/string.json', 'utf8'));
const baseVal = n => baseJson.string.find(e => e.name === n)?.value;
const zhVal = n => zhJson.string.find(e => e.name === n)?.value;

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- Strings ---
check(baseVal('language') === 'Language', 'language EN');
check(baseVal('handwriting_language_caption') ===
  'Handwriting language is used to improve recognition and search of your handwritten notes.',
  'caption EN verbatim');
check(zhVal('language')?.length > 0, 'language zh');
check(zhVal('handwriting_language_caption')?.length > 0, 'caption zh');

// --- Policy surface ---
check(policy.includes('originalHandwritingRecognitionLanguageOptions'),
  'options enumerator exported');
check(policy.includes('originalHandwritingLanguageDisplayName'),
  'display-name resolver exported');
check(/localeCode: 'de_DE', languageTag: 'de', displayName: 'Deutsch'/.test(policy),
  'dc5 order start + native name');
check(/localeCode: 'da_DK', languageTag: 'da', displayName: 'Dansk'/.test(policy),
  'dc5 order end + native name');
check((policy.match(/localeCode: '/g) || []).length === 23, 'all 23 dc5 languages');

// --- SettingsPage wiring ---
check(settings.includes("$r('app.string.language')"), 'row label');
check(settings.includes("$r('app.string.handwriting_language_caption')"), 'row caption');
check(settings.includes('OriginalHandwritingLanguagePreferenceStore'), 'store import');
check(settings.includes('getRecognitionLanguageId()'), 'load stored language');
check(settings.includes('resolveOriginalHandwritingLanguage('), 'effective resolution');
check(settings.includes('readHarmonyOriginalHandwritingLocale()'), 'system locale adapter');
check(settings.includes('originalHandwritingLanguageDisplayName(this.recognitionLanguageCode)'),
  'trailing current language name');
check(settings.includes('this.languageDialog.open()'), 'row opens picker');
check(settings.includes('HandwritingLanguageDialog'), 'picker dialog bound');
check(/setRecognitionLanguage\(localeCode: string\)[\s\S]{0,900}saveRecognitionLanguageId\(localeCode\)/.test(settings),
  'save path');
check(/setRecognitionLanguage[\s\S]{0,1200}this\.recognitionLanguageCode = previous/.test(settings),
  'rollback on save failure');
check(settings.includes('editor_setting_save_failed'), 'save-failure toast');
// original order: language row after auto_deselect_eraser (ruler_units absent)
check(settings.indexOf("$r('app.string.language')") >
  settings.indexOf("$r('app.string.auto_deselect_eraser')"), 'x22 row order');

// --- Picker dialog ---
const dialog = settings.slice(settings.indexOf('struct HandwritingLanguageDialog'));
check(dialog.includes('ForEach(this.options'), 'lists all options');
check(dialog.includes('option.localeCode === this.selected'), 'selected check');
check(dialog.includes('this.onPick(option.localeCode)'), 'pick callback');
check(dialog.includes('originalHandwritingRecognitionLanguageOptions()'), 'dc5-order options');

console.log(`TOTAL=${n}`);
