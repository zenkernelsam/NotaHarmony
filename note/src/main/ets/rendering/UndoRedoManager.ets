// T-021 基于 op 栈的撤销/重做管理器（纯逻辑，禁止平台 import）
// 全笔记单栈：动作携带 pageId，保持跨页操作的真实时间顺序。
// 原版 NoteImpl 使用全笔记 opHistory；文本编辑器 nnf(100) 是另一套局部历史，不能作为这里的容量。
import { InkPathCommand, StrokeElementData } from '../core/model/StrokeTypes';
import { ElementType, RichTextCharacterStyleRun, RichTextParagraphStyleRun,
  ImageElement, MathElement, ShapeElement, TextBlockElement } from '../core/model/ElementTypes';
import { PageInfo } from '../core/model/NoteTypes';
import { PageElementRef } from '../core/model/PageElementOrder';
import { HistoryCoalesceTrack, HistoryEffect, HistoryMetadata, Op } from '../core/model/OpTypes';

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
  PERSISTED_PAGE_MUTATIONS = 17,
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
  removedImages: ImageElement[];
  removedImageIndices: number[];
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
  addedImages: ImageElement[];
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
  removedImages: ImageElement[];
  removedImageIndices: number[];
}

export interface TransformElementsAction extends ActionBase {
  type: UndoableActionType.TRANSFORM_ELEMENTS;
  beforeStrokes: StrokeElementData[];
  afterStrokes: StrokeElementData[];
  beforeShapes: ShapeElement[];
  afterShapes: ShapeElement[];
  beforeTextBlocks: TextBlockElement[];
  afterTextBlocks: TextBlockElement[];
  beforeImages: ImageElement[];
  afterImages: ImageElement[];
}

export interface AddPageAction extends ActionBase {
  type: UndoableActionType.ADD_PAGE;
  pageAfter: PageInfo;
  pageOrderBefore: string[];
  pageOrderAfter: string[];
  pageStrokes: StrokeElementData[];
  pageTextBlocks: TextBlockElement[];
  pageShapes: ShapeElement[];
  pageImages: ImageElement[];
  pageMathBlocks?: MathElement[];
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
  pageImages: ImageElement[];
  pageMathBlocks?: MathElement[];
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

export interface PersistedPageMutationsAction extends ActionBase {
  type: UndoableActionType.PERSISTED_PAGE_MUTATIONS;
  operations: Op[];
}

export type UndoableAction = AddStrokeAction | RemoveStrokeAction | TransformStrokesAction |
  AddElementAction | DeleteElementAction | ReplaceElementAction | ReorderElementsAction |
  AddShapeAction | AddElementsAction | DeleteElementsAction | TransformElementsAction | EraseElementsAction |
  AddPageAction | DeletePageAction | ReorderPagesAction | PageSettingsAction | PersistedPageMutationsAction;

export interface RestoredHistoryAction {
  action: UndoableAction;
  history: HistoryMetadata;
}

export interface HistoryMove {
  action: UndoableAction;
  history: HistoryMetadata;
}

export interface PageContentSnapshot {
  strokes: StrokeElementData[];
  textBlocks: TextBlockElement[];
  shapes: ShapeElement[];
  images: ImageElement[];
  mathBlocks: MathElement[];
  elementOrder: PageElementRef[];
}

export interface EditorHistoryBridge {
  preparePageAction: (action: UndoableAction) => HistoryMetadata;
  pushPageAction: (action: UndoableAction, history?: HistoryMetadata) => void;
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
  history: HistoryMetadata;
}

const DEFAULT_HISTORY_MAX_ACTIONS: number = 128;
const DEFAULT_HISTORY_MAX_BYTES: number = 32 * 1024 * 1024;
const INSERT_TEXT_COALESCE_MS: number = 2000;
const REMOVE_TEXT_COALESCE_MS: number = 2000;
const CREATE_INK_COALESCE_MS: number = 10;

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
      estimateImages(action.removedImages) + action.removedImageIndices.length * 8 +
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
      estimateTextBlocks(action.addedTextBlocks) + estimateImages(action.addedImages) +
      estimateElementOrder(action.addedElementOrder) + estimateElementOrderChange(action);
  }
  if (action.type === UndoableActionType.DELETE_ELEMENTS) {
    return bytes + estimateStrokes(action.removedStrokes) + action.removedStrokeIndices.length * 8 +
      estimateShapes(action.removedShapes) + action.removedShapeIndices.length * 8 +
      estimateTextBlocks(action.removedTextBlocks) + action.removedTextBlockIndices.length * 8 +
      estimateImages(action.removedImages) + action.removedImageIndices.length * 8 +
      estimateElementOrderChange(action);
  }
  if (action.type === UndoableActionType.TRANSFORM_ELEMENTS) {
    return bytes + estimateStrokes(action.beforeStrokes) + estimateStrokes(action.afterStrokes) +
      estimateShapes(action.beforeShapes) + estimateShapes(action.afterShapes) +
      estimateTextBlocks(action.beforeTextBlocks) + estimateTextBlocks(action.afterTextBlocks) +
      estimateImages(action.beforeImages) + estimateImages(action.afterImages);
  }
  if (action.type === UndoableActionType.ADD_PAGE || action.type === UndoableActionType.DELETE_PAGE) {
    return bytes + 256 + estimateStringList(action.pageOrderBefore) + estimateStringList(action.pageOrderAfter) +
      estimateStrokes(action.pageStrokes) + estimateTextBlocks(action.pageTextBlocks) +
      estimateShapes(action.pageShapes) + estimateImages(action.pageImages) +
      estimateMathBlocks(action.pageMathBlocks ?? []) +
      estimateElementOrder(action.pageElementOrder);
  }
  if (action.type === UndoableActionType.REORDER_PAGES) {
    return bytes + estimateStringList(action.pageOrderBefore) + estimateStringList(action.pageOrderAfter);
  }
  if (action.type === UndoableActionType.PERSISTED_PAGE_MUTATIONS) {
    let operationBytes: number = 0;
    for (const operation of action.operations) {
      operationBytes += operation.payload.length + operation.opId.length * 2 + 128;
    }
    return bytes + operationBytes;
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
      stroke.splatPoints.length * 40 + stroke.maskPath.length * 16 +
      estimateInkPath(stroke.customPath) + estimateInkPath(stroke.fillPath);
  }
  return bytes;
}

