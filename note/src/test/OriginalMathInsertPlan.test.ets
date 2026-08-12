import { describe, expect, it } from '@ohos/hypium';
import {
  createOriginalMathInsertDraft, ORIGINAL_MATH_INSERT_MAX_HEIGHT,
  ORIGINAL_MATH_INSERT_MAX_WIDTH, fitOriginalMathMeasuredSize,
} from '../main/ets/core/model/OriginalMathInsertPlan';

export default function originalMathInsertPlanTest() {
  describe('OriginalMathInsertPlan', () => {
    it('centers the original maximum Math box with original defaults', 0, () => {
      const draft = createOriginalMathInsertDraft('\\frac{a}{b}',
        { x: 400, y: 500 }, 800, 1100);
      expect(draft === null).assertFalse();
      expect(draft?.id).assertEqual('');
      expect(draft?.transform[2]).assertEqual(280);
      expect(draft?.transform[5]).assertEqual(440);
      expect(draft?.blockWidth).assertEqual(ORIGINAL_MATH_INSERT_MAX_WIDTH);
      expect(draft?.blockHeight).assertEqual(ORIGINAL_MATH_INSERT_MAX_HEIGHT);
      expect(draft?.color).assertEqual(-16777216);
      expect(draft?.corner).assertEqual(0);
      expect(draft?.textWrap).assertEqual(0);
      expect(draft?.enableCaption).assertFalse();
      expect(draft?.positionLocked).assertFalse();
    });

    it('accepts measured engine output within the original maximum box', 0, () => {
      const draft = createOriginalMathInsertDraft('x',
        { x: 100, y: 100 }, 800, 1100, 80, 40);
      expect(draft?.transform[2]).assertEqual(60);
      expect(draft?.transform[5]).assertEqual(80);
      expect(draft?.bounds.right).assertEqual(140);
      expect(draft?.bounds.bottom).assertEqual(120);
    });

    it('rejects missing page center and invalid measured output', 0, () => {
      expect(createOriginalMathInsertDraft('x',
        { x: -1, y: 100 }, 800, 1100) === null).assertTrue();
      expect(createOriginalMathInsertDraft('x',
        { x: 100, y: 100 }, 800, 1100, 241, 40) === null).assertTrue();
      expect(createOriginalMathInsertDraft(' ',
        { x: 100, y: 100 }, 800, 1100) === null).assertTrue();
    });

    it('fits native natural dimensions proportionally into the original 240x120 frame', 0, () => {
      const fitted = fitOriginalMathMeasuredSize(480, 60);
      expect(fitted?.width).assertEqual(240);
      expect(fitted?.height).assertEqual(30);
      expect(fitOriginalMathMeasuredSize(0, 40) === null).assertTrue();
    });
  });
}
