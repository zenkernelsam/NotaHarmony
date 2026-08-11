import { describe, expect, it } from '@ohos/hypium';
import { isOriginalMathLatexDraftValid } from '../main/ets/ui/components/MathEditorOverlay';

export default function mathEditorOverlayTest() {
  describe('MathEditorOverlay', () => {
    it('accepts non-empty UTF-8 latex and rejects empty drafts', 0, () => {
      expect(isOriginalMathLatexDraftValid('\\frac{a}{b}')).assertTrue();
      expect(isOriginalMathLatexDraftValid('α + β')).assertTrue();
      expect(isOriginalMathLatexDraftValid('')).assertFalse();
      expect(isOriginalMathLatexDraftValid('   ')).assertFalse();
    });

    it('rejects drafts outside the original decoder budget', 0, () => {
      expect(isOriginalMathLatexDraftValid('x'.repeat(1048577))).assertFalse();
    });
  });
}
