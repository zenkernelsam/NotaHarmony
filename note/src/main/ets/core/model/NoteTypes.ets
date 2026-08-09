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

// 页面信息
export interface PageInfo {
  pageId: string;
  pageIndex: number;
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
