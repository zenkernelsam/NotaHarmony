import { describe, expect, it } from '@ohos/hypium';
import { Point2D } from '../main/ets/core/model/GeometryTypes';
import {
  OriginalHandwritingLanguageSource, resolveOriginalHandwritingLanguage,
} from '../main/ets/core/model/OriginalHandwritingLanguagePolicy';
import {
  OriginalHandwritingRecognitionContext, OriginalHandwritingRecognitionProvider,
  OriginalHandwritingRecognitionStroke, recognizeOriginalHandwritingText,
} from '../main/ets/core/adaptation/OriginalHandwritingRecognition';

class FakeHandwritingProvider implements OriginalHandwritingRecognitionProvider {
  available: boolean;
  result: string | null;
  calls: number = 0;
  lastLocaleCode: string = '';
  lastStrokes: OriginalHandwritingRecognitionStroke[] = [];

  constructor(available: boolean, result: string | null) {
    this.available = available;
    this.result = result;
  }

  isAvailable(): boolean {
    return this.available;
  }

  async recognizeText(strokes: OriginalHandwritingRecognitionStroke[], localeCode: string):
    Promise<string | null> {
    this.calls++;
    this.lastLocaleCode = localeCode;
    this.lastStrokes = strokes;
    return this.result;
  }
}

export default function originalHandwritingRecognitionTest() {
  describe('OriginalHandwritingRecognition', () => {
    it('uses exact note then global language lookup before the system locale', 0, () => {
      const note = resolveOriginalHandwritingLanguage('zh_TW', 'de_DE', locale('en'));
      expect(note.localeCode).assertEqual('zh_TW');
      expect(note.languageTag).assertEqual('zh-Hant');
      expect(note.source).assertEqual(OriginalHandwritingLanguageSource.NOTE_REGISTER);

      // en_GB passes the metadata ISO-prefix validator but is not a dc5 entry;
      // sh8.B therefore continues to the global preference without guessing.
      const global = resolveOriginalHandwritingLanguage('en_GB', 'fr', locale('ja'));
      expect(global.localeCode).assertEqual('fr_FR');
      expect(global.source).assertEqual(OriginalHandwritingLanguageSource.GLOBAL_PREFERENCE);
    });

    it('maps the original Chinese script and country branches', 0, () => {
      const hant = resolveOriginalHandwritingLanguage(null, null, locale('zh', 'Hant', 'CN'));
      expect(hant.localeCode).assertEqual('zh_TW');
      const regional = resolveOriginalHandwritingLanguage(null, null, locale('zh', '', 'HK'));
      expect(regional.languageTag).assertEqual('zh-Hant');
      const explicitHans = resolveOriginalHandwritingLanguage(null, null, locale('zh', 'Hans', 'HK'));
      expect(explicitHans.localeCode).assertEqual('zh_CN');
    });

    it('maps tl in no and nn then defaults unsupported locales to English', 0, () => {
      expect(resolveOriginalHandwritingLanguage(null, null, locale('tl')).localeCode)
        .assertEqual('fil_PH');
      expect(resolveOriginalHandwritingLanguage(null, null, locale('in')).localeCode)
        .assertEqual('id_ID');
      expect(resolveOriginalHandwritingLanguage(null, null, locale('no')).localeCode)
        .assertEqual('no_NO');
      expect(resolveOriginalHandwritingLanguage(null, null, locale('nn')).localeCode)
        .assertEqual('no_NO');
      const fallback = resolveOriginalHandwritingLanguage(null, null, locale('ar'));
      expect(fallback.localeCode).assertEqual('en_US');
      expect(fallback.source).assertEqual(OriginalHandwritingLanguageSource.DEFAULT_ENGLISH);
    });

    it('fails closed without a language-aware provider or selected strokes', 0, async () => {
      const unavailable = new FakeHandwritingProvider(false, 'ignored');
      expect((await recognizeOriginalHandwritingText(unavailable, strokes(), context())) === null)
        .assertTrue();
      expect(unavailable.calls).assertEqual(0);
      const available = new FakeHandwritingProvider(true, 'ignored');
      expect((await recognizeOriginalHandwritingText(available, [], context())) === null).assertTrue();
      expect(available.calls).assertEqual(0);
      expect((await recognizeOriginalHandwritingText(null, strokes(), context())) === null)
        .assertTrue();
    });

    it('passes ordered strokes force and dc5 localeCode to the async provider', 0, async () => {
      const selected: OriginalHandwritingRecognitionStroke[] = strokes();
      const provider = new FakeHandwritingProvider(true, 'hello');
      const result = await recognizeOriginalHandwritingText(provider, selected, {
        noteLanguage: 'zh-Hant', globalLanguage: 'en_US', systemLocale: locale('en'),
      });
      expect(result?.text).assertEqual('hello');
      expect(result?.localeCode).assertEqual('zh_TW');
      expect(result?.languageTag).assertEqual('zh-Hant');
      expect(provider.lastLocaleCode).assertEqual('zh_TW');
      expect(provider.lastStrokes === selected).assertTrue();
      expect(provider.lastStrokes.length).assertEqual(2);
      expect(provider.lastStrokes[0].samples[1].force).assertEqual(0.75);
      expect(provider.lastStrokes[1].samples[0].position.x).assertEqual(9);

      const empty = new FakeHandwritingProvider(true, '');
      expect((await recognizeOriginalHandwritingText(empty, selected, context()))?.text).assertEqual('');
      const noResult = new FakeHandwritingProvider(true, null);
      expect((await recognizeOriginalHandwritingText(noResult, selected, context())) === null).assertTrue();
    });
  });
}

function locale(language: string, script: string = '', country: string = '') {
  return { language: language, script: script, country: country };
}

function context(): OriginalHandwritingRecognitionContext {
  return {
    noteLanguage: null,
    globalLanguage: null,
    systemLocale: locale('en'),
  };
}

function strokes(): OriginalHandwritingRecognitionStroke[] {
  return [
    { samples: [
      { position: point(1, 2), force: 0.5 },
      { position: point(3, 4), force: 0.75 },
    ] },
    { samples: [{ position: point(9, 8), force: -1 }] },
  ];
}

function point(x: number, y: number): Point2D {
  return { x: x, y: y };
}
