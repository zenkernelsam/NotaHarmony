import { CubicSegment, Point2D } from '../core/model/GeometryTypes';
import {
  InkPathCommand, InkPathCommandType, StrokeElementData, StrokePathPoint,
} from '../core/model/StrokeTypes';

const MAX_PATH_ELEMENTS: number = 65535;
const HALF_MAX: number = 65504;

export function encodeOriginalInkCenterPath(stroke: StrokeElementData): Uint8Array {
  if (stroke.pathPoints.length === 0) {
    throw new Error('local CREATE_INK requires at least one path point');
  }
  const segmentCount: number = stroke.cubicSegments.length;
  const count: number = segmentCount === 0 ? 2 : segmentCount + 1;
  if (count > MAX_PATH_ELEMENTS) {
    throw new Error('local CREATE_INK path exceeds the original element limit');
  }
  const byteCount: number = 3 + attributedElementBytes(1) +
    (segmentCount === 0 ? attributedElementBytes(1) : segmentCount * attributedElementBytes(3));
  const bytes: Uint8Array = new Uint8Array(byteCount);
  // ldj.M2(..., true) selects version 0 with BITS_32 coordinates.
  bytes[0] = 1;
  writeU16BE(bytes, 1, count);
  let offset: number = 3;
  offset = writeAttributedElement(bytes, offset, 3,
    [stroke.pathPoints[0].position], stroke.pathPoints[0]);
  if (segmentCount === 0) {
    writeAttributedElement(bytes, offset, 2,
      [stroke.pathPoints[stroke.pathPoints.length - 1].position],
      stroke.pathPoints[stroke.pathPoints.length - 1]);
    return bytes;
  }
  for (let index: number = 0; index < segmentCount; index++) {
    const segment: CubicSegment = stroke.cubicSegments[index];
    const attributeIndex: number = Math.min(stroke.pathPoints.length - 1,
      Math.max(1, Math.round((index + 1) * (stroke.pathPoints.length - 1) / segmentCount)));
    offset = writeAttributedElement(bytes, offset, 0,
      [segment.p1, segment.p2, segment.p3], stroke.pathPoints[attributeIndex]);
  }
  return bytes;
}

// ldj.M2(..., true) uses the same attributed BITS_32 element encoding for
// ADD_PATH_ELEMENTS, but an append must never contain a MOVE element.
export function encodeOriginalInkPathAppend(stroke: StrokeElementData,
  firstSegment: number = 0, segmentCount: number = stroke.cubicSegments.length - firstSegment):
  Uint8Array {
  if (!Number.isSafeInteger(firstSegment) || firstSegment < 0 ||
    !Number.isSafeInteger(segmentCount) || segmentCount < 0 ||
    firstSegment > stroke.cubicSegments.length - segmentCount) {
    throw new Error('local ADD_PATH_ELEMENTS segment range is invalid');
  }
  const lineOnly: boolean = stroke.cubicSegments.length === 0 && firstSegment === 0 &&
    segmentCount === 0 && stroke.pathPoints.length >= 2;
  const count: number = lineOnly ? 1 : segmentCount;
  if (count < 1 || count > MAX_PATH_ELEMENTS) {
    throw new Error('local ADD_PATH_ELEMENTS path element count is invalid');
  }
  const byteCount: number = 3 + (lineOnly ? attributedElementBytes(1) :
    count * attributedElementBytes(3));
  const bytes: Uint8Array = new Uint8Array(byteCount);
  bytes[0] = 1;
  writeU16BE(bytes, 1, count);
  if (lineOnly) {
    writeAttributedElement(bytes, 3, 2,
      [stroke.pathPoints[stroke.pathPoints.length - 1].position],
      stroke.pathPoints[stroke.pathPoints.length - 1]);
    return bytes;
  }
  if (stroke.pathPoints.length < 2) {
    throw new Error('local ADD_PATH_ELEMENTS requires attributed path points');
  }
  let offset: number = 3;
  const totalSegments: number = stroke.cubicSegments.length;
  for (let index: number = firstSegment; index < firstSegment + segmentCount; index++) {
    const segment: CubicSegment = stroke.cubicSegments[index];
    const attributeIndex: number = Math.min(stroke.pathPoints.length - 1,
      Math.max(1, Math.round((index + 1) * (stroke.pathPoints.length - 1) / totalSegments)));
    offset = writeAttributedElement(bytes, offset, 0,
      [segment.p1, segment.p2, segment.p3], stroke.pathPoints[attributeIndex]);
  }
  return bytes;
}

