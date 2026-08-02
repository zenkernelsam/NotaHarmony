// T-013 脏矩形追踪器（任务卡 T-013，REVERSE_ANALYSIS §19：增量渲染区域 = bounds±3px）
import { Rect2D } from '../core/model/GeometryTypes';

export class DirtyRectTracker {
  private dirtyRect: Rect2D | null = null;
  private padding: number;

  constructor(padding?: number) {
    this.padding = padding !== undefined ? padding : 3;  // 对应原版 ±3px
  }

  // 标记脏区（笔画 bounds 膨胀 padding）
  markDirty(bounds: Rect2D): void {
    const inflated: Rect2D = {
      left: bounds.left - this.padding,
      top: bounds.top - this.padding,
      right: bounds.right + this.padding,
      bottom: bounds.bottom + this.padding,
    };
    if (this.dirtyRect === null) {
      this.dirtyRect = inflated;
    } else {
      // 合并（union）：外接矩形
      this.dirtyRect = {
        left: Math.min(this.dirtyRect.left, inflated.left),
        top: Math.min(this.dirtyRect.top, inflated.top),
        right: Math.max(this.dirtyRect.right, inflated.right),
        bottom: Math.max(this.dirtyRect.bottom, inflated.bottom),
      };
    }
  }

  // 获取并重置脏区
  consume(): Rect2D | null {
    const rect: Rect2D | null = this.dirtyRect;
    this.dirtyRect = null;
    return rect;
  }

  // 全屏脏（初始化/resize 时）
  markFullDirty(width: number, height: number): void {
    this.dirtyRect = { left: 0, top: 0, right: width, bottom: height };
  }

  isDirty(): boolean {
    return this.dirtyRect !== null;
  }
}
