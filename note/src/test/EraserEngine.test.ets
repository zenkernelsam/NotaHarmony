import { describe, it, expect } from '@ohos/hypium';
import {
  EraserEngine, EraserMode, EraseResult, PartialEraseReplacement,
} from '../main/ets/rendering/EraserEngine';
import { InkStyle, StrokeElementData, StrokePathPoint } from
  '../main/ets/core/model/StrokeTypes';
import { Point2D, TransformMatrix } from '../main/ets/core/model/GeometryTypes';

function makeStroke(id: string, points: Point2D[], transform?: TransformMatrix,
  brushWidth: number = 2, pencil: boolean = false): StrokeElementData {
  let left: number = points[0].x;
  let right: number = points[0].x;
  let top: number = points[0].y;
  let bottom: number = points[0].y;
  for (const point of points) {
    left = Math.min(left, point.x);
    right = Math.max(right, point.x);
    top = Math.min(top, point.y);
    bottom = Math.max(bottom, point.y);
  }
  return {
    id: id,
    pathPoints: points.map((point: Point2D): StrokePathPoint => ({
      position: point,
      widthFactor: 1,
      pressure: 1,
      altitudeAngleRadians: Math.PI / 2,
      azimuthUnitX: 1,
      azimuthUnitY: 0,
    })),
    cubicSegments: [],
    splatPoints: [],
    renderSpec: {
      color: 0xFF000000,
      brushWidth: brushWidth,
      inkStyle: InkStyle.FIXED_WIDTH,
      isHighlighter: false,
      isPencil: pencil,
    },
    transform: transform !== undefined ? transform : [1, 0, 0, 0, 1, 0, 0, 0, 1],
    bounds: { left: left, top: top, right: right, bottom: bottom },
    maskPath: [],
    isFinished: true,
  };
}

