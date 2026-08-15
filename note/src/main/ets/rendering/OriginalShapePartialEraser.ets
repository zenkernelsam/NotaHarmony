import { common2D, drawing } from '@kit.ArkGraphics2D';
import {
  ORIGINAL_PENCIL_FALLBACK_SEED, PencilSplatGenerator,
} from '../core/algorithm/PencilSplatGenerator';
import {
  ElementType, EllipseElement, LineElement, PolygonElement, ShapeArrowHead, ShapeElement,
} from '../core/model/ElementTypes';
import { CubicSegment, Point2D, Rect2D, TransformMatrix } from '../core/model/GeometryTypes';
import {
  InkPathCommand, InkPathCommandType, InkStyle, InkStyleMapEntry,
  StrokeElementData, StrokePathPoint, TapePattern,
} from '../core/model/StrokeTypes';

const GEOMETRY_EPSILON: number = 0.000001;
const MAX_COMPONENTS_PER_SHAPE: number = 4096;
const MAX_CENTER_PATH_SAMPLES: number = 131072;
const MAX_ORIGINAL_PATH_ELEMENTS: number = 65535;
const CENTER_TRANSITION_ITERATIONS: number = 20;
const PATH_APPROXIMATION_ERROR: number = 0.05;

export interface ShapePartialEraseReplacement {
  sourceShape: ShapeElement;
  remnants: StrokeElementData[];
}

interface ShapeEraseGeometry {
  center: drawing.Path;
  outline: drawing.Path;
  fill: drawing.Path | null;
}

interface CenterPathRun {
  start: number;
  end: number;
  wraps: boolean;
}

interface CenterPathData {
  pathPoints: StrokePathPoint[];
  cubicSegments: CubicSegment[];
}

interface PathContour {
  path: drawing.Path;
  commands: InkPathCommand[];
  vertices: Point2D[];
  sample: Point2D;
  areaMagnitude: number;
  parent: number;
  depth: number;
}

interface ComponentCenters {
  component: drawing.Path;
  centers: StrokeElementData[];
}

// Android 1.0.3 jt1/n8j/o8j performs Shape partial erase as path boolean
// difference, then materializes every visible component as CREATE_INK. This
// implementation uses the equivalent HarmonyOS PathOp/Pen outline pipeline.
export class OriginalShapePartialEraser {
  private eraserWidth: number;

  constructor(eraserWidth: number) {
    this.eraserWidth = eraserWidth;
  }

  erase(eraserPath: Point2D[], shapes: ShapeElement[]): ShapePartialEraseReplacement[] {
    if (eraserPath.length === 0 || !Number.isFinite(this.eraserWidth) || this.eraserWidth <= 0) {
      return [];
    }
    const eraserOutline: drawing.Path | null = this.buildEraserOutline(eraserPath);
    if (eraserOutline === null || eraserOutline.isEmpty()) {
      return [];
    }
    const result: ShapePartialEraseReplacement[] = [];
    for (const shape of shapes) {
      if (shape.positionLocked === true) {
        continue;
      }
      try {
        const remnants: StrokeElementData[] | null = this.eraseShape(eraserOutline, shape);
        if (remnants !== null) {
          result.push({ sourceShape: shape, remnants: remnants });
        }
      } catch (_error) {
        // The original n8j path branch treats a failed clip as Unchanged. One
        // malformed or singular Shape must not turn a partial erase into loss.
      }
    }
    return result;
  }

  private eraseShape(eraserOutline: drawing.Path, shape: ShapeElement): StrokeElementData[] | null {
    const geometry: ShapeEraseGeometry | null = this.buildShapeGeometry(shape);
    const inverse: TransformMatrix | null = this.inverseAffine(shape.transform);
    if (geometry === null || inverse === null) {
      return null;
    }
    const localEraser: drawing.Path = new drawing.Path(eraserOutline);
    const inverseMatrix: drawing.Matrix = new drawing.Matrix();
    inverseMatrix.setMatrix(inverse);
    localEraser.transform(inverseMatrix);

    const visualBefore: drawing.Path | null = this.unionPaths(geometry.outline, geometry.fill);
    if (visualBefore === null || visualBefore.isEmpty()) {
      return null;
    }
    const intersection: drawing.Path | null = this.intersectionPath(visualBefore, localEraser);
    if (intersection === null || intersection.isEmpty()) {
      return null;
    }
    const clippedOutline: drawing.Path | null = this.differencePath(geometry.outline, localEraser);
    const clippedFill: drawing.Path | null = geometry.fill === null ? null :
      this.differencePath(geometry.fill, localEraser);
    if (clippedOutline === null || (geometry.fill !== null && clippedFill === null)) {
      return null;
    }
    const visualAfter: drawing.Path | null = this.unionPaths(clippedOutline, clippedFill);
    if (visualAfter === null) {
      return null;
    }
    if (visualAfter.isEmpty()) {
      return [];
    }

    const components: drawing.Path[] = this.filledComponents(visualAfter);
    if (components.length === 0 || components.length > MAX_COMPONENTS_PER_SHAPE) {
      return null;
    }
    const centers: StrokeElementData[] | null = this.centerRemnants(
      shape, geometry.center, localEraser);
    if (centers === null) {
      return null;
    }
    const componentCenters: ComponentCenters[] = components.map(
      (component: drawing.Path): ComponentCenters => ({ component: component, centers: [] }));
    const unassigned: StrokeElementData[] = [];
    for (const center of centers) {
      const midpoint: Point2D = this.centerMidpoint(center);
      let target: number = -1;
      for (let index: number = 0; index < componentCenters.length; index++) {
        if (this.pathContainsNear(componentCenters[index].component, midpoint)) {
          target = index;
          break;
        }
      }
      if (target < 0) {
        target = this.nearestComponent(componentCenters, midpoint);
      }
      if (target < 0) {
        unassigned.push(center);
      } else {
        componentCenters[target].centers.push(center);
      }
    }

    const remnants: StrokeElementData[] = [];
    for (const entry of componentCenters) {
      const outlinePart: drawing.Path | null = this.intersectionPath(clippedOutline, entry.component);
      const fillPart: drawing.Path | null = clippedFill === null ? null :
        this.intersectionPath(clippedFill, entry.component);
      if (outlinePart === null || (clippedFill !== null && fillPart === null)) {
        return null;
      }
      const outlineCommands: InkPathCommand[] = this.pathCommands(outlinePart);
      const fillCommands: InkPathCommand[] = fillPart === null ? [] : this.pathCommands(fillPart);
      const primaryCenter: StrokeElementData | null = entry.centers.length === 0 ?
        null : entry.centers[0];
      remnants.push(this.buildRemnant(
        shape, primaryCenter, entry.component, outlineCommands, fillCommands, remnants.length));
      if (this.centerPathControlsRendering(shape)) {
        for (let index: number = 1; index < entry.centers.length; index++) {
          remnants.push(this.buildRemnant(
            shape, entry.centers[index], entry.component, outlineCommands, [], remnants.length));
        }
      }
    }
    for (const center of unassigned) {
      remnants.push(this.buildRemnant(
        shape, center, null, [], [], remnants.length));
    }
    return remnants;
  }

