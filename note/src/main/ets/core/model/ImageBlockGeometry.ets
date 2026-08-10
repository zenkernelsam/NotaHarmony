import { ImageElement } from './ElementTypes';
import { Point2D, Rect2D, TransformMatrix } from './GeometryTypes';

export function originalAssetHashKey(bits: string[]): string {
  return bits.join(':');
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
