// Partial/whole eraser geometry. This module stays platform-free so the same
// replacement plan can be exercised by ArkTS fixtures and the editor.
import {
  InkStyle, InkStyleMapEntry, StrokeElementData, StrokePathPoint,
} from '../core/model/StrokeTypes';
import { CubicSegment, Point2D, Rect2D, TransformMatrix } from '../core/model/GeometryTypes';

const GEOMETRY_EPSILON: number = 0.000001;
const TRANSITION_ITERATIONS: number = 14;
const MAX_SEGMENT_SAMPLES: number = 128;
const MAX_STROKE_SAMPLES: number = 131072;
const MAX_AUDIO_DURATION: number = 0xFFFFFFFF;
const MAX_UNSIGNED_LONG_DECIMAL: string = '18446744073709551615';

export enum EraserMode {
  PARTIAL = 0,
  WHOLE = 1,
}

export interface PartialEraseReplacement {
  sourceStroke: StrokeElementData;
  remnants: StrokeElementData[];
}

export interface EraseResult {
  mode: EraserMode;
  partialReplacements: PartialEraseReplacement[];
  deletedStrokeIds: string[];
}

interface SampledStrokePoint {
  local: Point2D;
  world: Point2D;
  attributes: StrokePathPoint;
  distance: number;
}

interface RemnantAudioTiming {
  startTime?: string;
  duration?: number | null;
}

export class EraserEngine {
  private mode: EraserMode;
  private eraserWidth: number;

  constructor(mode: EraserMode, eraserWidth?: number) {
    this.mode = mode;
    this.eraserWidth = eraserWidth !== undefined ? eraserWidth : 20;
  }

  erase(eraserPath: Point2D[], strokes: StrokeElementData[]): EraseResult {
    if (this.mode === EraserMode.WHOLE) {
      return this.eraseWhole(eraserPath, strokes);
    }
    return this.erasePartial(eraserPath, strokes);
  }

  private eraseWhole(eraserPath: Point2D[], strokes: StrokeElementData[]): EraseResult {
    const deleted: string[] = [];
    if (eraserPath.length === 0) {
      return { mode: this.mode, partialReplacements: [], deletedStrokeIds: deleted };
    }
    const radius: number = this.eraserWidth / 2;
    for (const stroke of strokes) {
      if (stroke.renderSpec.isPartialEraser === true) {
        continue;
      }
      if (this.pathHitsStroke(eraserPath, stroke, radius)) {
        deleted.push(stroke.id);
      }
    }
    return { mode: this.mode, partialReplacements: [], deletedStrokeIds: deleted };
  }

  // Notability 1.0.3 does not retain CREATE_INK tool 5 after a partial erase.
  // It clips each hit Ink into zero or more new Ink entities, creates those
  // remnants, and deletes the source entity. Pencil/custom-outline clipping is
  // deliberately left to the follow-up outline phase; treating it as a center
  // line here would destroy its native texture.
  private erasePartial(eraserPath: Point2D[], strokes: StrokeElementData[]): EraseResult {
    const replacements: PartialEraseReplacement[] = [];
    if (eraserPath.length === 0) {
      return { mode: this.mode, partialReplacements: replacements, deletedStrokeIds: [] };
    }
    for (const stroke of strokes) {
      if (!this.supportsCenterLinePartialErase(stroke)) {
        continue;
      }
      const samples: SampledStrokePoint[] | null = this.sampleStroke(stroke);
      if (samples === null || samples.length === 0) {
        continue;
      }
      const scale: number = this.maximumLinearScale(stroke.transform);
      const erased: boolean[] = samples.map((sample: SampledStrokePoint): boolean =>
        this.sampleIsErased(sample, eraserPath, stroke.renderSpec.brushWidth, scale));
      let hasErasedPoint: boolean = false;
      for (const value of erased) {
        hasErasedPoint = hasErasedPoint || value;
      }
      if (!hasErasedPoint) {
        continue;
      }
      const runs: SampledStrokePoint[][] = this.outsideRuns(
        samples, erased, eraserPath, stroke.renderSpec.brushWidth, scale);
      const remnants: StrokeElementData[] = [];
      const totalDistance: number = samples[samples.length - 1].distance;
      for (let index: number = 0; index < runs.length; index++) {
        const remnant: StrokeElementData | null = this.buildRemnant(
          stroke, runs[index], index, totalDistance);
        if (remnant !== null) {
          remnants.push(remnant);
        }
      }
      replacements.push({ sourceStroke: stroke, remnants: remnants });
    }
    return { mode: this.mode, partialReplacements: replacements, deletedStrokeIds: [] };
  }

