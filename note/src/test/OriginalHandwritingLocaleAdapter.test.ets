import { describe, expect, it } from '@ohos/hypium';
import { preferences } from '@kit.ArkData';
import {
  OriginalHandwritingSystemLocaleSource, parseOriginalHandwritingSystemLocale,
  readHarmonyOriginalHandwritingLocale,
} from '../main/ets/core/adaptation/OriginalHandwritingLocaleAdapter';
import {
  createOriginalHandwritingRecognitionContext,
  resolveProductionOriginalHandwritingLanguage,
} from '../main/ets/core/adaptation/OriginalHandwritingRecognitionContextAdapter';
import {
  OriginalHandwritingLanguagePreferenceStorage, OriginalHandwritingLanguagePreferenceTransaction,
} from '../main/ets/data/OriginalHandwritingLanguagePreferenceStore';
import {
  OriginalHandwritingProviderCompatibilityReason,
  evaluateHarmonyCoreVisionTextRecognitionCompatibility,
  evaluateOriginalHandwritingProviderCompatibility,
  harmonyCoreVisionTextRecognitionCapabilities,
} from '../main/ets/core/adaptation/OriginalHandwritingProviderCapabilityPolicy';
import { OriginalHandwritingLanguageSource } from '../main/ets/core/model/OriginalHandwritingLanguagePolicy';

class FakeLocaleSource implements OriginalHandwritingSystemLocaleSource {
  language: string;
  locale: string;
  fail: boolean;

  constructor(language: string, locale: string, fail: boolean = false) {
    this.language = language;
    this.locale = locale;
    this.fail = fail;
  }

  getSystemLanguage(): string {
    if (this.fail) {
      throw new Error('locale language unavailable');
    }
    return this.language;
  }

  getSystemLocale(): string {
    if (this.fail) {
      throw new Error('locale unavailable');
    }
    return this.locale;
  }
}

class FakePreferenceStorage implements OriginalHandwritingLanguagePreferenceStorage {
  present: boolean = false;
  value: preferences.ValueType = '';
  failFlush: boolean = false;
  failNextPut: boolean = false;
  failAllPuts: boolean = false;
  flushCount: number = 0;
  putCount: number = 0;

  async has(): Promise<boolean> {
    return this.present;
  }

  async read(): Promise<preferences.ValueType> {
    return this.value;
  }

  async put(value: preferences.ValueType): Promise<void> {
    this.putCount++;
    if (this.failAllPuts || this.failNextPut) {
      this.failNextPut = false;
      throw new Error('injected preference put failure');
    }
    this.present = true;
    this.value = value;
  }

  async remove(): Promise<void> {
    this.present = false;
    this.value = '';
  }

  async flush(): Promise<void> {
    this.flushCount++;
    if (this.failFlush) {
      throw new Error('injected preference flush failure');
    }
  }
}

class FakePreferenceReader {
  value: string | null;

  constructor(value: string | null) {
    this.value = value;
  }

  async getRecognitionLanguageId(): Promise<string | null> {
    return this.value;
  }
}

