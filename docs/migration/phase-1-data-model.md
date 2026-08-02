# Phase 1 — 数据模型与契约层

> 版本: v1.0 | 日期: 2026-08-02 | 状态: 待工人执行
> 前置: 00-OVERVIEW.md 已确认

---

## 1. 阶段目标

定义全部跨阶段共享的 ArkTS 接口、类型、枚举和数据库 schema。Phase 2/3/4 的工人只看本阶段产出的契约文件即可开工，无需再做架构决策。

**完成标准**：所有契约文件通过 `check_ets_files` 语法检查 + `build_project` 编译通过。

---

## 2. 模块边界

```
note/src/main/ets/core/
├── model/           ← 纯数据类型（零平台 import）
│   ├── GeometryTypes.ets
│   ├── StrokeTypes.ets
│   ├── BrushTypes.ets
│   ├── ElementTypes.ets
│   ├── OpTypes.ets
│   ├── NoteTypes.ets
│   └── AssetTypes.ets
├── adaptation/      ← 适配层接口（可有平台 import，但接口本身不绑定实现）
│   ├── InkInputProvider.ets
│   ├── StrokeRenderer.ets
│   ├── Predictor.ets
│   └── RecognitionProvider.ets
└── op/              ← op 流引擎接口
    └── OpStore.ets

note/src/main/ets/data/
├── DatabaseHelper.ets       ← DDL + 初始化 + 版本迁移
└── RepositoryInterfaces.ets ← Repository 抽象接口
```

---

## 3. 接口与类型定义（契约，工人不得修改签名）

### 3.1 GeometryTypes.ets — 基础几何

```typescript
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
```

### 3.2 StrokeTypes.ets — 输入与笔画

```typescript
import { Point2D, CubicSegment, Rect2D, TransformMatrix } from './GeometryTypes';

// 输入工具类型（对应 AndroidX Ink InputToolType）
export enum InputToolType {
  STYLUS = 0,
  MOUSE = 1,
  TOUCH = 2,
}

// 单个输入采样点（对应 hda.v() → StrokeInput）
export interface InputPoint {
  x: number;
  y: number;
  elapsedTimeMillis: number;
  toolType: InputToolType;
  pressure: number;         // [0,1]，无能力时 -1
  tiltRadians: number;      // [0, π/2]，无能力时 -1
  orientationRadians: number; // [0, 2π)，无能力时 -1
}

// 输入批次（区分真实/历史/预测）
export enum InputBatchKind {
  REAL = 0,       // 真实采样点（持久化）
  HISTORICAL = 1, // 历史点（持久化）
  PREDICTED = 2,  // 预测点（仅渲染预览，不持久化）
}

export interface InputBatch {
  kind: InputBatchKind;
  points: InputPoint[];
}

// 铅笔飞溅点（对应 faa）
export interface PencilSplatPoint {
  x: number;
  y: number;
  rotation: number;  // 弧度
  scale: number;
  opacity: number;   // [0,1]
}

// 持久化笔画点（对应 vm4/r4a + 三次贝塞尔分段）
export interface StrokePathPoint {
  position: Point2D;
  widthFactor: number;  // fc0.e() 逐点宽度因子，默认 1.0
}

// 渲染态笔画（对应 s78 的移植等价物）
export interface StrokeElementData {
  id: string;
  pathPoints: StrokePathPoint[];       // 中心线点序列
  cubicSegments: CubicSegment[];       // 拟合后的贝塞尔段
  splatPoints: PencilSplatPoint[];     // 铅笔专用（非铅笔为空）
  renderSpec: RenderSpec;              // 渲染规格
  transform: TransformMatrix;          // 统一变换矩阵
  bounds: Rect2D;                      // 边界盒
  maskPath: Point2D[];                 // 擦除遮罩点（可选）
  isFinished: boolean;
}

// 渲染规格（对应 vzf WetMirrorRenderSpec）
export interface RenderSpec {
  color: number;             // ARGB 整数
  brushWidth: number;        // 基础笔宽
  inkStyle: InkStyle;
  isHighlighter: boolean;
  isPencil: boolean;
}

// 墨水样式（对应 sz5）
export enum InkStyle {
  FIXED_WIDTH = 0,
  VARIABLE_WIDTH = 1,
  DASH = 2,
  DOTS = 3,
}
```

