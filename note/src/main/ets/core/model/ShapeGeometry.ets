import { ElementType, EllipseElement, LineElement, PolygonElement,
  OriginalShapeCreateMetadata,
  RichTextCharacterStyle, RichTextCharacterStyleRun,
  RichTextParagraphStyle, RichTextParagraphStyleRun,
  ShapeArrowHead, ShapeElement } from './ElementTypes';
import { Point2D, Rect2D, TransformMatrix } from './GeometryTypes';

const ELLIPSE_HIT_SEGMENTS: number = 64;
const CURVE_HIT_SEGMENTS: number = 64;

export interface LineRenderGeometry {
  mainPath: Point2D[];
  arrowHeadPath: Point2D[];
  // Parameter on the original line/quad/cubic where PathMeasure-style arrow trimming ends.
  // Consumers that can preserve native verbs use this instead of redrawing the sampled polyline.
  mainPathEndParameter: number;
}

interface TrimmedPolyline {
  points: Point2D[];
  endParameter: number;
}

export function cloneShapeElement(shape: ShapeElement): ShapeElement {
  if (shape.type === ElementType.ELLIPSE) {
    return {
      id: shape.id, type: ElementType.ELLIPSE, transform: shape.transform.slice(),
      bounds: cloneRect(shape.bounds), center: clonePoint(shape.center),
      radiusX: shape.radiusX, radiusY: shape.radiusY, rotationRadians: shape.rotationRadians,
      color: shape.color, strokeWidth: shape.strokeWidth, fillColor: shape.fillColor,
      richText: shape.richText, characterStyleRuns: cloneShapeCharacterRuns(shape),
      paragraphStyleRuns: cloneShapeParagraphRuns(shape), positionLocked: shape.positionLocked,
      originalTool: shape.originalTool, originalStyle: shape.originalStyle,
      originalTapePattern: shape.originalTapePattern,
      originalSmartHighlight: shape.originalSmartHighlight,
      originalForce: shape.originalForce,
      originalInkEffects: shape.originalInkEffects,
      originalInkEffectsTinted: shape.originalInkEffectsTinted,
      originalCreate: cloneOriginalShapeCreate(shape),
    };
  }
  if (shape.type === ElementType.LINE) {
    return {
      id: shape.id, type: ElementType.LINE, transform: shape.transform.slice(),
      bounds: cloneRect(shape.bounds), start: clonePoint(shape.start),
      controlPoint1: cloneNullablePoint(shape.controlPoint1),
      controlPoint2: cloneNullablePoint(shape.controlPoint2), end: clonePoint(shape.end),
      arrowHead: shape.arrowHead, color: shape.color, strokeWidth: shape.strokeWidth,
      fillColor: shape.fillColor, richText: shape.richText,
      characterStyleRuns: cloneShapeCharacterRuns(shape),
      paragraphStyleRuns: cloneShapeParagraphRuns(shape), positionLocked: shape.positionLocked,
      originalTool: shape.originalTool, originalStyle: shape.originalStyle,
      originalTapePattern: shape.originalTapePattern,
      originalSmartHighlight: shape.originalSmartHighlight,
      originalForce: shape.originalForce,
      originalInkEffects: shape.originalInkEffects,
      originalInkEffectsTinted: shape.originalInkEffectsTinted,
      originalCreate: cloneOriginalShapeCreate(shape),
    };
  }
  return {
    id: shape.id, type: ElementType.POLYGON, transform: shape.transform.slice(),
    bounds: cloneRect(shape.bounds),
    vertices: shape.vertices.map((point: Point2D): Point2D => clonePoint(point)),
    isClosed: shape.isClosed, color: shape.color, strokeWidth: shape.strokeWidth,
    fillColor: shape.fillColor, richText: shape.richText,
    characterStyleRuns: cloneShapeCharacterRuns(shape),
    paragraphStyleRuns: cloneShapeParagraphRuns(shape), positionLocked: shape.positionLocked,
    originalTool: shape.originalTool, originalStyle: shape.originalStyle,
    originalTapePattern: shape.originalTapePattern,
    originalSmartHighlight: shape.originalSmartHighlight,
    originalForce: shape.originalForce,
    originalInkEffects: shape.originalInkEffects,
    originalInkEffectsTinted: shape.originalInkEffectsTinted,
    originalCreate: cloneOriginalShapeCreate(shape),
  };
}

