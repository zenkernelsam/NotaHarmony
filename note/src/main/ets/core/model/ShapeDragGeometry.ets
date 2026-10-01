// Phase 1389 — 1.4.2 SHAPE 工具拖拽成形几何（u5g.java:117-186 移植）。
// 原版 SHAPE(eti.T) 工具：按下为包围盒一角（start=this.t），拖到对角（end=this.u），
// 松手提交形状元素。各 r5g 种类的映射：
//   LINE(5)/ARROW(4)：起点→终点线段；ARROW 端点带 SINGLE 箭头。
//   RECTANGLE(0)：包围盒四角（isClosed）。
//   ELLIPSE(1)：内切椭圆。
//   DIAMOND(2)：四边中点菱形。
//   TRIANGLE(3)：顶点在上边中点、底角为两下角。
// 约束修饰（r().q，"绘制正形/45°"）：形状 → 正方形包围盒（取长边），
//   LINE/ARROW → 端点吸附 45°（保长度）。
// Phase 1437 复核：j1k.q 在 1.4.2 全源树零写入点（m() setter 无调用方），
// 约束分支为休眠死代码——constrain 恒 false 即原版对齐，非缺口。
import { Point2D, Rect2D } from './GeometryTypes';
import { ShapeKind } from './BrushTypes';
import {
  ElementType, EllipseElement, LineElement, PolygonElement, ShapeArrowHead, ShapeElement,
} from './ElementTypes';
import { recomputeShapeBounds } from './ShapeGeometry';

// u5g.java:126 — 拖拽长度 ≤ 6.0（画布单位）不产出形状。
const SHAPE_DRAG_SLOP: number = 6.0;
const IDENTITY: number[] = [1, 0, 0, 0, 1, 0, 0, 0, 1];
const PI_OVER_4: number = Math.PI / 4;

function newElementId(): string {
  const timePart: string = Date.now().toString(36);
  const randPart: string = Math.random().toString(36).slice(2, 8);
  return timePart + randPart;
}

// 原版 InkTool/InkStyle 寄存器：SHAPE 工具产形以钢笔描边呈现 → originalTool=0(Pen)、
// originalStyle=1(MONO，CREATE_SHAPE 拒绝 variable-width 0)。拖拽无压感 → force=null
// （编码时经 originalShapeForce 落默认 1）。
function applyOriginalStrokeDefaults(shape: ShapeElement): void {
  shape.originalTool = 0;
  shape.originalStyle = 1;
  shape.originalForce = null;
}

// u5g.java:127-145 — 约束修饰下的终点修正。
//   LINE/ARROW：方向吸附 45°（atan2/π4 取整），保拖拽长度。
//   其余形状：取 |dx|,|dy| 较大者成正方形，符号随拖拽方向。
function constrainEnd(kind: ShapeKind, start: Point2D, end: Point2D): Point2D {
  const dx: number = end.x - start.x;
  const dy: number = end.y - start.y;
  if (kind === ShapeKind.LINE || kind === ShapeKind.ARROW) {
    const angle: number = Math.round(Math.atan2(dy, dx) / PI_OVER_4) * PI_OVER_4;
    const len: number = Math.hypot(dx, dy);
    return { x: start.x + Math.cos(angle) * len, y: start.y + Math.sin(angle) * len };
  }
  const side: number = Math.max(Math.abs(dx), Math.abs(dy));
  return {
    x: start.x + (dx === 0 ? 1 : Math.sign(dx)) * side,
    y: start.y + (dy !== 0 ? Math.sign(dy) : 1) * side,
  };
}

// 由拖拽包围盒成形当前 shapeKind 的 ShapeElement。返回 null 表示拖拽过短/退化。
// start/end 为画布坐标；constrain 对应原版 r().q 修饰。
export function buildDragShape(kind: ShapeKind, start: Point2D, end: Point2D,
  color: number, strokeWidth: number, constrain: boolean = false): ShapeElement | null {
  if (Math.hypot(end.x - start.x, end.y - start.y) <= SHAPE_DRAG_SLOP) {
    return null;
  }
  const target: Point2D = constrain ? constrainEnd(kind, start, end) : end;

  if (kind === ShapeKind.LINE || kind === ShapeKind.ARROW) {
    const line: LineElement = {
      id: newElementId(),
      type: ElementType.LINE,
      transform: IDENTITY.slice(),
      bounds: { left: 0, top: 0, right: 0, bottom: 0 },
      start: { x: start.x, y: start.y },
      controlPoint1: null,
      controlPoint2: null,
      end: { x: target.x, y: target.y },
      arrowHead: kind === ShapeKind.ARROW ? ShapeArrowHead.SINGLE : ShapeArrowHead.NONE,
      color: color,
      strokeWidth: strokeWidth,
      fillColor: null,
    };
    applyOriginalStrokeDefaults(line);
    line.bounds = recomputeShapeBounds(line);
    return line;
  }

  const left: number = Math.min(start.x, target.x);
  const top: number = Math.min(start.y, target.y);
  const w: number = Math.abs(target.x - start.x);
  const h: number = Math.abs(target.y - start.y);
  if (w === 0 || h === 0) {
    return null;  // u5g.java:157 — 退化包围盒不产出。
  }

  if (kind === ShapeKind.ELLIPSE) {
    const ellipse: EllipseElement = {
      id: newElementId(),
      type: ElementType.ELLIPSE,
      transform: IDENTITY.slice(),
      bounds: { left: 0, top: 0, right: 0, bottom: 0 },
      center: { x: left + w / 2, y: top + h / 2 },
      radiusX: w / 2,
      radiusY: h / 2,
      rotationRadians: 0,
      color: color,
      strokeWidth: strokeWidth,
      fillColor: null,
    };
    applyOriginalStrokeDefaults(ellipse);
    ellipse.bounds = recomputeShapeBounds(ellipse);
    return ellipse;
  }

  // RECTANGLE(0) / DIAMOND(2) / TRIANGLE(3) — 闭合多边形（u5g 顶点序）。
  let vertices: Point2D[];
  if (kind === ShapeKind.RECTANGLE) {
    vertices = [
      { x: left, y: top }, { x: left + w, y: top },
      { x: left + w, y: top + h }, { x: left, y: top + h },
    ];
  } else if (kind === ShapeKind.DIAMOND) {
    vertices = [
      { x: left + w / 2, y: top }, { x: left + w, y: top + h / 2 },
      { x: left + w / 2, y: top + h }, { x: left, y: top + h / 2 },
    ];
  } else {
    vertices = [
      { x: left + w / 2, y: top },
      { x: left + w, y: top + h }, { x: left, y: top + h },
    ];
  }
  const polygon: PolygonElement = {
    id: newElementId(),
    type: ElementType.POLYGON,
    transform: IDENTITY.slice(),
    bounds: { left: 0, top: 0, right: 0, bottom: 0 },
    vertices: vertices,
    isClosed: true,
    color: color,
    strokeWidth: strokeWidth,
    fillColor: null,
  };
  applyOriginalStrokeDefaults(polygon);
  polygon.bounds = recomputeShapeBounds(polygon);
  return polygon;
}
