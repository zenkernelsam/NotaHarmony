// T-021 基于 op 栈的撤销/重做管理器（纯逻辑，禁止平台 import）
// 全笔记单栈：动作携带 pageId，保持跨页操作的真实时间顺序。
// 原版 NoteImpl 使用全笔记 opHistory；文本编辑器 nnf(100) 是另一套局部历史，不能作为这里的容量。
import { StrokeElementData } from '../core/model/StrokeTypes';
import { ElementType, ShapeElement, TextBlockElement } from '../core/model/ElementTypes';
import { PageInfo } from '../core/model/NoteTypes';
import { PageElementRef } from '../core/model/PageElementOrder';

// 可撤销的操作类型
export enum UndoableActionType {
  ADD_STROKE = 0,
  DELETE_STROKE = 1,
  ERASE_STROKES = 2,
  TRANSFORM_STROKES = 3,
  ADD_ELEMENT = 4,       // 文本框创建
  DELETE_ELEMENT = 5,    // 文本框删除
  REPLACE_ELEMENT = 6,   // 形状替换（笔画→形状，before=原笔画）
  ADD_PAGE = 7,
  DELETE_PAGE = 8,
  REORDER_PAGES = 9,
  PAGE_SETTINGS = 10,
  REORDER_ELEMENTS = 11,
  ADD_SHAPE = 12,
  DELETE_ELEMENTS = 13,
  TRANSFORM_ELEMENTS = 14,
  ERASE_ELEMENTS = 15,
  ADD_ELEMENTS = 16,
}

interface ActionBase {
  type: UndoableActionType;
  noteId: string;
  pageId: string;
}

interface ElementOrderChange {
  elementOrderBefore: PageElementRef[];
  elementOrderAfter: PageElementRef[];
}

export interface AddStrokeAction extends ActionBase, ElementOrderChange {
  type: UndoableActionType.ADD_STROKE;
  addedStrokes: StrokeElementData[];
}

export interface RemoveStrokeAction extends ActionBase, ElementOrderChange {
  type: UndoableActionType.DELETE_STROKE;
  removedStrokes: StrokeElementData[];
  removedStrokeIndices: number[];
  beforeModifiedStrokes: StrokeElementData[];
  afterModifiedStrokes: StrokeElementData[];
}

export interface EraseElementsAction extends ActionBase, ElementOrderChange {
  type: UndoableActionType.ERASE_ELEMENTS;
  removedStrokes: StrokeElementData[];
  removedStrokeIndices: number[];
  beforeModifiedStrokes: StrokeElementData[];
  afterModifiedStrokes: StrokeElementData[];
  removedShapes: ShapeElement[];
  removedShapeIndices: number[];
  removedTextBlocks: TextBlockElement[];
  removedTextBlockIndices: number[];
}

export interface TransformStrokesAction extends ActionBase {
  type: UndoableActionType.TRANSFORM_STROKES;
  beforeStrokes: StrokeElementData[];
  afterStrokes: StrokeElementData[];
}

export interface AddElementAction extends ActionBase, ElementOrderChange {
  type: UndoableActionType.ADD_ELEMENT;
  addedElement: TextBlockElement;
}

export interface DeleteElementAction extends ActionBase, ElementOrderChange {
  type: UndoableActionType.DELETE_ELEMENT;
  removedElements: TextBlockElement[];
}

export interface ReplaceElementAction extends ActionBase {
  type: UndoableActionType.REPLACE_ELEMENT;
  beforeStrokes: StrokeElementData[];
  afterStrokes: StrokeElementData[];
  beforeElements: TextBlockElement[];
  afterElements: TextBlockElement[];
}

export interface ReorderElementsAction extends ActionBase, ElementOrderChange {
  type: UndoableActionType.REORDER_ELEMENTS;
}

export interface AddShapeAction extends ActionBase, ElementOrderChange {
  type: UndoableActionType.ADD_SHAPE;
  addedShape: ShapeElement;
}

export interface AddElementsAction extends ActionBase, ElementOrderChange {
  type: UndoableActionType.ADD_ELEMENTS;
  addedStrokes: StrokeElementData[];
  addedShapes: ShapeElement[];
  addedTextBlocks: TextBlockElement[];
  addedElementOrder: PageElementRef[];
}