export default function originalHandwritingLocaleAdapterTest() {
  describe('OriginalHandwritingLocaleAdapter', () => {
    it('parses BCP-47 language, script and region for the original policy', 0, () => {
      const locale = parseOriginalHandwritingSystemLocale('zh', 'zh-Hant-TW');
      expect(locale.language).assertEqual('zh');
      expect(locale.script).assertEqual('Hant');
      expect(locale.country).assertEqual('TW');
      const english = parseOriginalHandwritingSystemLocale('en', 'en-US');
      expect(english.language).assertEqual('en');
      expect(english.script).assertEqual('');
      expect(english.country).assertEqual('US');
      const languageCarriesScript = parseOriginalHandwritingSystemLocale('zh-Hant', 'zh-TW');
      expect(languageCarriesScript.script).assertEqual('Hant');
    });

    it('fails closed on malformed or inconsistent platform values', 0, () => {
      const malformed = parseOriginalHandwritingSystemLocale('zh', 'zh_CN');
      expect(malformed.language).assertEqual('');
      expect(malformed.script).assertEqual('');
      const inconsistent = parseOriginalHandwritingSystemLocale('en', 'zh-CN');
      expect(inconsistent.language).assertEqual('');
      const conflictingScript = parseOriginalHandwritingSystemLocale(
        'zh-Hans', 'zh-Hant-TW');
      expect(conflictingScript.language).assertEqual('');
      const conflictingRegion = parseOriginalHandwritingSystemLocale(
        'en-US', 'en-GB');
      expect(conflictingRegion.language).assertEqual('');
      const unknownExtension = parseOriginalHandwritingSystemLocale(
        'en', 'en-US-x-private');
      expect(unknownExtension.language).assertEqual('');
      const failed = readHarmonyOriginalHandwritingLocale(new FakeLocaleSource('', '', true));
      expect(failed.language).assertEqual('');
      expect(failed.country).assertEqual('');
    });

    it('connects note, independent global preference and system locale in order', 0, async () => {
      const context = await createOriginalHandwritingRecognitionContext(
        { hasHandwritingLanguage: false, handwritingLanguage: null },
        new FakePreferenceReader('fr_FR'), new FakeLocaleSource('ja', 'ja-JP'));
      expect(context.globalLanguage).assertEqual('fr_FR');
      expect(context.systemLocale.language).assertEqual('ja');
      const resolved = await resolveProductionOriginalHandwritingLanguage(
        { hasHandwritingLanguage: false, handwritingLanguage: null },
        new FakePreferenceReader('fr_FR'), new FakeLocaleSource('ja', 'ja-JP'));
      expect(resolved.localeCode).assertEqual('fr_FR');
      expect(resolved.source).assertEqual(OriginalHandwritingLanguageSource.GLOBAL_PREFERENCE);
    });

    it('canonicalizes preference values to dc5.I and rolls back a failed flush', 0, async () => {
      const storage = new FakePreferenceStorage();
      const transaction = new OriginalHandwritingLanguagePreferenceTransaction(storage);
      await transaction.saveRecognitionLanguageId('zh-Hant');
      expect(storage.value).assertEqual('zh_TW');
      expect(await transaction.getRecognitionLanguageId()).assertEqual('zh_TW');
      storage.failFlush = true;
      let failed: boolean = false;
      try {
        await transaction.saveRecognitionLanguageId('de_DE');
      } catch (_error) {
        failed = true;
      }
      expect(failed).assertTrue();
      expect(storage.value).assertEqual('zh_TW');
      expect(storage.flushCount).assertEqual(3);
    });

    it('compensates a put failure before flush', 0, async () => {
      const storage = new FakePreferenceStorage();
      const transaction = new OriginalHandwritingLanguagePreferenceTransaction(storage);
      await transaction.saveRecognitionLanguageId('en_US');
      storage.failNextPut = true;
      let failed: boolean = false;
      try {
        await transaction.saveRecognitionLanguageId('de_DE');
      } catch (_error) {
        failed = true;
      }
      expect(failed).assertTrue();
      expect(storage.value).assertEqual('en_US');
      expect(storage.flushCount).assertEqual(2);
      expect(storage.putCount).assertEqual(3);
    });

    it('does not flush an unknown value after rollback mutation fails', 0, async () => {
      const storage = new FakePreferenceStorage();
      const transaction = new OriginalHandwritingLanguagePreferenceTransaction(storage);
      await transaction.saveRecognitionLanguageId('en_US');
      storage.failAllPuts = true;
      let failed: boolean = false;
      try {
        await transaction.saveRecognitionLanguageId('de_DE');
      } catch (_error) {
        failed = true;
      }
      expect(failed).assertTrue();
      expect(storage.flushCount).assertEqual(1);
      expect(storage.putCount).assertEqual(3);
    });

    it('keeps CoreVision image OCR outside the original stroke provider contract', 0, () => {
      const absent = evaluateHarmonyCoreVisionTextRecognitionCompatibility(
        (_syscap: string): boolean => false);
      expect(absent.compatible).assertFalse();
      expect(absent.reason).assertEqual(
        OriginalHandwritingProviderCompatibilityReason.SYSTEM_CAPABILITY_UNAVAILABLE);
      const present = evaluateOriginalHandwritingProviderCompatibility(
        harmonyCoreVisionTextRecognitionCapabilities(true));
      expect(present.compatible).assertFalse();
      expect(present.reason).assertEqual(
        OriginalHandwritingProviderCompatibilityReason.INPUT_IS_NOT_STROKE_NATIVE);
    });
  });
}
