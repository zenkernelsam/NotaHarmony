import { Rect2D } from '../core/model/GeometryTypes';
import { PageBackgroundMargins } from '../core/model/NoteTypes';
import { POINTS_TO_PAGE_UNITS } from '../core/model/PageBackgroundModel';

export const PDF_RASTER_MAX_SIDE: number = 4096;
export const PDF_RASTER_MAX_PIXELS: number = 8 * 1024 * 1024;
export const PDF_RASTER_OVERSCAN_RATIO: number = 0.25;
const PDF_RASTER_EDGE_PIXELS: number = 1;
const ROTATION_EPSILON: number = 0.0001;
const COVERAGE_EPSILON: number = 0.001;

export interface PdfRasterRequest {
  paperWidth: number;
  paperHeight: number;
  visiblePageRect: Rect2D;
  outputScale: number;
  rotationRadians: number;
  margins: PageBackgroundMargins | null;
  overscanRatio: number;
}

export interface PdfRasterPlan {
  matrixX: number;
  matrixY: number;
  matrixWidth: number;
  matrixHeight: number;
  destinationRect: Rect2D;
  bitmapWidth: number;
  bitmapHeight: number;
  requestedOutputScale: number;
  rasterScale: number;
  pixelCount: number;
}

interface PdfRasterSize {
  bitmapWidth: number;
  bitmapHeight: number;
  rasterScale: number;
  pixelCount: number;
}

// The original iy9/sba path allocates only the union of requested page regions,
// then converts the top-origin document rectangle to PDF's bottom-origin clip box.
// Keep background rotation outside PDFKit: PdfMatrix.rotate always stays zero and
// the existing Canvas transform owns the four cardinal page rotations.
export function buildPdfRasterPlan(request: PdfRasterRequest,
  pdfPageWidthPt: number, pdfPageHeightPt: number): PdfRasterPlan | null {
  validateRequest(request);
  if (!Number.isFinite(pdfPageWidthPt) || !Number.isFinite(pdfPageHeightPt) ||
    pdfPageWidthPt <= 0 || pdfPageHeightPt <= 0) {
    throw new Error('PDF page dimensions are invalid');
  }
  const visible: Rect2D | null = expandedVisiblePageRect(request);
  if (visible === null) {
    return null;
  }
  const localVisible: Rect2D = paperToUnrotatedLocalRect(
    visible, request.paperWidth, request.paperHeight, request.rotationRadians);
  const content: Rect2D = pdfContentRect(request);
  const destination: Rect2D | null = intersectRect(localVisible, content);
  if (destination === null) {
    return null;
  }
  const contentWidth: number = content.right - content.left;
  const contentHeight: number = content.bottom - content.top;
  const destinationWidth: number = destination.right - destination.left;
  const destinationHeight: number = destination.bottom - destination.top;
  const normalizedLeft: number = (destination.left - content.left) / contentWidth;
  const normalizedRight: number = (destination.right - content.left) / contentWidth;
  const normalizedTop: number = (destination.top - content.top) / contentHeight;
  const normalizedBottom: number = (destination.bottom - content.top) / contentHeight;
  const matrixX: number = clamp(normalizedLeft * pdfPageWidthPt, 0, pdfPageWidthPt);
  const matrixRight: number = clamp(normalizedRight * pdfPageWidthPt, 0, pdfPageWidthPt);
  // PDFKit documents y as the distance from the page bottom. Canvas/page space is
  // top-origin, so the destination bottom becomes the PDF matrix's y coordinate.
  const matrixY: number = clamp((1 - normalizedBottom) * pdfPageHeightPt, 0, pdfPageHeightPt);
  const matrixTop: number = clamp((1 - normalizedTop) * pdfPageHeightPt, 0, pdfPageHeightPt);
  const matrixWidth: number = matrixRight - matrixX;
  const matrixHeight: number = matrixTop - matrixY;
  if (matrixWidth <= 0 || matrixHeight <= 0) {
    return null;
  }
  const rasterSize: PdfRasterSize = boundedRasterSize(
    destinationWidth, destinationHeight, request.outputScale);
  return {
    matrixX: matrixX,
    matrixY: matrixY,
    matrixWidth: matrixWidth,
    matrixHeight: matrixHeight,
    destinationRect: destination,
    bitmapWidth: rasterSize.bitmapWidth,
    bitmapHeight: rasterSize.bitmapHeight,
    requestedOutputScale: request.outputScale,
    rasterScale: rasterSize.rasterScale,
    pixelCount: rasterSize.pixelCount,
  };
}

