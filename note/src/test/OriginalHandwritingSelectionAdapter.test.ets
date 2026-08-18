import { describe, expect, it } from '@ohos/hypium';
import { Point2D, TransformMatrix } from '../main/ets/core/model/GeometryTypes';
import { InkStyle, StrokeElementData, StrokePathPoint } from '../main/ets/core/model/StrokeTypes';
import {
  adaptOriginalHandwritingSelection, OriginalHandwritingSelectionSkipReason,
} from '../main/ets/core/adaptation/OriginalHandwritingSelectionAdapter';

export default function originalHandwritingSelectionAdapterTest() {
  describe('OriginalHandwritingSelectionAdapter', () => {
    it('sorts canonical identities while keeping imported IDs in their input slots', 0, () => {
      const late: StrokeElementData = stroke('op:2:0', [pathPoint(20, 0, 0.2)]);
      const imported: StrokeElementData = stroke('nb-imported', [pathPoint(30, 0, -1)]);
      const middle: StrokeElementData = stroke('op:1:2', [pathPoint(10, 0, 0.4)]);
      const early: StrokeElementData = stroke('op:1:1', [pathPoint(0, 0, 0.6)]);
      const result = adaptOriginalHandwritingSelection(
        [late.id, imported.id, middle.id, early.id], [middle, late, early, imported]);

      expect(result.acceptedStrokeIds.length).assertEqual(4);
      expect(result.acceptedStrokeIds[0]).assertEqual(early.id);
      expect(result.acceptedStrokeIds[1]).assertEqual(imported.id);
      expect(result.acceptedStrokeIds[2]).assertEqual(middle.id);
      expect(result.acceptedStrokeIds[3]).assertEqual(late.id);
      expect(result.skipped.length).assertEqual(0);
    });

    it('applies the complete affine transform and preserves force values', 0, () => {
      const transformed: StrokeElementData = stroke('op:7:1', [
        pathPoint(1, 2, -1), pathPoint(-1, 4, 0.75),
      ], [0, -2, 10, 3, 0, 20, 0, 0, 1]);
      const result = adaptOriginalHandwritingSelection([transformed.id], [transformed]);

      expect(result.strokes.length).assertEqual(1);
      expect(result.strokes[0].samples.length).assertEqual(2);
      expect(result.strokes[0].samples[0].position.x).assertEqual(6);
      expect(result.strokes[0].samples[0].position.y).assertEqual(23);
      expect(result.strokes[0].samples[0].force).assertEqual(-1);
      expect(result.strokes[0].samples[1].position.x).assertEqual(2);
      expect(result.strokes[0].samples[1].position.y).assertEqual(17);
      expect(result.strokes[0].samples[1].force).assertEqual(0.75);
    });

    it('isolates filtered and malformed strokes with explicit reasons', 0, () => {
      const valid: StrokeElementData = stroke('valid', [pathPoint(0, 0, 0.5)]);
      const highlighter: StrokeElementData = stroke(
        'highlighter', [pathPoint(0, 0, 0.5)], identity(), true, true, false);
      const partial: StrokeElementData = stroke(
        'partial', [pathPoint(0, 0, 0.5)], identity(), true, false, true);
      const unfinished: StrokeElementData = stroke(
        'unfinished', [pathPoint(0, 0, 0.5)], identity(), false);
      const empty: StrokeElementData = stroke('empty', []);
      const badTransform: StrokeElementData = stroke(
        'bad-transform', [pathPoint(0, 0, 0.5)], [1, 0, 0, 0, 0, 0, 0, 0, 1]);
      const badSample: StrokeElementData = stroke('bad-sample', [pathPoint(0, 0, Number.NaN)]);
      const selected: string[] = [valid.id, highlighter.id, partial.id, unfinished.id,
        empty.id, badTransform.id, badSample.id, 'missing', valid.id];
      const result = adaptOriginalHandwritingSelection(selected,
        [valid, highlighter, partial, unfinished, empty, badTransform, badSample]);

      expect(result.acceptedStrokeIds.length).assertEqual(1);
      expect(result.acceptedStrokeIds[0]).assertEqual(valid.id);
      expect(result.skipped.length).assertEqual(8);
      expect(result.skipped[0].reason).assertEqual(OriginalHandwritingSelectionSkipReason.HIGHLIGHTER);
      expect(result.skipped[1].reason).assertEqual(OriginalHandwritingSelectionSkipReason.PARTIAL_ERASER);
      expect(result.skipped[2].reason).assertEqual(OriginalHandwritingSelectionSkipReason.UNFINISHED_STROKE);
      expect(result.skipped[3].reason).assertEqual(OriginalHandwritingSelectionSkipReason.EMPTY_CENTER_PATH);
      expect(result.skipped[4].reason).assertEqual(OriginalHandwritingSelectionSkipReason.INVALID_TRANSFORM);
      expect(result.skipped[5].reason).assertEqual(OriginalHandwritingSelectionSkipReason.INVALID_SAMPLE);
      expect(result.skipped[6].reason).assertEqual(OriginalHandwritingSelectionSkipReason.MISSING_STROKE);
      expect(result.skipped[7].reason).assertEqual(OriginalHandwritingSelectionSkipReason.DUPLICATE_SELECTION);
    });

    it('rejects an ambiguous page identity without dropping other strokes', 0, () => {
      const duplicateA: StrokeElementData = stroke('same', [pathPoint(1, 1, 0.1)]);
      const duplicateB: StrokeElementData = stroke('same', [pathPoint(2, 2, 0.2)]);
      const valid: StrokeElementData = stroke('other', [pathPoint(3, 3, 0.3)]);
      const result = adaptOriginalHandwritingSelection(['same', 'other'],
        [duplicateA, duplicateB, valid]);

      expect(result.acceptedStrokeIds.length).assertEqual(1);
      expect(result.acceptedStrokeIds[0]).assertEqual('other');
      expect(result.skipped.length).assertEqual(1);
      expect(result.skipped[0].reason).assertEqual(OriginalHandwritingSelectionSkipReason.AMBIGUOUS_STROKE_ID);
    });
  });
}

function identity(): TransformMatrix {
  return [1, 0, 0, 0, 1, 0, 0, 0, 1];
}

function pathPoint(x: number, y: number, pressure: number): StrokePathPoint {
  return {
    position: point(x, y), widthFactor: 1, pressure: pressure,
    altitudeAngleRadians: -1, azimuthUnitX: 0, azimuthUnitY: 0,
  };
}

function stroke(id: string, points: StrokePathPoint[], transform: TransformMatrix = identity(),
  finished: boolean = true, highlighter: boolean = false, partial: boolean = false): StrokeElementData {
  return {
    id: id, pathPoints: points, cubicSegments: [], splatPoints: [],
    renderSpec: {
      color: -16777216, brushWidth: 2, inkStyle: InkStyle.FIXED_WIDTH,
      isHighlighter: highlighter, isPencil: false, isPartialEraser: partial,
    },
    transform: transform, bounds: { left: 0, top: 0, right: 10, bottom: 10 },
    maskPath: [], isFinished: finished,
  };
}

function point(x: number, y: number): Point2D {
  return { x: x, y: y };
}
