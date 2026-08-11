import { CubicSegment, Point2D } from '../model/GeometryTypes';
import { PencilSplatPoint, StrokeElementData, StrokePathPoint } from '../model/StrokeTypes';
import { compareUnsignedLongDecimal, validateUnsignedLongDecimal } from '../../data/UnsignedDecimal';

const UINT64_MODULUS: string = '18446744073709551616';
const AUDIO_LINKED_ALPHA: number = 0.3;
const CUBIC_LENGTH_STEPS: number = 32;

export interface OriginalAudioSegmentRange {
  startTime: string;
  endTime: string;
}

export enum OriginalAudioLinkedPlaybackState {
  DISABLED = 0,
  UNBEGUN = 1,
  ANIMATING = 2,
  COMPLETE = 3,
}

export interface OriginalAudioLinkedPlayback {
  state: OriginalAudioLinkedPlaybackState;
  alpha: number | null;
  progress: number | null;
}

export function resolveOriginalAudioLinkedPlayback(stroke: StrokeElementData,
  currentAudioTime: string | null, segments: OriginalAudioSegmentRange[]): OriginalAudioLinkedPlayback {
  const start: string | undefined = stroke.audioStartTime;
  if (currentAudioTime === null || start === undefined || segments.length === 0) {
    return disabledPlayback();
  }
  try {
    validateUnsignedLongDecimal(start);
    validateUnsignedLongDecimal(currentAudioTime);
    if (!audioTimeBelongsToSegments(start, segments)) {
      return disabledPlayback();
    }
    const duration: number | null | undefined = stroke.audioDuration;
    const end: string | null = duration === null || duration === undefined ? null :
      addUint32ToUnsignedLong(start, duration);
    // This is the original s1j invariant: a wrapped/invalid end completes instead of animating.
    if (end !== null && compareUnsignedLongDecimal(end, start) < 0) {
      return completePlayback();
    }
    if (compareUnsignedLongDecimal(currentAudioTime, start) < 0) {
      return { state: OriginalAudioLinkedPlaybackState.UNBEGUN,
        alpha: AUDIO_LINKED_ALPHA, progress: null };
    }
    if (end !== null && compareUnsignedLongDecimal(currentAudioTime, end) < 0) {
      const total: number = duration as number;
      if (total > 0) {
        const elapsed: number = subtractUnsignedDecimalToNumber(currentAudioTime, start);
        return { state: OriginalAudioLinkedPlaybackState.ANIMATING,
          alpha: AUDIO_LINKED_ALPHA, progress: clampFraction(elapsed / total) };
      }
    }
    return completePlayback();
  } catch (_error) {
    return disabledPlayback();
  }
}

export function originalAudioTimeAtPosition(startTime: string, endTime: string,
  positionMs: number): string {
  validateUnsignedLongDecimal(startTime);
  validateUnsignedLongDecimal(endTime);
  if (compareUnsignedLongDecimal(startTime, endTime) > 0) {
    throw new Error('recording audio range is reversed');
  }
  const duration: number = subtractUnsignedDecimalToSafeNumber(endTime, startTime);
  const position: number = !Number.isFinite(positionMs) || positionMs <= 0 ? 0 :
    Math.min(Math.round(positionMs), duration);
  return addSafeNumberToUnsignedLong(startTime, position);
}

export function effectiveOriginalAudioSegments(segments: OriginalAudioSegmentRange[],
  fallbackStart: string, fallbackEnd: string): OriginalAudioSegmentRange[] {
  if (segments.length === 0) {
    return [{ startTime: fallbackStart, endTime: fallbackEnd }];
  }
  return segments.map((segment: OriginalAudioSegmentRange): OriginalAudioSegmentRange => ({
    startTime: segment.startTime, endTime: segment.endTime,
  }));
}

export function sliceStrokeForAudioProgress(stroke: StrokeElementData,
  progress: number): StrokeElementData {
  const fraction: number = clampFraction(progress);
  if (stroke.renderSpec.isPencil) {
    const count: number = Math.floor(stroke.splatPoints.length * fraction);
    return playbackStroke(stroke, stroke.pathPoints, stroke.cubicSegments,
      stroke.splatPoints.slice(0, count));
  }
  if (stroke.cubicSegments.length > 0) {
    return sliceCubicStroke(stroke, fraction);
  }
  return slicePolylineStroke(stroke, fraction);
}

