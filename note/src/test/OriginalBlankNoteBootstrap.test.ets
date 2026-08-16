import { describe, expect, it } from '@ohos/hypium';
import {
  originalDefaultTemplateFromSettings, originalDefaultTemplateSettings,
  originalFallbackDefaultTemplate,
} from '../main/ets/core/model/OriginalDefaultTemplate';
import { OriginalPaperFlair, PageOrientation, PaperSize, PaperTemplate } from
  '../main/ets/core/model/NoteTypes';
import { applyOriginalPaperSettings, originalDefaultNoteBackgroundSettings } from
  '../main/ets/core/model/PageBackgroundModel';
import {
  ORIGINAL_BLANK_NOTE_PAGE_COUNT, persistOriginalBlankNoteBootstrap,
} from '../main/ets/data/OriginalBlankNoteBootstrapPersistence';
import {
  decodeOriginalDefaultTemplate, encodeOriginalDefaultTemplate,
} from '../main/ets/data/OriginalDefaultTemplateCodec';
import { persistOriginalCreatePages } from '../main/ets/data/OriginalPagePersistence';

export default function originalBlankNoteBootstrapTest() {
  describe('OriginalBlankNoteBootstrap', () => {
    it('uses the concrete original Letter Plain fallback and two initial pages', 0, () => {
      expect(persistOriginalBlankNoteBootstrap !== undefined).assertTrue();
      expect(persistOriginalCreatePages !== undefined).assertTrue();
      expect(ORIGINAL_BLANK_NOTE_PAGE_COUNT).assertEqual(2);
      const settings = originalDefaultTemplateSettings(originalFallbackDefaultTemplate());
      expect(settings.size).assertEqual(PaperSize.LETTER);
      expect(settings.template).assertEqual(PaperTemplate.PLAIN);
      expect(settings.orientation).assertEqual(PageOrientation.PORTRAIT);
      expect(settings.registerBackground === null).assertFalse();
      expect(settings.background.sourceWidthPt).assertEqual(612);
      expect(settings.background.sourceHeightPt).assertEqual(792);
      expect(settings.background.margins?.topPt).assertEqual(36);
      expect(settings.background.margins?.bottomPt).assertEqual(36);
      expect(settings.background.paper?.flairBleeds).assertTrue();
      expect(settings.background.paper?.flairCentered).assertFalse();
    });

    it('round-trips selectedDefaultTemplate and rejects corrupt preferences', 0, () => {
      const settings = applyOriginalPaperSettings(originalDefaultNoteBackgroundSettings(),
        PaperSize.A4, PaperTemplate.GRID, PageOrientation.LANDSCAPE);
      if (settings.background.paper !== null) {
        settings.background.paper.flairSpacingPt = 18;
        settings.background.paper.colorR = 12;
        settings.background.paper.colorG = 34;
        settings.background.paper.colorB = 56;
        settings.background.paper.colorA = 200;
        settings.background.paper.legacyPaperIndex = 7;
        settings.registerBackground = settings.background;
      }
      const encoded: Uint8Array = encodeOriginalDefaultTemplate(
        originalDefaultTemplateFromSettings(settings));
      const decoded = decodeOriginalDefaultTemplate(encoded);
      expect(decoded === null).assertFalse();
      expect(decoded?.size).assertEqual(PaperSize.A4);
      expect(decoded?.template).assertEqual(PaperTemplate.GRID);
      expect(decoded?.orientation).assertEqual(PageOrientation.LANDSCAPE);
      expect(decoded?.paper.flair).assertEqual(OriginalPaperFlair.GRID);
      expect(decoded?.paper.flairSpacingPt).assertEqual(18);
      expect(decoded?.paper.flairBleeds).assertTrue();
      expect(decoded?.paper.flairCentered).assertFalse();
      expect(decoded?.paper.colorR).assertEqual(12);
      expect(decoded?.paper.colorG).assertEqual(34);
      expect(decoded?.paper.colorB).assertEqual(56);
      expect(decoded?.paper.colorA).assertEqual(200);
      expect(decoded?.paper.legacyPaperIndex).assertEqual(7);
      expect(encoded.length > 8).assertTrue();
      expect(decodeOriginalDefaultTemplate(new Uint8Array([4, 0, 0, 0])) === null).assertTrue();
      const corrupt: Uint8Array = encoded.slice();
      corrupt[0] = 0xFF;
      expect(decodeOriginalDefaultTemplate(corrupt) === null).assertTrue();
    });
  });
}