### 3.3 BrushTypes.ets — 工具与笔刷

```typescript
import { InkStyle } from './StrokeTypes';

// 笔刷样式（对应 z21）
export enum BrushStyle {
  MONO = 0,    // → FIXED_WIDTH
  TAPER = 1,   // → VARIABLE_WIDTH
  DASH = 2,    // → DASH
  DOT = 3,     // → DOTS
}

// 工具类型（对应 zy5）
export enum ToolType {
  DEFAULT = 0,
  SELECTION = 1,
  PARTIAL_ERASER = 2,
  PEN = 3,
  HIGHLIGHTER = 4,
  PENCIL = 5,
  REVIEW = 6,
  WHOLE_ERASER = 7,
}

// 笔刷配置（对应 f21 Brush）
export interface BrushSpec {
  brushStyle: BrushStyle;
  widthSize: number;               // 默认 36.0
  color: number;                   // ARGB，默认 -16777216（黑）
  selectedWidthWellIndex: number;
  selectedColorWellIndex: number;
}

// 工具状态（对应 j0f/jze）
export interface ToolState {
  toolId: string;
  trayOwnerId: string;
  toolType: ToolType;
  trayIndex: number;
  brush: BrushSpec;
  selectionIsFreehand: boolean;
  eraserIsPartial: boolean;
}

// BrushStyle → InkStyle 映射（对应 dxe.a()）
export function brushStyleToInkStyle(style: BrushStyle): InkStyle {
  switch (style) {
    case BrushStyle.MONO: return InkStyle.FIXED_WIDTH;
    case BrushStyle.TAPER: return InkStyle.VARIABLE_WIDTH;
    case BrushStyle.DASH: return InkStyle.DASH;
    case BrushStyle.DOT: return InkStyle.DOTS;
    default: return InkStyle.FIXED_WIDTH;
  }
}
```

### 3.4 ElementTypes.ets — 笔记元素体系

```typescript
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
}

// 多边形元素
export interface PolygonElement extends NoteElementBase {
  type: ElementType.POLYGON;
  vertices: Point2D[];
  isClosed: boolean;
  color: number;
  strokeWidth: number;
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

// 联合类型
export type NoteElement =
  | StrokeElementData
  | EllipseElement
  | PolygonElement
  | TextBlockElement
  | ImageElement;
```

### 3.5 OpTypes.ets — 操作流

```typescript
// op 类型枚举（基于 §21 已确认 + 合理扩展）
export enum OpType {
  // 页面操作
  CREATE_PAGE = 0,
  DELETE_PAGE = 1,
  UPDATE_PAGE = 2,      // 尺寸/模板变更
  REORDER_PAGES = 3,
  // 元素操作
  INSERT_ELEMENTS = 10,
  DELETE_ELEMENTS = 11,
  TRANSFORM_ELEMENTS = 12,
  UPDATE_ELEMENT_STYLE = 13,
  // 擦除
  ERASE_PARTIAL = 20,   // 像素擦除（写入 maskPath）
  ERASE_WHOLE = 21,     // 整条删除
  // 笔记级
  UPDATE_TITLE = 30,
  UNDO = 40,
  REDO = 41,
}

// 单条操作
export interface Op {
  opId: string;
  noteId: string;
  opType: OpType;
  payload: Uint8Array;     // 序列化后的操作内容
  clientTime: number;      // 客户端时间戳 ms
}

// op 序列化器接口
export interface OpSerializer {
  serialize(op: Op): Uint8Array;
  deserialize(data: Uint8Array): Op;
}
```

### 3.6 NoteTypes.ets — 笔记与页面