  private buildEraserOutline(points: Point2D[]): drawing.Path | null {
    const path: drawing.Path = new drawing.Path();
    if (points.length === 1) {
      path.addCircle(points[0].x, points[0].y, this.eraserWidth / 2,
        drawing.PathDirection.CLOCKWISE);
      return path;
    }
    path.moveTo(points[0].x, points[0].y);
    for (let index: number = 1; index < points.length; index++) {
      path.lineTo(points[index].x, points[index].y);
    }
    const pen: drawing.Pen = new drawing.Pen();
    pen.setStrokeWidth(this.eraserWidth);
    pen.setCapStyle(drawing.CapStyle.ROUND_CAP);
    pen.setJoinStyle(drawing.JoinStyle.ROUND_JOIN);
    const outline: drawing.Path = new drawing.Path();
    return pen.getFillPath(path, outline) ? outline : null;
  }

  private buildShapeGeometry(shape: ShapeElement): ShapeEraseGeometry | null {
    const centerPath: drawing.Path | null = this.shapeCenterPath(shape);
    if (centerPath === null || centerPath.isEmpty()) {
      return null;
    }
    const pen: drawing.Pen = new drawing.Pen();
    pen.setStrokeWidth(shape.strokeWidth);
    pen.setCapStyle(drawing.CapStyle.ROUND_CAP);
    pen.setJoinStyle(drawing.JoinStyle.ROUND_JOIN);
    const outline: drawing.Path = new drawing.Path();
    if (!pen.getFillPath(centerPath, outline)) {
      return null;
    }
    if (shape.type === ElementType.LINE && shape.arrowHead === ShapeArrowHead.SINGLE) {
      const arrow: drawing.Path | null = this.shapeArrowPath(shape, centerPath);
      if (arrow !== null && !outline.op(arrow, drawing.PathOp.UNION)) {
        return null;
      }
    }
    let fill: drawing.Path | null = null;
    if (shape.type !== ElementType.LINE && shape.fillColor !== null) {
      fill = new drawing.Path(centerPath);
    }
    return { center: centerPath, outline: outline, fill: fill };
  }

  private shapeCenterPath(shape: ShapeElement): drawing.Path | null {
    const path: drawing.Path = new drawing.Path();
    if (shape.type === ElementType.ELLIPSE) {
      const ellipse: EllipseElement = shape as EllipseElement;
      if (!this.finitePoint(ellipse.center) || !Number.isFinite(ellipse.radiusX) ||
        !Number.isFinite(ellipse.radiusY) || ellipse.radiusX <= 0 || ellipse.radiusY <= 0 ||
        !Number.isFinite(ellipse.rotationRadians)) {
        return null;
      }
      path.addOval({
        left: ellipse.center.x - ellipse.radiusX,
        top: ellipse.center.y - ellipse.radiusY,
        right: ellipse.center.x + ellipse.radiusX,
        bottom: ellipse.center.y + ellipse.radiusY,
      }, 1, drawing.PathDirection.CLOCKWISE);
      if (Math.abs(ellipse.rotationRadians) > GEOMETRY_EPSILON) {
        const rotation: drawing.Matrix = new drawing.Matrix();
        rotation.setRotation(ellipse.rotationRadians * 180 / Math.PI,
          ellipse.center.x, ellipse.center.y);
        path.transform(rotation);
      }
      return path;
    }
    if (shape.type === ElementType.LINE) {
      const line: LineElement = shape as LineElement;
      if (!this.finitePoint(line.start) || !this.finitePoint(line.end) ||
        line.controlPoint1 !== null && !this.finitePoint(line.controlPoint1) ||
        line.controlPoint2 !== null && !this.finitePoint(line.controlPoint2)) {
        return null;
      }
      path.moveTo(line.start.x, line.start.y);
      if (line.controlPoint1 !== null && line.controlPoint2 !== null) {
        path.cubicTo(line.controlPoint1.x, line.controlPoint1.y,
          line.controlPoint2.x, line.controlPoint2.y, line.end.x, line.end.y);
      } else if (line.controlPoint1 !== null) {
        path.quadTo(line.controlPoint1.x, line.controlPoint1.y, line.end.x, line.end.y);
      } else {
        path.lineTo(line.end.x, line.end.y);
      }
      return path;
    }
    const polygon: PolygonElement = shape as PolygonElement;
    if (polygon.vertices.length < 3 ||
      polygon.vertices.some((point: Point2D): boolean => !this.finitePoint(point))) {
      return null;
    }
    path.moveTo(polygon.vertices[0].x, polygon.vertices[0].y);
    for (let index: number = 1; index < polygon.vertices.length; index++) {
      path.lineTo(polygon.vertices[index].x, polygon.vertices[index].y);
    }
    // Android xai.d() closes every u4d polygon with at least three vertices.
    // isClosed is retained only for legacy Harmony package compatibility.
    path.close();
    return path;
  }

