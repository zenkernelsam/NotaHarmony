import { ImageElement } from './ElementTypes';
import { Point2D, Rect2D, TransformMatrix } from './GeometryTypes';

const HEX_DIGITS: string = '0123456789abcdef';
const MAX_UINT64_DECIMAL: string = '18446744073709551615';

export function originalAssetHashKey(bits: string[]): string {
  return bits.join(':');
}

// Original ba6.e0/f0 and zq6.h: each uint64 word is emitted least-significant byte first.
export function originalAssetStorageHash(bits: string[]): string {
  if (bits.length !== 8) {
    throw new Error('original asset hash must contain eight uint64 words');
  }
  let result: string = '';
  for (const word of bits) {
    validateAssetHashWord(word);
    let remaining: string = word;
    for (let byteIndex: number = 0; byteIndex < 8; byteIndex++) {
      const divided: DecimalDivision = divideDecimalBy256(remaining);
      result += HEX_DIGITS.charAt((divided.remainder >>> 4) & 0x0F);
      result += HEX_DIGITS.charAt(divided.remainder & 0x0F);
      remaining = divided.quotient;
    }
    if (remaining !== '0') {
      throw new Error('original asset hash word exceeds uint64');
    }
  }
  return result;
}

function validateAssetHashWord(value: string): void {
  if (value.length === 0 || value.length > MAX_UINT64_DECIMAL.length ||
    (value.length > 1 && value.charAt(0) === '0')) {
    throw new Error('original asset hash word is not canonical uint64');
  }
  for (let index: number = 0; index < value.length; index++) {
    const code: number = value.charCodeAt(index);
    if (code < 0x30 || code > 0x39) {
      throw new Error('original asset hash word contains a non-digit');
    }
  }
  if (value.length === MAX_UINT64_DECIMAL.length && value > MAX_UINT64_DECIMAL) {
    throw new Error('original asset hash word exceeds uint64');
  }
}

export function originalAssetLookupKeys(element: ImageElement): string[] {
  const storageHash: string = originalAssetStorageHash(element.assetHashBits);
  return storageHash === element.assetHash ? [storageHash] : [storageHash, element.assetHash];
}

export function imageAssetPackageMetadataMatches(left: ImageElement, right: ImageElement): boolean {
  return originalAssetStorageHash(left.assetHashBits) === originalAssetStorageHash(right.assetHashBits) &&
    left.fileSize === right.fileSize && left.mimeType.toLowerCase() === right.mimeType.toLowerCase();
}

interface DecimalDivision {
  quotient: string;
  remainder: number;
}

function divideDecimalBy256(value: string): DecimalDivision {
  let quotient: string = '';
  let remainder: number = 0;
  for (let index: number = 0; index < value.length; index++) {
    const current: number = remainder * 10 + value.charCodeAt(index) - 0x30;
    const digit: number = Math.floor(current / 256);
    remainder = current % 256;
    if (quotient.length > 0 || digit !== 0) {
      quotient += digit.toString();
    }
  }
  return { quotient: quotient.length === 0 ? '0' : quotient, remainder: remainder };
}

export function cloneImageElement(element: ImageElement): ImageElement {
  return {
    id: element.id,
    type: element.type,
    transform: element.transform.slice(),
    bounds: cloneRect(element.bounds),
    assetHash: element.assetHash,
    assetHashBits: element.assetHashBits.slice(),
    fileName: element.fileName,
    mimeType: element.mimeType,
    fileSize: element.fileSize,
    intrinsicWidth: element.intrinsicWidth,
    intrinsicHeight: element.intrinsicHeight,
    cropRect: element.cropRect === null ? null : cloneRect(element.cropRect),
    blockWidth: element.blockWidth,
    blockHeight: element.blockHeight,
    rotationRadians: element.rotationRadians,
    corner: element.corner,
    textWrap: element.textWrap,
    enableCaption: element.enableCaption,
    webUrl: element.webUrl,
    imageFlippedHorizontally: element.imageFlippedHorizontally,
    imageFlippedVertically: element.imageFlippedVertically,
    positionLocked: element.positionLocked,
  };
}

