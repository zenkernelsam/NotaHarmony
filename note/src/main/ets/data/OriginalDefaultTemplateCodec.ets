import {
  OriginalDefaultTemplateSelection, originalDefaultTemplateFromSettings,
  originalDefaultTemplateSettings,
} from '../core/model/OriginalDefaultTemplate';
import { NoteBackgroundSettings, PageBackground } from '../core/model/NoteTypes';
import {
  decodeOriginalPageBackgroundTable, OriginalDecodedPageBackground,
  originalPageBackgroundFitsHarmony,
} from './OriginalPageBackgroundOperation';
import { encodeOriginalPageBackgroundRoot } from './OriginalSetMetadataPayloadEncoder';
import { OriginalFlatBufferTableReader } from './OriginalSyncedOperationFlatBuffer';

const MAX_DEFAULT_TEMPLATE_BYTES: number = 1024 * 1024;

// Original ss8 case 7 serializes l3a.a(mask=7) as a root nz9 FlatBuffer byte[].
export function encodeOriginalDefaultTemplate(
  selection: OriginalDefaultTemplateSelection): Uint8Array {
  const settings: NoteBackgroundSettings = originalDefaultTemplateSettings(selection);
  if (settings.registerBackground === null) {
    throw new Error('selected default template has no concrete original background');
  }
  return encodeOriginalPageBackgroundRoot(settings.registerBackground);
}

// Original o59.h() treats malformed/truncated bytes as the built-in fallback. Return null
// so the settings store can make the same decision without changing the corrupt byte value.
export function decodeOriginalDefaultTemplate(
  encoded: Uint8Array): OriginalDefaultTemplateSelection | null {
  if (encoded.length < 8 || encoded.length > MAX_DEFAULT_TEMPLATE_BYTES) {
    return null;
  }
  try {
    const decoded: OriginalDecodedPageBackground = decodeOriginalPageBackgroundTable(
      OriginalFlatBufferTableReader.fromRoot(encoded));
    if (decoded.hasPdf || !originalPageBackgroundFitsHarmony(decoded)) {
      return null;
    }
    const background: PageBackground = decoded.background;
    const settings: NoteBackgroundSettings = {
      background: background,
      registerBackground: background,
      template: decoded.template,
      size: decoded.size,
      orientation: decoded.orientation,
      widthMm: decoded.widthMm,
      heightMm: decoded.heightMm,
    };
    return originalDefaultTemplateFromSettings(settings);
  } catch (_error) {
    return null;
  }
}