function cloneOriginalShapeCreate(shape: ShapeElement): OriginalShapeCreateMetadata | undefined {
  if (shape.originalCreate === undefined) {
    return undefined;
  }
  return {
    timestamp: shape.originalCreate.timestamp, siteId: shape.originalCreate.siteId,
    clientTime: shape.originalCreate.clientTime,
    pageTimestamp: shape.originalCreate.pageTimestamp,
    pageSiteId: shape.originalCreate.pageSiteId, pageIndex: shape.originalCreate.pageIndex,
    pencilSeed: shape.originalCreate.pencilSeed,
    averageForce: shape.originalCreate.averageForce,
  };
}

export function cloneShapeCharacterRuns(shape: ShapeElement):
  RichTextCharacterStyleRun[] | undefined {
  if (shape.characterStyleRuns === undefined) {
    return undefined;
  }
  return shape.characterStyleRuns.map((run: RichTextCharacterStyleRun):
    RichTextCharacterStyleRun => {
    const style: RichTextCharacterStyle = JSON.parse(JSON.stringify(run.style)) as
      RichTextCharacterStyle;
    return { start: run.start, end: run.end, style: style };
  });
}

export function cloneShapeParagraphRuns(shape: ShapeElement):
  RichTextParagraphStyleRun[] | undefined {
  if (shape.paragraphStyleRuns === undefined) {
    return undefined;
  }
  return shape.paragraphStyleRuns.map((run: RichTextParagraphStyleRun):
    RichTextParagraphStyleRun => {
    const style: RichTextParagraphStyle = JSON.parse(JSON.stringify(run.style)) as
      RichTextParagraphStyle;
    return { start: run.start, end: run.end, style: style };
  });
}

export function transformShapeElements(shapes: ShapeElement[], selectedIds: string[],
  transform: TransformMatrix): ShapeElement[] {
  const selected: Set<string> = new Set<string>(selectedIds);
  const result: ShapeElement[] = [];
  for (const shape of shapes) {
    if (!selected.has(shape.id) || shape.positionLocked === true) {
      result.push(shape);
      continue;
    }
    const updated: ShapeElement = cloneShapeElement(shape);
    updated.transform = multiplyTransform(transform, shape.transform);
    updated.bounds = recomputeShapeBounds(updated);
    result.push(updated);
  }
  return result;
}

export function recomputeShapeBounds(shape: ShapeElement): Rect2D {
  return transformBounds(localDefinitionBounds(shape), shape.transform);
}

