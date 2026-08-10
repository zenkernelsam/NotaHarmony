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

function transformPoint(point: Point2D, matrix: TransformMatrix): Point2D {
  return {
    x: matrix[0] * point.x + matrix[1] * point.y + matrix[2],
    y: matrix[3] * point.x + matrix[4] * point.y + matrix[5],
  };
}

function cloneRect(rect: Rect2D): Rect2D {
  return { left: rect.left, top: rect.top, right: rect.right, bottom: rect.bottom };
}
