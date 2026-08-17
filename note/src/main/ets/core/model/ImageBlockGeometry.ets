import { ImageElement } from './ElementTypes';
import { Point2D, Rect2D, TransformMatrix } from './GeometryTypes';
import { eraserPathHitsAffineBlock, selectionPathHitsAffineBlock } from './BlockHitGeometry';

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

export function imageBlockLocalBounds(element: ImageElement): Rect2D {
  return { left: 0, top: 0, right: element.blockWidth, bottom: element.blockHeight };
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
  return eraserPathHitsAffineBlock(
    eraserPath, imageBlockLocalBounds(element), element.transform, eraserWidth);
}

export function selectionPathHitsImageBlock(selectionPath: Point2D[],
  element: ImageElement): boolean {
  return selectionPathHitsAffineBlock(
    selectionPath, imageBlockLocalBounds(element), element.transform);
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

function transformPoint(point: Point2D, matrix: TransformMatrix): Point2D {
  return {
    x: matrix[0] * point.x + matrix[1] * point.y + matrix[2],
    y: matrix[3] * point.x + matrix[4] * point.y + matrix[5],
  };
}

function cloneRect(rect: Rect2D): Rect2D {
  return { left: rect.left, top: rect.top, right: rect.right, bottom: rect.bottom };
}
