// Original Notability 1.0.3 dc5/sh8 handwriting recognition language policy.
// Pure logic only: platform locale APIs must be adapted into OriginalLocaleLanguage
// before entering this module.

export const ORIGINAL_HANDWRITING_RECOGNITION_LANGUAGE_COUNT: number = 23;
export const ORIGINAL_HANDWRITING_DEFAULT_LOCALE_CODE: string = 'en_US';
export const ORIGINAL_HANDWRITING_DEFAULT_LANGUAGE_TAG: string = 'en';

export enum OriginalHandwritingLanguageSource {
  NOTE_REGISTER = 0,
  GLOBAL_PREFERENCE = 1,
  SYSTEM_LOCALE = 2,
  DEFAULT_ENGLISH = 3,
}

export interface OriginalLocaleLanguage {
  language: string;
  script: string;
  country: string;
}

export interface OriginalHandwritingLanguageResolution {
  // dc5.I: this exact value is written to MyScript's lang/recognizer.lang.
  localeCode: string;
  // dc5.J: canonical language tag used by the original lookup/fallback logic.
  languageTag: string;
  source: OriginalHandwritingLanguageSource;
}

interface OriginalHandwritingLanguageDefinition {
  localeCode: string;
  languageTag: string;
  // The original reads each row's label from the downloaded MyScript pack
  // metadata (gg1.h via boh.c); these are the native display names those
  // packs ship, kept in the exact dc5 enum order.
  displayName: string;
}

// Exact dc5 enum order and values. sh8.B compares the input against either
// localeCode or languageTag without case folding or region inference.
const ORIGINAL_HANDWRITING_LANGUAGES: OriginalHandwritingLanguageDefinition[] = [
  { localeCode: 'de_DE', languageTag: 'de', displayName: 'Deutsch' },
  { localeCode: 'en_US', languageTag: 'en', displayName: 'English (US)' },
  { localeCode: 'es_ES', languageTag: 'es', displayName: 'Español' },
  { localeCode: 'fr_FR', languageTag: 'fr', displayName: 'Français' },
  { localeCode: 'it_IT', languageTag: 'it', displayName: 'Italiano' },
  { localeCode: 'ja_JP', languageTag: 'ja', displayName: '日本語' },
  { localeCode: 'ko_KR', languageTag: 'ko', displayName: '한국어' },
  { localeCode: 'nl_NL', languageTag: 'nl', displayName: 'Nederlands' },
  { localeCode: 'no_NO', languageTag: 'nb', displayName: 'Norsk bokmål' },
  { localeCode: 'pt_BR', languageTag: 'pt', displayName: 'Português (Brasil)' },
  { localeCode: 'ru_RU', languageTag: 'ru', displayName: 'Русский' },
  { localeCode: 'tr_TR', languageTag: 'tr', displayName: 'Türkçe' },
  { localeCode: 'zh_CN', languageTag: 'zh-Hans', displayName: '简体中文' },
  { localeCode: 'zh_TW', languageTag: 'zh-Hant', displayName: '繁體中文' },
  { localeCode: 'th_TH', languageTag: 'th', displayName: 'ไทย' },
  { localeCode: 'fil_PH', languageTag: 'fil', displayName: 'Filipino' },
  { localeCode: 'id_ID', languageTag: 'id', displayName: 'Bahasa Indonesia' },
  { localeCode: 'ms_MY', languageTag: 'ms', displayName: 'Bahasa Melayu' },
  { localeCode: 'pl_PL', languageTag: 'pl', displayName: 'Polski' },
  { localeCode: 'sv_SE', languageTag: 'sv', displayName: 'Svenska' },
  { localeCode: 'uk_UA', languageTag: 'uk', displayName: 'Українська' },
  { localeCode: 'vi_VN', languageTag: 'vi', displayName: 'Tiếng Việt' },
  { localeCode: 'da_DK', languageTag: 'da', displayName: 'Dansk' },
];

export function isOriginalHandwritingRecognitionLanguage(value: string): boolean {
  return findOriginalHandwritingLanguage(value) !== null;
}

