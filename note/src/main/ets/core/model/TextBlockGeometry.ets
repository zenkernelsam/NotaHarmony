import {
  RichTextCharacterStyle, RichTextCharacterStyleRun, RichTextParagraphStyle,
  RichTextParagraphStyleRun, TextBlockElement,
} from './ElementTypes';
import { Point2D, Rect2D, TransformMatrix } from './GeometryTypes';
import { cloneOriginalPaper } from './PageBackgroundModel';
import {
  eraserPathHitsAffineBlock, pointHitsAffineBlock, selectionPathHitsAffineBlock,
} from './BlockHitGeometry';

export interface TextBlockTransformComponents {
  origin: Point2D;
  rotationRadians: number;
  scaleX: number;
  scaleY: number;
}

export function cloneTextBlockElement(element: TextBlockElement): TextBlockElement {
  return {
    id: element.id, type: element.type, transform: element.transform.slice(),
    bounds: cloneRect(element.bounds), richText: element.richText,
    textOrigin: clonePoint(element.textOrigin), blockWidth: element.blockWidth,
    blockHeight: element.blockHeight, rotationRadians: element.rotationRadians,
    contentLeftInset: element.contentLeftInset, contentTopInset: element.contentTopInset,
    contentRightInset: element.contentRightInset,
    contentBottomInset: element.contentBottomInset,
    fontSize: element.fontSize, fontColor: element.fontColor,
    corner: element.corner, textWrap: element.textWrap,
    enableCaption: element.enableCaption,
    paper: cloneOriginalPaper(element.paper === undefined ? null : element.paper),
    resizesWidthToFitText: element.resizesWidthToFitText,
    characterStyleRuns: cloneCharacterStyleRuns(element.characterStyleRuns),
    paragraphStyleRuns: cloneParagraphStyleRuns(element.paragraphStyleRuns),
    positionLocked: isTextBlockPositionLocked(element),
    originalCreate: element.originalCreate === undefined ? undefined : {
      timestamp: element.originalCreate.timestamp, siteId: element.originalCreate.siteId,
      clientTime: element.originalCreate.clientTime,
      pageTimestamp: element.originalCreate.pageTimestamp,
      pageSiteId: element.originalCreate.pageSiteId, pageIndex: element.originalCreate.pageIndex,
      pencilSeed: element.originalCreate.pencilSeed,
    },
  };
}

export function cloneCharacterStyleRuns(runs: RichTextCharacterStyleRun[] | undefined):
  RichTextCharacterStyleRun[] | undefined {
  if (runs === undefined) {
    return undefined;
  }
  return runs.map((run: RichTextCharacterStyleRun): RichTextCharacterStyleRun => {
    const style: RichTextCharacterStyle = JSON.parse(JSON.stringify(run.style)) as
      RichTextCharacterStyle;
    return { start: run.start, end: run.end, style: style };
  });
}

export function cloneParagraphStyleRuns(runs: RichTextParagraphStyleRun[] | undefined):
  RichTextParagraphStyleRun[] | undefined {
  if (runs === undefined) {
    return undefined;
  }
  return runs.map((run: RichTextParagraphStyleRun): RichTextParagraphStyleRun => {
    const style: RichTextParagraphStyle = JSON.parse(JSON.stringify(run.style)) as
      RichTextParagraphStyle;
    return { start: run.start, end: run.end, style: style };
  });
}

export function isTextBlockPositionLocked(element: TextBlockElement): boolean {
  return element.positionLocked === true;
}

export function textBlockLocalBounds(element: TextBlockElement): Rect2D {
  return {
    left: element.textOrigin.x,
    top: element.textOrigin.y,
    right: element.textOrigin.x + element.blockWidth,
    bottom: element.textOrigin.y + element.blockHeight,
  };
}

export function textBlockWorldCorners(element: TextBlockElement): Point2D[] {
  const local: Rect2D = textBlockLocalBounds(element);
  return [
    transformPoint({ x: local.left, y: local.top }, element.transform),
    transformPoint({ x: local.right, y: local.top }, element.transform),
    transformPoint({ x: local.right, y: local.bottom }, element.transform),
    transformPoint({ x: local.left, y: local.bottom }, element.transform),
  ];
}