// Android 1.0.3 n5d.G()/s4d/t4d/u4d computes a conservative definition-space
// box first, expands every edge by 2*borderWidth, then the entity transform is
// applied by the consumer.  Do not derive persisted bounds from sampled render
// points: that loses control-point extrema and the original arrow safety box.
function localDefinitionBounds(shape: ShapeElement): Rect2D {
  let bounds: Rect2D;
  if (shape.type === ElementType.LINE) {
    const points: Point2D[] = [shape.start, shape.end];
    if (shape.controlPoint1 !== null) {
      points.push(shape.controlPoint1);
    }
    if (shape.controlPoint2 !== null) {
      points.push(shape.controlPoint2);
    }
    bounds = pointsBounds(points);
    if (shape.arrowHead === ShapeArrowHead.SINGLE) {
      const arrowRadius: number = originalShapeArrowScale(shape.strokeWidth) * 46;
      bounds.left = Math.min(bounds.left, shape.end.x - arrowRadius);
      bounds.top = Math.min(bounds.top, shape.end.y - arrowRadius);
      bounds.right = Math.max(bounds.right, shape.end.x + arrowRadius);
      bounds.bottom = Math.max(bounds.bottom, shape.end.y + arrowRadius);
    }
  } else if (shape.type === ElementType.ELLIPSE) {
    const cosine: number = Math.cos(shape.rotationRadians);
    const sine: number = Math.sin(shape.rotationRadians);
    const halfWidth: number = Math.sqrt(
      shape.radiusX * shape.radiusX * cosine * cosine +
      shape.radiusY * shape.radiusY * sine * sine);
    const halfHeight: number = Math.sqrt(
      shape.radiusX * shape.radiusX * sine * sine +
      shape.radiusY * shape.radiusY * cosine * cosine);
    bounds = {
      left: shape.center.x - halfWidth,
      top: shape.center.y - halfHeight,
      right: shape.center.x + halfWidth,
      bottom: shape.center.y + halfHeight,
    };
  } else {
    bounds = pointsBounds(shape.vertices);
  }
  const padding: number = Math.max(0,
    Number.isFinite(shape.strokeWidth) ? shape.strokeWidth * 2 : 0);
  return {
    left: bounds.left - padding,
    top: bounds.top - padding,
    right: bounds.right + padding,
    bottom: bounds.bottom + padding,
  };
}

export function shapePathPoints(shape: ShapeElement): Point2D[] {
  const localSubpaths: Point2D[][] = shapeLocalSubpaths(shape);
  const transformed: Point2D[] = [];
  for (const subpath of localSubpaths) {
    for (const point of subpath) {
      transformed.push(transformPoint(point, shape.transform));
    }
  }
  return transformed;
}

export function eraserPathHitsShape(eraserPath: Point2D[], shape: ShapeElement,
  eraserWidth: number): boolean {
  if (eraserPath.length === 0 || shape.positionLocked === true) {
    return false;
  }
  const localSubpaths: Point2D[][] = shapeLocalSubpaths(shape);
  const shapeSubpaths: Point2D[][] = [];
  for (const local of localSubpaths) {
    const transformed: Point2D[] = [];
    for (const point of local) {
      transformed.push(transformPoint(point, shape.transform));
    }
    if (transformed.length > 0) {
      shapeSubpaths.push(transformed);
    }
  }
  if (shapeSubpaths.length === 0) {
    return false;
  }
  const fillPath: Point2D[] = shapeSubpaths[0];
  if (shape.type !== ElementType.LINE && shape.fillColor !== null && fillPath.length >= 3) {
    for (const eraserPoint of eraserPath) {
      if (pointInPolygon(eraserPoint, fillPath)) {
        return true;
      }
    }
  }
  const scale: number = maximumLinearScale(shape.transform);
  const radius: number = eraserWidth / 2 + shape.strokeWidth * scale / 2;
  const eraserSegments: number = Math.max(1, eraserPath.length - 1);
  for (let i: number = 0; i < eraserSegments; i++) {
    const a: Point2D = eraserPath[i];
    const b: Point2D = eraserPath.length === 1 ? a : eraserPath[i + 1];
    for (const shapePath of shapeSubpaths) {
      const shapeSegments: number = Math.max(1, shapePath.length - 1);
      for (let j: number = 0; j < shapeSegments; j++) {
        const c: Point2D = shapePath[j];
        const d: Point2D = shapePath.length === 1 ? c : shapePath[j + 1];
        if (segmentDistance(a, b, c, d) <= radius) {
          return true;
        }
      }
    }
  }
  return false;
}

