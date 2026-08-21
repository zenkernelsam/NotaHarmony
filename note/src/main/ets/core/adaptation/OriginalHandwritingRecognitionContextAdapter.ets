import {
  OriginalHandwritingLanguageResolution, OriginalLocaleLanguage,
  resolveOriginalHandwritingLanguage,
} from '../model/OriginalHandwritingLanguagePolicy';
import { relationalStore } from '@kit.ArkData';
import {
  OriginalNoteMetadataState, readOriginalNoteMetadataState,
} from '../../data/OriginalSetMetadataOperation';
import { OriginalHandwritingRecognitionContext } from './OriginalHandwritingRecognition';
import {
  OriginalHandwritingSystemLocaleSource, readHarmonyOriginalHandwritingLocale,
} from './OriginalHandwritingLocaleAdapter';

export interface OriginalHandwritingLanguagePreferenceReader {
  getRecognitionLanguageId(): Promise<string | null>;
}

export interface OriginalHandwritingNoteLanguageSnapshot {
  hasHandwritingLanguage: boolean;
  handwritingLanguage: string | null;
}

export async function createOriginalHandwritingRecognitionContext(
  note: OriginalHandwritingNoteLanguageSnapshot,
  preference: OriginalHandwritingLanguagePreferenceReader,
  localeSource?: OriginalHandwritingSystemLocaleSource):
  Promise<OriginalHandwritingRecognitionContext> {
  return {
    // An explicit-null note register and an absent register both continue to
    // the original global preference, so the provider context carries null.
    noteLanguage: note.hasHandwritingLanguage ? note.handwritingLanguage : null,
    globalLanguage: await preference.getRecognitionLanguageId(),
    systemLocale: readHarmonyOriginalHandwritingLocale(localeSource),
  };
}

export async function loadProductionOriginalHandwritingRecognitionContext(
  store: relationalStore.RdbStore,
  noteId: string,
  preference: OriginalHandwritingLanguagePreferenceReader,
  localeSource?: OriginalHandwritingSystemLocaleSource):
  Promise<OriginalHandwritingRecognitionContext> {
  if (noteId.length === 0) {
    throw new Error('original handwriting recognition context requires a note identity');
  }
  const note: OriginalNoteMetadataState = await readOriginalNoteMetadataState(store, noteId);
  return createOriginalHandwritingRecognitionContext(note, preference, localeSource);
}

export async function resolveProductionOriginalHandwritingLanguage(
  note: OriginalHandwritingNoteLanguageSnapshot,
  preference: OriginalHandwritingLanguagePreferenceReader,
  localeSource?: OriginalHandwritingSystemLocaleSource):
  Promise<OriginalHandwritingLanguageResolution> {
  const context: OriginalHandwritingRecognitionContext =
    await createOriginalHandwritingRecognitionContext(note, preference, localeSource);
  const locale: OriginalLocaleLanguage = context.systemLocale;
  return resolveOriginalHandwritingLanguage(
    context.noteLanguage, context.globalLanguage, locale);
}
