import { describe, it, expect } from '@ohos/hypium';
import { ForceSmoother } from '../main/ets/core/algorithm/ForceSmoother';
import { InputPoint, InputToolType } from '../main/ets/core/model/StrokeTypes';

function point(pressure: number, elapsedTimeMillis: number): InputPoint {
  return {
    x: elapsedTimeMillis,
    y: 0,
    elapsedTimeMillis: elapsedTimeMillis,
    toolType: InputToolType.STYLUS,
    pressure: pressure,
    tiltRadians: Math.PI / 2,
    orientationRadians: 0,
  };
}

export default function forceSmootherTest() {
  describe('ForceSmoother', () => {
    it('keeps the first force unchanged', 0, () => {
      const smoother: ForceSmoother = new ForceSmoother();
      expect(smoother.smooth([point(0.8, 0)])[0].pressure).assertEqual(0.8);
    });

    it('lerps force by elapsed time within the smoothing window', 0, () => {
      const smoother: ForceSmoother = new ForceSmoother({ maxForceChange: 1 });
      smoother.smooth([point(0, 0)]);
      expect(smoother.smooth([point(1, 4)])[0].pressure).assertEqual(0.5);
      expect(smoother.smooth([point(1, 12)])[0].pressure).assertEqual(1);
    });

    it('limits a large blended force change', 0, () => {
      const smoother: ForceSmoother = new ForceSmoother();
      smoother.smooth([point(0, 0)]);
      expect(smoother.smooth([point(1, 8)])[0].pressure).assertEqual(0.15);
    });

    it('clamps a negative time delta to zero', 0, () => {
      const smoother: ForceSmoother = new ForceSmoother({ maxForceChange: 1 });
      smoother.smooth([point(0.4, 8)]);
      expect(smoother.smooth([point(1, 4)])[0].pressure).assertEqual(0.4);
    });

    it('reset clears both force and timestamp history', 0, () => {
      const smoother: ForceSmoother = new ForceSmoother();
      smoother.smooth([point(0, 0), point(1, 8)]);
      smoother.reset();
      expect(smoother.smooth([point(0.9, 1)])[0].pressure).assertEqual(0.9);
    });

    it('does not smooth or retain predicted points', 0, () => {
      const smoother: ForceSmoother = new ForceSmoother({ maxForceChange: 1 });
      smoother.smooth([point(0, 0)]);
      expect(smoother.smooth([point(1, 4)], false)[0].pressure).assertEqual(1);
      expect(smoother.smooth([point(1, 8)])[0].pressure).assertEqual(1);
    });

    it('preserves the no-pressure sentinel without changing history', 0, () => {
      const smoother: ForceSmoother = new ForceSmoother({ maxForceChange: 1 });
      smoother.smooth([point(0, 0)]);
      expect(smoother.smooth([point(-1, 4)])[0].pressure).assertEqual(-1);
      expect(smoother.smooth([point(1, 8)])[0].pressure).assertEqual(1);
    });
  });
}