```typescript
import { Rect2D } from './GeometryTypes';

// 纸张尺寸（对应 e0a）
export enum PaperSize {
  A3 = 0,      // 297×420 mm
  A4 = 1,      // 210×297 mm
  A5 = 2,      // 148×210 mm
  A6 = 3,      // 105×148 mm
  A7 = 4,      // 74×105 mm
  LETTER = 5,  // 8.5×11 in
  LEGAL = 6,   // 8.5×14 in
  TABLOID = 7, // 11×17 in
}

// 纸张模板（对应 lp0）
export enum PaperTemplate {
  PLAIN = 0,
  LINES = 1,
  GRID = 2,
  DOTS = 3,
  DIAGONAL_GRID = 4,
  DECORATIVE = 5,
}

// 页面方向
export enum PageOrientation {
  PORTRAIT = 0,
  LANDSCAPE = 1,
}

// 页面信息
export interface PageInfo {
  pageId: string;
  size: PaperSize;
  template: PaperTemplate;
  orientation: PageOrientation;
  widthMm: number;
  heightMm: number;
}

// 笔记元数据（对应 SyncedNoteMetadata 简化版）
export interface NoteMeta {
  id: string;
  title: string;
  createdAt: number;
  updatedAt: number;
  favorite: boolean;
  lastOpened: number;
  folderId: string | null;
  hasRecordings: boolean;
}

// 笔记视图状态（对应 NoteStateEntity）
export interface NoteViewState {
  noteId: string;
  zoom: number;
  scrollOffsetX: number;
  scrollOffsetY: number;
}
```

### 3.7 AssetTypes.ets — 资源引用

```typescript
// 资源状态
export enum AssetStatus {
  PENDING = 0,
  LOCAL = 1,
  UPLOADED = 2,
  DOWNLOADED = 3,
  FAILED = 4,
}

// 笔记资源（对应 NoteAsset 表）
export interface NoteAsset {
  assetHash: string;      // SHA-256 哈希（主键）
  status: AssetStatus;
  noteIds: string[];      // 关联笔记（多对多）
  fileSize: number;
  mimeType: string;
  localPath: string | null;
}
```

### 3.8 适配层接口

#### InkInputProvider.ets

```typescript
import { InputBatch } from '../model/StrokeTypes';

// 触摸/笔事件抽象（业务层不直接 import @ohos TouchEvent）
export interface RawPointerEvent {
  x: number;
  y: number;
  pressure: number;
  tiltRadians: number;
  orientationRadians: number;
  toolType: number;
  timestamp: number;
  isHistorical: boolean;
}

export interface InkInputProvider {
  // 将平台原始事件转为标准输入批次
  processEvent(rawEvents: RawPointerEvent[], isPredicted: boolean): InputBatch;
  // 获取设备能力
  hasPressureSupport(): boolean;
  hasTiltSupport(): boolean;
  hasOrientationSupport(): boolean;
}
```

#### StrokeRenderer.ets

```typescript
import { StrokeElementData, PencilSplatPoint, RenderSpec } from '../model/StrokeTypes';
import { Rect2D } from '../model/GeometryTypes';

// 渲染上下文抽象（隔离 Canvas/OpenGL 差异）
export interface RenderContext {
  save(): void;
  restore(): void;
  clipRect(rect: Rect2D): void;
  clear(rect: Rect2D): void;
}

export interface StrokeRenderer {
  // 渲染中心线笔画（Mono/Dash/Dot）
  renderCenterPath(stroke: StrokeElementData, ctx: RenderContext): void;
  // 渲染可变宽度填充轮廓（Taper）
  renderVariableWidthOutline(stroke: StrokeElementData, ctx: RenderContext): void;
  // 渲染铅笔飞溅
  renderPencilSplats(splats: PencilSplatPoint[], spec: RenderSpec, ctx: RenderContext): void;
  // 渲染擦除遮罩
  renderEraserMask(stroke: StrokeElementData, ctx: RenderContext): void;
}
```

#### Predictor.ets

```typescript
import { InputPoint } from '../model/StrokeTypes';

export interface Predictor {
  // 基于历史点生成预测点（可为空实现）
  predict(history: InputPoint[]): InputPoint[];
  // 重置状态（新笔画开始时调用）
  reset(): void;
}
```

#### RecognitionProvider.ets（可插拔识别模组）

