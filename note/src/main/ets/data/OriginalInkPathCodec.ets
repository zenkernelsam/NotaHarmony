import { CubicSegment, Point2D, Rect2D, TransformMatrix } from '../core/model/GeometryTypes';
import { StrokePathPoint } from '../core/model/StrokeTypes';

export interface DecodedOriginalInkPath {
  pathPoints: StrokePathPoint[];
  cubicSegments: CubicSegment[];
  localBounds: Rect2D;
  attributed: boolean;
}

export interface DecodedOriginalInkPathAppend extends DecodedOriginalInkPath {
  endPoint: Point2D;
}

interface DecodedElement {
  type: number;
  points: Point2D[];
  width: number;
  force: number;
  altitude: number;
  azimuth: number;
  attributed: boolean;
}

export class OriginalInkPathDeferredError extends Error {
  readonly deferredReason: string;

  constructor(deferredReason: string) {
    super(deferredReason);
    this.deferredReason = deferredReason;
  }
}

const MAX_PATH_ELEMENTS: number = 65535;

export function decodeOriginalInkPath(bytes: Uint8Array): DecodedOriginalInkPath {
  return decodeCanonicalInkPath(bytes,
    'CREATE_INK_PATH_VERSION_UNSUPPORTED',
    'CREATE_INK_PATH_COORDINATE_ENCODING_UNSUPPORTED',
    'CREATE_INK_CENTER_PATH_TOO_SHORT',
    'CREATE_INK_MULTI_COMPONENT_PATH_UNSUPPORTED');
}

export function decodeOriginalInkPathReplacement(bytes: Uint8Array): DecodedOriginalInkPath {
  return decodeCanonicalInkPath(bytes,
    'MODIFY_INK_PATH_VERSION_UNSUPPORTED',
    'MODIFY_INK_PATH_COORDINATE_ENCODING_UNSUPPORTED',
    'MODIFY_INK_CENTER_PATH_TOO_SHORT',
    'MODIFY_INK_MULTI_COMPONENT_PATH_UNSUPPORTED');
}

function decodeCanonicalInkPath(bytes: Uint8Array, versionReason: string,
  encodingReason: string, lengthReason: string, multiComponentReason: string): DecodedOriginalInkPath {
  const elements: DecodedElement[] = decodeElements(bytes, 2,
    versionReason, encodingReason, lengthReason);
  if (elements[0].type !== 3 && elements[0].type !== 7) {
    throw new Error('original ink path is not one canonical component');
  }
  for (let index: number = 1; index < elements.length; index++) {
    if (isMove(elements[index])) {
      throw new OriginalInkPathDeferredError(multiComponentReason);
    }
  }
  const converted: DecodedOriginalInkPathAppend = convertElements(
    elements.slice(1), elements[0].points[0]);
  converted.pathPoints.unshift(toPathPoint(elements[0], elements[0].points[0]));
  converted.attributed = converted.attributed && elements[0].attributed;
  converted.localBounds = elementBounds(elements, null);
  return converted;
}

export function decodeOriginalInkPathAppend(bytes: Uint8Array,
  start: Point2D): DecodedOriginalInkPathAppend {
  const elements: DecodedElement[] = decodeElements(bytes, 1,
    'ADD_PATH_ELEMENTS_PATH_VERSION_UNSUPPORTED',
    'ADD_PATH_ELEMENTS_PATH_COORDINATE_ENCODING_UNSUPPORTED',
    'ADD_PATH_ELEMENTS_CENTER_PATH_EMPTY');
  for (const element of elements) {
    if (isMove(element)) {
      throw new OriginalInkPathDeferredError('ADD_PATH_ELEMENTS_MULTI_COMPONENT_UNSUPPORTED');
    }
  }
  return convertElements(elements, start);
}

export function unionOriginalInkBounds(left: Rect2D, right: Rect2D): Rect2D {
  return {
    left: Math.min(left.left, right.left), top: Math.min(left.top, right.top),
    right: Math.max(left.right, right.right), bottom: Math.max(left.bottom, right.bottom),
  };
}

