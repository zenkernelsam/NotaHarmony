import { describe, it, expect } from '@ohos/hypium';
import { PageOrientation, PaperSize } from '../main/ets/core/model/NoteTypes';
import {
  defaultOriginalBackgroundInfo, ORIGINAL_PAPER_SPACING_INCHES, OriginalPaperBackground,
  normalizeOriginalPaperSpacingInches, OriginalPaperLineType, originalPackedPaperSize,
  originalPaperSizeFromPacked,
  originalPaperSpacingInchesFromPoints, originalPaperSpacingPointsFromInches, packOriginalArgb,
  sameOriginalPaperBackground, unpackOriginalArgb, validateOriginalBackgroundInfo,
  validateOriginalPaperBackground,
} from '../main/ets/core/model/OriginalPaperSettings';

export default function originalPaperSettingsTest() {
  describe('OriginalPaperSettings', () => {
    it('uses the four original empty-table BackgroundInfo fallbacks', 0, () => {
      const plain = defaultOriginalBackgroundInfo(OriginalPaperLineType.PLAIN);
      expect(plain.spacingInches === null).assertTrue();
      expect(plain.hasOptions).assertFalse();
      for (const lineType of [OriginalPaperLineType.LINES, OriginalPaperLineType.GRID,
        OriginalPaperLineType.DOTS]) {
        const info = defaultOriginalBackgroundInfo(lineType);
        expect(info.spacingInches).assertEqual(Math.fround(0.5));
        expect(info.hasOptions).assertTrue();
      }
    });

    it('round-trips every original Float32 spacing preset at 72 points per inch', 0, () => {
      expect(ORIGINAL_PAPER_SPACING_INCHES.length).assertEqual(10);
      for (const spacing of ORIGINAL_PAPER_SPACING_INCHES) {
        const points: number = originalPaperSpacingPointsFromInches(spacing);
        expect(originalPaperSpacingInchesFromPoints(points)).assertEqual(spacing);
        expect(Math.fround(points)).assertEqual(points);
      }
      expect(originalPaperSpacingPointsFromInches(0.5)).assertEqual(36);
      expect(originalPaperSpacingInchesFromPoints(36)).assertEqual(Math.fround(0.5));
    });

    it('preserves signed ARGB including alpha and its RGBA channel order', 0, () => {
      const packed: number = packOriginalArgb(18, 52, 86, 128);
      expect(packed).assertEqual(-2146290602);
      const rgba = unpackOriginalArgb(packed);
      expect(rgba.red).assertEqual(18);
      expect(rgba.green).assertEqual(52);
      expect(rgba.blue).assertEqual(86);
      expect(rgba.alpha).assertEqual(128);
    });

    it('maps all eight ndj.f packed Float32 paper sizes without JS integer loss', 0, () => {
      const sizes: PaperSize[] = [PaperSize.A3, PaperSize.A4, PaperSize.A5, PaperSize.A6,
        PaperSize.A7, PaperSize.LETTER, PaperSize.LEGAL, PaperSize.TABLOID];
      for (const size of sizes) {
        const packed: string = originalPackedPaperSize(size);
        expect(Number.isSafeInteger(Number(packed))).assertFalse();
        expect(originalPaperSizeFromPacked(packed)).assertEqual(size);
        expect(originalPaperSizeFromPacked(Number(packed))).assertEqual(size);
      }
      expect(originalPackedPaperSize(PaperSize.LETTER)).assertEqual('4852600450409280307');
      expect(originalPackedPaperSize(PaperSize.LEGAL)).assertEqual('4852600450411777229');
      expect(originalPackedPaperSize(PaperSize.TABLOID)).assertEqual('4867180855066879590');
    });

    it('compares complete favorite semantics while ignoring the Room id', 0, () => {
      const first: OriginalPaperBackground = favorite(1);
      const second: OriginalPaperBackground = favorite(29);
      expect(sameOriginalPaperBackground(first, second)).assertTrue();
      second.spacingInches = Math.fround(0.75);
      expect(sameOriginalPaperBackground(first, second)).assertFalse();
    });

    it('accepts nullable or legacy positive spacing but restricts UI writes to presets', 0, () => {
      const nullable = validateOriginalBackgroundInfo({
        paperLineType: OriginalPaperLineType.GRID, spacingInches: null, hasOptions: false,
      });
      expect(nullable.spacingInches === null).assertTrue();
      const legacy = validateOriginalBackgroundInfo({
        paperLineType: OriginalPaperLineType.LINES, spacingInches: 0.6, hasOptions: true,
      });
      expect(legacy.spacingInches).assertEqual(Math.fround(0.6));
      expect(originalPaperSpacingPointsFromInches(0.6)).assertEqual(
        Math.fround(Math.fround(0.6) * Math.fround(72)));
      expect(() => normalizeOriginalPaperSpacingInches(0.6)).assertThrow();
    });

    it('rejects corrupt enums, color bytes, nonpositive spacing, legacy index and ids', 0, () => {
      expect(() => defaultOriginalBackgroundInfo(
        'RULED' as OriginalPaperLineType)).assertThrow();
      expect(() => validateOriginalBackgroundInfo({
        paperLineType: OriginalPaperLineType.LINES, spacingInches: 0, hasOptions: true,
      })).assertThrow();
      expect(() => packOriginalArgb(0, 0, 0, 256)).assertThrow();
      const invalidLegacy: OriginalPaperBackground = favorite(0);
      invalidLegacy.legacyPaperIndex = 256;
      expect(() => validateOriginalPaperBackground(invalidLegacy)).assertThrow();
      const invalidId: OriginalPaperBackground = favorite(0);
      invalidId.id = -1;
      expect(() => validateOriginalPaperBackground(invalidId)).assertThrow();
      expect(() => originalPaperSizeFromPacked('4852600450409280308')).assertThrow();
    });
  });
}

function favorite(id: number): OriginalPaperBackground {
  return {
    id: id,
    paperSize: PaperSize.LETTER,
    paperOrientation: PageOrientation.PORTRAIT,
    backgroundColor: packOriginalArgb(255, 255, 255),
    legacyPaperIndex: null,
    paperLineType: OriginalPaperLineType.LINES,
    spacingInches: Math.fround(0.5),
    hasOptions: true,
  };
}