```typescript
import { Point2D } from '../model/GeometryTypes';
import { NoteElement } from '../model/ElementTypes';

// 识别结果
export interface RecognitionResult {
  confidence: number;       // [0,1]
  elements: NoteElement[];  // 识别产出的元素
}

// 可插拔识别接口（主流程不依赖实现）
export interface RecognitionProvider {
  // 是否可用
  isAvailable(): boolean;
  // 形状识别（笔画完成后调用）
  recognizeShape(points: Point2D[]): RecognitionResult | null;
  // 手写转文字（选区菜单触发）
  recognizeText(points: Point2D[]): string | null;
}
```

### 3.9 OpStore.ets — op 流存储接口

```typescript
import { Op, OpSerializer } from '../model/OpTypes';

export interface OpStore {
  // 追加 op
  appendOp(op: Op): Promise<void>;
  // 读取笔记的全部 op（按 clientTime 排序）
  getOps(noteId: string): Promise<Op[]>;
  // 读取笔记的增量 op
  getOpsSince(noteId: string, sinceTime: number): Promise<Op[]>;
  // 删除笔记的全部 op
  deleteOps(noteId: string): Promise<void>;
  // 获取 op 计数
  getOpCount(noteId: string): Promise<number>;
}
```

### 3.10 DatabaseHelper.ets — DDL 契约

```typescript
// 数据库版本
export const DB_VERSION: number = 1;
export const DB_NAME: string = 'nota.db';

// DDL 语句（工人实现时直接执行）
export const DDL_NOTE_STATE: string = `
CREATE TABLE IF NOT EXISTS note_state (
  note_id TEXT PRIMARY KEY,
  zoom REAL NOT NULL DEFAULT 1.0,
  scroll_offset_x REAL NOT NULL DEFAULT 0,
  scroll_offset_y REAL NOT NULL DEFAULT 0
)`;

export const DDL_TOOL_STATE: string = `
CREATE TABLE IF NOT EXISTS tool_state (
  tool_id TEXT PRIMARY KEY,
  tray_owner_id TEXT NOT NULL,
  tool_type INTEGER NOT NULL,
  tray_index INTEGER NOT NULL,
  color INTEGER NOT NULL DEFAULT -16777216,
  width_size REAL NOT NULL DEFAULT 36.0,
  style INTEGER NOT NULL DEFAULT 0,
  selected_color_well_index INTEGER NOT NULL DEFAULT 0,
  selected_width_well_index INTEGER NOT NULL DEFAULT 0,
  selection_is_freehand INTEGER NOT NULL DEFAULT 0,
  eraser_is_partial INTEGER NOT NULL DEFAULT 0
)`;

export const DDL_CLIENT_OP: string = `
CREATE TABLE IF NOT EXISTS client_op (
  op_id TEXT PRIMARY KEY,
  note_id TEXT NOT NULL,
  op_type INTEGER NOT NULL,
  payload BLOB NOT NULL,
  client_time INTEGER NOT NULL
)`;

export const DDL_NOTE_ASSET: string = `
CREATE TABLE IF NOT EXISTS note_asset (
  asset_hash TEXT PRIMARY KEY,
  status INTEGER NOT NULL DEFAULT 0,
  note_ids TEXT NOT NULL DEFAULT '[]',
  file_size INTEGER NOT NULL DEFAULT 0,
  mime_type TEXT NOT NULL DEFAULT '',
  local_path TEXT
)`;

export const DDL_NOTE_META: string = `
CREATE TABLE IF NOT EXISTS note_meta (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL DEFAULT '',
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  favorite INTEGER NOT NULL DEFAULT 0,
  last_opened INTEGER NOT NULL DEFAULT 0,
  folder_id TEXT,
  has_recordings INTEGER NOT NULL DEFAULT 0
)`;

export const DDL_PAGE_INFO: string = `
CREATE TABLE IF NOT EXISTS page_info (
  page_id TEXT PRIMARY KEY,
  note_id TEXT NOT NULL,
  page_index INTEGER NOT NULL,
  size INTEGER NOT NULL DEFAULT 1,
  template INTEGER NOT NULL DEFAULT 0,
  orientation INTEGER NOT NULL DEFAULT 0,
  width_mm REAL NOT NULL DEFAULT 210.0,
  height_mm REAL NOT NULL DEFAULT 297.0
)`;

// 索引
export const DDL_INDEXES: string[] = [
  'CREATE INDEX IF NOT EXISTS idx_client_op_note ON client_op(note_id, client_time)',
  'CREATE INDEX IF NOT EXISTS idx_page_info_note ON page_info(note_id, page_index)',
  'CREATE INDEX IF NOT EXISTS idx_note_meta_folder ON note_meta(folder_id)',
];
```