  private supportsCenterLinePartialErase(stroke: StrokeElementData): boolean {
    return stroke.renderSpec.isPartialEraser !== true && !stroke.renderSpec.isPencil &&
      stroke.renderSpec.tapePattern === undefined && stroke.pathPoints.length > 0 &&
      stroke.maskPath.length === 0 &&
      (stroke.customPath === undefined || stroke.customPath === null) &&
      (stroke.fillPath === undefined || stroke.fillPath === null) &&
      (stroke.fillColor === undefined || stroke.fillColor === null);
  }

  private sampleStroke(stroke: StrokeElementData): SampledStrokePoint[] | null {
    const samples: SampledStrokePoint[] = [];
    const pathPoints: StrokePathPoint[] = stroke.pathPoints;
    if (pathPoints.length === 1 && stroke.cubicSegments.length === 0) {
      samples.push(this.sampledPoint(pathPoints[0].position, pathPoints[0], stroke.transform, 0));
      return samples;
    }
    let distance: number = 0;
    if (stroke.cubicSegments.length > 0) {
      const segmentCount: number = stroke.cubicSegments.length;
      for (let index: number = 0; index < segmentCount; index++) {
        const segment: CubicSegment = stroke.cubicSegments[index];
        const startAttribute: StrokePathPoint = pathPoints[this.attributeIndex(
          index, segmentCount, pathPoints.length)];
        const endAttribute: StrokePathPoint = pathPoints[this.attributeIndex(
          index + 1, segmentCount, pathPoints.length)];
        const worldControl: Point2D[] = [segment.p0, segment.p1, segment.p2, segment.p3].map(
          (point: Point2D): Point2D => this.transformPoint(point, stroke.transform));
        const divisions: number = this.sampleDivisionCount(worldControl, stroke.renderSpec.brushWidth);
        for (let step: number = 0; step <= divisions; step++) {
          if (index > 0 && step === 0) {
            continue;
          }
          const t: number = step / divisions;
          const local: Point2D = this.cubicPoint(segment, t);
          const attributes: StrokePathPoint = this.interpolatePathPoint(startAttribute, endAttribute, t, local);
          const world: Point2D = this.transformPoint(local, stroke.transform);
          if (samples.length > 0) {
            distance += this.pointDistance(samples[samples.length - 1].local, local);
          }
          samples.push({ local: local, world: world, attributes: attributes, distance: distance });
          if (samples.length > MAX_STROKE_SAMPLES) {
            return null;
          }
        }
      }
      return samples;
    }
    for (let index: number = 0; index < pathPoints.length - 1; index++) {
      const start: StrokePathPoint = pathPoints[index];
      const end: StrokePathPoint = pathPoints[index + 1];
      const worldStart: Point2D = this.transformPoint(start.position, stroke.transform);
      const worldEnd: Point2D = this.transformPoint(end.position, stroke.transform);
      const divisions: number = this.sampleDivisionCount(
        [worldStart, worldEnd], stroke.renderSpec.brushWidth);
      for (let step: number = 0; step <= divisions; step++) {
        if (index > 0 && step === 0) {
          continue;
        }
        const t: number = step / divisions;
        const local: Point2D = this.lerpPoint(start.position, end.position, t);
        const attributes: StrokePathPoint = this.interpolatePathPoint(start, end, t, local);
        const world: Point2D = this.transformPoint(local, stroke.transform);
        if (samples.length > 0) {
          distance += this.pointDistance(samples[samples.length - 1].local, local);
        }
        samples.push({ local: local, world: world, attributes: attributes, distance: distance });
        if (samples.length > MAX_STROKE_SAMPLES) {
          return null;
        }
      }
    }
    return samples;
  }