// Original CREATE_INK fields 10/11 use the same path container as centerPath,
// but their elements are deliberately unattributed (Android types 4..7).
// Unlike centerPath, auxiliary paths may contain multiple MOVE components.
export function encodeOriginalAuxiliaryInkPath(commands: InkPathCommand[]): Uint8Array {
  if (commands.length > MAX_PATH_ELEMENTS) {
    throw new Error('local CREATE_INK auxiliary path exceeds the original element limit');
  }
  let byteCount: number = 3;
  for (const command of commands) {
    const pointCount: number = auxiliaryPointCount(command.type);
    if (command.points.length !== pointCount) {
      throw new Error('local CREATE_INK auxiliary path command has an invalid point count');
    }
    byteCount += 1 + pointCount * 8;
  }
  const bytes: Uint8Array = new Uint8Array(byteCount);
  // Version 0, BITS_32 coordinates, matching ldj.M2(..., false).
  bytes[0] = 1;
  writeU16BE(bytes, 1, commands.length);
  let offset: number = 3;
  for (const command of commands) {
    bytes[offset++] = auxiliaryElementType(command.type);
    for (const point of command.points) {
      if (!Number.isFinite(point.x) || !Number.isFinite(point.y)) {
        throw new Error('local CREATE_INK auxiliary path contains a non-finite coordinate');
      }
      writeF32LE(bytes, offset, point.x);
      writeF32LE(bytes, offset + 4, point.y);
      offset += 8;
    }
  }
  return bytes;
}

function auxiliaryPointCount(type: InkPathCommandType): number {
  if (type === InkPathCommandType.CUBIC) {
    return 3;
  }
  if (type === InkPathCommandType.QUADRATIC) {
    return 2;
  }
  return 1;
}

function auxiliaryElementType(type: InkPathCommandType): number {
  if (type === InkPathCommandType.CUBIC) {
    return 4;
  }
  if (type === InkPathCommandType.QUADRATIC) {
    return 5;
  }
  if (type === InkPathCommandType.LINE_TO) {
    return 6;
  }
  if (type === InkPathCommandType.MOVE_TO) {
    return 7;
  }
  throw new Error('local CREATE_INK auxiliary path command is unknown');
}

function attributedElementBytes(pointCount: number): number {
  return 1 + pointCount * 8 + 6;
}

function writeAttributedElement(bytes: Uint8Array, offset: number, type: number,
  points: Point2D[], attributes: StrokePathPoint): number {
  bytes[offset++] = type;
  for (const point of points) {
    if (!Number.isFinite(point.x) || !Number.isFinite(point.y)) {
      throw new Error('local CREATE_INK path contains a non-finite coordinate');
    }
    writeF32LE(bytes, offset, point.x);
    writeF32LE(bytes, offset + 4, point.y);
    offset += 8;
  }
  const width: number = finiteClamped(attributes.widthFactor, 0, HALF_MAX, 1);
  const force: number = finiteClamped(attributes.pressure, 0, HALF_MAX, 0);
  writeU16BE(bytes, offset, encodeHalf(width));
  writeU16BE(bytes, offset + 2, encodeHalf(force));
  bytes[offset + 4] = quantize(attributes.altitudeAngleRadians, Math.PI / 2, false);
  const azimuth: number = Math.atan2(attributes.azimuthUnitY, attributes.azimuthUnitX);
  bytes[offset + 5] = quantize(azimuth, Math.PI * 2, true);
  return offset + 6;
}

function finiteClamped(value: number, minimum: number, maximum: number,
  fallback: number): number {
  return Number.isFinite(value) ? Math.min(maximum, Math.max(minimum, value)) : fallback;
}

function quantize(value: number, range: number, wraps: boolean): number {
  if (!Number.isFinite(value) || value < 0) {
    return 0;
  }
  let normalized: number = value;
  if (wraps) {
    normalized %= range;
    if (normalized < 0) {
      normalized += range;
    }
    return Math.round(normalized * 256 / range) & 0xFF;
  }
  normalized = Math.min(range, normalized);
  return Math.min(255, Math.round(normalized * 255 / range));
}

function encodeHalf(value: number): number {
  const float: Float32Array = new Float32Array(1);
  const bits: Uint32Array = new Uint32Array(float.buffer);
  float[0] = value;
  const raw: number = bits[0];
  const sign: number = raw >>> 16 & 0x8000;
  let exponent: number = (raw >>> 23 & 0xFF) - 127 + 15;
  let fraction: number = raw & 0x7FFFFF;
  if (exponent <= 0) {
    if (exponent < -10) {
      return sign;
    }
    fraction = (fraction | 0x800000) >>> (1 - exponent);
    return sign | ((fraction + 0x1000 + (fraction >>> 13 & 1)) >>> 13);
  }
  if (exponent >= 31) {
    return sign | 0x7C00;
  }
  const rounded: number = fraction + 0x1000 + (fraction >>> 13 & 1);
  if ((rounded & 0x800000) !== 0) {
    exponent++;
    fraction = 0;
    if (exponent >= 31) {
      return sign | 0x7C00;
    }
  } else {
    fraction = rounded;
  }
  return sign | exponent << 10 | fraction >>> 13 & 0x3FF;
}

function writeF32LE(bytes: Uint8Array, offset: number, value: number): void {
  new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength).setFloat32(offset, value, true);
}

function writeU16BE(bytes: Uint8Array, offset: number, value: number): void {
  bytes[offset] = value >>> 8 & 0xFF;
  bytes[offset + 1] = value & 0xFF;
}
