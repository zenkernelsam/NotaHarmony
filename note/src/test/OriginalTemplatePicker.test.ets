import { describe, expect, it } from '@ohos/hypium';
import {
  OriginalPaperFlair, PageOrientation, PagePaperBackground, PaperSize, PaperTemplate,
} from '../main/ets/core/model/NoteTypes';
import {
  applyOriginalPaperSettings, clonePageBackground, originalDefaultNoteBackgroundSettings,
} from '../main/ets/core/model/PageBackgroundModel';
import {
  applyOriginalTemplatePickerSelection, isOriginalTemplatePickerSelection,
  OriginalTemplatePickerDraft, originalTemplatePickerDraft,
  stageOriginalTemplateOrientation, stageOriginalTemplateSize,
} from '../main/ets/core/model/OriginalTemplatePickerState';

export default function originalTemplatePickerTest() {
  describe('OriginalTemplatePickerState', () => {
    it('stages size and orientation until a template card is selected', 0, () => {
      const current = applyOriginalPaperSettings(
        originalDefaultNoteBackgroundSettings(), PaperSize.LETTER,
        PaperTemplate.LINES, PageOrientation.PORTRAIT);
      const paper = current.background.paper as PagePaperBackground;
      paper.flairSpacingPt = 18;
      paper.colorR = 12;
      paper.colorG = 34;
      paper.colorB = 56;
      paper.colorA = 255;
      paper.legacyPaperIndex = 7;
      current.registerBackground = clonePageBackground(current.background);

      let draft: OriginalTemplatePickerDraft = originalTemplatePickerDraft(current);
      expect(isOriginalTemplatePickerSelection(current, draft, PaperTemplate.LINES)).assertTrue();
      draft = stageOriginalTemplateSize(draft, PaperSize.A4);
      draft = stageOriginalTemplateOrientation(draft, PageOrientation.LANDSCAPE);

      expect(current.size).assertEqual(PaperSize.LETTER);
      expect(current.orientation).assertEqual(PageOrientation.PORTRAIT);
      expect(isOriginalTemplatePickerSelection(current, draft, PaperTemplate.LINES)).assertFalse();

      const selected = applyOriginalTemplatePickerSelection(current, draft, PaperTemplate.LINES);
      expect(selected.size).assertEqual(PaperSize.A4);
      expect(selected.orientation).assertEqual(PageOrientation.LANDSCAPE);
      expect(selected.template).assertEqual(PaperTemplate.LINES);
      expect(selected.background.paper?.flair).assertEqual(OriginalPaperFlair.LINES);
      expect(selected.background.paper?.flairSpacingPt).assertEqual(18);
      expect(selected.background.paper?.colorR).assertEqual(12);
      expect(selected.background.paper?.colorG).assertEqual(34);
      expect(selected.background.paper?.colorB).assertEqual(56);
      expect(selected.background.paper?.legacyPaperIndex).assertEqual(7);
      expect(isOriginalTemplatePickerSelection(selected, draft, PaperTemplate.LINES)).assertTrue();
    });

    it('uses the selected style default spacing without losing paper color', 0, () => {
      const current = applyOriginalPaperSettings(
        originalDefaultNoteBackgroundSettings(), PaperSize.LETTER,
        PaperTemplate.LINES, PageOrientation.PORTRAIT);
      const paper = current.background.paper as PagePaperBackground;
      paper.flairSpacingPt = 18;
      paper.colorR = 244;
      current.registerBackground = clonePageBackground(current.background);

      const selected = applyOriginalTemplatePickerSelection(
        current, originalTemplatePickerDraft(current), PaperTemplate.GRID);
      expect(selected.template).assertEqual(PaperTemplate.GRID);
      expect(selected.background.paper?.flair).assertEqual(OriginalPaperFlair.GRID);
      expect(selected.background.paper?.flairSpacingPt).assertEqual(36);
      expect(selected.background.paper?.colorR).assertEqual(244);
    });
  });
}