  private sampledPoint(local: Point2D, attributes: StrokePathPoint,
    transform: TransformMatrix, distance: number): SampledStrokePoint {
    return {
      local: { x: local.x, y: local.y },
      world: this.transformPoint(local, transform),
      attributes: this.clonePathPoint(attributes, local),
      distance: distance,
    };
  }

  private attributeIndex(index: number, segmentCount: number, pointCount: number): number {
    return Math.min(pointCount - 1,
      Math.max(0, Math.round(index * (pointCount - 1) / segmentCount)));
  }

  private sampleDivisionCount(worldControl: Point2D[], brushWidth: number): number {
    let length: number = 0;
    for (let index: number = 1; index < worldControl.length; index++) {
      length += this.pointDistance(worldControl[index - 1], worldControl[index]);
    }
    const radius: number = Math.max(0.25, this.eraserWidth / 2);
    const width: number = Math.max(0.25, brushWidth);
    const step: number = Math.max(0.35, Math.min(3, radius / 3, width / 3));
    return Math.max(1, Math.min(MAX_SEGMENT_SAMPLES, Math.ceil(length / step)));
  }

  private outsideRuns(samples: SampledStrokePoint[], erased: boolean[], eraserPath: Point2D[],
    brushWidth: number, scale: number): SampledStrokePoint[][] {
    const runs: SampledStrokePoint[][] = [];
    let current: SampledStrokePoint[] = erased[0] ? [] : [samples[0]];
    for (let index: number = 1; index < samples.length; index++) {
      const previousErased: boolean = erased[index - 1];
      const currentErased: boolean = erased[index];
      if (!previousErased && !currentErased) {
        this.appendDistinctSample(current, samples[index]);
      } else if (!previousErased && currentErased) {
        const boundary: SampledStrokePoint = this.transitionSample(
          samples[index - 1], samples[index], false, eraserPath, brushWidth, scale);
        this.appendDistinctSample(current, boundary);
        this.finishRun(runs, current);
        current = [];
      } else if (previousErased && !currentErased) {
        const boundary: SampledStrokePoint = this.transitionSample(
          samples[index - 1], samples[index], true, eraserPath, brushWidth, scale);
        current = [boundary];
        this.appendDistinctSample(current, samples[index]);
      }
    }
    this.finishRun(runs, current);
    return runs;
  }

  private transitionSample(start: SampledStrokePoint, end: SampledStrokePoint,
    startErased: boolean, eraserPath: Point2D[], brushWidth: number,
    scale: number): SampledStrokePoint {
    let low: number = 0;
    let high: number = 1;
    for (let iteration: number = 0; iteration < TRANSITION_ITERATIONS; iteration++) {
      const middle: number = (low + high) / 2;
      const sample: SampledStrokePoint = this.interpolateSample(start, end, middle);
      if (this.sampleIsErased(sample, eraserPath, brushWidth, scale) === startErased) {
        low = middle;
      } else {
        high = middle;
      }
    }
    return this.interpolateSample(start, end, (low + high) / 2);
  }

  private interpolateSample(start: SampledStrokePoint, end: SampledStrokePoint,
    t: number): SampledStrokePoint {
    const local: Point2D = this.lerpPoint(start.local, end.local, t);
    const world: Point2D = this.lerpPoint(start.world, end.world, t);
    return {
      local: local,
      world: world,
      attributes: this.interpolatePathPoint(start.attributes, end.attributes, t, local),
      distance: start.distance + (end.distance - start.distance) * t,
    };
  }

  private sampleIsErased(sample: SampledStrokePoint, eraserPath: Point2D[],
    brushWidth: number, scale: number): boolean {
    const widthFactor: number = Number.isFinite(sample.attributes.widthFactor) ?
      Math.max(0, sample.attributes.widthFactor) : 1;
    const radius: number = this.eraserWidth / 2 + brushWidth * widthFactor * scale / 2;
    const segmentCount: number = Math.max(1, eraserPath.length - 1);
    for (let index: number = 0; index < segmentCount; index++) {
      const start: Point2D = eraserPath[index];
      const end: Point2D = eraserPath.length === 1 ? eraserPath[0] : eraserPath[index + 1];
      if (sample.world.x < Math.min(start.x, end.x) - radius ||
        sample.world.x > Math.max(start.x, end.x) + radius ||
        sample.world.y < Math.min(start.y, end.y) - radius ||
        sample.world.y > Math.max(start.y, end.y) + radius) {
        continue;
      }
      if (this.pointSegmentDistance(sample.world, start, end) <= radius) {
        return true;
      }
    }
    return false;
  }

