import { CubicSegment, Point2D, Rect2D, TransformMatrix } from '../model/GeometryTypes';
import { InkPathCommand, PencilSplatPoint, StrokeElementData } from '../model/StrokeTypes';
import {
  ORIGINAL_PENCIL_FALLBACK_SEED, PencilSplatGenerator,
} from '../algorithm/PencilSplatGenerator';

const MAX_SYNCED_PENCIL_SPLATS: number = 262144;
const ORIGINAL_PENCIL_WIDTH_MULTIPLIER: number = 2.84;

export interface RebuiltOriginalPencilWidth {
  splatPoints: PencilSplatPoint[];
  bounds: Rect2D;
}

export function rebuildOriginalPencilWidth(stroke: StrokeElementData,
  width: number): RebuiltOriginalPencilWidth {
  if (!stroke.renderSpec.isPencil || !Number.isFinite(width) || width <= 0 ||
    stroke.pathPoints.length === 0 || stroke.cubicSegments.length === 0) {
    throw new Error('unsupported original Pencil width rebuild');
  }
  const generator: PencilSplatGenerator = new PencilSplatGenerator({
    spacing: width, maximumSplatCount: MAX_SYNCED_PENCIL_SPLATS,
  });
  const styleEntry = stroke.styleMap === undefined || stroke.styleMap.length === 0 ?
    undefined : stroke.styleMap[0];
  generator.reset(styleEntry === undefined ? ORIGINAL_PENCIL_FALLBACK_SEED :
    styleEntry.backingPencilSeed);
  let referencePoint: Point2D | undefined = undefined;
  if (styleEntry !== undefined && (styleEntry.backingPencilReferencePoint.x !== 0 ||
    styleEntry.backingPencilReferencePoint.y !== 0)) {
    referencePoint = styleEntry.backingPencilReferencePoint;
  }
  const splatPoints: PencilSplatPoint[] = generator.generate(
    stroke.cubicSegments, stroke.pathPoints, undefined, referencePoint);
  return {
    splatPoints: splatPoints,
    bounds: rebuiltBounds(stroke, width),
  };
}

function rebuiltBounds(stroke: StrokeElementData, width: number): Rect2D {
  let combined: Rect2D = centerPathBounds(stroke);
  const padding: number = width * ORIGINAL_PENCIL_WIDTH_MULTIPLIER * 2;
  combined = {
    left: combined.left - padding, top: combined.top - padding,
    right: combined.right + padding, bottom: combined.bottom + padding,
  };
  const auxiliary: (InkPathCommand[] | null | undefined)[] = [
    stroke.customPath, stroke.fillPath,
  ];
  for (const path of auxiliary) {
    const bounds: Rect2D | null = commandBounds(path);
    if (bounds !== null) {
      combined = unionBounds(combined, bounds);
    }
  }
  return transformBounds(combined, stroke.transform);
}

function centerPathBounds(stroke: StrokeElementData): Rect2D {
  const first: Point2D = stroke.pathPoints[0].position;
  let result: Rect2D = { left: first.x, top: first.y, right: first.x, bottom: first.y };
  for (const segment of stroke.cubicSegments) {
    const quadratic: Point2D | null = recoverQuadraticControl(segment);
    if (quadratic !== null) {
      result = includePoint(result, quadratic);
    } else {
      result = includePoint(includePoint(result, segment.p1), segment.p2);
    }
    result = includePoint(result, segment.p3);
  }
  return result;
}

function recoverQuadraticControl(segment: CubicSegment): Point2D | null {
  const x: number | null = recoverQuadraticCoordinate(
    segment.p0.x, segment.p1.x, segment.p2.x, segment.p3.x);
  const y: number | null = recoverQuadraticCoordinate(
    segment.p0.y, segment.p1.y, segment.p2.y, segment.p3.y);
  return x === null || y === null ? null : { x: x, y: y };
}

function recoverQuadraticCoordinate(start: number, control1: number,
  control2: number, end: number): number | null {
  const estimate: number = start + (control1 - start) * 3 / 2;
  const buffer: ArrayBuffer = new ArrayBuffer(4);
  const view: DataView = new DataView(buffer);
  view.setFloat32(0, estimate, true);
  const centerBits: number = view.getUint32(0, true);
  for (let offset: number = -4; offset <= 4; offset++) {
    const bits: number = centerBits + offset;
    if (bits < 0 || bits > 0xFFFFFFFF) {
      continue;
    }
    view.setUint32(0, bits, true);
    const candidate: number = view.getFloat32(0, true);
    if (start + (candidate - start) * 2 / 3 === control1 &&
      end + (candidate - end) * 2 / 3 === control2) {
      return candidate;
    }
  }
  return null;
}

function commandBounds(commands: InkPathCommand[] | null | undefined): Rect2D | null {
  if (commands === null || commands === undefined || commands.length === 0) {
    return null;
  }
  let result: Rect2D | null = null;
  for (const command of commands) {
    for (const point of command.points) {
      result = result === null ?
        { left: point.x, top: point.y, right: point.x, bottom: point.y } :
        includePoint(result, point);
    }
  }
  return result;
}

function includePoint(bounds: Rect2D, point: Point2D): Rect2D {
  return {
    left: Math.min(bounds.left, point.x), top: Math.min(bounds.top, point.y),
    right: Math.max(bounds.right, point.x), bottom: Math.max(bounds.bottom, point.y),
  };
}

function unionBounds(left: Rect2D, right: Rect2D): Rect2D {
  return {
    left: Math.min(left.left, right.left), top: Math.min(left.top, right.top),
    right: Math.max(left.right, right.right), bottom: Math.max(left.bottom, right.bottom),
  };
}

function transformBounds(bounds: Rect2D, transform: TransformMatrix): Rect2D {
  const corners: Point2D[] = [
    { x: bounds.left, y: bounds.top }, { x: bounds.right, y: bounds.top },
    { x: bounds.right, y: bounds.bottom }, { x: bounds.left, y: bounds.bottom },
  ];
  let result: Rect2D = {
    left: Number.MAX_VALUE, top: Number.MAX_VALUE,
    right: -Number.MAX_VALUE, bottom: -Number.MAX_VALUE,
  };
  for (const point of corners) {
    const x: number = transform[0] * point.x + transform[1] * point.y + transform[2];
    const y: number = transform[3] * point.x + transform[4] * point.y + transform[5];
    result = includePoint(result, { x: x, y: y });
  }
  return result;
}
