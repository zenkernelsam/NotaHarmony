// T-003 笔记元素体系（契约 phase-1-data-model.md §3.4，照搬，禁止修改签名）
// 纯类型文件：禁止 import 任何 @ohos.* / @kit.* 平台模块
import { Point2D, Rect2D, TransformMatrix } from './GeometryTypes';
import { StrokeElementData } from './StrokeTypes';

// 元素类型（对应 c9e 子类枚举）
export enum ElementType {
  STROKE = 0,        // 笔画（yc7 等）
  ELLIPSE = 1,       // 椭圆形状（wv8/zzc）
  POLYGON = 2,       // 多边形形状（ina/a0d）
  TEXT = 3,          // 文本框（cde）
  IMAGE = 4,         // 图片（待补）
  SELECTION = 5,     // 选区包装（lce）
}

// 元素基类（所有笔记元素的公共字段）
export interface NoteElementBase {
  id: string;
  type: ElementType;
  transform: TransformMatrix;
  bounds: Rect2D;
}

// 椭圆元素
export interface EllipseElement extends NoteElementBase {
  type: ElementType.ELLIPSE;
  center: Point2D;
  radiusX: number;
  radiusY: number;
  rotationRadians: number;
  color: number;
  strokeWidth: number;
  fillColor: number | null;
}

// 多边形元素
export interface PolygonElement extends NoteElementBase {
  type: ElementType.POLYGON;
  vertices: Point2D[];
  isClosed: boolean;
  color: number;
  strokeWidth: number;
  fillColor: number | null;
}

// 文本块（对应 cde TextBlockInfo）
export interface TextBlockElement extends NoteElementBase {
  type: ElementType.TEXT;
  richText: string;              // 简化为纯文本（富文本后续扩展）
  textOrigin: Point2D;
  blockWidth: number;
  blockHeight: number;
  rotationRadians: number;
  contentLeftInset: number;
  contentTopInset: number;
  fontSize: number;
  fontColor: number;
}

// 图片元素（预留，Phase 3 补全）
export interface ImageElement extends NoteElementBase {
  type: ElementType.IMAGE;
  assetHash: string;
  cropRect: Rect2D | null;
}

export interface StrokeNoteElement extends NoteElementBase {
  type: ElementType.STROKE;
  stroke: StrokeElementData;
}

export interface SelectionElement extends NoteElementBase {
  type: ElementType.SELECTION;
  selectedElementIds: string[];
}

export type ShapeElement = EllipseElement | PolygonElement;

// 联合类型
export type NoteElement =
  | StrokeNoteElement
  | EllipseElement
  | PolygonElement
  | TextBlockElement
  | ImageElement
  | SelectionElement;
