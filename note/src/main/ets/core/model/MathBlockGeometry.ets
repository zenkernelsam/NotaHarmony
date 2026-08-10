import { MathElement } from './ElementTypes';
import { Point2D, Rect2D } from './GeometryTypes';

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

function transformPoint(x: number, y: number, element: MathElement): Point2D {
  return {
    x: element.transform[0] * x + element.transform[1] * y + element.transform[2],
    y: element.transform[3] * x + element.transform[4] * y + element.transform[5],
  };
}

function cloneRect(rect: Rect2D): Rect2D {
  return { left: rect.left, top: rect.top, right: rect.right, bottom: rect.bottom };
}
