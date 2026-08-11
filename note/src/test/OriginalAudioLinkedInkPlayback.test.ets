import { describe, expect, it } from '@ohos/hypium';
import {
  OriginalAudioLinkedPlaybackState, originalAudioTimeAtPosition,
  resolveOriginalAudioLinkedPlayback, sliceStrokeForAudioProgress,
} from '../main/ets/core/adaptation/OriginalAudioLinkedInkPlayback';
import { InkStyle, StrokeElementData, StrokePathPoint } from '../main/ets/core/model/StrokeTypes';

export default function originalAudioLinkedInkPlaybackTest() {
  describe('OriginalAudioLinkedInkPlayback', () => {
    it('matches original unbegun animating and complete states inside Recording segments', 0, () => {
      const stroke: StrokeElementData = lineStroke(false);
      stroke.audioStartTime = '18446744073709550000';
      stroke.audioDuration = 1000;
      const ranges = [{ startTime: '18446744073709549000', endTime: '18446744073709552000' }];
      const unbegun = resolveOriginalAudioLinkedPlayback(
        stroke, '18446744073709549999', ranges);
      expect(unbegun.state).assertEqual(OriginalAudioLinkedPlaybackState.UNBEGUN);
      expect(unbegun.alpha).assertEqual(0.3);
      expect(unbegun.progress).assertNull();
      const animating = resolveOriginalAudioLinkedPlayback(
        stroke, '18446744073709550250', ranges);
      expect(animating.state).assertEqual(OriginalAudioLinkedPlaybackState.ANIMATING);
      expect(Math.abs((animating.progress as number) - 0.25) < 0.000001).assertTrue();
      const complete = resolveOriginalAudioLinkedPlayback(
        stroke, '18446744073709551000', ranges);
      expect(complete.state).assertEqual(OriginalAudioLinkedPlaybackState.COMPLETE);
      expect(complete.alpha).assertNull();
    });

    it('disables playback outside Recording ranges and completes wrapped end invariants', 0, () => {
      const stroke: StrokeElementData = lineStroke(false);
      stroke.audioStartTime = '50';
      stroke.audioDuration = 10;
      expect(resolveOriginalAudioLinkedPlayback(stroke, '55', [
        { startTime: '0', endTime: '49' },
      ]).state).assertEqual(OriginalAudioLinkedPlaybackState.DISABLED);
      stroke.audioStartTime = '18446744073709551610';
      stroke.audioDuration = 10;
      expect(resolveOriginalAudioLinkedPlayback(stroke, '18446744073709551611', [
        { startTime: '18446744073709551600', endTime: '18446744073709551615' },
      ]).state).assertEqual(OriginalAudioLinkedPlaybackState.COMPLETE);
    });

    it('maps a local player position onto a precision-safe absolute audio time', 0, () => {
      expect(originalAudioTimeAtPosition(
        '18446744073709550000', '18446744073709551000', 250))
        .assertEqual('18446744073709550250');
      expect(originalAudioTimeAtPosition('100', '200', Number.MAX_SAFE_INTEGER)).assertEqual('200');
    });

    it('truncates Pencil by splat count and ordinary Ink by geometric length', 0, () => {
      const pencil: StrokeElementData = lineStroke(true);
      pencil.splatPoints = [
        { x: 0, y: 0, rotation: 0, scale: 1, opacity: 1 },
        { x: 1, y: 0, rotation: 0, scale: 1, opacity: 1 },
        { x: 2, y: 0, rotation: 0, scale: 1, opacity: 1 },
        { x: 3, y: 0, rotation: 0, scale: 1, opacity: 1 },
      ];
      expect(sliceStrokeForAudioProgress(pencil, 0.5).splatPoints.length).assertEqual(2);
      const sliced: StrokeElementData = sliceStrokeForAudioProgress(lineStroke(false), 0.25);
      expect(sliced.pathPoints.length).assertEqual(2);
      expect(Math.abs(sliced.pathPoints[1].position.x - 5) < 0.000001).assertTrue();
      expect(sliced.customPath).assertNull();
      expect(sliced.fillPath).assertNull();
    });
  });
}

function lineStroke(pencil: boolean): StrokeElementData {
  const points: StrokePathPoint[] = [point(0), point(10), point(20)];
  return {
    id: 'stroke', pathPoints: points, cubicSegments: [], splatPoints: [],
    renderSpec: { color: 0xFF000000 | 0, brushWidth: 2, inkStyle: InkStyle.FIXED_WIDTH,
      isHighlighter: false, isPencil: pencil },
    transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
    bounds: { left: -1, top: -1, right: 21, bottom: 1 }, maskPath: [],
    customPath: [], fillPath: [], fillColor: null, styleMap: [], isFinished: true,
  };
}

function point(x: number): StrokePathPoint {
  return { position: { x: x, y: 0 }, widthFactor: 1, pressure: 1,
    altitudeAngleRadians: -1, azimuthUnitX: 0, azimuthUnitY: 0 };
}