function estimateInkPath(path: InkPathCommand[] | null | undefined): number {
  if (path === null || path === undefined) {
    return 0;
  }
  let bytes: number = path.length * 24;
  for (const command of path) {
    bytes += command.points.length * 16;
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
  return 384 + (block.id.length + block.richText.length) * 2 + block.transform.length * 8 +
    estimateCharacterStyleRuns(block.characterStyleRuns) +
    estimateParagraphStyleRuns(block.paragraphStyleRuns);
}

function estimateCharacterStyleRuns(runs: RichTextCharacterStyleRun[] | undefined): number {
  if (runs === undefined) {
    return 0;
  }
  let bytes: number = runs.length * 32;
  for (const run of runs) {
    bytes += Object.keys(run.style).length * 16;
    if (run.style.familyName !== undefined) {
      bytes += run.style.familyName.length * 2;
    }
    if (run.style.link !== undefined) {
      bytes += run.style.link.length * 2;
    }
  }
  return bytes;
}

function estimateParagraphStyleRuns(runs: RichTextParagraphStyleRun[] | undefined): number {
  if (runs === undefined) {
    return 0;
  }
  let bytes: number = runs.length * 32;
  for (const run of runs) {
    bytes += Object.keys(run.style).length * 16;
    if (run.style.programmingLanguage !== undefined) {
      bytes += run.style.programmingLanguage.length * 2;
    }
  }
  return bytes;
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

function estimateImages(images: ImageElement[]): number {
  let bytes: number = 0;
  for (const image of images) {
    bytes += 512 + image.transform.length * 8 + image.assetHashBits.length * 48 +
      (image.id.length + image.assetHash.length + image.fileName.length + image.mimeType.length) * 2;
    if (image.webUrl !== null) {
      bytes += image.webUrl.length * 2;
    }
  }
  return bytes;
}

function estimateMathBlocks(blocks: MathElement[]): number {
  let bytes: number = 0;
  for (const block of blocks) {
    bytes += 384 + block.transform.length * 8 + (block.id.length + block.latex.length) * 2;
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
  private historyRevision: number = 0;
  private actionCounter: number = 0;
  private latestHistory: HistoryMetadata | null = null;

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
  push(action: UndoableAction, prepared?: HistoryMetadata): void {
    const entry: HistoryEntry = {
      action: action,
      estimatedBytes: estimateHistoryActionBytes(action),
      history: prepared === undefined ? this.createHistoryMetadata(action) : this.acceptPreparedHistory(prepared),
    };
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
    this.latestHistory = this.withEffect(entry.history, HistoryEffect.PUSH);
    this.advanceHistoryRevision();
  }

  peekUndo(): UndoableAction | null {
    return this.undoStack.length > 0 ? this.undoStack[this.undoStack.length - 1].action : null;
  }

  peekUndoGroup(): HistoryMove[] {
    return this.peekGroup(this.undoStack, HistoryEffect.UNDO);
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
    this.latestHistory = this.withEffect(entry.history, HistoryEffect.UNDO);
    this.advanceHistoryRevision();
    return true;
  }

  peekRedo(): UndoableAction | null {
    return this.redoStack.length > 0 ? this.redoStack[this.redoStack.length - 1].action : null;
  }

  peekRedoGroup(): HistoryMove[] {
    return this.peekGroup(this.redoStack, HistoryEffect.REDO);
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
    this.latestHistory = this.withEffect(entry.history, HistoryEffect.REDO);
    this.advanceHistoryRevision();
    return true;
  }

  commitUndoGroup(expected: HistoryMove[]): boolean {
    return this.commitGroup(expected, true);
  }

  commitRedoGroup(expected: HistoryMove[]): boolean {
    return this.commitGroup(expected, false);
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
    this.latestHistory = null;
    this.historyRevision = 0;
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

  getHistoryRevision(): number {
    return this.historyRevision;
  }

  getLatestHistoryMetadata(): HistoryMetadata | null {
    return this.latestHistory === null ? null : this.withEffect(this.latestHistory, this.latestHistory.effect);
  }

  restore(undo: RestoredHistoryAction[], redo: RestoredHistoryAction[]): void {
    const restoredUndo: HistoryEntry[] = [];
    const restoredRedo: HistoryEntry[] = [];
    const actionIds: Set<string> = new Set<string>();
    let restoredUndoBytes: number = 0;
    let restoredRedoBytes: number = 0;
    for (const restored of undo) {
      const entry: HistoryEntry = this.restoredEntry(restored);
      if (actionIds.has(entry.history.actionId)) {
        throw new Error('restored history contains a duplicate action identity');
      }
      actionIds.add(entry.history.actionId);
      restoredUndo.push(entry);
      restoredUndoBytes += entry.estimatedBytes;
    }
    for (const restored of redo) {
      const entry: HistoryEntry = this.restoredEntry(restored);
      if (actionIds.has(entry.history.actionId)) {
        throw new Error('restored history contains a duplicate action identity');
      }
      actionIds.add(entry.history.actionId);
      restoredRedo.push(entry);
      restoredRedoBytes += entry.estimatedBytes;
    }
    while (restoredUndo.length > 0 &&
      (restoredUndo.length + restoredRedo.length > this.maxActions ||
        restoredUndoBytes + restoredRedoBytes > this.maxEstimatedBytes)) {
      const evicted: HistoryEntry | undefined = restoredUndo.shift();
      if (evicted === undefined) {
        break;
      }
      restoredUndoBytes -= evicted.estimatedBytes;
      this.evictedActions++;
      this.evictedEstimatedBytes += evicted.estimatedBytes;
    }
    if (restoredRedo.length > this.maxActions || restoredRedoBytes > this.maxEstimatedBytes) {
      this.clear();
      return;
    }
    this.undoStack = restoredUndo;
    this.redoStack = restoredRedo;
    this.undoBytes = restoredUndoBytes;
    this.redoBytes = restoredRedoBytes;
    this.latestHistory = null;
    this.historyRevision = 0;
  }

  prepareHistoryMetadata(action: UndoableAction): HistoryMetadata {
    return this.createHistoryMetadata(action);
  }

  getHistoryMetadataForMove(expected: UndoableAction, isUndo: boolean): HistoryMetadata | null {
    const stack: HistoryEntry[] = isUndo ? this.undoStack : this.redoStack;
    const top: HistoryEntry | undefined = stack.length > 0 ? stack[stack.length - 1] : undefined;
    if (top === undefined || top.action !== expected) {
      return null;
    }
    return this.withEffect(top.history, isUndo ? HistoryEffect.UNDO : HistoryEffect.REDO);
  }

  private peekGroup(stack: HistoryEntry[], effect: HistoryEffect): HistoryMove[] {
    const result: HistoryMove[] = [];
    if (stack.length === 0) {
      return result;
    }
    let anchor: HistoryEntry = stack[stack.length - 1];
    result.push({ action: anchor.action, history: this.withEffect(anchor.history, effect) });
    for (let index: number = stack.length - 2; index >= 0; index--) {
      const candidate: HistoryEntry = stack[index];
      const window: number = this.coalesceWindow(candidate.history.coalesceTrack);
      if (window < 0 || candidate.history.coalesceTrack !== anchor.history.coalesceTrack ||
        Math.abs(anchor.history.actionTime - candidate.history.actionTime) > window) {
        break;
      }
      result.push({ action: candidate.action, history: this.withEffect(candidate.history, effect) });
      anchor = candidate;
    }
    return result;
  }

  private commitGroup(expected: HistoryMove[], isUndo: boolean): boolean {
    if (expected.length === 0) {
      return false;
    }
    const source: HistoryEntry[] = isUndo ? this.undoStack : this.redoStack;
    const target: HistoryEntry[] = isUndo ? this.redoStack : this.undoStack;
    const effect: HistoryEffect = isUndo ? HistoryEffect.UNDO : HistoryEffect.REDO;
    if (expected.length > source.length) {
      return false;
    }
    for (let offset: number = 0; offset < expected.length; offset++) {
      const entry: HistoryEntry = source[source.length - 1 - offset];
      const move: HistoryMove = expected[offset];
      if (entry.action !== move.action || !this.sameHistory(move.history, this.withEffect(entry.history, effect))) {
        return false;
      }
    }
    for (let offset: number = 0; offset < expected.length; offset++) {
      const entry: HistoryEntry | undefined = source.pop();
      if (entry === undefined) {
        throw new Error('validated history group unexpectedly became empty');
      }
      target.push(entry);
      if (isUndo) {
        this.undoBytes -= entry.estimatedBytes;
        this.redoBytes += entry.estimatedBytes;
      } else {
        this.redoBytes -= entry.estimatedBytes;
        this.undoBytes += entry.estimatedBytes;
      }
      this.latestHistory = this.withEffect(entry.history, effect);
      this.advanceHistoryRevision();
    }
    return true;
  }

  private coalesceWindow(track: HistoryCoalesceTrack): number {
    if (track === HistoryCoalesceTrack.INSERT_TEXT) {
      return INSERT_TEXT_COALESCE_MS;
    }
    if (track === HistoryCoalesceTrack.REMOVE_TEXT) {
      return REMOVE_TEXT_COALESCE_MS;
    }
    if (track === HistoryCoalesceTrack.CREATE_INK) {
      return CREATE_INK_COALESCE_MS;
    }
    return -1;
  }

  private sameHistory(left: HistoryMetadata, right: HistoryMetadata): boolean {
    return left.actionId === right.actionId && left.effect === right.effect &&
      left.coalesceTrack === right.coalesceTrack && left.actionTime === right.actionTime;
  }

  private createHistoryMetadata(action: UndoableAction): HistoryMetadata {
    this.actionCounter++;
    const now: number = Date.now();
    const random: string = Math.random().toString(36).slice(2, 12);
    return {
      actionId: `history-${now.toString(36)}-${this.actionCounter.toString(36)}-${random}`,
      effect: HistoryEffect.PUSH,
      coalesceTrack: action.type === UndoableActionType.ADD_STROKE
        ? HistoryCoalesceTrack.CREATE_INK : HistoryCoalesceTrack.NONE,
      actionTime: now,
    };
  }

  private withEffect(history: HistoryMetadata, effect: HistoryEffect): HistoryMetadata {
    return {
      actionId: history.actionId,
      effect: effect,
      coalesceTrack: history.coalesceTrack,
      actionTime: history.actionTime,
    };
  }

  private acceptPreparedHistory(history: HistoryMetadata): HistoryMetadata {
    if (history.effect !== HistoryEffect.PUSH || history.actionId.length === 0 ||
      !Number.isSafeInteger(history.actionTime) || history.actionTime < 0 ||
      !Number.isSafeInteger(history.coalesceTrack) || history.coalesceTrack < HistoryCoalesceTrack.NONE ||
      history.coalesceTrack > HistoryCoalesceTrack.CREATE_INK) {
      throw new Error('prepared history metadata is invalid');
    }
    return this.withEffect(history, HistoryEffect.PUSH);
  }

  private restoredEntry(restored: RestoredHistoryAction): HistoryEntry {
    const history: HistoryMetadata = this.acceptPreparedHistory(restored.history);
    if (restored.action.noteId.length === 0 || restored.action.pageId.length === 0) {
      throw new Error('restored history action identity is invalid');
    }
    return {
      action: restored.action,
      estimatedBytes: estimateHistoryActionBytes(restored.action),
      history: history,
    };
  }

  private advanceHistoryRevision(): void {
    if (this.historyRevision >= Number.MAX_SAFE_INTEGER) {
      throw new Error('history revision is exhausted');
    }
    this.historyRevision++;
  }
}
