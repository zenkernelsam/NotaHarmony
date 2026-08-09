// 脏区始终使用页面坐标；屏幕像素 padding 由当前 zoom 换算后再写入。
import { Rect2D } from '../core/model/GeometryTypes';

export class DirtyRectTracker {
  private dirtyRects: Rect2D[] = [];
  private screenPadding: number;
  private maxRegions: number;

  constructor(screenPadding: number = 3, maxRegions: number = 8) {
    this.screenPadding = Math.max(0, screenPadding);
    this.maxRegions = Math.max(1, maxRegions);
  }

  markDirty(bounds: Rect2D, zoom: number = 1): void {
    const safeZoom: number = zoom > 0 ? zoom : 1;
    const pagePadding: number = this.screenPadding / safeZoom;
    let candidate: Rect2D = {
      left: bounds.left - pagePadding,
      top: bounds.top - pagePadding,
      right: bounds.right + pagePadding,
      bottom: bounds.bottom + pagePadding,
    };
    let remaining: Rect2D[] = this.dirtyRects.slice();
    let merged: boolean = true;
    while (merged) {
      merged = false;
      const next: Rect2D[] = [];
      for (const rect of remaining) {
        if (this.intersects(rect, candidate)) {
          candidate = this.union(rect, candidate);
          merged = true;
        } else {
          next.push(rect);
        }
      }
      remaining = next;
    }
    remaining.push(candidate);
    if (remaining.length > this.maxRegions) {
      let collapsed: Rect2D = remaining[0];
      for (let i: number = 1; i < remaining.length; i++) {
        collapsed = this.union(collapsed, remaining[i]);
      }
      this.dirtyRects = [collapsed];
    } else {
      this.dirtyRects = remaining;
    }
  }

  consume(): Rect2D[] {
    const rects: Rect2D[] = this.dirtyRects;
    this.dirtyRects = [];
    return rects;
  }

  markFullDirty(pageBounds: Rect2D): void {
    this.dirtyRects = [{
      left: pageBounds.left, top: pageBounds.top,
      right: pageBounds.right, bottom: pageBounds.bottom,
    }];
  }

  isDirty(): boolean {
    return this.dirtyRects.length > 0;
  }

  private intersects(a: Rect2D, b: Rect2D): boolean {
    return a.left <= b.right && a.right >= b.left && a.top <= b.bottom && a.bottom >= b.top;
  }

  private union(a: Rect2D, b: Rect2D): Rect2D {
    return {
      left: Math.min(a.left, b.left),
      top: Math.min(a.top, b.top),
      right: Math.max(a.right, b.right),
      bottom: Math.max(a.bottom, b.bottom),
    };
  }
}