function audioTimeBelongsToSegments(time: string, segments: OriginalAudioSegmentRange[]): boolean {
  for (const segment of segments) {
    validateUnsignedLongDecimal(segment.startTime);
    validateUnsignedLongDecimal(segment.endTime);
    if (compareUnsignedLongDecimal(segment.startTime, segment.endTime) <= 0 &&
      compareUnsignedLongDecimal(time, segment.startTime) >= 0 &&
      compareUnsignedLongDecimal(time, segment.endTime) <= 0) {
      return true;
    }
  }
  return false;
}

function sliceCubicStroke(stroke: StrokeElementData, fraction: number): StrokeElementData {
  const lengths: number[] = stroke.cubicSegments.map((segment: CubicSegment): number => cubicLength(segment));
  const target: number = sum(lengths) * fraction;
  const segments: CubicSegment[] = [];
  const points: StrokePathPoint[] = [];
  if (stroke.pathPoints.length > 0) {
    points.push(cloneStrokePoint(stroke.pathPoints[0]));
  }
  let consumed: number = 0;
  for (let index: number = 0; index < stroke.cubicSegments.length; index++) {
    const segment: CubicSegment = stroke.cubicSegments[index];
    const length: number = lengths[index];
    if (consumed + length <= target) {
      segments.push(cloneCubic(segment));
      points.push(pointForSegmentEnd(stroke, index, 1, segment.p3));
      consumed += length;
      continue;
    }
    if (target > consumed && length > 0) {
      const localFraction: number = (target - consumed) / length;
      const t: number = cubicParameterAtLengthFraction(segment, localFraction);
      const left: CubicSegment = splitCubicLeft(segment, t);
      segments.push(left);
      points.push(pointForSegmentEnd(stroke, index, t, left.p3));
    }
    break;
  }
  return playbackStroke(stroke, points, segments, []);
}

function slicePolylineStroke(stroke: StrokeElementData, fraction: number): StrokeElementData {
  if (stroke.pathPoints.length === 0) {
    return playbackStroke(stroke, [], [], []);
  }
  const lengths: number[] = [];
  for (let index: number = 1; index < stroke.pathPoints.length; index++) {
    lengths.push(distance(stroke.pathPoints[index - 1].position, stroke.pathPoints[index].position));
  }
  const target: number = sum(lengths) * fraction;
  const points: StrokePathPoint[] = [cloneStrokePoint(stroke.pathPoints[0])];
  let consumed: number = 0;
  for (let index: number = 0; index < lengths.length; index++) {
    const length: number = lengths[index];
    if (consumed + length <= target) {
      points.push(cloneStrokePoint(stroke.pathPoints[index + 1]));
      consumed += length;
      continue;
    }
    if (target > consumed && length > 0) {
      points.push(interpolateStrokePoint(stroke.pathPoints[index], stroke.pathPoints[index + 1],
        (target - consumed) / length));
    }
    break;
  }
  return playbackStroke(stroke, points, [], []);
}

function playbackStroke(stroke: StrokeElementData, pathPoints: StrokePathPoint[],
  cubicSegments: CubicSegment[], splatPoints: PencilSplatPoint[]): StrokeElementData {
  return {
    id: stroke.id, pathPoints: pathPoints, cubicSegments: cubicSegments, splatPoints: splatPoints,
    renderSpec: stroke.renderSpec, transform: stroke.transform, bounds: stroke.bounds,
    maskPath: stroke.maskPath, customPath: null, fillPath: null, fillColor: null,
    styleMap: stroke.styleMap, audioStartTime: stroke.audioStartTime,
    audioDuration: stroke.audioDuration, isFinished: stroke.isFinished,
  };
}