### 3.11 RepositoryInterfaces.ets

```typescript
import { NoteMeta, NoteViewState, PageInfo } from '../core/model/NoteTypes';
import { ToolState } from '../core/model/BrushTypes';
import { NoteAsset } from '../core/model/AssetTypes';

export interface NoteRepository {
  createNote(title: string, folderId: string | null): Promise<NoteMeta>;
  getNote(noteId: string): Promise<NoteMeta | null>;
  getAllNotes(): Promise<NoteMeta[]>;
  getNotesByFolder(folderId: string): Promise<NoteMeta[]>;
  updateNote(note: NoteMeta): Promise<void>;
  deleteNote(noteId: string): Promise<void>;
  getViewState(noteId: string): Promise<NoteViewState | null>;
  saveViewState(state: NoteViewState): Promise<void>;
}

export interface PageRepository {
  getPages(noteId: string): Promise<PageInfo[]>;
  addPage(noteId: string, page: PageInfo): Promise<void>;
  deletePage(noteId: string, pageId: string): Promise<void>;
  updatePage(page: PageInfo): Promise<void>;
  reorderPages(noteId: string, pageIds: string[]): Promise<void>;
}

export interface ToolRepository {
  getToolStates(ownerId: string): Promise<ToolState[]>;
  saveToolState(state: ToolState): Promise<void>;
}

export interface AssetRepository {
  getAsset(hash: string): Promise<NoteAsset | null>;
  saveAsset(asset: NoteAsset): Promise<void>;
  getAssetsByNote(noteId: string): Promise<NoteAsset[]>;
  deleteAsset(hash: string): Promise<void>;
}
```

---

## 4. 涉及鸿蒙 API 与权限

| API | 起始版本 | SystemCapability | 用途 |
|-----|----------|------------------|------|
| @ohos.data.relationalStore | 9 | SystemCapability.DistributedDataManager.RelationalStore | 数据库 |
| @kit.Penkit (PointPredictor) | 5.0.0(12) | SystemCapability.Stylus.Handwrite | 预测点（Phase 2） |
| TouchEvent | 7 | 无特殊 | 输入采集（Phase 2） |

Phase 1 仅使用 relationalStore（DDL 定义），不涉及运行时权限。

---

## 5. 任务卡拆分预览

| 卡号 | 名称 | 产出文件 |
|------|------|----------|
| T-001 | 基础几何与笔画类型 | GeometryTypes.ets + StrokeTypes.ets |
| T-002 | 笔刷与工具类型 | BrushTypes.ets |
| T-003 | 笔记元素体系 | ElementTypes.ets |
| T-004 | 操作流类型与存储接口 | OpTypes.ets + OpStore.ets |
| T-005 | 笔记/页面/资源类型 | NoteTypes.ets + AssetTypes.ets |
| T-006 | 适配层四接口 | InkInputProvider.ets + StrokeRenderer.ets + Predictor.ets + RecognitionProvider.ets |
| T-007 | 数据库 DDL 与 Repository 接口 | DatabaseHelper.ets + RepositoryInterfaces.ets |

每张卡独立可编译；T-002~T-007 依赖 T-001 的类型定义。

---

## 6. 约束提醒

- 所有 model/ 下文件**禁止** import `@ohos.*` 或 `@kit.*`。
- adaptation/ 接口定义文件可以引用平台类型作为参数（如 RawPointerEvent 映射 TouchPoint），但接口签名本身不绑定具体实现类。
- 使用 `export` 导出所有公共类型；不使用 `any`；所有函数参数和返回值显式标注类型。
- 枚举使用数字值（便于数据库存储和序列化）。
