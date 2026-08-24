import { describe, expect, it } from '@ohos/hypium';
import {
  originalImageOrientedDimensions, planOriginalImageDownscale,
} from '../main/ets/core/model/OriginalImageInsertPlan';
import { originalRotationDegrees } from '../main/ets/data/OriginalImageNormalizer';

export default function originalImageNormalizerTest() {
  describe('OriginalImageNormalizer', () => {
    it('keeps images at or below the original 3000px boundary unchanged', 0, () => {
      expect(planOriginalImageDownscale(3000, 1)).assertEqual({
        sampleSize: 1, width: 3000, height: 1,
      });
      expect(planOriginalImageDownscale(1, 3000)).assertEqual({
        sampleSize: 1, width: 1, height: 3000,
      });
    });

    it('uses Float32 ratios and power-of-two sampling like Android vuh', 0, () => {
      const wide = planOriginalImageDownscale(6000, 2000);
      expect(wide?.sampleSize).assertEqual(2);
      expect(wide?.width).assertEqual(3000);
      expect(wide?.height).assertEqual(1000);
      expect(planOriginalImageDownscale(3001, 1)?.sampleSize).assertEqual(1);
    });

    it('maps EXIF orientations that swap encoded axes', 0, () => {
      for (const orientation of ['5', '6', '7', '8', 'Right-top']) {
        const oriented = originalImageOrientedDimensions(4000, 100, orientation);
        expect(oriented?.width).assertEqual(100);
        expect(oriented?.height).assertEqual(4000);
      }
      expect(originalImageOrientedDimensions(4000, 100, '3')?.width).assertEqual(4000);
    });

    it('maps renderer orientation degrees and mirror flags', 0, () => {
      expect(originalRotationDegrees('1')).assertEqual(0);
      expect(originalRotationDegrees('2')).assertEqual(0);
      expect(originalRotationDegrees('3')).assertEqual(180);
      expect(originalRotationDegrees('4')).assertEqual(180);
      expect(originalRotationDegrees('5')).assertEqual(270);
      expect(originalRotationDegrees('6')).assertEqual(90);
      expect(originalRotationDegrees('7')).assertEqual(90);
      expect(originalRotationDegrees('8')).assertEqual(270);
      expect(originalRotationDegrees('Right-top')).assertEqual(90);
    });

    it('rejects invalid normalization dimensions', 0, () => {
      expect(planOriginalImageDownscale(0, 10) === null).assertTrue();
      expect(planOriginalImageDownscale(10.5, 10) === null).assertTrue();
      expect(originalImageOrientedDimensions(0, 10, '1') === null).assertTrue();
    });

    it('keeps quarter-turn normalization on the original encoded-axis plan', 0, () => {
      expect(planOriginalImageDownscale(6000, 1000)).assertEqual({
        sampleSize: 2, width: 3000, height: 500,
      });
      expect(originalRotationDegrees('6')).assertEqual(90);
      expect(originalRotationDegrees('8')).assertEqual(270);
    });
  });
}
