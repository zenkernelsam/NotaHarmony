// 原版 laser pointer（zt6/xt6/yt6/du6/cu6）的瞬态渲染状态机。
// 语义：激光不产生持久笔画；按下/移动累积 tail 段（showTail）或只更新
// 指针点（!showTail）；抬手后 yt6 协程先等 500ms 再以 31×16ms 逐帧衰减
// alpha，最后 zt6.i() 清空——原版 fade 恰好落在另一分支的 alpha 字段上，
// 因此可见行为等价于“标记不透明驻留约 1 秒后清除”，本实现保留相同字段与
// 时序常量。
import { Point2D } from '../model/GeometryTypes';

export const ORIGINAL_LASER_COLOR: number = -1754827;      // rz1.r()：w31(-1754827)
export const ORIGINAL_LASER_WIDTH_PT: number = 15.0;       // rz1.r()/j6g：15.0f
export const ORIGINAL_LASER_FADE_DELAY_MS: number = 500;   // yt6：fag.B(500)
export const ORIGINAL_LASER_FADE_FRAMES: number = 31;      // yt6：i = 1..31
export const ORIGINAL_LASER_FRAME_MS: number = 16;         // yt6：fag.B(16)
export const ORIGINAL_LASER_DEFAULT_SHOW_TAIL: boolean = true; // cu6.i：bu6(true)

export interface OriginalLaserRenderState {
  color: number;
  widthPt: number;
  showTail: boolean;
  pointerPoint: Point2D | null;
  pointerAlpha: number;
  tailSegments: Point2D[][];
  tailAlpha: number;
}

export function emptyOriginalLaserRenderState(showTail: boolean): OriginalLaserRenderState {
  return {
    color: ORIGINAL_LASER_COLOR,
    widthPt: ORIGINAL_LASER_WIDTH_PT,
    showTail: showTail,
    pointerPoint: null,
    pointerAlpha: 0,
    tailSegments: [],
    tailAlpha: 0,
  };
}

// zt6：P=进行中的 tail 点队列，Q=已完成的 tail 段列表。
export class OriginalLaserSession {
  private showTail: boolean = ORIGINAL_LASER_DEFAULT_SHOW_TAIL;
  private color: number = ORIGINAL_LASER_COLOR;
  private widthPt: number = ORIGINAL_LASER_WIDTH_PT;
  private pendingTail: Point2D[] = [];
  private completedSegments: Point2D[][] = [];
  private pointerPoint: Point2D | null = null;
  private pointerAlpha: number = 0;
  private tailAlpha: number = 0;
  private strokeActive: boolean = false;

  setAppearance(color: number, widthPt: number, showTail: boolean): void {
    this.color = color;
    this.widthPt = widthPt;
    this.showTail = showTail;
  }

  isActive(): boolean {
    return this.strokeActive;
  }

  // xt6 emit → qt6（down）/rt6（move）共用累积路径。
  appendPoint(point: Point2D): void {
    if (this.showTail) {
      this.pendingTail.push({ x: point.x, y: point.y });
      this.pointerPoint = null;
      this.pointerAlpha = 0;
      this.tailAlpha = 1;
    } else {
      this.pointerPoint = { x: point.x, y: point.y };
      this.pointerAlpha = 1;
      this.tailAlpha = 0;
    }
    this.strokeActive = true;
  }

  // xt6 up 分支：!showTail 或队列不足一段 → 直接驻留清空；否则收尾入 Q。
  endStroke(): boolean {
    if (!this.strokeActive) {
      return false;
    }
    this.strokeActive = false;
    if (this.showTail) {
      if (this.pendingTail.length > 1) {
        this.completedSegments.push(this.pendingTail.slice());
      }
      this.pendingTail = [];
      if (this.completedSegments.length === 0) {
        this.clear();
        return false;
      }
    }
    return this.hasVisibleContent();
  }

  hasVisibleContent(): boolean {
    return this.pendingTail.length > 0 || this.completedSegments.length > 0 ||
      this.pointerPoint !== null;
  }

  // yt6 帧：alpha = 1 - i/31。原版按模式衰减另一字段；这里如实保留两个字段。
  applyFadeFrame(frame: number): void {
    const alpha: number = Math.max(0, 1 - frame / ORIGINAL_LASER_FADE_FRAMES);
    if (this.showTail) {
      this.pointerAlpha = alpha;
    } else {
      this.tailAlpha = alpha;
    }
  }

  // zt6.i()：取消 fade、清空全部状态。
  clear(): void {
    this.strokeActive = false;
    this.pendingTail = [];
    this.completedSegments = [];
    this.pointerPoint = null;
    this.pointerAlpha = 0;
    this.tailAlpha = 0;
  }

  renderState(): OriginalLaserRenderState {
    const segments: Point2D[][] = this.completedSegments.map(
      (seg: Point2D[]): Point2D[] => seg);
    if (this.pendingTail.length > 0) {
      segments.push(this.pendingTail.slice());
    }
    return {
      color: this.color,
      widthPt: this.widthPt,
      showTail: this.showTail,
      pointerPoint: this.pointerPoint,
      pointerAlpha: this.pointerAlpha,
      tailSegments: segments,
      tailAlpha: this.tailAlpha,
    };
  }
}
