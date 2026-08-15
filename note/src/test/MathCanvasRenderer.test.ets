import { describe, expect, it } from '@ohos/hypium';
import { originalMathRasterScale } from '../main/ets/rendering/MathCanvasRenderer';

export default function mathCanvasRendererTest() {
  describe('MathCanvasRenderer', () => {
    it('combines viewport zoom and display density', 0, () => {
      expect(originalMathRasterScale(1, 1)).assertEqual(1);
      expect(originalMathRasterScale(0.5, 3)).assertEqual(1.5);
      expect(originalMathRasterScale(1, 3)).assertEqual(3);
    });

    it('quantizes the original raster scale to half steps', 0, () => {
      expect(originalMathRasterScale(1.2499999, 1)).assertEqual(1);
      expect(originalMathRasterScale(1.25, 1)).assertEqual(1.5);
      expect(originalMathRasterScale(1, 2.74)).assertEqual(2.5);
      expect(originalMathRasterScale(1, 2.75)).assertEqual(3);
    });

    it('clamps the native bitmap scale and hardens invalid platform input', 0, () => {
      expect(originalMathRasterScale(0.25, 1)).assertEqual(1);
      expect(originalMathRasterScale(2, 3)).assertEqual(4);
      expect(originalMathRasterScale(Number.NaN, 3)).assertEqual(1);
      expect(originalMathRasterScale(1, Number.POSITIVE_INFINITY)).assertEqual(1);
    });
  });
}
