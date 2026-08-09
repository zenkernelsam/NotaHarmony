import { describe, it, expect } from '@ohos/hypium';
import {
  applyOriginalPencilAlphaCurve, computePencilSplatBounds, originalPencilAlpha,
  pencilSplatExtent,
} from '../main/ets/core/adaptation/PencilSplatMath';
import { Rect2D } from '../main/ets/core/model/GeometryTypes';
import { PencilSplatPoint } from '../main/ets/core/model/StrokeTypes';

function splat(x: number, y: number, scale: number, rotation: number = 0): PencilSplatPoint {
  return { x: x, y: y, scale: scale, rotation: rotation, opacity: 1 };
}

export default function pencilSplatMathTest() {
  describe('PencilSplatMath', () => {
    it('matches the original alpha power curve and truncation', 0, () => {
      expect(originalPencilAlpha(0)).assertEqual(0);
      expect(originalPencilAlpha(64)).assertEqual(32);
      expect(originalPencilAlpha(128)).assertEqual(90);
      expect(originalPencilAlpha(255)).assertEqual(255);

      const rgba: Uint8Array = new Uint8Array([
        10, 20, 30, 64, 40, 50, 60, 128, 99, 98, 97, 96,
        70, 80, 90, 255, 1, 2, 3, 0, 88, 87, 86, 85,
      ]);
      applyOriginalPencilAlphaCurve(rgba, 2, 2, 12);
      expect(rgba[0]).assertEqual(10);
      expect(rgba[3]).assertEqual(32);
      expect(rgba[7]).assertEqual(90);
      expect(rgba[11]).assertEqual(96);
      expect(rgba[15]).assertEqual(255);
      expect(rgba[19]).assertEqual(0);
      expect(rgba[23]).assertEqual(85);
    });

    it('uses the original sqrt2 rotated-quad extent for texture and fallback', 0, () => {
      const scale: number = 10;
      const expected: number = Math.sqrt(2) * scale;
      expect(Math.abs(pencilSplatExtent(scale) - expected) < 1e-12).assertTrue();

      const bounds: Rect2D | null = computePencilSplatBounds([
        splat(100, 50, scale, Math.PI / 4),
      ]);
      expect(bounds !== null).assertTrue();
      if (bounds !== null) {
        expect(Math.abs(bounds.left - (100 - expected)) < 1e-12).assertTrue();
        expect(Math.abs(bounds.top - (50 - expected)) < 1e-12).assertTrue();
        expect(Math.abs(bounds.right - (100 + expected)) < 1e-12).assertTrue();
        expect(Math.abs(bounds.bottom - (50 + expected)) < 1e-12).assertTrue();
      }
    });

    it('unions multiple splats and applies renderer padding once', 0, () => {
      const bounds: Rect2D | null = computePencilSplatBounds([
        splat(0, 0, 2), splat(20, 10, 4),
      ], 2);
      expect(bounds !== null).assertTrue();
      if (bounds !== null) {
        expect(Math.abs(bounds.left - (-2 * Math.sqrt(2) - 2)) < 1e-12).assertTrue();
        expect(Math.abs(bounds.right - (20 + 4 * Math.sqrt(2) + 2)) < 1e-12).assertTrue();
        expect(Math.abs(bounds.bottom - (10 + 4 * Math.sqrt(2) + 2)) < 1e-12).assertTrue();
      }
    });
  });
}