export function pdfRasterPlanCovers(plan: PdfRasterPlan | null,
  request: PdfRasterRequest): boolean {
  validateRequest(request);
  const visible: Rect2D | null = clippedVisiblePageRect(request);
  if (visible === null) {
    return true;
  }
  const localVisible: Rect2D = paperToUnrotatedLocalRect(
    visible, request.paperWidth, request.paperHeight, request.rotationRadians);
  const required: Rect2D | null = intersectRect(localVisible, pdfContentRect(request));
  if (required === null) {
    return true;
  }
  const nextDestination: Rect2D | null = rasterDestinationRect(request);
  if (nextDestination === null) {
    return true;
  }
  const nextRasterScale: number = boundedRasterSize(
    nextDestination.right - nextDestination.left,
    nextDestination.bottom - nextDestination.top,
    request.outputScale).rasterScale;
  // Compare the actual budget-bounded scale, not merely the requested scale.
  // A full-page overview can be capped by the pixel budget; after zooming into a
  // smaller covered region, reraster so that the newly affordable detail is not
  // stuck at the overview's lower resolution. Computing the next bounded scale
  // also prevents a refresh loop when the current request itself hits the cap.
  if (plan === null || plan.rasterScale + COVERAGE_EPSILON < nextRasterScale) {
    return false;
  }
  return plan.destinationRect.left <= required.left + COVERAGE_EPSILON &&
    plan.destinationRect.top <= required.top + COVERAGE_EPSILON &&
    plan.destinationRect.right >= required.right - COVERAGE_EPSILON &&
    plan.destinationRect.bottom >= required.bottom - COVERAGE_EPSILON;
}

function rasterDestinationRect(request: PdfRasterRequest): Rect2D | null {
  const expanded: Rect2D | null = expandedVisiblePageRect(request);
  if (expanded === null) {
    return null;
  }
  const localExpanded: Rect2D = paperToUnrotatedLocalRect(
    expanded, request.paperWidth, request.paperHeight, request.rotationRadians);
  return intersectRect(localExpanded, pdfContentRect(request));
}

function validateRequest(request: PdfRasterRequest): void {
  if (!Number.isFinite(request.paperWidth) || !Number.isFinite(request.paperHeight) ||
    request.paperWidth <= 0 || request.paperHeight <= 0 ||
    !finiteRect(request.visiblePageRect) || !Number.isFinite(request.outputScale) ||
    request.outputScale <= 0 || !Number.isFinite(request.overscanRatio) ||
    request.overscanRatio < 0 || request.overscanRatio > 1 ||
    !validMargins(request.margins) ||
    cardinalQuarterTurns(request.rotationRadians) < 0) {
    throw new Error('PDF raster request is invalid');
  }
}

function clippedVisiblePageRect(request: PdfRasterRequest): Rect2D | null {
  return intersectRect(request.visiblePageRect, {
    left: 0, top: 0, right: request.paperWidth, bottom: request.paperHeight,
  });
}

function expandedVisiblePageRect(request: PdfRasterRequest): Rect2D | null {
  const visible: Rect2D | null = clippedVisiblePageRect(request);
  if (visible === null) {
    return null;
  }
  const width: number = visible.right - visible.left;
  const height: number = visible.bottom - visible.top;
  const edge: number = PDF_RASTER_EDGE_PIXELS / request.outputScale;
  const expandX: number = width * request.overscanRatio + edge;
  const expandY: number = height * request.overscanRatio + edge;
  return {
    left: Math.max(0, visible.left - expandX),
    top: Math.max(0, visible.top - expandY),
    right: Math.min(request.paperWidth, visible.right + expandX),
    bottom: Math.min(request.paperHeight, visible.bottom + expandY),
  };
}

function pdfContentRect(request: PdfRasterRequest): Rect2D {
  const quarterTurns: number = cardinalQuarterTurns(request.rotationRadians);
  const quarterTurn: boolean = quarterTurns === 1 || quarterTurns === 3;
  const localWidth: number = quarterTurn ? request.paperHeight : request.paperWidth;
  const localHeight: number = quarterTurn ? request.paperWidth : request.paperHeight;
  const margins: PageBackgroundMargins | null = request.margins;
  const left: number = margins === null ? 0 : margins.leftPt * POINTS_TO_PAGE_UNITS;
  const top: number = margins === null ? 0 : margins.topPt * POINTS_TO_PAGE_UNITS;
  const right: number = margins === null ? 0 : margins.rightPt * POINTS_TO_PAGE_UNITS;
  const bottom: number = margins === null ? 0 : margins.bottomPt * POINTS_TO_PAGE_UNITS;
  const content: Rect2D = {
    left: clamp(left, 0, localWidth),
    top: clamp(top, 0, localHeight),
    right: clamp(localWidth - right, 0, localWidth),
    bottom: clamp(localHeight - bottom, 0, localHeight),
  };
  if (content.left > content.right || content.top > content.bottom) {
    throw new Error('PDF background margins leave no renderable content');
  }
  return content;
}

function validMargins(value: PageBackgroundMargins | null): boolean {
  return value === null ||
    (Number.isFinite(value.topPt) && value.topPt >= 0 &&
      Number.isFinite(value.bottomPt) && value.bottomPt >= 0 &&
      Number.isFinite(value.leftPt) && value.leftPt >= 0 &&
      Number.isFinite(value.rightPt) && value.rightPt >= 0);
}

