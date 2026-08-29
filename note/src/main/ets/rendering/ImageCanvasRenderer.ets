import { ImageElement } from '../core/model/ElementTypes';
import { Rect2D, TransformMatrix } from '../core/model/GeometryTypes';
import { Canvas2DDrawingContext } from '../core/adaptation/Canvas2DStrokeRenderer';

export interface ImageRenderGeometry {
  cropPixels: Rect2D;
  scaleX: number;
  scaleY: number;
  orientationDegrees: number;
  mirroredHorizontally: boolean;
  orientedWidth: number;
  orientedHeight: number;
  orientationTransform: TransformMatrix;
  flipTranslateX: number;
  flipTranslateY: number;
  flipScaleX: number;
  flipScaleY: number;
}

export function imageRenderGeometry(element: ImageElement,
  bitmapWidth: number, bitmapHeight: number, orientationDegrees: number = 0,
  mirroredHorizontally: boolean = false): ImageRenderGeometry | null {
  if (!Number.isFinite(orientationDegrees) || ![0, 90, 180, 270].includes(orientationDegrees)) {
    return null;
  }
  if (!Number.isFinite(bitmapWidth) || !Number.isFinite(bitmapHeight) || bitmapWidth <= 0 || bitmapHeight <= 0 ||
    !Number.isFinite(element.blockWidth) || !Number.isFinite(element.blockHeight) ||
    element.blockWidth <= 0 || element.blockHeight <= 0) {
    return null;
  }
  const swapsAxes: boolean = orientationDegrees === 90 || orientationDegrees === 270;
  const orientedWidth: number = swapsAxes ? bitmapHeight : bitmapWidth;
  const orientedHeight: number = swapsAxes ? bitmapWidth : bitmapHeight;
  const intrinsicWidth: number = element.intrinsicWidth > 0 ? element.intrinsicWidth : orientedWidth;
  const intrinsicHeight: number = element.intrinsicHeight > 0 ? element.intrinsicHeight : orientedHeight;
  const pixelScaleX: number = orientedWidth / intrinsicWidth;
  const pixelScaleY: number = orientedHeight / intrinsicHeight;
  const source: Rect2D = element.cropRect === null ?
    { left: 0, top: 0, right: intrinsicWidth, bottom: intrinsicHeight } : element.cropRect;
  const cropPixels: Rect2D = {
    left: clamp(source.left * pixelScaleX, 0, orientedWidth),
    top: clamp(source.top * pixelScaleY, 0, orientedHeight),
    right: clamp(source.right * pixelScaleX, 0, orientedWidth),
    bottom: clamp(source.bottom * pixelScaleY, 0, orientedHeight),
  };
  const cropWidth: number = cropPixels.right - cropPixels.left;
  const cropHeight: number = cropPixels.bottom - cropPixels.top;
  if (cropWidth <= 0 || cropHeight <= 0) {
    return null;
  }
  const orientationTransform: TransformMatrix | null = originalImageOrientationTransform(
    bitmapWidth, bitmapHeight, orientationDegrees, mirroredHorizontally);
  if (orientationTransform === null) {
    return null;
  }
  return {
    cropPixels: cropPixels,
    scaleX: element.blockWidth / cropWidth,
    scaleY: element.blockHeight / cropHeight,
    orientationDegrees: orientationDegrees,
    mirroredHorizontally: mirroredHorizontally,
    orientedWidth: orientedWidth,
    orientedHeight: orientedHeight,
    orientationTransform: orientationTransform,
    flipTranslateX: element.imageFlippedHorizontally ? orientedWidth : 0,
    flipTranslateY: element.imageFlippedVertically ? orientedHeight : 0,
    flipScaleX: element.imageFlippedHorizontally ? -1 : 1,
    flipScaleY: element.imageFlippedVertically ? -1 : 1,
  };
}

export class ImageCanvasRenderer {
  renderImage(element: ImageElement, bitmap: ImageBitmap, ctx: Canvas2DDrawingContext,
    orientationDegrees: number = 0,
    mirroredHorizontally: boolean = false): void {
    const geometry: ImageRenderGeometry | null = imageRenderGeometry(element, bitmap.width,
      bitmap.height, orientationDegrees, mirroredHorizontally);
    if (geometry === null) {
      return;
    }
    const crop: Rect2D = geometry.cropPixels;
    ctx.save();
    try {
      ctx.transform(element.transform);
      ctx.beginPath();
      ctx.rect(0, 0, element.blockWidth, element.blockHeight);
      ctx.clip();
      ctx.scale(geometry.scaleX, geometry.scaleY);
      ctx.translate(-crop.left, -crop.top);
      // Canvas transforms post-concatenate: this call order makes the raw
      // source see EXIF orientation first, then the block's user flip.
      ctx.translate(geometry.flipTranslateX, geometry.flipTranslateY);
      ctx.scale(geometry.flipScaleX, geometry.flipScaleY);
      ctx.transform(geometry.orientationTransform);
      ctx.drawImage(bitmap, 0, 0, bitmap.width, bitmap.height);
    } finally {
      ctx.restore();
    }
  }
}

export function originalImageOrientationTransform(bitmapWidth: number, bitmapHeight: number,
  orientationDegrees: number, mirroredHorizontally: boolean): TransformMatrix | null {
  if (!Number.isFinite(bitmapWidth) || !Number.isFinite(bitmapHeight) ||
    bitmapWidth <= 0 || bitmapHeight <= 0 || !Number.isFinite(orientationDegrees) ||
    ![0, 90, 180, 270].includes(orientationDegrees)) {
    return null;
  }
  // Equivalent to g3's postScale/postRotate around bitmap.width/height / 2,
  // followed by mapRect compensation that moves the result to (0, 0).
  const mirror: TransformMatrix = mirroredHorizontally ?
    [-1, 0, bitmapWidth, 0, 1, 0, 0, 0, 1] : identityTransform();
  let rotation: TransformMatrix;
  if (orientationDegrees === 90) {
    rotation = [0, -1, bitmapHeight, 1, 0, 0, 0, 0, 1];
  } else if (orientationDegrees === 180) {
    rotation = [-1, 0, bitmapWidth, 0, -1, bitmapHeight, 0, 0, 1];
  } else if (orientationDegrees === 270) {
    rotation = [0, 1, 0, -1, 0, bitmapWidth, 0, 0, 1];
  } else {
    rotation = identityTransform();
  }
  return multiplyTransform(rotation, mirror);
}

function identityTransform(): TransformMatrix {
  return [1, 0, 0, 0, 1, 0, 0, 0, 1];
}

function multiplyTransform(left: TransformMatrix, right: TransformMatrix): TransformMatrix {
  return [
    left[0] * right[0] + left[1] * right[3],
    left[0] * right[1] + left[1] * right[4],
    left[0] * right[2] + left[1] * right[5] + left[2],
    left[3] * right[0] + left[4] * right[3],
    left[3] * right[1] + left[4] * right[4],
    left[3] * right[2] + left[4] * right[5] + left[5],
    0, 0, 1,
  ];
}

function clamp(value: number, minimum: number, maximum: number): number {
  return Math.min(maximum, Math.max(minimum, value));
}
