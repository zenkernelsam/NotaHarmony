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

    it('matches the original time weight at 120Hz and 240Hz', 0, () => {
      const at120Hz: ForceSmoother = new ForceSmoother({ maxForceChange: 1 });
      at120Hz.smooth([point(0, 0)]);
      const force120Hz: number = at120Hz.smooth([point(1, 1000 / 120)])[0].pressure;
      expect(force120Hz).assertEqual(1);

      const at240Hz: ForceSmoother = new ForceSmoother({ maxForceChange: 1 });
      at240Hz.smooth([point(0, 0)]);
      const force240Hz: number = at240Hz.smooth([point(1, 1000 / 240)])[0].pressure;
      expect(Math.abs(force240Hz - (1000 / 240 / 8)) < 1e-12).assertTrue();
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