export function reflectImageCropRect(crop: Rect2D, intrinsicWidth: number,
  intrinsicHeight: number, horizontal: boolean): Rect2D {
  const x: number = Math.fround(crop.left);
  const y: number = Math.fround(crop.top);
  const width: number = Math.fround(crop.right - crop.left);
  const height: number = Math.fround(crop.bottom - crop.top);
  const reflectedX: number = horizontal ? Math.fround(Math.fround(intrinsicWidth) -
    Math.fround(x + width)) : x;
  const reflectedY: number = horizontal ? y : Math.fround(Math.fround(intrinsicHeight) -
    Math.fround(y + height));
  return {
    left: reflectedX, top: reflectedY,
    right: reflectedX + width, bottom: reflectedY + height,
  };
}

export function imageBlockWorldBounds(element: ImageElement): Rect2D {
  const corners: Point2D[] = [
    transformPoint({ x: 0, y: 0 }, element.transform),
    transformPoint({ x: element.blockWidth, y: 0 }, element.transform),
    transformPoint({ x: element.blockWidth, y: element.blockHeight }, element.transform),
    transformPoint({ x: 0, y: element.blockHeight }, element.transform),
  ];
  let left: number = corners[0].x;
  let top: number = corners[0].y;
  let right: number = corners[0].x;
  let bottom: number = corners[0].y;
  for (let index: number = 1; index < corners.length; index++) {
    left = Math.min(left, corners[index].x);
    top = Math.min(top, corners[index].y);
    right = Math.max(right, corners[index].x);
    bottom = Math.max(bottom, corners[index].y);
  }
  return { left: left, top: top, right: right, bottom: bottom };
}

export function isImageBlockPositionLocked(element: ImageElement): boolean {
  return element.positionLocked === true;
}

export function transformImageElements(elements: ImageElement[], selectedIds: string[],
  transform: TransformMatrix): ImageElement[] {
  const selected: Set<string> = new Set<string>(selectedIds);
  const result: ImageElement[] = [];
  for (const element of elements) {
    if (!selected.has(element.id) || isImageBlockPositionLocked(element)) {
      result.push(element);
      continue;
    }
    const updated: ImageElement = cloneImageElement(element);
    updated.transform = multiplyTransform(transform, element.transform);
    updated.rotationRadians = Math.atan2(updated.transform[3], updated.transform[0]);
    updated.bounds = imageBlockWorldBounds(updated);
    result.push(updated);
  }
  return result;
}

export function eraserPathHitsImageBlock(eraserPath: Point2D[], element: ImageElement,
  eraserWidth: number): boolean {
  if (eraserPath.length === 0 || isImageBlockPositionLocked(element)) {
    return false;
  }
  const corners: Point2D[] = imageBlockWorldCorners(element);
  for (const point of eraserPath) {
    if (pointInPolygon(point, corners)) {
      return true;
    }
  }
  const closed: Point2D[] = corners.concat([corners[0]]);
  const radius: number = Math.max(0, eraserWidth) / 2;
  const segmentCount: number = Math.max(1, eraserPath.length - 1);
  for (let i: number = 0; i < segmentCount; i++) {
    const start: Point2D = eraserPath[i];
    const end: Point2D = eraserPath.length === 1 ? start : eraserPath[i + 1];
    for (let edge: number = 0; edge < corners.length; edge++) {
      if (segmentDistance(start, end, closed[edge], closed[edge + 1]) <= radius) {
        return true;
      }
    }
  }
  return false;
}

function imageBlockWorldCorners(element: ImageElement): Point2D[] {
  return [
    transformPoint({ x: 0, y: 0 }, element.transform),
    transformPoint({ x: element.blockWidth, y: 0 }, element.transform),
    transformPoint({ x: element.blockWidth, y: element.blockHeight }, element.transform),
    transformPoint({ x: 0, y: element.blockHeight }, element.transform),
  ];
}