  private shapeArrowPath(shape: LineElement, centerPath: drawing.Path): drawing.Path | null {
    const length: number = centerPath.getLength(false);
    if (!Number.isFinite(length) || length <= GEOMETRY_EPSILON) {
      return null;
    }
    const arrowLength: number = Math.min(this.arrowScale(shape.strokeWidth) * 46, length);
    const baseDistance: number = length - arrowLength;
    const tip: common2D.Point = { x: 0, y: 0 };
    const base: common2D.Point = { x: 0, y: 0 };
    const tangent: common2D.Point = { x: 0, y: 0 };
    if (!centerPath.getPositionAndTangent(false, length, tip, tangent) ||
      !centerPath.getPositionAndTangent(false, baseDistance, base, tangent)) {
      return null;
    }
    const dx: number = tip.x - base.x;
    const dy: number = tip.y - base.y;
    const directionLength: number = Math.sqrt(dx * dx + dy * dy);
    if (directionLength <= GEOMETRY_EPSILON) {
      return null;
    }
    const halfWidth: number = this.arrowScale(shape.strokeWidth) * 20;
    const perpendicularX: number = -(dy / directionLength) * halfWidth;
    const perpendicularY: number = (dx / directionLength) * halfWidth;
    const arrow: drawing.Path = new drawing.Path();
    arrow.moveTo(base.x + perpendicularX, base.y + perpendicularY);
    arrow.lineTo(tip.x, tip.y);
    arrow.lineTo(base.x - perpendicularX, base.y - perpendicularY);
    return arrow;
  }

  private centerRemnants(shape: ShapeElement, centerPath: drawing.Path,
    eraserPath: drawing.Path): StrokeElementData[] | null {
    const length: number = centerPath.getLength(false);
    if (!Number.isFinite(length) || length < 0) {
      return null;
    }
    if (length <= GEOMETRY_EPSILON) {
      const single: StrokeElementData | null = this.centerStrokeFromPath(shape, centerPath, 0, 0);
      if (single === null) {
        return null;
      }
      return eraserPath.contains(single.pathPoints[0].position.x,
        single.pathPoints[0].position.y) ? [] : [single];
    }
    const scale: number = this.maximumLinearScale(shape.transform);
    if (!Number.isFinite(scale) || scale <= GEOMETRY_EPSILON) {
      return null;
    }
    const localEraserWidth: number = this.eraserWidth / scale;
    const step: number = Math.max(GEOMETRY_EPSILON * 16,
      Math.min(1, localEraserWidth / 4));
    const divisions: number = Math.max(1, Math.ceil(length / step));
    if (divisions > MAX_CENTER_PATH_SAMPLES) {
      return null;
    }
    const erased: boolean[] = [];
    let hasErased: boolean = false;
    let hasOutside: boolean = false;
    for (let index: number = 0; index <= divisions; index++) {
      const distance: number = length * index / divisions;
      const value: boolean | null = this.centerDistanceIsErased(centerPath, eraserPath, distance);
      if (value === null) {
        return null;
      }
      erased.push(value);
      hasErased = hasErased || value;
      hasOutside = hasOutside || !value;
    }
    if (!hasErased) {
      const source: StrokeElementData | null = this.centerStrokeFromPath(shape, centerPath, 0, 0);
      return source === null ? null : [source];
    }
    if (!hasOutside) {
      return [];
    }
    const runs: CenterPathRun[] = [];
    let runStart: number = erased[0] ? -1 : 0;
    for (let index: number = 1; index <= divisions; index++) {
      const previousDistance: number = length * (index - 1) / divisions;
      const distance: number = length * index / divisions;
      if (!erased[index - 1] && erased[index]) {
        const boundary: number | null = this.centerTransitionDistance(
          centerPath, eraserPath, previousDistance, distance, false);
        if (boundary === null || runStart < 0) {
          return null;
        }
        if (boundary - runStart > GEOMETRY_EPSILON) {
          runs.push({ start: runStart, end: boundary, wraps: false });
        }
        runStart = -1;
      } else if (erased[index - 1] && !erased[index]) {
        const boundary: number | null = this.centerTransitionDistance(
          centerPath, eraserPath, previousDistance, distance, true);
        if (boundary === null) {
          return null;
        }
        runStart = boundary;
      }
    }
    if (runStart >= 0 && length - runStart > GEOMETRY_EPSILON) {
      runs.push({ start: runStart, end: length, wraps: false });
    }
    if (centerPath.isClosed() && runs.length >= 2 &&
      runs[0].start <= GEOMETRY_EPSILON &&
      length - runs[runs.length - 1].end <= GEOMETRY_EPSILON) {
      const first: CenterPathRun = runs.shift() as CenterPathRun;
      const last: CenterPathRun = runs.pop() as CenterPathRun;
      runs.unshift({ start: last.start, end: first.end, wraps: true });
    }
    const result: StrokeElementData[] = [];
    for (let index: number = 0; index < runs.length; index++) {
      const run: CenterPathRun = runs[index];
      const remnantPath: drawing.Path = new drawing.Path();
      let extracted: boolean;
      if (run.wraps) {
        extracted = centerPath.getSegment(false, run.start, length, true, remnantPath);
        extracted = centerPath.getSegment(false, 0, run.end, false, remnantPath) && extracted;
      } else {
        extracted = centerPath.getSegment(false, run.start, run.end, true, remnantPath);
      }
      if (!extracted || remnantPath.isEmpty()) {
        return null;
      }
      const remnant: StrokeElementData | null = this.centerStrokeFromPath(
        shape, remnantPath, run.start, index);
      if (remnant === null) {
        return null;
      }
      result.push(remnant);
    }
    return result;
  }

  private centerStrokeFromPath(shape: ShapeElement, path: drawing.Path,
    startDistance: number, index: number): StrokeElementData | null {
    const data: CenterPathData | null = this.centerPathData(shape, path);
    if (data === null || data.pathPoints.length === 0) {
      return null;
    }
    const style: InkStyle = this.inkStyle(shape);
    const referencePoint: Point2D = data.pathPoints[0].position;
    return {
      id: `${shape.id}#shape-center-${index}`, pathPoints: data.pathPoints,
      cubicSegments: data.cubicSegments, splatPoints: [],
      renderSpec: {
        color: shape.color,
        brushWidth: shape.strokeWidth, inkStyle: style,
        isHighlighter: false, isPencil: false,
      },
      transform: shape.transform.slice(),
      bounds: this.centerBounds(data.pathPoints, data.cubicSegments, shape.transform),
      maskPath: [], customPath: null, fillPath: null, fillColor: null, isFinished: true,
      styleMap: this.styleMap(shape, style, referencePoint, startDistance),
    };
  }

