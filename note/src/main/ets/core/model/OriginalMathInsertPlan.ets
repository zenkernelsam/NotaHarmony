import { ElementType, MathElement } from './ElementTypes';
import { Point2D } from './GeometryTypes';
import { mathBlockWorldBounds } from './MathBlockGeometry';

export const ORIGINAL_MATH_INSERT_MAX_WIDTH: number = 240;
export const ORIGINAL_MATH_INSERT_MAX_HEIGHT: number = 120;

export interface OriginalMathMeasuredSize {
  width: number;
  height: number;
}

export function fitOriginalMathMeasuredSize(measuredWidth: number,
  measuredHeight: number): OriginalMathMeasuredSize | null {
  if (!Number.isFinite(measuredWidth) || measuredWidth <= 0 ||
    !Number.isFinite(measuredHeight) || measuredHeight <= 0) {
    return null;
  }
  const scale: number = Math.min(1, ORIGINAL_MATH_INSERT_MAX_WIDTH / measuredWidth,
    ORIGINAL_MATH_INSERT_MAX_HEIGHT / measuredHeight);
  const width: number = Math.max(1, Math.floor(measuredWidth * scale));
  const height: number = Math.max(1, Math.ceil(measuredHeight * scale));
  return width <= ORIGINAL_MATH_INSERT_MAX_WIDTH && height <= ORIGINAL_MATH_INSERT_MAX_HEIGHT
    ? { width, height } : null;
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
