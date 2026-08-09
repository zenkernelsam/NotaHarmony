import { describe, it, expect } from '@ohos/hypium';
import { PencilSplatGenerator } from '../main/ets/core/algorithm/PencilSplatGenerator';
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
  const generator: PencilSplatGenerator = new PencilSplatGenerator({ spacing: 4 });
  generator.reset(12345);
  return generator.generate([straightSegment()], [
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
