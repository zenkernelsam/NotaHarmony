import { describe, it, expect } from '@ohos/hypium';
import { WidthOutlineBuilder } from '../main/ets/core/algorithm/WidthOutlineBuilder';
import { CubicSegment, Point2D } from '../main/ets/core/model/GeometryTypes';
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

function close(actual: Point2D, x: number, y: number, tolerance: number = 1e-9): boolean {
  return Math.abs(actual.x - x) < tolerance && Math.abs(actual.y - y) < tolerance;
}

function contains(points: Point2D[], x: number, y: number, tolerance: number = 1e-9): boolean {
  for (const actual of points) {
    if (close(actual, x, y, tolerance)) {
      return true;
    }
  }
  return false;
}

function allFinite(points: Point2D[]): boolean {
  for (const actual of points) {
    if (!Number.isFinite(actual.x) || !Number.isFinite(actual.y)) {
      return false;
    }
  }
  return true;
}

function archCubic(): CubicSegment {
  return {
    p0: { x: 0, y: 0 },
    p1: { x: 0, y: 10 },
    p2: { x: 10, y: 10 },
    p3: { x: 10, y: 0 },
  };
}

export default function widthOutlineBuilderTest() {
  describe('WidthOutlineBuilder', () => {
    it('connects both round caps to the upper and lower outlines', 0, () => {
      const result = new WidthOutlineBuilder().build([point(0, 0), point(10, 0)], 2);
      expect(result.isValid).assertTrue();
      expect(close(result.outlinePoints[0], 0, -1)).assertTrue();
      expect(contains(result.outlinePoints, 0, 1)).assertTrue();
      expect(contains(result.outlinePoints, 10, 1)).assertTrue();
      expect(contains(result.outlinePoints, 10, -1)).assertTrue();
    });

    it('scans past duplicate leading points for the first normal', 0, () => {
      const result = new WidthOutlineBuilder().build([
        point(0, 0), point(0, 0), point(10, 0),
      ], 2);
      expect(result.isValid).assertTrue();
      expect(close(result.outlinePoints[0], 0, -1)).assertTrue();
      expect(contains(result.outlinePoints, 0, 1)).assertTrue();
    });

    it('renders a fully degenerate input as a circle using the largest radius', 0, () => {
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

    it('adaptively follows fitted cubic curvature instead of the endpoint chord', 0, () => {
      const builder: WidthOutlineBuilder = new WidthOutlineBuilder();
      const centerline: StrokePathPoint[] = [point(0, 0), point(10, 0)];
      const chord = builder.build(centerline, 2);
      const curved = builder.build(centerline, 2, [archCubic()]);
      expect(curved.isValid).assertTrue();
      expect(curved.outlinePoints.length > chord.outlinePoints.length).assertTrue();
      let maximumY: number = Number.NEGATIVE_INFINITY;
      for (const outlinePoint of curved.outlinePoints) {
        maximumY = Math.max(maximumY, outlinePoint.y);
      }
      expect(maximumY > 7.5).assertTrue();
    });

    it('is independent of raw sampling density when persisted cubic geometry matches', 0, () => {
      const builder: WidthOutlineBuilder = new WidthOutlineBuilder();
      const sparse: StrokePathPoint[] = [point(0, 0, 0.5), point(10, 0, 1.5)];
      const dense: StrokePathPoint[] = [
        point(0, 0, 0.5), point(1, 4, 0.1), point(5, -3, 1.9), point(10, 0, 1.5),
      ];
      const first = builder.build(sparse, 4, [archCubic()]);
      const reloaded = builder.build(dense, 4, [archCubic()]);
      expect(first.outlinePoints.length).assertEqual(reloaded.outlinePoints.length);
      for (let i: number = 0; i < first.outlinePoints.length; i++) {
        expect(close(first.outlinePoints[i], reloaded.outlinePoints[i].x,
          reloaded.outlinePoints[i].y)).assertTrue();
      }
    });

    it('maps each fitted segment to its monotonic width anchors', 0, () => {
      const centerline: StrokePathPoint[] = [
        point(0, 0, 1), point(5, 0, 2), point(10, 0, 0.5),
      ];
      const segments: CubicSegment[] = [
        {
          p0: { x: 0, y: 0 }, p1: { x: 1, y: 0 },
          p2: { x: 4, y: 0 }, p3: { x: 5, y: 0 },
        },
        {
          p0: { x: 5, y: 0 }, p1: { x: 6, y: 0 },
          p2: { x: 9, y: 0 }, p3: { x: 10, y: 0 },
        },
      ];
      const result = new WidthOutlineBuilder().build(centerline, 4, segments);
      expect(result.isValid).assertTrue();
      expect(contains(result.outlinePoints, 5, 4)).assertTrue();
      expect(contains(result.outlinePoints, 5, -4)).assertTrue();
    });

    it('uses denser angular sampling for a wide curved stroke', 0, () => {
      const centerline: StrokePathPoint[] = [point(0, 0), point(10, 0)];
      const builder: WidthOutlineBuilder = new WidthOutlineBuilder();
      const narrow = builder.build(centerline, 2, [archCubic()]);
      const wide = builder.build(centerline, 20, [archCubic()]);
      expect(wide.outlinePoints.length > narrow.outlinePoints.length).assertTrue();
    });

    it('uses a circular outside join and the stable inside intersection', 0, () => {
      const result = new WidthOutlineBuilder().build([
        point(0, 0), point(10, 0), point(10, 10),
      ], 2);
      expect(result.isValid).assertTrue();
      expect(contains(result.outlinePoints, 9, 1)).assertTrue();
      let outsideArcPoints: number = 0;
      for (const outlinePoint of result.outlinePoints) {
        const distance: number = Math.sqrt(
          (outlinePoint.x - 10) * (outlinePoint.x - 10) + outlinePoint.y * outlinePoint.y);
        if (outlinePoint.x >= 10 && outlinePoint.y <= 0 && Math.abs(distance - 1) < 1e-9) {
          outsideArcPoints++;
        }
      }
      expect(outsideArcPoints >= 3).assertTrue();
    });

    it('bounds hairpin joins instead of emitting an excessive miter spike', 0, () => {
      const result = new WidthOutlineBuilder().build([
        point(0, 0), point(10, 0), point(0.1, 0.01), point(10, 0.02),
      ], 4);
      expect(result.isValid).assertTrue();
      expect(allFinite(result.outlinePoints)).assertTrue();
      for (const outlinePoint of result.outlinePoints) {
        expect(outlinePoint.x >= -3 && outlinePoint.x <= 13).assertTrue();
        expect(outlinePoint.y >= -3 && outlinePoint.y <= 3).assertTrue();
      }
    });

    it('keeps a self-crossing centerline finite without unbounded joins', 0, () => {
      const result = new WidthOutlineBuilder().build([
        point(0, 0), point(10, 10), point(0, 10), point(10, 0),
      ], 3);
      expect(result.isValid).assertTrue();
      expect(allFinite(result.outlinePoints)).assertTrue();
      for (const outlinePoint of result.outlinePoints) {
        expect(outlinePoint.x >= -3 && outlinePoint.x <= 13).assertTrue();
        expect(outlinePoint.y >= -3 && outlinePoint.y <= 13).assertTrue();
      }
    });

    it('falls back to finite source points when persisted cubic data is corrupt', 0, () => {
      const corrupt: CubicSegment = {
        p0: { x: 0, y: 0 }, p1: { x: Number.NaN, y: 1 },
        p2: { x: 9, y: 1 }, p3: { x: 10, y: 0 },
      };
      const result = new WidthOutlineBuilder().build([
        point(0, 0), point(10, 0),
      ], 2, [corrupt]);
      expect(result.isValid).assertTrue();
      expect(allFinite(result.outlinePoints)).assertTrue();
    });
  });
}
