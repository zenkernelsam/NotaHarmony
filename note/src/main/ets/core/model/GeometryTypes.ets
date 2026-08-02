// T-001 基础几何类型（契约 phase-1-data-model.md §3.1，照搬，禁止修改签名）
// 纯类型文件：禁止 import 任何 @ohos.* / @kit.* 平台模块

// 二维点
export interface Point2D {
  x: number;
  y: number;
}

// 二维矩形
export interface Rect2D {
  left: number;
  top: number;
  right: number;
  bottom: number;
}

// 3×3 仿射变换矩阵（行主序 [a,b,c,d,e,f,g,h,i]）
// 对应 Android Matrix 的 9 个 float
export type TransformMatrix = number[];  // 长度固定 9

// 三次贝塞尔曲线段
export interface CubicSegment {
  p0: Point2D;
  p1: Point2D;  // 控制点 1
  p2: Point2D;  // 控制点 2
  p3: Point2D;
}
