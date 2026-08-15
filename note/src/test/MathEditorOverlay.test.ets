import { describe, expect, it } from '@ohos/hypium';
import { initialOriginalMathEditorDraftState, isOriginalMathEditorDoneEnabled,
  isOriginalMathLatexDraftValid, OriginalMathEditorDraftState } from
  '../main/ets/ui/components/MathEditorOverlay';

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

    it('starts the original four-state machine at Empty, Invalid, or Loading', 0, () => {
      expect(initialOriginalMathEditorDraftState('   ')).assertEqual(OriginalMathEditorDraftState.EMPTY);
      expect(initialOriginalMathEditorDraftState('x'.repeat(1048577))).assertEqual(
        OriginalMathEditorDraftState.INVALID);
      expect(initialOriginalMathEditorDraftState('\\frac{a}{b}')).assertEqual(
        OriginalMathEditorDraftState.LOADING);
    });

    it('enables Done only for an idle native-rendered Ok state', 0, () => {
      expect(isOriginalMathEditorDoneEnabled(OriginalMathEditorDraftState.OK, false)).assertTrue();
      expect(isOriginalMathEditorDoneEnabled(OriginalMathEditorDraftState.OK, true)).assertFalse();
      expect(isOriginalMathEditorDoneEnabled(OriginalMathEditorDraftState.LOADING, false)).assertFalse();
      expect(isOriginalMathEditorDoneEnabled(OriginalMathEditorDraftState.INVALID, false)).assertFalse();
      expect(isOriginalMathEditorDoneEnabled(OriginalMathEditorDraftState.EMPTY, false)).assertFalse();
    });
  });
}
