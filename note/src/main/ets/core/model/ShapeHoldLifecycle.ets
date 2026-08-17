import { Point2D } from './GeometryTypes';

// Android 1.0.3 y95 waits exactly 500 ms before invoking the shape callback.
export const ORIGINAL_SHAPE_HOLD_DELAY_MS: number = 500;

// tc5 uses four times the platform handwriting slop for stylus/mouse input.
export const ORIGINAL_SHAPE_HOLD_HANDWRITING_SLOP_MULTIPLIER: number = 4;
export const ORIGINAL_SHAPE_HOLD_FALLBACK_HANDWRITING_SLOP: number = 2;
// HarmonyOS API 21 exposes SourceTool but no public ViewConfiguration-style
// touch/handwriting slop query. Keep this explicitly named as a port fallback,
// not an Android 1.0.3 constant; a future platform adapter can pass baseSlop.
export const HARMONY_SHAPE_HOLD_FALLBACK_TOUCH_SLOP: number = 8;

export function originalShapeHoldPauseThreshold(handwritingInput: boolean,
  baseSlop?: number): number {
  const fallback: number = handwritingInput ?
    ORIGINAL_SHAPE_HOLD_FALLBACK_HANDWRITING_SLOP :
    HARMONY_SHAPE_HOLD_FALLBACK_TOUCH_SLOP;
  const resolved: number = baseSlop !== undefined && Number.isFinite(baseSlop) && baseSlop > 0 ?
    baseSlop : fallback;
  return handwritingInput ?
    resolved * ORIGINAL_SHAPE_HOLD_HANDWRITING_SLOP_MULTIPLIER : resolved;
}

// Mirrors tc5.pauseDetectionLatestPoint. Sub-slop motion keeps the current
// 500 ms job alive; only a threshold crossing moves the anchor and restarts it.
export class ShapeHoldPauseTracker {
  private anchor: Point2D | null = null;

  update(point: Point2D, threshold: number): boolean {
    if (!this.finitePoint(point) || !Number.isFinite(threshold) || threshold < 0) {
      return false;
    }
    if (this.anchor === null) {
      this.anchor = this.clonePoint(point);
      return true;
    }
    const dx: number = point.x - this.anchor.x;
    const dy: number = point.y - this.anchor.y;
    if (Math.sqrt(dx * dx + dy * dy) < threshold) {
      return false;
    }
    this.anchor = this.clonePoint(point);
    return true;
  }

  reset(): void {
    this.anchor = null;
  }

  getAnchor(): Point2D | null {
    return this.anchor === null ? null : this.clonePoint(this.anchor);
  }

  private finitePoint(point: Point2D): boolean {
    return Number.isFinite(point.x) && Number.isFinite(point.y);
  }

  private clonePoint(point: Point2D): Point2D {
    return { x: point.x, y: point.y };
  }
}