  private finishRun(runs: SampledStrokePoint[][], run: SampledStrokePoint[]): void {
    if (run.length === 0) {
      return;
    }
    if (run.length === 1 && runs.length > 0) {
      return;
    }
    runs.push(run);
  }

  private appendDistinctSample(run: SampledStrokePoint[], sample: SampledStrokePoint): void {
    if (run.length === 0 || this.pointDistance(run[run.length - 1].local, sample.local) > GEOMETRY_EPSILON) {
      run.push(sample);
    }
  }

  private buildRemnant(source: StrokeElementData, run: SampledStrokePoint[],
    remnantIndex: number, totalDistance: number): StrokeElementData | null {
    if (run.length === 0) {
      return null;
    }
    const pathPoints: StrokePathPoint[] = run.map(
      (sample: SampledStrokePoint): StrokePathPoint => this.clonePathPoint(
        sample.attributes, sample.local));
    const cubicSegments: CubicSegment[] = [];
    for (let index: number = 1; index < pathPoints.length; index++) {
      const start: Point2D = pathPoints[index - 1].position;
      const end: Point2D = pathPoints[index].position;
      cubicSegments.push({
        p0: { x: start.x, y: start.y },
        p1: { x: start.x + (end.x - start.x) / 3,
          y: start.y + (end.y - start.y) / 3 },
        p2: { x: start.x + (end.x - start.x) * 2 / 3,
          y: start.y + (end.y - start.y) * 2 / 3 },
        p3: { x: end.x, y: end.y },
      });
    }
    const styleMap: InkStyleMapEntry[] | undefined = this.remnantStyleMap(source, run[0].distance);
    const audio: RemnantAudioTiming = this.remnantAudioTiming(
      source, run[0].distance, run[run.length - 1].distance, totalDistance);
    return {
      id: `${source.id}#erase-${remnantIndex}`,
      pathPoints: pathPoints,
      cubicSegments: cubicSegments,
      splatPoints: [],
      renderSpec: {
        color: source.renderSpec.color,
        brushWidth: source.renderSpec.brushWidth,
        inkStyle: source.renderSpec.inkStyle,
        isHighlighter: source.renderSpec.isHighlighter,
        isPencil: false,
        inkEffects: source.renderSpec.inkEffects,
        inkEffectsTinted: source.renderSpec.inkEffectsTinted,
        inkEffectPhase: (source.renderSpec.inkEffectPhase ?? 0) + run[0].distance,
      },
      transform: source.transform.slice(),
      bounds: this.remnantBounds(pathPoints, source.renderSpec.brushWidth, source.transform),
      maskPath: [],
      customPath: null,
      fillPath: null,
      fillColor: null,
      styleMap: styleMap,
      audioStartTime: audio.startTime,
      audioDuration: audio.duration,
      isFinished: true,
    };
  }

  private remnantAudioTiming(source: StrokeElementData, startDistance: number,
    endDistance: number, totalDistance: number): RemnantAudioTiming {
    const sourceDuration: number | null | undefined = source.audioDuration;
    if (sourceDuration === undefined || sourceDuration === null || totalDistance <= GEOMETRY_EPSILON) {
      return { startTime: source.audioStartTime, duration: sourceDuration };
    }
    const boundedDuration: number = Math.max(0, Math.min(MAX_AUDIO_DURATION,
      Math.round(sourceDuration)));
    const startRatio: number = Math.max(0, Math.min(1, startDistance / totalDistance));
    const endRatio: number = Math.max(startRatio, Math.min(1, endDistance / totalDistance));
    const startOffset: number = Math.max(0, Math.min(MAX_AUDIO_DURATION,
      Math.round(startRatio * boundedDuration)));
    const duration: number = Math.max(0, Math.min(MAX_AUDIO_DURATION,
      Math.round((endRatio - startRatio) * boundedDuration)));
    return {
      startTime: this.shiftAudioStart(source.audioStartTime, startOffset),
      duration: duration,
    };
  }