export interface DeleteElementsAction extends ActionBase, ElementOrderChange {
  type: UndoableActionType.DELETE_ELEMENTS;
  removedStrokes: StrokeElementData[];
  removedStrokeIndices: number[];
  removedShapes: ShapeElement[];
  removedShapeIndices: number[];
  removedTextBlocks: TextBlockElement[];
  removedTextBlockIndices: number[];
}

export interface TransformElementsAction extends ActionBase {
  type: UndoableActionType.TRANSFORM_ELEMENTS;
  beforeStrokes: StrokeElementData[];
  afterStrokes: StrokeElementData[];
  beforeShapes: ShapeElement[];
  afterShapes: ShapeElement[];
  beforeTextBlocks: TextBlockElement[];
  afterTextBlocks: TextBlockElement[];
}

export interface AddPageAction extends ActionBase {
  type: UndoableActionType.ADD_PAGE;
  pageAfter: PageInfo;
  pageOrderBefore: string[];
  pageOrderAfter: string[];
  pageStrokes: StrokeElementData[];
  pageTextBlocks: TextBlockElement[];
  pageShapes: ShapeElement[];
  pageElementOrder: PageElementRef[];
  selectedPageIdBefore: string;
  selectedPageIdAfter: string;
}

export interface DeletePageAction extends ActionBase {
  type: UndoableActionType.DELETE_PAGE;
  pageBefore: PageInfo;
  pageOrderBefore: string[];
  pageOrderAfter: string[];
  pageStrokes: StrokeElementData[];
  pageTextBlocks: TextBlockElement[];
  pageShapes: ShapeElement[];
  pageElementOrder: PageElementRef[];
  selectedPageIdBefore: string;
  selectedPageIdAfter: string;
}

export interface ReorderPagesAction extends ActionBase {
  type: UndoableActionType.REORDER_PAGES;
  pageOrderBefore: string[];
  pageOrderAfter: string[];
}

export interface PageSettingsAction extends ActionBase {
  type: UndoableActionType.PAGE_SETTINGS;
  pageBefore: PageInfo;
  pageAfter: PageInfo;
}

export type UndoableAction = AddStrokeAction | RemoveStrokeAction | TransformStrokesAction |
  AddElementAction | DeleteElementAction | ReplaceElementAction | ReorderElementsAction |
  AddShapeAction | AddElementsAction | DeleteElementsAction | TransformElementsAction | EraseElementsAction |
  AddPageAction | DeletePageAction | ReorderPagesAction | PageSettingsAction;

export interface PageContentSnapshot {
  strokes: StrokeElementData[];
  textBlocks: TextBlockElement[];
  shapes: ShapeElement[];
  elementOrder: PageElementRef[];
}

export interface EditorHistoryBridge {
  pushPageAction: (action: UndoableAction) => void;
  captureCurrentPage: () => PageContentSnapshot;
  preparePageRemoval: (pageId: string) => void;
  cancelPageRemoval: (pageId: string) => void;
  flushCurrentPage: () => Promise<boolean>;
}

export interface HistoryBudget {
  maxActions: number;
  maxEstimatedBytes: number;
}

export interface HistoryMetrics {
  undoActions: number;
  redoActions: number;
  estimatedBytes: number;
  evictedActions: number;
  evictedEstimatedBytes: number;
}

interface HistoryEntry {
  action: UndoableAction;
  estimatedBytes: number;
}

const DEFAULT_HISTORY_MAX_ACTIONS: number = 128;
const DEFAULT_HISTORY_MAX_BYTES: number = 32 * 1024 * 1024;

