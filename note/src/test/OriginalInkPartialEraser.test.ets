import { describe, expect, it } from '@ohos/hypium';
import { BitmapTransferTracker } from '../main/ets/core/adaptation/BitmapTransferTracker';
import {
  Canvas2DOffscreenRenderContext, Canvas2DStrokeRenderer,
} from '../main/ets/core/adaptation/Canvas2DStrokeRenderer';
import {
  ORIGINAL_PENCIL_FALLBACK_SEED, PencilSplatGenerator,
} from '../main/ets/core/algorithm/PencilSplatGenerator';
import { CubicSegment, TransformMatrix } from '../main/ets/core/model/GeometryTypes';
import { PageElementKind } from '../main/ets/core/model/PageElementOrder';
import {
  InkPathCommand, InkPathCommandType, InkStyle, InkStyleMapEntry, PencilSplatPoint,
  StrokeElementData, StrokePathPoint, TapePattern,
} from '../main/ets/core/model/StrokeTypes';
import {
  OriginalPartialErasePlan, validateOriginalPartialErasePlan,
} from '../main/ets/data/StrokePersistence';
import {
  InkPartialEraseReplacement, OriginalInkPartialEraser,
} from '../main/ets/rendering/OriginalInkPartialEraser';
import { StrokeCanvasPainter } from '../main/ets/rendering/StrokeCanvasPainter';

const IDENTITY: TransformMatrix = [1, 0, 0, 0, 1, 0, 0, 0, 1];

function pathPoint(x: number, y: number, widthFactor: number = 1,
  pressure: number = 1): StrokePathPoint {
  return {
    position: { x: x, y: y }, widthFactor: widthFactor, pressure: pressure,
    altitudeAngleRadians: Math.PI / 2, azimuthUnitX: 1, azimuthUnitY: 0,
  };
}

function lineStroke(id: string = 'op:40:2', style: InkStyle = InkStyle.FIXED_WIDTH,
  pencil: boolean = false, width: number = 2, endX: number = 100): StrokeElementData {
  return {
    id: id, pathPoints: [pathPoint(0, 0), pathPoint(endX, 0)], cubicSegments: [],
    splatPoints: [], renderSpec: {
      color: 0xFF102030, brushWidth: width, inkStyle: style,
      isHighlighter: false, isPencil: pencil,
    },
    transform: IDENTITY.slice(),
    bounds: { left: -width, top: -width, right: endX + width, bottom: width },
    maskPath: [], customPath: null, fillPath: null, fillColor: null,
    isFinished: true,
  };
}

function rectangle(left: number, top: number, right: number,
  bottom: number): InkPathCommand[] {
  return [
    { type: InkPathCommandType.MOVE_TO, points: [{ x: left, y: top }] },
    { type: InkPathCommandType.LINE_TO, points: [{ x: right, y: top }] },
    { type: InkPathCommandType.LINE_TO, points: [{ x: right, y: bottom }] },
    { type: InkPathCommandType.LINE_TO, points: [{ x: left, y: bottom }] },
    { type: InkPathCommandType.LINE_TO, points: [{ x: left, y: top }] },
  ];
}

function minimumCenterX(stroke: StrokeElementData): number {
  let result: number = Number.MAX_VALUE;
  for (const point of stroke.pathPoints) {
    result = Math.min(result, point.position.x);
  }
  return result;
}

function maximumCenterX(stroke: StrokeElementData): number {
  let result: number = -Number.MAX_VALUE;
  for (const point of stroke.pathPoints) {
    result = Math.max(result, point.position.x);
  }
  return result;
}

function rightmost(remnants: StrokeElementData[]): StrokeElementData {
  let result: StrokeElementData = remnants[0];
  let resultMinimum: number = minimumCenterX(result);
  for (let index: number = 1; index < remnants.length; index++) {
    const candidateMinimum: number = minimumCenterX(remnants[index]);
    if (candidateMinimum > resultMinimum) {
      result = remnants[index];
      resultMinimum = candidateMinimum;
    }
  }
  return result;
}

function alphaAt(context: OffscreenCanvasRenderingContext2D,
  x: number, y: number): number {
  return context.getImageData(x, y, 1, 1).data[3];
}