  private shiftAudioStart(value: string | undefined, amount: number): string | undefined {
    if (value === undefined || amount <= 0 || !Number.isSafeInteger(amount)) {
      return value;
    }
    if (value.length === 0 || value.length > MAX_UNSIGNED_LONG_DECIMAL.length) {
      return value;
    }
    const digits: number[] = [];
    for (let index: number = 0; index < value.length; index++) {
      const digit: number = value.charCodeAt(index) - 0x30;
      if (digit < 0 || digit > 9) {
        return value;
      }
      digits.push(digit);
    }
    let carry: number = amount;
    for (let index: number = digits.length - 1; index >= 0 && carry > 0; index--) {
      const sum: number = digits[index] + carry;
      digits[index] = sum % 10;
      carry = Math.floor(sum / 10);
    }
    while (carry > 0) {
      digits.unshift(carry % 10);
      carry = Math.floor(carry / 10);
    }
    const shifted: string = digits.join('');
    if (shifted.length > MAX_UNSIGNED_LONG_DECIMAL.length ||
      (shifted.length === MAX_UNSIGNED_LONG_DECIMAL.length &&
        shifted > MAX_UNSIGNED_LONG_DECIMAL)) {
      return value;
    }
    return shifted;
  }

  private remnantStyleMap(source: StrokeElementData,
    startDistance: number): InkStyleMapEntry[] | undefined {
    if (source.styleMap === undefined) {
      return undefined;
    }
    return source.styleMap.map((entry: InkStyleMapEntry): InkStyleMapEntry => ({
      backingPencilSeed: entry.backingPencilSeed,
      backingPencilReferencePoint: {
        x: entry.backingPencilReferencePoint.x,
        y: entry.backingPencilReferencePoint.y,
      },
      backingDashPhase: entry.backingDashPhase +
        (source.renderSpec.inkStyle === InkStyle.DASH ||
          source.renderSpec.inkStyle === InkStyle.DOTS ? startDistance : 0),
      backingDashPeriod: entry.backingDashPeriod,
    }));
  }

  private remnantBounds(points: StrokePathPoint[], brushWidth: number,
    transform: TransformMatrix): Rect2D {
    let left: number = points[0].position.x;
    let right: number = left;
    let top: number = points[0].position.y;
    let bottom: number = top;
    let widthFactor: number = 1;
    for (const point of points) {
      left = Math.min(left, point.position.x);
      right = Math.max(right, point.position.x);
      top = Math.min(top, point.position.y);
      bottom = Math.max(bottom, point.position.y);
      if (Number.isFinite(point.widthFactor)) {
        widthFactor = Math.max(widthFactor, Math.max(0, point.widthFactor));
      }
    }
    const padding: number = brushWidth * widthFactor * 2;
    const corners: Point2D[] = [
      { x: left - padding, y: top - padding },
      { x: right + padding, y: top - padding },
      { x: right + padding, y: bottom + padding },
      { x: left - padding, y: bottom + padding },
    ];
    const first: Point2D = this.transformPoint(corners[0], transform);
    const result: Rect2D = { left: first.x, top: first.y, right: first.x, bottom: first.y };
    for (let index: number = 1; index < corners.length; index++) {
      const world: Point2D = this.transformPoint(corners[index], transform);
      result.left = Math.min(result.left, world.x);
      result.right = Math.max(result.right, world.x);
      result.top = Math.min(result.top, world.y);
      result.bottom = Math.max(result.bottom, world.y);
    }
    return result;
  }

  private pathHitsStroke(path: Point2D[], stroke: StrokeElementData,
    _eraserRadius: number): boolean {
    const samples: SampledStrokePoint[] | null = this.sampleStroke(stroke);
    if (samples === null || samples.length === 0) {
      return false;
    }
    const scale: number = this.maximumLinearScale(stroke.transform);
    for (const sample of samples) {
      if (this.sampleIsErased(sample, path, stroke.renderSpec.brushWidth, scale)) {
        return true;
      }
    }
    return false;
  }

