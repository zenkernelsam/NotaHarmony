// Language-aware handwriting OCR boundary derived from original jc5/hc5/pm8.
// The project currently has no production OCR provider. Callers must therefore
// pass null/unavailable and receive null instead of silently using ShapeDetector.
import { Point2D } from '../model/GeometryTypes';
import {
  OriginalHandwritingLanguageResolution, OriginalHandwritingLanguageSource,
  OriginalLocaleLanguage, resolveOriginalHandwritingLanguage,
} from '../model/OriginalHandwritingLanguagePolicy';

export interface OriginalHandwritingRecognitionSample {
  position: Point2D;
  force: number;
}

export interface OriginalHandwritingRecognitionStroke {
  // pm8 emits a separate pointer down/move/up sequence for every selected Ink.
  // Callers must provide page-space samples without flattening stroke boundaries.
  samples: OriginalHandwritingRecognitionSample[];
}

export interface OriginalHandwritingRecognitionProvider {
  isAvailable(): boolean;
  // pm8 is a coroutine, preserves per-stroke force, and configures MyScript with
  // dc5.I (for example zh_TW), not dc5.J.
  recognizeText(strokes: OriginalHandwritingRecognitionStroke[], localeCode: string):
    Promise<string | null>;
}

export interface OriginalHandwritingRecognitionContext {
  noteLanguage: string | null;
  globalLanguage: string | null;
  systemLocale: OriginalLocaleLanguage;
}

export interface OriginalHandwritingRecognitionResult {
  text: string;
  localeCode: string;
  languageTag: string;
  languageSource: OriginalHandwritingLanguageSource;
}

export async function recognizeOriginalHandwritingText(
  provider: OriginalHandwritingRecognitionProvider | null,
  strokes: OriginalHandwritingRecognitionStroke[], context: OriginalHandwritingRecognitionContext):
  Promise<OriginalHandwritingRecognitionResult | null> {
  // hc5 avoids invoking the recognizer for an empty selection. Harmony also
  // fails closed when no language-aware provider is installed.
  if (provider === null || !provider.isAvailable() || strokes.length === 0) {
    return null;
  }
  const language: OriginalHandwritingLanguageResolution =
    resolveOriginalHandwritingLanguage(
      context.noteLanguage, context.globalLanguage, context.systemLocale);
  const text: string | null = await provider.recognizeText(strokes, language.localeCode);
  if (text === null) {
    return null;
  }
  return {
    text: text,
    localeCode: language.localeCode,
    languageTag: language.languageTag,
    languageSource: language.source,
  };
}