  private centerPathData(shape: ShapeElement, path: drawing.Path): CenterPathData | null {
    const iterator: drawing.PathIterator = path.getPathIterator();
    const points: common2D.Point[] = [
      { x: 0, y: 0 }, { x: 0, y: 0 }, { x: 0, y: 0 }, { x: 0, y: 0 },
    ];
    const pathPoints: StrokePathPoint[] = [];
    const cubicSegments: CubicSegment[] = [];
    let current: Point2D | null = null;
    let contourStart: Point2D | null = null;
    let hasContour: boolean = false;
    while (iterator.hasNext()) {
      const verb: drawing.PathIteratorVerb = iterator.next(points);
      if (verb === drawing.PathIteratorVerb.DONE) {
        break;
      }
      if (verb === drawing.PathIteratorVerb.MOVE) {
        if (hasContour) {
          return null;
        }
        current = this.fromDrawingPoint(points[0]);
        contourStart = this.clonePoint(current);
        pathPoints.push(this.centerPathPoint(shape, current));
        hasContour = true;
      } else if (current !== null && verb === drawing.PathIteratorVerb.LINE) {
        const end: Point2D = this.fromDrawingPoint(points[1]);
        this.appendCenterCubic(shape, pathPoints, cubicSegments, current,
          { x: current.x + (end.x - current.x) / 3,
            y: current.y + (end.y - current.y) / 3 },
          { x: current.x + (end.x - current.x) * 2 / 3,
            y: current.y + (end.y - current.y) * 2 / 3 }, end);
        current = end;
      } else if (current !== null && verb === drawing.PathIteratorVerb.QUAD) {
        const control: Point2D = this.fromDrawingPoint(points[1]);
        const end: Point2D = this.fromDrawingPoint(points[2]);
        this.appendCenterCubic(shape, pathPoints, cubicSegments, current,
          { x: current.x + (control.x - current.x) * 2 / 3,
            y: current.y + (control.y - current.y) * 2 / 3 },
          { x: end.x + (control.x - end.x) * 2 / 3,
            y: end.y + (control.y - end.y) * 2 / 3 }, end);
        current = end;
      } else if (current !== null && verb === drawing.PathIteratorVerb.CUBIC) {
        const control1: Point2D = this.fromDrawingPoint(points[1]);
        const control2: Point2D = this.fromDrawingPoint(points[2]);
        const end: Point2D = this.fromDrawingPoint(points[3]);
        this.appendCenterCubic(shape, pathPoints, cubicSegments, current,
          control1, control2, end);
        current = end;
      } else if (verb === drawing.PathIteratorVerb.CONIC) {
        // The ArkTS iterator exposes the conic verb but not its rational weight.
        // Preserve the native clip boundary and approximate only its serialized
        // CREATE_INK center path instead of incorrectly treating it as weight 1.
        return this.approximateCenterPathData(shape, path);
      } else if (current !== null && contourStart !== null &&
        verb === drawing.PathIteratorVerb.CLOSE && !this.samePoint(current, contourStart)) {
        const end: Point2D = contourStart;
        this.appendCenterCubic(shape, pathPoints, cubicSegments, current,
          { x: current.x + (end.x - current.x) / 3,
            y: current.y + (end.y - current.y) / 3 },
          { x: current.x + (end.x - current.x) * 2 / 3,
            y: current.y + (end.y - current.y) * 2 / 3 }, end);
        current = end;
      }
    }
    return pathPoints.length === 0 ? null : {
      pathPoints: pathPoints, cubicSegments: cubicSegments,
    };
  }

  private approximateCenterPathData(shape: ShapeElement, path: drawing.Path): CenterPathData | null {
    const values: number[] = path.approximate(PATH_APPROXIMATION_ERROR);
    if (values.length < 3 || values.length % 3 !== 0 ||
      values.length / 3 > MAX_ORIGINAL_PATH_ELEMENTS) {
      return null;
    }
    const pathPoints: StrokePathPoint[] = [];
    let previousFraction: number = -1;
    for (let offset: number = 0; offset < values.length; offset += 3) {
      const fraction: number = values[offset];
      const point: Point2D = { x: values[offset + 1], y: values[offset + 2] };
      if (!Number.isFinite(fraction) || !this.finitePoint(point) ||
        fraction + GEOMETRY_EPSILON < previousFraction) {
        return null;
      }
      if (pathPoints.length > 0) {
        const previous: Point2D = pathPoints[pathPoints.length - 1].position;
        if (Math.abs(fraction - previousFraction) <= GEOMETRY_EPSILON &&
          !this.samePoint(previous, point)) {
          return null;
        }
        if (this.samePoint(previous, point)) {
          previousFraction = fraction;
          continue;
        }
      }
      pathPoints.push(this.centerPathPoint(shape, point));
      previousFraction = fraction;
    }
    if (path.isClosed() && pathPoints.length > 1 &&
      !this.samePoint(pathPoints[0].position, pathPoints[pathPoints.length - 1].position)) {
      pathPoints.push(this.centerPathPoint(shape, pathPoints[0].position));
    }
    return pathPoints.length === 0 ? null : {
      pathPoints: pathPoints, cubicSegments: this.lineSegments(pathPoints),
    };
  }

  private appendCenterCubic(shape: ShapeElement, pathPoints: StrokePathPoint[],
    cubicSegments: CubicSegment[], start: Point2D, control1: Point2D,
    control2: Point2D, end: Point2D): void {
    cubicSegments.push({
      p0: this.clonePoint(start), p1: this.clonePoint(control1),
      p2: this.clonePoint(control2), p3: this.clonePoint(end),
    });
    pathPoints.push(this.centerPathPoint(shape, end));
  }

  private centerPathPoint(shape: ShapeElement, position: Point2D): StrokePathPoint {
    return {
      position: this.clonePoint(position), widthFactor: 1,
      pressure: shape.originalCreate?.averageForce ?? 1,
      altitudeAngleRadians: Math.PI / 2, azimuthUnitX: 1, azimuthUnitY: 0,
    };
  }

  private centerDistanceIsErased(centerPath: drawing.Path, eraserPath: drawing.Path,
    distance: number): boolean | null {
    const position: common2D.Point = { x: 0, y: 0 };
    const tangent: common2D.Point = { x: 0, y: 0 };
    if (!centerPath.getPositionAndTangent(false, distance, position, tangent)) {
      return null;
    }
    return eraserPath.contains(position.x, position.y);
  }

  private centerTransitionDistance(centerPath: drawing.Path, eraserPath: drawing.Path,
    start: number, end: number, startErased: boolean): number | null {
    let low: number = start;
    let high: number = end;
    for (let iteration: number = 0; iteration < CENTER_TRANSITION_ITERATIONS; iteration++) {
      const middle: number = (low + high) / 2;
      const erased: boolean | null = this.centerDistanceIsErased(centerPath, eraserPath, middle);
      if (erased === null) {
        return null;
      }
      if (erased === startErased) {
        low = middle;
      } else {
        high = middle;
      }
    }
    return (low + high) / 2;
  }