function assertPatternPhase(style: InkStyle, period: number, id: string): void {
  const source: StrokeElementData = lineStroke(id, style, false, 2, 30);
  source.styleMap = [{
    backingPencilSeed: 73,
    backingPencilReferencePoint: { x: 7, y: 9 },
    backingDashPhase: 1,
    backingDashPeriod: period,
  }];
  const replacements: InkPartialEraseReplacement[] =
    new OriginalInkPartialEraser(2).erase(
      [{ x: 10, y: -10 }, { x: 10, y: 10 }], [source]);
  expect(replacements.length).assertEqual(1);
  const right: StrokeElementData = rightmost(replacements[0].remnants);
  const entry: InkStyleMapEntry = (right.styleMap as InkStyleMapEntry[])[0];
  const expected: number = (1 + minimumCenterX(right)) % period;
  expect(Math.abs(entry.backingDashPhase - expected) < 0.01).assertTrue();
  expect(entry.backingDashPeriod).assertEqual(period);
  expect(entry.backingPencilSeed).assertEqual(0);
  expect(entry.backingPencilReferencePoint.x).assertEqual(0);
  expect(entry.backingPencilReferencePoint.y).assertEqual(0);
  expect(Math.abs((right.renderSpec.inkEffectPhase as number) - expected) < 0.01).assertTrue();
}