function shapeLocalSubpaths(shape: ShapeElement): Point2D[][] {
  if (shape.type === ElementType.ELLIPSE) {
    return [ellipsePoints(shape)];
  }
  if (shape.type === ElementType.LINE) {
    const geometry: LineRenderGeometry = lineRenderGeometry(shape);
    const result: Point2D[][] = [geometry.mainPath];
    if (geometry.arrowHeadPath.length > 0) {
      result.push(geometry.arrowHeadPath);
    }
    return result;
  }
  return [polygonPoints(shape)];
}

// 原版 l96.W/d1j：箭头沿路径末段定向，长度与半宽随 borderWidth 缩放。
export function lineRenderGeometry(shape: LineElement): LineRenderGeometry {
  const sampled: Point2D[] = sampleLine(shape);
  if (shape.arrowHead !== ShapeArrowHead.SINGLE || sampled.length < 2) {
    return { mainPath: sampled, arrowHeadPath: [], mainPathEndParameter: 1 };
  }
  const totalLength: number = polylineLength(sampled);
  if (totalLength <= 0) {
    return { mainPath: sampled, arrowHeadPath: [], mainPathEndParameter: 1 };
  }
  const scale: number = originalShapeArrowScale(shape.strokeWidth);
  const arrowLength: number = Math.min(scale * 46, totalLength);
  const bodyLength: number = totalLength - arrowLength;
  const trimmed: TrimmedPolyline = trimPolyline(sampled, bodyLength);
  const mainPath: Point2D[] = trimmed.points;
  // Android PathMeasure returns a point on the original curve. The sampled polyline is only used
  // to locate its parameter; replace the interpolated endpoint with the exact Bezier position.
  const base: Point2D = linePointAt(shape, trimmed.endParameter);
  mainPath[mainPath.length - 1] = clonePoint(base);
  const tip: Point2D = linePointAt(shape, 1);
  const dx: number = tip.x - base.x;
  const dy: number = tip.y - base.y;
  const directionLength: number = Math.sqrt(dx * dx + dy * dy);
  if (directionLength <= 0) {
    return { mainPath: sampled, arrowHeadPath: [], mainPathEndParameter: 1 };
  }
  const halfWidth: number = scale * 20;
  const perpendicularX: number = -(dy / directionLength) * halfWidth;
  const perpendicularY: number = (dx / directionLength) * halfWidth;
  return {
    mainPath: mainPath,
    arrowHeadPath: [
      { x: base.x + perpendicularX, y: base.y + perpendicularY },
      clonePoint(tip),
      { x: base.x - perpendicularX, y: base.y - perpendicularY },
    ],
    mainPathEndParameter: trimmed.endParameter,
  };
}

function sampleLine(shape: LineElement): Point2D[] {
  if (shape.controlPoint1 === null) {
    return [clonePoint(shape.start), clonePoint(shape.end)];
  }
  const result: Point2D[] = [];
  for (let i: number = 0; i <= CURVE_HIT_SEGMENTS; i++) {
    result.push(linePointAt(shape, i / CURVE_HIT_SEGMENTS));
  }
  return result;
}

function linePointAt(shape: LineElement, t: number): Point2D {
  const inverse: number = 1 - t;
  if (shape.controlPoint1 !== null && shape.controlPoint2 !== null) {
    return {
      x: inverse * inverse * inverse * shape.start.x +
        3 * inverse * inverse * t * shape.controlPoint1.x +
        3 * inverse * t * t * shape.controlPoint2.x + t * t * t * shape.end.x,
      y: inverse * inverse * inverse * shape.start.y +
        3 * inverse * inverse * t * shape.controlPoint1.y +
        3 * inverse * t * t * shape.controlPoint2.y + t * t * t * shape.end.y,
    };
  }
  if (shape.controlPoint1 !== null) {
    return {
      x: inverse * inverse * shape.start.x +
        2 * inverse * t * shape.controlPoint1.x + t * t * shape.end.x,
      y: inverse * inverse * shape.start.y +
        2 * inverse * t * shape.controlPoint1.y + t * t * shape.end.y,
    };
  }
  return {
    x: shape.start.x + (shape.end.x - shape.start.x) * t,
    y: shape.start.y + (shape.end.y - shape.start.y) * t,
  };
}

