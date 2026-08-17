// Pure ShapeDefinition -> center-path geometry used by the original Shape/Pencil render paths.
// Keep this module free of platform imports so the exact LINE/ELLIPSE/POLYGON contract can be
// exercised by ArkTS fixtures without constructing a Canvas or native Path.
import {
  ElementType, EllipseElement, LineElement, ShapeArrowHead, ShapeElement,
} from './ElementTypes';
import { CubicSegment, Point2D } from './GeometryTypes';
import { lineRenderGeometry, LineRenderGeometry } from './ShapeGeometry';
import {
  InkPathCommand, InkPathCommandType, StrokePathPoint,
} from './StrokeTypes';

const ELLIPSE_CUBIC_KAPPA: number = 0.5522847498307936;

export interface ShapeStrokeComponent {
  pathPoints: StrokePathPoint[];
  cubicSegments: CubicSegment[];
  pathCommands: InkPathCommand[];
  closed: boolean;
}

export interface ShapeStrokeGeometry {
  components: ShapeStrokeComponent[];
  force: number;
}

export function shapeStrokeGeometry(shape: ShapeElement): ShapeStrokeGeometry {
  const force: number = originalShapeForce(shape);
  if (shape.type === ElementType.LINE) {
    return { components: lineComponents(shape, force), force: force };
  }
  if (shape.type === ElementType.ELLIPSE) {
    return { components: [ellipseComponent(shape, force)], force: force };
  }
  // xai always closes a Polygon with at least three points. `isClosed=false` can only come from
  // an older Harmony snapshot, so it must not change the original ShapeDefinition rendering.
  return { components: [polylineComponent(shape.vertices, true, force)], force: force };
}

export function originalShapeForce(shape: ShapeElement): number {
  const value: number | null | undefined = shape.originalForce !== undefined ?
    shape.originalForce : shape.originalCreate?.averageForce;
  return value !== null && value !== undefined && Number.isFinite(value) ? value : 1;
}

function lineComponents(shape: LineElement, force: number): ShapeStrokeComponent[] {
  if (shape.arrowHead === ShapeArrowHead.SINGLE) {
    // l96.W splits an arrow into body and arrow subpaths. The existing geometry helper performs
    // the same length-based trim; keep the two components separate because y4d.b() resets the
    // Pencil fallback seed before walking the arrow subpath.
    const rendered: LineRenderGeometry = lineRenderGeometry(shape);
    const result: ShapeStrokeComponent[] = [];
    const main: ShapeStrokeComponent | null = lineComponentOrNull(
      shape, rendered.mainPathEndParameter, force);
    const arrow: ShapeStrokeComponent | null = polylineComponentOrNull(
      rendered.arrowHeadPath, false, force);
    if (main !== null) {
      result.push(main);
    }
    if (arrow !== null) {
      result.push(arrow);
    }
    return result;
  }

  return [lineComponent(shape, 1, force)];
}

function lineComponentOrNull(shape: LineElement, endParameter: number,
  force: number): ShapeStrokeComponent | null {
  if (endParameter <= 0) {
    return null;
  }
  return lineComponent(shape, Math.min(endParameter, 1), force);
}

function lineComponent(shape: LineElement, endParameter: number,
  force: number): ShapeStrokeComponent {
  const start: Point2D = clonePoint(shape.start);
  let end: Point2D;
  let segment: CubicSegment;
  let command: InkPathCommand;
  if (shape.controlPoint1 !== null && shape.controlPoint2 !== null) {
    const first: Point2D = interpolate(start, shape.controlPoint1, endParameter);
    const second: Point2D = interpolate(shape.controlPoint1, shape.controlPoint2, endParameter);
    const third: Point2D = interpolate(shape.controlPoint2, shape.end, endParameter);
    const leftSecond: Point2D = interpolate(first, second, endParameter);
    const rightSecond: Point2D = interpolate(second, third, endParameter);
    end = interpolate(leftSecond, rightSecond, endParameter);
    segment = {
      p0: start, p1: first, p2: leftSecond, p3: end,
    };
    command = { type: InkPathCommandType.CUBIC,
      points: [clonePoint(first), clonePoint(leftSecond), clonePoint(end)] };
  } else if (shape.controlPoint1 !== null) {
    const control: Point2D = interpolate(start, shape.controlPoint1, endParameter);
    const right: Point2D = interpolate(shape.controlPoint1, shape.end, endParameter);
    end = interpolate(control, right, endParameter);
    segment = {
      p0: start,
      p1: { x: start.x + (control.x - start.x) * 2 / 3,
        y: start.y + (control.y - start.y) * 2 / 3 },
      p2: { x: end.x + (control.x - end.x) * 2 / 3,
        y: end.y + (control.y - end.y) * 2 / 3 },
      p3: end,
    };
    command = { type: InkPathCommandType.QUADRATIC,
      points: [clonePoint(control), clonePoint(end)] };
  } else {
    end = interpolate(start, shape.end, endParameter);
    segment = lineCubic(start, end);
    command = { type: InkPathCommandType.LINE_TO, points: [clonePoint(end)] };
  }
  return {
    pathPoints: [pathPoint(start, force), pathPoint(end, force)],
    cubicSegments: [segment],
    pathCommands: [moveCommand(start), command],
    closed: false,
  };
}

