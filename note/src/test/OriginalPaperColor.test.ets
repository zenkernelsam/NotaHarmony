import { describe, expect, it } from '@ohos/hypium';
import { PagePaperBackground } from '../main/ets/core/model/NoteTypes';
import {
  ORIGINAL_LEGACY_PAPER_PICKER_INDICES, originalHsvFromArgb,
  originalLegacyPaperPickerSwatchArgb, originalLegacyPaperResourceName,
  originalOpaqueArgbFromHsv, originalPaperRenderStyle,
} from '../main/ets/core/model/OriginalPaperColor';
import { packOriginalArgb, unpackOriginalArgb } from
  '../main/ets/core/model/OriginalPaperSettings';

export default function originalPaperColorTest() {
  describe('OriginalPaperColor', () => {
    it('keeps the original six legacy picker choices and all fifteen resources', 0, () => {
      expect(ORIGINAL_LEGACY_PAPER_PICKER_INDICES.join(','))
        .assertEqual('13,1,2,15,7,6');
      expect(originalLegacyPaperPickerSwatchArgb(13)).assertEqual(-1);
      expect(originalLegacyPaperPickerSwatchArgb(15)).assertEqual(packOriginalArgb(41, 41, 41));
      expect(originalLegacyPaperResourceName(1)).assertEqual('core_paper__paper01.webp');
      expect(originalLegacyPaperResourceName(15)).assertEqual('core_paper__paper15.webp');
      expect(originalLegacyPaperResourceName(16) === null).assertTrue();
    });

    it('writes edited HSV colors opaque while retaining hue and saturation', 0, () => {
      const source: number = packOriginalArgb(18, 52, 86, 128);
      const hsv = originalHsvFromArgb(source);
      const edited = unpackOriginalArgb(originalOpaqueArgbFromHsv(
        hsv.hue, hsv.saturation, hsv.value));
      expect(edited.alpha).assertEqual(255);
      expect(Math.abs(edited.red - 18) <= 1).assertTrue();
      expect(Math.abs(edited.green - 52) <= 1).assertTrue();
      expect(Math.abs(edited.blue - 86) <= 1).assertTrue();
    });

    it('uses original legacy line colors and dark-paper inversion policy', 0, () => {
      const whiteLegacy: PagePaperBackground = paper(null, 13);
      const light = originalPaperRenderStyle(whiteLegacy, '#FFFFFF', '#E0E0E0', false);
      expect(light.lineColor).assertEqual('rgba(163,183,211,1)');
      expect(light.invertLegacyTexture).assertFalse();
      const dark = originalPaperRenderStyle(whiteLegacy, '#262626', '#3A3A3A', true);
      expect(dark.backgroundColor).assertEqual('rgba(0,0,0,1)');
      expect(dark.lineColor).assertEqual('rgba(92,72,44,1)');
      expect(dark.invertLegacyTexture).assertTrue();

      const blackLegacy = originalPaperRenderStyle(paper(null, 15),
        '#262626', '#3A3A3A', true);
      expect(blackLegacy.invertLegacyTexture).assertFalse();
      expect(blackLegacy.lineColor).assertEqual('rgba(90,90,90,1)');
    });

    it('uses the original white default and invalid-legacy line fallbacks', 0, () => {
      const defaultLight = originalPaperRenderStyle(paper(null, null),
        '#FFFFFF', '#E0E0E0', false);
      expect(defaultLight.lineColor).assertEqual('rgba(187,187,187,1)');
      const defaultDark = originalPaperRenderStyle(paper(null, null),
        '#262626', '#3A3A3A', true);
      expect(defaultDark.lineColor).assertEqual('rgba(68,68,68,1)');
      const invalidLegacy = originalPaperRenderStyle(paper(null, 255),
        '#FFFFFF', '#E0E0E0', false);
      expect(invalidLegacy.lineColor).assertEqual('rgba(0,0,0,1)');
    });

    it('keeps an existing translucent custom paper color', 0, () => {
      const style = originalPaperRenderStyle(paper(packOriginalArgb(18, 52, 86, 128), null),
        '#FFFFFF', '#E0E0E0', false);
      expect(style.backgroundColor).assertEqual('rgba(18,52,86,0.5019607843137255)');
    });
  });
}

function paper(backgroundColor: number | null, legacyPaperIndex: number | null): PagePaperBackground {
  const rgba = backgroundColor === null ? null : unpackOriginalArgb(backgroundColor);
  return {
    flair: null, flairSpacingPt: null, flairBleeds: null, flairCentered: null,
    colorR: rgba === null ? null : rgba.red,
    colorG: rgba === null ? null : rgba.green,
    colorB: rgba === null ? null : rgba.blue,
    colorA: rgba === null ? null : rgba.alpha,
    legacyPaperIndex: legacyPaperIndex,
  };
}
