import { common2D, drawing } from '@kit.ArkGraphics2D';
import {
  ORIGINAL_PENCIL_FALLBACK_SEED, PencilSplatGenerationResult, PencilSplatGenerator,
} from '../core/algorithm/PencilSplatGenerator';
import { OutlineResult, WidthOutlineBuilder } from '../core/algorithm/WidthOutlineBuilder';
import { CubicSegment, Point2D, Rect2D, TransformMatrix } from '../core/model/GeometryTypes';
import {
  InkPathCommand, InkPathCommandType, InkStyle, InkStyleMapEntry, RenderSpec,
  StrokeElementData, StrokePathPoint,
} from '../core/model/StrokeTypes';

const GEOMETRY_EPSILON: number = 0.000001;
const CENTER_TRANSITION_ITERATIONS: number = 20;
const CUBIC_PARAMETER_ITERATIONS: number = 24;
const MAX_CENTER_PATH_SAMPLES: number = 131072;
const MAX_COMPONENTS_PER_INK: number = 4096;
const MAX_ORIGINAL_PATH_ELEMENTS: number = 65535;
const MAX_PENCIL_SPLATS: number = 262144;
const PATH_APPROXIMATION_ERROR: number = 0.05;
const ORIGINAL_PENCIL_OUTLINE_MULTIPLIER: number = 2.84;
const MAX_AUDIO_DURATION: number = 0xFFFFFFFF;
const MAX_UNSIGNED_LONG_DECIMAL: string = '18446744073709551615';

export interface InkPartialEraseReplacement {
  sourceStroke: StrokeElementData;
  remnants: StrokeElementData[];
}

interface CenterPathRun {
  start: number;
  end: number;
}

interface CenterRemnantData {
  pathPoints: StrokePathPoint[];
  cubicSegments: CubicSegment[];
  sample: Point2D;
  startDistance: number;
  endDistance: number;
}

interface CenterMetricSegment {
  cubic: CubicSegment;
  startAttribute: StrokePathPoint;
  endAttribute: StrokePathPoint;
  startDistance: number;
  length: number;
  linear: boolean;
}

interface CenterMetrics {
  path: drawing.Path;
  segments: CenterMetricSegment[];
  totalLength: number;
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
  centers: CenterRemnantData[];
}

interface RemnantAudioTiming {
  startTime?: string;
  duration?: number | null;
}

// Android 1.0.3 jt1/n8j/o8j clips Ink in local coordinates as three separate
// paths: attributed center, explicit/generated outline, and optional fill.  It
// then materializes each visible component as a new CREATE_INK.  The HarmonyOS
// PathOp/Pen pipeline below preserves that ownership instead of flattening the
// source into sampled center-line fragments.
export class OriginalInkPartialEraser {
  private eraserWidth: number;

  constructor(eraserWidth: number) {
    this.eraserWidth = eraserWidth;
  }

  erase(eraserPath: Point2D[], strokes: StrokeElementData[]): InkPartialEraseReplacement[] {
    if (eraserPath.length === 0 || !Number.isFinite(this.eraserWidth) || this.eraserWidth <= 0) {
      return [];
    }
    const eraserOutline: drawing.Path | null = this.buildEraserOutline(eraserPath);
    if (eraserOutline === null || eraserOutline.isEmpty()) {
      return [];
    }
    const replacements: InkPartialEraseReplacement[] = [];
    for (const stroke of strokes) {
      if (stroke.renderSpec.isPartialEraser === true || stroke.maskPath.length !== 0) {
        continue;
      }
      try {
        const remnants: StrokeElementData[] | null = this.eraseStroke(eraserOutline, stroke);
        if (remnants !== null) {
          replacements.push({ sourceStroke: stroke, remnants: remnants });
        }
      } catch (_error) {
        // n8j returns Unchanged when path conversion, boolean clipping, style
        // supply, or component materialization fails.  Never turn one malformed
        // Ink into an accidental source deletion.
      }
    }
    return replacements;
  }

