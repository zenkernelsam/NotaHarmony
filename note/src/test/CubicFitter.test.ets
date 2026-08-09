import { describe, it, expect } from '@ohos/hypium';
import { CubicFitter } from '../main/ets/core/algorithm/CubicFitter';
import { CubicSegment, Point2D } from '../main/ets/core/model/GeometryTypes';
import { StrokePathPoint } from '../main/ets/core/model/StrokeTypes';

function pathPoint(x: number, y: number = 0): StrokePathPoint {
  return {
    position: { x: x, y: y },
    widthFactor: 1,
    pressure: 1,
    altitudeAngleRadians: Math.PI / 2,
    azimuthUnitX: 1,
    azimuthUnitY: 0,
  };
}

function straightPoints(count: number): StrokePathPoint[] {
  const points: StrokePathPoint[] = [];
  for (let i: number = 0; i < count; i++) {
    points.push(pathPoint(i));
  }
  return points;
}

function isFinitePoint(point: Point2D): boolean {
  return Number.isFinite(point.x) && Number.isFinite(point.y);
}

export default function cubicFitterTest() {
  describe('CubicFitter', () => {
    it('uses linear one-third handles for two points', 0, () => {
      const segments: CubicSegment[] = new CubicFitter().fit([
        pathPoint(0), pathPoint(3),
      ], 1, 1);
      expect(segments.length).assertEqual(1);
      expect(segments[0].p0.x).assertEqual(0);
      expect(segments[0].p1.x).assertEqual(1);
      expect(segments[0].p2.x).assertEqual(2);
      expect(segments[0].p3.x).assertEqual(3);
    });

    it('projects the fitted first handle onto the supplied initial tangent', 0, () => {
      const segments: CubicSegment[] = new CubicFitter().fit([
        pathPoint(0), pathPoint(3),
      ], 1, 1, { x: 1, y: 1 });
      expect(Math.abs(segments[0].p1.x - 0.5) < 1e-12).assertTrue();
      expect(Math.abs(segments[0].p1.y - 0.5) < 1e-12).assertTrue();
    });

    it('enforces the per-evaluation point limit on long straight input', 0, () => {
      const segments: CubicSegment[] = new CubicFitter().fit(straightPoints(1000), 1, 1);
      expect(segments.length >= 5).assertTrue();
      expect(segments[segments.length - 1].p3.x).assertEqual(999);
      for (const segment of segments) {
        expect(isFinitePoint(segment.p0)).assertTrue();
        expect(isFinitePoint(segment.p1)).assertTrue();
        expect(isFinitePoint(segment.p2)).assertTrue();
        expect(isFinitePoint(segment.p3)).assertTrue();
      }
    });

    it('applies the four-point threshold after calculating the half endpoint', 0, () => {
      const fitter: CubicFitter = new CubicFitter({ maxPointsPerSegment: 7 });
      const segments: CubicSegment[] = fitter.fit(straightPoints(8), 1, 1);
      expect(segments.length).assertEqual(2);
      expect(segments[0].p3.x).assertEqual(3);
      expect(segments[1].p0.x).assertEqual(3);
      expect(segments[1].p3.x).assertEqual(7);
    });
  });
}
