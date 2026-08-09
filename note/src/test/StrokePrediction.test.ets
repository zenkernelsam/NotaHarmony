import { describe, it, expect } from '@ohos/hypium';
import {
  InkStyle, InputBatch, InputBatchKind, InputPoint, InputToolType, RenderSpec, StrokeElementData,
} from '../main/ets/core/model/StrokeTypes';
import { StrokeSession } from '../main/ets/rendering/StrokeSession';

const SPEC: RenderSpec = {
  color: 0xFF000000,
  brushWidth: 4,
  inkStyle: InkStyle.FIXED_WIDTH,
  isHighlighter: false,
  isPencil: false,
};

function point(x: number, time: number, pressure: number): InputPoint {
  return {
    x: x,
    y: 0,
    elapsedTimeMillis: time,
    toolType: InputToolType.STYLUS,
    pressure: pressure,
    tiltRadians: Math.PI / 2,
    orientationRadians: 0,
  };
}

function batch(kind: InputBatchKind, points: InputPoint[]): InputBatch {
  return { kind: kind, points: points };
}

export default function strokePredictionTest() {
  describe('StrokePrediction', () => {
    it('shows prediction in preview but excludes it from the finished stroke', 0, () => {
      const session: StrokeSession = new StrokeSession(SPEC);
      session.beginStroke(SPEC, 100);
      session.addBatch(batch(InputBatchKind.REAL, [point(0, 0, 0.2)]));
      session.addBatch(batch(InputBatchKind.PREDICTED, [point(10, 4, 0.9)]));

      const preview: StrokeElementData = session.getCurrentStroke()!;
      expect(preview.pathPoints.length).assertEqual(2);
      expect(preview.pathPoints[1].position.x).assertEqual(10);
      expect(session.getCurrentRealStroke()!.pathPoints.length).assertEqual(1);

      const finished: StrokeElementData = session.finishStroke();
      expect(finished.pathPoints.length).assertEqual(1);
      expect(finished.pathPoints[0].position.x).assertEqual(0);
    });

    it('replaces prediction with the next real sample without contaminating force state', 0, () => {
      const session: StrokeSession = new StrokeSession(SPEC);
      session.beginStroke(SPEC, 200);
      session.addBatch(batch(InputBatchKind.REAL, [point(0, 0, 0)]));
      session.addBatch(batch(InputBatchKind.PREDICTED, [point(50, 4, 1)]));
      session.addBatch(batch(InputBatchKind.REAL, [point(8, 8, 1)]));

      const current: StrokeElementData = session.getCurrentStroke()!;
      expect(current.pathPoints.length).assertEqual(2);
      expect(current.pathPoints[1].position.x).assertEqual(8);
      expect(current.pathPoints[1].pressure).assertEqual(0.15);
    });

    it('clears a stale preview when the platform returns no prediction', 0, () => {
      const session: StrokeSession = new StrokeSession(SPEC);
      session.beginStroke(SPEC, 300);
      session.addBatch(batch(InputBatchKind.REAL, [point(0, 0, 0.5)]));
      session.addBatch(batch(InputBatchKind.PREDICTED, [point(5, 1, 0.5)]));
      expect(session.getCurrentStroke()!.pathPoints.length).assertEqual(2);

      session.addBatch(batch(InputBatchKind.PREDICTED, []));
      expect(session.getCurrentStroke()!.pathPoints.length).assertEqual(1);
    });
  });
}
