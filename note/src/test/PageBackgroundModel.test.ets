import { describe, it, expect } from '@ohos/hypium';
import {
  OriginalPaperFlair, PageBackground, PageInfo, PageOrientation, PagePaperBackground,
  PaperSize, PaperTemplate, PdfLayoutBehavior,
} from '../main/ets/core/model/NoteTypes';
import {
  clonePageBackground, clonePageInfo, effectivePageBackground, originalDefaultNoteBackground,
  pageBackgroundCssColor, parsePageBackground, samePageBackground, serializePageBackground,
  templateForOriginalPaper, validatePageBackground,
} from '../main/ets/core/model/PageBackgroundModel';

export default function pageBackgroundModelTest() {
  describe('PageBackgroundModel', () => {
    it('round-trips original paper metadata without aliasing', 0, () => {
      const value: PageBackground = background();
      const encoded: string | null = serializePageBackground(value);
      expect(encoded === null).assertFalse();
      const decoded: PageBackground | null = parsePageBackground(encoded);
      expect(decoded === null).assertFalse();
      expect(samePageBackground(value, decoded)).assertTrue();
      const cloned: PageBackground | null = clonePageBackground(value);
      expect(cloned === null).assertFalse();
      if (cloned !== null && cloned.paper !== null) {
        cloned.paper.colorR = 1;
      }
      expect(value.paper === null ? -1 : value.paper.colorR).assertEqual(244);
      expect(pageBackgroundCssColor(value, '#ffffff')).assertEqual('rgba(244,245,246,1)');
    });

    it('uses original at3 template mapping', 0, () => {
      const paper: PagePaperBackground = background().paper as PagePaperBackground;
      expect(templateForOriginalPaper(paper)).assertEqual(PaperTemplate.GRID);
      paper.flair = OriginalPaperFlair.LINES;
      paper.flairSpacingPt = 18;
      expect(templateForOriginalPaper(paper)).assertEqual(PaperTemplate.LINES);
      paper.flairSpacingPt = null;
      expect(templateForOriginalPaper(paper)).assertEqual(PaperTemplate.PLAIN);
      paper.flair = OriginalPaperFlair.DOTS;
      expect(templateForOriginalPaper(paper)).assertEqual(PaperTemplate.DOTS);
    });

    it('preserves original ARGB alpha while rejecting incomplete colors', 0, () => {
      const translucent: PageBackground = background();
      (translucent.paper as PagePaperBackground).colorA = 128;
      validatePageBackground(translucent);
      expect(parsePageBackground(serializePageBackground(translucent))?.paper?.colorA).assertEqual(128);
      const incomplete: PageBackground = background();
      (incomplete.paper as PagePaperBackground).colorA = null;
      expectThrow((): void => validatePageBackground(incomplete));
      const rotated: PageBackground = background();
      rotated.rotationRadians = 0.25;
      expectThrow((): void => validatePageBackground(rotated));
      const margins: PageBackground = background();
      if (margins.margins !== null) {
        margins.margins.leftPt = 700;
      }
      expectThrow((): void => validatePageBackground(margins));
    });

    it('keeps a nullable page register separate from the note fallback', 0, () => {
      const fallback: PageBackground = background();
      const page: PageInfo = {
        pageId: 'page', pageIndex: 0, size: PaperSize.LETTER, template: PaperTemplate.GRID,
        orientation: PageOrientation.PORTRAIT, widthMm: 215.9, heightMm: 279.4,
        background: null, noteBackgroundFallback: fallback,
      };
      const effective: PageBackground | null = effectivePageBackground(page);
      expect(samePageBackground(effective, fallback)).assertTrue();
      const cloned: PageInfo = clonePageInfo(page);
      expect(cloned.background === null).assertTrue();
      expect(samePageBackground(cloned.noteBackgroundFallback, fallback)).assertTrue();
      const explicit: PageBackground = originalDefaultNoteBackground();
      page.background = explicit;
      expect(samePageBackground(effectivePageBackground(page), explicit)).assertTrue();
      expect(originalDefaultNoteBackground().sourceWidthPt).assertEqual(612);
      expect(originalDefaultNoteBackground().sourceHeightPt).assertEqual(792);
    });

    it('keeps PDF assets and pageInAsset lossless but independently owned', 0, () => {
      const fallback: PageBackground = pdfBackground();
      const page: PageInfo = {
        pageId: 'pdf', pageIndex: 0, size: PaperSize.LETTER, template: PaperTemplate.PLAIN,
        orientation: PageOrientation.PORTRAIT, widthMm: 215.9, heightMm: 279.4,
        background: null, noteBackgroundFallback: fallback, originalPageInAsset: 5,
      };
      const effective: PageBackground | null = effectivePageBackground(page);
      expect(effective?.pdf?.pageInAsset).assertEqual(5);
      expect(fallback.pdf?.pageInAsset).assertEqual(4);
      const encoded: string | null = serializePageBackground(fallback);
      const decoded: PageBackground | null = parsePageBackground(encoded);
      expect(samePageBackground(fallback, decoded)).assertTrue();
      if (decoded !== null && decoded.pdf !== undefined && decoded.pdf !== null) {
        decoded.pdf.metadata.assetHashBits[0] = '99';
        decoded.pdf.cropBoxes[0].widthPt = 1;
      }
      expect(fallback.pdf?.metadata.assetHashBits[0]).assertEqual('1');
      expect(fallback.pdf?.cropBoxes[0].widthPt).assertEqual(612);
      const invalid: PageBackground = pdfBackground();
      if (invalid.pdf !== undefined && invalid.pdf !== null) {
        invalid.pdf.cropBoxes.pop();
      }
      expectThrow((): void => validatePageBackground(invalid));
    });
  });
}

function background(): PageBackground {
  return {
    schemaVersion: 1,
    paper: {
      flair: OriginalPaperFlair.GRID, flairSpacingPt: 18, flairBleeds: true,
      flairCentered: false, colorR: 244, colorG: 245, colorB: 246, colorA: 255,
      legacyPaperIndex: 7,
    },
    rotationRadians: Math.PI / 2,
    sourceWidthPt: 612,
    sourceHeightPt: 792,
    margins: { topPt: 12, bottomPt: 14, leftPt: 16, rightPt: 18 },
  };
}

function pdfBackground(): PageBackground {
  return {
    schemaVersion: 2,
    paper: null,
    pdf: {
      metadata: {
        assetHashBits: ['1', '2', '3', '4', '5', '6', '7', '18446744073709551615'],
        fileName: 'source.pdf', mimeType: 'application/pdf', fileSize: 4096,
      },
      layoutBehavior: PdfLayoutBehavior.DOWNSCALING_AND_CROP_BOX,
      totalPageCount: 12, pagesConsumed: 2, pageOffset: 4,
      cropBoxes: [{ widthPt: 612, heightPt: 792 }, { widthPt: 612, heightPt: 792 }],
      pageInAsset: 4,
    },
    rotationRadians: 0,
    sourceWidthPt: 612,
    sourceHeightPt: 792,
    margins: null,
  };
}

function expectThrow(block: () => void): void {
  let rejected: boolean = false;
  try {
    block();
  } catch (_error) {
    rejected = true;
  }
  expect(rejected).assertTrue();
}