export default function originalInkPartialEraserTest() {
  describe('OriginalInkPartialEraser', () => {
    it('clips the visual outline without expanding center clipping by half the Ink width', 0, () => {
      const source: StrokeElementData = lineStroke('op:40:2', InkStyle.FIXED_WIDTH,
        false, 10);
      const replacements: InkPartialEraseReplacement[] =
        new OriginalInkPartialEraser(2).erase([{ x: 50, y: 5.5 }], [source]);
      expect(replacements.length).assertEqual(1);
      expect(replacements[0].remnants.length).assertEqual(1);
      expect(minimumCenterX(replacements[0].remnants[0]) < 0.001).assertTrue();
      expect(maximumCenterX(replacements[0].remnants[0]) > 99.999).assertTrue();
    });

    it('preserves native cubic center verbs and interpolated boundary attributes', 0, () => {
      const source: StrokeElementData = lineStroke(
        'op:41:2', InkStyle.VARIABLE_WIDTH, false, 2, 20);
      source.pathPoints = [pathPoint(0, 0, 1), pathPoint(20, 0, 3)];
      const cubic: CubicSegment = {
        p0: { x: 0, y: 0 }, p1: { x: 5, y: 20 },
        p2: { x: 15, y: 20 }, p3: { x: 20, y: 0 },
      };
      source.cubicSegments = [cubic];
      const replacements: InkPartialEraseReplacement[] =
        new OriginalInkPartialEraser(2).erase(
          [{ x: 10, y: -5 }, { x: 10, y: 25 }], [source]);
      expect(replacements.length).assertEqual(1);
      let hasCurvedCubic: boolean = false;
      let hasInterpolatedWidth: boolean = false;
      for (const remnant of replacements[0].remnants) {
        for (const segment of remnant.cubicSegments) {
          const dx: number = segment.p3.x - segment.p0.x;
          const dy: number = segment.p3.y - segment.p0.y;
          const cross1: number = dx * (segment.p1.y - segment.p0.y) -
            dy * (segment.p1.x - segment.p0.x);
          const cross2: number = dx * (segment.p2.y - segment.p0.y) -
            dy * (segment.p2.x - segment.p0.x);
          hasCurvedCubic = hasCurvedCubic || Math.abs(cross1) > 0.0001 ||
            Math.abs(cross2) > 0.0001;
        }
        for (const point of remnant.pathPoints) {
          hasInterpolatedWidth = hasInterpolatedWidth ||
            point.widthFactor > 1.1 && point.widthFactor < 2.9;
        }
      }
      expect(hasCurvedCubic).assertTrue();
      expect(hasInterpolatedWidth).assertTrue();
    });

    it('clips explicit custom and fill paths independently and gates fill by fillColor', 0, () => {
      const source: StrokeElementData = lineStroke(
        'op:42:2', InkStyle.FIXED_WIDTH, false, 2, 20);
      source.customPath = rectangle(-1, -3, 21, 3);
      source.fillPath = rectangle(0, -6, 20, 6);
      source.fillColor = 0x6B405060;
      const replacements: InkPartialEraseReplacement[] =
        new OriginalInkPartialEraser(2).erase(
          [{ x: 10, y: -10 }, { x: 10, y: 10 }], [source]);
      expect(replacements.length).assertEqual(1);
      expect(replacements[0].remnants.length >= 2).assertTrue();
      for (const remnant of replacements[0].remnants) {
        expect(remnant.customPath !== null && remnant.customPath !== undefined).assertTrue();
        expect(remnant.fillPath !== null && remnant.fillPath !== undefined).assertTrue();
        expect(remnant.fillColor).assertEqual(0x6B405060);
      }

      const gated: StrokeElementData = lineStroke(
        'op:43:2', InkStyle.FIXED_WIDTH, false, 2, 20);
      gated.fillPath = rectangle(0, 10, 20, 20);
      gated.fillColor = null;
      expect(new OriginalInkPartialEraser(2).erase([{ x: 10, y: 15 }], [gated]).length)
        .assertEqual(0);
      gated.fillColor = 0xFF405060;
      expect(new OriginalInkPartialEraser(2).erase([{ x: 10, y: 15 }], [gated]).length)
        .assertEqual(1);
    });

    it('uses the original 2.84 Pencil outline multiplier together with path width factors', 0,
      () => {
        const source: StrokeElementData = lineStroke(
          'op:44:2', InkStyle.FIXED_WIDTH, true, 2, 20);
        source.pathPoints = [pathPoint(0, 0, 2), pathPoint(20, 0, 2)];
        const replacements: InkPartialEraseReplacement[] =
          new OriginalInkPartialEraser(1).erase([{ x: 10, y: 4.5 }], [source]);
        expect(replacements.length).assertEqual(1);
        expect(minimumCenterX(replacements[0].remnants[0]) < 0.001).assertTrue();
        expect(maximumCenterX(replacements[0].remnants[0]) > 19.999).assertTrue();
      });

    it('advances Pencil seed/reference at a clipped boundary and rebuilds stable splats', 0, () => {
      const source: StrokeElementData = lineStroke(
        'op:45:2', InkStyle.FIXED_WIDTH, true, 4, 40);
      source.styleMap = [{
        backingPencilSeed: 1234,
        backingPencilReferencePoint: { x: 0, y: 0 },
        backingDashPhase: 7,
        backingDashPeriod: 8,
      }];
      const replacements: InkPartialEraseReplacement[] =
        new OriginalInkPartialEraser(4).erase(
          [{ x: 20, y: -10 }, { x: 20, y: 10 }], [source]);
      expect(replacements.length).assertEqual(1);
      const right: StrokeElementData = rightmost(replacements[0].remnants);
      const entry: InkStyleMapEntry = (right.styleMap as InkStyleMapEntry[])[0];
      expect(entry.backingPencilSeed === 1234).assertFalse();
      expect(entry.backingPencilSeed === ORIGINAL_PENCIL_FALLBACK_SEED).assertFalse();
      expect(entry.backingPencilReferencePoint.x !== 0 ||
        entry.backingPencilReferencePoint.y !== 0).assertTrue();
      expect(entry.backingDashPhase).assertEqual(0);
      expect(entry.backingDashPeriod).assertEqual(0);
      const generator: PencilSplatGenerator = new PencilSplatGenerator({
        spacing: right.renderSpec.brushWidth,
      });
      generator.reset(entry.backingPencilSeed);
      const rebuilt: PencilSplatPoint[] = generator.generate(
        right.cubicSegments, right.pathPoints, undefined,
        entry.backingPencilReferencePoint);
      expect(JSON.stringify(rebuilt)).assertEqual(JSON.stringify(right.splatPoints));

      const plan: OriginalPartialErasePlan = { replacements: [{
        sourceKind: PageElementKind.STROKE, source: source,
        remnants: replacements[0].remnants,
      }] };
      validateOriginalPartialErasePlan(plan);
      expect(plan.replacements.length).assertEqual(1);
    });

    it('advances both DASH and DOTS phase while resetting unrelated style registers', 0, () => {
      assertPatternPhase(InkStyle.DASH, 6, 'op:46:2');
      assertPatternPhase(InkStyle.DOTS, 4.002, 'op:47:2');
    });

    it('recomputes AudioLinked timing from retained center distance', 0, () => {
      const source: StrokeElementData = lineStroke(
        'op:48:2', InkStyle.FIXED_WIDTH, false, 2, 100);
      source.audioStartTime = '1000';
      source.audioDuration = 1000;
      const replacements: InkPartialEraseReplacement[] =
        new OriginalInkPartialEraser(20).erase(
          [{ x: 50, y: -10 }, { x: 50, y: 10 }], [source]);
      expect(replacements.length).assertEqual(1);
      const right: StrokeElementData = rightmost(replacements[0].remnants);
      expect(Math.abs(Number(right.audioStartTime) - 1600) <= 1).assertTrue();
      expect(Math.abs((right.audioDuration as number) - 400) <= 1).assertTrue();
    });

    it('inverse-transforms the eraser and preserves transform, effects, and Tape state', 0, () => {
      const source: StrokeElementData = lineStroke(
        'op:49:2', InkStyle.FIXED_WIDTH, false, 2, 20);
      source.transform = [1, 0, 100, 0, 1, 50, 0, 0, 1];
      source.renderSpec.inkEffects = '3';
      source.renderSpec.inkEffectsTinted = false;
      source.renderSpec.tapePattern = TapePattern.WAVES;
      const replacements: InkPartialEraseReplacement[] =
        new OriginalInkPartialEraser(2).erase(
          [{ x: 110, y: 40 }, { x: 110, y: 60 }], [source]);
      expect(replacements.length).assertEqual(1);
      for (const remnant of replacements[0].remnants) {
        expect(JSON.stringify(remnant.transform)).assertEqual(JSON.stringify(source.transform));
        expect(remnant.renderSpec.inkEffects).assertEqual('3');
        expect(remnant.renderSpec.inkEffectsTinted).assertFalse();
        expect(remnant.renderSpec.tapePattern).assertEqual(TapePattern.WAVES);
      }
    });

    it('can erase a persisted fill-only component with an empty custom-path sentinel', 0, () => {
      const source: StrokeElementData = lineStroke(
        'op:50:2', InkStyle.FIXED_WIDTH, false, 2, 20);
      source.pathPoints = [pathPoint(2, 10)];
      source.cubicSegments = [];
      source.customPath = [{
        type: InkPathCommandType.MOVE_TO, points: [{ x: 2, y: 10 }],
      }];
      source.fillPath = rectangle(0, 0, 20, 20);
      source.fillColor = 0xFF405060;
      const replacements: InkPartialEraseReplacement[] =
        new OriginalInkPartialEraser(2).erase(
          [{ x: 10, y: -5 }, { x: 10, y: 25 }], [source]);
      expect(replacements.length).assertEqual(1);
      expect(replacements[0].remnants.length >= 2).assertTrue();
      for (const remnant of replacements[0].remnants) {
        expect(remnant.fillPath !== null && remnant.fillPath !== undefined).assertTrue();
        expect(remnant.customPath !== null && remnant.customPath !== undefined).assertTrue();
        expect(remnant.fillColor).assertEqual(0xFF405060);
      }
    });

    it('partially clips a single-point Ink and fails closed for a singular transform', 0, () => {
      const dot: StrokeElementData = lineStroke(
        'op:51:2', InkStyle.FIXED_WIDTH, false, 10, 0);
      dot.pathPoints = [pathPoint(0, 0)];
      dot.cubicSegments = [];
      const replacements: InkPartialEraseReplacement[] =
        new OriginalInkPartialEraser(2).erase([{ x: 0, y: 4.5 }], [dot]);
      expect(replacements.length).assertEqual(1);
      expect(replacements[0].remnants[0].pathPoints.length).assertEqual(1);

      const singular: StrokeElementData = lineStroke('op:52:2');
      singular.transform = [0, 0, 0, 0, 1, 0, 0, 0, 1];
      expect(new OriginalInkPartialEraser(2).erase(
        [{ x: 50, y: -10 }, { x: 50, y: 10 }], [singular]).length).assertEqual(0);
    });

    it('clips Pencil splats to a remnant custom path in the shared canvas painter', 0, () => {
      const canvas: OffscreenCanvas = new OffscreenCanvas(100, 40);
      const context: OffscreenCanvasRenderingContext2D =
        canvas.getContext('2d', new RenderingContextSettings(true));
      const renderer: Canvas2DStrokeRenderer = new Canvas2DStrokeRenderer();
      const painter: StrokeCanvasPainter = new StrokeCanvasPainter(
        renderer, new BitmapTransferTracker());
      const source: StrokeElementData = lineStroke(
        'pencil-clip', InkStyle.FIXED_WIDTH, true, 4, 40);
      source.pathPoints = [pathPoint(20, 20), pathPoint(40, 20)];
      source.splatPoints = [
        { x: 30, y: 20, rotation: 0, scale: 4, opacity: 1 },
        { x: 70, y: 20, rotation: 0, scale: 4, opacity: 1 },
      ];
      source.customPath = rectangle(20, 10, 40, 30);
      painter.renderStroke(source, new Canvas2DOffscreenRenderContext(context), 100, 40);
      expect(alphaAt(context, 30, 20) > 0).assertTrue();
      expect(alphaAt(context, 70, 20)).assertEqual(0);
    });
  });
}