  private maximumLinearScale(matrix: TransformMatrix): number {
    const a: number = matrix[0];
    const b: number = matrix[1];
    const c: number = matrix[3];
    const d: number = matrix[4];
    const sum: number = a * a + b * b + c * c + d * d;
    const determinant: number = a * d - b * c;
    const discriminant: number = Math.max(0, sum * sum - 4 * determinant * determinant);
    return Math.sqrt(Math.max(0, (sum + Math.sqrt(discriminant)) / 2));
  }

  private cubicPoint(segment: CubicSegment, t: number): Point2D {
    const oneMinus: number = 1 - t;
    const b0: number = oneMinus * oneMinus * oneMinus;
    const b1: number = 3 * oneMinus * oneMinus * t;
    const b2: number = 3 * oneMinus * t * t;
    const b3: number = t * t * t;
    return {
      x: b0 * segment.p0.x + b1 * segment.p1.x + b2 * segment.p2.x + b3 * segment.p3.x,
      y: b0 * segment.p0.y + b1 * segment.p1.y + b2 * segment.p2.y + b3 * segment.p3.y,
    };
  }

  private interpolatePathPoint(start: StrokePathPoint, end: StrokePathPoint,
    t: number, position: Point2D): StrokePathPoint {
    const azimuthX: number = start.azimuthUnitX + (end.azimuthUnitX - start.azimuthUnitX) * t;
    const azimuthY: number = start.azimuthUnitY + (end.azimuthUnitY - start.azimuthUnitY) * t;
    const azimuthLength: number = Math.sqrt(azimuthX * azimuthX + azimuthY * azimuthY);
    return {
      position: { x: position.x, y: position.y },
      widthFactor: start.widthFactor + (end.widthFactor - start.widthFactor) * t,
      pressure: start.pressure + (end.pressure - start.pressure) * t,
      altitudeAngleRadians: start.altitudeAngleRadians +
        (end.altitudeAngleRadians - start.altitudeAngleRadians) * t,
      azimuthUnitX: azimuthLength <= GEOMETRY_EPSILON ? 0 : azimuthX / azimuthLength,
      azimuthUnitY: azimuthLength <= GEOMETRY_EPSILON ? 0 : azimuthY / azimuthLength,
    };
  }

  private clonePathPoint(source: StrokePathPoint, position: Point2D): StrokePathPoint {
    return {
      position: { x: position.x, y: position.y },
      widthFactor: source.widthFactor,
      pressure: source.pressure,
      altitudeAngleRadians: source.altitudeAngleRadians,
      azimuthUnitX: source.azimuthUnitX,
      azimuthUnitY: source.azimuthUnitY,
    };
  }

  private lerpPoint(start: Point2D, end: Point2D, t: number): Point2D {
    return { x: start.x + (end.x - start.x) * t,
      y: start.y + (end.y - start.y) * t };
  }

  private pointDistance(start: Point2D, end: Point2D): number {
    const dx: number = end.x - start.x;
    const dy: number = end.y - start.y;
    return Math.sqrt(dx * dx + dy * dy);
  }

  private pointSegmentDistance(point: Point2D, start: Point2D, end: Point2D): number {
    const dx: number = end.x - start.x;
    const dy: number = end.y - start.y;
    const lengthSquared: number = dx * dx + dy * dy;
    if (lengthSquared <= GEOMETRY_EPSILON) {
      return this.pointDistance(point, start);
    }
    const rawT: number = ((point.x - start.x) * dx + (point.y - start.y) * dy) / lengthSquared;
    const t: number = Math.max(0, Math.min(1, rawT));
    return this.pointDistance(point, { x: start.x + t * dx, y: start.y + t * dy });
  }

  private transformPoint(point: Point2D, matrix: TransformMatrix): Point2D {
    return {
      x: matrix[0] * point.x + matrix[1] * point.y + matrix[2],
      y: matrix[3] * point.x + matrix[4] * point.y + matrix[5],
    };
  }

  setMode(mode: EraserMode): void {
    this.mode = mode;
  }

  setWidth(width: number): void {
    this.eraserWidth = width;
  }

  getMode(): EraserMode {
    return this.mode;
  }

  getWidth(): number {
    return this.eraserWidth;
  }
}
