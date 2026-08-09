import { describe, it, expect } from '@ohos/hypium';
import { EraserEngine, EraserMode, EraseResult } from '../main/ets/rendering/EraserEngine';
import {
  ERASER_PATH_BREAK_COORDINATE, InkStyle, StrokeElementData, StrokePathPoint,
} from '../main/ets/core/model/StrokeTypes';
import { Point2D, TransformMatrix } from '../main/ets/core/model/GeometryTypes';

function makeStroke(id: string, points: Point2D[], transform?: TransformMatrix,
  maskPath?: Point2D[]): StrokeElementData {
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
      brushWidth: 2,
      inkStyle: InkStyle.FIXED_WIDTH,
      isHighlighter: false,
      isPencil: false,
    },
    transform: transform !== undefined ? transform : [1, 0, 0, 0, 1, 0, 0, 0, 1],
    bounds: { left: left, top: top, right: right, bottom: bottom },
    maskPath: maskPath !== undefined ? maskPath : [],
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

    it('separates independent partial eraser gestures', 0, () => {
      const stroke: StrokeElementData = makeStroke('partial', [{ x: 0, y: 0 }, { x: 100, y: 0 }]);
      const engine: EraserEngine = new EraserEngine(EraserMode.PARTIAL, 4);
      const first: StrokeElementData = engine.erase([{ x: 10, y: 0 }], [stroke]).affectedStrokes[0];
      const second: StrokeElementData = engine.erase([{ x: 90, y: 0 }], [first]).affectedStrokes[0];
      expect(second.maskPath.length).assertEqual(3);
      expect(second.maskPath[1].x).assertEqual(ERASER_PATH_BREAK_COORDINATE);
      expect(second.maskPath[1].y).assertEqual(ERASER_PATH_BREAK_COORDINATE);
    });

    it('hit-tests transformed strokes and stores partial masks in local coordinates', 0, () => {
      const transform: TransformMatrix = [1, 0, 50, 0, 1, 20, 0, 0, 1];
      const stroke: StrokeElementData = makeStroke('translated', [{ x: 0, y: 0 }, { x: 20, y: 0 }], transform);
      const result: EraseResult = new EraserEngine(EraserMode.PARTIAL, 4)
        .erase([{ x: 60, y: 20 }], [stroke]);
      expect(result.affectedStrokes.length).assertEqual(1);
      expect(result.affectedStrokes[0].maskPath[0].x).assertEqual(10);
      expect(result.affectedStrokes[0].maskPath[0].y).assertEqual(0);
    });
  });
}