export default function eraserEngineTest() {
  describe('EraserEngine', () => {
    it('does not delete a distant stroke inside the full path AABB', 0, () => {
      const stroke: StrokeElementData = makeStroke('distant', [{ x: 10, y: 90 }, { x: 20, y: 90 }]);
      const result: EraseResult = new EraserEngine(EraserMode.WHOLE, 4)
        .erase([{ x: 0, y: 0 }, { x: 100, y: 100 }], [stroke]);
      expect(result.deletedStrokeIds.length).assertEqual(0);
    });

    it('deletes an exactly crossing stroke and supports a zero-length eraser tap', 0, () => {
      const crossing: StrokeElementData = makeStroke('crossing', [{ x: 0, y: 10 }, { x: 20, y: 10 }]);
      const engine: EraserEngine = new EraserEngine(EraserMode.WHOLE, 4);
      expect(engine.erase([{ x: 10, y: 0 }, { x: 10, y: 20 }], [crossing]).deletedStrokeIds[0])
        .assertEqual('crossing');
      expect(engine.erase([{ x: 10, y: 10 }], [crossing]).deletedStrokeIds[0]).assertEqual('crossing');
    });

    it('replaces a crossing Ink with two newly identified remnants', 0, () => {
      const stroke: StrokeElementData = makeStroke('partial', [{ x: 0, y: 0 }, { x: 100, y: 0 }]);
      const result: EraseResult = new EraserEngine(EraserMode.PARTIAL, 4)
        .erase([{ x: 50, y: 0 }], [stroke]);
      expect(result.partialReplacements.length).assertEqual(1);
      const replacement: PartialEraseReplacement = result.partialReplacements[0];
      expect(replacement.sourceStroke.id).assertEqual('partial');
      expect(replacement.remnants.length).assertEqual(2);
      expect(replacement.remnants[0].id === replacement.remnants[1].id).assertFalse();
      expect(replacement.remnants[0].maskPath.length).assertEqual(0);
      expect(replacement.remnants[0].pathPoints[
        replacement.remnants[0].pathPoints.length - 1].position.x < 50).assertTrue();
      expect(replacement.remnants[1].pathPoints[0].position.x > 50).assertTrue();
    });

    it('can split a previous pair of remnants again without reusing an entity ID', 0, () => {
      const stroke: StrokeElementData = makeStroke('multi', [{ x: 0, y: 0 }, { x: 100, y: 0 }]);
      const engine: EraserEngine = new EraserEngine(EraserMode.PARTIAL, 4);
      const first: StrokeElementData[] = engine.erase([{ x: 25, y: 0 }], [stroke])
        .partialReplacements[0].remnants;
      const second: EraseResult = engine.erase([{ x: 75, y: 0 }], first);
      expect(first.length).assertEqual(2);
      expect(second.partialReplacements.length).assertEqual(1);
      expect(second.partialReplacements[0].remnants.length).assertEqual(2);
      expect(second.partialReplacements[0].remnants[0].id.indexOf('#erase-') >= 0).assertTrue();
    });

    it('hit-tests transformed Ink and preserves its original transform on remnants', 0, () => {
      const transform: TransformMatrix = [1, 0, 50, 0, 1, 20, 0, 0, 1];
      const stroke: StrokeElementData = makeStroke(
        'translated', [{ x: 0, y: 0 }, { x: 20, y: 0 }], transform);
      const result: EraseResult = new EraserEngine(EraserMode.PARTIAL, 4)
        .erase([{ x: 60, y: 20 }], [stroke]);
      expect(result.partialReplacements.length).assertEqual(1);
      expect(result.partialReplacements[0].remnants.length).assertEqual(2);
      expect(result.partialReplacements[0].remnants[0].transform[2]).assertEqual(50);
      expect(result.partialReplacements[0].remnants[1].pathPoints[0].position.x > 10).assertTrue();
    });

    it('recomputes each AudioLinked Ink remnant interval from its source path range', 0, () => {
      const stroke: StrokeElementData = makeStroke(
        'audio', [{ x: 0, y: 0 }, { x: 100, y: 0 }]);
      stroke.audioStartTime = '9007199254740993';
      stroke.audioDuration = 1000;
      const remnants: StrokeElementData[] = new EraserEngine(EraserMode.PARTIAL, 4)
        .erase([{ x: 50, y: 0 }], [stroke]).partialReplacements[0].remnants;
      expect(remnants.length).assertEqual(2);
      expect(remnants[0].audioStartTime).assertEqual('9007199254740993');
      expect(remnants[0].audioStartTime === remnants[1].audioStartTime).assertFalse();
      expect((remnants[0].audioDuration as number) > 0 &&
        (remnants[0].audioDuration as number) < 1000).assertTrue();
      expect((remnants[1].audioDuration as number) > 0 &&
        (remnants[1].audioDuration as number) < 1000).assertTrue();
    });

    it('includes the Ink half-width in partial hit testing and fully removes a dot', 0, () => {
      const thick: StrokeElementData = makeStroke(
        'thick', [{ x: 0, y: 0 }, { x: 20, y: 0 }], undefined, 6);
      const thickResult: EraseResult = new EraserEngine(EraserMode.PARTIAL, 2)
        .erase([{ x: 10, y: 3.5 }], [thick]);
      expect(thickResult.partialReplacements.length).assertEqual(1);

      const dot: StrokeElementData = makeStroke('dot', [{ x: 5, y: 5 }]);
      const dotResult: EraseResult = new EraserEngine(EraserMode.PARTIAL, 4)
        .erase([{ x: 5, y: 5 }], [dot]);
      expect(dotResult.partialReplacements.length).assertEqual(1);
      expect(dotResult.partialReplacements[0].remnants.length).assertEqual(0);
    });

    it('leaves Pencil for the outline-clipping phase instead of flattening its texture', 0, () => {
      const pencil: StrokeElementData = makeStroke(
        'pencil', [{ x: 0, y: 0 }, { x: 20, y: 0 }], undefined, 2, true);
      expect(new EraserEngine(EraserMode.PARTIAL, 4)
        .erase([{ x: 10, y: 0 }], [pencil]).partialReplacements.length).assertEqual(0);
    });
  });
}
