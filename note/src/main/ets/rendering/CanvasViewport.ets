// T-034 画布视口状态管理（缩放/平移 + 坐标映射）
// 纯逻辑模块：不 import 平台 API
import { Point2D, Rect2D } from '../core/model/GeometryTypes';

export class CanvasViewport {
  zoom: number = 1.0;          // [0.25, 4.0]
  scrollX: number = 0;
  scrollY: number = 0;
  private static readonly MIN_ZOOM: number = 0.25;
  private static readonly MAX_ZOOM: number = 4.0;

  // 屏幕坐标 → 画布坐标（输入点必须经此映射）
  screenToCanvas(sx: number, sy: number): Point2D {
    return { x: (sx - this.scrollX) / this.zoom, y: (sy - this.scrollY) / this.zoom };
  }

  // 画布坐标 → 屏幕坐标（选区边框/覆盖层显示用）
  canvasToScreen(cx: number, cy: number): Point2D {
    return { x: cx * this.zoom + this.scrollX, y: cy * this.zoom + this.scrollY };
  }

  visibleCanvasRect(screenWidth: number, screenHeight: number): Rect2D | null {
    if (!Number.isFinite(screenWidth) || !Number.isFinite(screenHeight) ||
      screenWidth <= 0 || screenHeight <= 0 || !Number.isFinite(this.zoom) || this.zoom <= 0 ||
      !Number.isFinite(this.scrollX) || !Number.isFinite(this.scrollY)) {
      return null;
    }
    const topLeft: Point2D = this.screenToCanvas(0, 0);
    const bottomRight: Point2D = this.screenToCanvas(screenWidth, screenHeight);
    return {
      left: Math.min(topLeft.x, bottomRight.x),
      top: Math.min(topLeft.y, bottomRight.y),
      right: Math.max(topLeft.x, bottomRight.x),
      bottom: Math.max(topLeft.y, bottomRight.y),
    };
  }

  // 以某屏幕点为中心缩放（保持该点下的画布内容不动）
  zoomAt(sx: number, sy: number, factor: number): void {
    if (!Number.isFinite(sx) || !Number.isFinite(sy) || !Number.isFinite(factor) || factor <= 0 ||
      !Number.isFinite(this.zoom) || !Number.isFinite(this.scrollX) || !Number.isFinite(this.scrollY)) {
      return;
    }
    const newZoom: number = this.clampZoom(this.zoom * factor);
    const actual: number = newZoom / this.zoom;
    if (actual === 1.0) {
      return;
    }
    // 保持 (sx, sy) 处画布内容不动：scroll = sx - canvasX * newZoom
    this.scrollX = sx - (sx - this.scrollX) * actual;
    this.scrollY = sy - (sy - this.scrollY) * actual;
    this.zoom = newZoom;
  }

  // 平移（屏幕像素增量）
  panBy(dx: number, dy: number): void {
    if (!Number.isFinite(dx) || !Number.isFinite(dy)) {
      return;
    }
    this.scrollX += dx;
    this.scrollY += dy;
  }

  // 直接设置缩放值，不改变 scroll；用于随后显式恢复/重算 scroll 的调用路径。
  setZoomRaw(z: number): boolean {
    if (!Number.isFinite(z) || z < CanvasViewport.MIN_ZOOM || z > CanvasViewport.MAX_ZOOM) {
      return false;
    }
    this.zoom = z;
    return true;
  }

  setScroll(x: number, y: number): boolean {
    if (!Number.isFinite(x) || !Number.isFinite(y)) {
      return false;
    }
    this.scrollX = x;
    this.scrollY = y;
    return true;
  }

  // 复位（100% 左上角）
  reset(): void {
    this.zoom = 1.0;
    this.scrollX = 0;
    this.scrollY = 0;
  }

  // 限制 zoom 范围（滚动边界 MVP 不限制：自由平移）
  clamp(): void {
    this.zoom = Number.isFinite(this.zoom) ? this.clampZoom(this.zoom) : 1.0;
    if (!Number.isFinite(this.scrollX)) {
      this.scrollX = 0;
    }
    if (!Number.isFinite(this.scrollY)) {
      this.scrollY = 0;
    }
  }

  private clampZoom(z: number): number {
    if (z < CanvasViewport.MIN_ZOOM) {
      return CanvasViewport.MIN_ZOOM;
    }
    if (z > CanvasViewport.MAX_ZOOM) {
      return CanvasViewport.MAX_ZOOM;
    }
    return z;
  }
}

export class CumulativeGestureTracker {
  private lastScale: number = 1;
  private lastOffsetX: number = 0;
  private lastOffsetY: number = 0;
  private scaleActive: boolean = false;
  private panActive: boolean = false;

  nextScaleFactor(scale: number): number {
    if (!Number.isFinite(scale) || scale <= 0) {
      return 1;
    }
    const factor: number = this.scaleActive ? scale / this.lastScale : scale;
    this.lastScale = scale;
    this.scaleActive = true;
    return Number.isFinite(factor) && factor > 0 ? factor : 1;
  }

  nextPanDelta(offsetX: number, offsetY: number): Point2D {
    if (!Number.isFinite(offsetX) || !Number.isFinite(offsetY)) {
      return { x: 0, y: 0 };
    }
    const dx: number = this.panActive ? offsetX - this.lastOffsetX : offsetX;
    const dy: number = this.panActive ? offsetY - this.lastOffsetY : offsetY;
    this.lastOffsetX = offsetX;
    this.lastOffsetY = offsetY;
    this.panActive = true;
    return { x: dx, y: dy };
  }

  resetScale(): void {
    this.lastScale = 1;
    this.scaleActive = false;
  }

  resetPan(): void {
    this.lastOffsetX = 0;
    this.lastOffsetY = 0;
    this.panActive = false;
  }
}