function multiplyTransform(a: TransformMatrix, b: TransformMatrix): TransformMatrix {
  return [
    a[0] * b[0] + a[1] * b[3], a[0] * b[1] + a[1] * b[4],
    a[0] * b[2] + a[1] * b[5] + a[2],
    a[3] * b[0] + a[4] * b[3], a[3] * b[1] + a[4] * b[4],
    a[3] * b[2] + a[4] * b[5] + a[5],
    0, 0, 1,
  ];
}

function pointInPolygon(point: Point2D, polygon: Point2D[]): boolean {
  let inside: boolean = false;
  for (let i: number = 0, j: number = polygon.length - 1; i < polygon.length; j = i++) {
    const left: Point2D = polygon[i];
    const right: Point2D = polygon[j];
    if ((left.y > point.y) !== (right.y > point.y) &&
      point.x < (right.x - left.x) * (point.y - left.y) / (right.y - left.y) + left.x) {
      inside = !inside;
    }
  }
  return inside;
}

function segmentDistance(a0: Point2D, a1: Point2D, b0: Point2D, b1: Point2D): number {
  if (segmentsIntersect(a0, a1, b0, b1)) {
    return 0;
  }
  return Math.min(pointSegmentDistance(a0, b0, b1), pointSegmentDistance(a1, b0, b1),
    pointSegmentDistance(b0, a0, a1), pointSegmentDistance(b1, a0, a1));
}

function segmentsIntersect(a0: Point2D, a1: Point2D, b0: Point2D, b1: Point2D): boolean {
  const o1: number = orientation(a0, a1, b0);
  const o2: number = orientation(a0, a1, b1);
  const o3: number = orientation(b0, b1, a0);
  const o4: number = orientation(b0, b1, a1);
  const epsilon: number = 0.0000001;
  if (((o1 > epsilon && o2 < -epsilon) || (o1 < -epsilon && o2 > epsilon)) &&
    ((o3 > epsilon && o4 < -epsilon) || (o3 < -epsilon && o4 > epsilon))) {
    return true;
  }
  return (Math.abs(o1) <= epsilon && pointOnSegment(b0, a0, a1, epsilon)) ||
    (Math.abs(o2) <= epsilon && pointOnSegment(b1, a0, a1, epsilon)) ||
    (Math.abs(o3) <= epsilon && pointOnSegment(a0, b0, b1, epsilon)) ||
    (Math.abs(o4) <= epsilon && pointOnSegment(a1, b0, b1, epsilon));
}

function pointOnSegment(point: Point2D, start: Point2D, end: Point2D, epsilon: number): boolean {
  return point.x >= Math.min(start.x, end.x) - epsilon &&
    point.x <= Math.max(start.x, end.x) + epsilon &&
    point.y >= Math.min(start.y, end.y) - epsilon &&
    point.y <= Math.max(start.y, end.y) + epsilon;
}

function orientation(a: Point2D, b: Point2D, c: Point2D): number {
  return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
}

function pointSegmentDistance(point: Point2D, start: Point2D, end: Point2D): number {
  const dx: number = end.x - start.x;
  const dy: number = end.y - start.y;
  const lengthSquared: number = dx * dx + dy * dy;
  if (lengthSquared <= 0.0000001) {
    return Math.hypot(point.x - start.x, point.y - start.y);
  }
  const t: number = Math.max(0, Math.min(1,
    ((point.x - start.x) * dx + (point.y - start.y) * dy) / lengthSquared));
  return Math.hypot(point.x - (start.x + t * dx), point.y - (start.y + t * dy));
}

function transformPoint(point: Point2D, matrix: TransformMatrix): Point2D {
  return {
    x: matrix[0] * point.x + matrix[1] * point.y + matrix[2],
    y: matrix[3] * point.x + matrix[4] * point.y + matrix[5],
  };
}

function cloneRect(rect: Rect2D): Rect2D {
  return { left: rect.left, top: rect.top, right: rect.right, bottom: rect.bottom };
}
