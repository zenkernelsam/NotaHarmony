import { Rect2D } from '../model/GeometryTypes';
import { PencilSplatPoint } from '../model/StrokeTypes';

export const ORIGINAL_PENCIL_TEXTURE_SIZE: number = 1024;
export const PENCIL_SPLAT_BOUND_FACTOR: number = Math.SQRT2;

export function originalPencilAlpha(alpha: number): number {
  if (alpha <= 0) {
    return 0;
  }
  if (alpha >= 255) {
    return 255;
  }
  return Math.floor(Math.pow(alpha / 255, 1.5) * 255);
}

export function applyOriginalPencilAlphaCurve(rgba: Uint8Array, width: number,
  height: number, rowStride: number): void {
  if (width <= 0 || height <= 0 || rowStride < width * 4 || rgba.length < rowStride * height) {
    throw new Error(`Invalid RGBA texture layout: ${width}x${height}, stride=${rowStride}, bytes=${rgba.length}`);
  }
  for (let y: number = 0; y < height; y++) {
    const rowStart: number = y * rowStride;
    for (let x: number = 0; x < width; x++) {
      const alphaOffset: number = rowStart + x * 4 + 3;
      rgba[alphaOffset] = originalPencilAlpha(rgba[alphaOffset]);
    }
  }
}

export function pencilSplatExtent(scale: number): number {
  return Math.max(scale, 0) * PENCIL_SPLAT_BOUND_FACTOR;
}

export function computePencilSplatBounds(splats: PencilSplatPoint[], padding: number = 0): Rect2D | null {
  if (splats.length === 0) {
    return null;
  }
  const safePadding: number = Math.max(padding, 0);
  const firstExtent: number = pencilSplatExtent(splats[0].scale) + safePadding;
  let left: number = splats[0].x - firstExtent;
  let top: number = splats[0].y - firstExtent;
  let right: number = splats[0].x + firstExtent;
  let bottom: number = splats[0].y + firstExtent;
  for (let i: number = 1; i < splats.length; i++) {
    const splat: PencilSplatPoint = splats[i];
    const extent: number = pencilSplatExtent(splat.scale) + safePadding;
    left = Math.min(left, splat.x - extent);
    top = Math.min(top, splat.y - extent);
    right = Math.max(right, splat.x + extent);
    bottom = Math.max(bottom, splat.y + extent);
  }
  return { left: left, top: top, right: right, bottom: bottom };
}