  private eraseStroke(eraserOutline: drawing.Path,
    stroke: StrokeElementData): StrokeElementData[] | null {
    const metrics: CenterMetrics | null = this.buildCenterMetrics(stroke);
    const inverse: TransformMatrix | null = this.inverseAffine(stroke.transform);
    if (metrics === null || inverse === null) {
      return null;
    }
    const localEraser: drawing.Path = new drawing.Path(eraserOutline);
    const inverseMatrix: drawing.Matrix = new drawing.Matrix();
    inverseMatrix.setMatrix(inverse);
    localEraser.transform(inverseMatrix);

    const outline: drawing.Path | null = this.buildInkOutline(stroke, metrics.path);
    if (outline === null) {
      return null;
    }
    const fill: drawing.Path | null = this.buildInkFill(stroke);
    const visualBefore: drawing.Path | null = this.unionPaths(outline, fill);
    if (visualBefore === null || visualBefore.isEmpty()) {
      return null;
    }
    const hit: drawing.Path | null = this.intersectionPath(visualBefore, localEraser);
    if (hit === null || hit.isEmpty()) {
      return null;
    }
    const clippedOutline: drawing.Path | null = this.differencePath(outline, localEraser);
    const clippedFill: drawing.Path | null = fill === null ? null :
      this.differencePath(fill, localEraser);
    if (clippedOutline === null || (fill !== null && clippedFill === null)) {
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
    if (components.length === 0 || components.length > MAX_COMPONENTS_PER_INK) {
      return null;
    }
    const centers: CenterRemnantData[] | null = this.centerRemnants(
      stroke, metrics, localEraser);
    if (centers === null) {
      return null;
    }
    const componentCenters: ComponentCenters[] = components.map(
      (component: drawing.Path): ComponentCenters => ({ component: component, centers: [] }));
    const unassigned: CenterRemnantData[] = [];
    for (const center of centers) {
      let target: number = -1;
      for (let index: number = 0; index < componentCenters.length; index++) {
        if (this.pathContainsNear(componentCenters[index].component, center.sample)) {
          target = index;
          break;
        }
      }
      if (target < 0) {
        target = this.nearestComponent(componentCenters, center.sample);
      }
      if (target < 0) {
        unassigned.push(center);
      } else {
        componentCenters[target].centers.push(center);
      }
    }

    const remnants: StrokeElementData[] = [];
    for (const entry of componentCenters) {
      const outlinePart: drawing.Path | null = this.intersectionPath(
        clippedOutline, entry.component);
      const fillPart: drawing.Path | null = clippedFill === null ? null :
        this.intersectionPath(clippedFill, entry.component);
      if (outlinePart === null || (clippedFill !== null && fillPart === null)) {
        return null;
      }
      const outlineCommands: InkPathCommand[] = outlinePart.isEmpty() ? [] :
        this.pathCommands(outlinePart);
      const fillCommands: InkPathCommand[] = fillPart === null || fillPart.isEmpty() ? [] :
        this.pathCommands(fillPart);
      const primary: CenterRemnantData | null = entry.centers.length === 0 ?
        null : entry.centers[0];
      remnants.push(this.buildRemnant(
        stroke, metrics, primary, entry.component, outlineCommands, fillCommands, remnants.length));
      if (this.centerPathControlsRendering(stroke)) {
        for (let index: number = 1; index < entry.centers.length; index++) {
          remnants.push(this.buildRemnant(
            stroke, metrics, entry.centers[index], entry.component,
            outlineCommands, [], remnants.length));
        }
      }
    }
    for (const center of unassigned) {
      remnants.push(this.buildRemnant(
        stroke, metrics, center, null, [], [], remnants.length));
    }
    return remnants;
  }

  private buildEraserOutline(points: Point2D[]): drawing.Path | null {
    for (const point of points) {
      if (!this.finitePoint(point)) {
        return null;
      }
    }
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

  private buildCenterMetrics(stroke: StrokeElementData): CenterMetrics | null {
    if (stroke.pathPoints.length === 0 ||
      stroke.pathPoints.some((point: StrokePathPoint): boolean =>
        !this.finitePoint(point.position))) {
      return null;
    }
    const path: drawing.Path = new drawing.Path();
    const segments: CenterMetricSegment[] = [];
    if (stroke.cubicSegments.length > 0) {
      const first: Point2D = stroke.cubicSegments[0].p0;
      if (!this.finitePoint(first) ||
        !this.samePoint(first, stroke.pathPoints[0].position)) {
        return null;
      }
      path.moveTo(first.x, first.y);
      let cumulative: number = 0;
      for (let index: number = 0; index < stroke.cubicSegments.length; index++) {
        const cubic: CubicSegment = stroke.cubicSegments[index];
        if (!this.finiteCubic(cubic) ||
          (index > 0 && !this.samePoint(
            stroke.cubicSegments[index - 1].p3, cubic.p0))) {
          return null;
        }
        path.cubicTo(cubic.p1.x, cubic.p1.y, cubic.p2.x, cubic.p2.y,
          cubic.p3.x, cubic.p3.y);
        const length: number = this.cubicLength(cubic);
        if (!Number.isFinite(length) || length < 0) {
          return null;
        }
        const startIndex: number = this.attributeIndex(
          index, stroke.cubicSegments.length, stroke.pathPoints.length);
        const endIndex: number = this.attributeIndex(
          index + 1, stroke.cubicSegments.length, stroke.pathPoints.length);
        segments.push({
          cubic: this.cloneSegment(cubic),
          startAttribute: this.clonePathPoint(stroke.pathPoints[startIndex]),
          endAttribute: this.clonePathPoint(stroke.pathPoints[endIndex]),
          startDistance: cumulative, length: length, linear: this.cubicIsLinear(cubic),
        });
        cumulative += length;
      }
      const nativeLength: number = path.getLength(false);
      return Number.isFinite(nativeLength) && nativeLength >= 0 ?
        { path: path, segments: segments, totalLength: nativeLength } : null;
    }

    path.moveTo(stroke.pathPoints[0].position.x, stroke.pathPoints[0].position.y);
    let cumulative: number = 0;
    for (let index: number = 1; index < stroke.pathPoints.length; index++) {
      const start: StrokePathPoint = stroke.pathPoints[index - 1];
      const end: StrokePathPoint = stroke.pathPoints[index];
      path.lineTo(end.position.x, end.position.y);
      const cubic: CubicSegment = this.lineCubic(start.position, end.position);
      const length: number = this.pointDistance(start.position, end.position);
      segments.push({
        cubic: cubic,
        startAttribute: this.clonePathPoint(start),
        endAttribute: this.clonePathPoint(end),
        startDistance: cumulative, length: length, linear: true,
      });
      cumulative += length;
    }
    const nativeLength: number = path.getLength(false);
    return Number.isFinite(nativeLength) && nativeLength >= 0 ?
      { path: path, segments: segments, totalLength: nativeLength } : null;
  }

  private buildInkOutline(stroke: StrokeElementData,
    centerPath: drawing.Path): drawing.Path | null {
    const custom: InkPathCommand[] | null | undefined = stroke.customPath;
    if (custom !== undefined && custom !== null && custom.length > 0) {
      // A MOVE-only custom path is the local representation used for an
      // original fill-only component. It is intentionally empty and must not
      // be mistaken for a failed path conversion when that component is
      // erased again.
      return this.pathFromCommands(custom);
    }
    const baseWidth: number = stroke.renderSpec.brushWidth *
      (stroke.renderSpec.isPencil ? ORIGINAL_PENCIL_OUTLINE_MULTIPLIER : 1);
    if (!Number.isFinite(baseWidth) || baseWidth <= 0) {
      return null;
    }
    const firstWidthFactor: number = stroke.pathPoints[0].widthFactor;
    const attributedWidth: boolean =
      stroke.renderSpec.inkStyle === InkStyle.VARIABLE_WIDTH ||
      stroke.pathPoints.some((point: StrokePathPoint): boolean =>
        Math.abs(point.widthFactor - firstWidthFactor) > GEOMETRY_EPSILON);
    if (attributedWidth) {
      const outline: OutlineResult = new WidthOutlineBuilder().build(
        stroke.pathPoints, baseWidth, stroke.cubicSegments);
      if (!outline.isValid || outline.outlinePoints.length < 3) {
        return new drawing.Path();
      }
      const path: drawing.Path = new drawing.Path();
      path.moveTo(outline.outlinePoints[0].x, outline.outlinePoints[0].y);
      for (let index: number = 1; index < outline.outlinePoints.length; index++) {
        path.lineTo(outline.outlinePoints[index].x, outline.outlinePoints[index].y);
      }
      path.close();
      return path;
    }
    const width: number = baseWidth * firstWidthFactor;
    if (!Number.isFinite(width) || width <= 0) {
      return new drawing.Path();
    }
    const nativeLength: number = centerPath.getLength(false);
    if (!Number.isFinite(nativeLength)) {
      return null;
    }
    if (nativeLength <= GEOMETRY_EPSILON) {
      const path: drawing.Path = new drawing.Path();
      path.addCircle(stroke.pathPoints[0].position.x, stroke.pathPoints[0].position.y,
        width / 2, drawing.PathDirection.CLOCKWISE);
      return path;
    }
    const pen: drawing.Pen = new drawing.Pen();
    pen.setStrokeWidth(width);
    pen.setCapStyle(drawing.CapStyle.ROUND_CAP);
    pen.setJoinStyle(drawing.JoinStyle.ROUND_JOIN);
    const outline: drawing.Path = new drawing.Path();
    return pen.getFillPath(centerPath, outline) ? outline : null;
  }

  private buildInkFill(stroke: StrokeElementData): drawing.Path | null {
    if (stroke.fillColor === undefined || stroke.fillColor === null ||
      stroke.fillPath === undefined || stroke.fillPath === null ||
      stroke.fillPath.length === 0) {
      return null;
    }
    const fill: drawing.Path | null = this.pathFromCommands(stroke.fillPath);
    if (fill === null) {
      throw new Error('Ink fill path conversion failed');
    }
    return fill;
  }

  private pathFromCommands(commands: InkPathCommand[]): drawing.Path | null {
    const path: drawing.Path = new drawing.Path();
    let current: Point2D | null = null;
    for (const command of commands) {
      for (const point of command.points) {
        if (!this.finitePoint(point)) {
          return null;
        }
      }
      if (command.type === InkPathCommandType.MOVE_TO && command.points.length === 1) {
        current = this.clonePoint(command.points[0]);
        path.moveTo(current.x, current.y);
      } else if (current !== null && command.type === InkPathCommandType.LINE_TO &&
        command.points.length === 1) {
        current = this.clonePoint(command.points[0]);
        path.lineTo(current.x, current.y);
      } else if (current !== null && command.type === InkPathCommandType.QUADRATIC &&
        command.points.length === 2) {
        const control: Point2D = command.points[0];
        current = this.clonePoint(command.points[1]);
        path.quadTo(control.x, control.y, current.x, current.y);
      } else if (current !== null && command.type === InkPathCommandType.CUBIC &&
        command.points.length === 3) {
        const control1: Point2D = command.points[0];
        const control2: Point2D = command.points[1];
        current = this.clonePoint(command.points[2]);
        path.cubicTo(control1.x, control1.y, control2.x, control2.y,
          current.x, current.y);
      } else {
        return null;
      }
    }
    return path;
  }

  private centerRemnants(stroke: StrokeElementData, metrics: CenterMetrics,
    eraserPath: drawing.Path): CenterRemnantData[] | null {
    const length: number = metrics.totalLength;
    if (length <= GEOMETRY_EPSILON) {
      const point: StrokePathPoint = this.clonePathPoint(stroke.pathPoints[0]);
      return eraserPath.contains(point.position.x, point.position.y) ? [] : [{
        pathPoints: [point], cubicSegments: [], sample: this.clonePoint(point.position),
        startDistance: 0, endDistance: 0,
      }];
    }
    const scale: number = this.maximumLinearScale(stroke.transform);
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
      const value: boolean | null = this.centerDistanceIsErased(
        metrics.path, eraserPath, distance);
      if (value === null) {
        return null;
      }
      erased.push(value);
      hasErased = hasErased || value;
      hasOutside = hasOutside || !value;
    }
    if (!hasErased) {
      const sample: Point2D | null = this.pathPosition(metrics.path, length / 2);
      return sample === null ? null : [{
        pathPoints: stroke.pathPoints.map(
          (point: StrokePathPoint): StrokePathPoint => this.clonePathPoint(point)),
        cubicSegments: stroke.cubicSegments.length > 0 ? stroke.cubicSegments.map(
          (segment: CubicSegment): CubicSegment => this.cloneSegment(segment)) :
          this.lineSegments(stroke.pathPoints),
        sample: sample, startDistance: 0, endDistance: length,
      }];
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
          metrics.path, eraserPath, previousDistance, distance, false);
        if (boundary === null || runStart < 0) {
          return null;
        }
        if (boundary - runStart > GEOMETRY_EPSILON) {
          runs.push({ start: runStart, end: boundary });
        }
        runStart = -1;
      } else if (erased[index - 1] && !erased[index]) {
        const boundary: number | null = this.centerTransitionDistance(
          metrics.path, eraserPath, previousDistance, distance, true);
        if (boundary === null) {
          return null;
        }
        runStart = boundary;
      }
    }
    if (runStart >= 0 && length - runStart > GEOMETRY_EPSILON) {
      runs.push({ start: runStart, end: length });
    }
    const result: CenterRemnantData[] = [];
    for (const run of runs) {
      const remnantPath: drawing.Path = new drawing.Path();
      if (!metrics.path.getSegment(false, run.start, run.end, true, remnantPath) ||
        remnantPath.isEmpty()) {
        return null;
      }
      const data: CenterRemnantData | null = this.centerPathData(
        metrics, remnantPath, run.start, run.end);
      if (data === null) {
        return null;
      }
      result.push(data);
    }
    return result;
  }

  private centerPathData(metrics: CenterMetrics, path: drawing.Path,
    startDistance: number, endDistance: number): CenterRemnantData | null {
    const iterator: drawing.PathIterator = path.getPathIterator();
    const points: common2D.Point[] = [
      { x: 0, y: 0 }, { x: 0, y: 0 }, { x: 0, y: 0 }, { x: 0, y: 0 },
    ];
    const pathPoints: StrokePathPoint[] = [];
    const cubicSegments: CubicSegment[] = [];
    let current: Point2D | null = null;
    let contourStart: Point2D | null = null;
    let localDistance: number = 0;
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
        pathPoints.push(this.attributeAtDistance(metrics, startDistance, current));
        hasContour = true;
      } else if (current !== null && verb === drawing.PathIteratorVerb.LINE) {
        const end: Point2D = this.fromDrawingPoint(points[1]);
        localDistance += this.pointDistance(current, end);
        cubicSegments.push(this.lineCubic(current, end));
        pathPoints.push(this.attributeAtDistance(
          metrics, Math.min(endDistance, startDistance + localDistance), end));
        current = end;
      } else if (current !== null && verb === drawing.PathIteratorVerb.QUAD) {
        const control: Point2D = this.fromDrawingPoint(points[1]);
        const end: Point2D = this.fromDrawingPoint(points[2]);
        const cubic: CubicSegment = this.quadraticCubic(current, control, end);
        localDistance += this.cubicLength(cubic);
        cubicSegments.push(cubic);
        pathPoints.push(this.attributeAtDistance(
          metrics, Math.min(endDistance, startDistance + localDistance), end));
        current = end;
      } else if (current !== null && verb === drawing.PathIteratorVerb.CUBIC) {
        const cubic: CubicSegment = {
          p0: this.clonePoint(current), p1: this.fromDrawingPoint(points[1]),
          p2: this.fromDrawingPoint(points[2]), p3: this.fromDrawingPoint(points[3]),
        };
        localDistance += this.cubicLength(cubic);
        cubicSegments.push(cubic);
        pathPoints.push(this.attributeAtDistance(
          metrics, Math.min(endDistance, startDistance + localDistance), cubic.p3));
        current = cubic.p3;
      } else if (current !== null && contourStart !== null &&
        verb === drawing.PathIteratorVerb.CLOSE) {
        if (!this.samePoint(current, contourStart)) {
          localDistance += this.pointDistance(current, contourStart);
          cubicSegments.push(this.lineCubic(current, contourStart));
          pathPoints.push(this.attributeAtDistance(
            metrics, Math.min(endDistance, startDistance + localDistance), contourStart));
          current = contourStart;
        }
      } else {
        // getSegment() of the Ink center is expected to retain line/quad/cubic
        // verbs.  A conic without its rational weight cannot be serialized
        // faithfully, so match n8j's fail-closed Unchanged behavior.
        return null;
      }
    }
    const sample: Point2D | null = this.pathPosition(
      metrics.path, (startDistance + endDistance) / 2);
    return pathPoints.length === 0 || sample === null ? null : {
      pathPoints: pathPoints, cubicSegments: cubicSegments, sample: sample,
      startDistance: startDistance, endDistance: endDistance,
    };
  }

  private attributeAtDistance(metrics: CenterMetrics, distance: number,
    position: Point2D): StrokePathPoint {
    if (metrics.segments.length === 0) {
      return {
        position: this.clonePoint(position), widthFactor: 1, pressure: 1,
        altitudeAngleRadians: Math.PI / 2, azimuthUnitX: 1, azimuthUnitY: 0,
      };
    }
    const bounded: number = Math.max(0, Math.min(metrics.totalLength, distance));
    let metric: CenterMetricSegment = metrics.segments[metrics.segments.length - 1];
    for (const candidate of metrics.segments) {
      if (bounded <= candidate.startDistance + candidate.length + GEOMETRY_EPSILON) {
        metric = candidate;
        break;
      }
    }
    const local: number = Math.max(0, Math.min(metric.length,
      bounded - metric.startDistance));
    let t: number;
    if (metric.length <= GEOMETRY_EPSILON) {
      t = 0;
    } else if (metric.linear) {
      t = local / metric.length;
    } else {
      t = this.cubicParameterAtLength(metric.cubic, local, metric.length);
    }
    return this.interpolatePathPoint(
      metric.startAttribute, metric.endAttribute, t, position);
  }

  private buildRemnant(source: StrokeElementData, metrics: CenterMetrics,
    center: CenterRemnantData | null, component: drawing.Path | null,
    outlineCommands: InkPathCommand[], fillCommands: InkPathCommand[],
    index: number): StrokeElementData {
    const fallback: Point2D = center === null ?
      this.pathFallbackPoint(component, outlineCommands, fillCommands) :
      this.clonePoint(center.pathPoints[0].position);
    const pathPoints: StrokePathPoint[] = center === null ? [{
      position: fallback, widthFactor: 1, pressure: 1,
      altitudeAngleRadians: Math.PI / 2, azimuthUnitX: 1, azimuthUnitY: 0,
    }] : center.pathPoints.map(
      (point: StrokePathPoint): StrokePathPoint => this.clonePathPoint(point));
    const cubicSegments: CubicSegment[] = center === null ? [] :
      center.cubicSegments.map(
        (segment: CubicSegment): CubicSegment => this.cloneSegment(segment));
    const styleMap: InkStyleMapEntry[] | undefined = center === null ?
      undefined : this.remnantStyleMap(source, metrics, center);
    const customPath: InkPathCommand[] | null = outlineCommands.length > 0 ?
      this.cloneCommands(outlineCommands) : fillCommands.length > 0 ? [{
        type: InkPathCommandType.MOVE_TO, points: [this.clonePoint(fallback)],
      }] : null;
    const clippedFill: InkPathCommand[] | null = fillCommands.length === 0 ?
      null : this.cloneCommands(fillCommands);
    const audio: RemnantAudioTiming = center === null ? {
      startTime: source.audioStartTime, duration: source.audioDuration,
    } : this.remnantAudioTiming(
      source, center.startDistance, center.endDistance, metrics.totalLength);
    const renderSpec: RenderSpec = this.remnantRenderSpec(source, styleMap);
    const outlineWidth: number = renderSpec.brushWidth *
      (renderSpec.isPencil ? ORIGINAL_PENCIL_OUTLINE_MULTIPLIER : 1);
    const stroke: StrokeElementData = {
      id: `${source.id}#erase-${index}`,
      pathPoints: pathPoints, cubicSegments: cubicSegments, splatPoints: [],
      renderSpec: renderSpec,
      transform: source.transform.slice(),
      bounds: this.remnantBounds(pathPoints, cubicSegments, customPath,
        clippedFill, outlineWidth, source.transform),
      maskPath: [], customPath: customPath, fillPath: clippedFill,
      fillColor: clippedFill === null ? null : source.fillColor,
      styleMap: styleMap,
      audioStartTime: audio.startTime, audioDuration: audio.duration,
      isFinished: true,
    };
    if (stroke.renderSpec.isPencil && stroke.cubicSegments.length > 0) {
      const generator: PencilSplatGenerator = new PencilSplatGenerator({
        spacing: stroke.renderSpec.brushWidth, maximumSplatCount: MAX_PENCIL_SPLATS,
      });
      const style: InkStyleMapEntry | undefined = styleMap === undefined ||
        styleMap.length === 0 ? undefined : styleMap[0];
      generator.reset(style === undefined ? ORIGINAL_PENCIL_FALLBACK_SEED :
        style.backingPencilSeed);
      const reference: Point2D | undefined = style === undefined ||
        this.zeroPoint(style.backingPencilReferencePoint) ? undefined :
        style.backingPencilReferencePoint;
      stroke.splatPoints = generator.generate(
        stroke.cubicSegments, stroke.pathPoints, undefined, reference);
    }
    return stroke;
  }

  private remnantRenderSpec(source: StrokeElementData,
    styleMap: InkStyleMapEntry[] | undefined): RenderSpec {
    let phase: number | undefined = source.renderSpec.inkEffectPhase;
    if (styleMap !== undefined && styleMap.length > 0 &&
      (source.renderSpec.inkStyle === InkStyle.DASH ||
        source.renderSpec.inkStyle === InkStyle.DOTS)) {
      phase = styleMap[0].backingDashPhase;
    }
    return {
      color: source.renderSpec.color,
      brushWidth: source.renderSpec.brushWidth,
      inkStyle: source.renderSpec.inkStyle,
      isHighlighter: source.renderSpec.isHighlighter,
      isPencil: source.renderSpec.isPencil,
      inkEffects: source.renderSpec.inkEffects,
      inkEffectsTinted: source.renderSpec.inkEffectsTinted,
      inkEffectPhase: phase,
      tapePattern: source.renderSpec.tapePattern,
    };
  }

  private remnantStyleMap(source: StrokeElementData, metrics: CenterMetrics,
    center: CenterRemnantData): InkStyleMapEntry[] | undefined {
    const sourceEntry: InkStyleMapEntry | undefined = source.styleMap === undefined ||
      source.styleMap.length === 0 ? undefined : source.styleMap[0];
    const wholeSource: boolean = center.startDistance <= GEOMETRY_EPSILON &&
      center.endDistance >= metrics.totalLength - GEOMETRY_EPSILON;
    if (wholeSource) {
      return this.styleMapEntry(sourceEntry);
    }
    if (source.renderSpec.isPencil) {
      return this.styleMapEntry(this.pencilStyleAtDistance(
        source, metrics, sourceEntry, center.startDistance));
    }
    if (source.renderSpec.inkStyle !== InkStyle.DASH &&
      source.renderSpec.inkStyle !== InkStyle.DOTS) {
      // o8j emits its all-zero yyd default when a non-pattern center component
      // is sliced; the all-default vector is then omitted from CREATE_INK.
      return undefined;
    }
    const period: number = source.renderSpec.inkStyle === InkStyle.DASH ?
      3 * source.renderSpec.brushWidth : 2.001 * source.renderSpec.brushWidth;
    const basePhase: number = sourceEntry === undefined ?
      (source.renderSpec.inkEffectPhase ?? 0) : sourceEntry.backingDashPhase;
    const phase: number = period > 0 ?
      ((basePhase + center.startDistance) % period + period) % period : 0;
    return this.styleMapEntry({
      // uyd carries only the advanced dash phase. o8j deliberately resets
      // Pencil state and preserves only the source period register.
      backingPencilSeed: 0,
      backingPencilReferencePoint: { x: 0, y: 0 },
      backingDashPhase: phase,
      backingDashPeriod: sourceEntry === undefined ? 0 : sourceEntry.backingDashPeriod,
    });
  }

  private pencilStyleAtDistance(source: StrokeElementData, metrics: CenterMetrics,
    sourceEntry: InkStyleMapEntry | undefined, startDistance: number): InkStyleMapEntry {
    const seed: number = sourceEntry === undefined ?
      ORIGINAL_PENCIL_FALLBACK_SEED : sourceEntry.backingPencilSeed;
    const sourceReference: Point2D | undefined = sourceEntry === undefined ||
      this.zeroPoint(sourceEntry.backingPencilReferencePoint) ? undefined :
      sourceEntry.backingPencilReferencePoint;
    let finalSeed: number = seed;
    let finalReference: Point2D | undefined = sourceReference === undefined ? undefined :
      this.clonePoint(sourceReference);
    if (startDistance > GEOMETRY_EPSILON && metrics.segments.length > 0) {
      const prefixPath: drawing.Path = new drawing.Path();
      if (!metrics.path.getSegment(false, 0,
        Math.min(metrics.totalLength, startDistance), true, prefixPath)) {
        throw new Error('Pencil prefix extraction failed');
      }
      const prefix: CenterRemnantData | null = this.centerPathData(
        metrics, prefixPath, 0, Math.min(metrics.totalLength, startDistance));
      if (prefix === null || prefix.cubicSegments.length === 0) {
        throw new Error('Pencil prefix conversion failed');
      }
      const generator: PencilSplatGenerator = new PencilSplatGenerator({
        spacing: source.renderSpec.brushWidth, maximumSplatCount: MAX_PENCIL_SPLATS,
      });
      generator.reset(seed);
      const generated: PencilSplatGenerationResult = generator.generateWithState(
        prefix.cubicSegments, prefix.pathPoints, undefined, sourceReference);
      finalSeed = generated.state.finalSeed;
      if (generated.state.finalReferencePoint !== undefined) {
        finalReference = generated.state.finalReferencePoint;
      }
    }
    return {
      backingPencilSeed: finalSeed,
      backingPencilReferencePoint: finalReference === undefined ? { x: 0, y: 0 } :
        this.clonePoint(finalReference),
      // vyd is materialized by o8j as Pencil seed/reference plus zeroed Dash
      // registers, irrespective of unrelated values on the source entry.
      backingDashPhase: 0,
      backingDashPeriod: 0,
    };
  }

  private remnantAudioTiming(source: StrokeElementData, startDistance: number,
    endDistance: number, totalDistance: number): RemnantAudioTiming {
    const sourceDuration: number | null | undefined = source.audioDuration;
    if (sourceDuration === undefined || sourceDuration === null ||
      totalDistance <= GEOMETRY_EPSILON) {
      return { startTime: source.audioStartTime, duration: sourceDuration };
    }
    const boundedDuration: number = Math.max(0, Math.min(MAX_AUDIO_DURATION,
      Math.round(sourceDuration)));
    const startRatio: number = Math.max(0, Math.min(1, startDistance / totalDistance));
    const endRatio: number = Math.max(startRatio,
      Math.min(1, endDistance / totalDistance));
    const startOffset: number = Math.max(0, Math.min(MAX_AUDIO_DURATION,
      Math.round(startRatio * boundedDuration)));
    const duration: number = Math.max(0, Math.min(MAX_AUDIO_DURATION,
      Math.round((endRatio - startRatio) * boundedDuration)));
    return {
      startTime: this.shiftAudioStart(source.audioStartTime, startOffset),
      duration: duration,
    };
  }

  private shiftAudioStart(value: string | undefined, amount: number): string | undefined {
    if (value === undefined || amount <= 0 || !Number.isSafeInteger(amount) ||
      value.length === 0 || value.length > MAX_UNSIGNED_LONG_DECIMAL.length) {
      return value;
    }
    const digits: number[] = [];
    for (let index: number = 0; index < value.length; index++) {
      const digit: number = value.charCodeAt(index) - 0x30;
      if (digit < 0 || digit > 9) {
        return value;
      }
      digits.push(digit);
    }
    let carry: number = amount;
    for (let index: number = digits.length - 1; index >= 0 && carry > 0; index--) {
      const sum: number = digits[index] + carry;
      digits[index] = sum % 10;
      carry = Math.floor(sum / 10);
    }
    while (carry > 0) {
      digits.unshift(carry % 10);
      carry = Math.floor(carry / 10);
    }
    const shifted: string = digits.join('');
    if (shifted.length > MAX_UNSIGNED_LONG_DECIMAL.length ||
      (shifted.length === MAX_UNSIGNED_LONG_DECIMAL.length &&
        shifted > MAX_UNSIGNED_LONG_DECIMAL)) {
      return value;
    }
    return shifted;
  }

  private centerDistanceIsErased(centerPath: drawing.Path,
    eraserPath: drawing.Path, distance: number): boolean | null {
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
      const erased: boolean | null = this.centerDistanceIsErased(
        centerPath, eraserPath, middle);
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

  private pathPosition(path: drawing.Path, distance: number): Point2D | null {
    const position: common2D.Point = { x: 0, y: 0 };
    const tangent: common2D.Point = { x: 0, y: 0 };
    return path.getPositionAndTangent(false, distance, position, tangent) ?
      { x: position.x, y: position.y } : null;
  }

  private centerPathControlsRendering(stroke: StrokeElementData): boolean {
    return stroke.renderSpec.isPencil ||
      stroke.renderSpec.inkStyle === InkStyle.DASH ||
      stroke.renderSpec.inkStyle === InkStyle.DOTS;
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
          contours[candidate].areaMagnitude <=
            contours[index].areaMagnitude + GEOMETRY_EPSILON) {
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
        if (contours[child].parent === index &&
          contours[child].depth === contours[index].depth + 1) {
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
        commands = [{ type: InkPathCommandType.MOVE_TO,
          points: [this.clonePoint(point)] }];
        vertices = [this.clonePoint(point)];
        start = point;
        last = point;
      } else if (currentPath !== null && verb === drawing.PathIteratorVerb.LINE) {
        const point: Point2D = this.fromDrawingPoint(points[1]);
        currentPath.lineTo(point.x, point.y);
        commands.push({ type: InkPathCommandType.LINE_TO,
          points: [this.clonePoint(point)] });
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
        currentPath.cubicTo(control1.x, control1.y, control2.x, control2.y,
          end.x, end.y);
        commands.push({ type: InkPathCommandType.CUBIC,
          points: [this.clonePoint(control1), this.clonePoint(control2),
            this.clonePoint(end)] });
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
      throw new Error('Ink auxiliary path approximation exceeds the original path budget');
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
        throw new Error('Ink auxiliary path approximation is invalid');
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
        commands = [{ type: InkPathCommandType.MOVE_TO,
          points: [this.clonePoint(point)] }];
        vertices = [this.clonePoint(point)];
        start = point;
        last = point;
      } else if (currentPath !== null && last !== null &&
        !this.samePoint(last, point)) {
        currentPath.lineTo(point.x, point.y);
        commands.push({ type: InkPathCommandType.LINE_TO,
          points: [this.clonePoint(point)] });
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
      commands.push({ type: InkPathCommandType.LINE_TO,
        points: [this.clonePoint(start)] });
      vertices.push(this.clonePoint(start));
    }
    if (commands.length > MAX_ORIGINAL_PATH_ELEMENTS) {
      throw new Error('Ink auxiliary path exceeds the original path budget');
    }
    contours.push({
      path: path,
      commands: this.cloneCommands(commands),
      vertices: vertices.map(
        (point: Point2D): Point2D => this.clonePoint(point)),
      sample: this.contourSample(path, vertices),
      areaMagnitude: Math.abs(this.signedArea(vertices)), parent: -1, depth: 0,
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
      const middle: Point2D = {
        x: (left.x + right.x) / 2, y: (left.y + right.y) / 2,
      };
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
    return { x: (bounds.left + bounds.right) / 2,
      y: (bounds.top + bounds.bottom) / 2 };
  }

  private pathCommands(path: drawing.Path): InkPathCommand[] {
    const contours: PathContour[] = this.pathContours(path);
    const result: InkPathCommand[] = [];
    for (const contour of contours) {
      for (const command of contour.commands) {
        result.push({ type: command.type,
          points: command.points.map(
            (point: Point2D): Point2D => this.clonePoint(point)) });
      }
    }
    if (result.length > MAX_ORIGINAL_PATH_ELEMENTS) {
      throw new Error('Ink auxiliary path exceeds the original path budget');
    }
    return result;
  }

  private unionPaths(outline: drawing.Path,
    fill: drawing.Path | null): drawing.Path | null {
    if (outline.isEmpty()) {
      return fill === null ? new drawing.Path() : new drawing.Path(fill);
    }
    const result: drawing.Path = new drawing.Path(outline);
    if (fill !== null && !result.op(fill, drawing.PathOp.UNION)) {
      return null;
    }
    return result;
  }

  private differencePath(source: drawing.Path,
    eraser: drawing.Path): drawing.Path | null {
    if (source.isEmpty()) {
      return new drawing.Path();
    }
    const result: drawing.Path = new drawing.Path(source);
    return result.op(eraser, drawing.PathOp.DIFFERENCE) ? result : null;
  }

  private intersectionPath(source: drawing.Path,
    clip: drawing.Path): drawing.Path | null {
    if (source.isEmpty() || clip.isEmpty()) {
      return new drawing.Path();
    }
    const result: drawing.Path = new drawing.Path(source);
    return result.op(clip, drawing.PathOp.INTERSECT) ? result : null;
  }

  private inverseAffine(matrix: TransformMatrix): TransformMatrix | null {
    if (matrix.length !== 9 ||
      matrix.some((value: number): boolean => !Number.isFinite(value)) ||
      Math.abs(matrix[6]) > GEOMETRY_EPSILON ||
      Math.abs(matrix[7]) > GEOMETRY_EPSILON ||
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

  private remnantBounds(points: StrokePathPoint[], cubicSegments: CubicSegment[],
    customPath: InkPathCommand[] | null, fillPath: InkPathCommand[] | null,
    outlineWidth: number, transform: TransformMatrix): Rect2D {
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
      for (const point of [segment.p0, segment.p1, segment.p2, segment.p3]) {
        left = Math.min(left, point.x);
        top = Math.min(top, point.y);
        right = Math.max(right, point.x);
        bottom = Math.max(bottom, point.y);
      }
    }
    const padding: number = Math.max(0, outlineWidth) * 2;
    left -= padding;
    top -= padding;
    right += padding;
    bottom += padding;
    for (const commands of [customPath, fillPath]) {
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
    const result: Rect2D = {
      left: first.x, top: first.y, right: first.x, bottom: first.y,
    };
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
      return { x: (bounds.left + bounds.right) / 2,
        y: (bounds.top + bounds.bottom) / 2 };
    }
    return { x: 0, y: 0 };
  }

  private pathContainsNear(path: drawing.Path, point: Point2D): boolean {
    if (path.contains(point.x, point.y)) {
      return true;
    }
    const epsilon: number = 0.001;
    return path.contains(point.x + epsilon, point.y) ||
      path.contains(point.x - epsilon, point.y) ||
      path.contains(point.x, point.y + epsilon) ||
      path.contains(point.x, point.y - epsilon);
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

  private cubicParameterAtLength(segment: CubicSegment, target: number,
    total: number): number {
    if (target <= GEOMETRY_EPSILON) {
      return 0;
    }
    if (target >= total - GEOMETRY_EPSILON) {
      return 1;
    }
    let low: number = 0;
    let high: number = 1;
    for (let iteration: number = 0; iteration < CUBIC_PARAMETER_ITERATIONS; iteration++) {
      const middle: number = (low + high) / 2;
      const prefix: CubicSegment = this.splitCubic(segment, middle).left;
      const length: number = this.cubicLength(prefix);
      if (length < target) {
        low = middle;
      } else {
        high = middle;
      }
    }
    return (low + high) / 2;
  }

  private splitCubic(segment: CubicSegment, t: number): CubicSplit {
    const p01: Point2D = this.lerpPoint(segment.p0, segment.p1, t);
    const p12: Point2D = this.lerpPoint(segment.p1, segment.p2, t);
    const p23: Point2D = this.lerpPoint(segment.p2, segment.p3, t);
    const p012: Point2D = this.lerpPoint(p01, p12, t);
    const p123: Point2D = this.lerpPoint(p12, p23, t);
    const middle: Point2D = this.lerpPoint(p012, p123, t);
    return {
      left: {
        p0: this.clonePoint(segment.p0), p1: p01, p2: p012, p3: middle,
      },
      right: {
        p0: middle, p1: p123, p2: p23, p3: this.clonePoint(segment.p3),
      },
    };
  }

  private cubicLength(segment: CubicSegment): number {
    const path: drawing.Path = new drawing.Path();
    path.moveTo(segment.p0.x, segment.p0.y);
    path.cubicTo(segment.p1.x, segment.p1.y, segment.p2.x, segment.p2.y,
      segment.p3.x, segment.p3.y);
    return path.getLength(false);
  }

  private cubicIsLinear(segment: CubicSegment): boolean {
    const dx: number = segment.p3.x - segment.p0.x;
    const dy: number = segment.p3.y - segment.p0.y;
    const cross1: number = dx * (segment.p1.y - segment.p0.y) -
      dy * (segment.p1.x - segment.p0.x);
    const cross2: number = dx * (segment.p2.y - segment.p0.y) -
      dy * (segment.p2.x - segment.p0.x);
    return Math.abs(cross1) <= GEOMETRY_EPSILON &&
      Math.abs(cross2) <= GEOMETRY_EPSILON;
  }

  private attributeIndex(index: number, segmentCount: number,
    pointCount: number): number {
    return Math.min(pointCount - 1,
      Math.max(0, Math.round(index * (pointCount - 1) / segmentCount)));
  }

  private interpolatePathPoint(start: StrokePathPoint, end: StrokePathPoint,
    t: number, position: Point2D): StrokePathPoint {
    const azimuthX: number = start.azimuthUnitX +
      (end.azimuthUnitX - start.azimuthUnitX) * t;
    const azimuthY: number = start.azimuthUnitY +
      (end.azimuthUnitY - start.azimuthUnitY) * t;
    const azimuthLength: number = Math.sqrt(azimuthX * azimuthX + azimuthY * azimuthY);
    return {
      position: this.clonePoint(position),
      widthFactor: start.widthFactor + (end.widthFactor - start.widthFactor) * t,
      pressure: start.pressure + (end.pressure - start.pressure) * t,
      altitudeAngleRadians: start.altitudeAngleRadians +
        (end.altitudeAngleRadians - start.altitudeAngleRadians) * t,
      azimuthUnitX: azimuthLength <= GEOMETRY_EPSILON ? 0 : azimuthX / azimuthLength,
      azimuthUnitY: azimuthLength <= GEOMETRY_EPSILON ? 0 : azimuthY / azimuthLength,
    };
  }

  private quadraticCubic(start: Point2D, control: Point2D,
    end: Point2D): CubicSegment {
    return {
      p0: this.clonePoint(start),
      p1: { x: start.x + (control.x - start.x) * 2 / 3,
        y: start.y + (control.y - start.y) * 2 / 3 },
      p2: { x: end.x + (control.x - end.x) * 2 / 3,
        y: end.y + (control.y - end.y) * 2 / 3 },
      p3: this.clonePoint(end),
    };
  }

  private lineCubic(start: Point2D, end: Point2D): CubicSegment {
    return {
      p0: this.clonePoint(start),
      p1: { x: start.x + (end.x - start.x) / 3,
        y: start.y + (end.y - start.y) / 3 },
      p2: { x: start.x + (end.x - start.x) * 2 / 3,
        y: start.y + (end.y - start.y) * 2 / 3 },
      p3: this.clonePoint(end),
    };
  }

  private lineSegments(points: StrokePathPoint[]): CubicSegment[] {
    const result: CubicSegment[] = [];
    for (let index: number = 1; index < points.length; index++) {
      result.push(this.lineCubic(
        points[index - 1].position, points[index].position));
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

  private transformPoint(point: Point2D, transform: TransformMatrix): Point2D {
    return {
      x: transform[0] * point.x + transform[1] * point.y + transform[2],
      y: transform[3] * point.x + transform[4] * point.y + transform[5],
    };
  }

  private cloneStyleEntry(entry: InkStyleMapEntry): InkStyleMapEntry {
    return {
      backingPencilSeed: entry.backingPencilSeed,
      backingPencilReferencePoint: this.clonePoint(entry.backingPencilReferencePoint),
      backingDashPhase: entry.backingDashPhase,
      backingDashPeriod: entry.backingDashPeriod,
    };
  }

  private styleMapEntry(entry: InkStyleMapEntry | undefined):
    InkStyleMapEntry[] | undefined {
    if (entry === undefined ||
      entry.backingPencilSeed === 0 &&
      this.zeroPoint(entry.backingPencilReferencePoint) &&
      entry.backingDashPhase === 0 && entry.backingDashPeriod === 0) {
      return undefined;
    }
    return [this.cloneStyleEntry(entry)];
  }

  private cloneCommands(commands: InkPathCommand[]): InkPathCommand[] {
    return commands.map((command: InkPathCommand): InkPathCommand => ({
      type: command.type,
      points: command.points.map(
        (point: Point2D): Point2D => this.clonePoint(point)),
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

  private fromDrawingPoint(point: common2D.Point): Point2D {
    return { x: point.x, y: point.y };
  }

  private pointDistance(start: Point2D, end: Point2D): number {
    const dx: number = end.x - start.x;
    const dy: number = end.y - start.y;
    return Math.sqrt(dx * dx + dy * dy);
  }

  private lerpPoint(start: Point2D, end: Point2D, t: number): Point2D {
    return { x: start.x + (end.x - start.x) * t,
      y: start.y + (end.y - start.y) * t };
  }

  private finiteCubic(segment: CubicSegment): boolean {
    return this.finitePoint(segment.p0) && this.finitePoint(segment.p1) &&
      this.finitePoint(segment.p2) && this.finitePoint(segment.p3);
  }

  private finitePoint(point: Point2D): boolean {
    return Number.isFinite(point.x) && Number.isFinite(point.y);
  }

  private zeroPoint(point: Point2D): boolean {
    return point.x === 0 && point.y === 0;
  }

  private samePoint(left: Point2D, right: Point2D): boolean {
    return Math.abs(left.x - right.x) <= GEOMETRY_EPSILON &&
      Math.abs(left.y - right.y) <= GEOMETRY_EPSILON;
  }

  private clonePoint(point: Point2D): Point2D {
    return { x: point.x, y: point.y };
  }
}

interface CubicSplit {
  left: CubicSegment;
  right: CubicSegment;
}
