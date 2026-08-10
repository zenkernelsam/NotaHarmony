import { describe, it, expect } from '@ohos/hypium';
import {
  PencilSplatGenerator, PencilSplatLimitError,
} from '../main/ets/core/algorithm/PencilSplatGenerator';
import { CubicSourceRange } from '../main/ets/core/algorithm/CubicFitter';
import { CubicSegment } from '../main/ets/core/model/GeometryTypes';
import {
  InkStyle, InputBatchKind, InputPoint, InputToolType, PencilSplatPoint, RenderSpec, StrokePathPoint,
} from '../main/ets/core/model/StrokeTypes';
import { StrokeSession } from '../main/ets/rendering/StrokeSession';

function straightSegment(): CubicSegment {
  return {
    p0: { x: 0, y: 0 },
    p1: { x: 10, y: 0 },
    p2: { x: 20, y: 0 },
    p3: { x: 30, y: 0 },
  };
}

function verticalSegment(): CubicSegment {
  return {
    p0: { x: 0, y: 0 },
    p1: { x: 0, y: 10 },
    p2: { x: 0, y: 20 },
    p3: { x: 0, y: 30 },
  };
}

function appendedStraightSegment(): CubicSegment {
  return {
    p0: { x: 30, y: 0 },
    p1: { x: 40, y: 0 },
    p2: { x: 50, y: 0 },
    p3: { x: 60, y: 0 },
  };
}

function pencilPoint(x: number, pressure: number, altitude: number,
  azimuthX: number, azimuthY: number): StrokePathPoint {
  return {
    position: { x: x, y: 0 },
    widthFactor: 0.3 + 0.7 * pressure,
    pressure: pressure,
    altitudeAngleRadians: altitude,
    azimuthUnitX: azimuthX,
    azimuthUnitY: azimuthY,
  };
}

function generate(pressure: number, altitude: number, azimuthX: number,
  azimuthY: number): PencilSplatPoint[] {
  return generateOnSegment(straightSegment(), pressure, altitude, azimuthX, azimuthY);
}

function generateOnSegment(segment: CubicSegment, pressure: number, altitude: number,
  azimuthX: number, azimuthY: number): PencilSplatPoint[] {
  const generator: PencilSplatGenerator = new PencilSplatGenerator({ spacing: 4 });
  generator.reset(12345);
  return generator.generate([segment], [
    pencilPoint(0, pressure, altitude, azimuthX, azimuthY),
    pencilPoint(30, pressure, altitude, azimuthX, azimuthY),
  ]);
}