export function textBlockWorldBounds(element: TextBlockElement): Rect2D {
  return pointsBounds(textBlockWorldCorners(element));
}

export function textBlockTransformComponents(element: TextBlockElement): TextBlockTransformComponents {
  const matrix: TransformMatrix = element.transform;
  const scaleX: number = Math.sqrt(matrix[0] * matrix[0] + matrix[3] * matrix[3]);
  const determinant: number = matrix[0] * matrix[4] - matrix[1] * matrix[3];
  const scaleY: number = scaleX > 0.0000001
    ? determinant / scaleX : Math.sqrt(matrix[1] * matrix[1] + matrix[4] * matrix[4]);
  return {
    origin: transformPoint(element.textOrigin, matrix),
    rotationRadians: scaleX > 0.0000001 ? Math.atan2(matrix[3], matrix[0]) : 0,
    scaleX: scaleX,
    scaleY: scaleY,
  };
}

export function transformTextBlockElements(elements: TextBlockElement[], selectedIds: string[],
  transform: TransformMatrix): TextBlockElement[] {
  const selected: Set<string> = new Set<string>(selectedIds);
  const result: TextBlockElement[] = [];
  for (const element of elements) {
    if (!selected.has(element.id)) {
      result.push(element);
      continue;
    }
    if (isTextBlockPositionLocked(element)) {
      result.push(element);
      continue;
    }
    const updated: TextBlockElement = cloneTextBlockElement(element);
    updated.transform = multiplyTransform(transform, element.transform);
    updated.rotationRadians = Math.atan2(updated.transform[3], updated.transform[0]);
    updated.bounds = textBlockWorldBounds(updated);
    result.push(updated);
  }
  return result;
}

export function pointHitsTextBlock(point: Point2D, element: TextBlockElement): boolean {
  return !isTextBlockPositionLocked(element) &&
    pointHitsAffineBlock(point, textBlockLocalBounds(element), element.transform);
}

export function selectionPathHitsTextBlock(selectionPath: Point2D[],
  element: TextBlockElement): boolean {
  return selectionPathHitsAffineBlock(
    selectionPath, textBlockLocalBounds(element), element.transform);
}

export function eraserPathHitsTextBlock(eraserPath: Point2D[], element: TextBlockElement,
  eraserWidth: number): boolean {
  if (eraserPath.length === 0 || isTextBlockPositionLocked(element)) {
    return false;
  }
  return eraserPathHitsAffineBlock(
    eraserPath, textBlockLocalBounds(element), element.transform, eraserWidth);
}

function multiplyTransform(a: TransformMatrix, b: TransformMatrix): TransformMatrix {
  const result: TransformMatrix = [0, 0, 0, 0, 0, 0, 0, 0, 1];
  for (let row: number = 0; row < 3; row++) {
    for (let col: number = 0; col < 3; col++) {
      let sum: number = 0;
      for (let k: number = 0; k < 3; k++) {
        sum += a[row * 3 + k] * b[k * 3 + col];
      }
      result[row * 3 + col] = sum;
    }
  }
  return result;
}

function transformPoint(point: Point2D, matrix: TransformMatrix): Point2D {
  return {
    x: matrix[0] * point.x + matrix[1] * point.y + matrix[2],
    y: matrix[3] * point.x + matrix[4] * point.y + matrix[5],
  };
}

function pointsBounds(points: Point2D[]): Rect2D {
  let left: number = points[0].x;
  let top: number = points[0].y;
  let right: number = points[0].x;
  let bottom: number = points[0].y;
  for (let i: number = 1; i < points.length; i++) {
    left = Math.min(left, points[i].x);
    top = Math.min(top, points[i].y);
    right = Math.max(right, points[i].x);
    bottom = Math.max(bottom, points[i].y);
  }
  return { left: left, top: top, right: right, bottom: bottom };
}

function clonePoint(point: Point2D): Point2D {
  return { x: point.x, y: point.y };
}

function cloneRect(rect: Rect2D): Rect2D {
  return { left: rect.left, top: rect.top, right: rect.right, bottom: rect.bottom };
}