  private buildRemnant(shape: ShapeElement, center: StrokeElementData | null,
    component: drawing.Path | null, outlineCommands: InkPathCommand[],
    fillCommands: InkPathCommand[], index: number): StrokeElementData {
    const fallback: Point2D = center === null ?
      this.pathFallbackPoint(component, outlineCommands, fillCommands) :
      this.clonePoint(center.pathPoints[0].position);
    const pathPoints: StrokePathPoint[] = center === null ? [{
      position: fallback, widthFactor: 1,
      pressure: shape.originalCreate?.averageForce ?? 1,
      altitudeAngleRadians: Math.PI / 2, azimuthUnitX: 1, azimuthUnitY: 0,
    }] : center.pathPoints.map((point: StrokePathPoint): StrokePathPoint =>
      this.clonePathPoint(point));
    const cubicSegments: CubicSegment[] = center === null ? [] :
      center.cubicSegments.map((segment: CubicSegment): CubicSegment =>
        this.cloneSegment(segment));
    const style: InkStyle = this.inkStyle(shape);
    const tool: number = shape.originalTool ?? 0;
    const styleMap: InkStyleMapEntry[] | undefined = center?.styleMap === undefined ?
      this.styleMap(shape, style, fallback, 0) :
      center.styleMap.map((entry: InkStyleMapEntry): InkStyleMapEntry => ({
        backingPencilSeed: entry.backingPencilSeed,
        backingPencilReferencePoint: this.clonePoint(entry.backingPencilReferencePoint),
        backingDashPhase: entry.backingDashPhase,
        backingDashPeriod: entry.backingDashPeriod,
      }));
    const customPath: InkPathCommand[] | null = outlineCommands.length > 0 ?
      this.cloneCommands(outlineCommands) : fillCommands.length > 0 ? [{
        type: InkPathCommandType.MOVE_TO, points: [this.clonePoint(fallback)],
      }] : null;
    const stroke: StrokeElementData = {
      id: `${shape.id}#erase-${index}`,
      pathPoints: pathPoints, cubicSegments: cubicSegments, splatPoints: [],
      renderSpec: {
        color: shape.color, brushWidth: shape.strokeWidth, inkStyle: style,
        isHighlighter: tool === 2, isPencil: tool === 1,
        tapePattern: tool === 3 ? TapePattern.STRIPES : undefined,
      },
      transform: shape.transform.slice(),
      bounds: this.remnantBounds(pathPoints, cubicSegments, customPath,
        fillCommands.length === 0 ? null : fillCommands, shape.strokeWidth, shape.transform),
      maskPath: [], customPath: customPath,
      fillPath: fillCommands.length === 0 ? null : this.cloneCommands(fillCommands),
      fillColor: fillCommands.length === 0 ? null : shape.fillColor,
      styleMap: styleMap, isFinished: true,
    };
    if (stroke.renderSpec.isPencil && stroke.cubicSegments.length > 0) {
      const generator: PencilSplatGenerator = new PencilSplatGenerator({
        spacing: stroke.renderSpec.brushWidth, maximumSplatCount: 262144,
      });
      generator.reset(styleMap === undefined ? ORIGINAL_PENCIL_FALLBACK_SEED :
        styleMap[0].backingPencilSeed);
      stroke.splatPoints = generator.generate(
        stroke.cubicSegments, stroke.pathPoints, undefined,
        styleMap === undefined ? undefined : styleMap[0].backingPencilReferencePoint);
    }
    return stroke;
  }

  private filledComponents(path: drawing.Path): drawing.Path[] {
    const contours: PathContour[] = this.pathContours(path);
    if (contours.length <= 1) {
      return [new drawing.Path(path)];
    }
    for (let index: number = 0; index < contours.length; index++) {
      let parent: number = -1;
      let parentArea: number = Number.MAX_VALUE;
      for (let candidate: number = 0; candidate < contours.length; candidate++) {
        if (candidate === index ||
          contours[candidate].areaMagnitude <= contours[index].areaMagnitude + GEOMETRY_EPSILON) {
          continue;
        }
        if (contours[candidate].path.contains(
          contours[index].sample.x, contours[index].sample.y) &&
          contours[candidate].areaMagnitude < parentArea) {
          parent = candidate;
          parentArea = contours[candidate].areaMagnitude;
        }
      }
      contours[index].parent = parent;
    }
    for (let index: number = 0; index < contours.length; index++) {
      let depth: number = 0;
      let parent: number = contours[index].parent;
      const visited: Set<number> = new Set<number>();
      while (parent >= 0 && !visited.has(parent)) {
        visited.add(parent);
        depth++;
        parent = contours[parent].parent;
      }
      contours[index].depth = depth;
    }
    const components: drawing.Path[] = [];
    for (let index: number = 0; index < contours.length; index++) {
      if (contours[index].depth % 2 !== 0) {
        continue;
      }
      const component: drawing.Path = new drawing.Path();
      component.addPath(contours[index].path);
      for (let child: number = 0; child < contours.length; child++) {
        if (contours[child].parent === index && contours[child].depth === contours[index].depth + 1) {
          component.addPath(contours[child].path);
        }
      }
      component.setFillType(drawing.PathFillType.EVEN_ODD);
      components.push(component);
    }
    return components.length === 0 ? [new drawing.Path(path)] : components;
  }