export default function pencilSplatGeneratorTest() {
  describe('PencilSplatGenerator', () => {
    it('uses one splat per walk position for an upright pencil', 0, () => {
      const upright: PencilSplatPoint[] = generate(1, Math.PI / 2, 1, 0);
      const tilted: PencilSplatPoint[] = generate(1, 0.2, 1, 0);
      expect(upright.length > 0).assertTrue();
      expect(tilted.length > upright.length * 5).assertTrue();
    });

    it('uses force rather than width factor for opacity', 0, () => {
      const light: PencilSplatPoint[] = generate(0, 0.2, 1, 0);
      const heavy: PencilSplatPoint[] = generate(1, 0.2, 1, 0);
      expect(light.length > 0).assertTrue();
      expect(heavy.length > 0).assertTrue();
      expect(light[0].opacity < heavy[0].opacity).assertTrue();
    });

    it('rotates dispersion with the stylus azimuth vector', 0, () => {
      const horizontal: PencilSplatPoint[] = generate(1, 0.2, 1, 0);
      const vertical: PencilSplatPoint[] = generate(1, 0.2, 0, 1);
      expect(horizontal.length).assertEqual(vertical.length);
      const dx: number = Math.abs(horizontal[0].x - vertical[0].x);
      const dy: number = Math.abs(horizontal[0].y - vertical[0].y);
      expect(dx + dy > 0.0001).assertTrue();
    });

    it('matches the original fixed-seed first splat', 0, () => {
      const splats: PencilSplatPoint[] = generate(0.8, 0.2, 0, 1);
      expect(splats.length >= 18).assertTrue();
      expect(Math.abs(splats[0].x - (-11.450678740197482)) < 1e-10).assertTrue();
      expect(Math.abs(splats[0].y - 17.59178049583085) < 1e-10).assertTrue();
      expect(Math.abs(splats[0].rotation - 0.02337137604544309) < 1e-12).assertTrue();
      expect(Math.abs(splats[0].scale - 1.4764619925891513) < 1e-12).assertTrue();
      expect(Math.abs(splats[0].opacity - 0.01981311951082389) < 1e-12).assertTrue();
    });

    it('reproduces the complete splat sequence for the same seed', 0, () => {
      const first: PencilSplatPoint[] = generate(0.8, 0.2, 0, 1);
      const second: PencilSplatPoint[] = generate(0.8, 0.2, 0, 1);
      expect(first.length).assertEqual(second.length);
      for (let i: number = 0; i < first.length; i++) {
        expect(first[i].x).assertEqual(second[i].x);
        expect(first[i].y).assertEqual(second[i].y);
        expect(first[i].rotation).assertEqual(second[i].rotation);
        expect(first[i].scale).assertEqual(second[i].scale);
        expect(first[i].opacity).assertEqual(second[i].opacity);
      }
    });

    it('normalizes a negative int32 backing seed like original cfa', 0, () => {
      const negative: PencilSplatGenerator = new PencilSplatGenerator({ spacing: 4 });
      negative.reset(-12345);
      const positive: PencilSplatGenerator = new PencilSplatGenerator({ spacing: 4 });
      positive.reset(12345);
      const points: StrokePathPoint[] = [
        pencilPoint(0, 0.8, 0.2, 1, 0), pencilPoint(30, 0.8, 0.2, 1, 0),
      ];
      const left: PencilSplatPoint[] = negative.generate([straightSegment()], points);
      const right: PencilSplatPoint[] = positive.generate([straightSegment()], points);
      expect(left.length).assertEqual(right.length);
      expect(left[0].x).assertEqual(right[0].x);
      expect(left[0].rotation).assertEqual(right[0].rotation);
    });

    it('starts the first walk from the stored Pencil reference point', 0, () => {
      const points: StrokePathPoint[] = [
        pencilPoint(0, 0.8, Math.PI / 2, 1, 0),
        pencilPoint(30, 0.8, Math.PI / 2, 1, 0),
      ];
      const base: PencilSplatGenerator = new PencilSplatGenerator({ spacing: 4 });
      base.reset(12345);
      const fromStart: PencilSplatPoint[] = base.generate([straightSegment()], points);
      const referenced: PencilSplatGenerator = new PencilSplatGenerator({ spacing: 4 });
      referenced.reset(12345);
      const fromReference: PencilSplatPoint[] = referenced.generate(
        [straightSegment()], points, undefined, { x: 10, y: 0 });
      expect(fromStart.length > fromReference.length).assertTrue();
      expect(fromReference[0].x > fromStart[0].x + 9).assertTrue();
    });

    it('preserves the existing splat prefix when the original path is appended', 0, () => {
      const shortPoints: StrokePathPoint[] = [
        pencilPoint(0, 0.8, 0.2, 1, 0), pencilPoint(30, 0.8, 0.2, 1, 0),
      ];
      const longPoints: StrokePathPoint[] = shortPoints.concat([
        pencilPoint(60, 0.8, 0.2, 1, 0),
      ]);
      const shortGenerator: PencilSplatGenerator = new PencilSplatGenerator({ spacing: 4 });
      shortGenerator.reset(-12345);
      const before: PencilSplatPoint[] = shortGenerator.generate(
        [straightSegment()], shortPoints, undefined, { x: 10, y: 0 });
      const longGenerator: PencilSplatGenerator = new PencilSplatGenerator({ spacing: 4 });
      longGenerator.reset(-12345);
      const after: PencilSplatPoint[] = longGenerator.generate(
        [straightSegment(), appendedStraightSegment()], longPoints, undefined, { x: 10, y: 0 });
      expect(after.length > before.length).assertTrue();
      for (let i: number = 0; i < before.length; i++) {
        expect(after[i].x).assertEqual(before[i].x);
        expect(after[i].y).assertEqual(before[i].y);
        expect(after[i].rotation).assertEqual(before[i].rotation);
        expect(after[i].opacity).assertEqual(before[i].opacity);
      }
    });

    it('rejects a configured remote materialization budget without truncation', 0, () => {
      const generator: PencilSplatGenerator = new PencilSplatGenerator({
        spacing: 4, maximumSplatCount: 10,
      });
      generator.reset(12345);
      let limited: boolean = false;
      try {
        generator.generate([straightSegment()], [
          pencilPoint(0, 0.8, 0.2, 1, 0), pencilPoint(30, 0.8, 0.2, 1, 0),
        ]);
      } catch (_error) {
        limited = _error instanceof PencilSplatLimitError;
      }
      expect(limited).assertTrue();
    });

    it('uses the original fixed azimuth fallback instead of the curve tangent', 0, () => {
      const missing: PencilSplatPoint[] = generateOnSegment(
        verticalSegment(), 0.8, 0.2, 0, 0);
      const originalFallback: PencilSplatPoint[] = generateOnSegment(
        verticalSegment(), 0.8, 0.2, 1, 0);
      expect(missing.length).assertEqual(originalFallback.length);
      expect(missing[0].x).assertEqual(originalFallback[0].x);
      expect(missing[0].y).assertEqual(originalFallback[0].y);
    });

    it('interpolates attributes from the fitted segment source range', 0, () => {
      const points: StrokePathPoint[] = [
        pencilPoint(0, 0, 0.2, 1, 0),
        pencilPoint(15, 0.8, 0.2, 1, 0),
        pencilPoint(30, 0.8, 0.2, 1, 0),
      ];
      const range: CubicSourceRange = { startIndex: 1, endIndex: 2 };
      const mappedGenerator: PencilSplatGenerator = new PencilSplatGenerator({ spacing: 4 });
      mappedGenerator.reset(12345);
      const mapped: PencilSplatPoint[] = mappedGenerator.generate(
        [straightSegment()], points, [range]);
      const legacyGenerator: PencilSplatGenerator = new PencilSplatGenerator({ spacing: 4 });
      legacyGenerator.reset(12345);
      const globalRatio: PencilSplatPoint[] = legacyGenerator.generate(
        [straightSegment()], points);
      expect(mapped[0].opacity > globalRatio[0].opacity).assertTrue();
      expect(mapped[0].scale > globalRatio[0].scale).assertTrue();
    });

    it('does not discard an intermediate pressure peak inside a source range', 0, () => {
      const peakPoints: StrokePathPoint[] = [
        pencilPoint(0, 0, 0.2, 1, 0),
        pencilPoint(15, 1, 0.2, 1, 0),
        pencilPoint(30, 0, 0.2, 1, 0),
      ];
      const flatPoints: StrokePathPoint[] = [
        pencilPoint(0, 0, 0.2, 1, 0),
        pencilPoint(15, 0, 0.2, 1, 0),
        pencilPoint(30, 0, 0.2, 1, 0),
      ];
      const range: CubicSourceRange = { startIndex: 0, endIndex: 2 };
      const peakGenerator: PencilSplatGenerator = new PencilSplatGenerator({ spacing: 4 });
      peakGenerator.reset(12345);
      const peak: PencilSplatPoint[] = peakGenerator.generate(
        [straightSegment()], peakPoints, [range]);
      const flatGenerator: PencilSplatGenerator = new PencilSplatGenerator({ spacing: 4 });
      flatGenerator.reset(12345);
      const flat: PencilSplatPoint[] = flatGenerator.generate(
        [straightSegment()], flatPoints, [range]);
      expect(peak[0].opacity > flat[0].opacity).assertTrue();
      expect(peak[0].scale > flat[0].scale).assertTrue();
    });

    it('keeps existing splats stable when the full stroke is rebuilt', 0, () => {
      const spec: RenderSpec = {
        color: 0xFF000000,
        brushWidth: 4,
        inkStyle: InkStyle.FIXED_WIDTH,
        isHighlighter: false,
        isPencil: true,
      };
      const points: InputPoint[] = [];
      for (let i: number = 0; i < 4; i++) {
        points.push({
          x: i * 10,
          y: 0,
          elapsedTimeMillis: i * 8,
          toolType: InputToolType.STYLUS,
          pressure: 0.8,
          tiltRadians: 0.2,
          orientationRadians: -Math.PI / 2,
        });
      }
      const session: StrokeSession = new StrokeSession(spec);
      session.beginStroke(spec, 12345, 1);
      session.addBatch({ kind: InputBatchKind.REAL, points: points });
      const first: PencilSplatPoint[] = session.getCurrentStroke()!.splatPoints.slice();
      session.addBatch({ kind: InputBatchKind.REAL, points: [] });
      const second: PencilSplatPoint[] = session.getCurrentStroke()!.splatPoints;
      expect(first.length > 0).assertTrue();
      expect(first.length).assertEqual(second.length);
      expect(first[0].x).assertEqual(second[0].x);
      expect(first[0].y).assertEqual(second[0].y);
      expect(first[0].opacity).assertEqual(second[0].opacity);
    });
  });
}
