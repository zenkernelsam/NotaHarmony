// Harmony system language/locale adapter for the original Java Locale policy.
// Parsing stays pure so malformed platform values can be replayed without a
// device. Unknown or invalid fields are deliberately empty; the existing
// policy then falls back to a recognized locale or English.
import { i18n } from '@kit.LocalizationKit';
import { OriginalLocaleLanguage } from '../model/OriginalHandwritingLanguagePolicy';

const EMPTY_ORIGINAL_LOCALE: OriginalLocaleLanguage = {
  language: '',
  script: '',
  country: '',
};

export interface OriginalHandwritingSystemLocaleSource {
  getSystemLanguage(): string;
  getSystemLocale(): string;
}

export class HarmonyOriginalHandwritingSystemLocaleSource implements
  OriginalHandwritingSystemLocaleSource {
  getSystemLanguage(): string {
    return i18n.System.getSystemLanguage();
  }

  getSystemLocale(): string {
    return i18n.System.getSystemLocale();
  }
}

export function readHarmonyOriginalHandwritingLocale(
  source: OriginalHandwritingSystemLocaleSource =
    new HarmonyOriginalHandwritingSystemLocaleSource()): OriginalLocaleLanguage {
  try {
    return parseOriginalHandwritingSystemLocale(
      source.getSystemLanguage(), source.getSystemLocale());
  } catch (_error) {
    return emptyOriginalLocale();
  }
}

export function parseOriginalHandwritingSystemLocale(systemLanguage: string,
  systemLocale: string): OriginalLocaleLanguage {
  const languageLocale: OriginalLocaleLanguage | null = parsedLocale(systemLanguage);
  const locale: OriginalLocaleLanguage | null = parsedLocale(systemLocale);
  if (languageLocale === null || locale === null ||
    languageLocale.language !== locale.language ||
    fieldsConflict(languageLocale.script, locale.script) ||
    fieldsConflict(languageLocale.country, locale.country)) {
    return emptyOriginalLocale();
  }
  return {
    language: locale.language,
    script: locale.script.length > 0 ? locale.script : languageLocale.script,
    country: locale.country.length > 0 ? locale.country : languageLocale.country,
  };
}

function fieldsConflict(left: string, right: string): boolean {
  return left.length > 0 && right.length > 0 && left !== right;
}

function parsedLocale(value: string): OriginalLocaleLanguage | null {
  const parts: string[] | null = localeParts(value);
  if (parts === null) {
    return null;
  }
  let script: string = '';
  let country: string = '';
  for (let index: number = 1; index < parts.length; index++) {
    const part: string = parts[index];
    if (/^[A-Za-z]{4}$/.test(part)) {
      if (script.length > 0) {
        return null;
      }
      script = titleCaseScript(part);
    } else if (/^([A-Za-z]{2}|[0-9]{3})$/.test(part)) {
      if (country.length > 0) {
        return null;
      }
      country = part.toUpperCase();
    } else {
      // The production adapter only needs the language/script/region shape
      // exposed by LocalizationKit. Do not silently discard BCP-47 variant,
      // extension or private-use subtags and then resolve a guessed locale.
      return null;
    }
  }
  return { language: parts[0], script: script, country: country };
}

function localeParts(value: string): string[] | null {
  if (value.length === 0 || value !== value.trim() || value.includes('_') ||
    !/^[A-Za-z]{2,8}(?:-[A-Za-z0-9]{1,8})*$/.test(value)) {
    return null;
  }
  const parts: string[] = value.split('-');
  parts[0] = parts[0].toLowerCase();
  return parts;
}

function titleCaseScript(value: string): string {
  return value.slice(0, 1).toUpperCase() + value.slice(1).toLowerCase();
}

function emptyOriginalLocale(): OriginalLocaleLanguage {
  return {
    language: EMPTY_ORIGINAL_LOCALE.language,
    script: EMPTY_ORIGINAL_LOCALE.script,
    country: EMPTY_ORIGINAL_LOCALE.country,
  };
}