  private pathContours(path: drawing.Path): PathContour[] {
    if (this.pathContainsConic(path)) {
      // PathIteratorVerb.CONIC does not expose its rational weight. Keep all
      // boolean work native, then flatten only the final CREATE_INK geometry;
      // treating the control/end pair as weight-one QUAD changes an oval.
      return this.approximatePathContours(path);
    }
    const iterator: drawing.PathIterator = path.getPathIterator();
    const points: common2D.Point[] = [
      { x: 0, y: 0 }, { x: 0, y: 0 }, { x: 0, y: 0 }, { x: 0, y: 0 },
    ];
    const contours: PathContour[] = [];
    let currentPath: drawing.Path | null = null;
    let commands: InkPathCommand[] = [];
    let vertices: Point2D[] = [];
    let start: Point2D | null = null;
    let last: Point2D | null = null;
    while (iterator.hasNext()) {
      const verb: drawing.PathIteratorVerb = iterator.next(points);
      if (verb === drawing.PathIteratorVerb.DONE) {
        break;
      }
      if (verb === drawing.PathIteratorVerb.MOVE) {
        if (currentPath !== null) {
          this.finishContour(contours, currentPath, commands, vertices, start, last);
        }
        const point: Point2D = this.fromDrawingPoint(points[0]);
        currentPath = new drawing.Path();
        currentPath.moveTo(point.x, point.y);
        commands = [{ type: InkPathCommandType.MOVE_TO, points: [this.clonePoint(point)] }];
        vertices = [this.clonePoint(point)];
        start = point;
        last = point;
      } else if (currentPath !== null && verb === drawing.PathIteratorVerb.LINE) {
        const point: Point2D = this.fromDrawingPoint(points[1]);
        currentPath.lineTo(point.x, point.y);
        commands.push({ type: InkPathCommandType.LINE_TO, points: [this.clonePoint(point)] });
        vertices.push(this.clonePoint(point));
        last = point;
      } else if (currentPath !== null && verb === drawing.PathIteratorVerb.QUAD) {
        const control: Point2D = this.fromDrawingPoint(points[1]);
        const end: Point2D = this.fromDrawingPoint(points[2]);
        currentPath.quadTo(control.x, control.y, end.x, end.y);
        commands.push({ type: InkPathCommandType.QUADRATIC,
          points: [this.clonePoint(control), this.clonePoint(end)] });
        vertices.push(this.clonePoint(end));
        last = end;
      } else if (currentPath !== null && verb === drawing.PathIteratorVerb.CUBIC) {
        const control1: Point2D = this.fromDrawingPoint(points[1]);
        const control2: Point2D = this.fromDrawingPoint(points[2]);
        const end: Point2D = this.fromDrawingPoint(points[3]);
        currentPath.cubicTo(control1.x, control1.y, control2.x, control2.y, end.x, end.y);
        commands.push({ type: InkPathCommandType.CUBIC,
          points: [this.clonePoint(control1), this.clonePoint(control2), this.clonePoint(end)] });
        vertices.push(this.clonePoint(end));
        last = end;
      } else if (currentPath !== null && verb === drawing.PathIteratorVerb.CLOSE) {
        if (start !== null && last !== null && !this.samePoint(start, last)) {
          currentPath.lineTo(start.x, start.y);
          commands.push({ type: InkPathCommandType.LINE_TO,
            points: [this.clonePoint(start)] });
          vertices.push(this.clonePoint(start));
          last = start;
        }
        currentPath.close();
      }
    }
    if (currentPath !== null) {
      this.finishContour(contours, currentPath, commands, vertices, start, last);
    }
    return contours;
  }

  private pathContainsConic(path: drawing.Path): boolean {
    const iterator: drawing.PathIterator = path.getPathIterator();
    const points: common2D.Point[] = [
      { x: 0, y: 0 }, { x: 0, y: 0 }, { x: 0, y: 0 }, { x: 0, y: 0 },
    ];
    while (iterator.hasNext()) {
      const verb: drawing.PathIteratorVerb = iterator.next(points);
      if (verb === drawing.PathIteratorVerb.CONIC) {
        return true;
      }
      if (verb === drawing.PathIteratorVerb.DONE) {
        break;
      }
    }
    return false;
  }

  private approximatePathContours(path: drawing.Path): PathContour[] {
    const values: number[] = path.approximate(PATH_APPROXIMATION_ERROR);
    if (values.length < 3 || values.length % 3 !== 0 ||
      values.length / 3 > MAX_ORIGINAL_PATH_ELEMENTS) {
      throw new Error('Shape auxiliary path approximation exceeds the original path budget');
    }
    const contours: PathContour[] = [];
    let currentPath: drawing.Path | null = null;
    let commands: InkPathCommand[] = [];
    let vertices: Point2D[] = [];
    let start: Point2D | null = null;
    let last: Point2D | null = null;
    let previousFraction: number = -1;
    for (let offset: number = 0; offset < values.length; offset += 3) {
      const fraction: number = values[offset];
      const point: Point2D = { x: values[offset + 1], y: values[offset + 2] };
      if (!Number.isFinite(fraction) || fraction < 0 || fraction > 1 ||
        !this.finitePoint(point) || fraction + GEOMETRY_EPSILON < previousFraction) {
        throw new Error('Shape auxiliary path approximation is invalid');
      }
      const contourBreak: boolean = currentPath === null ||
        last !== null && Math.abs(fraction - previousFraction) <= GEOMETRY_EPSILON &&
        !this.samePoint(last, point);
      if (contourBreak) {
        if (currentPath !== null) {
          this.finishContour(contours, currentPath, commands, vertices, start, last);
        }
        currentPath = new drawing.Path();
        currentPath.moveTo(point.x, point.y);
        commands = [{ type: InkPathCommandType.MOVE_TO, points: [this.clonePoint(point)] }];
        vertices = [this.clonePoint(point)];
        start = point;
        last = point;
      } else if (currentPath !== null && last !== null && !this.samePoint(last, point)) {
        currentPath.lineTo(point.x, point.y);
        commands.push({ type: InkPathCommandType.LINE_TO, points: [this.clonePoint(point)] });
        vertices.push(this.clonePoint(point));
        last = point;
      }
      previousFraction = fraction;
    }
    if (currentPath !== null) {
      this.finishContour(contours, currentPath, commands, vertices, start, last);
    }
    return contours;
  }

  private finishContour(contours: PathContour[], path: drawing.Path,
    commands: InkPathCommand[], vertices: Point2D[], start: Point2D | null,
    last: Point2D | null): void {
    if (commands.length === 0 || start === null) {
      return;
    }
    if (last !== null && !this.samePoint(start, last)) {
      path.lineTo(start.x, start.y);
      path.close();
      commands.push({ type: InkPathCommandType.LINE_TO, points: [this.clonePoint(start)] });
      vertices.push(this.clonePoint(start));
    }
    const areaMagnitude: number = Math.abs(this.signedArea(vertices));
    contours.push({
      path: path, commands: this.cloneCommands(commands),
      vertices: vertices.map((point: Point2D): Point2D => this.clonePoint(point)),
      sample: this.contourSample(path, vertices), areaMagnitude: areaMagnitude,
      parent: -1, depth: 0,
    });
  }

