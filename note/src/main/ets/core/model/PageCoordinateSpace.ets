import { PageInfo } from './NoteTypes';

export const PAGE_UNITS_PER_MM: number = 3.78;
export const MAX_PAGE_CACHE_SIDE: number = 2048;
export const MAX_PAGE_CACHE_PIXELS: number = 2000000;

export interface PagePixelSize {
  width: number;
  height: number;
  pixels: number;
  rgbaBytes: number;
}

export function pagePixelSize(widthMm: number, heightMm: number): PagePixelSize {
  if (!Number.isFinite(widthMm) || !Number.isFinite(heightMm) || widthMm <= 0 || heightMm <= 0) {
    throw new Error(`Invalid page dimensions: ${widthMm}x${heightMm} mm`);
  }
  const width: number = Math.ceil(widthMm * PAGE_UNITS_PER_MM);
  const height: number = Math.ceil(heightMm * PAGE_UNITS_PER_MM);
  if (width > MAX_PAGE_CACHE_SIDE || height > MAX_PAGE_CACHE_SIDE) {
    throw new Error(`Page cache side exceeded: ${width}x${height}`);
  }
  const pixels: number = width * height;
  if (!Number.isSafeInteger(pixels) || pixels > MAX_PAGE_CACHE_PIXELS) {
    throw new Error(`Page cache budget exceeded: ${width}x${height} (${pixels} pixels)`);
  }
  return { width: width, height: height, pixels: pixels, rgbaBytes: pixels * 4 };
}

export function validatePageDimensions(page: PageInfo): void {
  pagePixelSize(page.widthMm, page.heightMm);
}