function pointForSegmentEnd(stroke: StrokeElementData, segmentIndex: number,
  fraction: number, position: Point2D): StrokePathPoint {
  if (segmentIndex + 1 < stroke.pathPoints.length) {
    const point: StrokePathPoint = interpolateStrokePoint(
      stroke.pathPoints[segmentIndex], stroke.pathPoints[segmentIndex + 1], fraction);
    point.position = { x: position.x, y: position.y };
    return point;
  }
  const source: StrokePathPoint = stroke.pathPoints.length === 0 ? defaultStrokePoint(position) :
    stroke.pathPoints[stroke.pathPoints.length - 1];
  const result: StrokePathPoint = cloneStrokePoint(source);
  result.position = { x: position.x, y: position.y };
  return result;
}

function cubicParameterAtLengthFraction(segment: CubicSegment, fraction: number): number {
  const target: number = cubicLength(segment) * clampFraction(fraction);
  let previous: Point2D = segment.p0;
  let consumed: number = 0;
  for (let step: number = 1; step <= CUBIC_LENGTH_STEPS; step++) {
    const t: number = step / CUBIC_LENGTH_STEPS;
    const current: Point2D = cubicPoint(segment, t);
    const piece: number = distance(previous, current);
    if (consumed + piece >= target && piece > 0) {
      return ((step - 1) + (target - consumed) / piece) / CUBIC_LENGTH_STEPS;
    }
    consumed += piece;
    previous = current;
  }
  return 1;
}

function cubicLength(segment: CubicSegment): number {
  let length: number = 0;
  let previous: Point2D = segment.p0;
  for (let step: number = 1; step <= CUBIC_LENGTH_STEPS; step++) {
    const current: Point2D = cubicPoint(segment, step / CUBIC_LENGTH_STEPS);
    length += distance(previous, current);
    previous = current;
  }
  return length;
}

function cubicPoint(segment: CubicSegment, t: number): Point2D {
  const inverse: number = 1 - t;
  return {
    x: inverse * inverse * inverse * segment.p0.x + 3 * inverse * inverse * t * segment.p1.x +
      3 * inverse * t * t * segment.p2.x + t * t * t * segment.p3.x,
    y: inverse * inverse * inverse * segment.p0.y + 3 * inverse * inverse * t * segment.p1.y +
      3 * inverse * t * t * segment.p2.y + t * t * t * segment.p3.y,
  };
}

function splitCubicLeft(segment: CubicSegment, t: number): CubicSegment {
  const p01: Point2D = interpolatePoint(segment.p0, segment.p1, t);
  const p12: Point2D = interpolatePoint(segment.p1, segment.p2, t);
  const p23: Point2D = interpolatePoint(segment.p2, segment.p3, t);
  const p012: Point2D = interpolatePoint(p01, p12, t);
  const p123: Point2D = interpolatePoint(p12, p23, t);
  return { p0: clonePoint(segment.p0), p1: p01, p2: p012, p3: interpolatePoint(p012, p123, t) };
}

function interpolateStrokePoint(left: StrokePathPoint, right: StrokePathPoint,
  fraction: number): StrokePathPoint {
  return {
    position: interpolatePoint(left.position, right.position, fraction),
    widthFactor: interpolate(left.widthFactor, right.widthFactor, fraction),
    pressure: interpolate(left.pressure, right.pressure, fraction),
    altitudeAngleRadians: interpolate(left.altitudeAngleRadians, right.altitudeAngleRadians, fraction),
    azimuthUnitX: interpolate(left.azimuthUnitX, right.azimuthUnitX, fraction),
    azimuthUnitY: interpolate(left.azimuthUnitY, right.azimuthUnitY, fraction),
  };
}

function cloneStrokePoint(point: StrokePathPoint): StrokePathPoint {
  return { position: clonePoint(point.position), widthFactor: point.widthFactor,
    pressure: point.pressure, altitudeAngleRadians: point.altitudeAngleRadians,
    azimuthUnitX: point.azimuthUnitX, azimuthUnitY: point.azimuthUnitY };
}

function defaultStrokePoint(position: Point2D): StrokePathPoint {
  return { position: clonePoint(position), widthFactor: 1, pressure: -1,
    altitudeAngleRadians: -1, azimuthUnitX: 0, azimuthUnitY: 0 };
}