  private contourSample(path: drawing.Path, vertices: Point2D[]): Point2D {
    const bounds: common2D.Rect = path.getBounds();
    const width: number = Math.max(GEOMETRY_EPSILON, bounds.right - bounds.left);
    const height: number = Math.max(GEOMETRY_EPSILON, bounds.bottom - bounds.top);
    const epsilon: number = Math.max(0.0001, Math.min(width, height) * 0.0001);
    for (let index: number = 1; index < vertices.length; index++) {
      const left: Point2D = vertices[index - 1];
      const right: Point2D = vertices[index];
      const dx: number = right.x - left.x;
      const dy: number = right.y - left.y;
      const length: number = Math.sqrt(dx * dx + dy * dy);
      if (length <= GEOMETRY_EPSILON) {
        continue;
      }
      const middle: Point2D = { x: (left.x + right.x) / 2, y: (left.y + right.y) / 2 };
      const nx: number = -dy / length * epsilon;
      const ny: number = dx / length * epsilon;
      if (path.contains(middle.x + nx, middle.y + ny)) {
        return { x: middle.x + nx, y: middle.y + ny };
      }
      if (path.contains(middle.x - nx, middle.y - ny)) {
        return { x: middle.x - nx, y: middle.y - ny };
      }
    }
    for (let row: number = 1; row < 8; row++) {
      for (let column: number = 1; column < 8; column++) {
        const point: Point2D = {
          x: bounds.left + width * column / 8,
          y: bounds.top + height * row / 8,
        };
        if (path.contains(point.x, point.y)) {
          return point;
        }
      }
    }
    return { x: (bounds.left + bounds.right) / 2, y: (bounds.top + bounds.bottom) / 2 };
  }

  private pathCommands(path: drawing.Path): InkPathCommand[] {
    const contours: PathContour[] = this.pathContours(path);
    const result: InkPathCommand[] = [];
    for (const contour of contours) {
      for (const command of contour.commands) {
        result.push({ type: command.type,
          points: command.points.map((point: Point2D): Point2D => this.clonePoint(point)) });
      }
    }
    return result;
  }

  private unionPaths(outline: drawing.Path, fill: drawing.Path | null): drawing.Path | null {
    const result: drawing.Path = new drawing.Path(outline);
    if (fill !== null && !result.op(fill, drawing.PathOp.UNION)) {
      return null;
    }
    return result;
  }

  private differencePath(source: drawing.Path, eraser: drawing.Path): drawing.Path | null {
    const result: drawing.Path = new drawing.Path(source);
    return result.op(eraser, drawing.PathOp.DIFFERENCE) ? result : null;
  }

  private intersectionPath(source: drawing.Path, clip: drawing.Path): drawing.Path | null {
    const result: drawing.Path = new drawing.Path(source);
    return result.op(clip, drawing.PathOp.INTERSECT) ? result : null;
  }

  private inverseAffine(matrix: TransformMatrix): TransformMatrix | null {
    if (matrix.length !== 9 || matrix.some((value: number): boolean => !Number.isFinite(value)) ||
      Math.abs(matrix[6]) > GEOMETRY_EPSILON || Math.abs(matrix[7]) > GEOMETRY_EPSILON ||
      Math.abs(matrix[8] - 1) > GEOMETRY_EPSILON) {
      return null;
    }
    const determinant: number = matrix[0] * matrix[4] - matrix[1] * matrix[3];
    if (Math.abs(determinant) <= GEOMETRY_EPSILON) {
      return null;
    }
    const inverseA: number = matrix[4] / determinant;
    const inverseB: number = -matrix[1] / determinant;
    const inverseC: number = -matrix[3] / determinant;
    const inverseD: number = matrix[0] / determinant;
    return [
      inverseA, inverseB, -(inverseA * matrix[2] + inverseB * matrix[5]),
      inverseC, inverseD, -(inverseC * matrix[2] + inverseD * matrix[5]),
      0, 0, 1,
    ];
  }

  private inkStyle(shape: ShapeElement): InkStyle {
    return shape.originalStyle === 2 ? InkStyle.DASH :
      shape.originalStyle === 3 ? InkStyle.DOTS : InkStyle.FIXED_WIDTH;
  }

  private centerPathControlsRendering(shape: ShapeElement): boolean {
    const style: InkStyle = this.inkStyle(shape);
    return shape.originalTool === 1 || style === InkStyle.DASH || style === InkStyle.DOTS;
  }

  private styleMap(shape: ShapeElement, style: InkStyle,
    referencePoint: Point2D, phase: number): InkStyleMapEntry[] | undefined {
    if (shape.originalTool !== 1 && style !== InkStyle.DASH && style !== InkStyle.DOTS) {
      return undefined;
    }
    return [{
      backingPencilSeed: shape.originalCreate?.pencilSeed ?? ORIGINAL_PENCIL_FALLBACK_SEED,
      backingPencilReferencePoint: this.clonePoint(referencePoint),
      backingDashPhase: phase,
      backingDashPeriod: style === InkStyle.DASH ? 3 * shape.strokeWidth :
        style === InkStyle.DOTS ? 2.001 * shape.strokeWidth : 0,
    }];
  }

  private lineSegments(points: StrokePathPoint[]): CubicSegment[] {
    const result: CubicSegment[] = [];
    for (let index: number = 1; index < points.length; index++) {
      const start: Point2D = points[index - 1].position;
      const end: Point2D = points[index].position;
      result.push({
        p0: this.clonePoint(start),
        p1: { x: start.x + (end.x - start.x) / 3,
          y: start.y + (end.y - start.y) / 3 },
        p2: { x: start.x + (end.x - start.x) * 2 / 3,
          y: start.y + (end.y - start.y) * 2 / 3 },
        p3: this.clonePoint(end),
      });
    }
    return result;
  }

  private centerBounds(points: StrokePathPoint[], cubicSegments: CubicSegment[],
    transform: TransformMatrix): Rect2D {
    return this.remnantBounds(points, cubicSegments, null, null, 0, transform);
  }

