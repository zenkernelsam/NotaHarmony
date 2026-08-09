import { RawPointerEvent } from './InkInputProvider';

export interface PointerRawSample {
  pointerId: number;
  event: RawPointerEvent;
}

export class PointerInputBatches {
  historical: RawPointerEvent[];
  real: RawPointerEvent[];

  constructor(historical: RawPointerEvent[] = [], real: RawPointerEvent[] = []) {
    this.historical = historical;
    this.real = real;
  }
}

// Maintains one physical pointer stream across ArkUI frames. Historical samples may overlap
// adjacent frames, so ordering and exact-sample deduplication must happen before fitting.
export class PointerSampleStream {
  private pointerId: number = -1;
  private lastTimestamp: number = -1;
  private lastX: number = 0;
  private lastY: number = 0;
  private hasLast: boolean = false;

  begin(pointerId: number): void {
    this.pointerId = pointerId;
    this.lastTimestamp = -1;
    this.lastX = 0;
    this.lastY = 0;
    this.hasLast = false;
  }

  append(samples: PointerRawSample[]): PointerInputBatches {
    if (this.pointerId < 0 || samples.length === 0) {
      return new PointerInputBatches();
    }
    const matching: PointerRawSample[] = [];
    for (let i: number = 0; i < samples.length; i++) {
      const sample: PointerRawSample = samples[i];
      if (sample.pointerId === this.pointerId && isFiniteSample(sample.event)) {
        matching.push(sample);
      }
    }
    matching.sort((left: PointerRawSample, right: PointerRawSample): number => {
      if (left.event.timestamp !== right.event.timestamp) {
        return left.event.timestamp - right.event.timestamp;
      }
      if (left.event.isHistorical === right.event.isHistorical) {
        return 0;
      }
      return left.event.isHistorical ? -1 : 1;
    });

    const historical: RawPointerEvent[] = [];
    const real: RawPointerEvent[] = [];
    for (let i: number = 0; i < matching.length; i++) {
      const event: RawPointerEvent = matching[i].event;
      if (this.hasLast && event.timestamp < this.lastTimestamp) {
        continue;
      }
      if (this.hasLast && event.timestamp === this.lastTimestamp &&
        event.x === this.lastX && event.y === this.lastY) {
        continue;
      }
      if (event.isHistorical) {
        historical.push(event);
      } else {
        real.push(event);
      }
      this.lastTimestamp = event.timestamp;
      this.lastX = event.x;
      this.lastY = event.y;
      this.hasLast = true;
    }
    return new PointerInputBatches(historical, real);
  }

  reset(): void {
    this.pointerId = -1;
    this.hasLast = false;
    this.lastTimestamp = -1;
  }
}

function isFiniteSample(event: RawPointerEvent): boolean {
  return Number.isFinite(event.x) && Number.isFinite(event.y) &&
    Number.isFinite(event.timestamp) && event.timestamp >= 0;
}