export function estimateHistoryActionBytes(action: UndoableAction): number {
  let bytes: number = 256 + (action.noteId.length + action.pageId.length) * 2;
  if (action.type === UndoableActionType.ADD_STROKE) {
    return bytes + estimateStrokes(action.addedStrokes) + estimateElementOrderChange(action);
  }
  if (action.type === UndoableActionType.DELETE_STROKE) {
    return bytes + estimateStrokes(action.removedStrokes) + action.removedStrokeIndices.length * 8 +
      estimateStrokes(action.beforeModifiedStrokes) + estimateStrokes(action.afterModifiedStrokes) +
      estimateElementOrderChange(action);
  }
  if (action.type === UndoableActionType.ERASE_ELEMENTS) {
    return bytes + estimateStrokes(action.removedStrokes) + action.removedStrokeIndices.length * 8 +
      estimateStrokes(action.beforeModifiedStrokes) + estimateStrokes(action.afterModifiedStrokes) +
      estimateShapes(action.removedShapes) + action.removedShapeIndices.length * 8 +
      estimateTextBlocks(action.removedTextBlocks) + action.removedTextBlockIndices.length * 8 +
      estimateElementOrderChange(action);
  }
  if (action.type === UndoableActionType.TRANSFORM_STROKES) {
    return bytes + estimateStrokes(action.beforeStrokes) + estimateStrokes(action.afterStrokes);
  }
  if (action.type === UndoableActionType.ADD_ELEMENT) {
    return bytes + estimateTextBlock(action.addedElement) + estimateElementOrderChange(action);
  }
  if (action.type === UndoableActionType.DELETE_ELEMENT) {
    return bytes + estimateTextBlocks(action.removedElements) + estimateElementOrderChange(action);
  }
  if (action.type === UndoableActionType.REPLACE_ELEMENT) {
    return bytes + estimateStrokes(action.beforeStrokes) + estimateStrokes(action.afterStrokes) +
      estimateTextBlocks(action.beforeElements) + estimateTextBlocks(action.afterElements);
  }
  if (action.type === UndoableActionType.REORDER_ELEMENTS) {
    return bytes + estimateElementOrderChange(action);
  }
  if (action.type === UndoableActionType.ADD_SHAPE) {
    return bytes + estimateShape(action.addedShape) + estimateElementOrderChange(action);
  }
  if (action.type === UndoableActionType.ADD_ELEMENTS) {
    return bytes + estimateStrokes(action.addedStrokes) + estimateShapes(action.addedShapes) +
      estimateTextBlocks(action.addedTextBlocks) +
      estimateElementOrder(action.addedElementOrder) + estimateElementOrderChange(action);
  }
  if (action.type === UndoableActionType.DELETE_ELEMENTS) {
    return bytes + estimateStrokes(action.removedStrokes) + action.removedStrokeIndices.length * 8 +
      estimateShapes(action.removedShapes) + action.removedShapeIndices.length * 8 +
      estimateTextBlocks(action.removedTextBlocks) + action.removedTextBlockIndices.length * 8 +
      estimateElementOrderChange(action);
  }
  if (action.type === UndoableActionType.TRANSFORM_ELEMENTS) {
    return bytes + estimateStrokes(action.beforeStrokes) + estimateStrokes(action.afterStrokes) +
      estimateShapes(action.beforeShapes) + estimateShapes(action.afterShapes) +
      estimateTextBlocks(action.beforeTextBlocks) + estimateTextBlocks(action.afterTextBlocks);
  }
  if (action.type === UndoableActionType.ADD_PAGE || action.type === UndoableActionType.DELETE_PAGE) {
    return bytes + 256 + estimateStringList(action.pageOrderBefore) + estimateStringList(action.pageOrderAfter) +
      estimateStrokes(action.pageStrokes) + estimateTextBlocks(action.pageTextBlocks) +
      estimateShapes(action.pageShapes) + estimateElementOrder(action.pageElementOrder);
  }
  if (action.type === UndoableActionType.REORDER_PAGES) {
    return bytes + estimateStringList(action.pageOrderBefore) + estimateStringList(action.pageOrderAfter);
  }
  return bytes + 512;
}

function estimateElementOrderChange(action: ElementOrderChange): number {
  return estimateElementOrder(action.elementOrderBefore) + estimateElementOrder(action.elementOrderAfter);
}

function estimateElementOrder(order: PageElementRef[]): number {
  let bytes: number = order.length * 32;
  for (const ref of order) {
    bytes += ref.elementId.length * 2;
  }
  return bytes;
}

function estimateStrokes(strokes: StrokeElementData[]): number {
  let bytes: number = 0;
  for (const stroke of strokes) {
    bytes += 384 + stroke.id.length * 2 + stroke.transform.length * 8 +
      stroke.pathPoints.length * 64 + stroke.cubicSegments.length * 112 +
      stroke.splatPoints.length * 40 + stroke.maskPath.length * 16;
  }
  return bytes;
}

function estimateTextBlocks(blocks: TextBlockElement[]): number {
  let bytes: number = 0;
  for (const block of blocks) {
    bytes += estimateTextBlock(block);
  }
  return bytes;
}

function estimateTextBlock(block: TextBlockElement): number {
  return 384 + (block.id.length + block.richText.length) * 2 + block.transform.length * 8;
}