function paperToUnrotatedLocalRect(rect: Rect2D, paperWidth: number, paperHeight: number,
  rotationRadians: number): Rect2D {
  switch (cardinalQuarterTurns(rotationRadians)) {
    case 0:
      return cloneRect(rect);
    case 1:
      return {
        left: rect.top,
        top: paperWidth - rect.right,
        right: rect.bottom,
        bottom: paperWidth - rect.left,
      };
    case 2:
      return {
        left: paperWidth - rect.right,
        top: paperHeight - rect.bottom,
        right: paperWidth - rect.left,
        bottom: paperHeight - rect.top,
      };
    case 3:
      return {
        left: paperHeight - rect.bottom,
        top: rect.left,
        right: paperHeight - rect.top,
        bottom: rect.right,
      };
    default:
      throw new Error('PDF background rotation is not cardinal');
  }
}

function boundedRasterScale(width: number, height: number, requested: number): number {
  const sideScale: number = Math.min(PDF_RASTER_MAX_SIDE / width, PDF_RASTER_MAX_SIDE / height);
  const pixelScale: number = Math.sqrt(PDF_RASTER_MAX_PIXELS / (width * height));
  const bounded: number = Math.min(requested, sideScale, pixelScale);
  if (!Number.isFinite(bounded) || bounded <= 0) {
    throw new Error('PDF raster scale is invalid');
  }
  return bounded;
}

function boundedRasterSize(width: number, height: number, requested: number): PdfRasterSize {
  const maximumScale: number = boundedRasterScale(width, height, requested);
  let rasterScale: number = maximumScale;
  let bitmapWidth: number = roundedRasterDimension(width, rasterScale);
  let bitmapHeight: number = roundedRasterDimension(height, rasterScale);
  if (!rasterSizeFitsBudget(bitmapWidth, bitmapHeight)) {
    // The original uses positive Math.round. At the theoretical pixel cap,
    // independently rounding both dimensions can exceed the product budget by
    // a few pixels, so converge to the greatest scale whose rounded dimensions
    // still fit rather than changing the original rounding rule to floor.
    let lower: number = 0;
    let upper: number = maximumScale;
    for (let i: number = 0; i < 48; i++) {
      const middle: number = (lower + upper) / 2;
      const middleWidth: number = roundedRasterDimension(width, middle);
      const middleHeight: number = roundedRasterDimension(height, middle);
      if (rasterSizeFitsBudget(middleWidth, middleHeight)) {
        lower = middle;
      } else {
        upper = middle;
      }
    }
    rasterScale = lower;
    bitmapWidth = roundedRasterDimension(width, rasterScale);
    bitmapHeight = roundedRasterDimension(height, rasterScale);
  }
  const pixelCount: number = bitmapWidth * bitmapHeight;
  if (!Number.isFinite(rasterScale) || rasterScale <= 0 ||
    !rasterSizeFitsBudget(bitmapWidth, bitmapHeight) || !Number.isSafeInteger(pixelCount)) {
    throw new Error('PDF raster budget calculation failed');
  }
  return {
    bitmapWidth: bitmapWidth,
    bitmapHeight: bitmapHeight,
    rasterScale: rasterScale,
    pixelCount: pixelCount,
  };
}

function roundedRasterDimension(logicalSize: number, scale: number): number {
  return Math.max(1, Math.round(logicalSize * scale));
}

function rasterSizeFitsBudget(width: number, height: number): boolean {
  const pixelCount: number = width * height;
  return Number.isSafeInteger(width) && Number.isSafeInteger(height) &&
    width >= 1 && height >= 1 && width <= PDF_RASTER_MAX_SIDE &&
    height <= PDF_RASTER_MAX_SIDE && Number.isSafeInteger(pixelCount) &&
    pixelCount <= PDF_RASTER_MAX_PIXELS;
}

function cardinalQuarterTurns(rotationRadians: number): number {
  if (!Number.isFinite(rotationRadians)) {
    return -1;
  }
  if (near(rotationRadians, 0)) {
    return 0;
  }
  if (near(rotationRadians, Math.PI / 2)) {
    return 1;
  }
  if (near(rotationRadians, Math.PI)) {
    return 2;
  }
  return near(rotationRadians, Math.PI * 3 / 2) ? 3 : -1;
}

function intersectRect(left: Rect2D, right: Rect2D): Rect2D | null {
  const result: Rect2D = {
    left: Math.max(left.left, right.left),
    top: Math.max(left.top, right.top),
    right: Math.min(left.right, right.right),
    bottom: Math.min(left.bottom, right.bottom),
  };
  return result.left < result.right && result.top < result.bottom ? result : null;
}

function finiteRect(rect: Rect2D): boolean {
  return Number.isFinite(rect.left) && Number.isFinite(rect.top) &&
    Number.isFinite(rect.right) && Number.isFinite(rect.bottom) &&
    rect.left < rect.right && rect.top < rect.bottom;
}

function cloneRect(rect: Rect2D): Rect2D {
  return { left: rect.left, top: rect.top, right: rect.right, bottom: rect.bottom };
}

function clamp(value: number, minimum: number, maximum: number): number {
  return Math.max(minimum, Math.min(maximum, value));
}

function near(left: number, right: number): boolean {
  return Math.abs(left - right) < ROTATION_EPSILON;
}
