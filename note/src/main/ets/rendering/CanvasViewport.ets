// T-034 画布视口状态管理（缩放/平移 + 坐标映射）
// 纯逻辑模块：不 import 平台 API
import { Point2D } from '../core/model/GeometryTypes';

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

  // 以某屏幕点为中心缩放（保持该点下的画布内容不动）
  zoomAt(sx: number, sy: number, factor: number): void {
    if (factor <= 0) {
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
    this.scrollX += dx;
    this.scrollY += dy;
  }

  // 直接设置缩放（控制条按钮用；保持画布中心不动）
  setZoom(z: number): void {
    this.zoomAt(0, 0, this.clampZoom(z) / this.zoom);
  }

  setScroll(x: number, y: number): void {
    this.scrollX = x;
    this.scrollY = y;
  }

  // 复位（100% 左上角）
  reset(): void {
    this.zoom = 1.0;
    this.scrollX = 0;
    this.scrollY = 0;
  }

  // 限制 zoom 范围（滚动边界 MVP 不限制：自由平移）
  clamp(): void {
    this.zoom = this.clampZoom(this.zoom);
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
