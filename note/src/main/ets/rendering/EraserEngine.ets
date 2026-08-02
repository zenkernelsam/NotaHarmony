// T-014 橡皮擦引擎（任务卡 T-014，REVERSE_ANALYSIS §5b：PARTIAL 挖洞 + WHOLE 整条删除）
// 纯几何碰撞检测：禁止 import 平台 API
import { StrokeElementData } from '../core/model/StrokeTypes';
import { Point2D, Rect2D } from '../core/model/GeometryTypes';

export enum EraserMode {
  PARTIAL = 0,  // 像素擦除（挖洞）
  WHOLE = 1,    // 整条删除
}

export interface EraseResult {
  mode: EraserMode;
  // PARTIAL: 受影响的笔画（maskPath 已更新）
  affectedStrokes: StrokeElementData[];
  // WHOLE: 应删除的笔画 ID
  deletedStrokeIds: string[];
}

export class EraserEngine {
  private mode: EraserMode;
  private eraserWidth: number;  // 擦除宽度（默认 20）

  constructor(mode: EraserMode, eraserWidth?: number) {
    this.mode = mode;
    this.eraserWidth = eraserWidth !== undefined ? eraserWidth : 20;
  }

  // 执行擦除（传入擦除路径点 + 当前所有笔画）
  erase(eraserPath: Point2D[], strokes: StrokeElementData[]): EraseResult {
    if (this.mode === EraserMode.WHOLE) {
      return this.eraseWhole(eraserPath, strokes);
    }
    return this.erasePartial(eraserPath, strokes);
  }

  // WHOLE: 擦除路径 bounds 与笔画 bounds 相交 → 整条删除
  private eraseWhole(eraserPath: Point2D[], strokes: StrokeElementData[]): EraseResult {
    const deleted: string[] = [];
    if (eraserPath.length === 0) {
      return { mode: this.mode, affectedStrokes: [], deletedStrokeIds: deleted };
    }
    const radius: number = this.eraserWidth / 2;
    for (const stroke of strokes) {
      if (this.intersectsBounds(eraserPath, stroke.bounds, radius)) {
        deleted.push(stroke.id);
      }
    }
    return { mode: this.mode, affectedStrokes: [], deletedStrokeIds: deleted };
  }

  // PARTIAL: 将擦除路径写入受影响笔画的 maskPath（渲染器用 destination-out 挖洞）
  private erasePartial(eraserPath: Point2D[], strokes: StrokeElementData[]): EraseResult {
    const affected: StrokeElementData[] = [];
    if (eraserPath.length === 0) {
      return { mode: this.mode, affectedStrokes: affected, deletedStrokeIds: [] };
    }
    const radius: number = this.eraserWidth / 2;
    for (const stroke of strokes) {
      if (this.intersectsBounds(eraserPath, stroke.bounds, radius)) {
        // 复制笔画并追加擦除路径点
        const updated: StrokeElementData = {
          id: stroke.id,
          pathPoints: stroke.pathPoints,
          cubicSegments: stroke.cubicSegments,
          splatPoints: stroke.splatPoints,
          renderSpec: stroke.renderSpec,
          transform: stroke.transform,
          bounds: stroke.bounds,
          maskPath: stroke.maskPath.concat(eraserPath),
          isFinished: stroke.isFinished,
        };
        affected.push(updated);
      }
    }
    return { mode: this.mode, affectedStrokes: affected, deletedStrokeIds: [] };
  }

  // 碰撞检测：擦除路径 bounds（膨胀 radius）与笔画 bounds 相交（MVP：AABB 相交）
  private intersectsBounds(path: Point2D[], bounds: Rect2D, radius: number): boolean {
    if (path.length === 0) {
      return false;
    }
    let left: number = path[0].x;
    let top: number = path[0].y;
    let right: number = left;
    let bottom: number = top;
    for (const p of path) {
      if (p.x < left) {
        left = p.x;
      }
      if (p.x > right) {
        right = p.x;
      }
      if (p.y < top) {
        top = p.y;
      }
      if (p.y > bottom) {
        bottom = p.y;
      }
    }
    // AABB 相交判定（膨胀 radius）
    const overlapX: boolean = (left - radius) <= bounds.right && (right + radius) >= bounds.left;
    const overlapY: boolean = (top - radius) <= bounds.bottom && (bottom + radius) >= bounds.top;
    return overlapX && overlapY;
  }

  setMode(mode: EraserMode): void {
    this.mode = mode;
  }

  setWidth(width: number): void {
    this.eraserWidth = width;
  }

  getMode(): EraserMode {
    return this.mode;
  }
}
