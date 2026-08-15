import { Point2D } from '../core/model/GeometryTypes';
import {
  InkStyle, StrokeElementData, StrokePathPoint,
} from '../core/model/StrokeTypes';

export const MAX_ORIGINAL_PARTIAL_ERASER_PREVIEW_POINTS: number = 65535;

export enum OriginalPartialEraserPreviewPhase {
  IDLE = 0,
  TRACKING = 1,
  AWAITING_COMMIT = 2,
}

// Android 1.0.3 creates a transient tool-5 Ink at pointer-down, appends its
// path while the gesture is active, and ends that interaction only after the
// durable partial-erase replacement has been dispatched (kt1/bt1/dh5/wc).
// This class owns the equivalent non-persistent local preview. It deliberately
// exposes no persistence representation: callers may render the current Ink
// or copy its center path for the final boolean clip, but must never append it
// to the page element arrays or operation log.
export class OriginalPartialEraserTransientPreview {
  private phase: OriginalPartialEraserPreviewPhase = OriginalPartialEraserPreviewPhase.IDLE;
  private points: Point2D[] = [];
  private previewStroke: StrokeElementData | null = null;
  private nextToken: number = 0;
  private activeToken: number = 0;
  private failed: boolean = false;
  private maxPoints: number;

  constructor(maxPoints: number = MAX_ORIGINAL_PARTIAL_ERASER_PREVIEW_POINTS) {
    if (!Number.isSafeInteger(maxPoints) || maxPoints < 1 ||
      maxPoints > MAX_ORIGINAL_PARTIAL_ERASER_PREVIEW_POINTS) {
      throw new Error('partial eraser preview point budget is invalid');
    }
    this.maxPoints = maxPoints;
  }

  begin(point: Point2D, width: number): number {
    if (!this.finitePoint(point) || !Number.isFinite(width) || width <= 0) {
      throw new Error('partial eraser preview start is invalid');
    }
    this.nextToken = this.nextToken >= Number.MAX_SAFE_INTEGER ? 1 : this.nextToken + 1;
    this.activeToken = this.nextToken;
    this.phase = OriginalPartialEraserPreviewPhase.TRACKING;
    this.failed = false;
    const initial: Point2D = this.clonePoint(point);
    this.points = [initial];
    const halfWidth: number = width / 2;
    this.previewStroke = {
      id: `transient-partial-eraser-${this.activeToken}`,
      pathPoints: [this.strokePoint(initial)],
      cubicSegments: [],
      splatPoints: [],
      renderSpec: {
        color: 0xFF000000 | 0,
        brushWidth: width,
        inkStyle: InkStyle.FIXED_WIDTH,
        isHighlighter: false,
        isPencil: false,
        isPartialEraser: true,
      },
      transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
      bounds: {
        left: initial.x - halfWidth,
        top: initial.y - halfWidth,
        right: initial.x + halfWidth,
        bottom: initial.y + halfWidth,
      },
      maskPath: [],
      isFinished: false,
    };
    return this.activeToken;
  }

  append(point: Point2D): boolean {
    if (this.phase !== OriginalPartialEraserPreviewPhase.TRACKING || this.failed ||
      this.previewStroke === null) {
      return false;
    }
    if (!this.finitePoint(point) || this.points.length >= this.maxPoints) {
      // A truncated eraser path could delete content the user did not preview.
      // Fail the whole gesture and let finish() return no commit token.
      this.failed = true;
      this.points = [];
      this.previewStroke = null;
      return false;
    }
    const previous: Point2D = this.points[this.points.length - 1];
    if (previous.x === point.x && previous.y === point.y) {
      return false;
    }
    const next: Point2D = this.clonePoint(point);
    this.points.push(next);
    this.previewStroke.pathPoints.push(this.strokePoint(next));
    const halfWidth: number = this.previewStroke.renderSpec.brushWidth / 2;
    this.previewStroke.bounds.left = Math.min(this.previewStroke.bounds.left, next.x - halfWidth);
    this.previewStroke.bounds.top = Math.min(this.previewStroke.bounds.top, next.y - halfWidth);
    this.previewStroke.bounds.right = Math.max(this.previewStroke.bounds.right, next.x + halfWidth);
    this.previewStroke.bounds.bottom = Math.max(this.previewStroke.bounds.bottom, next.y + halfWidth);
    return true;
  }

  finish(): number | null {
    if (this.phase !== OriginalPartialEraserPreviewPhase.TRACKING || this.failed ||
      this.points.length === 0 || this.previewStroke === null) {
      this.reset();
      return null;
    }
    this.phase = OriginalPartialEraserPreviewPhase.AWAITING_COMMIT;
    return this.activeToken;
  }

  complete(token: number): boolean {
    if (this.phase !== OriginalPartialEraserPreviewPhase.AWAITING_COMMIT ||
      token !== this.activeToken) {
      return false;
    }
    this.reset();
    return true;
  }

  cancel(token?: number): boolean {
    if (this.phase === OriginalPartialEraserPreviewPhase.IDLE ||
      (token !== undefined && token !== this.activeToken)) {
      return false;
    }
    this.reset();
    return true;
  }

  getPhase(): OriginalPartialEraserPreviewPhase {
    return this.phase;
  }

  getPath(): Point2D[] {
    return this.points.map((point: Point2D): Point2D => this.clonePoint(point));
  }

  getStroke(): StrokeElementData | null {
    return this.previewStroke;
  }

  isFailed(): boolean {
    return this.failed;
  }

  private reset(): void {
    this.phase = OriginalPartialEraserPreviewPhase.IDLE;
    this.points = [];
    this.previewStroke = null;
    this.activeToken = 0;
    this.failed = false;
  }

  private finitePoint(point: Point2D): boolean {
    return Number.isFinite(point.x) && Number.isFinite(point.y);
  }

  private clonePoint(point: Point2D): Point2D {
    return { x: point.x, y: point.y };
  }

  private strokePoint(point: Point2D): StrokePathPoint {
    return {
      position: this.clonePoint(point),
      widthFactor: 1,
      pressure: -1,
      altitudeAngleRadians: -1,
      azimuthUnitX: 0,
      azimuthUnitY: 0,
    };
  }
}