function polylineLength(points: Point2D[]): number {
  let length: number = 0;
  for (let i: number = 1; i < points.length; i++) {
    const dx: number = points[i].x - points[i - 1].x;
    const dy: number = points[i].y - points[i - 1].y;
    length += Math.sqrt(dx * dx + dy * dy);
  }
  return length;
}

function trimPolyline(points: Point2D[], targetLength: number): TrimmedPolyline {
  const result: Point2D[] = [clonePoint(points[0])];
  if (targetLength <= 0) {
    return { points: result, endParameter: 0 };
  }
  let traversed: number = 0;
  const segmentCount: number = points.length - 1;
  for (let i: number = 1; i < points.length; i++) {
    const previous: Point2D = points[i - 1];
    const current: Point2D = points[i];
    const dx: number = current.x - previous.x;
    const dy: number = current.y - previous.y;
    const segmentLength: number = Math.sqrt(dx * dx + dy * dy);
    if (traversed + segmentLength >= targetLength) {
      const remaining: number = targetLength - traversed;
      const t: number = segmentLength <= 0 ? 0 : remaining / segmentLength;
      result.push({ x: previous.x + dx * t, y: previous.y + dy * t });
      return { points: result, endParameter: ((i - 1) + t) / segmentCount };
    }
    result.push(clonePoint(current));
    traversed += segmentLength;
  }
  return { points: result, endParameter: 1 };
}

export function originalShapeArrowScale(strokeWidth: number): number {
  let adjusted: number = strokeWidth;
  if (adjusted < 2) {
    adjusted = ((adjusted - 2) / 2) + 2;
  } else if (adjusted > 4) {
    adjusted = ((adjusted - 4) / 4) + 4;
  }
  return Math.max(0, adjusted) / 7;
}

function maximumLinearScale(matrix: TransformMatrix): number {
  const a: number = matrix[0];
  const b: number = matrix[1];
  const c: number = matrix[3];
  const d: number = matrix[4];
  const trace: number = a * a + b * b + c * c + d * d;
  const determinant: number = a * d - b * c;
  const discriminant: number = Math.max(0, trace * trace - 4 * determinant * determinant);
  return Math.sqrt(Math.max(0, (trace + Math.sqrt(discriminant)) / 2));
}