function cloneCubic(segment: CubicSegment): CubicSegment {
  return { p0: clonePoint(segment.p0), p1: clonePoint(segment.p1),
    p2: clonePoint(segment.p2), p3: clonePoint(segment.p3) };
}

function clonePoint(point: Point2D): Point2D {
  return { x: point.x, y: point.y };
}

function interpolatePoint(left: Point2D, right: Point2D, fraction: number): Point2D {
  return { x: interpolate(left.x, right.x, fraction), y: interpolate(left.y, right.y, fraction) };
}

function interpolate(left: number, right: number, fraction: number): number {
  return left + (right - left) * fraction;
}

function distance(left: Point2D, right: Point2D): number {
  return Math.hypot(right.x - left.x, right.y - left.y);
}

function sum(values: number[]): number {
  let result: number = 0;
  for (const value of values) {
    result += value;
  }
  return result;
}

function addUint32ToUnsignedLong(value: string, duration: number): string {
  if (!Number.isSafeInteger(duration) || duration < 0 || duration > 0xFFFFFFFF) {
    throw new Error('audio duration is not uint32');
  }
  return addSafeNumberToUnsignedLong(value, duration);
}

function addSafeNumberToUnsignedLong(value: string, increment: number): string {
  validateUnsignedLongDecimal(value);
  if (!Number.isSafeInteger(increment) || increment < 0) {
    throw new Error('unsigned decimal increment is invalid');
  }
  let carry: number = increment;
  let index: number = value.length - 1;
  let result: string = '';
  while (index >= 0 || carry > 0) {
    const digit: number = index >= 0 ? value.charCodeAt(index) - 0x30 : 0;
    const total: number = digit + carry;
    result = `${total % 10}${result}`;
    carry = Math.floor(total / 10);
    index--;
  }
  if (index >= 0) {
    result = `${value.substring(0, index + 1)}${result}`;
  }
  if (compareUnboundedDecimal(result, UINT64_MODULUS) >= 0) {
    result = subtractDecimal(result, UINT64_MODULUS);
  }
  validateUnsignedLongDecimal(result);
  return result;
}

function subtractUnsignedDecimalToNumber(left: string, right: string): number {
  return Number(subtractDecimal(left, right));
}

function subtractUnsignedDecimalToSafeNumber(left: string, right: string): number {
  const result: string = subtractDecimal(left, right);
  const value: number = Number(result);
  if (!Number.isSafeInteger(value)) {
    throw new Error('unsigned decimal difference exceeds safe integer');
  }
  return value;
}

function subtractDecimal(left: string, right: string): string {
  if (compareUnboundedDecimal(left, right) < 0) {
    throw new Error('unsigned decimal subtraction is negative');
  }
  let borrow: number = 0;
  let result: string = '';
  let leftIndex: number = left.length - 1;
  let rightIndex: number = right.length - 1;
  while (leftIndex >= 0) {
    let digit: number = left.charCodeAt(leftIndex) - 0x30 - borrow;
    const subtrahend: number = rightIndex >= 0 ? right.charCodeAt(rightIndex) - 0x30 : 0;
    if (digit < subtrahend) {
      digit += 10;
      borrow = 1;
    } else {
      borrow = 0;
    }
    result = `${digit - subtrahend}${result}`;
    leftIndex--;
    rightIndex--;
  }
  let first: number = 0;
  while (first + 1 < result.length && result.charAt(first) === '0') {
    first++;
  }
  return result.substring(first);
}

function compareUnboundedDecimal(left: string, right: string): number {
  if (left.length !== right.length) {
    return left.length < right.length ? -1 : 1;
  }
  return left === right ? 0 : left < right ? -1 : 1;
}

function clampFraction(value: number): number {
  if (!Number.isFinite(value) || value <= 0) {
    return 0;
  }
  return Math.min(value, 1);
}

function disabledPlayback(): OriginalAudioLinkedPlayback {
  return { state: OriginalAudioLinkedPlaybackState.DISABLED, alpha: null, progress: null };
}

function completePlayback(): OriginalAudioLinkedPlayback {
  return { state: OriginalAudioLinkedPlaybackState.COMPLETE, alpha: null, progress: null };
}