// Original vmc language-picker rows: every dc5 language in enum order with
// the pack-native display name shown as the row label (pb5 case 0).
export interface OriginalHandwritingLanguageOption {
  localeCode: string;
  languageTag: string;
  displayName: string;
}

export function originalHandwritingRecognitionLanguageOptions():
  OriginalHandwritingLanguageOption[] {
  return ORIGINAL_HANDWRITING_LANGUAGES.map(
    (language: OriginalHandwritingLanguageDefinition): OriginalHandwritingLanguageOption => ({
      localeCode: language.localeCode,
      languageTag: language.languageTag,
      displayName: language.displayName,
    }));
}

export function originalHandwritingLanguageDisplayName(localeCode: string): string {
  const language: OriginalHandwritingLanguageDefinition | null =
    findOriginalHandwritingLanguage(localeCode);
  return language === null ? localeCode : language.displayName;
}

// The original global kc5/fr2 path persists dc5.I, never dc5.J. Keeping the
// canonicalization here lets the preference boundary accept either exact
// lookup form without ever writing a language tag such as zh-Hant.
export function originalHandwritingRecognitionLocaleCode(value: string | null): string | null {
  const language: OriginalHandwritingLanguageDefinition | null =
    findOriginalHandwritingLanguage(value);
  return language === null ? null : language.localeCode;
}

// Mirrors jc5.e + sh8.D. A non-null but unsupported note/global value is not
// guessed into a nearby locale; the original simply continues to the next source.
export function resolveOriginalHandwritingLanguage(noteLanguage: string | null,
  globalLanguage: string | null,
  systemLocale: OriginalLocaleLanguage): OriginalHandwritingLanguageResolution {
  const note: OriginalHandwritingLanguageDefinition | null =
    findOriginalHandwritingLanguage(noteLanguage);
  if (note !== null) {
    return resolution(note, OriginalHandwritingLanguageSource.NOTE_REGISTER);
  }
  const global: OriginalHandwritingLanguageDefinition | null =
    findOriginalHandwritingLanguage(globalLanguage);
  if (global !== null) {
    return resolution(global, OriginalHandwritingLanguageSource.GLOBAL_PREFERENCE);
  }
  const locale: OriginalHandwritingLanguageDefinition | null =
    languageFromSystemLocale(systemLocale);
  if (locale !== null) {
    return resolution(locale, OriginalHandwritingLanguageSource.SYSTEM_LOCALE);
  }
  const fallback: OriginalHandwritingLanguageDefinition = ORIGINAL_HANDWRITING_LANGUAGES[1];
  return resolution(fallback, OriginalHandwritingLanguageSource.DEFAULT_ENGLISH);
}

function findOriginalHandwritingLanguage(value: string | null):
  OriginalHandwritingLanguageDefinition | null {
  if (value === null) {
    return null;
  }
  for (const language of ORIGINAL_HANDWRITING_LANGUAGES) {
    if (language.localeCode === value || language.languageTag === value) {
      return language;
    }
  }
  return null;
}

function languageFromSystemLocale(locale: OriginalLocaleLanguage):
  OriginalHandwritingLanguageDefinition | null {
  if (locale.language === 'zh') {
    if (locale.script === 'Hant' ||
      (locale.script !== 'Hans' && isTraditionalChineseCountry(locale.country))) {
      return findOriginalHandwritingLanguage('zh-Hant');
    }
    return findOriginalHandwritingLanguage('zh-Hans');
  }
  let language: string = locale.language;
  if (language === 'tl') {
    language = 'fil';
  } else if (language === 'in') {
    language = 'id';
  } else if (language === 'no' || language === 'nn') {
    language = 'nb';
  }
  return findOriginalHandwritingLanguage(language);
}

function isTraditionalChineseCountry(country: string): boolean {
  return country === 'TW' || country === 'HK' || country === 'MO';
}

function resolution(language: OriginalHandwritingLanguageDefinition,
  source: OriginalHandwritingLanguageSource): OriginalHandwritingLanguageResolution {
  return {
    localeCode: language.localeCode,
    languageTag: language.languageTag,
    source: source,
  };
}
