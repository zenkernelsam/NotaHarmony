// T-005 笔记/页面类型（契约 phase-1-data-model.md §3.6，照搬，禁止修改签名）
// 纯类型文件：禁止 import 任何 @ohos.* / @kit.* 平台模块

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

// Original 1.0.3 n3a values. Keep the wire values stable.
export enum OriginalPaperFlair {
  LINES = 0,
  DOTS = 1,
  GRID = 2,
}

export interface PagePaperBackground {
  flair: OriginalPaperFlair | null;
  flairSpacingPt: number | null;
  flairBleeds: boolean | null;
  flairCentered: boolean | null;
  colorR: number | null;
  colorG: number | null;
  colorB: number | null;
  colorA: number | null;
  legacyPaperIndex: number | null;
}

export interface PageBackgroundMargins {
  topPt: number;
  bottomPt: number;
  leftPt: number;
  rightPt: number;
}

// Original 1.0.3 xw9 wire values.
export enum PdfLayoutBehavior {
  DOWNSCALING_AND_MAX_BOX = 0,
  DOWNSCALING_AND_CROP_BOX = 1,
  FIT_AND_CROP_BOX = 2,
}

export interface OriginalAssetMetadata {
  assetHashBits: string[];
  fileName: string;
  mimeType: string;
  fileSize: number;
}

export interface PdfCropBoxSize {
  widthPt: number;
  heightPt: number;
}

export interface PagePdfBackground {
  metadata: OriginalAssetMetadata;
  layoutBehavior: PdfLayoutBehavior;
  totalPageCount: number;
  pagesConsumed: number;
  pageOffset: number;
  cropBoxes: PdfCropBoxSize[];
  // wz9 keeps this in an independent register. It is copied here only on the
  // effective/renderable value so package exports remain self-contained.
  pageInAsset: number;
}

export interface PageBackground {
  schemaVersion: number;
  paper: PagePaperBackground | null;
  pdf?: PagePdfBackground | null;
  rotationRadians: number;
  sourceWidthPt: number | null;
  sourceHeightPt: number | null;
  margins: PageBackgroundMargins | null;
}

// 页面信息
export interface PageInfo {
  pageId: string;
  pageIndex: number;
  size: PaperSize;
  template: PaperTemplate;
  orientation: PageOrientation;
  widthMm: number;
  heightMm: number;
  background?: PageBackground | null;
  // Effective note-level fallback. This is loaded separately from the nullable
  // page register and must never be written back as the page background.
  noteBackgroundFallback?: PageBackground | null;
  // Original wz9 pageInAsset register. Undefined denotes a local/non-original
  // page; original pages always materialize an unsigned uint32 value.
  originalPageInAsset?: number;
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
export const CURRENT_VIEW_COORDINATE_MODEL_VERSION: number = 1;

export function isCurrentViewCoordinateModel(version: number): boolean {
  return version === CURRENT_VIEW_COORDINATE_MODEL_VERSION;
}

export interface NoteViewState {
  noteId: string;
  zoom: number;
  scrollOffsetX: number;
  scrollOffsetY: number;
  coordinateModelVersion: number;
}
