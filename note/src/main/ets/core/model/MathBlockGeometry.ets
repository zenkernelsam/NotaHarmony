import { MathElement } from './ElementTypes';
import { Point2D, Rect2D, TransformMatrix } from './GeometryTypes';
import { eraserPathHitsAffineBlock, selectionPathHitsAffineBlock } from './BlockHitGeometry';

export function cloneMathElement(element: MathElement): MathElement {
  return {
    id: element.id,
    type: element.type,
    transform: element.transform.slice(),
    bounds: cloneRect(element.bounds),
    latex: element.latex,
    color: element.color,
    blockWidth: element.blockWidth,
    blockHeight: element.blockHeight,
    rotationRadians: element.rotationRadians,
    corner: element.corner,
    textWrap: element.textWrap,
    enableCaption: element.enableCaption,
    positionLocked: element.positionLocked,
  };
}

export function mathBlockWorldBounds(element: MathElement): Rect2D {
  const corners: Point2D[] = [
    transformPoint(0, 0, element),
    transformPoint(element.blockWidth, 0, element),
    transformPoint(element.blockWidth, element.blockHeight, element),
    transformPoint(0, element.blockHeight, element),
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

export function isMathBlockPositionLocked(element: MathElement): boolean {
  return element.positionLocked === true;
}

export function mathBlockLocalBounds(element: MathElement): Rect2D {
  return { left: 0, top: 0, right: element.blockWidth, bottom: element.blockHeight };
}

export function transformMathElements(elements: MathElement[], selectedIds: string[],
  transform: TransformMatrix): MathElement[] {
  const selected: Set<string> = new Set<string>(selectedIds);
  const result: MathElement[] = [];
  for (const element of elements) {
    if (!selected.has(element.id) || isMathBlockPositionLocked(element)) {
      result.push(element);
      continue;
    }
    const updated: MathElement = cloneMathElement(element);
    updated.transform = multiplyTransform(transform, element.transform);
    updated.rotationRadians = Math.atan2(updated.transform[3], updated.transform[0]);
    updated.bounds = mathBlockWorldBounds(updated);
    result.push(updated);
  }
  return result;
}

export function eraserPathHitsMathBlock(eraserPath: Point2D[], element: MathElement,
  eraserWidth: number): boolean {
  if (eraserPath.length === 0 || isMathBlockPositionLocked(element)) {
    return false;
  }
  return eraserPathHitsAffineBlock(
    eraserPath, mathBlockLocalBounds(element), element.transform, eraserWidth);
}

export function selectionPathHitsMathBlock(selectionPath: Point2D[],
  element: MathElement): boolean {
  return selectionPathHitsAffineBlock(
    selectionPath, mathBlockLocalBounds(element), element.transform);
}

function multiplyTransform(a: TransformMatrix, b: TransformMatrix): TransformMatrix {
  return [
    a[0] * b[0] + a[1] * b[3], a[0] * b[1] + a[1] * b[4],
    a[0] * b[2] + a[1] * b[5] + a[2],
    a[3] * b[0] + a[4] * b[3], a[3] * b[1] + a[4] * b[4],
    a[3] * b[2] + a[4] * b[5] + a[5],
    0, 0, 1,
  ];
}

function transformPoint(x: number, y: number, element: MathElement): Point2D {
  return {
    x: element.transform[0] * x + element.transform[1] * y + element.transform[2],
    y: element.transform[3] * x + element.transform[4] * y + element.transform[5],
  };
}

function cloneRect(rect: Rect2D): Rect2D {
  return { left: rect.left, top: rect.top, right: rect.right, bottom: rect.bottom };
}
