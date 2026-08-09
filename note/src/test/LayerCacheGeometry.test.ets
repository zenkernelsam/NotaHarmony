import { describe, it, expect } from '@ohos/hypium';
import { Rect2D, TransformMatrix } from '../main/ets/core/model/GeometryTypes';
import {
  computeIsolatedLayerBounds, translateTransformToCrop,
} from '../main/ets/core/adaptation/LayerCacheGeometry';

export default function layerCacheGeometryTest() {
  describe('LayerCacheGeometry', () => {
    it('rounds padded mask bounds and clamps them to the page', 0, () => {
      const crop: Rect2D = computeIsolatedLayerBounds({
        left: -0.2, top: 10.4, right: 98.1, bottom: 101.8,
      }, 100, 100, 2);
      expect(crop.left).assertEqual(0);
      expect(crop.top).assertEqual(8);
      expect(crop.right).assertEqual(100);
      expect(crop.bottom).assertEqual(100);
    });

    it('left-multiplies crop translation without mutating the stroke transform', 0, () => {
      const transform: TransformMatrix = [0, -1, 100, 1, 0, 50, 0, 0, 1];
      const translated: TransformMatrix = translateTransformToCrop(transform, {
        left: 20, top: 30, right: 80, bottom: 90,
      });
      expect(translated[0]).assertEqual(0);
      expect(translated[1]).assertEqual(-1);
      expect(translated[2]).assertEqual(80);
      expect(translated[3]).assertEqual(1);
      expect(translated[4]).assertEqual(0);
      expect(translated[5]).assertEqual(20);
      expect(transform[2]).assertEqual(100);
      expect(transform[5]).assertEqual(50);
    });
  });
}
