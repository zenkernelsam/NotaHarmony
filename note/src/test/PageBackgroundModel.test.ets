import { describe, it, expect } from '@ohos/hypium';
import {
  OriginalPaperFlair, PageBackground, PagePaperBackground, PaperTemplate,
} from '../main/ets/core/model/NoteTypes';
import {
  clonePageBackground, pageBackgroundCssColor, parsePageBackground, samePageBackground,
  serializePageBackground, templateForOriginalPaper, validatePageBackground,
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

    it('rejects invalid original background values', 0, () => {
      const translucent: PageBackground = background();
      (translucent.paper as PagePaperBackground).colorA = 128;
      expectThrow((): void => validatePageBackground(translucent));
      const rotated: PageBackground = background();
      rotated.rotationRadians = 0.25;
      expectThrow((): void => validatePageBackground(rotated));
      const margins: PageBackground = background();
      if (margins.margins !== null) {
        margins.margins.leftPt = 700;
      }
      expectThrow((): void => validatePageBackground(margins));
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

function expectThrow(block: () => void): void {
  let rejected: boolean = false;
  try {
    block();
  } catch (_error) {
    rejected = true;
  }
  expect(rejected).assertTrue();
}
