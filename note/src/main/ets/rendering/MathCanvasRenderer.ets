import { Canvas2DDrawingContext } from '../core/adaptation/Canvas2DStrokeRenderer';
import { MathElement } from '../core/model/ElementTypes';
import { originalMathEngine, OriginalMathBitmap } from './OriginalMathEngine';

interface MathBitmapCacheEntry {
  key: string;
  texture: OriginalMathBitmap;
  bytes: number;
  lastUsed: number;
}

const MIN_RASTER_SCALE: number = 1;
const MAX_RASTER_SCALE: number = 4;
const RASTER_SCALE_STEPS_PER_UNIT: number = 2;
const MAX_CACHE_BYTES: number = 4 * 1024 * 1024;

// Original ue4.v: round(clamp(viewportZoom * density, 1, 4) * 2) / 2.
export function originalMathRasterScale(viewportZoom: number, density: number): number {
  const zoom: number = Math.fround(viewportZoom);
  const pixelsPerVp: number = Math.fround(density);
  if (!Number.isFinite(zoom) || !Number.isFinite(pixelsPerVp) || zoom <= 0 || pixelsPerVp <= 0) {
    return MIN_RASTER_SCALE;
  }
  const physicalScale: number = Math.fround(zoom * pixelsPerVp);
  const clampedScale: number = physicalScale < MIN_RASTER_SCALE ? MIN_RASTER_SCALE :
    (physicalScale > MAX_RASTER_SCALE ? MAX_RASTER_SCALE : physicalScale);
  return Math.round(Math.fround(clampedScale * RASTER_SCALE_STEPS_PER_UNIT)) /
    RASTER_SCALE_STEPS_PER_UNIT;
}

// Mirrors the original w18 cache: parse/layout is native, while the canvas only composites a bitmap.
export class MathCanvasRenderer {
  private cache: MathBitmapCacheEntry[] = [];
  private cacheBytes: number = 0;
  private clock: number = 0;

  renderMath(element: MathElement, ctx: Canvas2DDrawingContext, rasterScale: number): void {
    const pixelScale: number = Math.fround(rasterScale);
    if (element.latex.length === 0 || element.blockWidth <= 0 || element.blockHeight <= 0 ||
      !Number.isFinite(pixelScale) || pixelScale < MIN_RASTER_SCALE || pixelScale > MAX_RASTER_SCALE ||
      !originalMathEngine.isReady()) {
      return;
    }
    const key: string = `${element.latex}\u0000${element.blockWidth}\u0000${element.blockHeight}\u0000` +
      `${element.color}\u0000${pixelScale}`;
    let entry: MathBitmapCacheEntry | undefined = this.cache.find((candidate: MathBitmapCacheEntry): boolean =>
      candidate.key === key);
    let transientTexture: OriginalMathBitmap | null = null;
    if (entry === undefined) {
      const texture: OriginalMathBitmap | null = originalMathEngine.render(
        element.latex, element.blockWidth, element.blockHeight, element.color, pixelScale);
      if (texture === null) return;
      entry = { key, texture, bytes: texture.width * texture.height * 4, lastUsed: ++this.clock };
      if (entry.bytes <= MAX_CACHE_BYTES) {
        this.cache.push(entry);
        this.cacheBytes += entry.bytes;
        this.evictCache();
      } else {
        transientTexture = texture;
      }
    } else {
      entry.lastUsed = ++this.clock;
    }
    ctx.save();
    try {
      ctx.transform(element.transform);
      ctx.drawImage(entry.texture.bitmap, 0, 0, element.blockWidth, element.blockHeight);
    } finally {
      ctx.restore();
      if (transientTexture !== null) {
        this.releaseTexture(transientTexture);
      }
    }
  }

  clear(): void {
    for (const entry of this.cache) {
      this.releaseTexture(entry.texture);
    }
    this.cache = [];
    this.cacheBytes = 0;
  }

  private evictCache(): void {
    while (this.cacheBytes > MAX_CACHE_BYTES && this.cache.length > 0) {
      this.cache.sort((left: MathBitmapCacheEntry, right: MathBitmapCacheEntry): number =>
        left.lastUsed - right.lastUsed);
      const removed: MathBitmapCacheEntry | undefined = this.cache.shift();
      if (removed === undefined) break;
      this.cacheBytes -= removed.bytes;
      this.releaseTexture(removed.texture);
    }
  }

  private releaseTexture(texture: OriginalMathBitmap): void {
    try {
      texture.bitmap.close();
    } catch (_error) { }
    texture.pixelMap.release().catch(() => {});
  }
}
