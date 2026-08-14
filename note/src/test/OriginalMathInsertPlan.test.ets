import { describe, expect, it } from '@ohos/hypium';
import {
  createOriginalMathInsertDraft, ORIGINAL_MATH_INSERT_MAX_HEIGHT,
  ORIGINAL_MATH_INSERT_MAX_WIDTH, fitOriginalMathMeasuredSizeToBox,
  originalMathMeasurementFontSize,
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
        { x: 100, y: 100 }, 800, 1100, 242, 40) === null).assertTrue();
      expect(createOriginalMathInsertDraft(' ',
        { x: 100, y: 100 }, 800, 1100) === null).assertTrue();
    });

    it('fits the original max-font native measurement into the 240x120 frame', 0, () => {
      expect(originalMathMeasurementFontSize(240.9, 120.9)).assertEqual(240);
      const fitted = fitOriginalMathMeasuredSizeToBox(240, 120, 480, 60);
      expect(fitted?.width).assertEqual(240);
      expect(fitted?.height).assertEqual(30);
      expect(fitted?.fontSize).assertEqual(120);
      const enlarged = fitOriginalMathMeasuredSizeToBox(240, 120, 40, 80);
      expect(enlarged?.width).assertEqual(60);
      expect(enlarged?.height).assertEqual(120);
      expect(enlarged?.fontSize).assertEqual(360);
      expect(fitOriginalMathMeasuredSizeToBox(240, 120, 0, 40) === null).assertTrue();
    });

    it('preserves original Float32 fitting at exact-axis rounding boundaries', 0, () => {
      expect(originalMathMeasurementFontSize(10.9999999, 4)).assertEqual(11);
      const exactAxis = fitOriginalMathMeasuredSizeToBox(27, 55, 126, 319);
      expect(exactAxis?.fontSize).assertEqual(9);
      expect(exactAxis?.width).assertEqual(22);
      expect(exactAxis?.height).assertEqual(55);
      const roundedOvershoot = fitOriginalMathMeasuredSizeToBox(240, 81, 852, 133);
      expect(roundedOvershoot?.fontSize).assertEqual(67);
      expect(roundedOvershoot?.width).assertEqual(241);
      expect(roundedOvershoot?.height).assertEqual(38);
      const draft = createOriginalMathInsertDraft('x',
        { x: 200, y: 200 }, 800, 1100, 241, 81);
      expect(draft?.blockWidth).assertEqual(241);
    });
  });
}
