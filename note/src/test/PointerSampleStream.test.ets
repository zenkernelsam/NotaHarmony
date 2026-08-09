import { describe, it, expect } from '@ohos/hypium';
import { InkInputProviderImpl } from '../main/ets/core/adaptation/InkInputProviderImpl';
import { RawPointerEvent } from '../main/ets/core/adaptation/InkInputProvider';
import {
  PointerInputBatches, PointerRawSample, PointerSampleStream,
} from '../main/ets/core/adaptation/PointerSampleStream';
import {
  InkStyle, InputBatch, InputToolType, RenderSpec, StrokeElementData,
} from '../main/ets/core/model/StrokeTypes';
import { StrokeSession } from '../main/ets/rendering/StrokeSession';

const SPEC: RenderSpec = {
  color: 0xFF000000,
  brushWidth: 2,
  inkStyle: InkStyle.FIXED_WIDTH,
  isHighlighter: false,
  isPencil: false,
};

function raw(x: number, timestamp: number, isHistorical: boolean,
  pressure: number = 0.5, toolType: number = 0, tilt: number = -1,
  orientation: number = -1): RawPointerEvent {
  return {
    x: x,
    y: x * 2,
    pressure: pressure,
    tiltRadians: tilt,
    orientationRadians: orientation,
    toolType: toolType,
    timestamp: timestamp,
    isHistorical: isHistorical,
  };
}

function sample(pointerId: number, event: RawPointerEvent): PointerRawSample {
  return { pointerId: pointerId, event: event };
}

function addBatches(session: StrokeSession, provider: InkInputProviderImpl,
  batches: PointerInputBatches): void {
  if (batches.historical.length > 0) {
    session.addBatch(provider.processEvent(batches.historical, false));
  }
  if (batches.real.length > 0) {
    session.addBatch(provider.processEvent(batches.real, false));
  }
}

export default function pointerSampleStreamTest() {
  describe('PointerSampleStream', () => {
    it('orders historical samples before the current sample and preserves all points', 0, () => {
      const stream: PointerSampleStream = new PointerSampleStream();
      stream.begin(7);
      const batches: PointerInputBatches = stream.append([
        sample(7, raw(2, 102, true)),
        sample(9, raw(99, 99, true)),
        sample(7, raw(0, 100, true)),
        sample(7, raw(3, 103, false)),
        sample(7, raw(1, 101, true)),
      ]);
      expect(batches.historical.length).assertEqual(3);
      expect(batches.real.length).assertEqual(1);
      expect(batches.historical[0].x).assertEqual(0);
      expect(batches.historical[2].x).assertEqual(2);

      const provider: InkInputProviderImpl = InkInputProviderImpl.createForArkUI();
      const session: StrokeSession = new StrokeSession(SPEC);
      provider.beginStroke(100);
      session.beginStroke(SPEC, 100);
      addBatches(session, provider, batches);
      const stroke: StrokeElementData = session.finishStroke();
      expect(stroke.pathPoints.length).assertEqual(4);
      expect(stroke.pathPoints[3].position.x).assertEqual(3);
    });

    it('drops overlapping historical samples and samples from other pointers', 0, () => {
      const stream: PointerSampleStream = new PointerSampleStream();
      stream.begin(1);
      stream.append([
        sample(1, raw(0, 10, false)),
        sample(1, raw(1, 11, false)),
      ]);
      const batches: PointerInputBatches = stream.append([
        sample(1, raw(1, 11, true)),
        sample(2, raw(2, 12, true)),
        sample(1, raw(3, 13, false)),
      ]);
      expect(batches.historical.length).assertEqual(0);
      expect(batches.real.length).assertEqual(1);
      expect(batches.real[0].x).assertEqual(3);
    });

    it('keeps the final up coordinate as a real endpoint', 0, () => {
      const stream: PointerSampleStream = new PointerSampleStream();
      const provider: InkInputProviderImpl = InkInputProviderImpl.createForArkUI();
      const session: StrokeSession = new StrokeSession(SPEC);
      stream.begin(4);
      provider.beginStroke(500);
      session.beginStroke(SPEC, 500);
      addBatches(session, provider, stream.append([sample(4, raw(0, 500, false))]));
      addBatches(session, provider, stream.append([sample(4, raw(10, 508, false))]));
      const stroke: StrokeElementData = session.finishStroke();
      expect(stroke.pathPoints.length).assertEqual(2);
      expect(stroke.pathPoints[1].position.x).assertEqual(10);
    });

    it('uses event timestamps independent of processing delay', 0, () => {
      const provider: InkInputProviderImpl = InkInputProviderImpl.createForArkUI();
      provider.beginStroke(1000);
      const batch: InputBatch = provider.processEvent([
        raw(0, 1000, false), raw(1, 1008, false), raw(2, 1016, false),
      ], false);
      expect(batch.points[0].elapsedTimeMillis).assertEqual(0);
      expect(batch.points[1].elapsedTimeMillis).assertEqual(8);
      expect(batch.points[2].elapsedTimeMillis).assertEqual(16);
    });

    it('preserves zero pressure, missing pressure and tool types', 0, () => {
      const provider: InkInputProviderImpl = InkInputProviderImpl.createForArkUI();
      provider.beginStroke(20);
      const batch: InputBatch = provider.processEvent([
        raw(0, 20, false, 0, 0),
        raw(1, 21, false, -1, 1),
        raw(2, 22, false, 0.5, 2),
      ], false);
      expect(batch.points[0].pressure).assertEqual(0);
      expect(batch.points[1].pressure).assertEqual(-1);
      expect(batch.points[0].toolType).assertEqual(InputToolType.STYLUS);
      expect(batch.points[1].toolType).assertEqual(InputToolType.MOUSE);
      expect(batch.points[2].toolType).assertEqual(InputToolType.TOUCH);
    });

    it('propagates angles and keeps missing-angle fallback finite', 0, () => {
      const provider: InkInputProviderImpl = InkInputProviderImpl.createForArkUI();
      const session: StrokeSession = new StrokeSession(SPEC);
      provider.beginStroke(0);
      session.beginStroke(SPEC, 0);
      session.addBatch(provider.processEvent([
        raw(0, 0, false, 0.5, 0, 0.25, 0),
        raw(1, 1, false, 0.5, 0, 0.75, Math.PI / 2),
        raw(2, 2, false, 0.5, 0, -1, -1),
      ], false));
      const stroke: StrokeElementData = session.finishStroke();
      expect(stroke.pathPoints[0].altitudeAngleRadians).assertEqual(0.25);
      expect(stroke.pathPoints[1].altitudeAngleRadians).assertEqual(0.75);
      expect(Math.abs(stroke.pathPoints[1].azimuthUnitX + 1) < 1e-12).assertTrue();
      expect(stroke.pathPoints[2].altitudeAngleRadians).assertEqual(-1);
      expect(Number.isFinite(stroke.pathPoints[2].azimuthUnitX)).assertTrue();
      expect(Number.isFinite(stroke.pathPoints[2].azimuthUnitY)).assertTrue();
    });
  });
}
