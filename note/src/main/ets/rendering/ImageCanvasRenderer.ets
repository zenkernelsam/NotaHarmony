import { ImageElement } from '../core/model/ElementTypes';
import { Rect2D } from '../core/model/GeometryTypes';
import { Canvas2DDrawingContext } from '../core/adaptation/Canvas2DStrokeRenderer';

export interface ImageRenderGeometry {
  cropPixels: Rect2D;
  scaleX: number;
  scaleY: number;
  flipTranslateX: number;
  flipTranslateY: number;
  flipScaleX: number;
  flipScaleY: number;
}

export function imageRenderGeometry(element: ImageElement,
  bitmapWidth: number, bitmapHeight: number): ImageRenderGeometry | null {
  if (!Number.isFinite(bitmapWidth) || !Number.isFinite(bitmapHeight) || bitmapWidth <= 0 || bitmapHeight <= 0 ||
    !Number.isFinite(element.blockWidth) || !Number.isFinite(element.blockHeight) ||
    element.blockWidth <= 0 || element.blockHeight <= 0) {
    return null;
  }
  const intrinsicWidth: number = element.intrinsicWidth > 0 ? element.intrinsicWidth : bitmapWidth;
  const intrinsicHeight: number = element.intrinsicHeight > 0 ? element.intrinsicHeight : bitmapHeight;
  const pixelScaleX: number = bitmapWidth / intrinsicWidth;
  const pixelScaleY: number = bitmapHeight / intrinsicHeight;
  const source: Rect2D = element.cropRect === null ?
    { left: 0, top: 0, right: intrinsicWidth, bottom: intrinsicHeight } : element.cropRect;
  const cropPixels: Rect2D = {
    left: clamp(source.left * pixelScaleX, 0, bitmapWidth),
    top: clamp(source.top * pixelScaleY, 0, bitmapHeight),
    right: clamp(source.right * pixelScaleX, 0, bitmapWidth),
    bottom: clamp(source.bottom * pixelScaleY, 0, bitmapHeight),
  };
  const cropWidth: number = cropPixels.right - cropPixels.left;
  const cropHeight: number = cropPixels.bottom - cropPixels.top;
  if (cropWidth <= 0 || cropHeight <= 0) {
    return null;
  }
  return {
    cropPixels: cropPixels,
    scaleX: element.blockWidth / cropWidth,
    scaleY: element.blockHeight / cropHeight,
    flipTranslateX: element.imageFlippedHorizontally ? bitmapWidth : 0,
    flipTranslateY: element.imageFlippedVertically ? bitmapHeight : 0,
    flipScaleX: element.imageFlippedHorizontally ? -1 : 1,
    flipScaleY: element.imageFlippedVertically ? -1 : 1,
  };
}

export class ImageCanvasRenderer {
  renderImage(element: ImageElement, bitmap: ImageBitmap, ctx: Canvas2DDrawingContext): void {
    const geometry: ImageRenderGeometry | null = imageRenderGeometry(element, bitmap.width, bitmap.height);
    if (geometry === null) {
      return;
    }
    const crop: Rect2D = geometry.cropPixels;
    ctx.save();
    ctx.transform(element.transform);
    ctx.scale(geometry.scaleX, geometry.scaleY);
    ctx.translate(-crop.left, -crop.top);
    ctx.beginPath();
    ctx.rect(crop.left, crop.top, crop.right - crop.left, crop.bottom - crop.top);
    ctx.clip();
    ctx.translate(geometry.flipTranslateX, geometry.flipTranslateY);
    ctx.scale(geometry.flipScaleX, geometry.flipScaleY);
    ctx.drawImage(bitmap, 0, 0, bitmap.width, bitmap.height);
    ctx.restore();
  }
}

function clamp(value: number, minimum: number, maximum: number): number {
  return Math.min(maximum, Math.max(minimum, value));
}
