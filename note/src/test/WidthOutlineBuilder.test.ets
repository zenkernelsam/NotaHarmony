import { describe, it, expect } from '@ohos/hypium';
import { WidthOutlineBuilder } from '../main/ets/core/algorithm/WidthOutlineBuilder';
import { Point2D } from '../main/ets/core/model/GeometryTypes';
import { StrokePathPoint } from '../main/ets/core/model/StrokeTypes';

function point(x: number, y: number, widthFactor: number = 1): StrokePathPoint {
  return {
    position: { x: x, y: y },
    widthFactor: widthFactor,
    pressure: 1,
    altitudeAngleRadians: Math.PI / 2,
    azimuthUnitX: 1,
    azimuthUnitY: 0,
  };
}

function close(actual: Point2D, x: number, y: number): boolean {
  return Math.abs(actual.x - x) < 1e-9 && Math.abs(actual.y - y) < 1e-9;
}

export default function widthOutlineBuilderTest() {
  describe('WidthOutlineBuilder', () => {
    it('connects both round caps to the upper and lower outlines', 0, () => {
      const result = new WidthOutlineBuilder().build([point(0, 0), point(10, 0)], 2);
      expect(result.isValid).assertTrue();
      expect(close(result.outlinePoints[0], 0, -1)).assertTrue();
      expect(close(result.outlinePoints[5], 0, 1)).assertTrue();
      expect(close(result.outlinePoints[6], 0, 1)).assertTrue();
      expect(close(result.outlinePoints[8], 10, 1)).assertTrue();
      expect(close(result.outlinePoints[13], 10, -1)).assertTrue();
      expect(close(result.outlinePoints[14], 10, -1)).assertTrue();
    });

    it('scans past duplicate leading points for the first normal', 0, () => {
      const result = new WidthOutlineBuilder().build([
        point(0, 0), point(0, 0), point(10, 0),
      ], 2);
      expect(result.isValid).assertTrue();
      expect(close(result.outlinePoints[0], 0, -1)).assertTrue();
      expect(close(result.outlinePoints[5], 0, 1)).assertTrue();
    });

    it('renders a fully degenerate input as a circle', 0, () => {
      const result = new WidthOutlineBuilder().build([
        point(4, 7, 0.5), point(4, 7, 1),
      ], 4);
      expect(result.isValid).assertTrue();
      expect(result.outlinePoints.length).assertEqual(16);
      for (const outlinePoint of result.outlinePoints) {
        const dx: number = outlinePoint.x - 4;
        const dy: number = outlinePoint.y - 7;
        expect(Math.abs(Math.sqrt(dx * dx + dy * dy) - 2) < 1e-9).assertTrue();
      }
    });

    it('renders a single input point as a circle', 0, () => {
      const result = new WidthOutlineBuilder().build([point(2, 3)], 2);
      expect(result.isValid).assertTrue();
      expect(result.outlinePoints.length).assertEqual(16);
    });
  });
}
