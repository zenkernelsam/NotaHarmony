import { ElementType, MathElement } from './ElementTypes';
import { Point2D } from './GeometryTypes';
import { mathBlockWorldBounds } from './MathBlockGeometry';

export const ORIGINAL_MATH_INSERT_MAX_WIDTH: number = 240;
export const ORIGINAL_MATH_INSERT_MAX_HEIGHT: number = 120;

export interface OriginalMathMeasuredSize {
  width: number;
  height: number;
  fontSize: number;
}

export function originalMathMeasurementFontSize(boxWidth: number,
  boxHeight: number): number | null {
  if (!Number.isFinite(boxWidth) || !Number.isFinite(boxHeight)) {
    return null;
  }
  const width: number = Math.floor(boxWidth);
  const height: number = Math.floor(boxHeight);
  const fontSize: number = Math.max(width, height);
  return width > 0 && height > 0 && fontSize > 0 ? fontSize : null;
}

// Mirrors s18.d: nativeMeasure is first called with max(floor(width), floor(height))
// as the font size, then the measured layout is proportionally fitted into the box.
export function fitOriginalMathMeasuredSizeToBox(boxWidth: number, boxHeight: number,
  measuredWidth: number, measuredHeight: number): OriginalMathMeasuredSize | null {
  const measurementFontSize: number | null =
    originalMathMeasurementFontSize(boxWidth, boxHeight);
  if (measurementFontSize === null ||
    !Number.isFinite(measuredWidth) || measuredWidth <= 0 ||
    !Number.isFinite(measuredHeight) || measuredHeight <= 0) {
    return null;
  }
  const widthLimit: number = Math.floor(boxWidth);
  const heightLimit: number = Math.floor(boxHeight);
  const scale: number = Math.min(widthLimit / measuredWidth, heightLimit / measuredHeight);
  if (!Number.isFinite(scale) || scale <= 0) {
    return null;
  }
  const fontSize: number = Math.floor(measurementFontSize * scale);
  const width: number = Math.max(1, Math.ceil(measuredWidth * scale));
  const height: number = Math.max(1, Math.ceil(measuredHeight * scale));
  return fontSize > 0 && width <= widthLimit && height <= heightLimit
    ? { width: width, height: height, fontSize: fontSize } : null;
}

export function createOriginalMathInsertDraft(latex: string, viewportCenter: Point2D,
  pageWidth: number, pageHeight: number,
  measuredWidth: number = ORIGINAL_MATH_INSERT_MAX_WIDTH,
  measuredHeight: number = ORIGINAL_MATH_INSERT_MAX_HEIGHT): MathElement | null {
  if (latex.trim().length === 0 || !Number.isFinite(viewportCenter.x) ||
    !Number.isFinite(viewportCenter.y) || !Number.isFinite(pageWidth) || pageWidth <= 0 ||
    !Number.isFinite(pageHeight) || pageHeight <= 0 ||
    viewportCenter.x < 0 || viewportCenter.x > pageWidth ||
    viewportCenter.y < 0 || viewportCenter.y > pageHeight ||
    !Number.isFinite(measuredWidth) || measuredWidth <= 0 ||
    measuredWidth > ORIGINAL_MATH_INSERT_MAX_WIDTH ||
    !Number.isFinite(measuredHeight) || measuredHeight <= 0 ||
    measuredHeight > ORIGINAL_MATH_INSERT_MAX_HEIGHT) {
    return null;
  }
  const originX: number = viewportCenter.x - measuredWidth / 2;
  const originY: number = viewportCenter.y - measuredHeight / 2;
  const draft: MathElement = {
    id: '', type: ElementType.MATH,
    transform: [1, 0, originX, 0, 1, originY, 0, 0, 1],
    bounds: { left: 0, top: 0, right: 0, bottom: 0 },
    latex: latex, color: -16777216,
    blockWidth: measuredWidth, blockHeight: measuredHeight,
    rotationRadians: 0, corner: 0, textWrap: 0,
    enableCaption: false, positionLocked: false,
  };
  draft.bounds = mathBlockWorldBounds(draft);
  return draft;
}