function estimateShapes(shapes: ShapeElement[]): number {
  let bytes: number = 0;
  for (const shape of shapes) {
    bytes += estimateShape(shape);
  }
  return bytes;
}

function estimateShape(shape: ShapeElement): number {
  let bytes: number = 384 + shape.id.length * 2 + shape.transform.length * 8;
  if (shape.type === ElementType.POLYGON) {
    bytes += shape.vertices.length * 32;
  } else if (shape.type === ElementType.LINE) {
    bytes += 96;
  }
  return bytes;
}

function estimateStringList(values: string[]): number {
  let bytes: number = values.length * 16;
  for (const value of values) {
    bytes += value.length * 2;
  }
  return bytes;
}

function normalizeBudget(value: number, fallback: number, integer: boolean): number {
  if (!Number.isFinite(value) || value <= 0) {
    return fallback;
  }
  return integer ? Math.max(1, Math.floor(value)) : Math.max(1, value);
}

export class UndoRedoManager {
  private undoStack: HistoryEntry[] = [];
  private redoStack: HistoryEntry[] = [];
  private maxActions: number;
  private maxEstimatedBytes: number;
  private undoBytes: number = 0;
  private redoBytes: number = 0;
  private evictedActions: number = 0;
  private evictedEstimatedBytes: number = 0;

  constructor(budget: number | HistoryBudget = {
    maxActions: DEFAULT_HISTORY_MAX_ACTIONS,
    maxEstimatedBytes: DEFAULT_HISTORY_MAX_BYTES,
  }) {
    this.maxActions = normalizeBudget(typeof budget === 'number' ? budget : budget.maxActions,
      DEFAULT_HISTORY_MAX_ACTIONS, true);
    this.maxEstimatedBytes = normalizeBudget(
      typeof budget === 'number' ? DEFAULT_HISTORY_MAX_BYTES : budget.maxEstimatedBytes,
      DEFAULT_HISTORY_MAX_BYTES, false);
  }

  // 记录操作（清空 redoStack）
  push(action: UndoableAction): void {
    const entry: HistoryEntry = { action: action, estimatedBytes: estimateHistoryActionBytes(action) };
    this.undoStack.push(entry);
    this.undoBytes += entry.estimatedBytes;
    this.redoStack = [];
    this.redoBytes = 0;
    while (this.undoStack.length > this.maxActions || this.undoBytes > this.maxEstimatedBytes) {
      const evicted: HistoryEntry | undefined = this.undoStack.shift();
      if (evicted === undefined) {
        break;
      }
      this.undoBytes -= evicted.estimatedBytes;
      this.evictedActions++;
      this.evictedEstimatedBytes += evicted.estimatedBytes;
    }
  }

  peekUndo(): UndoableAction | null {
    return this.undoStack.length > 0 ? this.undoStack[this.undoStack.length - 1].action : null;
  }

  commitUndo(expected: UndoableAction): boolean {
    if (this.peekUndo() !== expected) {
      return false;
    }
    const entry: HistoryEntry | undefined = this.undoStack.pop();
    if (entry === undefined) {
      return false;
    }
    this.undoBytes -= entry.estimatedBytes;
    this.redoStack.push(entry);
    this.redoBytes += entry.estimatedBytes;
    return true;
  }

  peekRedo(): UndoableAction | null {
    return this.redoStack.length > 0 ? this.redoStack[this.redoStack.length - 1].action : null;
  }

  commitRedo(expected: UndoableAction): boolean {
    if (this.peekRedo() !== expected) {
      return false;
    }
    const entry: HistoryEntry | undefined = this.redoStack.pop();
    if (entry === undefined) {
      return false;
    }
    this.redoBytes -= entry.estimatedBytes;
    this.undoStack.push(entry);
    this.undoBytes += entry.estimatedBytes;
    return true;
  }

  canUndo(): boolean {
    return this.undoStack.length > 0;
  }

  canRedo(): boolean {
    return this.redoStack.length > 0;
  }

  clear(): void {
    this.undoStack = [];
    this.redoStack = [];
    this.undoBytes = 0;
    this.redoBytes = 0;
  }

  getMetrics(): HistoryMetrics {
    return {
      undoActions: this.undoStack.length,
      redoActions: this.redoStack.length,
      estimatedBytes: this.undoBytes + this.redoBytes,
      evictedActions: this.evictedActions,
      evictedEstimatedBytes: this.evictedEstimatedBytes,
    };
  }
}