export function multiplyTransform(a: TransformMatrix, b: TransformMatrix): TransformMatrix {
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

export function transformBounds(bounds: Rect2D, transform: TransformMatrix): Rect2D {
  const corners: Point2D[] = [
    { x: bounds.left, y: bounds.top }, { x: bounds.right, y: bounds.top },
    { x: bounds.right, y: bounds.bottom }, { x: bounds.left, y: bounds.bottom },
  ];
  let left: number = Number.MAX_VALUE;
  let top: number = Number.MAX_VALUE;
  let right: number = -Number.MAX_VALUE;
  let bottom: number = -Number.MAX_VALUE;
  for (const corner of corners) {
    const point: Point2D = transformPoint(corner, transform);
    left = Math.min(left, point.x);
    top = Math.min(top, point.y);
    right = Math.max(right, point.x);
    bottom = Math.max(bottom, point.y);
  }
  return { left: left, top: top, right: right, bottom: bottom };
}

function pointsBounds(points: Point2D[]): Rect2D {
  if (points.length === 0) {
    return { left: 0, top: 0, right: 0, bottom: 0 };
  }
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

function ellipsePoints(shape: EllipseElement): Point2D[] {
  const result: Point2D[] = [];
  const cosRotation: number = Math.cos(shape.rotationRadians);
  const sinRotation: number = Math.sin(shape.rotationRadians);
  for (let i: number = 0; i <= ELLIPSE_HIT_SEGMENTS; i++) {
    const angle: number = i / ELLIPSE_HIT_SEGMENTS * Math.PI * 2;
    const x: number = Math.cos(angle) * shape.radiusX;
    const y: number = Math.sin(angle) * shape.radiusY;
    result.push({
      x: shape.center.x + x * cosRotation - y * sinRotation,
      y: shape.center.y + x * sinRotation + y * cosRotation,
    });
  }
  return result;
}

function polygonPoints(shape: PolygonElement): Point2D[] {
  const result: Point2D[] = shape.vertices.map((point: Point2D): Point2D => clonePoint(point));
  if (shape.isClosed && result.length > 0) {
    result.push(clonePoint(result[0]));
  }
  return result;
}

function transformPoint(point: Point2D, matrix: TransformMatrix): Point2D {
  return {
    x: matrix[0] * point.x + matrix[1] * point.y + matrix[2],
    y: matrix[3] * point.x + matrix[4] * point.y + matrix[5],
  };
}

function segmentDistance(a: Point2D, b: Point2D, c: Point2D, d: Point2D): number {
  if (segmentsIntersect(a, b, c, d)) {
    return 0;
  }
  return Math.min(
    Math.min(pointSegmentDistance(a, c, d), pointSegmentDistance(b, c, d)),
    Math.min(pointSegmentDistance(c, a, b), pointSegmentDistance(d, a, b)));
}

function segmentsIntersect(a: Point2D, b: Point2D, c: Point2D, d: Point2D): boolean {
  const abC: number = cross(a, b, c);
  const abD: number = cross(a, b, d);
  const cdA: number = cross(c, d, a);
  const cdB: number = cross(c, d, b);
  return abC * abD <= 0 && cdA * cdB <= 0 &&
    Math.max(Math.min(a.x, b.x), Math.min(c.x, d.x)) <= Math.min(Math.max(a.x, b.x), Math.max(c.x, d.x)) &&
    Math.max(Math.min(a.y, b.y), Math.min(c.y, d.y)) <= Math.min(Math.max(a.y, b.y), Math.max(c.y, d.y));
}

function pointSegmentDistance(point: Point2D, a: Point2D, b: Point2D): number {
  const dx: number = b.x - a.x;
  const dy: number = b.y - a.y;
  const lengthSquared: number = dx * dx + dy * dy;
  if (lengthSquared <= 0.0000001) {
    return Math.sqrt((point.x - a.x) * (point.x - a.x) + (point.y - a.y) * (point.y - a.y));
  }
  const raw: number = ((point.x - a.x) * dx + (point.y - a.y) * dy) / lengthSquared;
  const t: number = Math.max(0, Math.min(1, raw));
  const x: number = a.x + t * dx;
  const y: number = a.y + t * dy;
  return Math.sqrt((point.x - x) * (point.x - x) + (point.y - y) * (point.y - y));
}

function cross(a: Point2D, b: Point2D, point: Point2D): number {
  return (b.x - a.x) * (point.y - a.y) - (b.y - a.y) * (point.x - a.x);
}

function pointInPolygon(point: Point2D, polygon: Point2D[]): boolean {
  let inside: boolean = false;
  let previous: number = polygon.length - 1;
  for (let current: number = 0; current < polygon.length; current++) {
    const a: Point2D = polygon[current];
    const b: Point2D = polygon[previous];
    const crosses: boolean = (a.y > point.y) !== (b.y > point.y) &&
      point.x < (b.x - a.x) * (point.y - a.y) / (b.y - a.y) + a.x;
    if (crosses) {
      inside = !inside;
    }
    previous = current;
  }
  return inside;
}

function clonePoint(point: Point2D): Point2D {
  return { x: point.x, y: point.y };
}

function cloneNullablePoint(point: Point2D | null): Point2D | null {
  return point === null ? null : clonePoint(point);
}

function cloneRect(rect: Rect2D): Rect2D {
  return { left: rect.left, top: rect.top, right: rect.right, bottom: rect.bottom };
}
