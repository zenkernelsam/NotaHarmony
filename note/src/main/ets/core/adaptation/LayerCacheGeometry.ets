import { Rect2D, TransformMatrix } from '../model/GeometryTypes';

export function computeIsolatedLayerBounds(bounds: Rect2D, pageWidth: number, pageHeight: number,
  padding: number = 2): Rect2D {
  if (!Number.isFinite(bounds.left) || !Number.isFinite(bounds.top) ||
    !Number.isFinite(bounds.right) || !Number.isFinite(bounds.bottom)) {
    return { left: 0, top: 0, right: pageWidth, bottom: pageHeight };
  }
  const safePadding: number = Math.max(0, padding);
  return {
    left: Math.max(0, Math.floor(bounds.left - safePadding)),
    top: Math.max(0, Math.floor(bounds.top - safePadding)),
    right: Math.min(pageWidth, Math.ceil(bounds.right + safePadding)),
    bottom: Math.min(pageHeight, Math.ceil(bounds.bottom + safePadding)),
  };
}

export function translateTransformToCrop(transform: TransformMatrix, crop: Rect2D): TransformMatrix {
  const translated: TransformMatrix = transform.slice();
  translated[2] -= crop.left;
  translated[5] -= crop.top;
  return translated;
}
