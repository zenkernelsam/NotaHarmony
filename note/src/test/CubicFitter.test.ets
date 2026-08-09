import { describe, it, expect } from '@ohos/hypium';
import {
  computeOriginalFitTolerance, CubicAttributeSplitOptions, CubicFitResult, CubicFitter,
} from '../main/ets/core/algorithm/CubicFitter';
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

function attributePoint(x: number, widthFactor: number, pressure: number,
  altitude: number, azimuthX: number, azimuthY: number): StrokePathPoint {
  return {
    position: { x: x, y: 0 },
    widthFactor: widthFactor,
    pressure: pressure,
    altitudeAngleRadians: altitude,
    azimuthUnitX: azimuthX,
    azimuthUnitY: azimuthY,
  };
}

function isFinitePoint(point: Point2D): boolean {
  return Number.isFinite(point.x) && Number.isFinite(point.y);
}

export default function cubicFitterTest() {
  describe('CubicFitter', () => {
    it('matches the original clamped tolerance table', 0, () => {
      const widths: number[] = [1, 2.6, 10, 18, 30];
      const expected: number[] = [0.5, 0.5, 0.29056603773584905, 0.2, 0.2];
      for (let i: number = 0; i < widths.length; i++) {
        const actual: number = computeOriginalFitTolerance(widths[i], 1);
        expect(Math.abs(actual - expected[i]) < 1e-12).assertTrue();
      }
    });

    it('applies zoom both before the clamp and after the ratio', 0, () => {
      expect(Math.abs(computeOriginalFitTolerance(10, 2) - 0.1) < 1e-12).assertTrue();
    });

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

    it('uses the original quadratic extrapolation for three points', 0, () => {
      const segments: CubicSegment[] = new CubicFitter().fit([
        pathPoint(0, 0), pathPoint(1, 2), pathPoint(2, 0),
      ], 1, 1);
      expect(segments.length).assertEqual(1);
      expect(Math.abs(segments[0].p1.x - 2 / 3) < 1e-12).assertTrue();
      expect(Math.abs(segments[0].p1.y - 8 / 3) < 1e-12).assertTrue();
      expect(Math.abs(segments[0].p2.x - 4 / 3) < 1e-12).assertTrue();
      expect(Math.abs(segments[0].p2.y - 8 / 3) < 1e-12).assertTrue();
    });

    it('returns no segment for a single point without span pollution', 0, () => {
      expect(new CubicFitter().fit([pathPoint(4, 7)], 1, 1).length).assertEqual(0);
    });

    it('projects the fitted first handle onto the supplied initial tangent', 0, () => {
      const segments: CubicSegment[] = new CubicFitter().fit([
        pathPoint(0), pathPoint(3),
      ], 1, 1, { x: 1, y: 1 });
      expect(Math.abs(segments[0].p1.x - 0.5) < 1e-12).assertTrue();
      expect(Math.abs(segments[0].p1.y - 0.5) < 1e-12).assertTrue();
    });

    it('keeps the fitted handle when the continuity tangent is degenerate', 0, () => {
      const segments: CubicSegment[] = new CubicFitter().fit([
        pathPoint(0), pathPoint(3),
      ], 1, 1, { x: 0, y: 0 });
      expect(segments[0].p1.x).assertEqual(1);
      expect(segments[0].p1.y).assertEqual(0);
    });

    it('applies the 200-point predicate before accepting 201 points', 0, () => {
      const result: CubicFitResult = new CubicFitter().fitWithSourceRanges(
        straightPoints(201), 1, 1);
      expect(result.segments.length).assertEqual(2);
      expect(result.sourceRanges[0].endIndex).assertEqual(99);
      expect(result.sourceRanges[1].startIndex).assertEqual(99);
      expect(result.sourceRanges[1].endIndex).assertEqual(200);
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

    it('retains contiguous source ranges for every fitted segment', 0, () => {
      const result: CubicFitResult = new CubicFitter().fitWithSourceRanges(
        straightPoints(1000), 1, 1);
      expect(result.segments.length).assertEqual(result.sourceRanges.length);
      expect(result.sourceRanges[0].startIndex).assertEqual(0);
      expect(result.sourceRanges[result.sourceRanges.length - 1].endIndex).assertEqual(999);
      for (let i: number = 1; i < result.sourceRanges.length; i++) {
        expect(result.sourceRanges[i].startIndex)
          .assertEqual(result.sourceRanges[i - 1].endIndex);
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

    it('falls back to finite handles when an interior sample is non-finite', 0, () => {
      const segments: CubicSegment[] = new CubicFitter().fit([
        pathPoint(0), pathPoint(1, Number.NaN), pathPoint(2), pathPoint(3),
      ], 1, 1);
      expect(segments.length).assertEqual(1);
      expect(isFinitePoint(segments[0].p0)).assertTrue();
      expect(isFinitePoint(segments[0].p1)).assertTrue();
      expect(isFinitePoint(segments[0].p2)).assertTrue();
      expect(isFinitePoint(segments[0].p3)).assertTrue();
    });

    it('splits pencil geometry at an intermediate pressure deviation', 0, () => {
      const options: CubicAttributeSplitOptions = {
        preserveWidth: false,
        preservePencilAttributes: true,
      };
      const result: CubicFitResult = new CubicFitter().fitWithSourceRanges([
        attributePoint(0, 1, 0, 1, 1, 0),
        attributePoint(1, 1, 1, 1, 1, 0),
        attributePoint(2, 1, 0, 1, 1, 0),
      ], 1, 1, undefined, options);
      expect(result.segments.length).assertEqual(2);
      expect(result.sourceRanges[0].startIndex).assertEqual(0);
      expect(result.sourceRanges[0].endIndex).assertEqual(1);
      expect(result.sourceRanges[1].startIndex).assertEqual(1);
      expect(result.sourceRanges[1].endIndex).assertEqual(2);
      expect(result.segments[0].p3.x).assertEqual(result.segments[1].p0.x);
      expect(result.segments[0].p3.y).assertEqual(result.segments[1].p0.y);
    });

    it('keeps pressure deviations at the original threshold unsplit', 0, () => {
      const options: CubicAttributeSplitOptions = {
        preserveWidth: false,
        preservePencilAttributes: true,
      };
      const result: CubicFitResult = new CubicFitter().fitWithSourceRanges([
        attributePoint(0, 1, 0, 1, 1, 0),
        attributePoint(1, 1, 0.25, 1, 1, 0),
        attributePoint(2, 1, 0, 1, 1, 0),
      ], 1, 1, undefined, options);
      expect(result.segments.length).assertEqual(1);
    });

    it('splits variable width by screen-space error', 0, () => {
      const options: CubicAttributeSplitOptions = {
        preserveWidth: true,
        preservePencilAttributes: false,
      };
      const result: CubicFitResult = new CubicFitter().fitWithSourceRanges([
        attributePoint(0, 1, 1, 1, 1, 0),
        attributePoint(1, 1.1, 1, 1, 1, 0),
        attributePoint(2, 1, 1, 1, 1, 0),
      ], 10, 1, undefined, options);
      expect(result.segments.length).assertEqual(2);
    });

    it('splits pencil geometry at altitude and azimuth deviations', 0, () => {
      const options: CubicAttributeSplitOptions = {
        preserveWidth: false,
        preservePencilAttributes: true,
      };
      const altitude: CubicFitResult = new CubicFitter().fitWithSourceRanges([
        attributePoint(0, 1, 1, 1, 1, 0),
        attributePoint(1, 1, 1, 1.1, 1, 0),
        attributePoint(2, 1, 1, 1, 1, 0),
      ], 1, 1, undefined, options);
      const azimuth: CubicFitResult = new CubicFitter().fitWithSourceRanges([
        attributePoint(0, 1, 1, 1, 1, 0),
        attributePoint(1, 1, 1, 1, 0.98, 0.02),
        attributePoint(2, 1, 1, 1, 1, 0),
      ], 1, 1, undefined, options);
      expect(altitude.segments.length).assertEqual(2);
      expect(azimuth.segments.length).assertEqual(2);
    });
  });
}
