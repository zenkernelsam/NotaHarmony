// T-003 笔记元素体系（契约 phase-1-data-model.md §3.4，照搬，禁止修改签名）
// 纯类型文件：禁止 import 任何 @ohos.* / @kit.* 平台模块
import { Point2D, Rect2D, TransformMatrix } from './GeometryTypes';
import { PagePaperBackground } from './NoteTypes';
import { OriginalInkCreateMetadata, StrokeElementData } from './StrokeTypes';

// 元素类型（对应 c9e 子类枚举）
export enum ElementType {
  STROKE = 0,        // 笔画（yc7 等）
  ELLIPSE = 1,       // 椭圆形状（wv8/zzc）
  POLYGON = 2,       // 多边形形状（ina/a0d）
  TEXT = 3,          // 文本框（cde）
  IMAGE = 4,         // 原版独立 ImageBlock
  SELECTION = 5,     // 选区包装（lce）
  LINE = 6,          // 原版 ShapeDefinition.LINE（可含二次/三次控制点和末端箭头）
  MATH = 7,          // 原版独立 MathBlock（u08），不是 TEXT 别名
}

export enum ShapeArrowHead {
  NONE = 0,
  SINGLE = 1,
}

export interface OriginalShapeCreateMetadata extends OriginalInkCreateMetadata {
  averageForce: number | null;
}

// 元素基类（所有笔记元素的公共字段）
export interface NoteElementBase {
  id: string;
  type: ElementType;
  transform: TransformMatrix;
  bounds: Rect2D;
}

// Original Shapes own the same RichText CRDT as Text Blocks. These fields stay optional so
// pre-v57 Harmony snapshots and locally detected shapes remain readable as empty rich text.
export interface ShapeRichTextContent {
  richText?: string;
  characterStyleRuns?: RichTextCharacterStyleRun[];
  paragraphStyleRuns?: RichTextParagraphStyleRun[];
  // Missing on locally detected and legacy snapshots; original Shapes default to unlocked.
  positionLocked?: boolean;
  // Original InkTool register (Pen=0, Pencil=1, Highlighter=2, Tape=3).
  // Optional for pre-Phase-118 and non-original Shape snapshots.
  originalTool?: number;
  // Original InkStyle register. CREATE_SHAPE rejects variable-width style 0.
  originalStyle?: number;
  // Reserved type-18 identity carried by one newly recognized local Shape until commit.
  originalCreate?: OriginalShapeCreateMetadata;
}

// 椭圆元素
export interface EllipseElement extends NoteElementBase, ShapeRichTextContent {
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
export interface PolygonElement extends NoteElementBase, ShapeRichTextContent {
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
  richText: string;
  // Code-point offsets materialized from the original RichText SeqId/style CRDT.
  characterStyleRuns?: RichTextCharacterStyleRun[];
  paragraphStyleRuns?: RichTextParagraphStyleRun[];
  textOrigin: Point2D;
  blockWidth: number;
  blockHeight: number;
  rotationRadians: number;
  contentLeftInset: number;
  contentTopInset: number;
  fontSize: number;
  fontColor: number;
  // Original BlockCommon registers retained on TEXT snapshots.
  corner?: number;
  textWrap?: number;
  enableCaption?: boolean;
  paper?: PagePaperBackground | null;
  resizesWidthToFitText?: boolean;
  // Missing on legacy Harmony snapshots; the original Block default is unlocked.
  positionLocked?: boolean;
}

export interface RichTextCharacterStyle {
  bold?: boolean;
  italic?: boolean;
  underline?: boolean;
  highlightColor?: number;
  familyName?: string;
  fontSize?: number;
  foregroundColor?: number;
  link?: string;
  superscript?: boolean;
  subscript?: boolean;
  strikethrough?: boolean;
}

export interface RichTextCharacterStyleRun {
  start: number;
  end: number;
  style: RichTextCharacterStyle;
}

export interface RichTextParagraphStyle {
  indentLevel?: number;
  alignment?: number;
  lineSpacing?: number;
  decoratorStyle?: number;
  programmingLanguage?: string;
  writingDirection?: number;
  isChecked?: boolean;
}

export interface RichTextParagraphStyleRun {
  start: number;
  end: number;
  style: RichTextParagraphStyle;
}

// 原版 IMAGE Block。assetHash 是 8 个 uint64 十进制 word 的稳定冒号串，不是 SHA-256。
export interface ImageElement extends NoteElementBase {
  type: ElementType.IMAGE;
  assetHash: string;
  assetHashBits: string[];
  fileName: string;
  mimeType: string;
  fileSize: number;
  intrinsicWidth: number;
  intrinsicHeight: number;
  cropRect: Rect2D | null;
  blockWidth: number;
  blockHeight: number;
  rotationRadians: number;
  corner: number;
  textWrap: number;
  enableCaption: boolean;
  webUrl: string | null;
  imageFlippedHorizontally: boolean;
  imageFlippedVertically: boolean;
  positionLocked: boolean;
}

// 原版 u08 MathBlock。latex/color 是两个独立 LWW register。
export interface MathElement extends NoteElementBase {
  type: ElementType.MATH;
  latex: string;
  color: number;
  blockWidth: number;
  blockHeight: number;
  rotationRadians: number;
  corner: number;
  textWrap: number;
  enableCaption: boolean;
  positionLocked: boolean;
}

// 原版 1.0.3 uf7/s4d：cp1+cp2 为 cubic，仅 cp1 为 quadratic，无控制点为直线。
export interface LineElement extends NoteElementBase, ShapeRichTextContent {
  type: ElementType.LINE;
  start: Point2D;
  controlPoint1: Point2D | null;
  controlPoint2: Point2D | null;
  end: Point2D;
  arrowHead: ShapeArrowHead;
  color: number;
  strokeWidth: number;
  fillColor: number | null;
}

export interface StrokeNoteElement extends NoteElementBase {
  type: ElementType.STROKE;
  stroke: StrokeElementData;
}

export interface SelectionElement extends NoteElementBase {
  type: ElementType.SELECTION;
  selectedElementIds: string[];
}

export type ShapeElement = EllipseElement | PolygonElement | LineElement;

// 联合类型
export type NoteElement =
  | StrokeNoteElement
  | EllipseElement
  | PolygonElement
  | LineElement
  | TextBlockElement
  | ImageElement
  | MathElement
  | SelectionElement;