function decodeElements(bytes: Uint8Array, minimumCount: number,
  versionReason: string, encodingReason: string, lengthReason: string): DecodedElement[] {
  if (bytes.length < 3) {
    throw new Error('original ink path header is truncated');
  }
  const version: number = bytes[0] >>> 3;
  const coordinateEncoding: number = bytes[0] & 7;
  if (version !== 0) {
    throw new OriginalInkPathDeferredError(versionReason);
  }
  if (coordinateEncoding !== 0 && coordinateEncoding !== 1) {
    throw new OriginalInkPathDeferredError(encodingReason);
  }
  const count: number = bytes[1] * 256 + bytes[2];
  if (count < minimumCount || count > MAX_PATH_ELEMENTS) {
    throw new OriginalInkPathDeferredError(lengthReason);
  }
  let offset: number = 3;
  const elements: DecodedElement[] = [];
  for (let index: number = 0; index < count; index++) {
    requireBytes(bytes, offset, 1);
    const type: number = bytes[offset++];
    if (type < 0 || type > 7) {
      throw new Error('original ink path element type is unknown');
    }
    const pointCount: number = type === 0 || type === 4 ? 3 :
      type === 1 || type === 5 ? 2 : 1;
    const points: Point2D[] = [];
    for (let pointIndex: number = 0; pointIndex < pointCount; pointIndex++) {
      const decoded = decodePoint(bytes, offset, coordinateEncoding);
      if (!Number.isFinite(decoded.point.x) || !Number.isFinite(decoded.point.y)) {
        throw new Error('original ink path contains a non-finite point');
      }
      points.push(decoded.point);
      offset = decoded.nextOffset;
    }
    const attributed: boolean = type <= 3;
    let width: number = 1;
    let force: number = -1;
    let altitude: number = -1;
    let azimuth: number = -1;
    if (attributed) {
      requireBytes(bytes, offset, 6);
      width = decodeHalf(bytes[offset] * 256 + bytes[offset + 1]);
      force = decodeHalf(bytes[offset + 2] * 256 + bytes[offset + 3]);
      altitude = bytes[offset + 4] * Math.PI / (2 * 255);
      azimuth = bytes[offset + 5] * Math.PI * 2 / 256;
      offset += 6;
      if (!Number.isFinite(width) || !Number.isFinite(force) || width < 0 || force < 0) {
        throw new Error('original ink path attributes are invalid');
      }
    }
    elements.push({ type: type, points: points, width: width, force: force,
      altitude: altitude, azimuth: azimuth, attributed: attributed });
  }
  if (offset !== bytes.length) {
    throw new Error('original ink path has trailing bytes');
  }
  return elements;
}

function convertElements(elements: DecodedElement[], start: Point2D): DecodedOriginalInkPathAppend {
  const pathPoints: StrokePathPoint[] = [];
  const cubicSegments: CubicSegment[] = [];
  let current: Point2D = clonePoint(start);
  let allAttributed: boolean = true;
  for (const element of elements) {
    let segment: CubicSegment;
    let end: Point2D;
    if (element.type === 0 || element.type === 4) {
      end = element.points[2];
      segment = { p0: clonePoint(current), p1: clonePoint(element.points[0]),
        p2: clonePoint(element.points[1]), p3: clonePoint(end) };
    } else if (element.type === 1 || element.type === 5) {
      const control: Point2D = element.points[0];
      end = element.points[1];
      segment = {
        p0: clonePoint(current),
        p1: { x: current.x + (control.x - current.x) * 2 / 3,
          y: current.y + (control.y - current.y) * 2 / 3 },
        p2: { x: end.x + (control.x - end.x) * 2 / 3,
          y: end.y + (control.y - end.y) * 2 / 3 },
        p3: clonePoint(end),
      };
    } else {
      end = element.points[0];
      segment = { p0: clonePoint(current),
        p1: { x: current.x + (end.x - current.x) / 3,
          y: current.y + (end.y - current.y) / 3 },
        p2: { x: current.x + (end.x - current.x) * 2 / 3,
          y: current.y + (end.y - current.y) * 2 / 3 }, p3: clonePoint(end) };
    }
    cubicSegments.push(segment);
    pathPoints.push(toPathPoint(element, end));
    current = end;
    allAttributed = allAttributed && element.attributed;
  }
  return {
    pathPoints: pathPoints,
    cubicSegments: cubicSegments,
    localBounds: elementBounds(elements, start),
    attributed: allAttributed,
    endPoint: clonePoint(current),
  };
}