  private remnantBounds(points: StrokePathPoint[], cubicSegments: CubicSegment[],
    customPath: InkPathCommand[] | null, fillPath: InkPathCommand[] | null,
    width: number, transform: TransformMatrix): Rect2D {
    let left: number = points[0].position.x;
    let top: number = points[0].position.y;
    let right: number = left;
    let bottom: number = top;
    for (const point of points) {
      left = Math.min(left, point.position.x);
      top = Math.min(top, point.position.y);
      right = Math.max(right, point.position.x);
      bottom = Math.max(bottom, point.position.y);
    }
    for (const segment of cubicSegments) {
      const controls: Point2D[] = [segment.p0, segment.p1, segment.p2, segment.p3];
      for (const point of controls) {
        left = Math.min(left, point.x);
        top = Math.min(top, point.y);
        right = Math.max(right, point.x);
        bottom = Math.max(bottom, point.y);
      }
    }
    left -= width * 2;
    top -= width * 2;
    right += width * 2;
    bottom += width * 2;
    const auxiliary: (InkPathCommand[] | null)[] = [customPath, fillPath];
    for (const commands of auxiliary) {
      if (commands === null) {
        continue;
      }
      for (const command of commands) {
        for (const point of command.points) {
          left = Math.min(left, point.x);
          top = Math.min(top, point.y);
          right = Math.max(right, point.x);
          bottom = Math.max(bottom, point.y);
        }
      }
    }
    const corners: Point2D[] = [
      { x: left, y: top }, { x: right, y: top },
      { x: right, y: bottom }, { x: left, y: bottom },
    ];
    const first: Point2D = this.transformPoint(corners[0], transform);
    const result: Rect2D = { left: first.x, top: first.y, right: first.x, bottom: first.y };
    for (let index: number = 1; index < corners.length; index++) {
      const point: Point2D = this.transformPoint(corners[index], transform);
      result.left = Math.min(result.left, point.x);
      result.top = Math.min(result.top, point.y);
      result.right = Math.max(result.right, point.x);
      result.bottom = Math.max(result.bottom, point.y);
    }
    return result;
  }

  private pathFallbackPoint(component: drawing.Path | null,
    outline: InkPathCommand[], fill: InkPathCommand[]): Point2D {
    const commands: InkPathCommand[] = outline.length > 0 ? outline : fill;
    for (const command of commands) {
      if (command.points.length > 0) {
        return this.clonePoint(command.points[command.points.length - 1]);
      }
    }
    if (component !== null) {
      const bounds: common2D.Rect = component.getBounds();
      return { x: (bounds.left + bounds.right) / 2, y: (bounds.top + bounds.bottom) / 2 };
    }
    return { x: 0, y: 0 };
  }

  private centerMidpoint(stroke: StrokeElementData): Point2D {
    return this.clonePoint(stroke.pathPoints[Math.floor(stroke.pathPoints.length / 2)].position);
  }

  private pathContainsNear(path: drawing.Path, point: Point2D): boolean {
    if (path.contains(point.x, point.y)) {
      return true;
    }
    const epsilon: number = 0.001;
    return path.contains(point.x + epsilon, point.y) ||
      path.contains(point.x - epsilon, point.y) ||
      path.contains(point.x, point.y + epsilon) || path.contains(point.x, point.y - epsilon);
  }

  private nearestComponent(entries: ComponentCenters[], point: Point2D): number {
    let result: number = -1;
    let best: number = Number.MAX_VALUE;
    for (let index: number = 0; index < entries.length; index++) {
      const bounds: common2D.Rect = entries[index].component.getBounds();
      const dx: number = point.x < bounds.left ? bounds.left - point.x :
        point.x > bounds.right ? point.x - bounds.right : 0;
      const dy: number = point.y < bounds.top ? bounds.top - point.y :
        point.y > bounds.bottom ? point.y - bounds.bottom : 0;
      const distance: number = dx * dx + dy * dy;
      if (distance < best) {
        best = distance;
        result = index;
      }
    }
    return result;
  }

  private signedArea(points: Point2D[]): number {
    let area: number = 0;
    for (let index: number = 1; index < points.length; index++) {
      area += points[index - 1].x * points[index].y -
        points[index].x * points[index - 1].y;
    }
    return area / 2;
  }

  private cloneCommands(commands: InkPathCommand[]): InkPathCommand[] {
    return commands.map((command: InkPathCommand): InkPathCommand => ({
      type: command.type,
      points: command.points.map((point: Point2D): Point2D => this.clonePoint(point)),
    }));
  }

  private clonePathPoint(point: StrokePathPoint): StrokePathPoint {
    return {
      position: this.clonePoint(point.position), widthFactor: point.widthFactor,
      pressure: point.pressure, altitudeAngleRadians: point.altitudeAngleRadians,
      azimuthUnitX: point.azimuthUnitX, azimuthUnitY: point.azimuthUnitY,
    };
  }

  private cloneSegment(segment: CubicSegment): CubicSegment {
    return {
      p0: this.clonePoint(segment.p0), p1: this.clonePoint(segment.p1),
      p2: this.clonePoint(segment.p2), p3: this.clonePoint(segment.p3),
    };
  }

  private transformPoint(point: Point2D, transform: TransformMatrix): Point2D {
    return {
      x: transform[0] * point.x + transform[1] * point.y + transform[2],
      y: transform[3] * point.x + transform[4] * point.y + transform[5],
    };
  }

  private fromDrawingPoint(point: common2D.Point): Point2D {
    return { x: point.x, y: point.y };
  }

  private maximumLinearScale(matrix: TransformMatrix): number {
    const a: number = matrix[0];
    const b: number = matrix[1];
    const c: number = matrix[3];
    const d: number = matrix[4];
    const sum: number = a * a + b * b + c * c + d * d;
    const determinant: number = a * d - b * c;
    const discriminant: number = Math.max(0,
      sum * sum - 4 * determinant * determinant);
    return Math.sqrt(Math.max(0, (sum + Math.sqrt(discriminant)) / 2));
  }

  private arrowScale(strokeWidth: number): number {
    let adjusted: number = strokeWidth;
    if (adjusted < 2) {
      adjusted = ((adjusted - 2) / 2) + 2;
    } else if (adjusted > 4) {
      adjusted = ((adjusted - 4) / 4) + 4;
    }
    return Math.max(0, adjusted) / 7;
  }

  private finitePoint(point: Point2D): boolean {
    return Number.isFinite(point.x) && Number.isFinite(point.y);
  }

  private samePoint(left: Point2D, right: Point2D): boolean {
    return Math.abs(left.x - right.x) <= GEOMETRY_EPSILON &&
      Math.abs(left.y - right.y) <= GEOMETRY_EPSILON;
  }

  private clonePoint(point: Point2D): Point2D {
    return { x: point.x, y: point.y };
  }
}