function ellipseComponent(shape: EllipseElement, force: number): ShapeStrokeComponent {
  const localPoints: Point2D[][] = [
    [
      { x: shape.radiusX, y: 0 },
      { x: shape.radiusX, y: ELLIPSE_CUBIC_KAPPA * shape.radiusY },
      { x: ELLIPSE_CUBIC_KAPPA * shape.radiusX, y: shape.radiusY },
      { x: 0, y: shape.radiusY },
    ],
    [
      { x: 0, y: shape.radiusY },
      { x: -ELLIPSE_CUBIC_KAPPA * shape.radiusX, y: shape.radiusY },
      { x: -shape.radiusX, y: ELLIPSE_CUBIC_KAPPA * shape.radiusY },
      { x: -shape.radiusX, y: 0 },
    ],
    [
      { x: -shape.radiusX, y: 0 },
      { x: -shape.radiusX, y: -ELLIPSE_CUBIC_KAPPA * shape.radiusY },
      { x: -ELLIPSE_CUBIC_KAPPA * shape.radiusX, y: -shape.radiusY },
      { x: 0, y: -shape.radiusY },
    ],
    [
      { x: 0, y: -shape.radiusY },
      { x: ELLIPSE_CUBIC_KAPPA * shape.radiusX, y: -shape.radiusY },
      { x: shape.radiusX, y: -ELLIPSE_CUBIC_KAPPA * shape.radiusY },
      { x: shape.radiusX, y: 0 },
    ],
  ];
  const segments: CubicSegment[] = [];
  const commands: InkPathCommand[] = [];
  const points: StrokePathPoint[] = [];
  for (let index: number = 0; index < localPoints.length; index++) {
    const local: Point2D[] = localPoints[index];
    const p0: Point2D = ellipsePoint(shape, local[0]);
    const p1: Point2D = ellipsePoint(shape, local[1]);
    const p2: Point2D = ellipsePoint(shape, local[2]);
    const p3: Point2D = ellipsePoint(shape, local[3]);
    if (index === 0) {
      points.push(pathPoint(p0, force));
      commands.push(moveCommand(p0));
    }
    points.push(pathPoint(p3, force));
    segments.push({ p0: p0, p1: p1, p2: p2, p3: p3 });
    commands.push({ type: InkPathCommandType.CUBIC,
      points: [clonePoint(p1), clonePoint(p2), clonePoint(p3)] });
  }
  return {
    pathPoints: points, cubicSegments: segments, pathCommands: commands, closed: true,
  };
}

function ellipsePoint(shape: EllipseElement, local: Point2D): Point2D {
  const cosine: number = Math.cos(shape.rotationRadians);
  const sine: number = Math.sin(shape.rotationRadians);
  return {
    x: shape.center.x + local.x * cosine - local.y * sine,
    y: shape.center.y + local.x * sine + local.y * cosine,
  };
}

function polylineComponentOrNull(points: Point2D[], closed: boolean,
  force: number): ShapeStrokeComponent | null {
  if (points.length === 0) {
    return null;
  }
  return polylineComponent(points, closed, force);
}

function polylineComponent(points: Point2D[], closed: boolean,
  force: number): ShapeStrokeComponent {
  const normalized: Point2D[] = [];
  for (const point of points) {
    if (normalized.length === 0 || !samePoint(normalized[normalized.length - 1], point)) {
      normalized.push(clonePoint(point));
    }
  }
  if (closed && normalized.length > 1 && !samePoint(normalized[0], normalized[normalized.length - 1])) {
    normalized.push(clonePoint(normalized[0]));
  }
  if (normalized.length === 0) {
    normalized.push({ x: 0, y: 0 });
  }
  const pathPoints: StrokePathPoint[] = normalized.map(
    (point: Point2D): StrokePathPoint => pathPoint(point, force));
  const segments: CubicSegment[] = [];
  const commands: InkPathCommand[] = [moveCommand(normalized[0])];
  for (let index: number = 1; index < normalized.length; index++) {
    segments.push(lineCubic(normalized[index - 1], normalized[index]));
    commands.push({ type: InkPathCommandType.LINE_TO,
      points: [clonePoint(normalized[index])] });
  }
  return {
    pathPoints: pathPoints, cubicSegments: segments,
    pathCommands: commands, closed: closed,
  };
}

function pathPoint(position: Point2D, force: number): StrokePathPoint {
  return {
    position: clonePoint(position), widthFactor: 1, pressure: force,
    altitudeAngleRadians: Math.PI / 2, azimuthUnitX: 1, azimuthUnitY: 0,
  };
}

function moveCommand(point: Point2D): InkPathCommand {
  return { type: InkPathCommandType.MOVE_TO, points: [clonePoint(point)] };
}

function lineCubic(start: Point2D, end: Point2D): CubicSegment {
  return {
    p0: clonePoint(start),
    p1: { x: start.x + (end.x - start.x) / 3,
      y: start.y + (end.y - start.y) / 3 },
    p2: { x: start.x + (end.x - start.x) * 2 / 3,
      y: start.y + (end.y - start.y) * 2 / 3 },
    p3: clonePoint(end),
  };
}

function interpolate(start: Point2D, end: Point2D, t: number): Point2D {
  return {
    x: start.x + (end.x - start.x) * t,
    y: start.y + (end.y - start.y) * t,
  };
}

function samePoint(a: Point2D, b: Point2D): boolean {
  return a.x === b.x && a.y === b.y;
}

function clonePoint(point: Point2D): Point2D {
  return { x: point.x, y: point.y };
}