export function originalInkTransform(originX: number, originY: number,
  rotation: number, scaleX: number, scaleY: number): TransformMatrix {
  const cos: number = Math.cos(rotation);
  const sin: number = Math.sin(rotation);
  return [cos * scaleX, -sin * scaleY, originX,
    sin * scaleX, cos * scaleY, originY, 0, 0, 1];
}

export function transformedExpandedBounds(bounds: Rect2D, width: number,
  transform: TransformMatrix): Rect2D {
  // Original s06.G()/cq.H() uses the control-point hull and pads it by 2 * base width.
  const padding: number = width * 2;
  const corners: Point2D[] = [
    { x: bounds.left - padding, y: bounds.top - padding },
    { x: bounds.right + padding, y: bounds.top - padding },
    { x: bounds.right + padding, y: bounds.bottom + padding },
    { x: bounds.left - padding, y: bounds.bottom + padding },
  ];
  let left: number = Number.MAX_VALUE;
  let top: number = Number.MAX_VALUE;
  let right: number = -Number.MAX_VALUE;
  let bottom: number = -Number.MAX_VALUE;
  for (const point of corners) {
    const x: number = transform[0] * point.x + transform[1] * point.y + transform[2];
    const y: number = transform[3] * point.x + transform[4] * point.y + transform[5];
    left = Math.min(left, x);
    top = Math.min(top, y);
    right = Math.max(right, x);
    bottom = Math.max(bottom, y);
  }
  return { left: left, top: top, right: right, bottom: bottom };
}

function decodePoint(bytes: Uint8Array, offset: number,
  encoding: number): { point: Point2D, nextOffset: number } {
  if (encoding === 0) {
    requireBytes(bytes, offset, 4);
    return { point: {
      x: decodeHalf(bytes[offset] * 256 + bytes[offset + 1]),
      y: decodeHalf(bytes[offset + 2] * 256 + bytes[offset + 3]),
    }, nextOffset: offset + 4 };
  }
  requireBytes(bytes, offset, 8);
  const view: DataView = new DataView(bytes.buffer, bytes.byteOffset + offset, 8);
  return { point: { x: view.getFloat32(0, true), y: view.getFloat32(4, true) },
    nextOffset: offset + 8 };
}

function decodeHalf(value: number): number {
  const sign: number = (value & 0x8000) === 0 ? 1 : -1;
  const exponent: number = (value >>> 10) & 0x1F;
  const fraction: number = value & 0x3FF;
  if (exponent === 0) {
    return sign * fraction * Math.pow(2, -24);
  }
  if (exponent === 31) {
    return fraction === 0 ? sign * Number.POSITIVE_INFINITY : Number.NaN;
  }
  return sign * (1 + fraction / 1024) * Math.pow(2, exponent - 15);
}

function toPathPoint(element: DecodedElement, position: Point2D): StrokePathPoint {
  return {
    position: clonePoint(position), widthFactor: element.width, pressure: element.force,
    altitudeAngleRadians: element.altitude,
    azimuthUnitX: element.azimuth < 0 ? 0 : Math.cos(element.azimuth),
    azimuthUnitY: element.azimuth < 0 ? 0 : Math.sin(element.azimuth),
  };
}

function elementBounds(elements: DecodedElement[], start: Point2D | null): Rect2D {
  const first: Point2D = start === null ? elements[0].points[0] : start;
  let left: number = first.x;
  let top: number = first.y;
  let right: number = left;
  let bottom: number = top;
  for (const element of elements) {
    for (const point of element.points) {
      left = Math.min(left, point.x);
      top = Math.min(top, point.y);
      right = Math.max(right, point.x);
      bottom = Math.max(bottom, point.y);
    }
  }
  return { left: left, top: top, right: right, bottom: bottom };
}

function isMove(element: DecodedElement): boolean {
  return element.type === 3 || element.type === 7;
}

function clonePoint(point: Point2D): Point2D {
  return { x: point.x, y: point.y };
}

function requireBytes(bytes: Uint8Array, offset: number, count: number): void {
  if (!Number.isSafeInteger(offset) || offset < 0 || count < 0 || offset > bytes.length - count) {
    throw new Error('original ink path is truncated');
  }
}
